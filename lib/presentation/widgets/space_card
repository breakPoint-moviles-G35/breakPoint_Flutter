import 'package:flutter/material.dart';
// Si luego quieres caché de red, ver la nota al final (cached_network_image)

class SpaceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double rating;
  final double? priceCOP;
  final List<String>? metaLines;
  final String rightTag;
  final double imageAspectRatio;

  // NUEVO: fuente de imagen (elige una)
  final String? imageUrl;   // para imágenes por URL
  final String? assetImage; // para imágenes locales en assets/

  final VoidCallback? onTap;

  const SpaceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rating,
    this.priceCOP,
    this.metaLines,
    this.rightTag = 'xxx',
    this.imageAspectRatio = 16 / 9,
    this.imageUrl,
    this.assetImage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    Widget _buildImage() {
      final img = imageUrl != null
          ? Image.network(imageUrl!, fit: BoxFit.cover)
          : (assetImage != null
              ? Image.asset(assetImage!, fit: BoxFit.cover)
              : Container(color: const Color(0xFFE6E4E8))); // placeholder

      return ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: radius.topLeft,
          topRight: radius.topRight,
        ),
        child: AspectRatio(aspectRatio: imageAspectRatio, child: img),
      );
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.star, size: 16),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1)),
                      const SizedBox(width: 12),
                      Text(rightTag, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.black54, height: 1.2)),
                  ],
                  const SizedBox(height: 6),
                  if (metaLines != null && metaLines!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: metaLines!
                          .map((t) => Text(t, style: const TextStyle(color: Colors.black54)))
                          .toList(),
                    )
                  else if (priceCOP != null)
                    Text(
                      '\$${priceCOP!.toStringAsFixed(0)}X X X',
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
