import 'dart:convert';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcService {
  Future<bool> isNfcAvailable() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (_) {
      return false;
    }
  }

  Future<String?> readNfcTag() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        return null;
      }
      await FlutterNfcKit.finish();
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Hold your device near the NFC tag",
      );
      final buffer = StringBuffer();
      buffer.writeln('Tag ID: ${tag.id}');
      if (tag.ndefAvailable ?? false) {
        final records = await FlutterNfcKit.readNDEFRecords(cached: false);
        for (final record in records) {
          if (record is ndef.TextRecord) {
            buffer.writeln('Text: ${record.text}');
          } else if (record is ndef.UriRecord) {
            buffer.writeln('URI: ${record.uri}');
          }
        }
      }
      await FlutterNfcKit.finish(iosAlertMessage: "Reading complete!");
      return buffer.toString().trim().isEmpty ? null : buffer.toString().trim();
    } catch (_) {
      await FlutterNfcKit.finish(iosErrorMessage: "Error reading tag");
      return null;
    }
  }

  Future<bool> writeNfcTag(String content) async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) return false;
      await FlutterNfcKit.finish();
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Hold your device near the NFC tag to write",
      );
      if (tag.ndefWritable ?? false) {
        await FlutterNfcKit.writeNDEFRecords([
          ndef.TextRecord(text: content, language: "en", encoding: ndef.TextEncoding.UTF8),
        ]);
        await FlutterNfcKit.finish(iosAlertMessage: "Write successful!");
        return true;
      }
      await FlutterNfcKit.finish(iosErrorMessage: "Tag is not writable");
      return false;
    } catch (_) {
      await FlutterNfcKit.finish(iosErrorMessage: "Error writing tag");
      return false;
    }
  }

  Future<bool> writeJsonToNfcTag(Map<String, dynamic> jsonData) async {
    try {
      final jsonString = json.encode(jsonData);
      return await writeNfcTag(jsonString);
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> readJsonFromNfcTag() async {
    try {
      final text = await readNfcTag();
      if (text == null) return null;
      return json.decode(text) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}


