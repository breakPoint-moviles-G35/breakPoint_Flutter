import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/space.dart';
import 'viewmodel/host_viewmodel.dart';
import '../../routes/app_router.dart';
import './profile_host_screen.dart';

class HostSpacesScreen extends StatefulWidget {
  const HostSpacesScreen({super.key});

  @override
  State<HostSpacesScreen> createState() => _HostSpacesScreenState();
}

class _HostSpacesScreenState extends State<HostSpacesScreen> {
  int _index = 0; // 0: Espacios, 1: Perfil

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final vm = context.read<HostViewModel>();
      if (vm.currentHost == null) {
        await vm.loadMyHostProfile();
      }
      await vm.loadMySpaces();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HostViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      appBar: _index == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 2,
              title: const Text(
                'Mis Espacios',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C1B6C),
                ),
              ),
              centerTitle: true,
            )
          : null,
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF5C1B6C),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nuevo espacio',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.createSpace);
              },
            )
          : null,
      body: _index == 0
          ? RefreshIndicator(
              onRefresh: () async {
                await vm.loadMySpaces();
              },
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vm.error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              vm.error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : vm.mySpaces.isEmpty
                          ? const Center(
                              child: Text(
                                'Aún no has creado ningún espacio',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: vm.mySpaces.length + 1, 
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  // Mostrar estadísticas generadas por el isolate
                                  if (vm.stats == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return _HostStatsHeader(stats: vm.stats!);
                                }

                                final space = vm.mySpaces[index - 1];
                                return _SpaceCard(space: space);
                              },
                            ),
            )
          : const ProfileHostScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Espacios',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  final Space space;
  const _SpaceCard({required this.space});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Seleccionaste: ${space.title}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: space.imageUrl.isNotEmpty
                    ? Image.network(
                        space.imageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 40,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      space.subtitle ?? 'Sin descripción',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${space.price.toStringAsFixed(0)} / hora',
                      style: const TextStyle(
                        color: Color(0xFF5C1B6C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


///                 WIDGET NUEVO — HEADER DE ESTADÍSTICAS


class _HostStatsHeader extends StatelessWidget {
  final HostSpacesStats stats;

  const _HostStatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: "Espacios",
              value: stats.totalSpaces.toString(),
              color: const Color(0xFF5C1B6C),
            ),
            _StatItem(
              label: "Capacidad",
              value: stats.totalCapacity.toString(),
              color: Colors.blue,
            ),
            _StatItem(
              label: "Precio prom.",
              value: "\$${stats.avgPrice.toStringAsFixed(0)}",
              color: Colors.green,
            ),
            _StatItem(
              label: "Rating prom.",
              value: stats.avgRating.toStringAsFixed(1),
              color: Colors.orange,
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
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
