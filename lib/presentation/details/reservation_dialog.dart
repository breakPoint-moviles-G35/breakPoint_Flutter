import 'package:flutter/material.dart';
import '../../routes/app_router';

class ReservationDialog extends StatelessWidget {
  const ReservationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text("Reservation",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 40),
              ],
            ),
            const Divider(),

            const SizedBox(height: 8),
            const Center(
              child: Text("Details",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),

            // Info de reserva ficticia
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Loft Bogotá · 2 hours",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                Text("COP \$40,000",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Reserved hours",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                Text("2:30 PM – 4:30 PM",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Host contact",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                Text("+57 300 123 4567",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple)),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, // Botón morado
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 28),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, AppRouter.reservations);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Reservation confirmed for Loft Bogotá!")),
                  );
                },
                child: const Text("Confirm reservation",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
