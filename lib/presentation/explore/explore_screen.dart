import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/presentation/widgets/offline_banner.dart';

import 'package:breakpoint/routes/app_router.dart';
import 'package:breakpoint/presentation/widgets/space_card.dart';
import 'package:breakpoint/presentation/widgets/recommendation_card.dart';
import 'package:breakpoint/presentation/details/space_detail_screen.dart';
import 'package:breakpoint/presentation/explore/viewmodel/explore_viewmodel.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  Future<void> _openFilters(BuildContext context, ExploreViewModel vm) async {
    final picked = await Navigator.pushNamed(context, AppRouter.filters) as DateTimeRange?;
    if (picked != null) {
      vm.setStartEndFromRange(picked);
    }
  }

  // ============================================================
  // BottomSheet — Últimos vistos (SIN IMÁGENES)
  // ============================================================
  Widget _buildLastViewedSheet(BuildContext context, ExploreViewModel vm) {
    final items = vm.lastViewed;

    if (items.isEmpty) {
      return SizedBox(
        height: 200,
        child: const Center(
          child: Text(
            "No hay espacios vistos recientemente",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final s = items[i];
          return ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.meeting_room, size: 28, color: Colors.black54),
            ),
            title: Text(s.title),
            subtitle: Text(s.subtitle ?? ''),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SpaceDetailScreen(space: s),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExploreViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              const Icon(Icons.search, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: vm.searchCtrl,
                  onChanged: vm.onQueryChanged,
                  decoration: const InputDecoration(
                    hintText: 'Buscar...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                tooltip: 'Scan',
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _openFilters(context, vm),
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
          ),
          const SizedBox(width: 4),
        ],
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Banner de desconexión
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: vm.isOffline
                  ? OfflineBanner(
                      onRetry: vm.retry,
                      message: 'Sin conexión. Mostrando espacios guardados.',
                    )
                  : const SizedBox.shrink(),
            ),

            // ======================================================
            // Recomendaciones
            // ======================================================
            if (vm.recommendations.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Recomendadas para ti',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: 1.2,
                      child: PageView.builder(
                        itemCount: vm.recommendations.length,
                        itemBuilder: (context, index) {
                          final space = vm.recommendations[index];
                          return RecommendationCard(
                            space: space,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SpaceDetailScreen(space: space),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          vm.recommendations.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: index == 0 ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? const Color(0xFF5C1B6C)
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],

            // ======================================================
            // Row con scroll horizontal — botones correctos
            // ======================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Ordenar por precio
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                      onPressed: vm.toggleSort,
                      child: const Text('Ordenar por precio'),
                    ),
                    const SizedBox(width: 8),

                    // Últimos vistos
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                      icon: const Icon(Icons.history, size: 18),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                          ),
                          builder: (_) => _buildLastViewedSheet(context, vm),
                        );
                      },
                      label: const Text('Últimos vistos'),
                    ),
                    const SizedBox(width: 8),

                    // Chip de fechas
                    if (vm.hasRange)
                      Row(
                        children: [
                          InputChip(
                            label: Text(
                              '${vm.fmtIsoDay(vm.start!)} – ${vm.fmtIsoDay(vm.end!)}',
                            ),
                            onDeleted: () => vm.setStartEndFromRange(null),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),

                    // Botón Ver Mapa
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRouter.map);
                      },
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Ver mapa'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5C1B6C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ======================================================
            // Título de sección
            // ======================================================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Todos los espacios',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ======================================================
            // Lista de espacios
            // ======================================================
            Builder(
              builder: (_) {
                if (vm.isLoading) return const Center(child: CircularProgressIndicator());
                if (vm.error != null && vm.spaces.isEmpty) {
                  return Center(child: Text(vm.error!));
                }
                if (vm.spaces.isEmpty) {
                  return const Center(child: Text('No hay espacios disponibles.'));
                }

                return Column(
                  children: vm.spaces.map((s) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SpaceCard(
                        title: s.title,
                        subtitle: s.subtitle ?? '',
                        rating: s.rating,
                        priceCOP: s.price,
                        imageUrl: s.imageUrl,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SpaceDetailScreen(space: s),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 2) {
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
}
