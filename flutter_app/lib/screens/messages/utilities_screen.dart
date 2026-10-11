import 'package:flutter/material.dart';

class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Utilitaires'),
          backgroundColor: const Color(0xFF1A1A2E),
          bottom: const TabBar(
            labelColor: Color(0xFF00D4AA),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Scanner'),
              Tab(text: 'Recherche'),
              Tab(text: 'Paramètres'),
              Tab(text: 'À propos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ScannerTab(),
            _SearchTab(),
            _SettingsTab(),
            _AboutTab(),
          ],
        ),
      ),
    );
  }
}

class _ScannerTab extends StatelessWidget {
  const _ScannerTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Scanner multi-fonctions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[700]!, width: 2),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 64, color: Color(0xFF00D4AA)),
                        SizedBox(height: 8),
                        Text(
                          'Appareil photo',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        Text(
                          'Scanner QR codes',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Ouvrir l\'appareil photo'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Recherche avancée',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher sur internet...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00D4AA)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0F0F1A),
                ),
              ),
              const SizedBox(height: 16),
              _buildSearchResult('Résultat 1', 'Résumé du résultat 1...'),
              const Divider(height: 1),
              _buildSearchResult('Résultat 2', 'Résumé du résultat 2...'),
              const Divider(height: 1),
              _buildSearchResult('Résultat 3', 'Résumé du résultat 3...'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResult(String title, String snippet) {
    return ListTile(
      leading: const Icon(Icons.search, color: Color(0xFF00D4AA)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(snippet, style: TextStyle(color: Colors.grey[400])),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.shield, color: Color(0xFF00D4AA)),
            title: const Text('Protection IP', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Privacité renforcée', style: TextStyle(color: Colors.grey)),
            trailing: Switch(
              value: true,
              onChanged: (val) {},
              activeColor: const Color(0xFF00D4AA),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.grey),
            title: const Text('Paramètres de confidentialité', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Gérer les préférences de confidentialité', style: TextStyle(color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ),
        const Divider(),
        const Text(
          'Paramètres de confidentialité',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        _buildSettingItem('Protection IP', 'Tor Always-On activé', Icons.shield),
        _buildSettingItem('Cacher l\'activité', 'Aucun log de navigation', Icons.visibility_off),
        _buildSettingItem('Chiffrement', 'Curve25519 + AES-256-GCM', Icons.lock),
        const Divider(),
        const Text(
          'Réseau',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        _buildSettingItem('SearXNG', 'http://localhost:8080', Icons.search),
        _buildSettingItem('Tor Proxy', 'socks5://localhost:9050', Icons.dns),
      ],
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0F0F1A),
          child: Icon(icon, color: Colors.grey),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFF0F0F1A),
          child: const Icon(Icons.apps, size: 48, color: Color(0xFF00D4AA)),
        ),
        const SizedBox(height: 16),
        const Text(
          'AnonSuperApp',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Version 1.0.0',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const Text(
          'Privacy-First Super-App',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Une application complète : Messagerie, Réseau Social, Utilitaires, Paiements et plus.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const Text(
          'Fonctionnalités incluses',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        _buildAboutItem('Messagerie', 'Textes, notes vocales, appels, groupes'),
        _buildAboutItem('Réseau Social', 'Moments, Channels, Top Stories'),
        _buildAboutItem('Utilitaires', 'Scanner, Recherche, Paramètres'),
        _buildAboutItem('Finance', 'Paiement mobile, Transferts'),
      ],
    );
  }

  Widget _buildAboutItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check, color: const Color(0xFF00D4AA)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
