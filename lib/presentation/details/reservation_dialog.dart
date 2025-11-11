import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:breakpoint/core/constants/api_constants.dart';
import '../../domain/entities/space.dart';
import '../../data/repositories/reservation_repository_impl.dart';
import '../../routes/app_router.dart';
import '../../data/services/reservation_api.dart';


class ReservationDialog extends StatefulWidget {
  final Space space;

  const ReservationDialog({super.key, required this.space});

  @override
  State<ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<ReservationDialog> {
  final _guestController = TextEditingController(text: '1');
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isLoading = false;

  // Selección de hora
  
  Future<void> _pickStartTime(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (picked != null) {
      final selected = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      setState(() => _startTime = selected);
    }
  }

  Future<void> _pickEndTime(BuildContext context) async {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona la hora de inicio')),
      );
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(_startTime!.add(const Duration(hours: 1))),
    );
    if (picked != null) {
      final selected = DateTime(
        _startTime!.year,
        _startTime!.month,
        _startTime!.day,
        picked.hour,
        picked.minute,
      );
      setState(() => _endTime = selected);
    }
  }
  
  // Enviar reserva al backend
  
  Future<void> _confirmReservation(BuildContext context) async {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona horario de inicio y fin')),
      );
      return;
    }

    final guestCount = int.tryParse(_guestController.text) ?? 1;

    setState(() => _isLoading = true);

    try {
      
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)); 
      final api = ReservationApi(dio);
      final repo = ReservationRepositoryImpl(api);

      await repo.createReservation(
        spaceId: widget.space.id,
        slotStart: _startTime!.toIso8601String(),
        slotEnd: _endTime!.toIso8601String(),
        guestCount: guestCount,
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reserva confirmada para ${widget.space.title}!'),
          ),
        );
        Navigator.pushReplacementNamed(context, AppRouter.reservations);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la reserva: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

 
  // Formato de hora sin intl
  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    final timeOfDay = TimeOfDay.fromDateTime(dateTime);
    return timeOfDay.format(context);
  }

  @override
  Widget build(BuildContext context) {
    final space = widget.space;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
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
                  const Text(
                    "New Reservation",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const Divider(),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  space.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),

              // Precio
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Precio por hora:",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    "COP \$${space.price.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cantidad de invitados
              TextField(
                controller: _guestController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de invitados',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Selección de hora
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickStartTime(context),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                        _startTime == null ? "Inicio" : _formatTime(_startTime)),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickEndTime(context),
                    icon: const Icon(Icons.timer_off),
                    label: Text(
                        _endTime == null ? "Fin" : _formatTime(_endTime)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botón confirmar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _confirmReservation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Confirm reservation",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
