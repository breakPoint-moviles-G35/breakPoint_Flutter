import 'package:flutter/material.dart';
import 'package:breakpoint/domain/repositories/space_repository.dart';
import 'package:breakpoint/domain/repositories/host_repository.dart';

class CreateSpaceViewModel extends ChangeNotifier {
  final SpaceRepository spaceRepo;
  final HostRepository hostRepo;

  CreateSpaceViewModel(this.spaceRepo, this.hostRepo);

  bool isSubmitting = false;
  String? error;
  String? hostProfileId;

  Future<void> ensureHostProfileId() async {
    if (hostProfileId != null && hostProfileId!.isNotEmpty) return;
    final me = await hostRepo.getMyHostProfile();
    hostProfileId = me.id;
  }

  Future<bool> submit({
    required String title,
    String? subtitle,
    String? geo,
    required int capacity,
    required List<String> amenities,
    List<String>? accessibility,
    String? imageUrl,
    required String rules,
    required double price,
  }) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      await ensureHostProfileId();
      if (hostProfileId == null || hostProfileId!.isEmpty) {
        throw Exception('No se pudo obtener tu HostProfile');
      }

      await spaceRepo.createSpace(
        hostProfileId: hostProfileId!,
        title: title,
        subtitle: subtitle,
        geo: geo,
        capacity: capacity,
        amenities: amenities,
        accessibility: accessibility,
        imageUrl: imageUrl,
        rules: rules,
        price: price,
      );
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}


