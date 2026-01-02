import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class Sqlitelist extends StatefulWidget {
  @override
  _SqlitelistState createState() => _SqlitelistState();
}

class _SqlitelistState extends State<Sqlitelist> {
  Database? _database;
  List<Map<String, dynamic>> _loginData = [];
  List<Map<String, dynamic>> _callsheetData = [];
  List<Map<String, dynamic>> _intimeData = [];
  List<Map<String, dynamic>> _callsheetOfflineData = [];
  bool _isLoading = true;
  int _viewMode = 0; // 0: callsheet, 1: login, 2: intime, 3: callsheetoffline

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Helper to ensure database is open, reopens if closed
  Future<Database> ensureDatabaseOpen() async {
    if (_database == null || !_database!.isOpen) {
      _database = await _initDatabase();
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String dbPath =
          path.join(await getDatabasesPath(), 'production_login.db');
      print('📍 SQLite List - Connecting to existing database: $dbPath');
      final db = await openDatabase(
        dbPath,
        version: 1,
      );
      final logintable = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='login_data'");
      if (logintable.isEmpty) {
        throw Exception(
            'Login table not found. Please login first to create the database.');
      }
      print('✅ SQLite List - Connected to existing login_data table');
      print('📋 Table verification: Found login_data table');
      return db;
    } catch (e) {
      print('❌ SQLite List - Database connection error: $e');
      rethrow;
    }
  }

