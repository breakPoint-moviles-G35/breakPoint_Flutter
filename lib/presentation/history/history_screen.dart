import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/domain/repositories/reservation_repository.dart';
import 'package:breakpoint/domain/repositories/review_repository.dart';
import 'package:breakpoint/domain/repositories/auth_repository.dart';
import 'package:breakpoint/domain/entities/reservation.dart';
import 'package:breakpoint/presentation/widgets/space_card.dart';
import 'package:breakpoint/routes/app_router.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isLoading = false;
  String? error;
  List<Reservation> historyReservations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final reservationRepo = context.read<ReservationRepository>();
      final reviewRepo = context.read<ReviewRepository>();
      final authRepo = context.read<AuthRepository>();
      final currentUser = authRepo.currentUser;

      if (currentUser == null) {
        setState(() {
          error = 'Usuario no autenticado';
          isLoading = false;
        });
        return;
      }

      // Obtener todas las reservas cerradas
      final closedReservations = await reservationRepo.getClosedReservations();

      // Filtrar las que tienen review del usuario actual
      final reservationsWithReview = <Reservation>[];
      
      for (final reservation in closedReservations) {
        try {
          // Obtener todas las reviews del espacio
          final reviews = await reviewRepo.getReviewsBySpace(reservation.spaceId);
          
          // Verificar si el usuario actual tiene una review para este espacio
          final hasUserReview = reviews.any((review) => review.userId == currentUser.id);
          
          if (hasUserReview) {
            reservationsWithReview.add(reservation);
          }
        } catch (e) {
          // Si hay error al obtener reviews, ignorar esta reserva
          print('Error al verificar reviews para espacio ${reservation.spaceId}: $e');
        }
      }

      setState(() {
        historyReservations = reservationsWithReview;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error al cargar historial: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Reservas'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Builder(builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          
          if (historyReservations.isEmpty) {
            return const Center(
              child: Text(
                'No tienes reservas en tu historial aún.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: historyReservations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final r = historyReservations[i];
              return SpaceCard(
                title: r.spaceTitle,
                subtitle: _formatSlot(r),
                rating: 0,
                priceCOP: r.totalAmount,
                originalPriceCOP: r.discountApplied ? r.baseSubtotal : null,
                rightTag: 'Completada',
                imageAspectRatio: 16 / 9,
                imageUrl: r.spaceImageUrl,
                metaLines: [
                  'Total: ${r.currency} ${r.totalAmount.toStringAsFixed(0)}',
                  if (r.discountApplied)
                    'Descuento aplicado: ${r.discountPercent.toStringAsFixed(0)}%',
                ],
                onTap: () {},
              );
            },
          );
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        onDestinationSelected: (i) {
          if (i == 0) {
            Navigator.pushReplacementNamed(context, AppRouter.explore);
          } else if (i == 1) {
            Navigator.pushReplacementNamed(context, AppRouter.rate);
          } else if (i == 2) {
            Navigator.pushReplacementNamed(context, AppRouter.reservations);
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
    return '$t · $day';
  }
}

