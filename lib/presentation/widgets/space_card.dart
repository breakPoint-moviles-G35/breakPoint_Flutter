import 'dart:io';
import 'package:flutter/material.dart';

class SpaceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double rating;
  final double? priceCOP;
  final double? originalPriceCOP; // precio base antes de descuento (opcional)
  final Color discountedColor;    // color para precio con descuento
  final List<String>? metaLines;
  final String rightTag;
  final double imageAspectRatio;

  /// Fuente de imagen (elige según tu caso)
  final String? imageUrl;   // URL http/https o file:///... o ruta local
  final String? assetImage; // asset declarado en pubspec

  final VoidCallback? onTap;

  const SpaceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rating,
    this.priceCOP,
    this.originalPriceCOP,
    this.discountedColor = Colors.green,
    this.metaLines,
    this.rightTag = '',
    this.imageAspectRatio = 16 / 9,
    this.imageUrl,
    this.assetImage,
    this.onTap,
  });

  bool get hasValidRating => rating > 0 && rating.isFinite;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

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

                      // 🔹 Solo mostrar rating si es válido (> 0)
                      if (hasValidRating) ...[
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],

                      if (rightTag.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Text(
                          rightTag,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ],
                  ),

                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.2,
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  if (metaLines != null && metaLines!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: metaLines!
                          .map((t) => Text(
                                t,
                                style:
                                    const TextStyle(color: Colors.black54),
                              ))
                          .toList(),
                    )
                  else if (priceCOP != null) ...[
                    if (originalPriceCOP != null && priceCOP! < originalPriceCOP!) ...[
                      Row(
                        children: [
                          Text(
                            '\$${originalPriceCOP!.toStringAsFixed(0)} COP',
                            style: const TextStyle(
                              color: Colors.black45,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${priceCOP!.toStringAsFixed(0)} COP',
                            style: TextStyle(
                              color: discountedColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        '\$${priceCOP!.toStringAsFixed(0)} COP',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final u = imageUrl?.trim();

    bool isHttpUrl(String? s) =>
        s != null && s.isNotEmpty && (s.startsWith('http://') || s.startsWith('https://'));
    bool isFileUri(String? s) => s != null && s.startsWith('file://');
    bool isFilePath(String? s) =>
        s != null && s.isNotEmpty && s.startsWith('/') && !isHttpUrl(s);

    Widget img;
    if (isHttpUrl(u)) {
      // Imagen por red
      img = Image.network(
        u!,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) {
          debugPrint('Image.network error: $u');
          return const _ImagePlaceholder();
        },
      );
    } else if (isFileUri(u) || isFilePath(u)) {
      // Archivo local
      final path = isFileUri(u)
          ? u!.replaceFirst(RegExp(r'^file://'), '')
          : u!;
      img = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
      );
    } else if (assetImage != null && assetImage!.isNotEmpty) {
      // Asset
      img = Image.asset(
        assetImage!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
      );
    } else {
      // Fallback
      img = const _ImagePlaceholder();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: AspectRatio(aspectRatio: imageAspectRatio, child: img),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE6E4E8),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined,
          size: 28, color: Colors.black38),
    );
  }
}
