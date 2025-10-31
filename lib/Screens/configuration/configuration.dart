import 'package:flutter/material.dart';
import 'package:production/Screens/Home/offline_callsheet_detail_screen.dart';
import 'package:production/variables.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'individualunitpage.dart';

class ConfigurationScreen extends StatefulWidget {
  final Map<String, dynamic> callsheet;
  final int callsheetid;
  const ConfigurationScreen(
      {super.key, required this.callsheetid, required this.callsheet});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _responseUnits = [];
  String _errorMessage = "";
  bool _isOffline = false;

  // Function to check internet connectivity
  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        Duration(seconds: 5),
      );
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  // Function to fetch login data and make HTTP request
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
        int? vpoidValue =
            int.tryParse(loginRows.first['vpoid']?.toString() ?? '');
        String? vsidValue = loginRows.first['vsid']?.toString();

        // Prepare payload
        final payload = {"vpoid": vpoidValue};

        try {
          // Make HTTP POST request
          final response = await http
              .post(
                processSessionRequest,
                headers: {
                  'Content-Type': 'application/json; charset=UTF-8',
                  'VMETID': vmetid_fetch_unit,
                  'VSID': vsidValue ?? "",
                },
                body: jsonEncode(payload),
              )
              .timeout(Duration(seconds: 30));

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
                      item.containsKey('unitid') &&
                      item.containsKey('unitType')) {
                    units.add({
                      'unitid': item['unitid'],
                      'unitType': item['unitType'],
                    });
                  }
                }

                setState(() {
                  _isLoading = false;
                  _responseUnits = units;
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

  @override
  void initState() {
    super.initState();
    // Check internet connection first
    initializeScreen();
  }

  // Initialize screen with internet check
  Future<void> initializeScreen() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    bool hasInternet = await checkInternetConnection();

    if (hasInternet) {
      // If online, fetch data from server
      fetchLoginDataAndMakeRequest();
    } else {
      // If offline, show offline message
      setState(() {
        _isLoading = false;
        _isOffline = true;
        _errorMessage = "";
      });
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
            title: const Text("Configuration",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => OfflineCallsheetDetailScreen(
                          callsheet: widget.callsheet))),
            ),
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
                          'Checking connection...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Airbnb',
                          ),
                        ),
                      ],
                    ),
                  )
                : _isOffline
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off,
                              color: Colors.orange,
                              size: 80,
                            ),
                            SizedBox(height: 30),
                            Text(
                              'You\'re in Offline Mode',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Airbnb',
                              ),
                            ),
                            SizedBox(height: 15),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Configuration requires an internet connection. Please check your network settings and try again.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontFamily: 'Airbnb',
                                ),
                              ),
                            ),
                            SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    initializeScreen();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 25, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Retry',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Airbnb',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                OfflineCallsheetDetailScreen(
                                                    callsheet:
                                                        widget.callsheet)));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[600],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 25, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_back, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Go Back',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Airbnb',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                                    setState(() {
                                      _isOffline = false;
                                    });
                                    initializeScreen();
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
                                  'No units found',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontFamily: 'Airbnb',
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _responseUnits.length,
                                      itemBuilder: (context, index) {
                                        final unit = _responseUnits[index];
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: 15),
                                          child: Container(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                // Assign unitid to config_unitid
                                                int selectedUnitId =
                                                    unit['unitid'] is int
                                                        ? unit['unitid']
                                                        : int.tryParse(unit[
                                                                    'unitid']
                                                                .toString()) ??
                                                            0;
                                                String selectedUnitName =
                                                    unit['unitType'] ??
                                                        'Unknown';

                                                // Set global variables
                                                config_unitid = selectedUnitId;
                                                config_unitname =
                                                    selectedUnitName;

                                                print(
                                                    'Selected Unit ID: ${unit['unitid']}');
                                                print(
                                                    'config_unitid set to: $config_unitid');
                                                print(
                                                    'config_unitname set to: $config_unitname');

                                                // Navigate to individual unit page with parameters
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        Individualunitpage(
                                                            callsheet: widget
                                                                .callsheet,
                                                            config_unitid:
                                                                selectedUnitId,
                                                            config_unitname:
                                                                selectedUnitName,
                                                            callsheetid: widget
                                                                .callsheetid),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue
                                                    .withOpacity(0.8),
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.all(20),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    unit['unitType'] ??
                                                        'Unknown',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'Airbnb',
                                                    ),
                                                  ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    'ID: ${unit['unitid']}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white70,
                                                      fontFamily: 'Airbnb',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isOffline = false;
                                        });
                                        initializeScreen();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.all(16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Refresh',
                                        style: TextStyle(
                                          fontSize: 16,
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
