import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/space.dart';
import '../../domain/entities/host.dart';
import '../../domain/repositories/host_repository.dart';
import '../reservations/reservation_screen.dart';
import '../host/host_detail_screen.dart';
import '../host/viewmodel/host_viewmodel.dart';
import '../reviews/review_screen.dart'; 

import '../../../data/services/review_api.dart';
import '../../../data/repositories/review_repository_impl.dart';
import '../../../domain/repositories/review_repository.dart';
import '../../../domain/entities/review.dart';
import 'package:dio/dio.dart';
import 'viewmodel/review_summary_viewmodel.dart';

class SpaceDetailScreen extends StatefulWidget {
  final Space space;

  const SpaceDetailScreen({
    super.key,
    required this.space,
  });

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hostViewModel = Provider.of<HostViewModel>(context, listen: false);
      hostViewModel.clearHost();
      hostViewModel.loadHostBySpaceId(widget.space.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _bottomBar(context),
      body: SafeArea(
        child: ChangeNotifierProvider(
          create: (_) {
            final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000'));
            final repo = ReviewRepositoryImpl(ReviewApi(dio));
            final vm = ReviewSummaryViewModel(repo);
            vm.loadReviewSummary(widget.space.id);
            return vm;
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen superior
                Stack(
                  children: [
                    Container(
                      height: 240,
                      color: Colors.grey[300],
                      child: widget.space.imageUrl.isNotEmpty
                          ? Image.network(widget.space.imageUrl,
                              fit: BoxFit.cover)
                          : const Center(child: Icon(Icons.image, size: 120)),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),

                // Título y descripción (sin rating visual)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.space.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(widget.space.subtitle ?? "Sin descripción",
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 6),
                      Text(
                        "${widget.space.capacity} capacity",
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Amenities
                _sectionTitle(context, "Amenities"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: widget.space.amenities.isNotEmpty
                        ? widget.space.amenities
                            .map(
                                (a) => _AmenityRow(icon: Icons.check, label: a))
                            .toList()
                        : [const Text("No amenities listed")],
                  ),
                ),

                const Divider(),

                // Estadísticas mock
                _buildStatsSection(context),

                const Divider(),

                // Host section
                _sectionTitle(context, "Meet your host"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Consumer<HostViewModel>(
                    builder: (context, hostViewModel, child) {
                      if (hostViewModel.isLoading ||
                          hostViewModel.error != null ||
                          hostViewModel.currentHost == null) {
                        return _buildHostCardPlaceholder();
                      }
                      return _buildHostCard(hostViewModel.currentHost!);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _navigateToHostDetail(context),
                    child: const Text("Contact host",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),

                const Divider(),

                // About
                _sectionTitle(context, "About this place"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(widget.space.rules,
                      style: const TextStyle(fontSize: 16, height: 1.4)),
                ),

                const Divider(),

                // Reviews dinámicas
                Consumer<ReviewSummaryViewModel>(
                  builder: (context, vm, _) {
                    final rating = vm.averageRating.toStringAsFixed(1);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(context, "★ $rating · Reviews"),
                        const SizedBox(height: 8),
                        if (vm.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (vm.featuredReview != null)
                          _buildReviewCard(vm.featuredReview!)
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text("No hay reviews aún."),
                          ),
                        const SizedBox(height: 16),
                        Center(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              side: const BorderSide(color: Colors.black),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReviewScreen(spaceId: widget.space.id),
                                ),
                              );
                            },
                            child: Text(
                              vm.reviewCount > 0
                                  ? "Show ${vm.reviewCount} reviews"
                                  : "Show reviews",
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------- Review Card --------------------
  Widget _buildReviewCard(Review review) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "“${review.text}”",
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              "Review destacada",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? "Usuario",
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      review.userEmail ?? "",
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- Bottom Bar --------------------
  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("COP \$${widget.space.price.toStringAsFixed(0)}/hour",
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReservationScreen(
                    spaceTitle: widget.space.title,
                    spaceAddress:
                        '123 Business District, Suite 456, City Center',
                    spaceRating: widget.space.rating,
                    reviewCount: 127,
                    pricePerHour: widget.space.price,
                    spaceId: widget.space.id,
                  ),
                ),
              );
            },
            child: const Text("Reserve",
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // -------------------- Navegación --------------------
  void _navigateToHostDetail(BuildContext context) {
    final hostViewModel = Provider.of<HostViewModel>(context, listen: false);
    hostViewModel.loadHostBySpaceId(widget.space.id);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const HostDetailScreen()),
    );
  }

  // -------------------- Sección genérica --------------------
  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
    );
  }

  // -------------------- Host --------------------
  Widget _buildHostCardPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: const [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 34, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text("Cargando...",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text("Obteniendo información del host",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHostCard(Host host) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Column(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 34, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(host.firstName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Host · ${host.monthsHosting} months hosting",
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HostStat(value: "${host.totalReviews}", label: "Reviews"),
              const SizedBox(width: 20),
              _HostStat(
                  value: "${host.averageRating.toStringAsFixed(1)}",
                  label: "Rating"),
              const SizedBox(width: 20),
              const _HostStat(value: "95%", label: "Response rate"),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------- Stats Mock --------------------
  Widget _buildStatsSection(BuildContext context) {
    final chips = const [
      ['07:00', 2],
      ['08:00', 2],
      ['14:00', 1],
      ['15:00', 1],
    ];
    final barHeights = <double>[0.0, 1.0, 1.0, 0.6, 0.0, 0.0];
    final xLabels = const ['6a', '9a', '12p', '3p', '6p', '9p'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, "Horas más reservadas (semana)"),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in chips)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InputChip(
                      label: Text('${c[0]}  x${c[1]}'),
                      backgroundColor: const Color(0xFFF2E7FE),
                      labelStyle:
                          const TextStyle(color: Color(0xFF5C1B6C)),
                      onPressed: () {},
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Tap hours for details',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          _BarsChart(heights: barHeights, labels: xLabels, maxHeight: 140),
          const SizedBox(height: 6),
          const Text('Tope visual en 10 reservas por hora',
              style: TextStyle(fontSize: 12, color: Colors.black45)),
        ],
      ),
    );
  }
}

// -------------------- Reusables --------------------
class _AmenityRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AmenityRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 28, color: Colors.black87),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _HostStat extends StatelessWidget {
  final String value;
  final String label;

  const _HostStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _BarsChart extends StatelessWidget {
  final List<double> heights;
  final List<String> labels;
  final double maxHeight;

  const _BarsChart(
      {required this.heights, required this.labels, this.maxHeight = 140});

  @override
  Widget build(BuildContext context) {
    const barWidth = 14.0;
    const barColor = Color(0xFF8155BA);

    return SizedBox(
      height: maxHeight + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < heights.length; i++)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: barWidth,
                  height: (heights[i].clamp(0.0, 1.0)) * maxHeight,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(labels[i],
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
              ],
            ),
        ],
      ),
    );
  }
}