  Future<void> _initializeDatabase() async {
    try {
      await _fetchLoginData();
      await _fetchCallsheetData();
      await _fetchIntimeData();
      await _fetchCallsheetOfflineData();
    } catch (e) {
      print('❌ Error initializing database: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCallsheetOfflineData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final db = await ensureDatabaseOpen();
      final callsheetOfflineTable = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='callsheetoffline'");
      if (callsheetOfflineTable.isEmpty) {
        setState(() {
          _callsheetOfflineData = [];
          _isLoading = false;
        });
        return;
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'callsheetoffline',
        orderBy: 'created_at DESC',
      );
      print(
          '📊 SQLite List - Retrieved \\${maps.length} callsheetoffline records');
      setState(() {
        _callsheetOfflineData = maps;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching callsheetoffline data: $e');
      if (e.toString().contains('database_closed')) {
        _database = null;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLoginData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final db = await ensureDatabaseOpen();
      final List<Map<String, dynamic>> maps = await db.query(
        'login_data',
        orderBy: 'login_date DESC',
      );
      print('📊 SQLite List - Retrieved \\${maps.length} login records');
      setState(() {
        _loginData = maps;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching login data: $e');
      if (e.toString().contains('database_closed')) {
        _database = null;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCallsheetData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final db = await ensureDatabaseOpen();
      final callsheettable = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='callsheet'");
      if (callsheettable.isEmpty) {
        setState(() {
          _callsheetData = [];
          _isLoading = false;
        });
        return;
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'callsheet',
        orderBy: 'created_at DESC',
      );
      print('📊 SQLite List - Retrieved \\${maps.length} callsheet records');
      setState(() {
        _callsheetData = maps;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching callsheet data: $e');
      if (e.toString().contains('database_closed')) {
        _database = null;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchIntimeData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final db = await ensureDatabaseOpen();
      final intimeTable = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='intime'");
      if (intimeTable.isEmpty) {
        setState(() {
          _intimeData = [];
          _isLoading = false;
        });
        return;
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'intime',
        orderBy: 'marked_at DESC',
      );
      print('📊 SQLite List - Retrieved \\${maps.length} intime records');
      setState(() {
        _intimeData = maps;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching intime data: $e');
      if (e.toString().contains('database_closed')) {
        _database = null;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllData() async {
    try {
      final db = await ensureDatabaseOpen();
      String table = _viewMode == 0
          ? 'callsheet'
          : _viewMode == 1
              ? 'login_data'
              : _viewMode == 2
                  ? 'intime'
                  : 'callsheetoffline';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Clear All Data'),
          content: Text(
              'Are you sure you want to clear all $table data? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await db.delete(table);
        print('🗑️ All $table data cleared');
        if (_viewMode == 0) {
          await _fetchCallsheetData();
        } else if (_viewMode == 1) {
          await _fetchLoginData();
        } else if (_viewMode == 2) {
          await _fetchIntimeData();
        } else {
          await _fetchCallsheetOfflineData();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All $table data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error clearing data: $e');
      if (e.toString().contains('database_closed')) {
        _database = null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRecord(int id) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Record'),
          content: Text('Are you sure you want to delete this record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        final db = await ensureDatabaseOpen();
        String table = _viewMode == 0
            ? 'callsheet'
            : _viewMode == 1
                ? 'login_data'
                : _viewMode == 2
                    ? 'intime'
                    : 'callsheetoffline';
        await db.delete(table, where: 'id = ?', whereArgs: [id]);
        print('🗑️ $table record $id deleted');
        if (_viewMode == 0) {
          await _fetchCallsheetData();
        } else if (_viewMode == 1) {
          await _fetchLoginData();
        } else if (_viewMode == 2) {
          await _fetchIntimeData();
        } else {
          await _fetchCallsheetOfflineData();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting record: $e');
      if (e.toString().contains('database_closed')) {
        _database = null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF355E8C),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          tooltip: 'Back',
        ),
        title: Text(
          _viewMode == 0
              ? 'SQLite Call Sheet Data'
              : _viewMode == 1
                  ? 'SQLite Login Data'
                  : _viewMode == 2
                      ? 'SQLite Intime Data'
                      : 'SQLite CallSheetOffline Data',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF355E8C),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz, color: Colors.white),
            onPressed: () {
              setState(() {
                _viewMode = (_viewMode + 1) % 4;
              });
            },
            tooltip: _viewMode == 0
                ? 'Show Login Data'
                : _viewMode == 1
                    ? 'Show Intime Data'
                    : _viewMode == 2
                        ? 'Show CallSheetOffline Data'
                        : 'Show Call Sheet Data',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              if (_viewMode == 0) {
                await _fetchCallsheetData();
              } else if (_viewMode == 1) {
                await _fetchLoginData();
              } else if (_viewMode == 2) {
                await _fetchIntimeData();
              } else {
                await _fetchCallsheetOfflineData();
              }
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(Icons.clear_all, color: Colors.white),
            onPressed: _clearAllData,
            tooltip: 'Clear All Data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading '
                    '${_viewMode == 0 ? 'call sheet' : _viewMode == 1 ? 'login' : _viewMode == 2 ? 'intime' : 'callsheetoffline'} data...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : (_viewMode == 0
                  ? _callsheetData.isEmpty
                  : _viewMode == 1
                      ? _loginData.isEmpty
                      : _viewMode == 2
                          ? _intimeData.isEmpty
                          : _callsheetOfflineData.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storage,
                        size: 64,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      SizedBox(height: 16),
                      Text(
                        _viewMode == 0
                            ? 'No call sheet data found'
                            : _viewMode == 1
                                ? 'No login data found'
                                : _viewMode == 2
                                    ? 'No intime data found'
                                    : 'No callsheetoffline data found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _viewMode == 0
                            ? 'Create a call sheet to see data here'
                            : _viewMode == 1
                                ? 'Login through the app to see data here'
                                : _viewMode == 2
                                    ? 'Mark attendance to see intime data here'
                                    : 'Create a callsheet (offline) to see data here',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Records: '
                            '${_viewMode == 0 ? _callsheetData.length : _viewMode == 1 ? _loginData.length : _viewMode == 2 ? _intimeData.length : _callsheetOfflineData.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _viewMode == 0
                            ? _callsheetData.length
                            : _viewMode == 1
                                ? _loginData.length
                                : _viewMode == 2
                                    ? _intimeData.length
                                    : _callsheetOfflineData.length,
                        itemBuilder: (context, index) {
                          final item = _viewMode == 0
                              ? _callsheetData[index]
                              : _viewMode == 1
                                  ? _loginData[index]
                                  : _viewMode == 2
                                      ? _intimeData[index]
                                      : _callsheetOfflineData[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            child: ExpansionTile(
                              title: Text(
                                _viewMode == 0
                                    ? (item['name'] ?? 'No Name')
                                    : _viewMode == 1
                                        ? (item['manager_name'] ??
                                            'Unknown Manager')
                                        : _viewMode == 2
                                            ? (item['name'] ?? 'No Name')
                                            : (item['callsheetname'] ??
                                                'No Name'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: _viewMode == 0
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Location: \\${item['location'] ?? 'N/A'}',
                                            style: TextStyle(fontSize: 14)),
                                        Text(
                                            'Date: \\${_formatDate(item['created_at'])}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600])),
                                      ],
                                    )
                                  : _viewMode == 1
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Movie: \\${item['registered_movie'] ?? 'N/A'}',
                                                style: TextStyle(fontSize: 14)),
                                            Text(
                                                'Date: \\${_formatDate(item['login_date'])}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600])),
                                          ],
                                        )
                                      : _viewMode == 2
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    'VCID: \\${item['vcid'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                        fontSize: 14)),
                                                Text(
                                                    'Date: \\${_formatDate(item['marked_at'])}',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.grey[600])),
                                              ],
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    'Location: ${item['location'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                        fontSize: 14)),
                                                Text(
                                                    'Date: ${_formatDate(item['created_at'])}',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.grey[600])),
                                                Text(
                                                    'Status: ${item['status'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.grey[600])),
                                              ],
                                            ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteRecord(item['id']),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    children: _viewMode == 0
                                        ? [
                                            _buildDetailRow('Shift ID',
                                                item['shiftId']?.toString()),
                                            _buildDetailRow('Latitude',
                                                item['latitude']?.toString()),
                                            _buildDetailRow(
                                                'Callsheet ID',
                                                item['callSheetId']
                                                    ?.toString()),
                                            _buildDetailRow('MovieName',
                                                item['MovieName']?.toString()),
                                            _buildDetailRow('Shift',
                                                item['shift']?.toString()),
                                            _buildDetailRow(
                                                'Callsheet No',
                                                item['callSheetNo']
                                                    ?.toString()),
                                            _buildDetailRow('Longitude',
                                                item['longitude']?.toString()),
                                            _buildDetailRow('Project ID',
                                                item['projectId']?.toString()),
                                            _buildDetailRow('VM ID',
                                                item['vmid']?.toString()),
                                            _buildDetailRow('VPID',
                                                item['vpid']?.toString()),
                                            _buildDetailRow('VPOID',
                                                item['vpoid']?.toString()),
                                            _buildDetailRow('VBPID',
                                                item['vbpid']?.toString()),
                                            _buildDetailRow(
                                                'Production Type ID',
                                                item['productionTypeid']
                                                    ?.toString()),
                                            _buildDetailRow(
                                                'Location', item['location']),
                                            _buildDetailRow('Location Type',
                                                item['locationType']),
                                            _buildDetailRow(
                                                'Status', item['status']),
                                            _buildDetailRow(
                                                'Location Type ID',
                                                item['locationTypeId']
                                                    ?.toString()),
                                            _buildDetailRow(
                                                'Created At',
                                                _formatDate(
                                                    item['created_at'])),
                                          ]
                                        : _viewMode == 1
                                            ? [
                                                _buildDetailRow('Manager Name',
                                                    item['manager_name']),
                                                _buildDetailRow('Profile Image',
                                                    item['profile_image']),
                                                     _buildDetailRow('cinefoDeviceId',
                                                    item['cinefoDeviceId']?.toString()),
                                                _buildDetailRow(
                                                    'Registered Movie',
                                                    item['registered_movie']),
                                                _buildDetailRow('Mobile Number',
                                                    item['mobile_number']),
                                                _buildDetailRow('Password',
                                                    item['password']),
                                                _buildDetailRow('Project ID',
                                                    item['project_id']),
                                                _buildDetailRow(
                                                    'Production Type ID',
                                                    item['production_type_id']
                                                        ?.toString()),
                                                _buildDetailRow(
                                                    'Production House',
                                                    item['production_house']),
                                                _buildDetailRow('VMID',
                                                    item['vmid']?.toString()),
                                                _buildDetailRow(
                                                    'Login Date',
                                                    _formatDate(
                                                        item['login_date'])),
                                                _buildDetailRow('Device ID',
                                                    item['device_id']),
                                                _buildDetailRow(
                                                    'VSID', item['vsid']),
                                                _buildDetailRow(
                                                    'VPID', item['vpid']),
                                                _buildDetailRow('VUID',
                                                    item['vuid']?.toString()),
                                                _buildDetailRow('Company Name',
                                                    item['companyName']),
                                                _buildDetailRow(
                                                    'Email', item['email']),
                                                _buildDetailRow('VBPID',
                                                    item['vbpid']?.toString()),
                                                _buildDetailRow('VCID',
                                                    item['vcid']?.toString()),
                                                _buildDetailRow('VSUBID',
                                                    item['vsubid']?.toString()),
                                                _buildDetailRow('VPOID',
                                                    item['vpoid']?.toString()),
                                                _buildDetailRow(
                                                    'MTypeId',
                                                    item['mtypeId']
                                                        ?.toString()),
                                                _buildDetailRow('Unit Name',
                                                    item['unitName']),
                                                _buildDetailRow(
                                                    'VMTypeId',
                                                    item['vmTypeId']
                                                        ?.toString()),
                                                _buildDetailRow('ID Card URL',
                                                    item['idcardurl']),
                                                _buildDetailRow('VPIDPO',
                                                    item['vpidpo']?.toString()),
                                                _buildDetailRow('VPIDBP',
                                                    item['vpidbp']?.toString()),
                                                _buildDetailRow('Unit ID',
                                                    item['unitid']?.toString()),
                                                _buildDetailRow('Platform Logo',
                                                    item['platformlogo']),
                                              ]
                                            : _viewMode == 2
                                                ? [
                                                    _buildDetailRow(
                                                        'Name', item['name']),
                                                    _buildDetailRow(
                                                        'Designation',
                                                        item['designation']),
                                                    _buildDetailRow(
                                                        'Code', item['code']),
                                                    _buildDetailRow(
                                                        'Union Name',
                                                        item['unionName']),
                                                    _buildDetailRow(
                                                        'VCID', item['vcid']),
                                                    _buildDetailRow(
                                                        'CallsheetID',
                                                        item['callsheetid']
                                                            ?.toString()),
                                                    _buildDetailRow(
                                                        'Marked At',
                                                        _formatDate(
                                                            item['marked_at'])),
                                                    _buildDetailRow(
                                                        'attendance_status',
                                                        item[
                                                            'attendance_status']),
                                                    _buildDetailRow(
                                                        'Mode', item['mode']),
                                                    _buildDetailRow(
                                                        'attendanceDate',
                                                        item['attendanceDate']),
                                                    _buildDetailRow(
                                                        'attendanceTime',
                                                        item['attendanceTime']),
                                                  ]
                                                : [
                                                    _buildDetailRow(
                                                        'Callsheet ID',
                                                        item['callSheetId']
                                                            ?.toString()),
                                                    _buildDetailRow(
                                                        'Callsheet No',
                                                        item['callSheetNo']
                                                            ?.toString()),
                                                    _buildDetailRow(
                                                        'MovieName',
                                                        item['MovieName']
                                                            ?.toString()),
                                                    _buildDetailRow(
                                                        'Callsheet Name',
                                                        item['callsheetname']
                                                            ?.toString()),
                                                    _buildDetailRow(
                                                        'Shift',
                                                        item['shift']
                                                            ?.toString()),
                                                    _buildDetailRow(
                                                        'Shift ID',
                                                        item['shiftId']
                                                            ?.toString()),
                                                    _buildDetailRow(
                                                        'Latitude',
                                                        item['latitude']
                                                            ?.toString()),
                                                    _buildDetailRow(
                                                        'Longitude',
                                                        item['longitude']
                                                            ?.toString()),
                                                    _buildDetailRow(
                                                        'Project ID',
                                                        item['projectId']
                                                            ?.toString()),
                                                    _buildDetailRow(
                                                        'Production Type ID',
                                                        item['productionTypeid']
                                                            ?.toString()),
                                                    _buildDetailRow('Location',
                                                        item['location']),
                                                    _buildDetailRow(
                                                        'Location Type',
                                                        item['locationType']),
                                                    _buildDetailRow('Status',
                                                        item['status']),
                                                    _buildDetailRow(
                                                        'Location Type ID',
                                                        item['locationTypeId']
                                                            ?.toString()),
                                                    _buildDetailRow(
                                                        'Created At',
                                                        _formatDate(item[
                                                            'created_at'])),
                                                    _buildDetailRow(
                                                        'Created time',
                                                        item[
                                                            'created_at_time']),
                                                    _buildDetailRow(
                                                        'Created date',
                                                        item['created_date']),
                                                    _buildDetailRow(
                                                        'pack_up_time',
                                                        item['pack_up_time']),
                                                    _buildDetailRow(
                                                        'pack_up_date',
                                                        item['pack_up_date']),
                                                    _buildDetailRow('isonline',
                                                        item['isonline']),
                                                  ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
