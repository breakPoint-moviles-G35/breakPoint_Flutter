import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:breakpoint/domain/repositories/reservation_repository.dart';
import 'package:breakpoint/domain/entities/reservation.dart';

class NfcScanScreen extends StatefulWidget {
  const NfcScanScreen({super.key});

  @override
  State<NfcScanScreen> createState() => _NfcScanScreenState();
}

class _NfcScanScreenState extends State<NfcScanScreen> {
  bool isScanning = false;
  String? lastMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan NFC')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isScanning)
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: CircularProgressIndicator(),
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.nfc),
              label: const Text('Escanear NFC'),
              onPressed: isScanning ? null : _scan,
            ),
            if (lastMessage != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(lastMessage!, textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _scan() async {
    final repo = context.read<ReservationRepository>();
    setState(() { isScanning = true; lastMessage = null; });

    try {
      final available = await NfcManager.instance.isAvailable();
      if (!available) {
        setState(() { lastMessage = 'NFC no disponible en este dispositivo'; });
        return;
      }

      await NfcManager.instance.startSession(onDiscovered: (tag) async {
        try {
          // Leer payload (opcional)
          final ndef = Ndef.from(tag);
          if (ndef?.cachedMessage != null && ndef!.cachedMessage!.records.isNotEmpty) {
            final rec = ndef.cachedMessage!.records.first;
            final payload = utf8.decode(rec.payload);
            lastMessage = 'Tag leído: $payload';
          }

          // Consultar reservas activas ahora
          final actives = await repo.getActiveNow();
          if (actives.isEmpty) {
            if (!mounted) return;
            await _showInfo('No tiene reservas activas en este momento.');
          } else {
            // Tomar la primera para el ejemplo; en real, podríamos elegir por space
            final Reservation r = actives.first;
            if (!mounted) return;
            final confirm = await _confirmCheckout(r.spaceTitle);
            if (confirm == true) {
              await repo.checkoutReservation(r.id);
              if (!mounted) return;
              await _showInfo('Checkout realizado correctamente');
            }
          }
        } finally {
          await NfcManager.instance.stopSession();
          if (mounted) setState(() { isScanning = false; });
        }
      });
    } catch (e) {
      setState(() { lastMessage = 'Error al leer NFC: $e'; });
    } finally {
      setState(() { isScanning = false; });
    }
  }

  Future<void> _showInfo(String msg) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<bool?> _confirmCheckout(String spaceTitle) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Checkout'),
        content: Text('¿Desea hacer el checkout de la habitación "$spaceTitle"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
  }
}


