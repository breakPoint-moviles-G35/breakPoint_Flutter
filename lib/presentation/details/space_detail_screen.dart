import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/domain/entities/space.dart';
import 'package:breakpoint/domain/entities/space_detail.dart';
import 'package:breakpoint/domain/repositories/space_repository.dart';
import 'package:breakpoint/routes/app_router.dart';

import 'reservation_dialog.dart';
import 'contact_host_sheet.dart';
import 'package:breakpoint/presentation/reviews/reviews_screen.dart';

class SpaceDetailScreen extends StatefulWidget {
  final Space space;

  const SpaceDetailScreen({super.key, required this.space});

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  SpaceDetail? spaceDetail;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadSpaceDetails();
  }

  Future<void> _loadSpaceDetails() async {
    try {
      final repository = context.read<SpaceRepository>();
      final details = await repository.getSpaceDetails(widget.space.id);
      
      setState(() {
        spaceDetail = details;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSpaceDetails,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final space = spaceDetail?.space ?? widget.space;
    final host = spaceDetail?.host;
    final reviews = spaceDetail?.reviews ?? [];

    return Scaffold(
      bottomNavigationBar: _bottomBar(context, space),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen superior con botón back
              Stack(
                children: [
                  Container(
                    height: 240,
                    color: Colors.grey[300],
                    child: (space.imageUrl.isNotEmpty)
                        ? Image.network(space.imageUrl, fit: BoxFit.cover)
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

              // Título + rating
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(space.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(space.subtitle ?? "Sin descripción",
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 24, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(space.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Text("${space.capacity} capacity",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600])),
                      ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (space.amenities.isNotEmpty)
                      ? space.amenities
                          .map((a) =>
                              _AmenityRow(icon: Icons.check, label: a))
                          .toList()
                      : const [Text("No amenities listed")],
                ),
              ),

              const Divider(),

              // Host section - ahora con datos reales
              if (host != null) ...[
                _sectionTitle(context, "Meet your host"),
                Padding(
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
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.grey,
                          backgroundImage: host.avatarUrl != null
                              ? NetworkImage(host.avatarUrl!)
                              : null,
                          child: host.avatarUrl == null
                              ? const Icon(Icons.person, size: 34, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(host.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          host.displayIsSuperhost 
                              ? "Superhost · ${host.displayMonthsHosting} months hosting"
                              : "Host · ${host.displayMonthsHosting} months hosting",
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _HostStat(
                              value: "${host.displayReviewsCount}", 
                              label: "Reviews"
                            ),
                            const SizedBox(width: 20),
                            // Solo mostrar rating si hay reviews
                            if (host.hasReviews) ...[
                              _HostStat(
                                value: "${host.displayRating?.toStringAsFixed(1) ?? '0.0'} ★", 
                                label: "Rating"
                              ),
                              const SizedBox(width: 20),
                            ],
                            _HostStat(
                              value: "95%", // TODO: agregar campo responseRate al modelo
                              label: "Response rate"
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            showContactHostSheet(
                              context,
                              host: HostProfileView(
                                name: host.displayName,
                                isSuperhost: host.displayIsSuperhost,
                                reviewsCount: host.displayReviewsCount,
                                ratingAvg: host.displayRating ?? 0.0,
                                monthsHosting: host.displayMonthsHosting,
                                born: host.displayBorn,
                                location: host.displayLocation,
                                work: host.displayWork,
                              ),
                            );
                          },
                          child: const Text("Contact host",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
              ],

              // About
              _sectionTitle(context, "About this place"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  space.rules,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),

              const Divider(),

              // Reviews section - ahora con datos reales
              _sectionTitle(
                context, 
                reviews.isNotEmpty 
                  ? "★ ${space.rating.toStringAsFixed(1)} · ${reviews.length} Reviews"
                  : "Reviews"
              ),
              if (reviews.isNotEmpty) ...[
                // Mostrar la primera review como preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              reviews.first.authorName?.substring(0, 1).toUpperCase() ?? '?',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reviews.first.authorName ?? 'Anonymous',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: List.generate(5, (index) => 
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: index < reviews.first.rating 
                                          ? Colors.amber 
                                          : Colors.grey[300],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (reviews.first.comment != null && reviews.first.comment!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          reviews.first.comment!,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "No reviews yet. Be the first to review this space!",
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.reviews,
                      arguments: ReviewsArgs(
                        spaceId: space.id,
                        initialRatingAvg: reviews.isNotEmpty ? space.rating : null,
                        initialTotalReviews: reviews.length,
                      ),
                    );
                  },
                  child: const Text("Show all reviews",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, Space space) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("COP \$${space.price.toStringAsFixed(0)}/night",
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ReservationDialog(space: space),
              );
            },
            child: const Text("Reserve",
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }

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
}

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

