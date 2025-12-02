import 'dart:async';
import 'dart:convert';
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

class RateScreen extends StatefulWidget {
  const RateScreen({super.key});

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  bool isLoading = false;
  String? error;
  bool isOffline = false;
  List<Reservation> closed = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

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
      setState(() { isLoading = true; error = null; });
      
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
          setState(() {
            closed = cached;
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
      final allClosed = await reservationRepo.getClosedReservations();

      // Filtrar solo las que NO tienen review del usuario actual
      final closedWithoutReview = <Reservation>[];
      
      for (final reservation in allClosed) {
        try {
          // Obtener todas las reviews del espacio
          final reviews = await reviewRepo.getReviewsBySpace(reservation.spaceId);
          
          // Verificar si el usuario actual tiene una review para este espacio
          final hasUserReview = reviews.any((review) => review.userId == currentUser.id);
          
          // Solo agregar si NO tiene review
          if (!hasUserReview) {
            closedWithoutReview.add(reservation);
          }
        } catch (e) {
          // Si hay error al obtener reviews, asumir que no tiene review y agregar
          print('Error al verificar reviews para espacio ${reservation.spaceId}: $e');
          closedWithoutReview.add(reservation);
        }
      }

      // Guardar en cache
      await _saveToCache(closedWithoutReview);

      setState(() {
        closed = closedWithoutReview;
        error = null;
        isLoading = false;
      });
    } catch (e) {
      // Intentar cargar desde cache si hubo error
      final cached = await _loadFromCache();
      if (cached.isNotEmpty) {
        setState(() {
          closed = cached;
          error = null;
          isOffline = true;
        });
      } else {
        setState(() {
          error = 'Error al cargar reservas cerradas: $e';
          isOffline = true;
        });
      }
      if (mounted) setState(() { isLoading = false; });
    }
  }

  Future<void> _saveToCache(List<Reservation> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items.map((r) => r.toJson()).toList();
      await prefs.setString('cached_rate_reservations', jsonEncode(list));
      await prefs.setInt(
        'cached_rate_reservations_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<List<Reservation>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cached_rate_reservations');
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
        closed = cached;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate your stays'),
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
                      onPressed: () => _openCreateReview(context, r),
                      child: const Text('Crear review'),
                    ),
                  ),
                ],
              );
            },
          );
              }),
            ),
          ),
        ],
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

  Future<void> _openCreateReview(BuildContext context, Reservation r) async {
    final textCtrl = TextEditingController();
    int rating = 0;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(builder: (ctx, setMState) {
          Future<void> submit() async {
            // Validar 50 palabras máx
            final words = textCtrl.text.trim().split(RegExp(r"\s+")).where((w) => w.isNotEmpty).toList();
            if (words.length > 50) {
              setMState(() => error = 'Máximo 50 palabras');
              return;
            }
            if (rating == 0) {
              setMState(() => error = 'Selecciona un rating');
              return;
            }
            try {
              final reviewRepo = context.read<ReviewRepository>();
              await reviewRepo.createReview(
                spaceId: r.spaceId,
                text: textCtrl.text.trim(),
                rating: rating.toString(),
              );
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review creada correctamente')),
                );
                // Recargar la lista para que la reserva desaparezca de rate
                _load();
              }
            } catch (e) {
              setMState(() => error = 'Error al crear review: $e');
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                      const SizedBox(width: 8),
                      const Text('Rate your experience',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Campo texto
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Review'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: textCtrl,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Estrellas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    return IconButton(
                      onPressed: () => setMState(() => rating = idx),
                      icon: Icon(
                        idx <= rating ? Icons.star : Icons.star_border,
                        color: Colors.black87,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                if (error != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(error!, style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 8),
                ],
                // Botón
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: submit,
                      child: const Text('Send'),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}


