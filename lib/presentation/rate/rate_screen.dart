import 'package:flutter/material.dart';
import 'package:breakpoint/routes/app_router.dart';

class RateScreen extends StatelessWidget {
  const RateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      {
        'title': 'Centre place Graslin - Private room La Cambroine',
        'rating': 4.96,
        'subtitleTop': 'Rental unit',
        'subtitleBottom': 'Cambroine',
        'image': null,
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: _SearchBarMock(),
        centerTitle: true,
        toolbarHeight: 64,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final it = items[i];
          return _RateCard(
            title: it['title'] as String,
            rating: (it['rating'] as num).toDouble(),
            subtitleTop: it['subtitleTop'] as String,
            subtitleBottom: it['subtitleBottom'] as String,
            onCreateReview: () => _openCreateReview(context),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (i) {
          if (i == 0) {
            Navigator.pushReplacementNamed(context, AppRouter.explore);
          } else if (i == 2) {
            Navigator.pushReplacementNamed(context, AppRouter.reservations);
          } else if (i == 3) {
            Navigator.pushReplacementNamed(context, AppRouter.profile);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Rate'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Reservations'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _openCreateReview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _CreateReviewSheet(),
    );
  }
}

class _SearchBarMock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: const [
          SizedBox(width: 12),
          Icon(Icons.search, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text('Lorem ipsum?', style: TextStyle(color: Colors.black54))),
          Icon(Icons.tune, size: 20),
          SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final String title;
  final double rating;
  final String subtitleTop;
  final String subtitleBottom;
  final VoidCallback onCreateReview;

  const _RateCard({
    required this.title,
    required this.rating,
    required this.subtitleTop,
    required this.subtitleBottom,
    required this.onCreateReview,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen placeholder
          Container(
            height: 120,
            width: 120,
            color: Colors.black12,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 16),
              const SizedBox(width: 4),
              Text(rating.toStringAsFixed(2)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            subtitleTop,
            style: const TextStyle(color: Colors.black87),
          ),
          Text(
            subtitleBottom,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onCreateReview,
            child: const Text('Create Review'),
          ),
        ],
      ),
    );
  }
}

class _CreateReviewSheet extends StatefulWidget {
  const _CreateReviewSheet();

  @override
  State<_CreateReviewSheet> createState() => _CreateReviewSheetState();
}

class _CreateReviewSheetState extends State<_CreateReviewSheet> {
  int _rating = 0;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 8),
                const Text('Rate your experience', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          const Divider(height: 1),

          // Imagen placeholder
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Texto review
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Review'),
                const SizedBox(height: 8),
                TextField(
                  controller: _ctrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Estrellas 1..5
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final idx = i + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = idx),
                icon: Icon(
                  idx <= _rating ? Icons.star : Icons.star_border,
                  color: Colors.black87,
                ),
              );
            }),
          ),

          const SizedBox(height: 8),

          // Botón Send (sin acción)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Send'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


