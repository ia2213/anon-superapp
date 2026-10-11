import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';

final systemStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ApiService();
  return api.getSystemStatus();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(systemStatusProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Paramètres'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Section
          _buildSectionHeader('État du Système'),
          statusAsync.when(
            data: (status) => _buildStatusCard(status),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e'),
          ),
          
          const SizedBox(height: 24),
          
          // Privacy Section
          _buildSectionHeader('Confidentialité'),
          _buildSettingsTile(
            icon: Icons.shield,
            title: 'Protection IP',
            subtitle: 'Tor Always-On',
            trailing: Switch(
              value: true,
              onChanged: null,
              activeColor: const Color(0xFF00D4AA),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.visibility_off,
            title: "Masquer l'activité",
            subtitle: 'Aucun log de navigation',
            trailing: Switch(
              value: true,
              onChanged: null,
              activeColor: const Color(0xFF00D4AA),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.lock,
            title: 'Chiffrement',
            subtitle: 'Curve25519 + AES-256-GCM',
            trailing: Switch(
              value: true,
              onChanged: null,
              activeColor: const Color(0xFF00D4AA),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Network Section
          _buildSectionHeader('Réseau'),
          _buildSettingsTile(
            icon: Icons.dns,
            title: 'API Server',
            subtitle: 'http://localhost:8000',
            onTap: () => _showApiSettings(context),
          ),
          _buildSettingsTile(
            icon: Icons.wifi_tethering,
            title: 'Tor Proxy',
            subtitle: 'socks5://localhost:9050',
          ),
          _buildSettingsTile(
            icon: Icons.search,
            title: 'SearXNG',
            subtitle: 'http://localhost:8080',
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader('À propos'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'AnonSuperApp',
            subtitle: 'Version 1.0.0',
          ),
          _buildSettingsTile(
            icon: Icons.code,
            title: 'Code Source',
            subtitle: 'github.com/ia2213/anon-superapp',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.description,
            title: 'Licence',
            subtitle: 'MIT',
          ),
          
          const SizedBox(height: 32),
          
          // Danger Zone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Zone Dangereuse',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Effacer toutes les données'),
                    onPressed: () => _showDeleteConfirmation(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00D4AA),
        ),
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Système Opérationnel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (status['modules'] != null)
              ...((status['modules'] as Map).entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF00D4AA)),
                    const SizedBox(width: 8),
                    Text('${e.key}: OK'),
                  ],
                ),
              ))),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00D4AA)),
        title: Text(title),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500])),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }

  void _showApiSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Configuration API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "URL de l'API",
                hintText: 'http://localhost:8000',
                filled: true,
                fillColor: const Color(0xFF0F0F1A),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmation'),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir effacer toutes les données? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement data deletion
            },
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }
}
