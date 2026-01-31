import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneTestScreen extends StatefulWidget {
  const PhoneTestScreen({super.key});

  @override
  State<PhoneTestScreen> createState() => _PhoneTestScreenState();
}

class _PhoneTestScreenState extends State<PhoneTestScreen> {
  // Collection Stream to list all devices
  final Stream<QuerySnapshot> _collectionStream = 
      FirebaseFirestore.instance.collection('live_stream').snapshots();
  
  String? _selectedDeviceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Monitoreo en Tiempo Real'),
        backgroundColor: Colors.grey[900],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _collectionStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }
          
          if (!snapshot.hasData) {
             return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
              return const Center(child: Text("No hay cámaras activas", style: TextStyle(color: Colors.white)));
          }

          // Auto-select first camera if none selected
          if (_selectedDeviceId == null && docs.isNotEmpty) {
             // Try to find one with 'bus' in ID, else take first
             _selectedDeviceId = docs.first.id;
          }

          // Compute Global Stats
          int totalPeople = 0;
          int totalIn = 0;
          int totalOut = 0;
          for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              totalPeople += (data['current_people'] as int? ?? 0);
              totalIn += (data['total_in'] as int? ?? 0);
              totalOut += (data['total_out'] as int? ?? 0);
          }

          // Find selected doc data
          final selectedDoc = docs.firstWhere((d) => d.id == _selectedDeviceId, orElse: () => docs.first);
          final selectedData = selectedDoc.data() as Map<String, dynamic>;
          
          final String currentId = selectedDoc.id;
          final int currentCount = selectedData['current_people'] ?? 0;
          final int currentIn = selectedData['total_in'] ?? 0;
          final int currentOut = selectedData['total_out'] ?? 0;
          final String? base64Image = selectedData['image_base64'];
          final Timestamp? lastUpdated = selectedData['last_updated'];
          final bool isLive = lastUpdated != null && DateTime.now().difference(lastUpdated.toDate()).inSeconds < 15;

          return Column(
            children: [
                // 1. CAMERA SELECTOR (Horizontal List)
                Container(
                    height: 60,
                    color: Colors.grey[900],
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                            final docId = docs[index].id;
                            final isSelected = docId == _selectedDeviceId;
                            return GestureDetector(
                                onTap: () => setState(() => _selectedDeviceId = docId),
                                child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: isSelected ? Colors.blueAccent : Colors.grey[800],
                                        borderRadius: BorderRadius.circular(20),
                                        border: isSelected ? Border.all(color: Colors.white) : null
                                    ),
                                    child: Text(
                                        docId,
                                        style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.grey[400],
                                            fontWeight: FontWeight.bold
                                        ),
                                    ),
                                ),
                            );
                        },
                    ),
                ),

                // 2. VIDEO AREA
                Expanded(
                    flex: 3,
                    child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isLive ? Colors.green : Colors.red),
                            boxShadow: [
                               BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20) 
                            ]
                        ),
                        child: Stack(
                            fit: StackFit.expand,
                            children: [
                                // Video Stream from Firestore (Base64)
                                base64Image != null 
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.memory(
                                            base64Decode(base64Image.split(',').last),
                                            fit: BoxFit.cover,
                                            gaplessPlayback: true,
                                        )
                                      )
                                    : const Center(
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                                Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                                                SizedBox(height: 16),
                                                Text("Sin señal de video", style: TextStyle(color: Colors.grey)),
                                            ],
                                        ),
                                    ),
                                
                                // Real-Time Overlay Counter
                                Positioned(
                                    top: 20,
                                    right: 20,
                                    child: _buildOverlayStats(currentCount, currentIn, currentOut),
                                ),

                                // Status Indicator
                                Positioned(
                                    top: 20,
                                    left: 20,
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: isLive ? Colors.green : Colors.red,
                                            borderRadius: BorderRadius.circular(4)
                                        ),
                                        child: Text(
                                            isLive ? "EN VIVO: $currentId" : "OFFLINE: $currentId",
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                    ),
                                )
                            ],
                        ),
                    ),
                ),
                
                // 3. GLOBAL STATS
                Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    color: Colors.grey[900],
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                            _buildStatItem("TOTAL A BORDO", "$totalPeople", Colors.greenAccent),
                            _buildStatItem("TOTAL ENTRADAS", "$totalIn", Colors.blueAccent),
                            _buildStatItem("TOTAL SALIDAS", "$totalOut", Colors.redAccent),
                        ],
                    ),
                )
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverlayStats(int count, int countIn, int countOut) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
                Text("Visión: $count", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("In: $countIn", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                 Text("Out: $countOut", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
        ),
      );
  }

  Widget _buildStatItem(String label, String value, Color color) {
      return Column(
          children: [
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
      );
  }
}
