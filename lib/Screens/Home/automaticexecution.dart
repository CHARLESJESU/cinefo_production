// Fetch and print VSID from login_data table
import 'package:http/http.dart' as http;
import 'package:production/Screens/Home/importantfunc.dart';
import 'dart:convert';
import 'package:production/variables.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

int k = 0;

Future<void> processAllOfflineCallSheets() async {
  try {
    // Get database path and open connection
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(path.join(dbPath, 'production_login.db'));

    // Ensure callsheetoffline table exists before querying
    await db.execute('''
      CREATE TABLE IF NOT EXISTS callsheetoffline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        callSheetId INTEGER,
        callSheetNo TEXT,
        MovieName TEXT,
        callsheetname TEXT,
        shift TEXT,
        shiftId INTEGER,
        latitude REAL,
        longitude REAL,
        projectId TEXT,
        productionTypeid INTEGER,
        location TEXT,
        locationType TEXT,
        locationTypeId INTEGER,
        created_at TEXT,
        status TEXT,
        created_at_time TEXT,
        created_date TEXT,
        pack_up_time TEXT,
        pack_up_date TEXT,
        isonline TEXT
      )
    ''');
    print('✅ callsheetoffline table verified/created');

    // Query all records from callsheetoffline table
    final List<Map<String, dynamic>> callsheetRecords = await db.query(
      'callsheetoffline',
      orderBy: 'id ASC', // Process in order
    );

    await db.close();

    if (callsheetRecords.isEmpty) {
      print('No callsheets found to process.');
      return;
    }

    print('Found ${callsheetRecords.length} callsheet(s) to process.');

    // Process each callsheet record one by one
    for (int i = 0; i < callsheetRecords.length; i++) {
      final callsheetData = callsheetRecords[i];
      k++;
      print(
          'Processing callsheet ${i + 1}/${callsheetRecords.length}: ${callsheetData['callSheetNo']}');

      try {
        await createCallSheetFromOfflineWithoutContext(callsheetData);
        print(
            'Successfully processed callsheet: ${callsheetData['callSheetNo']}');
      } catch (e) {
        print('Error processing callsheet ${callsheetData['callSheetNo']}: $e');
        // Continue with next record even if current one fails
        continue;
      }
    }

    print('Finished processing all callsheets.');
  } catch (e) {
    print('Error in processAllOfflineCallSheets: $e');
  }
}

