import 'package:flutter/material.dart';
import 'package:breakpoint/presentation/details/contact_host_sheet.dart'
    show HostProfileView; // modelo simple del sheet
import 'package:breakpoint/presentation/details/space_detail_screen.dart';
import 'package:breakpoint/domain/entities/space.dart'; // <-- entidad Space

class HostDetailScreen extends StatelessWidget {
  final HostProfileView host;
  const HostDetailScreen({super.key, required this.host});

  void _goToSampleSpace(BuildContext context) {
    // TODO: Reemplazar por un Space real del backend/listado del host
    final sample = Space(
      id: 'demo-1',
      title: 'Centre place Graslin',
      subtitle: 'Private room · La Cambroine',
      rating: 4.96,
      price: 220000, // COP
      imageUrl: '',
      capacity: 2,
      amenities: const ['Wi-Fi', 'Desk'],
      rules: 'No smoking. No pets.', // pon algo simple
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpaceDetailScreen(space: sample),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grey50 = const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: grey50,
      appBar: AppBar(
        title: const Text('Host detail'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _HostCardBig(host: host),
          const SizedBox(height: 12),

          _BulletRow(icon: Icons.cake_outlined, text: host.born),
          const SizedBox(height: 10),
          _BulletRow(
              icon: Icons.location_on_outlined,
              text: 'Lives in ${host.location}'),
          const SizedBox(height: 10),
          _BulletRow(icon: Icons.work_outline, text: 'My work: ${host.work}'),

          const SizedBox(height: 14),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 10),

          // SECTION: Host reviews
          Text(
            "${host.name}'s reviews",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3, // TODO: cantidad real
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => const _ReviewCard(),
            ),
          ),

          const SizedBox(height: 22),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 12),

          // SECTION: Host’s confirmed information
          const Text(
            "Host’s confirmed information",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const _CheckRow(text: "Identity"),
          const SizedBox(height: 8),
          const _CheckRow(text: "Email address"),
          const SizedBox(height: 8),
          const _CheckRow(text: "Phone number"),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {}, // TODO
              child: const Text(
                "Learn about identity verification",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ),

          const SizedBox(height: 4),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 12),

          // SECTION: Host’s listings
          const Text(
            "Host’s listings",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 246,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 2, // TODO: cantidad real
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _ListingCard(
                onTap: () => _goToSampleSpace(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _goToSampleSpace(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Show all 6 rooms"), // TODO: número real
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {}, // TODO
              child: const Text(
                "Report this profile",
                style: TextStyle(
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _HostCardBig extends StatelessWidget {
  final HostProfileView host;
  const _HostCardBig({required this.host});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 38,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 38, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(host.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                Text(
                  host.isSuperhost ? 'Superhost' : 'Host',
                  style: TextStyle(
                    color: host.isSuperhost
                        ? Colors.deepPurple
                        : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Kpi(value: '${host.reviewsCount}', label: 'Reviews'),
                    _MiddleDivider(),
                    // Solo mostrar rating si hay reviews
                    if (host.reviewsCount > 0) ...[
                      _Kpi(
                          value: host.ratingAvg.toStringAsFixed(2),
                          label: 'Rating',
                          icon: Icons.star),
                      _MiddleDivider(),
                    ],
                    _Kpi(
                        value: '${host.monthsHosting}',
                        label: 'Months hosting'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiddleDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        color: Colors.grey[300],
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}

class _Kpi extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  const _Kpi({required this.value, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BulletRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black87),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14.5))),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;
  const _CheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check, size: 18, color: Colors.black87),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14.5))),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean commodo ligula eget dolor.",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Lorem ipsum",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Emma",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text("3 months ago",
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _ListingCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFE0E0E0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child:
                  const Center(child: Icon(Icons.image, size: 48, color: Colors.white)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _RatingRow(),
                  SizedBox(height: 6),
                  Text(
                    "Centre place Graslin - Private room La Cambroine",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text("Rental unit", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.star, size: 16, color: Colors.amber),
        SizedBox(width: 4),
        Text("4.96"),
      ],
    );
  }
}
