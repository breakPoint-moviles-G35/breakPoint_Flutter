import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:breakpoint/domain/repositories/reservation_repository.dart';
import 'package:breakpoint/domain/repositories/review_repository.dart';
import 'package:breakpoint/domain/repositories/auth_repository.dart';
import 'package:breakpoint/domain/entities/reservation.dart';
import 'package:breakpoint/presentation/widgets/space_card.dart';
import 'package:breakpoint/presentation/widgets/offline_banner.dart';
import 'package:breakpoint/routes/app_router.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isLoading = false;
  String? error;
  bool isOffline = false;
  List<Reservation> historyReservations = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // 🔹 Estadísticas calculadas en isolate
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _load();
  }

  void _initConnectivity() {
    Connectivity().checkConnectivity().then((status) {
      setState(() {
        isOffline = status.contains(ConnectivityResult.none);
      });
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final hasNet = !result.contains(ConnectivityResult.none);
      if (hasNet && isOffline) {
        setState(() => isOffline = false);
        _load();
      } else if (!hasNet) {
        setState(() => isOffline = true);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
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

      // Verificar conectividad
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet = !connectivity.contains(ConnectivityResult.none);
      setState(() => isOffline = !hasInternet);

      if (!hasInternet) {
        // Sin internet: cargar desde cache
        final cached = await _loadFromCache();
        if (cached.isNotEmpty) {
          // Calcular estadísticas desde cache
          await _calculateStats(cached);
          setState(() {
            historyReservations = cached;
            error = null;
            isLoading = false;
          });
          return;
        } else {
          setState(() {
            error = 'Sin conexión y sin datos guardados.';
            isLoading = false;
          });
          return;
        }
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

      // Guardar en cache
      await _saveToCache(reservationsWithReview);

      // 🔹 ESTRATEGIA DE MULTI-THREADING: Calcular estadísticas en isolate
      if (reservationsWithReview.isNotEmpty) {
        await _calculateStats(reservationsWithReview);
      }

      setState(() {
        historyReservations = reservationsWithReview;
        error = null;
        isLoading = false;
      });
    } catch (e) {
      // Intentar cargar desde cache si hubo error
      final cached = await _loadFromCache();
      if (cached.isNotEmpty) {
        // Calcular estadísticas desde cache
        await _calculateStats(cached);
        setState(() {
          historyReservations = cached;
          error = null;
          isOffline = true;
        });
      } else {
        setState(() {
          error = 'Error al cargar historial: $e';
          isOffline = true;
        });
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveToCache(List<Reservation> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items.map((r) => r.toJson()).toList();
      await prefs.setString('cached_history_reservations', jsonEncode(list));
      await prefs.setInt(
        'cached_history_reservations_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<List<Reservation>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cached_history_reservations');
      if (jsonStr == null || jsonStr.isEmpty) return [];

      final list = jsonDecode(jsonStr) as List;
      return list.map((json) => Reservation.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _retry() async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasNetwork = !connectivity.contains(ConnectivityResult.none);
    setState(() => isOffline = !hasNetwork);
    if (hasNetwork) {
      await _load();
    } else {
      final cached = await _loadFromCache();
      setState(() {
        historyReservations = cached;
      });
      if (cached.isNotEmpty) {
        await _calculateStats(cached);
      }
    }
  }

  /// 🔹 Calcula estadísticas usando isolate para no bloquear el hilo principal
  Future<void> _calculateStats(List<Reservation> reservations) async {
    try {
      // Preparar datos serializables para el isolate
      final reservationsData = reservations.map((r) => {
        'dayOfWeek': r.slotStart.weekday, // 1=Lunes, 7=Domingo
        'hour': r.slotStart.hour,
        'totalAmount': r.totalAmount,
      }).toList();

      // Procesar en isolate
      final stats = await Isolate.run<Map<String, dynamic>>(() {
        return _processStatsInIsolate(reservationsData);
      });

      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      print('Error al calcular estadísticas: $e');
    }
  }

  /// 🔹 Función estática que se ejecuta en el isolate
  /// Procesa las estadísticas de reservas sin bloquear el hilo principal
  static Map<String, dynamic> _processStatsInIsolate(List<Map<String, dynamic>> reservationsData) {
    if (reservationsData.isEmpty) {
      return {
        'totalSpent': 0.0,
        'favoriteDays': [],
        'favoriteHours': [],
      };
    }

    // 1. Gastos totales
    double totalSpent = 0.0;
    for (final r in reservationsData) {
      totalSpent += (r['totalAmount'] as num).toDouble();
    }

    // 2. Días favoritos (día de la semana)
    final Map<int, int> dayCount = {};
    for (final r in reservationsData) {
      final day = r['dayOfWeek'] as int;
      dayCount[day] = (dayCount[day] ?? 0) + 1;
    }

    // Encontrar días favoritos (puede haber empate)
    final dayEntries = dayCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final maxDayCount = dayEntries.isNotEmpty ? dayEntries.first.value : 0;
    final favoriteDays = dayEntries
        .where((e) => e.value == maxDayCount)
        .map((e) => e.key)
        .toList();

    // 3. Horas favoritas
    final Map<int, int> hourCount = {};
    for (final r in reservationsData) {
      final hour = r['hour'] as int;
      hourCount[hour] = (hourCount[hour] ?? 0) + 1;
    }

    final hourEntries = hourCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final maxHourCount = hourEntries.isNotEmpty ? hourEntries.first.value : 0;
    final favoriteHours = hourEntries
        .where((e) => e.value == maxHourCount)
        .map((e) => e.key)
        .toList()
      ..sort();

    return {
      'totalSpent': totalSpent,
      'favoriteDays': favoriteDays,
      'favoriteHours': favoriteHours,
    };
  }

  String _formatDayOfWeek(int day) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[day - 1];
  }

  String _formatFavoriteDays(List<int> days) {
    if (days.isEmpty) return 'N/A';
    if (days.length == 1) {
      return _formatDayOfWeek(days.first);
    }
    // Si hay empate, mostrar varios días
    return days.map((d) => _formatDayOfWeek(d)).join(', ');
  }

  String _formatFavoriteHours(List<int> hours) {
    if (hours.isEmpty) return 'N/A';
    if (hours.length == 1) {
      return '${hours.first.toString().padLeft(2, '0')}:00';
    }
    // Si hay empate o no se repite una hora específica, mostrar rango
    hours.sort();
    final min = hours.first;
    final max = hours.last;
    if (max - min <= 2) {
      // Si están cerca, mostrar todas
      return hours.map((h) => '${h.toString().padLeft(2, '0')}:00').join(', ');
    } else {
      // Si están lejos, mostrar rango
      return '${min.toString().padLeft(2, '0')}:00 - ${max.toString().padLeft(2, '0')}:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Reservas'),
        centerTitle: true,
        actions: [
          if (isOffline)
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
            child: isOffline
                ? OfflineBanner(onRetry: _retry)
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: RefreshIndicator(
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

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            children: [
              // 🔹 Sección de estadísticas
              if (_stats != null) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estadísticas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5C1B6C),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          Icons.attach_money,
                          'Gastos totales',
                          '\$${(_stats!['totalSpent'] as num).toStringAsFixed(0)} COP',
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          Icons.calendar_today,
                          'Días favoritos',
                          _formatFavoriteDays(
                            List<int>.from(_stats!['favoriteDays'] as List),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          Icons.access_time,
                          'Hora favorita',
                          _formatFavoriteHours(
                            List<int>.from(_stats!['favoriteHours'] as List),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Lista de reservas
              ...historyReservations.asMap().entries.map((entry) {
                final index = entry.key;
                final r = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < historyReservations.length - 1 ? 16 : 0,
                  ),
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
              }),
            ],
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

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5C1B6C)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5C1B6C),
          ),
        ),
      ],
    );
  }
}

