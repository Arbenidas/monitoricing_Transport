import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'live_map_widget.dart';
import '../theme/app_theme.dart';

class MapWidget extends StatelessWidget {
  const MapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Real-time Map
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('live_stream').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              
              // Filter for valid locations ONLY
              final docs = snapshot.data!.docs.where((doc) {
                 final data = doc.data() as Map<String, dynamic>;
                 return data['location'] != null;
              }).toList();

              if (docs.isEmpty) {
                 return Container(
                    color: const Color(0xFFE2E8F0),
                    child: Center(
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                            Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text("Sin ubicación de unidades", style: TextStyle(color: Colors.grey.shade600))
                         ],
                       )
                    )
                 );
              }

              return LiveMapWidget(cameras: docs);
            },
          ),
          
          // Title Overlay
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public, size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Mapa en Vivo',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
