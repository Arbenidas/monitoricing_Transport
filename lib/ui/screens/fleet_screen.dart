import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'unit_detail_screen.dart'; // Will create this next

import '../widgets/live_map_widget.dart'; // Add import

class FleetScreen extends StatefulWidget { // Convert to StatefulWidget
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  bool _showMap = false;

  // Helper to extract Bus ID from Camera ID (e.g. "bus_101_front" -> "bus_101")
  String _getBusId(String cameraId) {
    // Determine delimiter (underscore or hyphen)
    // Simple heuristic: Take first 2 parts if starts with "bus_"
    final parts = cameraId.split('_');
    if (parts.length >= 2) {
       // e.g. "bus", "101", "front" -> "bus_101"
       return "${parts[0]}_${parts[1]}";
    }
    return "Desconocido"; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Flota de Unidades'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
            tooltip: _showMap ? "Ver Lista" : "Ver Mapa",
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('live_stream').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          
          // If Map View is active
          if (_showMap) {
             return LiveMapWidget(
               cameras: docs,
               onMarkerTap: (camId) {
                  // Optional: Navigate to detail or show info window
                  // For now, simpler to perhaps just show a snackbar or logic
               },
             );
          }

          // GROUP BY BUS ID
          final Map<String, List<QueryDocumentSnapshot>> fleet = {};
          
          for (var doc in docs) {
            final cameraId = doc.id;
            final busId = _getBusId(cameraId);
            
            if (!fleet.containsKey(busId)) {
              fleet[busId] = [];
            }
            fleet[busId]!.add(doc);
          }

          if (fleet.isEmpty) {
             return const Center(child: Text("No hay unidades activas", style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fleet.length,
            itemBuilder: (context, index) {
              final busId = fleet.keys.elementAt(index);
              final cameras = fleet[busId]!;
              
              // Calculate Aggregates
              int totalPeople = 0;
              bool isAnyLive = false;

              for (var cam in cameras) {
                final data = cam.data() as Map<String, dynamic>;
                totalPeople += (data['current_people'] as int? ?? 0);
                
                final Timestamp? lastUpdated = data['last_updated'];
                if (lastUpdated != null && DateTime.now().difference(lastUpdated.toDate()).inSeconds < 15) {
                    isAnyLive = true;
                }
              }

              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(Icons.directions_bus, size: 40, color: isAnyLive ? Colors.greenAccent : Colors.grey),
                  title: Text(
                    busId.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    "${cameras.length} Cámaras conectadas",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                        Text("$totalPeople", style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text("Pasajeros", style: TextStyle(color: Colors.grey, fontSize: 10))
                    ],
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => UnitDetailScreen(unitId: busId, cameras: cameras)
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
