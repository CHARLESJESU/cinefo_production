import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'offlinecreatecallsheet.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:production/Screens/Home/offline_callsheet_detail_screen.dart';

class CallSheet extends StatefulWidget {
  const CallSheet({super.key});

  @override
  State<CallSheet> createState() => _CallSheetState();
}

class _CallSheetState extends State<CallSheet> {
  List<Map<String, dynamic>> _callsheetList = [];

  @override
  void initState() {
    super.initState();
    _fetchCallsheetData();
  }

  Future<void> _fetchCallsheetData() async {
    try {
      String dbPath =
          path.join(await getDatabasesPath(), 'production_login.db');
      final db = await openDatabase(dbPath);

      // Fetch callsheet table (if exists)
      final callsheetTable = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='callsheetoffline'");
      if (callsheetTable.isNotEmpty) {
        final List<Map<String, dynamic>> callsheetMaps = await db.query(
          'callsheetoffline',
          orderBy: 'created_at DESC',
        );
        setState(() {
          _callsheetList = callsheetMaps;
        });
      } else {
        setState(() {
          _callsheetList = [];
        });
      }
      await db.close();
    } catch (e) {
      setState(() {
        _callsheetList = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final isMobile =
            sizingInformation.deviceScreenType == DeviceScreenType.mobile;
        final horizontalPadding = isMobile ? 20.0 : 60.0;
        final fontSizeHeader = isMobile ? 18.0 : 24.0;

        return Scaffold(
          backgroundColor: const Color.fromRGBO(247, 244, 244, 1),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Stack(
                  children: [
                    // Full screen blue container
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height - 200,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF2B5682),
                            Color(0xFF24426B),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          top: 20,
                          right: horizontalPadding,
                          bottom: 20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text("CallSheet",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: fontSizeHeader,
                                        fontWeight: FontWeight.w500)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            OfflineCreateCallSheet(),
                                      ),
                                    );
                                    // Refresh when coming back from create screen
                                    await _fetchCallsheetData();
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.add,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Today's Schedule section above profile card
                    Padding(
                      padding: EdgeInsets.only(
                        top: isMobile ? 60 : 70,
                        left: horizontalPadding,
                        right: horizontalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Schedule",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: fontSizeHeader,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Offline call sheet section
                    Padding(
                      padding: EdgeInsets.only(
                        top: isMobile ? 140 : 150,
                        left: horizontalPadding,
                        right: horizontalPadding,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Callsheet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2B5682),
                              ),
                            ),
                            const SizedBox(height: 15),
                            if (_callsheetList.isNotEmpty)
                              ..._callsheetList.map((item) => _buildListItem(
                                    item['callSheetNo']?.toString() ?? '',
                                    item['locationType']?.toString() ?? '',
                                    (item['created_at']?.toString() ?? '')
                                        .split('T')
                                        .first,
                                    item['status']?.toString() ?? '',
                                    callsheetData: item,
                                  ))
                            else
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No call sheet available',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Create a call sheet to see it here',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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
              _fetchCallsheetData();
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
