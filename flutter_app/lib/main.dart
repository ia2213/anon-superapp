import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/social/social_screen.dart';
import 'screens/utilities/utilities_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: AnonSuperApp()));
}

class AnonSuperApp extends StatelessWidget {
  const AnonSuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'AnonSuperApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF1A1A2E),
      ),
      home: AnonSuperAppHome(),
    );
  }
}

class AnonSuperAppHome extends StatefulWidget {
  const AnonSuperAppHome({super.key});

  @override
  State<AnonSuperAppHome> createState() => _AnonSuperAppHomeState();
}

class _AnonSuperAppHomeState extends State<AnonSuperAppHome> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = [
    MessagesScreen(),
    SocialScreen(),
    UtilitiesScreen(),
    WalletScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'AnonSuperApp',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
            tooltip: 'Rechercher',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
            tooltip: 'Plus',
          ),
        ],
      ),
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F0F1A),
        selectedItemColor: const Color(0xFF00D4AA),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.message, size: 24),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people, size: 24),
            label: 'Réseau',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.extension, size: 24),
            label: 'Utilitaires',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on, size: 24),
            label: 'Paiement',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 24),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}
