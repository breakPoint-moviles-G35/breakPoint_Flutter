import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/domain/repositories/reservation_repository.dart';
import 'package:breakpoint/domain/entities/reservation.dart';
import 'package:breakpoint/presentation/widgets/space_card.dart';
import 'package:breakpoint/routes/app_router.dart';

class RateScreen extends StatefulWidget {
  const RateScreen({super.key});

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  bool isLoading = false;
  String? error;
  List<Reservation> closed = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() { isLoading = true; error = null; });
      final repo = context.read<ReservationRepository>();
      closed = await repo.getClosedReservations();
    } catch (e) {
      error = 'Error al cargar reservas cerradas: $e';
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate your stays')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Builder(builder: (context) {
          if (isLoading) return const Center(child: CircularProgressIndicator());
          if (error != null) return Center(child: Text(error!));
          if (closed.isEmpty) return const Center(child: Text('No tienes reservas para calificar.'));

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: closed.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final r = closed[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpaceCard(
                    title: r.spaceTitle,
                    subtitle: '',
                    rating: 0,
                    priceCOP: null,
                    metaLines: [
                      _formatSlot(r),
                      'Total: ${r.currency} ${r.totalAmount.toStringAsFixed(0)}',
                    ],
                    rightTag: 'Closed',
                    imageAspectRatio: 16 / 9,
                    imageUrl: r.spaceImageUrl,
                    onTap: () {},
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () {
                        // Placeholder por ahora
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Abrir crear review (pendiente)')),
                        );
                      },
                      child: const Text('Crear review'),
                    ),
                  ),
                ],
              );
            },
          );
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (i) {
          if (i == 0) {
            Navigator.pushReplacementNamed(context, AppRouter.explore);
          } else if (i == 2) {
            Navigator.pushReplacementNamed(context, AppRouter.reservations);
          } else if (i == 3) {
            Navigator.pushReplacementNamed(context, AppRouter.profile);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Rate'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Reservations'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  String _formatSlot(Reservation r) {
    String two(int n) => n.toString().padLeft(2, '0');
    final s = r.slotStart;
    final e = r.slotEnd;
    final day = '${two(s.day)}/${two(s.month)}/${s.year}';
    final t = '${two(s.hour)}:${two(s.minute)} - ${two(e.hour)}:${two(e.minute)}';
    return 'Horas: $t · $day';
  }
}


