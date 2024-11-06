import 'package:flutter/material.dart';
import 'screens/rooms_list_screen.dart';
import 'screens/tenants_list_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/transactions_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // White background color
        primaryColor: Colors.black, // Black primary color
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.black), // Black text color
        ),
        iconTheme: IconThemeData(color: Colors.black), // Black icon color
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    RoomsListScreen(),
    TenantsListScreen(),
    AnalyticsScreen(),
    TransactionsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white, // White background for the nav bar
        selectedItemColor: Colors.black, // Black color for the selected item
        unselectedItemColor: Colors.black54, // Slightly faded black for unselected items
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Tenants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Transactions',
          ),
        ],
      ),
    );
  }
}
