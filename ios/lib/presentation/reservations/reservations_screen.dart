import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/routes/app_router.dart';
import 'package:breakpoint/presentation/widgets/offline_banner.dart';
import 'package:breakpoint/presentation/widgets/space_card.dart';
import 'package:breakpoint/presentation/reservations/viewmodel/reservations_viewmodel.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  bool _isListeningForNfc = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNfcListening();
    });
  }

  void _startNfcListening() async {
    if (_isListeningForNfc) return;

    _isListeningForNfc = true;
    final vm = context.read<ReservationsViewModel>();

    // Listen for NFC tags while on this screen
    while (mounted && _isListeningForNfc) {
      try {
        final result = await vm.startNfcListening();

        if (result != null && mounted && _isListeningForNfc) {
          // NFC tag detected, show confirmation dialog
          _showCloseReservationDialog();
          // Wait before listening again to avoid multiple dialogs
          await Future.delayed(const Duration(seconds: 3));
        }
      } catch (e) {
        // Error in NFC reading, wait a bit and try again
        if (mounted && _isListeningForNfc) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }

  void _showCloseReservationDialog() {
    final vm = context.read<ReservationsViewModel>();
    final reservation = vm.getMostProximalReservation();

    if (reservation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay reservas activas para cerrar')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Reserva'),
        content: Text(
          '¿Deseas cerrar la reserva de "${reservation.spaceTitle}" '
          'programada para ${reservation.formattedDate} a las ${reservation.formattedTimeRange}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close confirmation dialog first
              Navigator.of(dialogContext).pop();

              // Show loading indicator with scaffold context
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              bool success = false;
              try {
                success = await vm.closeMostProximalReservation();
              } catch (e) {
                // Handle any unexpected errors
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop(); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error inesperado: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              // Close loading dialog
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pop();

                // Show result message
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reserva cerrada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(vm.error ?? 'Error al cerrar la reserva'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Sí, Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isListeningForNfc = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationsViewModel>();
    vm.init();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas Activas'),
        centerTitle: true,
        actions: [
          if (vm.isOffline)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.cloud_off, color: Colors.redAccent),
            ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Banner de desconexión
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: vm.isOffline
                ? OfflineBanner(onRetry: vm.retry)
                : const SizedBox.shrink(),
          ),

          Expanded(
            child: Builder(builder: (_) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (vm.error != null && vm.reservations.isEmpty) {
                return Center(child: Text(vm.error!));
              }

              if (vm.reservations.isEmpty) {
                return const Center(
                  child: Text('No tienes reservas activas.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                itemCount: vm.reservations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final r = vm.reservations[i];
                  return Column(
                    children: [
                      SpaceCard(
                        title: r.spaceTitle,
                        subtitle:
                        '${r.formattedDate} • ${r.formattedTimeRange}',
                        rating: 0,
                        priceCOP: r.totalAmount,
                        rightTag: r.statusText,
                        imageAspectRatio: 16 / 9,
                        imageUrl: r.spaceImageUrl,
                        onTap: () {},
                      ),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (i) {
          if (i == 0) {
            Navigator.pushReplacementNamed(context, AppRouter.explore);
          } else if (i == 1) {
            Navigator.pushReplacementNamed(context, AppRouter.rate);
          } else if (i == 3) {
            Navigator.pushReplacementNamed(context, AppRouter.profile);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: 'Rate'),
          NavigationDestination(
              icon: Icon(Icons.event_note_outlined), label: 'Reservations'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}