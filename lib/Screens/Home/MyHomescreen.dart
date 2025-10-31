import 'package:flutter/material.dart';
import 'package:production/Profile/profilesccreen.dart';
import 'package:production/Profile/changepassword.dart';

import 'package:production/Screens/Attendance/nfcUIDreader.dart';
import 'package:production/Screens/callsheet/offlinecreatecallsheet.dart';
import 'package:production/Screens/callsheet/createcallsheet.dart';
import 'package:production/Tesing/Sqlitelist.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:production/Screens/Home/offline_callsheet_detail_screen.dart';
import 'package:production/Screens/Home/importantfunc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:production/Screens/Login/loginscreen.dart';
import 'dart:io';

class MyHomescreen extends StatefulWidget {
  const MyHomescreen({super.key});

  @override
  State<MyHomescreen> createState() => _MyHomescreenState();
}

class _MyHomescreenState extends State<MyHomescreen> {
  String? _deviceId;
  String? _managerName;
  String? _mobileNumber;
  String? _registeredMovie;
  String? _productionHouse;
  String? _profileImage;
  List<Map<String, dynamic>> _callsheetList = [];

  @override
  void initState() {
    super.initState();
    _fetchLoginAndCallsheetData();
  }

  Future<void> _fetchLoginAndCallsheetData() async {
    try {
      String dbPath =
          path.join(await getDatabasesPath(), 'production_login.db');
      final db = await openDatabase(dbPath);
      // Fetch login_data
      final List<Map<String, dynamic>> loginMaps = await db.query(
        'login_data',
        orderBy: 'id ASC',
        limit: 1,
      );
      if (loginMaps.isNotEmpty && mounted) {
        setState(() {
          _deviceId = loginMaps.first['device_id']?.toString() ?? 'N/A';
          _managerName = loginMaps.first['manager_name']?.toString() ?? '';
          _mobileNumber = loginMaps.first['mobile_number']?.toString() ?? '';
          _registeredMovie =
              loginMaps.first['registered_movie']?.toString() ?? '';
          _productionHouse =
              loginMaps.first['production_house']?.toString() ?? '';
          _profileImage = loginMaps.first['profile_image']?.toString();
        });
      }
      // Ensure callsheetoffline table exists
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

      // Fetch callsheet data
      try {
        final List<Map<String, dynamic>> callsheetMaps = await db.query(
          'callsheetoffline',
          orderBy: 'created_at DESC',
        );
        setState(() {
          _callsheetList = callsheetMaps;
        });
      } catch (e) {
        print('Error fetching callsheet data: $e');
        setState(() {
          _callsheetList = [];
        });
      }
      await db.close();
    } catch (e) {
      setState(() {
        _deviceId = 'N/A';
        _managerName = '';
        _mobileNumber = '';
        _registeredMovie = '';
        _productionHouse = '';
        _profileImage = null;
        _callsheetList = [];
      });
    }
  }

