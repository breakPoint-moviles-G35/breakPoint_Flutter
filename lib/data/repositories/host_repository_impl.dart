import '../../domain/entities/host.dart';
import '../../domain/repositories/host_repository.dart';
import '../services/host_api.dart';

class HostRepositoryImpl implements HostRepository {
  final HostApi api;
  HostRepositoryImpl(this.api);

  @override
  Future<Host> getHostById(String id) async {
    final data = await api.getHostById(id);
    return Host.fromJson(data);
  }

  @override
  Future<Host> getHostByUserId(String userId) async {
    final data = await api.getHostByUserId(userId);
    return Host.fromJson(data);
  }
}
