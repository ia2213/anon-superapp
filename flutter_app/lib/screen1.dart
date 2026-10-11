import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/messenger/messenger_screen.dart';
import 'screens/groups/groups_screen.dart';

class AnonSuperApp extends StatelessWidget {
  const AnonSuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: MaterialApp(
        title: 'AnonSuperApp',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AnonSuperAppHome(),
      ),
    );
  }
}

class AnonSuperAppHome extends StatelessWidget {
  const AnonSuperAppHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AnonSuperApp'),
          backgroundColor: const Color(0xFF1A1A2E),
          bottom: const TabBar(
            labelColor: Color(0xFF00D4AA),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Messages'),
              Tab(text: 'Messagerie'),
              Tab(text: 'Groupes'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
              tooltip: 'Rechercher',
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
              tooltip: 'Plus',
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            MessagesScreen(),
            MessengerScreen(),
            GroupsScreen(),
          ],
        ),
      ),
    );
  }
}
