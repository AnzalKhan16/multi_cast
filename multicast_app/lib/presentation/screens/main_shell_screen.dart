import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'sender_screen.dart';
import 'receiver_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SenderScreen(),
    ReceiverScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.send_outlined),
      selectedIcon: Icon(Icons.send),
      label: 'Broadcast',
    ),
    NavigationDestination(
      icon: Icon(Icons.connected_tv_outlined),
      selectedIcon: Icon(Icons.connected_tv),
      label: 'Receive',
    ),
  ];

  final List<NavigationRailDestination> _railDestinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.send_outlined),
      selectedIcon: Icon(Icons.send),
      label: Text('Broadcast'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.connected_tv_outlined),
      selectedIcon: Icon(Icons.connected_tv),
      label: Text('Receive'),
    ),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsive layout
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: _railDestinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: _screens[_currentIndex],
                ),
              ],
            )
          : _screens[_currentIndex],
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: _destinations,
            ),
    );
  }
}
