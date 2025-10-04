import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/domain/entities/review.dart';
import 'package:breakpoint/domain/repositories/review_repository.dart';

/// Args para pasar el espacio por Navigator
class ReviewsArgs {
  final String spaceId;
  final double? initialRatingAvg;
  final int? initialTotalReviews;
  ReviewsArgs({required this.spaceId, this.initialRatingAvg, this.initialTotalReviews});
}

class ReviewsScreen extends StatefulWidget {
  final ReviewsArgs args;
  const ReviewsScreen({super.key, required this.args});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Review> reviews = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final repository = context.read<ReviewRepository>();
      final reviewsData = await repository.getReviewsBySpaceId(widget.args.spaceId);
      
      setState(() {
        reviews = reviewsData;
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
                onPressed: _loadReviews,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final double ratingAvg = widget.args.initialRatingAvg ?? 
        (reviews.isNotEmpty ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length : 0.0);
    final int totalReviews = reviews.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            _SummaryCard(totalReviews: totalReviews, ratingAvg: ratingAvg, reviews: reviews),
            const SizedBox(height: 12),
            Expanded(
              child: reviews.isEmpty
                  ? const Center(
                      child: Text(
                        'No reviews yet. Be the first to review this space!',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.separated(
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _ReviewCard(review: reviews[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalReviews;
  final double ratingAvg;
  final List<Review> reviews;

  const _SummaryCard({
    required this.totalReviews, 
    required this.ratingAvg,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '★ ${ratingAvg.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$totalReviews reviews',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Rating breakdown (opcional)
          if (totalReviews > 0) ...[
            Column(
              children: List.generate(5, (index) {
                final stars = 5 - index;
                final count = reviews.where((r) => r.rating == stars).length;
                final percentage = totalReviews > 0 ? count / totalReviews : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$stars', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percentage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('$count', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                child: Text(
                  review.authorName?.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) => 
                            Icon(
                              Icons.star,
                              size: 16,
                              color: index < review.rating 
                                  ? Colors.amber 
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
