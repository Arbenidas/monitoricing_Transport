enum AlertType {
  highOccupancy,
  longWaitTime,
  disturbance,
  custom,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

class AlertEvent {
  final String id;
  final String entityId;
  final String message;
  final AlertType type;
  final AlertSeverity severity;
  final DateTime timestamp;

  AlertEvent({
    required this.id,
    required this.entityId,
    required this.message,
    required this.type,
    required this.severity,
    required this.timestamp,
  });
}
