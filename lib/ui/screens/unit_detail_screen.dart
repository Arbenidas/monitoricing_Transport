import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class UnitDetailScreen extends StatefulWidget {
  final String unitId;
  final List<QueryDocumentSnapshot> cameras; // Initial snapshot, logic will listen to stream

  const UnitDetailScreen({super.key, required this.unitId, required this.cameras});

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  double _fare = 0.50; // Default fare
  final TextEditingController _fareController = TextEditingController(text: "0.50");

  @override
  Widget build(BuildContext context) {
    // Listen to updates for ALL cameras in this unit
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.unitId.toUpperCase().replaceAll('_', ' ')),
        backgroundColor: Colors.grey[900],
        actions: [
            IconButton(
                icon: const Icon(Icons.attach_money),
                onPressed: _showFareDialog,
            )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('live_stream').snapshots(),
        builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            // Filter strictly for this unit's cameras
            final unitDocs = snapshot.data!.docs.where((d) => d.id.startsWith(widget.unitId)).toList();
            
            if (unitDocs.isEmpty) return const Center(child: Text("Sin señal", style: TextStyle(color: Colors.white)));

            // AGGREGATE METRICS & DE-DUPLICATION LOGIC
            int totalIn = 0;
            int totalOut = 0;
            int currentOnBoard = 0;
            
            // Collect timestamps to find duplicates
            List<int> entryTimestamps = [];
            int duplicateCount = 0;

            for (var cam in unitDocs) {
                final data = cam.data() as Map<String, dynamic>;
                totalIn += (data['total_in'] as int? ?? 0);
                totalOut += (data['total_out'] as int? ?? 0);
                currentOnBoard += (data['current_people'] as int? ?? 0);
                
                final int? ts = data['last_entry_ts'];
                if (ts != null) entryTimestamps.add(ts);
            }
            
            // Simple Fusion Logic (NIVEL 1: Heurística Temporal): 
            // If timestamps are within 2000ms, consider them the same event.
            // TODO: Implementar NIVEL 2 -> Call Cloud Function (scripts/vertex_ai_reid.py) para verificación visual real.
            entryTimestamps.sort();
            for (int i = 0; i < entryTimestamps.length - 1; i++) {
                if ((entryTimestamps[i+1] - entryTimestamps[i]) < 2000) {
                    duplicateCount++;
                    // Aquí llamaríamos a Vertex AI para confirmar si las fotos coinciden visualmente:
                    // bool confirmed = await verifyWithVertexAI(img1, img2);
                    // if (confirmed) duplicateCount++;
                    
                    i++; // Skip next one as it's paired
                }
            }

            // Correct totals
            final int correctedIn = totalIn - duplicateCount;
            // FINANCIALS
            final double revenue = correctedIn * _fare;

            return Column(
                children: [
                    // SMART FUSION ALERT (Mock AI)
                    if (duplicateCount > 0)
                        Container(
                            width: double.infinity,
                            color: Colors.indigo,
                            padding: const EdgeInsets.all(8),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                        "IA Híbrida: $duplicateCount duplicados fusionados",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                ],
                            ),
                        ),

                    // 1. FINANCIAL DASHBOARD
                    Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.grey[900],
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                                _buildMetric("ABORTADOS", "$currentOnBoard", Colors.blue),
                                _buildMetric("TOTAL ENTRADAS", "$correctedIn", Colors.green), // Corrected
                                _buildMetric("INGRESOS", "\$${revenue.toStringAsFixed(2)}", Colors.amber),
                            ],
                        ),
                    ),

                    const SizedBox(height: 10),

                    // 2. CAMERA GRID
                    Expanded(
                        child: GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 2 Cameras per row
                                childAspectRatio: 1.2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10
                            ),
                            itemCount: unitDocs.length,
                            itemBuilder: (context, index) {
                                final doc = unitDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                return _buildCameraCard(doc.id, data);
                            },
                        ),
                    ),
                    
                    // 3. LOG / DEBUG
                    Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                            "Tarifa actual: \$${_fare.toStringAsFixed(2)} por pasajero",
                            style: const TextStyle(color: Colors.grey),
                        ),
                    )
                ],
            );
        },
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
      return Column(
          children: [
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
      );
  }

  Widget _buildCameraCard(String camId, Map<String, dynamic> data) {
      final String? base64 = data['image_base64'];
      final int count = data['current_people'] ?? 0;
      final Timestamp? lastUpdated = data['last_updated'];
      final bool isLive = lastUpdated != null && DateTime.now().difference(lastUpdated.toDate()).inSeconds < 15;

      return Container(
          decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isLive ? Colors.green : Colors.red, width: 2)
          ),
          child: Stack(
              fit: StackFit.expand,
              children: [
                  if (base64 != null)
                     ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(base64Decode(base64.split(',').last), fit: BoxFit.cover, gaplessPlayback: true)
                     )
                  else
                     const Center(child: Icon(Icons.videocam_off, color: Colors.grey)),
                  
                  // Label
                  Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                          padding: const EdgeInsets.all(4),
                          color: Colors.black54,
                          child: Text(
                              camId.split('_').last.toUpperCase(), // "FRONT", "BACK"
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              textAlign: TextAlign.center,
                          ),
                      ),
                  ),

                  // Count Badge
                  Positioned(
                      top: 8, right: 8,
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                          child: Text("$count Pax", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      ),
                  )
              ],
          ),
      );
  }

  void _showFareDialog() {
      showDialog(context: context, builder: (_) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Configurar Tarifa", style: TextStyle(color: Colors.white)),
          content: TextField(
              controller: _fareController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: "Precio por Pasaje",
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixText: "\$ ",
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
          ),
          actions: [
              TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                  child: const Text("Guardar"),
                  onPressed: () {
                      setState(() {
                          _fare = double.tryParse(_fareController.text) ?? 0.50;
                      });
                      Navigator.pop(context);
                  },
              )
          ],
      ));
  }
}
