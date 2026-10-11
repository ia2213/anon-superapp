import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/search_result.dart';

class AnonymousBrowserScreen extends StatelessWidget {
  final SearchResult result;

  const AnonymousBrowserScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(result.url);

    return Scaffold(
      appBar: AppBar(
        title: Text(result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            tooltip: 'Ouvrir en externe',
          ),
        ],
      ),
      body: Column(
        children: [
          // Privacy Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF0F0F1A),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Color(0xFF00D4AA), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mode Tor Anonyme • Cookies isolés • IP masquée',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('SÉCURISÉ', style: TextStyle(color: Colors.green, fontSize: 10)),
                ),
              ],
            ),
          ),
          // Embedded secure view simulating anonymous browsing container
          Expanded(
            child: Container(
              color: const Color(0xFF12121C),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security, size: 64, color: Color(0xFF00D4AA)),
                      const SizedBox(height: 20),
                      Text(
                        result.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        result.url,
                        style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        result.snippet,
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D4AA),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        icon: const Icon(Icons.launch),
                        label: const Text('Ouvrir la page cible chiffrée'),
                        onPressed: () async {
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
