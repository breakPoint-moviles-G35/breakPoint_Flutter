import 'package:flutter/material.dart';
import '../../domain/entities/space.dart';
import '../reservations/reservation_screen.dart';

class SpaceDetailScreen extends StatelessWidget {
  final Space space;

  const SpaceDetailScreen({
    super.key,
    required this.space,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _bottomBar(context),
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
                    child: space.imageUrl.isNotEmpty
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
                        const Icon(Icons.star,
                            size: 24, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          space.rating.toString(),
                          style: const TextStyle(fontSize: 18),
                        ),
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
                  children: space.amenities.isNotEmpty
                      ? space.amenities
                          .map((a) =>
                              _AmenityRow(icon: Icons.check, label: a))
                          .toList()
                      : [const Text("No amenities listed")],
                ),
              ),

              const Divider(),

              // Host (placeholder)
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
                      Column(
                        children: const [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person,
                                size: 34, color: Colors.white),
                          ),
                          SizedBox(height: 8),
                          Text("Andrés",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Superhost · 3 years hosting",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _HostStat(value: "120", label: "Reviews"),
                          SizedBox(width: 20),
                          _HostStat(value: "4.9", label: "Rating"),
                          SizedBox(width: 20),
                          _HostStat(value: "95%", label: "Response rate"),
                        ],
                      ),
                    ],
                  ),
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
                  onPressed: () {},
                  child: const Text("Contact host",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),

              const Divider(),

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

              // Reviews (placeholder)
              _sectionTitle(context, "★ ${space.rating} · Reviews"),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "“The loft was super clean and in a great location. "
                  "Andrés was very responsive and helpful throughout our stay.”",
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

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
          Text("COP \$${space.price.toStringAsFixed(0)}/night",
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReservationScreen(
                    spaceTitle: space.title,
                    spaceAddress: '123 Business District, Suite 456, City Center',
                    spaceRating: space.rating,
                    reviewCount: 127,
                    pricePerHour: space.price / 24, // Convertir precio por noche a precio por hora
                    spaceId: space.id,
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
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
