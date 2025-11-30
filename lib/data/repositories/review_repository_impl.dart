 import 'dart:collection';
 import 'package:dio/dio.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../services/review_api.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewApi _api;

  ReviewRepositoryImpl(this._api);

  // LRU cache en memoria para estadísticas por espacio
  static const int _maxEntries = 50;
  static const Duration _ttl = Duration(minutes: 10);
  final _LruCache<String, Map<String, dynamic>> _statsCache =
      _LruCache(maxEntries: _maxEntries, ttl: _ttl);

  /// Obtiene todas las reviews asociadas a un espacio específico
  @override
  Future<List<Review>> getReviewsBySpace(String spaceId) async {
    try {
      final response = await _api.getReviewsBySpace(spaceId);
      return response.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener reviews: $e');
    }
  }

  /// Obtiene las estadísticas (promedio, cantidad, etc.) de las reviews de un espacio
  @override
  Future<Map<String, dynamic>> getSpaceStats(String spaceId) async {
    try {
      // 1) Intentar leer de LRU
      final cached = _statsCache.get(spaceId);
      if (cached != null) return cached;

      // 2) Ir a red y actualizar cache
      final stats = await _api.getSpaceStats(spaceId);
      _statsCache.put(spaceId, stats);
      return stats;
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  @override
  Future<void> createReview({
    required String spaceId,
    required String text,
    required String rating,
  }) async {
    try {
      await _api.createReview(spaceId: spaceId, text: text, rating: rating);
    } catch (e) {
      throw Exception('Error al crear review: $e');
    }
  }

  /// 🔹 Nuevo método para obtener el promedio de rating de un espacio
  Future<double> fetchAverageRatingForSpace(int spaceId) async {
    try {
      final stats = await _api.getSpaceStats(spaceId.toString());
      // Espera una respuesta tipo: {"averageRating": 4.6, "reviewCount": 15}
      return (stats["averageRating"] ?? 0.0).toDouble();
    } catch (e) {
      print("⚠️ Error al obtener el promedio de rating para espacio $spaceId: $e");
      return 0.0;
    }
  }
}

class _LruEntry<V> {
  final V value;
  final int timestampMs;
  _LruEntry(this.value, this.timestampMs);
}

class _LruCache<K, V> {
  final int maxEntries;
  final Duration ttl;
  final _map = LinkedHashMap<K, _LruEntry<V>>();

  _LruCache({required this.maxEntries, required this.ttl});

  V? get(K key) {
    final entry = _map.remove(key);
    if (entry == null) return null;
    // Verificar TTL
    final now = DateTime.now().millisecondsSinceEpoch;
    final isFresh = (now - entry.timestampMs) <= ttl.inMilliseconds;
    if (!isFresh) {
      // Expirado: no reinsertar
      return null;
    }
    // Reinsertar para marcar como más recientemente usado
    _map[key] = entry;
    return entry.value;
  }

  void put(K key, V value) {
    // Insertar/actualizar y mover al final
    _map.remove(key);
    _map[key] = _LruEntry(value, DateTime.now().millisecondsSinceEpoch);
    // Evicción si excede el límite
    while (_map.length > maxEntries) {
      final oldestKey = _map.keys.first;
      _map.remove(oldestKey);
    }
  }
}
