import '../entities/host.dart';

abstract class HostRepository {
  Future<Host> getHostById(String id);
  Future<Host> getHostByUserId(String userId);
}
