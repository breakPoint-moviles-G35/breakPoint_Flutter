import 'package:flutter/material.dart';
import 'package:breakpoint/routes/app_router.dart';

class HostHomeScreen extends StatelessWidget {
  const HostHomeScreen({super.key});

  InputDecoration _searchDecoration() => InputDecoration(
        hintText: 'Buscar...',
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.black54, width: 1),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(decoration: _searchDecoration()),
        centerTitle: true,
        toolbarHeight: 64,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  // Por ahora sin acción de navegación
                },
                child: const Text('Crear espacio'),
              ),
            ),
            const SizedBox(height: 16),
            // Placeholder de tarjeta estilo maqueta
            Container(
              height: 120,
              width: 120,
              color: const Color(0xFFE0E0E0),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.star, size: 16),
                SizedBox(width: 4),
                Text('4.96'),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Lorem Ipsum', style: TextStyle(fontWeight: FontWeight.w700)),
            const Text('Address: XXXX', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 2) {
            Navigator.pushReplacementNamed(context, AppRouter.reservations);
          } else if (i == 3) {
            Navigator.pushReplacementNamed(context, AppRouter.profile);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Host'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Rate'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Reservations'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}


