import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:production/Screens/Attendance/encryption.dart';

class NFCNotifier extends ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  void clearNfcData() {
    _message = "";
    _vcid = null;
    safeNotifyListeners();
  }

  bool _isProcessing = false;
  String _message = "";
  bool get isProcessing => _isProcessing;
  String get message => _message;
  bool _hasStarted = false;
  bool get hasStarted => _hasStarted;
  String? _vcid;
  String? get vcid => _vcid;

  Future<void> startNFCOperation(
      {required NFCOperation nfcOperation, String dataType = ""}) async {
    try {
      _isProcessing = true;
      _hasStarted = true;
      safeNotifyListeners();
      bool isAvail = await NfcManager.instance.isAvailable();
      if (isAvail) {
        if (nfcOperation == NFCOperation.read) {
          _message = "Scanning";
        }
        safeNotifyListeners();
        NfcManager.instance.startSession(
          pollingOptions: {NfcPollingOption.iso14443},
          onDiscovered: (NfcTag nfcTag) async {
            try {
              if (nfcOperation == NFCOperation.read) {
                await _readFromTag(tag: nfcTag);
              }
            } catch (e) {
              print('Error in NFC discovery: $e');
              _message = "Error reading NFC: ${e.toString()}";
              safeNotifyListeners();
            } finally {
              _hasStarted = false;
              _isProcessing = false;
              safeNotifyListeners();
              // Stop session immediately after reading
              await NfcManager.instance.stopSession();
            }
          },
        );
      } else {
        _isProcessing = false;
        _hasStarted = false;
        _message = "Please Enable NFC From Settings";
        safeNotifyListeners();
      }
    } catch (e) {
      _isProcessing = false;
      _hasStarted = false;
      _message = e.toString();
      safeNotifyListeners();
    }
  }

  Future<void> _readFromTag({required NfcTag tag}) async {
    try {
      print('DEBUG: Starting NFC tag reading...');
      String? decodedText;

      // Get tag data using dynamic access
      final dynamic tagData = (tag as dynamic).data;
      print('DEBUG: Tag data type: ${tagData.runtimeType}');

      // Try to read actual NFC data
      try {
        // First try NDEF wrapper method
        final ndef = Ndef.from(tag);
        if (ndef != null) {
          final ndefMessage = ndef.cachedMessage;
          if (ndefMessage != null && ndefMessage.records.isNotEmpty) {
            for (final record in ndefMessage.records) {
              if (record.payload.isNotEmpty) {
                // Try different decoding methods
                try {
                  // Method 1: Direct payload as string
                  decodedText = String.fromCharCodes(record.payload);
                  if (decodedText.trim().isNotEmpty) {
                    // Remove leading 'en' language prefix if present for display
                    String displayDecoded = decodedText;
                    // Remove a single leading 'en' (case-insensitive) if present
                    displayDecoded =
                        displayDecoded.replaceFirst(RegExp(r'^(?i)en'), '');
                    // Normalize decodedText so downstream uses the stripped value
                    decodedText = displayDecoded;
                    // Print full string (no truncation) as requested
                    print('DEBUG: NDEF payload (direct): $displayDecoded');
                    break;
                  }
                } catch (e) {
                  print('DEBUG: Direct payload decode failed: $e');
                }

                try {
                  // Method 2: Skip language code for text records
                  if (record.payload.length > 3) {
                    int languageCodeLength = record.payload[0] & 0x3F;
                    if (languageCodeLength < record.payload.length) {
                      decodedText = String.fromCharCodes(
                          record.payload.sublist(languageCodeLength + 1));
                      if (decodedText.trim().isNotEmpty) {
                        // Remove leading 'en' language prefix if present for display
                        String displayDecoded = decodedText;
                        // Remove a single leading 'en' (case-insensitive) if present
                        displayDecoded =
                            displayDecoded.replaceFirst(RegExp(r'^(?i)en'), '');
                        // Normalize decodedText so downstream uses the stripped value
                        decodedText = displayDecoded;
                        // Print full string (no truncation) as requested
                        print(
                            'DEBUG: NDEF payload (text record): $displayDecoded');
                        break;
                      }
                    }
                  }
                } catch (e) {
                  print('DEBUG: Text record decode failed: $e');
                }
              }
            }
          }
        }

        // Check raw NDEF data if wrapper failed
        if (decodedText == null &&
            tagData is Map &&
            tagData.containsKey('ndef') &&
            tagData['ndef'] != null) {
          print('DEBUG: Found raw NDEF data');
          final ndefData = tagData['ndef'];
          if (ndefData['cachedMessage'] != null &&
              ndefData['cachedMessage']['records'] != null &&
              ndefData['cachedMessage']['records'].isNotEmpty) {
            final payload = ndefData['cachedMessage']['records'][0]['payload'];
            if (payload != null && payload.isNotEmpty) {
              try {
                decodedText = String.fromCharCodes(List<int>.from(payload));
                // Normalize: remove a single leading 'en' (case-insensitive) if present
                decodedText = decodedText.replaceFirst(RegExp(r'^(?i)en'), '');
                print('DEBUG: Raw NDEF data extracted: $decodedText');
              } catch (e) {
                print('DEBUG: Error decoding raw NDEF: $e');
              }
            }
          }
        }

        // Fallback to Mifare Ultralight if NDEF failed
        if (decodedText == null &&
            tagData is Map &&
            tagData.containsKey('mifareultralight')) {
          print('DEBUG: Trying Mifare Ultralight data');
          final mifareData = tagData['mifareultralight'];
          if (mifareData != null && mifareData['data'] != null) {
            List<int> data = List<int>.from(mifareData['data']);
            // Convert bytes to string, filtering out null bytes
            String rawText =
                String.fromCharCodes(data.where((byte) => byte != 0));
            if (rawText.trim().isNotEmpty) {
              decodedText = rawText.trim();
              // Normalize: remove a single leading 'en' (case-insensitive) if present
              decodedText = decodedText.replaceFirst(RegExp(r'^(?i)en'), '');
              print('DEBUG: Mifare data extracted: $decodedText');
            }
          }
        }
      } catch (e) {
        print('DEBUG: Error reading NFC data: $e');
      }

      if (decodedText == null || decodedText.isEmpty) {
        print('DEBUG: No data found on NFC card');
        _message = "No Data Found";
        safeNotifyListeners();
        return;
      }

      print('DEBUG: Starting decryption...');
      // For logs, remove leading 'en' language code if present so displayed data
      // Raw extracted data (decodedText already normalized)
      print('DEBUG: Raw extracted data length: ${decodedText.length}');
      print('DEBUG: Raw extracted data: $decodedText');

      // Clean up the extracted data for decryption
      String cleanedData = decodedText.trim();

      // Remove language code prefix if present (common in NDEF text records)
      // cleanedData is derived from decodedText which is already normalized

      // Robust base64 extraction/normalization:
      // - Accept standard and URL-safe base64 characters
      // - Find the longest continuous base64-like substring (to avoid trailing garbage)
      // - Normalize URL-safe chars (- -> +, _ -> /)
      String extractLikelyBase64(String input) {
        // Replace common URL-safe chars with standard base64 equivalents for matching
        final normalizedInput = input.replaceAll('-', '+').replaceAll('_', '/');

        // Find candidate substrings consisting of base64 chars and padding
        final candidateRe = RegExp(r'[A-Za-z0-9+/=]{40,}');
        final matches = candidateRe.allMatches(normalizedInput).toList();
        if (matches.isEmpty)
          return normalizedInput.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

        // Choose the longest match (most likely the real payload)
        Match best = matches.first;
        for (final m in matches) {
          if (m.end - m.start > best.end - best.start) best = m;
        }

        String candidate = normalizedInput.substring(best.start, best.end);
        // Strip any non-base64 chars just in case
        candidate = candidate.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
        return candidate;
      }

      cleanedData = extractLikelyBase64(cleanedData);

      print(
          'DEBUG: Cleaned data for decryption: ${cleanedData.length > 100 ? cleanedData.substring(0, 100) + '...' : cleanedData}');
      print('DEBUG: Cleaned data length: ${cleanedData.length}');

      // Validate it looks like base64
      if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(cleanedData)) {
        print('DEBUG: WARNING - Cleaned data doesn\'t look like valid base64');
      }

      // Additional validation - check if data is empty after cleaning
      if (cleanedData.isEmpty) {
        print('DEBUG: ERROR - No valid base64 data found after cleaning');
        _message = "No valid encrypted data found on card";
        safeNotifyListeners();
        return;
      }

      // Fix Base64 padding if needed
      while (cleanedData.length % 4 != 0) {
        cleanedData += '=';
      }
      print(
          'DEBUG: Base64 data after padding correction: ${cleanedData.length > 100 ? cleanedData.substring(0, 100) + '...' : cleanedData}');
      print('DEBUG: Final data length: ${cleanedData.length}');

      // Test the isBase64 validation manually
      try {
        base64Decode(cleanedData);
        print('DEBUG: Base64 validation passed');
      } catch (e) {
        print('DEBUG: Base64 validation failed: $e');
        print(
            'DEBUG: First 50 chars: ${cleanedData.length > 50 ? cleanedData.substring(0, 50) : cleanedData}');
        print(
            'DEBUG: Last 50 chars: ${cleanedData.length > 50 ? cleanedData.substring(cleanedData.length - 50) : cleanedData}');
        _message = "Invalid encrypted data format on card";
        safeNotifyListeners();
        return;
      }

      // Decrypt and parse the data
      final String encryptionKey = "VLABSOLUTION2023";
      final encrypt.IV iv = encrypt.IV.fromUtf8(encryptionKey);
      final decryptedText = decryptAES(cleanedData, encryptionKey, iv);
      print('DEBUG: Decryption completed successfully');

      Map<String, dynamic> data = jsonDecode(decryptedText);
      _vcid = data['vcid'];
      print('DEBUG: VCID extracted: $_vcid');

      String formattedData = '''
Name: ${data["name"] ?? "N/A"}
Designation: ${data["designation"] ?? "N/A"}
Code: ${data["code"] ?? "N/A"}
Union Name: ${data["unionName"] ?? "N/A"}
''';

      print('DEBUG: Formatted data created');
      _message = formattedData;
      safeNotifyListeners();
      print('DEBUG: NFC reading completed successfully');
    } catch (e) {
      print('ERROR in _readFromTag: $e');
      _message = "Error reading card data: $e";
      _vcid = null;
      safeNotifyListeners();
    }
  }
}

enum NFCOperation { read }
