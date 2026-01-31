enum EntityType {
  transport,
  retail,
}

class MonitoredEntity {
  final String id;
  final String name;
  final EntityType type;
  final String groupId; // Route or Mall ID
  final double revenueFactor; // Tariff or Avg Ticket
  // Mock Coordinates (0.0 - 1.0)
  final double x;
  final double y;

  MonitoredEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.groupId,
    required this.revenueFactor,
    this.x = 0.5,
    this.y = 0.5,
  });

  // Calculate generic revenue for count
  double calculateRevenue(int count) {
    return count * revenueFactor;
  }
}