  // Method to perform logout - delete all login data and navigate to login screen
  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF2B5682),
                ),
                SizedBox(width: 20),
                Text('Logging out...'),
              ],
            ),
          );
        },
      );

      // Delete all data from login_data table
      String dbPath =
          path.join(await getDatabasesPath(), 'production_login.db');
      final db = await openDatabase(dbPath);

      // Delete all records from login_data table
      await db.delete('login_data');
      await db.close();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to login screen and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const Loginscreen(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');

      // Close loading dialog if it's open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(
              color: Color(0xFF2B5682),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _performLogout(); // Call the logout method
              },
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
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
          endDrawer: Drawer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2B5682),
                    Color(0xFF24426B),
                  ],
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2B5682),
                          Color(0xFF24426B),
                        ],
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        backgroundImage: AssetImage('assets/tenkrow.png'),
                        radius: 40,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  // View Profile
                  ListTile(
                    leading: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'View Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Profilesccreen(),
                        ),
                      );
                    },
                  ),

                  // White separator line
                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),

                  // Change Password
                  ListTile(
                    leading: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'Change Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Changepassword(),
                        ),
                      ); // Close drawer first
                    },
                  ),

                  // White separator line
                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),

                  // Logout
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      _showLogoutDialog(context);
                    },
                  ),
                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.devices,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'Device ID',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _deviceId ?? 'Loading...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'NFC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => NfcHomePage(),
                      //   ),
                      // );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NfcHomePage(),
                        ),
                      );
                    },
                  ),
                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'vSync',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Sqlitelist(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'assets/cinefo-logo.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
            actions: [
              // IconButton(
              //   icon: Icon(Icons.add),
              //   color: Colors.white,
              //   iconSize: 24,
              //   onPressed: () async {
              //     await Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => CreateCallSheet(),
              //       ),
              //     );
              //     _fetchLoginAndCallsheetData(); // Refresh after returning
              //   },
              // ),
              IconButton(
                icon: Icon(Icons.notifications),
                color: Colors.white,
                iconSize: 24,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _fetchLoginAndCallsheetData,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: 100), // Add bottom padding to avoid navigation bar
                child: Column(
                  children: [
                    SizedBox(height: 20), // Space from AppBar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          color: Color(0xFF355E8C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 7),
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.grey[300],
                              child: (_profileImage != null &&
                                      _profileImage!.isNotEmpty &&
                                      _profileImage!.toLowerCase() != 'unknown')
                                  ? ClipOval(
                                      child: Image.network(
                                        _profileImage!,
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Icon(Icons.person,
                                              size: 48,
                                              color: Colors.grey[600]);
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(Icons.person,
                                              size: 48,
                                              color: Colors.grey[600]);
                                        },
                                      ),
                                    )
                                  : Icon(Icons.person,
                                      size: 48, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_managerName ?? '',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text("Production Manager",
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white70)),
                                  Text(_mobileNumber ?? '',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white70)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20), // Space between containers
                    // Avengers: Endgame container (different design)
                    //container 2
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF4A6FA5),
                              Color(0xFF2E4B73),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _registeredMovie ?? '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _productionHouse ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20), // Space after container 2
                    // Offline call sheet section
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 30),
                    //   child: Container(
                    //     margin: EdgeInsets.only(top: 10),
                    //     padding: EdgeInsets.all(16),
                    //     decoration: BoxDecoration(
                    //       color: Colors.white,
                    //       borderRadius: BorderRadius.circular(15),
                    //       boxShadow: [
                    //         BoxShadow(
                    //           color: Colors.black.withOpacity(0.08),
                    //           blurRadius: 6,
                    //           offset: Offset(0, 2),
                    //         ),
                    //       ],
                    //     ),
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         Text(
                    //           'Offline call sheet',
                    //           style: TextStyle(
                    //             fontSize: 16,
                    //             fontWeight: FontWeight.bold,
                    //             color: Color(0xFF2B5682),
                    //           ),
                    //         ),
                    //         SizedBox(height: 15),
                    //         if (_callsheetList.isNotEmpty)
                    //           ..._callsheetList.map((item) => _buildListItem(
                    //                 item['callSheetNo']?.toString() ?? '',
                    //                 item['locationType']?.toString() ?? '',
                    //                 (item['created_at']?.toString() ?? '')
                    //                     .split('T')
                    //                     .first,
                    //                 item['status']?.toString() ?? '',
                    //                 callsheetData: item,
                    //               ))
                    //         else
                    //           Container(
                    //             width: double.infinity,
                    //             padding: EdgeInsets.symmetric(vertical: 20),
                    //             child: Column(
                    //               mainAxisAlignment: MainAxisAlignment.center,
                    //               children: [
                    //                 Icon(
                    //                   Icons.description_outlined,
                    //                   size: 48,
                    //                   color: Colors.grey[400],
                    //                 ),
                    //                 SizedBox(height: 12),
                    //                 Text(
                    //                   'No offline call sheet available',
                    //                   style: TextStyle(
                    //                     fontSize: 14,
                    //                     color: Colors.grey[600],
                    //                     fontWeight: FontWeight.w500,
                    //                   ),
                    //                 ),
                    //                 SizedBox(height: 4),
                    //                 Text(
                    //                   'Create a call sheet to see it here',
                    //                   style: TextStyle(
                    //                     fontSize: 12,
                    //                     color: Colors.grey[500],
                    //                   ),
                    //                 ),
                    //               ],
                    //             ),
                    //           ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to get initial 3 list items

  // Helper method to build individual list item
  Widget _buildListItem(String code, String timing, String date, String status,
      {Map<String, dynamic>? callsheetData}) {
    return GestureDetector(
      onTap: () async {
        if (callsheetData != null) {
          if (status == 'open') {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    OfflineCallsheetDetailScreen(callsheet: callsheetData),
              ),
            );
            if (result == true) {
              _fetchLoginAndCallsheetData();
            }
          }
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
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
        ),
        child: Row(
          children: [
            // Left side - Code and timing
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B5682),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    timing,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  // Execute button - commented out for future use
                  // if (status.toLowerCase() == 'closed')
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 8.0),
                  //     child: ElevatedButton(
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: Color(0xFF2B5682),
                  //         foregroundColor: Colors.white,
                  //         minimumSize: Size(80, 32),
                  //         padding:
                  //             EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(8),
                  //         ),
                  //       ),
                  //       onPressed: () async {
                  //         bool internetAvailable = false;
                  //         try {
                  //           var connectivityResult =
                  //               await Connectivity().checkConnectivity();
                  //           if (connectivityResult ==
                  //                   ConnectivityResult.mobile ||
                  //               connectivityResult == ConnectivityResult.wifi) {
                  //             internetAvailable = true;
                  //           }
                  //         } catch (e) {
                  //           // fallback: try to ping google
                  //           try {
                  //             final result =
                  //                 await InternetAddress.lookup('google.com');
                  //             if (result.isNotEmpty &&
                  //                 result[0].rawAddress.isNotEmpty) {
                  //               internetAvailable = true;
                  //             }
                  //           } catch (_) {
                  //             internetAvailable = false;
                  //           }
                  //         }
                  //         if (internetAvailable) {
                  //           // ignore: use_build_context_synchronously
                  //           await createCallSheetFromOffline(
                  //               callsheetData ?? {}, context);
                  //         } else {
                  //           ScaffoldMessenger.of(context).showSnackBar(
                  //             SnackBar(
                  //               content: Text('Internet is not available'),
                  //               backgroundColor: Colors.red,
                  //             ),
                  //           );
                  //         }
                  //       },
                  //       child: Text('Execute'),
                  //     ),
                  //   ),
                ],
              ),
            ),
            // Right side - Date
            Expanded(
              flex: 1,
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF355E8C),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
