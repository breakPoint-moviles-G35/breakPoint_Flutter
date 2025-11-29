import 'package:flutter/foundation.dart';
import 'package:breakpoint/data/services/nfc_service.dart';

/// ViewModel to manage NFC operations
class NfcViewModel extends ChangeNotifier {
  final NfcService _nfcService;

  NfcViewModel(this._nfcService);

  bool _isNfcAvailable = false;
  bool _isReading = false;
  bool _isWriting = false;
  String? _lastReadData;
  String? _errorMessage;
  bool _writeSuccess = false;

  bool get isNfcAvailable => _isNfcAvailable;
  bool get isReading => _isReading;
  bool get isWriting => _isWriting;
  String? get lastReadData => _lastReadData;
  String? get errorMessage => _errorMessage;
  bool get writeSuccess => _writeSuccess;

  /// Initialize and check NFC availability
  Future<void> init() async {
    _isNfcAvailable = await _nfcService.isNfcAvailable();
    notifyListeners();
  }

  /// Start reading an NFC tag
  Future<void> startReading() async {
    if (!_isNfcAvailable) {
      _errorMessage = 'NFC is not available on this device';
      notifyListeners();
      return;
    }

    _isReading = true;
    _errorMessage = null;
    _lastReadData = null;
    notifyListeners();

    try {
      final data = await _nfcService.readNfcTag();
      
      if (data != null) {
        _lastReadData = data;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to read NFC tag';
      }
    } catch (e) {
      _errorMessage = 'Error reading NFC tag: $e';
    } finally {
      _isReading = false;
      notifyListeners();
    }
  }

  /// Start writing text to an NFC tag
  Future<void> writeText(String text) async {
    if (!_isNfcAvailable) {
      _errorMessage = 'NFC is not available on this device';
      notifyListeners();
      return;
    }

    if (text.isEmpty) {
      _errorMessage = 'Text cannot be empty';
      notifyListeners();
      return;
    }

    _isWriting = true;
    _errorMessage = null;
    _writeSuccess = false;
    notifyListeners();

    try {
      final success = await _nfcService.writeNfcTag(text);
      
      if (success) {
        _writeSuccess = true;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to write to NFC tag';
      }
    } catch (e) {
      _errorMessage = 'Error writing to NFC tag: $e';
    } finally {
      _isWriting = false;
      notifyListeners();
    }
  }

  /// Read JSON data from an NFC tag
  Future<Map<String, dynamic>?> readJson() async {
    if (!_isNfcAvailable) {
      _errorMessage = 'NFC is not available on this device';
      notifyListeners();
      return null;
    }

    _isReading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final jsonData = await _nfcService.readJsonFromNfcTag();
      
      if (jsonData != null) {
        _lastReadData = jsonData.toString();
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to read JSON from NFC tag';
      }
      
      return jsonData;
    } catch (e) {
      _errorMessage = 'Error reading JSON from NFC tag: $e';
      return null;
    } finally {
      _isReading = false;
      notifyListeners();
    }
  }

  /// Write JSON data to an NFC tag
  Future<void> writeJson(Map<String, dynamic> jsonData) async {
    if (!_isNfcAvailable) {
      _errorMessage = 'NFC is not available on this device';
      notifyListeners();
      return;
    }

    if (jsonData.isEmpty) {
      _errorMessage = 'JSON data cannot be empty';
      notifyListeners();
      return;
    }

    _isWriting = true;
    _errorMessage = null;
    _writeSuccess = false;
    notifyListeners();

    try {
      final success = await _nfcService.writeJsonToNfcTag(jsonData);
      
      if (success) {
        _writeSuccess = true;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to write JSON to NFC tag';
      }
    } catch (e) {
      _errorMessage = 'Error writing JSON to NFC tag: $e';
    } finally {
      _isWriting = false;
      notifyListeners();
    }
  }

  /// Write a reservation ID to an NFC tag
  Future<void> writeReservation(String reservationId, String spaceId) async {
    if (!_isNfcAvailable) {
      _errorMessage = 'NFC is not available on this device';
      notifyListeners();
      return;
    }

    _isWriting = true;
    _errorMessage = null;
    _writeSuccess = false;
    notifyListeners();

    try {
      final success = await _nfcService.writeReservationId(reservationId, spaceId);
      
      if (success) {
        _writeSuccess = true;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to write reservation to NFC tag';
      }
    } catch (e) {
      _errorMessage = 'Error writing reservation to NFC tag: $e';
    } finally {
      _isWriting = false;
      notifyListeners();
    }
  }

  /// Read a reservation from an NFC tag
  Future<Map<String, dynamic>?> readReservation() async {
    if (!_isNfcAvailable) {
      _errorMessage = 'NFC is not available on this device';
      notifyListeners();
      return null;
    }

    _isReading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reservationData = await _nfcService.readReservationId();
      
      if (reservationData != null) {
        _lastReadData = reservationData.toString();
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to read reservation from NFC tag';
      }
      
      return reservationData;
    } catch (e) {
      _errorMessage = 'Error reading reservation from NFC tag: $e';
      return null;
    } finally {
      _isReading = false;
      notifyListeners();
    }
  }

  /// Stop any active NFC session
  Future<void> stopSession() async {
    _isReading = false;
    _isWriting = false;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all state
  void reset() {
    _lastReadData = null;
    _errorMessage = null;
    _writeSuccess = false;
    _isReading = false;
    _isWriting = false;
    notifyListeners();
  }
}

