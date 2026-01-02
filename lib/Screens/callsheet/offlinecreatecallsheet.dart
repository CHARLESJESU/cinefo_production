import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OfflineCreateCallSheet extends StatefulWidget {
  const OfflineCreateCallSheet({super.key});

  @override
  State<OfflineCreateCallSheet> createState() => _OfflineCreateCallSheetState();
}

class _OfflineCreateCallSheetState extends State<OfflineCreateCallSheet> {
  Future<void> _createCallSheet() async {
    // Validate all required fields
    if (selectedShift == null || selectedShift!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a shift.')),
      );
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter callsheet name.')),
      );
      return;
    }
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date.')),
      );
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter location.')),
      );
      return;
    }
    if (selectedShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shift ID is missing. Please reselect shift.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final db = await _callsheetDb;

      // Check if same shiftId already exists for the selected date
      String selectedDateStr =
          "${selectedDate!.day.toString().padLeft(2, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.year}";

      // Generate date in YYMMDD format for callSheetId
      String dateForId = "${selectedDate!.year.toString().substring(2)}${selectedDate!.month.toString().padLeft(2, '0')}${selectedDate!.day.toString().padLeft(2, '0')}";

      print('📅 Selected Date for SQLite: $selectedDateStr');

      final existingShift = await db.query(
        'callsheetoffline',
        where: 'shiftId = ? AND created_date = ?',
        whereArgs: [selectedShiftId, selectedDateStr],
      );

      if (existingShift.isNotEmpty) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Duplicate Shift'),
              content: Text(
                  'Already this shift is created in this day so choose another shift.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }

      // Fetch login_data for MovieName, projectId, productionTypeid
      final loginRows = await db.query('login_data', limit: 1);
      if (loginRows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login data not found.')),
        );
        setState(() => _isLoading = false);
        return;
      }
      final loginData = loginRows.first;

      // Generate unique callSheetId using format: "YYMMDD-shiftId-deviceId"
      String callSheetId = '$dateForId-$selectedShiftId-${loginData['cinefoDeviceId']}';
      
      // Generate unique callSheetNo: "CN" + (max existing id + 1)
      final result =
          await db.rawQuery('SELECT MAX(id) as maxId FROM callsheetoffline');
      int nextId = (result.first['maxId'] as int? ?? 0) + 1;
      String callSheetNo = 'CN$callSheetId';

      // Prepare data
      Map<String, dynamic> data = {
        // id is auto-increment
        'callSheetId': callSheetId,
        'callSheetNo': callSheetNo,
        'MovieName': loginData['registered_movie'],
        'callsheetname': _nameController.text,
        'shift': selectedShift,
        'shiftId': selectedShiftId,
        'latitude': 0,
        'longitude': 0,
        'projectId': loginData['project_id'],
        'productionTypeid': loginData['production_type_id'],
        'location': _locationController.text,
        'locationType': selectedLocationType == 1
            ? 'In-station'
            : selectedLocationType == 2
                ? 'Out-station'
                : 'Outside City',
        'locationTypeId': selectedLocationType,
        'created_at': selectedDateStr,
        'status': 'open',
        'created_date': selectedDateStr,
        'created_at_time':
            DateTime.now().toString().split(' ')[1].split('.')[0],
        'pack_up_time': null,
        'pack_up_date': null,
        'isonline': '0', // Indicate this entry was created offline
      };

      // Debug: Print the data being inserted
      print('📝 Inserting callsheet to SQLite:');
      print('   - created_at: ${data['created_at']}');
      print('   - created_date: ${data['created_date']}');
      print('   - callsheetname: ${data['callsheetname']}');

      await db.insert('callsheetoffline', data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Callsheet created successfully!')),
      );
      Navigator.of(context).pop();
      setState(() => _isLoading = false);
      // Optionally clear fields or pop screen
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  bool _isLoading = false;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  String? selectedShift;
  DateTime? selectedDate;
  int selectedLocationType = 1;
  List<Map<String, dynamic>> shiftList = [];
  List<String> shiftTimes = [];
  int? selectedShiftId;
  double? selectedLatitude;
  double? selectedLongitude;
  Future<Database> get _callsheetDb async {
    String dbPath = path.join(await getDatabasesPath(), 'production_login.db');
    return openDatabase(
      dbPath,
      version: 3, // Increased version to trigger onCreate/onUpgrade
      onCreate: (db, version) async {
        // Create callsheetoffline table
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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Create callsheetoffline table if it doesn't exist during upgrade
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
      },
      onOpen: (db) async {
        // Ensure table exists every time database is opened
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
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // You can add mock data for shiftList if needed for UI preview
    shiftList = [
      {"shiftId": 1, "shift": "2AM - 9AM (Sunrise)"},
      {"shiftId": 2, "shift": "6AM - 6PM (Regular)"},
      {"shiftId": 3, "shift": "2PM - 10PM (Evening)"},
      {"shiftId": 4, "shift": "6PM - 2AM (Night)"},
      {"shiftId": 5, "shift": "10PM - 6AM (Mid-Night)"},
    ];
    shiftTimes = shiftList.map((shift) => shift['shift'].toString()).toList();
  }

  Future<void> _selectDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickLocation() async {
    setState(() {
      _locationController.text = "Fetching location...";
    });

    Position? position = await Geolocator.getLastKnownPosition();

    if (position == null) {
      position = await _determinePosition();
    }

    LatLng initialPosition = LatLng(position.latitude, position.longitude);

    LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenStreetMapScreen(initialPosition),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _locationController.text = "Fetching address...";
      });

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            pickedLocation.latitude, pickedLocation.longitude);

        String fullAddress = [
          placemarks.first.street,
          placemarks.first.subLocality,
          placemarks.first.locality,
          placemarks.first.administrativeArea,
          placemarks.first.country
        ].where((e) => e != null && e.isNotEmpty).join(", ");

        setState(() {
          selectedLatitude = pickedLocation.latitude;
          selectedLongitude = pickedLocation.longitude;
          _locationController.text = fullAddress;
        });
      } catch (e) {
        setState(() {
          _locationController.text = "Address not found";
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create callsheet"),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Your Details',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 530,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color.fromARGB(255, 223, 222, 222)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 20, left: 15, right: 15),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Shift',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 6),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButton<String>(
                                  value: selectedShift,
                                  hint: const Text("Select Shift"),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: shiftList.map((shift) {
                                    return DropdownMenuItem<String>(
                                      value: shift['shift'],
                                      child: Text(shift['shift']),
                                    );
                                  }).toList(),
                                  onChanged: (shiftName) {
                                    if (shiftName != null) {
                                      Map<String, dynamic> shiftData =
                                          shiftList.firstWhere(
                                        (shift) => shift['shift'] == shiftName,
                                      );
                                      // Extract label from shift string, e.g., '6AM - 6PM (Regular)' => 'Regular'
                                      String label = '';
                                      final RegExp labelRegExp =
                                          RegExp(r'\(([^)]+)\)');
                                      final match =
                                          labelRegExp.firstMatch(shiftName);
                                      if (match != null &&
                                          match.groupCount >= 1) {
                                        label = match.group(1)!;
                                      } else {
                                        label = shiftName; // fallback
                                      }
                                      setState(() {
                                        selectedShift = shiftName;
                                        selectedShiftId = shiftData['shiftId'];
                                        _nameController.text = label;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('Date',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 6),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 50,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: InkWell(
                                  onTap: _selectDate,
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          selectedDate != null
                                              ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                              : "Select Date",
                                          style: TextStyle(
                                            color: selectedDate != null
                                                ? Colors.black
                                                : Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                        Icon(Icons.calendar_today,
                                            color: Colors.grey[600]),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('Callsheet name',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              const SizedBox(height: 6),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 50,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('Location type',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 6),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonFormField<int>(
                                  value: selectedLocationType,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  icon: const Icon(Icons.arrow_drop_down),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 1, child: Text("In-station")),
                                    DropdownMenuItem(
                                        value: 2, child: Text("Out-station")),
                                    DropdownMenuItem(
                                        value: 3, child: Text("Outside City")),
                                  ],
                                  onChanged: (int? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedLocationType = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const Text('Location',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 6),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _locationController,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Enter location',
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _pickLocation,
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Icon(
                                          Icons.location_on,
                                          color: Colors.blue,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Removed Enable Offline Mode checkbox
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: _isLoading ? null : _createCallSheet,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color.fromRGBO(10, 69, 254, 1),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Create',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 17),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OpenStreetMapScreen extends StatefulWidget {
  final LatLng initialPosition;
  OpenStreetMapScreen(this.initialPosition, {Key? key}) : super(key: key);

  @override
  _OpenStreetMapScreenState createState() => _OpenStreetMapScreenState();
}

class _OpenStreetMapScreenState extends State<OpenStreetMapScreen> {
  late LatLng selectedLocation;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialPosition;
  }

  // 🔍 Function to Search for Location
  Future<void> _searchLocation() async {
    String query = _searchController.text;
    if (query.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        setState(() {
          selectedLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
          _mapController.move(selectedLocation, 15.0);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location not found!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search location...",
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchLocation,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🗺️ Map (Expanded for responsiveness)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: selectedLocation,
                    initialZoom: 13.0,
                    onTap: (_, latLng) {
                      setState(() {
                        selectedLocation = latLng;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLocation,
                          width: 40.0,
                          height: 40.0,
                          child: const Icon(Icons.location_on,
                              size: 40, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ✅ Floating Button for Confirm
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, selectedLocation),
        icon: const Icon(Icons.check),
        label: const Text("Confirm"),
      ),
    );
  }
}
