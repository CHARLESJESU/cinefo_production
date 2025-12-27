// Fetch and print VSID from login_data table
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:production/variables.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:production/sessionexpired.dart';

/// Check if the API response indicates session expiration
/// and navigate to SessionExpired screen if needed
/// Returns true if session expired, false otherwise
bool checkSessionExpiration(BuildContext context, http.Response response) {
  try {
    final responseBody = json.decode(response.body);

    // Check if the response contains session expired error
    if (responseBody is Map) {
      // Check in the root level
      if (responseBody['errordescription'] == "Session Expired") {
        print('⚠️ Session Expired detected - navigating to login');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Sessionexpired()),
          (route) => false,
        );
        return true;
      }

      // Check in nested error object if exists
      if (responseBody['error'] != null && responseBody['error'] is Map) {
        if (responseBody['error']['errordescription'] == "Session Expired") {
          print('⚠️ Session Expired detected - navigating to login');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Sessionexpired()),
            (route) => false,
          );
          return true;
        }
      }
    }
  } catch (e) {
    print('Error checking session expiration: $e');
  }
  return false;
}

Future<Map<String, dynamic>> decryptapi({
  required String encryptdata,
  required String vsid,
}) async {
  try {
    final payload = {"data": encryptdata};
    print("🚗🚗🚗🚗🚗🚗$vsid");
    final tripstatusresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'lHEiVtuLv8SFG0kxOydaeOm0OdIIZ9HGIYj4yxNL1AvGbTwX4GOxGwTe9EWnT4gIYGsegd6oxl3gRpQWJQDvvBzZ3DCehjDUCxKgXd5LiGgCRiKAhvpINP08iBxuQldbTVuIxdzV1X0RQJvUZ/cxh3mesg1gx9gWlHZ2mvZAxIPjdpZFY7HCyY058DD+uQGMAc5MpKs21MCQF2jTHI11y1EYoWoYqCH+2/Tf/bIeFtRwGM8keGaXrSShsskWKEXcS4t4jNRV3ch1/t/QPjcbFU4Lqg6GU35234pJmDHCLs5vDxCV2G7Ro7j8YZZkJMDc6xo39fRBT1YjL8tZ9sJ3ZQ==',
        'VSID': vsid,
      },
      body: jsonEncode(payload),
    );

    print('🚗 Decrypt API Response Status: ${tripstatusresponse.statusCode}');
    print('🚗 Decrypt API Response Status: ${payload}');
    print('🚗 Decrypts API Response Body: ${tripstatusresponse.body}');

    if (tripstatusresponse.statusCode == 200) {
      try {
        final responseBody = jsonDecode(tripstatusresponse.body);
        final vcid = responseBody['responseData']['vcid'];
        return {
          'statusCode': tripstatusresponse.statusCode,
          'body': tripstatusresponse.body,
          'vcid': vcid,
          'success': true,
        };
      } catch (parseError) {
        print('❌ Error parsing response: $parseError');
        return {
          'statusCode': tripstatusresponse.statusCode,
          'body': tripstatusresponse.body,
          'vcid': null,
          'success': true,
        };
      }
    } else {
      return {
        'statusCode': tripstatusresponse.statusCode,
        'body': tripstatusresponse.body,
        'vcid': null,
        'success': false,
      };
    }
  } catch (e) {
    print('❌ Error in decryptapi: $e');
    return {
      'statusCode': 0,
      'body': 'Error: $e',
      'vcid': null,
      'success': false,
    };
  }
}

