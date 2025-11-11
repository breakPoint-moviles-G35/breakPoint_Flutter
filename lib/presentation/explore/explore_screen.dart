import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:breakpoint/routes/app_router.dart';
import 'package:breakpoint/presentation/widgets/space_card.dart';
import 'package:breakpoint/presentation/widgets/recommendation_card.dart';
import 'package:breakpoint/presentation/details/space_detail_screen.dart';
import 'package:breakpoint/presentation/explore/viewmodel/explore_viewmodel.dart';
import 'package:breakpoint/presentation/widgets/offline_banner.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  Future<void> _openFilters(BuildContext context, ExploreViewModel vm) async {
    final picked = await Navigator.pushNamed(context, AppRouter.filters) as DateTimeRange?;
    if (picked != null) {
      vm.setStartEndFromRange(picked); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExploreViewModel>();
    vm.init();

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
          if (vm.isOffline)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.cloud_off, color: Colors.redAccent, size: 22),
            ),
          IconButton(
            onPressed: () => _openFilters(context, vm),
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
          ),
          const SizedBox(width: 4),
        ],
        centerTitle: true,
      ),
      body: (vm.isLoading || vm.isLoadingRecommendations)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Sección de recomendaciones
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
                    // Indicadores de página
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

            // Sección de filtros y controles
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                        onPressed: vm.toggleSort,
                        child: const Text('Ordenar por precio'),
                      ),
                      const SizedBox(width: 8),
                      if (vm.hasRange)
                        InputChip(
                          label: Text(
                            '${vm.fmtIsoDay(vm.start!)} – ${vm.fmtIsoDay(vm.end!)}',
                          ),
                          onDeleted: () => vm.setStartEndFromRange(null),
                        ),
                    ],
                  ),
                  // 🔹 Nuevo botón "Ver mapa"
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.map);
                    },
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Ver mapa'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5C1B6C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ⬇️ Banner de “Desconectado” justo arriba de la lista
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: vm.isOffline
                  ? OfflineBanner(onRetry: vm.retry)
                  : const SizedBox.shrink(),
            ),

            // Título "Todos los espacios"
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

            // Lista de espacios
            Builder(
              builder: (_) {
                if (vm.isLoading) return const Center(child: CircularProgressIndicator());

                // Mostrar error SOLO si no hay espacios para enseñar
                if (vm.spaces.isEmpty) {
                  if (vm.isOffline) {
                    if (vm.error != null && vm.error!.toLowerCase().contains('cach')) {
                      return const Center(child: Text('Sin conexión y sin datos guardados.'));
                    } else {
                      // Puede estar offline pero sin error de cache
                      return const Center(child: Text('Sin conexión. No hay espacios para mostrar.'));
                    }
                  } else if (vm.error != null) {
                    // Error técnico SOLO si no hay espacios y no es por falta de conexión
                    return Center(child: Text('Error de conexión. Intenta de nuevo más tarde.'));
                  } else {
                    return const Center(child: Text('No hay espacios disponibles en el momento. Intenta más tarde.'));
                  }
                }

                // Si hay espacios, muestra la lista y nunca muestra el error de conexión
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
          if (i == 1) {
            Navigator.pushReplacementNamed(context, AppRouter.rate);
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
}
