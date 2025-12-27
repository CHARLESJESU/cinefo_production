import 'package:flutter/material.dart';
import 'package:production/Profile/profilesccreen.dart';
import 'package:production/Profile/changepassword.dart';
import 'package:production/Screens/Attendance/nfcUIDreader.dart';
import 'package:production/Tesing/Sqlitelist.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:production/Screens/Login/loginscreen.dart';
import 'approvalstatus.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchLoginData();
  }

  Future<void> _fetchLoginData() async {
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
      await db.close();
    } catch (e) {
      setState(() {
        _deviceId = 'N/A';
        _managerName = '';
        _mobileNumber = '';
        _registeredMovie = '';
        _productionHouse = '';
        _profileImage = null;
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

      // Ensure table exists before attempting delete
      await db.execute('''
        CREATE TABLE IF NOT EXISTS login_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          manager_name TEXT,
          profile_image TEXT,
          registered_movie TEXT,
          mobile_number TEXT,
          password TEXT,
          project_id TEXT,
          production_type_id INTEGER,
          production_house TEXT,
          vmid INTEGER,
          login_date TEXT,
          device_id TEXT,
          vsid TEXT,
          vpid TEXT,
          vuid INTEGER,
          companyName TEXT,
          email TEXT,
          vbpid INTEGER,
          vcid INTEGER,
          vsubid INTEGER,
          vpoid INTEGER,
          mtypeId INTEGER,
          unitName TEXT,
          vmTypeId INTEGER,
          idcardurl TEXT,
          vpidpo INTEGER,
          vpidbp INTEGER,
          unitid INTEGER,
          platformlogo TEXT
        )
      ''');

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
              IconButton(
                icon: Icon(Icons.notifications),
                color: Colors.white,
                iconSize: 24,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Approvalstatus()));
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
            onRefresh: _fetchLoginData,
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
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
