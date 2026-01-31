import 'dart:async';
import 'dart:math';
import '../models/alert_event.dart';
import '../models/passenger_event.dart';
import '../models/monitored_entity.dart';
import 'ai_service_interface.dart';
import '../models/video_analysis.dart';
import 'package:uuid/uuid.dart';

class MockAiService implements AiServiceInterface {
  final _eventStreamController = StreamController<PassengerEvent>.broadcast();
  final _alertStreamController = StreamController<AlertEvent>.broadcast();
  final _uuid = const Uuid();
  final Random _random = Random();
  Timer? _simulationTimer;

  // Mock Data: Transport Fleet (Buses)
  final List<MonitoredEntity> monitoredEntities = [
    // Ruta A
    MonitoredEntity(id: 'bus_101', name: 'Unidad 101', type: EntityType.transport, groupId: 'Ruta A', revenueFactor: 0.50, x: 0.2, y: 0.4),
    MonitoredEntity(id: 'bus_102', name: 'Unidad 102', type: EntityType.transport, groupId: 'Ruta A', revenueFactor: 0.50, x: 0.3, y: 0.3),
    MonitoredEntity(id: 'bus_103', name: 'Unidad 103', type: EntityType.transport, groupId: 'Ruta A', revenueFactor: 0.50, x: 0.4, y: 0.5),
    
    // Ruta B
    MonitoredEntity(id: 'bus_201', name: 'Unidad 201', type: EntityType.transport, groupId: 'Ruta B', revenueFactor: 0.75, x: 0.6, y: 0.2),
    MonitoredEntity(id: 'bus_202', name: 'Unidad 202', type: EntityType.transport, groupId: 'Ruta B', revenueFactor: 0.75, x: 0.7, y: 0.3),
    
    // Ruta C
    MonitoredEntity(id: 'bus_301', name: 'Unidad 301', type: EntityType.transport, groupId: 'Ruta C', revenueFactor: 0.60, x: 0.5, y: 0.8),
    MonitoredEntity(id: 'bus_302', name: 'Unidad 302', type: EntityType.transport, groupId: 'Ruta C', revenueFactor: 0.60, x: 0.8, y: 0.6),
  ];

  MockAiService() {
    _startSimulation();
  }

  @override
  Stream<PassengerEvent> get eventsStream => _eventStreamController.stream;

  @override
  Stream<AlertEvent> get alertsStream => _alertStreamController.stream;

  void _startSimulation() {
    // Generate an event every 1.5 seconds
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (_eventStreamController.isClosed) return;

      // Pick random entity
      final entity = monitoredEntities[_random.nextInt(monitoredEntities.length)];
      
      // 1. Generate Passenger Event
      final isEntry = _random.nextDouble() > 0.45; 

      final event = PassengerEvent(
        id: _uuid.v4(),
        entityId: entity.id,
        type: isEntry ? EventType.entry : EventType.exit,
        timestamp: DateTime.now(),
      );

      _eventStreamController.add(event);

      // 2. Randomly Generate Alert (10% chance)
      if (_random.nextDouble() < 0.10) {
        _generateRandomAlert(entity);
      }
    });
  }

  void _generateRandomAlert(MonitoredEntity entity) {
     if (_alertStreamController.isClosed) return;

     AlertType type;
     AlertSeverity severity;
     String message;

     double r = _random.nextDouble();
     if (r < 0.33) {
       type = AlertType.highOccupancy;
       severity = AlertSeverity.warning;
       message = 'Alta ocupación detectada en ${entity.name}';
     } else if (r < 0.66) {
       type = AlertType.longWaitTime;
       severity = AlertSeverity.info;
       message = 'Tiempo de espera elevado en ${entity.name}';
     } else {
       type = AlertType.disturbance;
       severity = AlertSeverity.critical;
       message = 'Incidente reportado en ${entity.name}';
     }

     final alert = AlertEvent(
       id: _uuid.v4(),
       entityId: entity.id,
       type: type,
       severity: severity,
       message: message,
       timestamp: DateTime.now(),
     );

     _alertStreamController.add(alert);
  }

  @override
  Future<VideoAnalysisResult> analyzeVideo(String videoUrl) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    const totalDuration = Duration(seconds: 10);
    List<DetectedObject> detectedObjects = [];

    // Mock Person 1: Walking Left to Right
    List<ObjectFrame> frames1 = [];
    for (int i = 0; i <= 50; i++) {
        // 5 seconds, 10 updates per second (total 50 frames)
        double progress = i / 50.0;
        double x = progress * 0.8; // Move from 0.0 to 0.8 width
        frames1.add(ObjectFrame(
            timeOffset: Duration(milliseconds: (i * 100).toInt()),
            boundingBox: NormalizedBoundingBox(
                left: x,
                top: 0.4,
                right: x + 0.1, // 10% width
                bottom: 0.7 // 30% height
            ),
        ));
    }
    detectedObjects.add(DetectedObject(
        id: 'person_1',
        label: 'Person',
        confidence: 0.95,
        frames: frames1,
    ));

    // Mock Person 2: Walking Right to Left (starts at 2s)
    List<ObjectFrame> frames2 = [];
    for (int i = 0; i <= 50; i++) {
        double progress = i / 50.0;
        double x = 0.9 - (progress * 0.8); // Move from 0.9 to 0.1
        frames2.add(ObjectFrame(
            timeOffset: Duration(seconds: 2) + Duration(milliseconds: (i * 100).toInt()),
            boundingBox: NormalizedBoundingBox(
                left: x,
                top: 0.5,
                right: x + 0.1,
                bottom: 0.8
            ),
        ));
    }
    detectedObjects.add(DetectedObject(
        id: 'person_2',
        label: 'Person',
        confidence: 0.88,
        frames: frames2,
    ));

    return VideoAnalysisResult(
        videoId: _uuid.v4(),
        duration: totalDuration,
        objects: detectedObjects,
        totalPeopleCount: 2,
    );
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _eventStreamController.close();
    _alertStreamController.close();
  }
}
