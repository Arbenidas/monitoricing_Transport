import 'package:flutter_test/flutter_test.dart';
import 'package:transport_monitoring/models/monitored_entity.dart';
import 'package:transport_monitoring/models/passenger_event.dart';
import 'package:transport_monitoring/providers/dashboard_provider.dart';
import 'package:transport_monitoring/services/ai_service_interface.dart';
import 'dart:async';

class MockAiServiceForTest implements AiServiceInterface {
  final _controller = StreamController<PassengerEvent>.broadcast();

  @override
  List<MonitoredEntity> monitoredEntities = [
    MonitoredEntity(id: 'bus_1', name: 'Bus 1', type: EntityType.transport, groupId: 'A', revenueFactor: 1.50),
  ];

  @override
  Stream<PassengerEvent> get eventsStream => _controller.stream;

  void emitEvent(PassengerEvent event) {
    _controller.add(event);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  test('DashboardProvider updates stats and revenue correctly', () async {
    final service = MockAiServiceForTest();
    final provider = DashboardProvider(service);

    expect(provider.stats.totalEntries, 0);
    expect(provider.stats.totalRevenue, 0.0);

    // Emit Entry Event
    service.emitEvent(PassengerEvent(
      id: '1', 
      entityId: 'bus_1', 
      type: EventType.entry, 
      timestamp: DateTime.now()
    ));

    // Wait for stream listener
    await Future.delayed(Duration.zero);

    expect(provider.stats.totalEntries, 1);
    expect(provider.stats.currentOccupancy, 1);
    expect(provider.stats.totalRevenue, 1.50); // Tariff check

    // Emit Exit Event
    service.emitEvent(PassengerEvent(
      id: '2', 
      entityId: 'bus_1', 
      type: EventType.exit, 
      timestamp: DateTime.now()
    ));

    await Future.delayed(Duration.zero);

    expect(provider.stats.totalEntries, 1); // Doesn't decrease on exit
    expect(provider.stats.currentOccupancy, 0); // Decreases
  });
}
