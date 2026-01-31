import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // Using direct HTML for reliability on Web
import '../../providers/dashboard_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../screens/fleet_screen.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MonitorPro'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          _buildNavItem(context, 'Inicio', true, () {}),
          _buildNavItem(context, 'Unidades (Flota)', false, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetScreen()));
          }),
          _buildNavItem(context, 'Rutas', false, () {}),
          const SizedBox(width: 20),
          
          // MODO CÁMARA BUTTON
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text("MODO CÁMARA"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
                // Direct JS navigation is most robust for this use case
                final String url = 'mobile_camera.html';
                html.window.open(url, "_self");
            },
          ),

          const SizedBox(width: 20),
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: DashboardScreen(),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap, 
        child: Center(
            child: Text(
            title,
            style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            ),
        ),
      ),
    );
  }
}
