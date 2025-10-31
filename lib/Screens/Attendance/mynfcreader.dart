import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:production/Screens/Home/importantfunc.dart';
import 'package:production/variables.dart';
import 'package:sqflite/sqflite.dart';
import 'dailogei.dart';

class MyNFCReader {
  bool _sessionRunning = false;

  /// Check if NFC is available on the device
  Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Start NFC scanning session and return written data when card is detected
  /// Automatically calls decryptapi() after fetching card data
  /// Then shows countdown dialog with user details
  /// Returns a Map with:
  /// - 'success': bool indicating if scan was successful
  /// - 'cardData': String containing the data written on the NFC card
  /// - 'decryptResult': Map containing the result from decryptapi() call
  /// - 'decryptError': String containing decrypt error (if decrypt failed)
  /// - 'error': String containing error message (if scan failed)
  Future<Map<String, dynamic>> scanNfcCard({BuildContext? context}) async {
    if (_sessionRunning) {
      return {'success': false, 'error': 'NFC session already running'};
    }

    final bool isAvailable = await isNfcAvailable();
    if (!isAvailable) {
      return {'success': false, 'error': 'NFC not available on this device'};
    }

    // Use a Completer to handle the async NFC session
    final completer = Completer<Map<String, dynamic>>();

    _sessionRunning = true;

    try {
      NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (NfcTag tag) async {
          try {
            final result = await _extractNfcData(tag, context);
            await NfcManager.instance.stopSession();
            _sessionRunning = false;
            completer.complete(result);
          } catch (e) {
            await NfcManager.instance.stopSession();
            _sessionRunning = false;
            completer.complete(
                {'success': false, 'error': 'Error reading NFC tag: $e'});
          }
        },
      );

      // Wait for the NFC session to complete
      return await completer.future;
    } catch (e) {
      _sessionRunning = false;
      return {'success': false, 'error': 'Error starting NFC session: $e'};
    }
  }

  /// Stop the current NFC session
  Future<void> stopSession() async {
    if (_sessionRunning) {
      await NfcManager.instance.stopSession();
      _sessionRunning = false;
    }
  }

  /// Extract written data from NFC tag (internal method)
  Future<Map<String, dynamic>> _extractNfcData(
      NfcTag tag, BuildContext? context) async {
    try {
      String? cardData;

      // Priority 1: Try NDEF extraction for written text/data
      try {
        final ndef = Ndef.from(tag);
        if (ndef != null) {
          final dynNdef = ndef as dynamic;
          final msg = dynNdef.cachedMessage;
          if (msg != null) {
            final records = msg.records as List<dynamic>?;
            if (records != null && records.isNotEmpty) {
              final parts = <String>[];
              for (final r in records) {
                try {
                  final payload = r.payload as dynamic;
                  if (payload is Uint8List || payload is List<int>) {
                    final bytes = payload is Uint8List
                        ? payload
                        : Uint8List.fromList(payload as List<int>);

                    // Try decode as NDEF Text record (most common for written data)
                    try {
                      final text = _decodeNdefText(bytes);
                      if (text != null && text.trim().isNotEmpty) {
                        parts.add(text.trim());
                        continue;
                      }
                    } catch (_) {}

                    // Try direct UTF-8 decode for plain text
                    try {
                      final text = utf8.decode(bytes);
                      if (text.trim().isNotEmpty) {
                        parts.add(text.trim());
                        continue;
                      }
                    } catch (_) {}

                    // Last resort: treat as raw bytes (could be encrypted data)
                    final rawString =
                        String.fromCharCodes(bytes.where((b) => b != 0));
                    if (rawString.trim().isNotEmpty) {
                      parts.add(rawString.trim());
                    }
                  } else if (payload is String && payload.trim().isNotEmpty) {
                    parts.add(payload.trim());
                  }
                } catch (_) {}
              }
              if (parts.isNotEmpty) {
                cardData = parts.join(' ');
              }
            }
          }
        }
      } catch (_) {}

      // Priority 2: If no NDEF data found, try raw tag data for written content
      if (cardData == null || cardData.isEmpty) {
        try {
          final dynamic tagData = (tag as dynamic).data;

          // Look for Mifare Ultralight data (common for simple NFC tags)
          if (tagData is Map && tagData.containsKey('mifareultralight')) {
            final mifareData = tagData['mifareultralight'];
            if (mifareData != null && mifareData['data'] != null) {
              final List<int> rawBytes = List<int>.from(mifareData['data']);

              // Filter out null bytes and system bytes (first few bytes are usually system data)
              final contentBytes = rawBytes.where((byte) => byte != 0).toList();
              if (contentBytes.length > 12) {
                // Skip system data (first ~12 bytes)
                final userDataBytes = contentBytes.skip(12).toList();
                try {
                  final text = utf8.decode(userDataBytes);
                  if (text.trim().isNotEmpty) {
                    cardData = text.trim();
                  }
                } catch (_) {
                  // If UTF-8 fails, treat as raw string
                  final rawText = String.fromCharCodes(userDataBytes);
                  if (rawText.trim().isNotEmpty) {
                    cardData = rawText.trim();
                  }
                }
              }
            }
          }

          // Try other tag types for written data
          if (cardData == null || cardData.isEmpty) {
            if (tagData is Map) {
              // Look for any field that might contain written data
              for (final key in tagData.keys) {
                final keyStr = key.toString().toLowerCase();
                if (keyStr.contains('data') ||
                    keyStr.contains('payload') ||
                    keyStr.contains('message') ||
                    keyStr.contains('content')) {
                  final value = tagData[key];
                  if (value is List<int>) {
                    try {
                      final text =
                          utf8.decode(value.where((b) => b != 0).toList());
                      if (text.trim().isNotEmpty) {
                        cardData = text.trim();
                        break;
                      }
                    } catch (_) {}
                  } else if (value is String && value.trim().isNotEmpty) {
                    cardData = value.trim();
                    break;
                  }
                }
              }
            }
          }
        } catch (_) {}
      }

      if (cardData == null || cardData.isEmpty) {
        return {'success': false, 'error': 'No written data found on NFC card'};
      }

      print(
          '📱 Card data extracted: ${cardData.length > 100 ? cardData.substring(0, 100) + '...' : cardData}');

      // Automatically call decryptapi after fetching card data
      try {
        print('🔐 Calling decryptapi with card data...');

        // Get vsid from variables or SQLite
        String currentVsid = vsid ?? '';
        if (currentVsid.isEmpty) {
          try {
            final databasePath = await getDatabasesPath();
            final dbPath = '${databasePath}/production_login.db';
            final database = await openDatabase(dbPath, version: 1);
            final List<Map<String, dynamic>> maps = await database.query(
              'login_data',
              orderBy: 'id ASC',
              limit: 1,
            );
            await database.close();

            if (maps.isNotEmpty && maps.first['vsid'] != null) {
              currentVsid = maps.first['vsid'].toString();
              print('📊 Retrieved vsid from SQLite: $currentVsid');
            } else {
              print('⚠️ No vsid found in SQLite database');
            }
          } catch (e) {
            print('❌ Error retrieving vsid from SQLite: $e');
          }
        }

        // Call decryptapi
        final decryptResult = await decryptapi(
          encryptdata: cardData,
          vsid: currentVsid,
        );

        print('🔐 Decrypt API Result:');
        print('  - Success: ${decryptResult['success']}');
        print('  - Status Code: ${decryptResult['statusCode']}');
        print('  - VCID: ${decryptResult['vcid']}');
        print('  - Body: ${decryptResult['body']}');

        // Show countdown dialog after decryptapi call
        if (decryptResult['success'] == true &&
            decryptResult['vcid'] != null &&
            context != null) {
          try {
            // Parse the decrypt result body to create user message
            String userMessage = '';
            try {
              final responseData = jsonDecode(decryptResult['body']);
              final userData = responseData['responseData'];
              if (userData != null) {
                userMessage = '''Name: ${userData['fname'] ?? 'N/A'}
Designation: ${userData['subunitname'] ?? 'N/A'}
Code: ${userData['code'] ?? 'N/A'}
Union Name: ${userData['unitname'] ?? 'N/A'}''';
              }
            } catch (e) {
              print('❌ Error parsing user data for dialog: $e');
              userMessage = 'User data available';
            }

            print('📱 Showing countdown dialog with user details');

            // Show the countdown dialog with user details
            showResultDialogi(
              context,
              userMessage,
              () {
                print('� Dialog dismissed callback executed');
              },
              decryptResult['vcid'].toString(),
              attendanceid?.toString() ??
                  '1', // Use attendanceid from variables or default to '1'
            );
          } catch (e) {
            print('❌ Error showing dialog: $e');
          }
        }

        return {
          'success': true,
          'cardData': cardData,
          'decryptResult': decryptResult,
        };
      } catch (decryptError) {
        print('❌ Error calling decryptapi: $decryptError');
        return {
          'success': true,
          'cardData': cardData,
          'decryptError': decryptError.toString(),
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error extracting NFC card data: $e'};
    }
  }

  // Helper methods

  /// Decode an NDEF Text record payload, stripping the status byte and
  /// language code (e.g. "en") and returning the decoded text. Returns
  /// null if the payload doesn't look like a text record.
  String? _decodeNdefText(Uint8List payload) {
    if (payload.isEmpty) return null;
    final status = payload[0];
    // status bits: bit7 = encoding (0 = UTF-8, 1 = UTF-16), bits 5..0 = lang length
    final isUtf16 = (status & 0x80) != 0;
    final langLen = status & 0x3F;
    if (payload.length <= 1 + langLen) return null;
    final textBytes = payload.sublist(1 + langLen);
    try {
      if (isUtf16) {
        return utf8.decode(textBytes); // attempting utf8 fallback for utf16
      } else {
        return utf8.decode(textBytes);
      }
    } catch (_) {
      return null;
    }
  }
}
