import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../models/search_result.dart';
import '../../models/crypto_rate.dart';
import '../../models/prepaid_card.dart';
import '../../models/chat_room.dart';
import '../../models/chat_message.dart';
import '../../models/file_transfer.dart';
import 'messages/messages_screen.dart';

class MessengerScreen extends ConsumerWidget {
  const MessengerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messagerie Avancée'),
          backgroundColor: const Color(0xFF1A1A2E),
          bottom: const TabBar(
            labelColor: Color(0xFF00D4AA),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Status'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {},
              tooltip: 'Nouveau message',
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _ChatsTab(),
            _StatusTab(),
          ],
        ),
      ),
    );
  }
}

class _ChatsTab extends StatelessWidget {
  const _ChatsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 10,
            itemBuilder: (context, index) {
              return _buildChatItem(context, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00D4AA)),
          suffixIcon: const Icon(Icons.mic, color: Color(0xFF00D4AA)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFF0F0F1A),
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const CircleAvatar(
                  backgroundColor: Color(0xFF00D4AA),
                  child: Icon(Icons.person, size: 28, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Contact $index',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4AA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'En ligne',
                            style: TextStyle(fontSize: 10, color: Color(0xFF00D4AA)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Message imparable...',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Statuts en temps réel',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildStatusCard('Vos contacts', 245, 'en ligne'),
        _buildStatusCard('Groupes actifs', 18, 'en ligne'),
        _buildStatusCard('Mini-apps', 42, 'disponible'),
        _buildStatusCard('Paiements', 12, 'en ligne'),
        const SizedBox(height: 16),
        const Text(
          'Actif',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildLiveStatus(),
      ],
    );
  }

  Widget _buildStatusCard(String title, int count, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00D4AA).withOpacity(0.1),
          child: Icon(
            status == 'en ligne' ? Icons.check_circle : Icons.hourglass_empty,
            color: status == 'en ligne' ? Color(0xFF00D4AA) : Colors.grey,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00D4AA)),
        ),
      ),
    );
  }

  Widget _buildLiveStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statut en temps réel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusRow(Icons.currency_bitcoin, 'Bitcoin', '\$88,500', '$+1.2%'),
            _buildStatusRow(Icons.currency_bitcoin, 'Monero', '\$165', '\$+2.5%'),
            _buildStatusRow(Icons.currency_bitcoin, 'Litecoin', '\$85', '\$−0.5%'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, String change) {
    final isPositive = change.startsWith('+');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF00D4AA)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPositive ? const Color(0xFF00D4AA).withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              change,
              style: TextStyle(
                color: isPositive ? Color(0xFF00D4AA) : Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
