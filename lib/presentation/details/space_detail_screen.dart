import 'package:flutter/material.dart';
import 'reservation_dialog.dart';




class SpaceDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final double rating;
  final double price;

  const SpaceDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.price,
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
                    child: const Center(
                      child: Icon(Icons.image, size: 120),
                    ),
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
                    Text("Modern Loft in Bogotá",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("La Candelaria · Near Monserrate",
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 24, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          "4.8",
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 10),
                        Text("234 reviews",
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
                  children: const [
                    _AmenityRow(icon: Icons.bed, label: "1 queen bed"),
                    Divider(),
                    _AmenityRow(icon: Icons.chair, label: "Dedicated workspace"),
                    Divider(),
                    _AmenityRow(icon: Icons.wifi, label: "High-speed Wi-Fi"),
                  ],
                ),
              ),

              const Divider(),

              // Host
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
                          _HostStat(value: "4.9 ★", label: "Rating"),
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

              // Card extra (Booking dates) antes de About
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Your trip",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text("Jun 25 – Jun 30 · 2 guests",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.black87),
                    ],
                  ),
                ),
              ),

              const Divider(),

              // About
              _sectionTitle(context, "About this place"),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Stay in this cozy modern loft located in the heart of Bogotá’s historic district. "
                  "Perfect for couples or solo travelers looking to explore museums, restaurants, "
                  "and vibrant nightlife. The loft has a fully equipped kitchen, smart TV, and "
                  "a balcony with city views.",
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
              ),

              const Divider(),

              // Reviews
              _sectionTitle(context, "★ 4.8 · 234 reviews"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "“The loft was super clean and in a great location. "
                        "Walking distance to Monserrate and the Gold Museum. "
                        "Andrés was very responsive and helpful throughout our stay.”",
                        style: TextStyle(fontSize: 15, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person,
                                size: 20, color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Emma",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Text("From Canada",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          )
                        ],
                      )
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
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: const Text("Show all reviews",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),

              const Divider(),

              _sectionTitle(context, "Cancellation policy"),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Free cancellation up to 24 hours before check-in. "
                  "After that, 50% refund for cancellations.",
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const Divider(),

              _sectionTitle(context, "Safety & property"),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Security cameras at building entrance. Fire alarms installed. "
                  "Emergency exits available on each floor.",
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const Divider(),

              // Report listing (texto negro)
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Report this listing",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w500)),
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
          Text("COP \$220,000/night",
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
              showDialog(
                context: context, 
                builder: (context) => const ReservationDialog(),
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
