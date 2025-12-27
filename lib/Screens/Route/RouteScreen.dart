import 'package:flutter/material.dart';
import 'package:production/Screens/Home/MyHomescreen.dart';
import 'package:production/Screens/callsheet/callsheet.dart';
import 'package:production/Screens/report/Reports.dart';
import 'package:production/variables.dart';

class Routescreen extends StatefulWidget {
  final int initialIndex;

  const Routescreen({super.key, this.initialIndex = 0}); // Default to Home tab

  @override
  State<Routescreen> createState() => _RoutescreenState();
}

class _RoutescreenState extends State<Routescreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // Set initial tab from parameter
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF355E8C),
      body: SafeArea(
        child: _getScreenWidget(_currentIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF355E8C),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Callsheet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Reports',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.trip_origin),
          //   label: 'Trip',
          // ),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _getScreenWidget(int index) {
    switch (index) {
      case 0:
        // return const MovieListScreen();
        return const MyHomescreen();
      case 1:
        // if (productionTypeId == 3) {
        //   return (selectedProjectId != null && selectedProjectId != "0")
        //       ? CallSheet()
        //       : const MovieListScreen();
        // } else {
        //   // For productionTypeId == 2 or any other case
        //   return CallSheet();
        // }
        return CallSheet();

      case 2:
        return Reports(
          projectId: projectid.toString(),
          callsheetid: callsheetid.toString(),
        );
      // case 3:
      //   return TripScreen();
      default:
        return const MyHomescreen();
    }
  }
}
