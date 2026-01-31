import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/kpi_card.dart';
import '../widgets/analytics_chart.dart';
import '../widgets/map_widget.dart';
import '../widgets/alerts_list.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});
  
  final currencyFormat = NumberFormat.simpleCurrency();

  static const double _breakpointNarrow = 600;
  static const double _breakpointWide = 900;

  double _paddingForWidth(double width) {
    if (width < _breakpointNarrow) return 12;
    if (width < _breakpointWide) return 16;
    return 32;
  }

  int _crossAxisCountForWidth(double width) {
    if (width < _breakpointNarrow) return 1;
    if (width < _breakpointWide) return 2;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final stats = provider.stats;
        final width = MediaQuery.of(context).size.width;
        final padding = _paddingForWidth(width);
        final isNarrow = width < _breakpointNarrow;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard de Monitoreo',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Route Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: const Text('Todas'),
                        selected: provider.selectedGroupId == null,
                        onSelected: (selected) {
                          if (selected) provider.setFilterGroup(null);
                        },
                        selectedColor: AppTheme.primaryBlue,
                        labelStyle: TextStyle(
                          color: provider.selectedGroupId == null ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        elevation: provider.selectedGroupId == null ? 4 : 0,
                        shadowColor: Colors.black12,
                      ),
                    ),
                    ...provider.availableGroups.map((group) {
                      final isSelected = provider.selectedGroupId == group;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(group),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) provider.setFilterGroup(group);
                          },
                          selectedColor: AppTheme.primaryBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          elevation: isSelected ? 4 : 0,
                          shadowColor: Colors.black12,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: isNarrow ? _buildNarrowLayout(context, provider, stats) : _buildGridLayout(context, provider, stats, width),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNarrowLayout(BuildContext context, DashboardProvider provider, dynamic stats) {
    final width = MediaQuery.of(context).size.width;
    final padding = _paddingForWidth(width);
    final contentWidth = width - padding * 2;
    const spacing = 12.0;
    final cellWidth = (contentWidth - spacing) / 2;
    const cellHeight = 100.0;
    final childAspectRatio = cellWidth / cellHeight;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: cellHeight * 2 + spacing,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: childAspectRatio,
              children: [
                KpiCard(
                  label: 'Pasajeros Totales',
                  value: '${stats.totalEntries}',
                  icon: Icons.groups,
                  isTrendUp: true,
                  subtext: '+5% vs Ayer',
                ),
                KpiCard(
                  label: 'Tiempo en Ruta',
                  value: '${stats.avgStayTime.inMinutes} min',
                  icon: Icons.timer,
                  subtext: 'Estable',
                  iconColor: Colors.blue,
                ),
                KpiCard(
                  label: 'Recaudo Total',
                  value: currencyFormat.format(stats.totalRevenue),
                  icon: Icons.attach_money,
                  isTrendUp: true,
                  subtext: 'Basado en Tarifas',
                  iconColor: Colors.green,
                ),
                KpiCard(
                  label: 'Buses Activos',
                  value: '${stats.activeEntitiesCount}',
                  icon: Icons.directions_bus,
                  iconColor: Colors.orange,
                  subtext: 'En circulación',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
            child: AnalyticsChart(dataPoints: provider.occupancyHistory),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            height: 250,
            child: MapWidget(),
          ),
          const SizedBox(height: 24),
          const AlertsList(),
        ],
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context, DashboardProvider provider, dynamic stats, double width) {
    final crossAxisCount = _crossAxisCountForWidth(width);
    const spacing = 24.0;

    final kpiTiles = [
      StaggeredGridTile.count(
        crossAxisCellCount: 1,
        mainAxisCellCount: 0.8,
        child: KpiCard(
          label: 'Pasajeros Totales',
          value: '${stats.totalEntries}',
          icon: Icons.groups,
          isTrendUp: true,
          subtext: '+5% vs Ayer',
        ),
      ),
      StaggeredGridTile.count(
        crossAxisCellCount: 1,
        mainAxisCellCount: 0.8,
        child: KpiCard(
          label: 'Tiempo en Ruta',
          value: '${stats.avgStayTime.inMinutes} min',
          icon: Icons.timer,
          subtext: 'Estable',
          iconColor: Colors.blue,
        ),
      ),
      StaggeredGridTile.count(
        crossAxisCellCount: 1,
        mainAxisCellCount: 0.8,
        child: KpiCard(
          label: 'Recaudo Total',
          value: currencyFormat.format(stats.totalRevenue),
          icon: Icons.attach_money,
          isTrendUp: true,
          subtext: 'Basado en Tarifas',
          iconColor: Colors.green,
        ),
      ),
      StaggeredGridTile.count(
        crossAxisCellCount: 1,
        mainAxisCellCount: 0.8,
        child: KpiCard(
          label: 'Buses Activos',
          value: '${stats.activeEntitiesCount}',
          icon: Icons.directions_bus,
          iconColor: Colors.orange,
          subtext: 'En circulación',
        ),
      ),
    ];

    return SingleChildScrollView(
      child: StaggeredGridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ...kpiTiles,
          StaggeredGridTile.count(
            crossAxisCellCount: crossAxisCount >= 4 ? 2 : crossAxisCount,
            mainAxisCellCount: 2,
            child: AnalyticsChart(dataPoints: provider.occupancyHistory),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: crossAxisCount >= 4 ? 2 : crossAxisCount,
            mainAxisCellCount: 2,
            child: const MapWidget(),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: crossAxisCount,
            mainAxisCellCount: 1.5,
            child: const AlertsList(),
          ),
        ],
      ),
    );
  }
}
