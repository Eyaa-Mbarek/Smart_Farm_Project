import 'package:flutter/material.dart';
import 'package:smart_farm_test/presentation/screens/home/home_screen.dart'; // Your dashboard
import 'package:smart_farm_test/presentation/screens/profile/profile_screen.dart'; // Profile page

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index for the selected tab

  // List of the pages to navigate between
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Index 0
    ProfileScreen(), // Index 1
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body will be the widget from _widgetOptions based on the selected index
      body: IndexedStack( // Use IndexedStack to keep state of pages
         index: _selectedIndex,
         children: _widgetOptions,
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
             activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
             activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
         showUnselectedLabels: false, // Optional: Hide labels for unselected items
      ),
    );
  }
}