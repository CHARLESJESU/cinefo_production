import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:production/sessionexpired.dart';
import 'package:production/variables.dart';

class Reportdetails extends StatefulWidget {
  final String projectId;
  final String maincallsheetid;
  final bool isOffline;

  const Reportdetails(
      {super.key,
      required this.projectId,
      required this.maincallsheetid,
      this.isOffline = false});

  @override
  State<Reportdetails> createState() => _ReportdetailsState();
}

class _ReportdetailsState extends State<Reportdetails> {
  List<AttendanceEntry> reportData = [];
  bool isLoading = true;

  Future<void> fetchOfflineAttendanceData() async {
    try {
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(path.join(dbPath, 'production_login.db'));

      // Query intime table for attendance data matching the callsheet ID
      final List<Map<String, dynamic>> intimeData = await db.query(
        'intime',
        where: 'callsheetid = ?',
        whereArgs: [int.parse(widget.maincallsheetid)],
      );

      // Group data by person (name or vcid) and combine in/out times
      Map<String, AttendanceEntry> attendanceMap = {};

      for (var record in intimeData) {
        String personKey = record['name'] ?? record['vcid'] ?? 'Unknown';
        String attendanceStatus = record['attendance_status']?.toString() ?? '';
        String markedTime = record['marked_at'] ?? '';

        if (attendanceMap.containsKey(personKey)) {
          // Update existing entry
          if (attendanceStatus == '1') {
            attendanceMap[personKey] = attendanceMap[personKey]!.copyWith(
              inTime: _formatTime(markedTime),
            );
          } else if (attendanceStatus == '2') {
            attendanceMap[personKey] = attendanceMap[personKey]!.copyWith(
              outTime: _formatTime(markedTime),
            );
          }
        } else {
          // Create new entry - for offline data, create combined code from available fields
          String unitCode = record['unitId']?.toString() ?? '';
          String memberCodeCode = record['code']?.toString() ?? '';
          String combinedCode = unitCode.isNotEmpty && memberCodeCode.isNotEmpty
              ? '$unitCode-$memberCodeCode'
              : (unitCode.isNotEmpty ? unitCode : memberCodeCode);

          attendanceMap[personKey] = AttendanceEntry(
            memberName: record['name'] ?? 'Unknown',
            code: combinedCode.isNotEmpty ? combinedCode : null,
            inTime: attendanceStatus == '1' ? _formatTime(markedTime) : null,
            outTime: attendanceStatus == '2' ? _formatTime(markedTime) : null,
          );
        }
      }

      setState(() {
        reportData = attendanceMap.values.toList();
        isLoading = false;
      });

      await db.close();
    } catch (e) {
      print("Error fetching offline attendance: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--';
    try {
      DateTime dateTime = DateTime.parse(isoString);
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '--';
    }
  }

  Future<void> reportsscreen() async {
    print(widget.maincallsheetid);
    print(widget.projectId);
    try {
      final response = await http.post(
        processSessionRequest,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              "M1eZ6wLvBLCuSi4sdl6UoLJWnxZP5rJeLboXP93ukEsq/wVU4oxKSDUuD0ztNzeehHyKegLPgfFNJhMOm+sVeofs6HNJwTmSvrVpE2uIedFafjzruD4npza1tgz9gi0VYTaAU4gnqdtXEC4BCBjz6dGXV0BBdDWKpag1fZnOdB4+h2P9bv946GvG53+PsxFC30VEt5utBorby+AeL3xW6HjsK72KpZkE/YROUmdqwyjGapxu0NmAij2+zB9yYYvINMJa68aeBSEiaqWWKdJyqSL1nE3HhwmWJX/XCp+dNBRjtwgK5JZMIcsOl+ZX298fE0bghyXkq0lw69Kjmw2lmw==",
          'VSID': vsid ?? "",
        },
        body: jsonEncode({
          "callsheetid": widget.maincallsheetid,
          "projectId": widget.projectId,
        }),
      );
      print("${widget.maincallsheetid}✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ");
      print("${widget.projectId}✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ");
      if (response.statusCode == 200) {
        print("${response.body}✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ");
        final decoded = jsonDecode(response.body);
        if (decoded['responseData'] != null) {
          List<AttendanceEntry> entries = (decoded['responseData'] as List)
              .map((e) => AttendanceEntry.fromJson(e))
              .toList();
          setState(() {
            reportData = entries;
            isLoading = false;
          });
        }
      } else {
        Map error = jsonDecode(response.body);
        print(error);
        if (error['errordescription'] == "Session Expired") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const Sessionexpired()));
        }
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Exception: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isOffline) {
      fetchOfflineAttendanceData();
    } else {
      reportsscreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 80,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.only(left: 30, top: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back),
                      ),
                      SizedBox(width: 20),
                      Text(
                        widget.isOffline
                            ? "Offline Report Details"
                            : "Report Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(228, 215, 248, 1),
                        border: Border.all(
                          color: Color.fromRGBO(131, 77, 218, 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Text('Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(131, 77, 218, 1),
                                )),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(131, 77, 218, 1),
                                )),
                          ),
                          Expanded(
                            child: Text('In Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(131, 77, 218, 1),
                                )),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Text('Out Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(131, 77, 218, 1),
                                )),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: reportData.length,
                        itemBuilder: (context, index) {
                          final entry = reportData[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 2, child: Text(entry.code ?? "--")),
                                Expanded(
                                    flex: 3, child: Text(entry.memberName)),
                                Expanded(child: Text(entry.inTime ?? "--")),
                                SizedBox(width: 20),
                                Expanded(child: Text(entry.outTime ?? "--")),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AttendanceEntry {
  final String memberName;
  final String? code;
  final String? inTime;
  final String? outTime;

  AttendanceEntry({
    required this.memberName,
    this.code,
    this.inTime,
    this.outTime,
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    String unitCode = json['unitcode']?.toString() ?? '';
    String memberCodeCode = json['membercodeCode']?.toString() ?? '';
    String combinedCode = unitCode.isNotEmpty && memberCodeCode.isNotEmpty
        ? '$unitCode-$memberCodeCode'
        : (unitCode.isNotEmpty ? unitCode : memberCodeCode);

    return AttendanceEntry(
      memberName: json['memberName'] ?? '',
      code: combinedCode.isNotEmpty ? combinedCode : null,
      inTime: json['intime'],
      outTime: json['outTime'],
    );
  }

  AttendanceEntry copyWith({
    String? memberName,
    String? code,
    String? inTime,
    String? outTime,
  }) {
    return AttendanceEntry(
      memberName: memberName ?? this.memberName,
      code: code ?? this.code,
      inTime: inTime ?? this.inTime,
      outTime: outTime ?? this.outTime,
    );
  }
}
