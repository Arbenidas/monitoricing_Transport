import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveMapWidget extends StatefulWidget {
  final List<QueryDocumentSnapshot> cameras;
  final Function(String)? onMarkerTap;

  const LiveMapWidget({
    super.key,
    required this.cameras,
    this.onMarkerTap,
  });

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  // Default center (Mexico City - to match user's likely context or safe default)
  final LatLng _initialCenter = const LatLng(19.4326, -99.1332);
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    // 1. Convert cameras to markers
    final markers = widget.cameras.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final GeoPoint? location = data['location'];
      final String camId = doc.id;
      final String busId = camId.split('_').length > 1 
          ? camId.split('_').sublist(0, 2).join(' ') 
          : camId;

      if (location == null) return null;

      return Marker(
        point: LatLng(location.latitude, location.longitude),
        width: 140,
        height: 80,
        child: GestureDetector(
          onTap: () => widget.onMarkerTap?.call(doc.id),
          child: Column(
            children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: Colors.black87,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.greenAccent),
                   boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black54)]
                 ),
                 child: Text(
                   busId.toUpperCase(),
                   style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                 ),
               ),
               const Icon(Icons.directions_bus, color: Colors.greenAccent, size: 30),
            ],
          ),
        ),
      );
    }).whereType<Marker>().toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: markers.isNotEmpty ? markers.first.point : _initialCenter,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.transport.monitoring',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        
        // Floating Camera List
        if (markers.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: widget.cameras.length,
                itemBuilder: (context, index) {
                  final doc = widget.cameras[index];
                  final camId = doc.id;
                  final busId = camId.split('_').length > 1 
                      ? camId.split('_').sublist(0, 2).join(' ') 
                      : camId;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ActionChip(
                      avatar: const Icon(Icons.videocam, size: 16, color: Colors.white),
                      label: Text(busId.toUpperCase(), style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.greenAccent),
                      onPressed: () {
                         final data = doc.data() as Map<String, dynamic>;
                         final GeoPoint? location = data['location'];
                         if (location != null) {
                             _mapController.move(
                                 LatLng(location.latitude, location.longitude), 
                                 16 // Close zoom
                             );
                         }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
