import 'package:flutter/material.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    Center(child: Text('Inventory')),
    Center(child: Text('Expiry')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Med Cabinet'),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Expiry',
          ),
        ],
      ),
    );
  }
}