Future<Map<String, dynamic>> datacollectionapi({
  required int vcid,
  required String rfid,
  required String vsid,
}) async {
  try {
    // Convert rfid from string to numerical type
    print('🔄 Converting RFID: $rfid');
    dynamic rfidNumeric;

    try {
      // First, try parsing as decimal (most common case for numeric strings)
      if (rfid.contains(':') || rfid.contains(' ')) {
        // If it contains separators, treat as hex
        String cleanRfid = rfid.replaceAll(':', '').replaceAll(' ', '');
        print('🔄 Cleaned hex RFID: $cleanRfid');
        rfidNumeric = BigInt.parse(cleanRfid, radix: 16);
        print('✅ Converted hex to BigInt: $rfidNumeric');

        // Try to convert to int if it fits
        if (rfidNumeric <= BigInt.from(0x7FFFFFFFFFFFFFFF)) {
          rfidNumeric = rfidNumeric.toInt();
          print('✅ Converted BigInt to int: $rfidNumeric');
        }
      } else {
        // Try parsing as decimal first
        rfidNumeric = BigInt.parse(rfid);
        print('✅ Parsed as decimal BigInt: $rfidNumeric');

        // Try to convert to int if it fits
        if (rfidNumeric <= BigInt.from(0x7FFFFFFFFFFFFFFF)) {
          rfidNumeric = rfidNumeric.toInt();
          print('✅ Converted BigInt to int: $rfidNumeric');
        }
      }
    } catch (parseError) {
      print(
          '⚠️ Could not parse RFID as number, keeping as string: $parseError');
      // Keep as string if conversion fails
      rfidNumeric = rfid;
    }

    final payload = {"vcid": vcid, "rfid": rfid};
    final tripstatusresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'cEaZFUbJTVPh4nn1q/OkOGnG7bxNbYO6J5u3eZbobZBDeLCyCVHe1D+ey6YNiy7HsWoceFbDts95o4VD7iwZ5VbIyfJd/9Wx6FS0eE5P+jxAh/MpyArcp8u5lM5qL8VAxiWzTNHns6quPcCsgB1jeMiFuhQozs0e5/tdHHDe2SQqtqQCfghKswFN9g+vElZ1wy1VRzbRQOHU16+CzxxKrRKbbczcJGNKZqbLk9ggw3fVcR2KYVHPRJWJ7E4GdvGWHTsotxbY9ZxlkdN6pasna9fMmIWf+TuLsKUphiNUEql/YsGRgu8U+YZRREMXjQcGlfysVb4BZzwdkV/8UfJ5jQ==',
        'VSID': vsid,
      },
      body: jsonEncode(payload),
    );

    print(
        '🚗 datacollection API Response Status: ${tripstatusresponse.statusCode}');
    print('🚗 datacollection API Response Status: ${payload}');
    print('🚗 datacollection API Response Body: ${tripstatusresponse.body}');

    return {
      'statusCode': tripstatusresponse.statusCode,
      'body': tripstatusresponse.body,
      'success': tripstatusresponse.statusCode == 200,
    };
  } catch (e) {
    print('❌ Error in tripstatusapi: $e');
    return {
      'statusCode': 0,
      'body': 'Error: $e',
      'success': false,
    };
  }
}

Future<void> printVSIDFromLoginData() async {
  try {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(path.join(dbPath, 'production_login.db'));
    final List<Map<String, dynamic>> loginRows =
        await db.query('login_data', orderBy: 'id ASC', limit: 1);
    if (loginRows.isNotEmpty && loginRows.first['vsid'] != null) {
      print('Fetched VSID from login_data: \\${loginRows.first['vsid']}');
      vsid = loginRows.first['vsid'];
      projectId = loginRows.first['project_id'];
      vmid = loginRows.first['vmid'];
      vpid = loginRows.first['vpid'];
      vpoid = loginRows.first['vpoid'];
      vbpid = loginRows.first['vbpid'];
      productionTypeId = loginRows.first['production_type_id'];
    } else {
      print('VSID not found in login_data table.');
    }
    await db.close();
  } catch (e) {
    print('Error fetching VSID from login_data: \\${e.toString()}');
  }
}

void showmessage(BuildContext context, String message, String ok) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: const Text('Message'),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25),
            child: Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.start,
              overflow: TextOverflow.visible,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

void showsuccessPopUp(
    BuildContext context, String message, Future<void> Function() onDismissed) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text('Message'),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Text(message),
          ),
        ],
      );
    },
  );

  Future.delayed(const Duration(seconds: 1), () async {
    Navigator.of(context).pop();
    print('Pop-up dismissed');
    await onDismissed();
  });
}

// Alternative showsuccessPopUp with VoidCallback (for backward compatibility)
void showsuccessPopUpSync(
    BuildContext context, String message, VoidCallback onDismissed) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text('Message'),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Text(message),
          ),
        ],
      );
    },
  );

  Future.delayed(const Duration(seconds: 1), () {
    Navigator.of(context).pop();
    print('Pop-up dismissed');
    onDismissed();
  });
}

void showSimplePopUp(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: const Text('Message'),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25),
            child: Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.start,
              overflow: TextOverflow.visible,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

Widget commonRow(String imagePath, String text, int number) {
  return Row(
    children: [
      Image.asset(
        imagePath,
        width: 50,
        height: 50,
      ),
      const SizedBox(width: 10),
      Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      Spacer(),
      Text(
        number.toString(),
        style: const TextStyle(fontSize: 14, color: Colors.blue),
      ),
    ],
  );
}
