import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';
import '../models/monitored_entity.dart';
import '../models/passenger_event.dart';
import '../models/alert_event.dart';
import '../services/ai_service_interface.dart';

class DashboardProvider extends ChangeNotifier {
  final AiServiceInterface _aiService;
  
  // State
  DashboardStats _stats = DashboardStats();
  
  // Filter state
  MonitoredEntity? _selectedEntity;
  String? _selectedGroupId;
  EntityType? _filterType;

  // Getters
  List<MonitoredEntity> get monitoredEntities {
    if (_selectedGroupId != null) {
      return _aiService.monitoredEntities.where((e) => e.groupId == _selectedGroupId).toList();
    }
    return _aiService.monitoredEntities;
  }
  
  List<String> get availableGroups {
    return _aiService.monitoredEntities.map((e) => e.groupId).toSet().toList()..sort();
  }

  String? get selectedGroupId => _selectedGroupId;
  DashboardStats get stats => _stats;
  List<int> get occupancyHistory => _occupancyHistory;
  MonitoredEntity? get selectedEntity => _selectedEntity;
  List<AlertEvent> get alerts => _alerts;
  
  final List<AlertEvent> _alerts = [];
  
  // Historical data for charts (last 24 points e.g.)
  final List<int> _occupancyHistory = [];
  
  DashboardProvider(this._aiService) {
    _init();
  }

  void _init() {
    _aiService.eventsStream.listen(_onEvent);
    _aiService.alertsStream.listen(_onAlert);
  }

  void _onEvent(PassengerEvent event) {
    // Find entity in FULL list to check its properties
    final entity = _aiService.monitoredEntities.firstWhere(
      (e) => e.id == event.entityId, 
      orElse: () => _aiService.monitoredEntities.first // Fallback
    );

    // If we are filtering by specific entity and this event is not for it, ignore.
    if (_selectedEntity != null && event.entityId != _selectedEntity!.id) return;
    
    // Filter by Group (Route)
    if (_selectedGroupId != null && entity.groupId != _selectedGroupId) return;

    // If we are filtering by type (e.g. only Buses) and this event is not for it, ignore.
    if (_filterType != null) {
       if (entity.type != _filterType) return;
    }

    _updateStats(event, entity);
    notifyListeners();
  }

  void _onAlert(AlertEvent alert) {
    // Filter alerts by group too if needed
    if (_selectedGroupId != null) {
       final entity = _aiService.monitoredEntities.firstWhere((e) => e.id == alert.entityId);
       if (entity.groupId != _selectedGroupId) return;
    }

    // Add new alert to the top of the list
    _alerts.insert(0, alert);
    
    // Keep only last 10 alerts
    if (_alerts.length > 10) {
      _alerts.removeLast();
    }
    notifyListeners();
  }

  void removeAlert(String alertId) {
    _alerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
  }

  void _updateStats(PassengerEvent event, MonitoredEntity entity) {
    int newEntries = _stats.totalEntries;
    int newExits = _stats.totalExits;
    int newOccupancy = _stats.currentOccupancy;
    double newRevenue = _stats.totalRevenue;

    if (event.type == EventType.entry) {
      newEntries++;
      newOccupancy++;
      // Revenue is added on entry 
      newRevenue += entity.revenueFactor; 
    } else {
      newExits++;
      newOccupancy = (newOccupancy > 0) ? newOccupancy - 1 : 0;
    }

    _stats = _stats.copyWith(
      totalEntries: newEntries,
      totalExits: newExits,
      currentOccupancy: newOccupancy,
      totalRevenue: newRevenue,
      activeEntitiesCount: monitoredEntities.length,
    );
    
    // Update history for charts (maintain max 50 points)
    _occupancyHistory.add(newOccupancy);
    if (_occupancyHistory.length > 50) {
      _occupancyHistory.removeAt(0);
    }
  }

  // Actions
  void selectEntity(MonitoredEntity? entity) {
    _selectedEntity = entity;
    _resetStats(); 
    notifyListeners();
  }
  
  void setFilterGroup(String? groupId) {
    _selectedGroupId = groupId;
    _resetStats();
    notifyListeners();
  }
  
  void _resetStats() {
    _stats = DashboardStats(activeEntitiesCount: monitoredEntities.length);
    _occupancyHistory.clear();
    _alerts.clear(); // Clear alerts on filter change for clean view
  }
}
