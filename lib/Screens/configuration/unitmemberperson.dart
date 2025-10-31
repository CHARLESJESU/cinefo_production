import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:production/variables.dart';
import 'dart:convert';
import 'configuration.dart';

class Unitmemberperson extends StatefulWidget {
  final Map<String, dynamic> callsheet;
  final String config_unitname;
  final int config_unitid;
  final int unitid;
  final int callsheetid;
  const Unitmemberperson({
    super.key,
    required this.config_unitname,
    required this.callsheet,
    required this.config_unitid,
    required this.unitid,
    required this.callsheetid,
  });

  @override
  State<Unitmemberperson> createState() => _UnitmemberpersonState();
}

class _UnitmemberpersonState extends State<Unitmemberperson> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _responseUnits = [];
  String _errorMessage = "";
  String vsidValue1 = "";
  List<bool> _selectedMembers = [];
  Future<void> fetchLoginDataAndMakeRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      // Get database path and open connection
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(path.join(dbPath, 'production_login.db'));

      // Fetch login_data
      final List<Map<String, dynamic>> loginRows = await db.query(
        'login_data',
        orderBy: 'id ASC',
        limit: 1,
      );

      if (loginRows.isNotEmpty && loginRows.first['vpoid'] != null) {
        String? vsidValue = loginRows.first['vsid']?.toString();
        vsidValue1 = vsidValue!;
        // Prepare payload
        final payload = {"unitid": config_unitid, "callsheetid": callsheetid};
        print('Prepared Payload: $payload');
        print(widget.callsheetid);
        print(widget.config_unitid);
        print(widget.unitid);
        try {
          // Make HTTP POST request
          final response = await http
              .post(
                processSessionRequest,
                headers: {
                  'Content-Type': 'application/json; charset=UTF-8',
                  'VMETID': vmetid_Fecth_callsheet_members,
                  'VSID': vsidValue1 ?? "",
                },
                body: jsonEncode(payload),
              )
              .timeout(Duration(seconds: 30));
          print(widget.callsheetid);
          print(widget.config_unitid);
          print(widget.unitid);
          print('HTTP request completed successfully!');
          print('HTTP Response Status Code: ${response.statusCode}');
          print('Full HTTP Response Body: ${response.body}');

          // Parse the JSON response
          if (response.statusCode == 200) {
            try {
              final Map<String, dynamic> jsonResponse =
                  jsonDecode(response.body);
              if (jsonResponse.containsKey('responseData') &&
                  jsonResponse['responseData'] is List) {
                List<dynamic> responseDataList = jsonResponse['responseData'];
                List<Map<String, dynamic>> units = [];

                for (var item in responseDataList) {
                  if (item is Map<String, dynamic> &&
                      item.containsKey("membercodeCode") &&
                      item.containsKey("memberName")) {
                    units.add({
                      'membercodeCode': item['membercodeCode'],
                      'memberName': item['memberName'],
                      'vmId': item['vmId']
                    });
                  }
                }

                setState(() {
                  _isLoading = false;
                  _responseUnits = units;
                  _selectedMembers = List<bool>.filled(units.length, false);
                });
              } else {
                setState(() {
                  _isLoading = false;
                  _errorMessage =
                      "Invalid response format: responseData not found or not a list";
                });
              }
            } catch (jsonError) {
              setState(() {
                _isLoading = false;
                _errorMessage = "Error parsing JSON: ${jsonError.toString()}";
              });
            }
          } else {
            setState(() {
              _isLoading = false;
              _errorMessage = "HTTP Error: Status Code ${response.statusCode}";
            });
          }
        } catch (httpError) {
          print('HTTP Request Error: ${httpError.toString()}');
          setState(() {
            _isLoading = false;
            _errorMessage = "HTTP Request Error: ${httpError.toString()}";
          });
        }
      } else {
        print('vpoid not found in login_data table.');
        setState(() {
          _isLoading = false;
          _errorMessage = "vpoid not found in login_data table.";
        });
      }

      await db.close();
    } catch (e) {
      print(
          'Error fetching login data or making HTTP request: ${e.toString()}');
      setState(() {
        _isLoading = false;
        _errorMessage = "Database error: ${e.toString()}";
      });
    }
  }

  void _saveSelectedMembers() async {
    List<Map<String, dynamic>> selectedMembers = [];

    for (int i = 0; i < _responseUnits.length; i++) {
      if (_selectedMembers[i]) {
        selectedMembers.add({
          'memberName': _responseUnits[i]['memberName'],
          'membercodeCode': _responseUnits[i]['membercodeCode'],
          'vmId': _responseUnits[i]['vmId'],
        });
      }
    }

    // Extract vmId values from selected members
    List<int> vmIds = selectedMembers
        .map((member) => member['vmId'] as int? ?? 0)
        .where((vmId) => vmId != 0)
        .toList();

    final payload = {
      "vmid": vmIds,
      "configid": widget.config_unitid,
      "unitId": widget.unitid,
      "callSheetId": widget.callsheetid
    };

    try {
      final response = await http
          .post(
            processSessionRequest,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'VMETID': vmetid_save_config,
              'VSID': vsidValue1 ?? "",
            },
            body: jsonEncode(payload),
          )
          .timeout(Duration(seconds: 30));

      print('HTTP request completed successfully!');
      print('HTTP Response Status Code: ${response.statusCode}');
      print('Full HTTP Response Body: ${response.body}');
      print('Selected Members: $selectedMembers');

      if (response.statusCode == 200) {
        // Show success popup
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Saved Successfully!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Airbnb',
                    ),
                  ),
                ],
              ),
              content: Text(
                '${selectedMembers.length} members have been saved successfully.',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Airbnb',
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    // Navigate to configuration page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConfigurationScreen(
                          callsheet: widget.callsheet,
                          callsheetid: widget.callsheetid,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Airbnb',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        // Show error message for non-200 status codes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: Server returned status ${response.statusCode}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message for exceptions
      print('Error saving members: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving members: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Call the function when the screen initializes
    fetchLoginDataAndMakeRequest();
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
            title: Text("${widget.config_unitname} Members",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Loading members...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Airbnb',
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 60,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Error',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Airbnb',
                              ),
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontFamily: 'Airbnb',
                                ),
                              ),
                            ),
                            SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: () {
                                fetchLoginDataAndMakeRequest();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Airbnb',
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _responseUnits.isEmpty
                        ? Center(
                            child: Text(
                              'No members found',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'Airbnb',
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              // Header info
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(20),
                                margin: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Unit: ${widget.config_unitname}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Airbnb',
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Callsheet ID: ${widget.callsheetid}',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontFamily: 'Airbnb',
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Select members for this callsheet:',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontFamily: 'Airbnb',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Members list
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _responseUnits.length,
                                  itemBuilder: (context, index) {
                                    final member = _responseUnits[index];
                                    final memberName =
                                        member['memberName'] ?? 'Unknown';
                                    final memberCode =
                                        member['membercodeCode'] ?? 'Unknown';

                                    return Container(
                                      margin: EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3)),
                                      ),
                                      child: CheckboxListTile(
                                        title: Text(
                                          '$memberName - $memberCode',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Airbnb',
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Member Code: $memberCode',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontFamily: 'Airbnb',
                                          ),
                                        ),
                                        value: _selectedMembers[index],
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _selectedMembers[index] =
                                                value ?? false;
                                          });
                                        },
                                        activeColor: Colors.green,
                                        checkColor: Colors.white,
                                        controlAffinity:
                                            ListTileControlAffinity.trailing,
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Save button
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _saveSelectedMembers();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Save Selected Members',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Airbnb',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
          ),
        ),
      ],
    );
  }
}
