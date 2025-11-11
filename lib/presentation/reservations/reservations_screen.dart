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
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenNfc();
    });
  }

  Future<void> _listenNfc() async {
    if (_listening) return;
    _listening = true;
    final vm = context.read<ReservationsViewModel>();
    while (mounted && _listening) {
      final res = await vm.startNfcListening();
      if (!mounted || !_listening) break;
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC detectado. Usa el botón de checkout si aplica.')),
        );
        await Future.delayed(const Duration(seconds: 2));
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  @override
  void dispose() {
    _listening = false;
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
                  return SpaceCard(
                    title: r.spaceTitle,
                    subtitle: '${r.formattedDate} • ${r.formattedTimeRange}',
                    rating: 0,
                    priceCOP: r.totalAmount,
                    originalPriceCOP: r.discountApplied ? r.baseSubtotal : null,
                    rightTag: r.discountApplied ? '25% OFF' : r.statusText,
                    imageAspectRatio: 16 / 9,
                    imageUrl: r.spaceImageUrl,
                    onTap: () {},
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


