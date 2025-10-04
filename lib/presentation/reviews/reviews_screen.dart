import 'package:flutter/material.dart';

/// Args para pasar el espacio por Navigator
class ReviewsArgs {
  final String spaceId;                // TODO: usa el real
  final double? initialRatingAvg;      // opcional, por si ya lo tienes del detalle
  final int? initialTotalReviews;      // opcional
  ReviewsArgs({required this.spaceId, this.initialRatingAvg, this.initialTotalReviews});
}

/// Modelo simple para UI (mock). TODO: reemplazar por tu modelo real.
class ReviewItem {
  final String author;
  final int rating; // 1..5
  final String text;
  final DateTime createdAt;
  ReviewItem({required this.author, required this.rating, required this.text, required this.createdAt});
}

class ReviewsScreen extends StatelessWidget {
  final ReviewsArgs args;
  const ReviewsScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    // TODO: cuando conectes al back, trae datos usando args.spaceId
    // final vm = context.watch<ReviewsViewModel>();
    // vm.load(spaceId: args.spaceId);

    // MOCKS (borra cuando conectes)
    final double ratingAvg = args.initialRatingAvg ?? 4.95; // TODO: summary real
    final int totalReviews = args.initialTotalReviews ?? 22; // TODO: summary real
    final items = <ReviewItem>[
      ReviewItem(author: 'Emma',  rating: 5, text: 'Excelente ubicación y muy limpio.', createdAt: DateTime(2024,12,6)),
      ReviewItem(author: 'Lucas', rating: 4, text: 'Buen host, volvería sin dudar.',   createdAt: DateTime(2024,11,21)),
      ReviewItem(author: 'Sara',  rating: 5, text: 'Tal cual las fotos. Recomendado.', createdAt: DateTime(2024,10,2)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            _SummaryCard(totalReviews: totalReviews, ratingAvg: ratingAvg),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _ReviewTile(item: items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalReviews; final double ratingAvg;
  const _SummaryCard({required this.totalReviews, required this.ratingAvg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Kpi(value: '$totalReviews', label: 'Reviews'),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          _Kpi(value: ratingAvg.toStringAsFixed(2), label: 'Rating', icon: Icons.star),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String value; final String label; final IconData? icon;
  const _Kpi({required this.value, required this.label, this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (icon != null) ...[Icon(icon, size: 18, color: Colors.amber), const SizedBox(width: 6)],
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ]),
    ]);
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewItem item;
  const _ReviewTile({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.text, style: const TextStyle(fontSize: 14.5, height: 1.35)),
        const SizedBox(height: 12),
        Row(children: [
          const CircleAvatar(radius: 18, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 20, color: Colors.white)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.author, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(_timeAgo(item.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ])),
          _Stars(rating: item.rating),
        ]),
      ]),
    );
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  const _Stars({required this.rating});
  @override
  Widget build(BuildContext context) {
    return Row(children: List.generate(5, (i) {
      final filled = i < rating;
      return Icon(filled ? Icons.star : Icons.star_border, size: 18, color: Colors.amber);
    }));
  }
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays >= 30) { final m = (diff.inDays / 30).floor(); return '$m month${m>1?'s':''} ago'; }
  if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays>1?'s':''} ago';
  if (diff.inHours >= 1) return '${diff.inHours} hour${diff.inHours>1?'s':''} ago';
  return 'just now';
}
