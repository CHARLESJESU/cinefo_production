import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:production/Screens/Home/importantfunc.dart';
import 'package:sqflite/sqflite.dart';
import '../../variables.dart';

class NfcHomePage extends StatefulWidget {
  const NfcHomePage({super.key});

  @override
  State<NfcHomePage> createState() => _NfcHomePageState();
}

class _NfcHomePageState extends State<NfcHomePage> {
  String _status = 'Ready to scan NFC card. Please tap your card...';
  // ignore: unused_field
  String? _uidHex; // Used internally for processing
  String? _uidDec;
  bool _isSubmitting = false;
  bool _isRegistrationComplete = false;
  Map<String, dynamic>? _userDetails;

  bool _isAvailable = false;
  bool _sessionRunning = false;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    try {
      bool available = await NfcManager.instance.isAvailable();
      setState(() => _isAvailable = available);
      if (available && !_isRegistrationComplete) {
        // Automatically start scanning when available
        _startSession();
      }
    } catch (_) {
      setState(() => _isAvailable = false);
    }
  }

  String _bytesToHex(Uint8List bytes, {String separator = ':'}) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(separator);
  }

  String _bytesToDecLE(Uint8List bytes) {
    BigInt value = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      value |= (BigInt.from(bytes[i]) << (8 * i));
    }
    return value.toString();
  }

  String _bytesToDecLast9(Uint8List bytes) {
    final dec = _bytesToDecLE(bytes);
    if (dec.length <= 10) return dec.padLeft(10, '0');
    return dec.substring(dec.length - 10);
  }

  Uint8List? _findIdIn(dynamic node) {
    if (node == null) return null;

    if (node is Uint8List) {
      if (node.length >= 4 && node.length <= 16) return node;
    }

    if (node is List<int>) {
      final bytes = Uint8List.fromList(node);
      if (bytes.length >= 4 && bytes.length <= 16) return bytes;
    }

    if (node is Map) {
      for (final key in node.keys) {
        final value = node[key];
        final keyLower = key.toString().toLowerCase();
        if (keyLower.contains('id') || keyLower.contains('identifier')) {
          final found = _findIdIn(value);
          if (found != null) return found;
        }
      }
      for (final value in node.values) {
        final found = _findIdIn(value);
        if (found != null) return found;
      }
    }

    if (node is List) {
      for (final item in node) {
        final found = _findIdIn(item);
        if (found != null) return found;
      }
    }

    // Try common dynamic properties safely
    try {
      final dyn = node as dynamic;
      for (final prop in ['id', 'ID', 'identifier', 'tag', 'uid', 'UID']) {
        try {
          final val = _tryGetProp(dyn, prop);
          if (val != null) {
            final found = _findIdIn(val);
            if (found != null) return found;
          }
        } catch (_) {}
      }
    } catch (_) {}

    return null;
  }

  dynamic _tryGetProp(dynamic obj, String name) {
    if (obj == null) return null;
    try {
      if (obj is Map) {
        if (obj.containsKey(name)) return obj[name];
        final lower = name.toLowerCase();
        if (obj.containsKey(lower)) return obj[lower];
        return null;
      }
    } catch (_) {}

    try {
      final dyn = obj as dynamic;
      switch (name) {
        case 'id':
          return dyn.id;
        case 'ID':
          return dyn.ID;
        case 'identifier':
          return dyn.identifier;
        case 'tag':
          return dyn.tag;
        case 'uid':
          return dyn.uid;
        case 'UID':
          return dyn.UID;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

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
        return utf8.decode(
          textBytes,
        ); // attempting utf8 fallback for utf16 is hard; try utf8 first
      } else {
        return utf8.decode(textBytes);
      }
    } catch (_) {
      return null;
    }
  }

  /// (Removed long recursive string search to simplify code.)

  // Method to get login data from SQLite database
  Future<Map<String, dynamic>?> _getLoginDataFromSQLite() async {
    try {
      final databasePath = await getDatabasesPath();
      final dbPath = '${databasePath}/production_login.db';

      final database = await openDatabase(
        dbPath,
        version: 1,
      );

      final List<Map<String, dynamic>> maps = await database.query(
        'login_data',
        orderBy: 'id ASC', // Get the first user (lowest ID)
        limit: 1,
      );

      await database.close();

      if (maps.isNotEmpty) {
        print('📊 Retrieved login data from SQLite: ${maps.first}');
        return maps.first;
      }
      return null;
    } catch (e) {
      print('❌ Error getting login data from SQLite: $e');
      return null;
    }
  }

  void _startSession() async {
    if (!_isAvailable) {
      setState(() => _status = 'NFC not available on this device');
      return;
    }

    setState(() {
      _status = 'Waiting for tag...';
      _uidHex = null;
      _uidDec = null;
      _sessionRunning = true;
    });

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        try {
          // First, try NDEF extraction (most large encrypted payloads are
          // stored in NDEF records). Use the nfc_manager_ndef wrapper to
          // access records if available.
          String? ndefPayload;
          try {
            final ndef = Ndef.from(tag);
            if (ndef != null) {
              // use dynamic to avoid tight typing on library internals
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
                        // Try decode as NDEF Text record (strip language code like 'en')
                        try {
                          final text =
                              _decodeNdefText(bytes) ?? utf8.decode(bytes);
                          if (text.trim().isNotEmpty) {
                            parts.add(text.trim());
                            continue;
                          }
                        } catch (_) {}
                        // Fallback to base64
                        parts.add(base64.encode(bytes));
                      } else if (payload is String) {
                        parts.add(payload);
                      } else {
                        parts.add(payload.toString());
                      }
                    } catch (_) {}
                  }
                  if (parts.isNotEmpty) ndefPayload = parts.join(' ');
                }
              }
            }
          } catch (_) {}

          // Capture a meaningful representation of tag.data. Some plugin
          // implementations return a platform object (TagPigeon) whose
          // toString() is just "Instance of 'TagPigeon'". Try to extract a
          // useful string: map -> pretty JSON, bytes -> base64, or search for
          // long strings (payloads) inside the structure.
          final dynamic tagData = (tag as dynamic).data;
          // prefer ndefPayload if found
          String tagDataRepr;
          try {
            if (tagData == null) {
              tagDataRepr = '';
            } else if (tagData is Map) {
              tagDataRepr = const JsonEncoder.withIndent('  ').convert(tagData);
            } else if (tagData is Uint8List) {
              tagDataRepr = base64.encode(tagData);
            } else if (tagData is List<int>) {
              tagDataRepr = base64.encode(Uint8List.fromList(tagData));
            } else if (tagData is String) {
              tagDataRepr = tagData;
            } else {
              tagDataRepr = tagData.toString();
            }
          } catch (_) {
            tagDataRepr = tagData?.toString() ?? '';
          }

          String raw = ndefPayload ??
              (tagDataRepr.isNotEmpty ? tagDataRepr : null) ??
              tag.toString();

          // Produce a full debug dump and print it to console (and save to
          // state so it's visible in-app). Keep this detailed for debugging.
          String dump;
          try {
            if (tagData is Map) {
              dump = const JsonEncoder.withIndent('  ').convert(tagData);
            } else if (tagData is Uint8List) {
              dump =
                  'Uint8List(len=${tagData.length}): ${base64.encode(tagData)}';
            } else if (tagData is List<int>) {
              final bytes = Uint8List.fromList(tagData);
              dump = 'List<int>(len=${bytes.length}): ${base64.encode(bytes)}';
            } else {
              dump = tagData.toString();
            }
          } catch (e) {
            dump = 'Error dumping tag.data: $e';
          }

          // Also include tag.toString() for completeness.
          final fullDump =
              'tag.toString(): ${tag.toString()}\n tag.data dump:\n$dump';
          // Print to console (debugPrint handles long messages better).
          debugPrint(fullDump, wrapWidth: 1200);

          // Attempt to find UID bytes as before
          final uidBytes = _findIdIn((tag as dynamic).data);

          if (uidBytes != null) {
            final hex = _bytesToHex(uidBytes);
            final dec = _bytesToDecLast9(uidBytes);
            setState(() {
              _uidHex = hex;
              _uidDec = dec;
              _status = 'Tag found — Processing...';
            });

            // Automatically call decrypt API
            await _processNfcData(raw, dec);
          } else {
            // fallback: try some properties
            dynamic maybeId = _tryGetProp((tag as dynamic).data, 'id') ??
                _tryGetProp((tag as dynamic).data, 'ID') ??
                _tryGetProp((tag as dynamic).data, 'tag');
            final fallback = _findIdIn(maybeId);
            if (fallback != null) {
              final hex = _bytesToHex(fallback);
              final dec = _bytesToDecLast9(fallback);
              setState(() {
                _uidHex = hex;
                _uidDec = dec;
                _status = 'Tag found — Processing...';
              });

              // Automatically call decrypt API
              await _processNfcData(raw, dec);
            } else {
              setState(() {
                _status = 'Tag found — raw data captured';
                _uidHex = null;
                _uidDec = null;
              });

              // Try to process with raw data only
              await _processNfcData(raw, '');
            }
          }
        } catch (e) {
          setState(() {
            _status = 'Error reading tag: $e';
          });
        } finally {
          await NfcManager.instance.stopSession();
          setState(() => _sessionRunning = false);
        }
      },
    );
  }

  // Method to start countdown and automatically restart scanning
  void _startCountdownAndRestart() {
    setState(() {
      _countdown = 3; // Start with 3 seconds
    });

    // Update countdown every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isRegistrationComplete = false;
            _uidHex = null;
            _uidDec = null;
            _userDetails = null;
            _status = 'Ready to scan next NFC card...';
            _countdown = 0;
          });
          _startSession(); // Automatically start next scan
        }
      }
    });
  }

  Future<void> _processNfcData(String rawData, String uidDec) async {
    try {
      setState(() => _status = 'Decrypting data...');

      // Check if vsid is empty and get it from SQLite if needed
      String currentVsid = vsid ?? '';
      if (currentVsid.isEmpty) {
        try {
          final loginData = await _getLoginDataFromSQLite();
          if (loginData != null && loginData['vsid'] != null) {
            currentVsid = loginData['vsid'].toString();
            print('📊 Retrieved vsid from SQLite: $currentVsid');
          } else {
            print('⚠️ No vsid found in SQLite database');
          }
        } catch (e) {
          print('❌ Error retrieving vsid from SQLite: $e');
        }
      }

      // Call the decrypt API with all three parameters
      final result = await decryptapi(
        encryptdata: rawData, // Raw NFC data // UID in decimal format
        vsid: currentVsid, // Using vsid from variables or SQLite
      );

      if (mounted) {
        if (result['success'] == true) {
          // Parse the response to extract user details
          try {
            final responseBody = result['body'];
            print('🔍 Decrypt API Response: $responseBody');

            // Parse JSON response to extract user details
            final responseData = jsonDecode(responseBody);
            final userData = responseData['responseData'];

            if (userData != null) {
              final mobileNumber =
                  userData['mobileNumber']?.toString() ?? 'N/A';
              final fname = userData['fname']?.toString() ?? 'N/A';
              final code = userData['code']?.toString() ?? 'N/A';
              final vcid = userData['vcid'];

              // Store user details and vcid for later use
              _userDetails = {
                'mobileNumber': mobileNumber,
                'fname': fname,
                'code': code,
                'vcid': vcid,
              };

              setState(() => _status = 'User details fetched successfully');

              // Show user details dialog
              _showUserDetailsDialog(mobileNumber, fname, code);
            } else {
              setState(() => _status = 'Failed to extract user details');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to extract user details from response'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (parseError) {
            print('❌ Error parsing decrypt response: $parseError');
            setState(() => _status = 'Error parsing response');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error parsing decrypt response: $parseError'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          setState(() => _status = 'Decryption failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Decryption failed: ${result['body']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Error processing NFC data');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing NFC data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserDetailsDialog(String mobileNumber, String fname, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mobile Number: $mobileNumber',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Name: $fname', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Code: $code', style: const TextStyle(fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Call data collection API after OK is pressed
                _performDataCollection();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDataCollection() async {
    if (_userDetails == null || _userDetails!['vcid'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user details available for registration'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _status = 'Registering attendance...';
    });

    try {
      // Check if vsid is empty and get it from SQLite if needed
      String currentVsid = vsid ?? '';
      if (currentVsid.isEmpty) {
        try {
          final loginData = await _getLoginDataFromSQLite();
          if (loginData != null && loginData['vsid'] != null) {
            currentVsid = loginData['vsid'].toString();
            print(
                '📊 Retrieved vsid from SQLite for data collection: $currentVsid');
          } else {
            print('⚠️ No vsid found in SQLite database for data collection');
          }
        } catch (e) {
          print('❌ Error retrieving vsid from SQLite for data collection: $e');
        }
      }

      final dataCollectionResult = await datacollectionapi(
        vcid: _userDetails!['vcid'],
        rfid: _uidDec ?? '', // Using UID decimal as RFID
        vsid: currentVsid, // Using vsid from variables or SQLite
      );

      if (mounted) {
        if (dataCollectionResult['success'] == true) {
          setState(() {
            _isRegistrationComplete = true;
            _status = 'Registration completed successfully';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully registered!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          print('✅ Data collection API successful');

          // Start countdown and auto-restart scanning
          _startCountdownAndRestart();
        } else {
          setState(() => _status = 'Registration failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Registration failed: ${dataCollectionResult['body']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          print(
              '❌ Data collection API failed: ${dataCollectionResult['body']}');
        }
      }
    } catch (dataCollectionError) {
      if (mounted) {
        setState(() => _status = 'Registration error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: $dataCollectionError'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        print('❌ Error in data collection API: $dataCollectionError');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC Attendance Scanner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _isAvailable ? Icons.nfc : Icons.nfc_outlined,
                      size: 48,
                      color: _isAvailable ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'NFC Status: ${_isAvailable ? "Available" : "Not Available"}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Status:',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    if (_isSubmitting) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (_isRegistrationComplete) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Attendance registered successfully!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_countdown > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Next scan starts in $_countdown seconds...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else if (!_isAvailable) ...[
              const Card(
                color: Colors.red,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'NFC is not available on this device',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'Hold your NFC card near the phone to scan',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_sessionRunning) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }
}
