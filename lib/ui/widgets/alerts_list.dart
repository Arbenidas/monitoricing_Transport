import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/alert_event.dart';

class AlertsList extends StatelessWidget {
  const AlertsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alertas en Tiempo Real',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Consumer<DashboardProvider>(
                  builder: (context, provider, _) {
                    return Text(
                      '${provider.alerts.length} activas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    );
                  }
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<DashboardProvider>(
                builder: (context, provider, child) {
                  final alerts = provider.alerts;
                  
                  if (alerts.isEmpty) {
                    return Center(
                      child: Text(
                        'Sin alertas recientes',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return _AlertItem(alert: alert, onDismiss: () => provider.removeAlert(alert.id));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final AlertEvent alert;
  final VoidCallback onDismiss;

  const _AlertItem({required this.alert, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (alert.severity) {
      case AlertSeverity.warning:
        icon = Icons.warning_amber;
        color = Colors.amber;
        break;
      case AlertSeverity.critical:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      case AlertSeverity.info:
      default:
        icon = Icons.info_outline;
        color = Colors.blue;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(alert.message, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        DateFormat('hh:mm:ss a').format(alert.timestamp),
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 18),
        onPressed: onDismiss,
        color: Colors.grey[400],
      ),
    );
  }
}
