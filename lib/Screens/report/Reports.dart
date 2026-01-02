import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:production/Screens/Home/importantfunc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:production/Screens/report/Reportdetails.dart';
import 'package:production/variables.dart';

class Reports extends StatefulWidget {
  final String projectId;
  final String callsheetid;

  const Reports(
      {super.key, required this.projectId, required this.callsheetid});
  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  List<Map<String, dynamic>> callSheets = [];
  List<Map<String, dynamic>> offlineCallSheets = [];
  bool isLoading = true; // State for loading indicator

  @override
  void initState() {
    super.initState();
    printVSIDFromLoginData().then((_) => Future.wait([
          callsheet(), // Fetch API data
          fetchOfflineCallSheets(), // Fetch SQLite data
        ]));
  }

  Future<void> fetchOfflineCallSheets() async {
    try {
      final dbPath = await getDatabasesPath();
      final db = await openDatabase('${dbPath}/production_login.db');

      // Check if callsheetoffline table exists
      final tableExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='callsheetoffline'");

      if (tableExists.isNotEmpty) {
        final List<Map<String, dynamic>> offlineData = await db.query(
          'callsheetoffline',
          orderBy: 'created_at DESC',
        );

        setState(() {
          offlineCallSheets = offlineData;
        });
      }

      await db.close();
    } catch (e) {
      print('Error fetching offline call sheets: $e');
    }
  }

  Future<void> callsheet() async {
    try {
      final response = await http.post(
        processSessionRequest,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              'CpgDDfl7OjvtUfpQTq2Ay6pOFg0PjAExT+oKNsVaRW6PmfKxZqN0t1/tLoQjXSTMPIhb1P7rk0FStcwChgtzyZ9eB2gYIew67wiUjlmQquYyrB/isPKkyl8JtOi93+DhAd5xnejC8R45wEhEEt7kCpEIFSqdfg0TqXbProryg+wohtZFfMscEDmgdR6WwcdfyQzpR82+0QK1oPm/CxeYWUATCA1FKW4sqYCtiXANLlIaxAEcjB8SxKoxrixmGqO32n9eTvFHGm80EkZ1x+0o9lL5FeLGiqqdRYD34jEP/NsKAKbU6Q6UfE4VZuxoomWDMLL5Cp2QKj5YuWoY1NVdSg==',
          'VSID': vsid ?? "",
        },
        body: jsonEncode(
            {"projectid": projectId, "callsheetid": 0, "vmid": vmid}),
      );
      print(vmid);
      print(projectId);
      // Check if widget is still mounted before processing response
      if (!mounted) return;

      // ✅ Check for session expiration using global helper
      if (checkSessionExpiration(context, response)) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return; // Stop processing if session expired
      }

      if (response.statusCode == 200) {
        print("✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅${response.body} ");
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == "200" && data['responseData'] != null) {
          // Check mounted before calling setState
          if (mounted) {
            setState(() {
              callSheets =
                  List<Map<String, dynamic>>.from(data['responseData']);
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error in callsheet(): $e");
      // Check mounted before error setState
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2B5682),
                Color(0xFF24426B),
              ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text(
              "CallSheets Reports",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
                  // Reports list section
                  if (isLoading)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircularProgressIndicator(
                          color: Color(0xFF2B5682),
                        ),
                      ),
                    )
                  else if (callSheets.isEmpty && offlineCallSheets.isEmpty)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No CallSheets Available",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Online Call Sheets Section
                        if (callSheets.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              "Online CallSheets",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          ...callSheets.map((callsheet) => containerBox(
                                context,
                                callsheet['callSheetNo'] ?? "N/A",
                                callsheet['callsheetStatus'] ?? "N/A",
                                callsheet['location'] ?? "N/A",
                                callsheet['date'],
                                callsheet['callSheetId']?.toString() ?? "N/A",
                                isOffline: false,
                              )),
                          SizedBox(height: 20),
                        ],
                        // Offline Call Sheets Section
                        if (offlineCallSheets.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              "Offline CallSheets",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          ...offlineCallSheets.map((callsheet) => containerBox(
                                context,
                                callsheet['callSheetNo'] ?? "N/A",
                                callsheet['status'] ?? "N/A",
                                callsheet['locationType'] ?? "N/A",
                                callsheet['created_at'],
                                callsheet['callSheetId']?.toString() ?? "N/A",
                                isOffline: true,
                              )),
                        ],
                      ],
                    ),
                  // Add extra bottom padding to prevent content from being hidden by navigation
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget containerBox(
      BuildContext context,
      String title,
      String callsheetStatus,
      String location,
      dynamic dateValue,
      dynamic callsheetid,
      {bool isOffline = false}) {
    String formattedDate = "Invalid Date";
    if (dateValue != null && dateValue.toString().trim().isNotEmpty) {
      try {
        DateTime parsedDate = DateTime.parse(dateValue.toString());
        formattedDate = DateFormat("dd/MM/yyyy").format(parsedDate);
      } catch (e) {
        print("Error parsing date: $e");
      }
    }

    return GestureDetector(
      onTap: () {
        // Print for debug
        print(
            'Navigating to Reportdetails with callsheetid: $callsheetid, projectId: ${projectId.toString()}, isOffline: $isOffline');
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Reportdetails(
                    projectId: projectId.toString(),
                    maincallsheetid: callsheetid.toString(),
                    isOffline: isOffline)));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4A6FA5).withOpacity(0.1),
                    Color(0xFF2E4B73).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2B5682),
                      ),
                    ),
                  ),
                  if (isOffline)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OFFLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(callsheetStatus).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      callsheetStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(callsheetStatus),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            // Location and Date
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    callsheetid.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF355E8C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'open':
        return Colors.green;
      case 'closed':
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
