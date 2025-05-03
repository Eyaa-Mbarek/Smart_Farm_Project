import 'package:flutter/material.dart';
import 'package:smart_farm_test/presentation/screens/home/home_screen.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/screens/profile/profile_screen.dart'; // Adjust import path

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index for the selected tab

  // List of the pages to navigate between
  // Keep state of each page using IndexedStack
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Index 0 - Dashboard
    ProfileScreen(), // Index 1 - Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("MainScreen building with index: $_selectedIndex"); // Debug log
    return Scaffold(
      // Use IndexedStack to preserve the state of each screen when switching tabs
      body: IndexedStack(
         index: _selectedIndex,
         children: _widgetOptions,
      ),
      // Bottom Navigation Bar setup
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
             activeIcon: Icon(Icons.dashboard), // Optional: different icon when active
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
             activeIcon: Icon(Icons.person), // Optional: different icon when active
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex, // Highlight the current tab
        selectedItemColor: Theme.of(context).colorScheme.primary, // Color for selected item
        unselectedItemColor: Colors.grey.shade600, // Color for unselected items
        onTap: _onItemTapped, // Callback when a tab is tapped
         // Optional styling:
         // type: BottomNavigationBarType.fixed, // Or .shifting
         // showUnselectedLabels: false,
         // selectedFontSize: 12,
         // unselectedFontSize: 10,
      ),
    );
  }
}