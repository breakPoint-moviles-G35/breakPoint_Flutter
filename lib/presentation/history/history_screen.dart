import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/domain/entities/reservation.dart';
import 'package:breakpoint/presentation/widgets/space_card.dart';
import 'package:breakpoint/presentation/widgets/offline_banner.dart';
import 'package:breakpoint/presentation/history/viewmodel/history_viewmodel.dart';
import 'package:breakpoint/routes/app_router.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<HistoryViewModel>();
      vm.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Reservas'),
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
          // Banner de desconexión
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: vm.isOffline
                ? OfflineBanner(onRetry: vm.retry)
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.load,
              child: Builder(builder: (context) {
                if (vm.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (vm.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        vm.error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                
                if (vm.historyReservations.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tienes reservas en tu historial aún.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: vm.historyReservations.length + (vm.stats != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Mostrar estadísticas como primer item (barra superior)
                    if (vm.stats != null && index == 0) {
                      return _HistoryStatsHeader(stats: vm.stats!);
                    }
                    
                    // Ajustar índice para las reservas
                    final reservationIndex = vm.stats != null ? index - 1 : index;
                    final r = vm.historyReservations[reservationIndex];
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SpaceCard(
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
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
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


/// 🔹 Widget para mostrar estadísticas como barra superior (similar a Host)
class _HistoryStatsHeader extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _HistoryStatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final favoriteDays = List<int>.from(stats['favoriteDays'] as List);
    final favoriteHours = List<int>.from(stats['favoriteHours'] as List);
    
    String formatDayOfWeek(int day) {
      const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return days[day - 1];
    }
    
    String formatFavoriteDays(List<int> days) {
      if (days.isEmpty) return 'N/A';
      if (days.length == 1) {
        return formatDayOfWeek(days.first);
      }
      return days.map((d) => formatDayOfWeek(d)).join(', ');
    }
    
    String formatFavoriteHours(List<int> hours) {
      if (hours.isEmpty) return 'N/A';
      if (hours.length == 1) {
        return '${hours.first.toString().padLeft(2, '0')}:00';
      }
      hours.sort();
      final min = hours.first;
      final max = hours.last;
      if (max - min <= 2) {
        return hours.map((h) => '${h.toString().padLeft(2, '0')}:00').join(', ');
      } else {
        return '${min.toString().padLeft(2, '0')}:00 - ${max.toString().padLeft(2, '0')}:00';
      }
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _StatItem(
                  label: "Días favoritos",
                  value: formatFavoriteDays(favoriteDays),
                  color: const Color(0xFF5C1B6C),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: "Hora favorita",
                  value: formatFavoriteHours(favoriteHours),
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 🔹 NO usar Expanded aquí porque ya está dentro de un Expanded en el Row
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

