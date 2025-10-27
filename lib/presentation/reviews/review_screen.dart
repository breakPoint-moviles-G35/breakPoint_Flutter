import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/repositories/review_repository.dart';
import '../../../data/repositories/review_repository_impl.dart';
import '../../../data/services/review_api.dart';
import 'viewmodel/review_viewmodel.dart';
import 'package:dio/dio.dart';

class ReviewScreen extends StatelessWidget {
  final String spaceId;

  const ReviewScreen({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context) {
    final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000')); // cambia a tu URL
    final repo = ReviewRepositoryImpl(ReviewApi(dio));

    return ChangeNotifierProvider(
      create: (_) => ReviewViewModel(repo)..loadReviews(spaceId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reviews'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Consumer<ReviewViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.errorMessage != null) {
              return Center(child: Text(vm.errorMessage!));
            }

            if (vm.reviews.isEmpty) {
              return const Center(child: Text('No hay reviews todavía.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.reviews.length,
              itemBuilder: (context, i) {
                final review = vm.reviews[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(review.rating.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(review.text,
                          style:
                              const TextStyle(fontSize: 15, height: 1.4)),
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
                              Text(review.userName ?? "Usuario",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(review.userEmail ?? "",
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
