import 'monitored_entity.dart';

class DashboardStats {
  final double totalRevenue;
  final int totalEntries;
  final int totalExits;
  final int currentOccupancy;
  final Duration avgStayTime;
  final int activeEntitiesCount;

  DashboardStats({
    this.totalRevenue = 0.0,
    this.totalEntries = 0,
    this.totalExits = 0,
    this.currentOccupancy = 0,
    this.avgStayTime = Duration.zero,
    this.activeEntitiesCount = 0,
  });

  DashboardStats copyWith({
    double? totalRevenue,
    int? totalEntries,
    int? totalExits,
    int? currentOccupancy,
    Duration? avgStayTime,
    int? activeEntitiesCount,
  }) {
    return DashboardStats(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalEntries: totalEntries ?? this.totalEntries,
      totalExits: totalExits ?? this.totalExits,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      avgStayTime: avgStayTime ?? this.avgStayTime,
      activeEntitiesCount: activeEntitiesCount ?? this.activeEntitiesCount,
    );
  }
}
