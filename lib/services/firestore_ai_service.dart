import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/alert_event.dart';
import '../models/passenger_event.dart';
import '../models/monitored_entity.dart';
import 'ai_service_interface.dart';
import '../models/video_analysis.dart';

class FirestoreAiService implements AiServiceInterface {
  final _eventStreamController = StreamController<PassengerEvent>.broadcast();
  final _alertStreamController = StreamController<AlertEvent>.broadcast();
  final _uuid = const Uuid();
  
  // Cache state to calculate diffs
  final Map<String, int> _lastInCounts = {};
  final Map<String, int> _lastOutCounts = {};
  
  // Dynamic list built from Firestore
  List<MonitoredEntity> _monitoredEntities = [];
  
  StreamSubscription? _firestoreSub;

  FirestoreAiService() {
    _initSubscription();
  }

  void _initSubscription() {
    _firestoreSub = FirebaseFirestore.instance.collection('live_stream').snapshots().listen((snapshot) {
      final List<MonitoredEntity> currentEntities = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final deviceId = doc.id;
        
        // --- 1. BUILD ENTITY ---
        // Logic to try to parse Bus ID from Device ID or use assignment field
        // Expected format: "bus_101_front" or custom field "assigned_bus_id"
        String busId = data['assigned_bus_id'] ?? _parseBusId(deviceId);
        String name = "Cámara $deviceId"; 
        
        // Create Entity (One Entity per Camera for granular tracking, 
        // or we could aggregate here. Let's map Camera -> Entity for now)
        final entity = MonitoredEntity(
            id: deviceId,
            name: name,
            type: EntityType.transport,
            groupId: busId, // Group by Bus
            revenueFactor: 0.50, // Default fare, could be configurable
            x: 0.5, y: 0.5
        );
        currentEntities.add(entity);

        // --- 2. DETECT EVENTS (Diffing) ---
        final int currentIn = data['total_in'] as int? ?? 0;
        final int currentOut = data['total_out'] as int? ?? 0;

        _checkForEvents(deviceId, currentIn, currentOut);
      }
      
      _monitoredEntities = currentEntities;
      
    }, onError: (e) {
      print("Error listening to Firestore: $e");
    });
  }
  
  String _parseBusId(String deviceId) {
     if (deviceId.contains('_')) {
         final parts = deviceId.split('_');
         if (parts.length >= 2) return "${parts[0]}_${parts[1]}";
     }
     return "Sin Asignar";
  }

  void _checkForEvents(String entityId, int currentIn, int currentOut) {
      // IN EVENTS
      final lastIn = _lastInCounts[entityId];
      if (lastIn != null && currentIn > lastIn) {
          final diff = currentIn - lastIn;
          for(int i=0; i<diff; i++) {
              _eventStreamController.add(PassengerEvent(
                  id: _uuid.v4(),
                  entityId: entityId,
                  type: EventType.entry,
                  timestamp: DateTime.now()
              ));
          }
      }
      _lastInCounts[entityId] = currentIn;

      // OUT EVENTS
      final lastOut = _lastOutCounts[entityId];
      if (lastOut != null && currentOut > lastOut) {
          final diff = currentOut - lastOut;
          for(int i=0; i<diff; i++) {
              _eventStreamController.add(PassengerEvent(
                  id: _uuid.v4(),
                  entityId: entityId,
                  type: EventType.exit,
                  timestamp: DateTime.now()
              ));
          }
      }
      _lastOutCounts[entityId] = currentOut;
  }

  @override
  Stream<PassengerEvent> get eventsStream => _eventStreamController.stream;

  @override
  Stream<AlertEvent> get alertsStream => _alertStreamController.stream;

  @override
  List<MonitoredEntity> get monitoredEntities => _monitoredEntities;

  @override
  Future<VideoAnalysisResult> analyzeVideo(String videoUrl) async {
    // Determine implementation later if needed for real video files
    throw UnimplementedError();
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    _eventStreamController.close();
    _alertStreamController.close();
  }
}
