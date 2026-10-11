import 'package:flutter/material.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groupes'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Column(
        children: [
          _buildCreateGroupCard(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildGroupCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateGroupCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F1A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.group_add, color: Color(0xFF00D4AA)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Nom du groupe',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Créer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0F0F1A),
          child: Text((index + 1).toString(), style: const TextStyle(color: Colors.white)),
        ),
        title: Text('Groupe $index', style: const TextStyle(color: Colors.white)),
        subtitle: const Text('24 membres', style: TextStyle(color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.videocam, color: Color(0xFF00D4AA)),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.call, color: const Color(0xFF00D4AA)),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