Future<void> createCallSheetFromOfflineWithoutContext(
    Map<String, dynamic> callsheetData) async {
  Map? createCallSheetresponse1;
  Map<String, dynamic>? responseData;
  http.Response? response;

  await printVSIDFromLoginData();

  // CRITICAL DEBUG: Log initial state to track isonline changes
  print("\n🆔 === Processing callsheet: ${callsheetData['callSheetNo']} ===");
  print(
      "🔍 INITIAL isonline value: '${callsheetData['isonline']}' (type: ${callsheetData['isonline'].runtimeType})");

  // Check if callsheet was created offline
  if (callsheetData['isonline'] == '0') {
    print(
        "✅ Callsheet is offline (isonline='0'), proceeding with HTTP request...");
    print("✅ Callsheet is offline, proceeding with creation...");
    //start here

    final payload = {
      "name": callsheetData['callsheetname'] ?? '',
      "tempId": callsheetData['callSheetId']?.toString() ?? '',
      "shiftId": callsheetData['shiftId'] ?? '',
      "latitude": callsheetData['latitude'] ?? '',
      "longitude": callsheetData['longitude'] ?? '',
      "projectId": projectId ?? '',
      "vmid": vmid ?? '',
      "vpid": vpid ?? '',
      "vpoid": vpoid ?? '',
      "vbpid": vbpid ?? '',
      "productionTypeid": productionTypeId ?? '',
      "location": callsheetData['location'] ?? '',
      "locationType": callsheetData['locationType'] ?? '',
      "locationTypeId": callsheetData['locationTypeId'] ?? '',
      "date": callsheetData['created_at'] ?? '',
      "createdDate": callsheetData['created_date'] ?? '',
      "createdTime": callsheetData['created_at_time'] ?? '',
    };

    response = await http.post(
      processSessionRequest,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'U2DhAAJYK/dbno+9M7YQDA/pzwEzOu43/EiwXnpz9lfxZA32d6CyxoYt1OfWxfE1oAquMJjvptk3K/Uw1/9mSknCQ2OVkG+kIptUboOqaxSqSXbi7MYsuyUkrnedc4ftw0SORisKVW5i/w1q0Lbafn+KuOMEvxzLXjhK7Oib+n4wyZM7VhIVYcODI3GZyxHmxsstQiQk9agviX9U++t4ZD4C7MbuIJtWCYuClDarLhjAXx3Ulr/ItA3RgyIUD6l3kjpsHxWLqO3kkZCCPP8N5+7SoFw4hfJIftD7tRUamgNZQwPzkq60YRIzrs1BlAQEBz4ofX1Uv2ky8t5XQLlEJw==',
        'VSID': vsid ?? "",
      },
      body: jsonEncode(payload),
    );
    print(response.body + "❌❌❌❌❌❌❌❌❌");
    print('Request Payload:');
    payload.forEach((key, value) {
      print('$key: $value');
    });
    print('VSID: ${loginresponsebody?['vsid']?.toString() ?? ""}');
    print('Response: ${response.body}');
    print('----------------------------------------');
    print(
        "🔍 HTTP Response Status Code: ${response.statusCode} for callsheet: ${callsheetData['callSheetNo']}");

    // Parse the response regardless of status code to check the message
    try {
      createCallSheetresponse1 = json.decode(response.body);
    } catch (e) {
      print("❌ Failed to parse response JSON: $e");
      createCallSheetresponse1 = null;
    }

    if (createCallSheetresponse1?['status'] == "200") {
      print(
          "✅✅✅ STATUS CODE 200 - EXECUTING isonline update for callsheet: ${callsheetData['callSheetNo']}");
      print(response.body);
      // Try to update isonline value - handle read-only map issue
      try {
        callsheetData['isonline'] = '1';
        print(
            "✅✅✅ SUCCESS: Set callsheetData['isonline'] = '1' for callsheet: ${callsheetData['callSheetNo']}");
      } catch (e) {
        print("❌ Cannot modify callsheetData (read-only): $e");
        // Update the database directly instead
        try {
          var dbPath = await getDatabasesPath();
          var db = await openDatabase(dbPath + '/production_login.db');
          await db.update(
            'callsheetoffline',
            {'isonline': '1'},
            where: 'callSheetNo = ?',
            whereArgs: [callsheetData['callSheetNo']],
          );
          await db.close();
          print("✅ Updated isonline in database directly");
        } catch (dbError) {
          print("❌ Error updating database: $dbError");
        }
      }

      print(
          "📋 Server response message: ${createCallSheetresponse1?['message']}");
      print(
          "📋 Server response status: ${createCallSheetresponse1?['status']}");

      if (createCallSheetresponse1?['message'] == "Success") {
        responseData = createCallSheetresponse1?['responseData'];

        print("Created call sheet successfully");
      } else {
        print('Error: ${createCallSheetresponse1?['message']}');
      }
    } else {
      print(
          "❌❌❌ STATUS CODE ${response.statusCode} - NOT EXECUTING isonline update for callsheet: ${callsheetData['callSheetNo']}");
      print(
          "❌❌❌ isonline should remain '0' for callsheet: ${callsheetData['callSheetNo']}");
      print("❌ HTTP Error Response: ${response.body}");
    }
  } else {
    print(
        "⏭️ Callsheet ${callsheetData['callSheetNo']} is already online (isonline != '0'), skipping HTTP request");
  }

  // CRITICAL DEBUG: Check final isonline value after HTTP processing
  print(
      "🔍🔍🔍 FINAL isonline value for ${callsheetData['callSheetNo']}: '${callsheetData['isonline']}'\n");

  // false condition
  // Continue with intime and closecallsheet processes (always execute)
  try {
    var dbPath = await getDatabasesPath();
    var mainDb = await openDatabase(dbPath + '/production_login.db');

    // Use responseData if available (from callsheet creation), otherwise use existing callsheetData
    String callsheetId =
        (responseData?['callSheetId'] ?? callsheetData['callSheetId'])
            .toString();

    // Handle intime table schema migration
    try {
      // First check if the table has the correct schema by checking columns
      var result = await mainDb.rawQuery("PRAGMA table_info(intime)");
      List<String> existingColumns =
          result.map((row) => row['name'] as String).toList();

      bool hasCorrectSchema = [
        'name',
        'designation',
        'code',
        'unionName',
        'marked_at',
        'mode'
      ].every((col) => existingColumns.contains(col));

      if (!hasCorrectSchema && existingColumns.isNotEmpty) {
        print('⚠️ intime table has incorrect schema. Recreating table...');

        // Backup existing data
        var existingData = await mainDb.query('intime');

        // Drop and recreate with correct schema
        await mainDb.execute('DROP TABLE IF EXISTS intime');
        await mainDb.execute('''
          CREATE TABLE intime (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            designation TEXT,
            code TEXT,
            unionName TEXT,
            vcid TEXT,
            marked_at TEXT,
            latitude TEXT,
            longitude TEXT,
            location TEXT,
            attendance_status TEXT,
            callsheetid INTEGER,
            mode TEXT,
            attendanceDate TEXT,
            attendanceTime TEXT
          )
        ''');

        // Restore data that can be migrated
        for (var row in existingData) {
          Map<String, dynamic> migratedData = {
            'vcid': row['vcid'],
            'callsheetid': row['callsheetid'],
            'latitude': row['latitude'],
            'longitude': row['longitude'],
            'attendance_status': row['attendance_status'],
            'location': row['location'],
            'attendanceDate': row['attendanceDate'],
            'attendanceTime': row['attendanceTime'],
            'name': '', // Set defaults for new columns
            'designation': '',
            'code': '',
            'unionName': '',
            'marked_at': '',
            'mode': 'offline'
          };
          await mainDb.insert('intime', migratedData);
        }

        print('✅ intime table recreated with correct schema and data migrated');
      } else {
        // Create table if it doesn't exist
        await mainDb.execute('''
          CREATE TABLE IF NOT EXISTS intime (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            designation TEXT,
            code TEXT,
            unionName TEXT,
            vcid TEXT,
            marked_at TEXT,
            latitude TEXT,
            longitude TEXT,
            location TEXT,
            attendance_status TEXT,
            callsheetid INTEGER,
            mode TEXT,
            attendanceDate TEXT,
            attendanceTime TEXT
          )
        ''');
        print('✅ intime table verified or created with complete schema');
      }
    } catch (e) {
      print('⚠️ Error handling intime table: $e');
    }

    // Query the updated rows for syncing
    List<Map<String, dynamic>> rows = [];
    try {
      rows = await mainDb.query(
        'intime',
        where: 'callsheetid = ?',
        whereArgs: [callsheetId],
        orderBy: 'id ASC', // FIFO
      );
    } catch (e) {
      print('⚠️ Error querying intime table: $e');
      rows = []; // Set empty list if query fails
    }
    print("❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌");
    print("🔍🔍🔍 ROWS COUNT: ${rows.length}");
    if (rows.isEmpty) {
      print("🎯 TAKING FIRST PATH: rows.isEmpty = true");
      print(
          "🔍 DEBUG: rows.isEmpty = true, checking callsheet status for closing...");
      print(
          "🔍 callsheetData['status']: '${callsheetData['status']}' (type: ${callsheetData['status'].runtimeType})");
      print(
          "🔍 Condition check: callsheetData['status'] == 'closed' = ${callsheetData['status'] == 'closed'}");

      if (callsheetData['status'] == 'closed') {
        print(
            "🎯 FIRST CONDITION: Callsheet status is 'closed' and rows is empty, proceeding with HTTP close request...");
       final payload = {
            "callshettId": 0,
            "tempId": callsheetId,
            "projectid": projectId,
            "shiftid": callsheetData['shiftId'],
            "callSheetStatusId": 3,
            "callSheetTime": callsheetData['pack_up_time'] ??
                DateFormat('HH:mm').format(DateTime.now()),
            "callsheetcloseDate": callsheetData['pack_up_date'] ??
                DateFormat('dd-MM-yyyy').format(DateTime.now()),
          };
        await http.post(
          processSessionRequest,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'VMETID':
                'O/OtGf1bn9oD4GFpjRQ+Dec3uinWC4FwTdbrFCyiQDpN8SPMhon+ZaDHuLsnBHmfqGAjFXy6Gdjt6mQwzwqgfdWu+e+M8qwNk8gX9Ca3JxFQc++CDr8nd1Mrr57aHoLMlXprbFMxNy7ptfNoccm61r/9/lHCANMOt85n05HVfccknlopttLI5WM7DsNVU60/x5qylzlpXL24l8KwEFFPK1ky410+/uI3GkYi0l1u9DektKB/m1CINVbQ1Oob+FOW5lhNsBjqgpM/x1it89d7chbThdP5xlpygZsuG0AW4lakebF3ze497e16600v72fclgAZ3M21C0zUM4w9XIweMg==',
            'VSID': vsid ?? "",
          },
          body: jsonEncode(payload),
        );
        print('--- ✅ Call Sheet Closed Successfully ---');
        try {
          // Ensure database is still open
          if (!mainDb.isOpen) {
            mainDb = await openDatabase(dbPath + '/production_login.db');
          }

          await mainDb.delete(
            'callsheetoffline',
            where: 'callSheetId = ?',
            whereArgs: [callsheetId],
          );
          print('Deleted callsheetoffline row for callSheetId: ' + callsheetId);
        } catch (e) {
          print('Error deleting callsheetoffline row: ' + e.toString());
        }
      } else {
        print(
            "❌ FIRST CONDITION: Callsheet status is NOT 'closed'. Status: '${callsheetData['status']}'");
        print("❌ Skipping call sheet closing HTTP request in first condition.");
      }
    } else {
      print(
          "🎯 TAKING SECOND PATH: rows.isEmpty = false, processing attendance records first");
      for (final row in rows) {
        print('IntimeSyncService: Attempting to POST row id=${row['id']}');

        final requestBody = jsonEncode({
          "data": row['vcid'],
          "tempId": row['callsheetid'],
          "callsheetid": 0,
          "projectid": projectId,
          "productionTypeId": productionTypeId,
          "doubing": {},
          "latitude": row['latitude'],
          "longitude": row['longitude'],
          "attendanceStatus": row['attendance_status'],
          "location": row['location'],
          "attendanceDate": row['attendanceDate'] ?? '',
          "attendanceTime": row['attendanceTime'] ?? '',
        });

        // Get VSID from loginresponsebody or fallback to SQLite
        String? vsidLocal = loginresponsebody?['vsid']?.toString();
        if (vsidLocal == null || vsidLocal.isEmpty) {
          try {
            final dbPath2 = await getDatabasesPath();
            final db2 =
                await openDatabase(path.join(dbPath2, 'production_login.db'));
            final List<Map<String, dynamic>> loginRows =
                await db2.query('login_data', orderBy: 'id ASC', limit: 1);
            if (loginRows.isNotEmpty && loginRows.first['vsid'] != null) {
              vsidLocal = loginRows.first['vsid'].toString();
            }
            await db2.close();
          } catch (e) {
            print('Error fetching vsid from SQLite: $e');
          }
        }

        print("📊📊📊📊📊📊📊📊📊📊 VSID: $vsidLocal");
        print("📊📊📊📊📊📊📊📊📊📊 Request Body: $processSessionRequest");
        final intimeResponse = await http.post(
          processSessionRequest,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'VMETID':
                "ZRaYT9Da/Sv4QuuHfhiVvjCkg5cM5eCUEIN/w8pmJuIB0U/tbjZYxO4ShGIQEr4e5w2lwTSWArgTUc1AcaU/Qi9CxL6bi18tfj5+SWs+Sc9TV/1EMOoJJ2wxvTyRIl7+F5Tz7ELXkSdETOQCcZNaGTYKy/FGJRYVs3pMrLlUV59gCnYOiQEzKObo8Iz0sYajyJld+/ZXeT2dPStZbTR4N6M1qbWvS478EsPahC7vnrS0ZV5gEz8CYkFS959F2IpSTmEF9N/OTneYOETkyFl1BJhWJOknYZTlwL7Hrrl9HYO12FlDRgNUuWCJCepFG+Rmy8VMZTZ0OBNpewjhDjJAuQ==",
            'VSID': vsidLocal ?? "",
          },
          body: requestBody,
        );
        print(
            'IntimeSyncService: Sending POST request with body: $requestBody');
        // Print response body in chunks to handle large responses
        print('📊 Response body length: ${intimeResponse.body.length}');
        if (intimeResponse.body.isNotEmpty) {
          const int chunkSize = 800; // Print in chunks of 800 characters
          for (int i = 0; i < intimeResponse.body.length; i += chunkSize) {
            int end = (i + chunkSize < intimeResponse.body.length)
                ? i + chunkSize
                : intimeResponse.body.length;
            print(
                '📊 Chunk ${(i / chunkSize).floor() + 1}: ${intimeResponse.body.substring(i, end)}');
          }
        } else {
          print('📊 Response body is empty');
        }

        print(
            'IntimeSyncService: POST statusCode=${intimeResponse.statusCode}');
        if (intimeResponse.statusCode == 200 ||
            intimeResponse.statusCode == 1017) {
          print(
              "IntimeSyncService: Deleting row id=${row['id']} after successful POST.");

          // Ensure database is still open before deletion
          if (!mainDb.isOpen) {
            print('❌ Database is closed, reopening...');
            mainDb = await openDatabase(dbPath + '/production_login.db');
          }

          try {
            final deleteResult = await mainDb
                .delete('intime', where: 'id = ?', whereArgs: [row['id']]);
            if (deleteResult > 0) {
              print("✅ Successfully deleted record id=${row['id']}");
            } else {
              print("⚠️ No record found with id=${row['id']} to delete");
            }
          } catch (e) {
            print('❌ Error deleting record id=${row['id']}: $e');
            // Try to reopen database and retry once
            try {
              if (mainDb.isOpen) {
                await mainDb.close();
              }
              mainDb = await openDatabase(dbPath + '/production_login.db');
              final retryResult = await mainDb
                  .delete('intime', where: 'id = ?', whereArgs: [row['id']]);
              if (retryResult > 0) {
                print("✅ Successfully deleted record id=${row['id']} on retry");
              } else {
                print(
                    "⚠️ No record found with id=${row['id']} to delete on retry");
              }
            } catch (retryError) {
              print(
                  '❌ Retry delete failed for record id=${row['id']}: $retryError');
            }
          }
        } else if (intimeResponse.statusCode == -1 ||
            intimeResponse.statusCode == 400 ||
            intimeResponse.statusCode == 500) {
          print(
              "IntimeSyncService: Skipping row id=${row['id']} due to statusCode=${intimeResponse.statusCode}. Data not deleted.");
          // Skip this row, do not delete, continue to next row
          continue;
        } else {
          print(
              "IntimeSyncService: POST failed for row id=${row['id']}, stopping sync this cycle.");
          // Stop on first failure to preserve FIFO
          break;
        }
      }

      // After all attendance syncing is complete, close the call sheet
      print("🔍 DEBUG: Checking callsheet status for closing...");
      print(
          "🔍 callsheetData['status']: '${callsheetData['status']}' (type: ${callsheetData['status'].runtimeType})");
      print(
          "🔍 Condition check: callsheetData['status'] == 'closed' = ${callsheetData['status'] == 'closed'}");

      if (callsheetData['status'] == 'closed') {
        print("⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ");
        print(
            "✅ Callsheet status is 'closed', proceeding with HTTP close request...");
        final payload={
            "callshettId": 0,
            "tempId": callsheetId,
            "projectid": projectId,
            "shiftid": callsheetData['shiftId'],
            "callSheetStatusId": 3,
            "callSheetTime": callsheetData['pack_up_time'] ??
                DateFormat('HH:mm').format(DateTime.now()),
            "callsheetcloseDate": callsheetData['pack_up_date'] ??
                DateFormat('dd-MM-yyyy').format(DateTime.now()),
          };
        await http.post(
          processSessionRequest,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'VMETID':
                'O/OtGf1bn9oD4GFpjRQ+Dec3uinWC4FwTdbrFCyiQDpN8SPMhon+ZaDHuLsnBHmfqGAjFXy6Gdjt6mQwzwqgfdWu+e+M8qwNk8gX9Ca3JxFQc++CDr8nd1Mrr57aHoLMlXprbFMxNy7ptfNoccm61r/9/lHCANMOt85n05HVfccknlopttLI5WM7DsNVU60/x5qylzlpXL24l8KwEFFPK1ky410+/uI3GkYi0l1u9DektKB/m1CINVbQ1Oob+FOW5lhNsBjqgpM/x1it89d7chbThdP5xlpygZsuG0AW4lakebF3ze497e16600v72fclgAZ3M21C0zUM4w9XIweMg==',
            'VSID': vsid ?? "",
          },
          body: jsonEncode(payload),
        );
        print('--- ✅ Call Sheet Closed Successfully ---');

        // Delete the closed call sheet from callsheetoffline table
        try {
          // Ensure database is still open
          if (!mainDb.isOpen) {
            mainDb = await openDatabase(dbPath + '/production_login.db');
          }

          await mainDb.delete(
            'callsheetoffline',
            where: 'callSheetId = ?',
            whereArgs: [callsheetId],
          );
          print('Deleted callsheetoffline row for callSheetId: ' + callsheetId);
        } catch (e) {
          print('Error deleting callsheetoffline row: ' + e.toString());
        }
      } else {
        print(
            "❌ Callsheet status is NOT 'closed'. Status: '${callsheetData['status']}'");
        print("❌ Skipping call sheet closing HTTP request.");
      }
    }

    // Close the main database connection at the very end
    try {
      if (mainDb.isOpen) {
        await mainDb.close();
      }
    } catch (e) {
      print('Error closing main database: $e');
    }
  } catch (e) {
    print('Error in intime and closecallsheet processes: ' + e.toString());
  }
}
