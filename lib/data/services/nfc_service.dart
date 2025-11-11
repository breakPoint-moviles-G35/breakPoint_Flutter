import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

/// Service to handle NFC tag reading and writing operations
class NfcService {
  /// Check if NFC is available on the device
  Future<bool> isNfcAvailable() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (e) {
      print('Error checking NFC availability: $e');
      return false;
    }
  }

  /// Start NFC session to read data from a tag
  /// Returns the data read from the tag as a String, or null if reading fails
  Future<String?> readNfcTag() async {
    try {
      // Check if NFC is available on the device
      var availability = await FlutterNfcKit.nfcAvailability;

      if (availability != NFCAvailability.available) {
        return 'NFC is not available on this device';
      }

      // Close any existing NFC session
      await FlutterNfcKit.finish();

      // Start polling for NFC tags
      var tag = await FlutterNfcKit.poll(
          timeout: Duration(seconds: 10),
          iosMultipleTagMessage: "Multiple tags found!",
          iosAlertMessage: "Hold your device near the NFC tag"
      );

      StringBuffer result = StringBuffer();
      result.writeln('Tag ID: ${tag.id}');
      result.writeln('Tag Type: ${tag.type}');
      result.writeln('Tag Standard: ${tag.standard}');

      // Read NDEF records if available
      if (tag.ndefAvailable ?? false) {
        var records = await FlutterNfcKit.readNDEFRecords(cached: false);

        if (records.isNotEmpty) {
          for (var record in records) {
            if (record is ndef.TextRecord) {
              result.writeln('Text: ${record.text}');
            } else if (record is ndef.UriRecord) {
              result.writeln('URI: ${record.uri}');
            }
          }
        } else {
          result.writeln('No NDEF records found');
        }
      } else {
        result.writeln('This tag does not contain NDEF data');
      }

      // Finish the NFC session
      await FlutterNfcKit.finish(iosAlertMessage: "Reading complete!");

      return result.toString().trim();

    } catch (e) {
      await FlutterNfcKit.finish(iosErrorMessage: "Error reading tag");
      return 'Error reading NFC tag: $e';
    }
  }

  /// Write text data to an NFC tag
  /// Returns true if writing was successful, false otherwise

  Future<bool> writeNfcTag(String content) async {
    try {
      // Check if NFC is available on the device
      var availability = await FlutterNfcKit.nfcAvailability;

      if (availability != NFCAvailability.available) {
        return false;
      }

      // Close any existing NFC session
      await FlutterNfcKit.finish();

      // Start polling for NFC tags
      var tag = await FlutterNfcKit.poll(
          timeout: Duration(seconds: 10),
          iosMultipleTagMessage: "Multiple tags found!",
          iosAlertMessage: "Hold your device near the NFC tag to write"
      );

      // Check if the tag is writable
      if (tag.ndefWritable ?? false) {
        // Create a text record with the content
        await FlutterNfcKit.writeNDEFRecords([
          ndef.TextRecord(
              text: content,
              language: "en",
              encoding: ndef.TextEncoding.UTF8
          )
        ]);

        // Finish the NFC session
        await FlutterNfcKit.finish(iosAlertMessage: "Write successful!");

        return true;
      } else {
        // Tag is not writable
        await FlutterNfcKit.finish(iosErrorMessage: "Tag is not writable");
        return false;
      }

    } catch (e) {
      await FlutterNfcKit.finish(iosErrorMessage: "Error writing tag");
      return false;
    }
  }

  /// Write JSON data to an NFC tag
  /// Returns true if writing was successful, false otherwise
  Future<bool> writeJsonToNfcTag(Map<String, dynamic> jsonData) async {
    try {
      final jsonString = json.encode(jsonData);
      return await writeNfcTag(jsonString);
    } catch (e) {
      print('Error writing JSON to NFC tag: $e');
      return false;
    }
  }

  /// Read JSON data from an NFC tag
  /// Returns the parsed JSON as a Map, or null if reading/parsing fails
  Future<Map<String, dynamic>?> readJsonFromNfcTag() async {
    try {
      final textData = await readNfcTag();
      
      if (textData == null) {
        return null;
      }

      return json.decode(textData) as Map<String, dynamic>;
    } catch (e) {
      print('Error reading JSON from NFC tag: $e');
      return null;
    }
  }

  /// Write a space reservation ID to an NFC tag
  /// Useful for checking in to a reserved space
  Future<bool> writeReservationId(String reservationId, String spaceId) async {
    final data = {
      'type': 'reservation',
      'reservationId': reservationId,
      'spaceId': spaceId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return await writeJsonToNfcTag(data);
  }

  /// Read a space reservation ID from an NFC tag
  Future<Map<String, dynamic>?> readReservationId() async {
    return await readJsonFromNfcTag();
  }
}

