import 'package:flutter/material.dart';
import 'search/search_screen.dart';
import 'wallet/wallet_screen.dart';
import 'messaging/messaging_screen.dart';
import 'transfer/transfer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const SearchScreen(),
    const WalletScreen(),
    const MessagingScreen(),
    const TransferScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.file_copy_outlined),
            selectedIcon: Icon(Icons.file_copy),
            label: 'Transfer',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🛡️ AnonSuperApp',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your privacy-first super app',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            _buildStatusCard(
              context,
              '🔍 Search',
              'SearXNG + Tor',
              'Anonymous web search',
              Colors.blue,
            ),
            _buildStatusCard(
              context,
              '💳 Wallet',
              'Zero-KYC Cards',
              'Crypto prepaid cards',
              Colors.green,
            ),
            _buildStatusCard(
              context,
              '💬 Messaging',
              'P2P Encrypted',
              'Berty/Tor/WebRTC',
              Colors.purple,
            ),
            _buildStatusCard(
              context,
              '📁 Transfer',
              'croc P2P',
              'Secure file sharing',
              Colors.orange,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00D4AA).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: Color(0xFF00D4AA)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '100% Anonymous — No logs, no tracking, zero KYC',
                      style: TextStyle(color: Color(0xFF00D4AA)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    String title,
    String subtitle,
    String description,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.circle, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
