import 'package:flutter/foundation.dart';
import 'package:breakpoint/data/services/nfc_service.dart';

class NfcViewModel extends ChangeNotifier {
  final NfcService _nfcService;
  NfcViewModel(this._nfcService);

  bool _isReading = false;
  String? _lastRead;
  String? _error;

  bool get isReading => _isReading;
  String? get lastRead => _lastRead;
  String? get error => _error;

  Future<String?> readOnce() async {
    _isReading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _nfcService.readNfcTag();
      _lastRead = data;
      return data;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isReading = false;
      notifyListeners();
    }
  }
}


