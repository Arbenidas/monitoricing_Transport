enum EventType {
  entry,
  exit,
}

class PassengerEvent {
  final String id;
  final String entityId;
  final EventType type;
  final DateTime timestamp;

  PassengerEvent({
    required this.id,
    required this.entityId,
    required this.type,
    required this.timestamp,
  });
}
