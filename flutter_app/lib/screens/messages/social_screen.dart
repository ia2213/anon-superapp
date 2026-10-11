import 'package:flutter/material.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réseau Social'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildMomentsTab(),
          _buildChannelsTab(),
          _buildTopStoriesTab(),
        ],
      ),
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

  Widget _buildMomentsTab() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Moments'),
            _buildMomentCard('Je viens de publier un nouvel article sur mon avancement sur AnonSuperApp 🚀', 'Calendrier', 'Aujourd\'hui'),
            _buildMomentCard('💭 Note : Le développement de la SuperApp est en cours. J\'ai besoin de temps mais le résultat sera formidable.', 'Calendrier', 'Aujourd\'hui'),
            _buildMomentCard('Découverte de nouvelles API publiques pour la recherche anonyme - résultats impressionnants !', 'Annuaire', 'Hier'),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentCard(String text, String author, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF0F0F1A),
                    child: Text(
                      author[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author, style: const TextStyle(color: Colors.white)),
                      Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(text, style: TextStyle(color: Colors.grey[300], height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelsTab() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Channels'),
            _buildChannelCard('Calendrier', 'Aujourd\'hui', 12345),
            _buildChannelCard('Annuaire', 'Hier', 5678),
            const SizedBox(height: 16),
            _buildSectionHeader('Livestream'),
            _buildChannelCard('Live: Développement AnonSuperApp', 'En direct', 5521),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCard(String name, String time, int viewers) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 120,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam, color: Color(0xFF00D4AA), size: 32),
                    SizedBox(height: 4),
                    Text('Vidéo', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$viewers spectateurs', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_filled, color: Color(0xFF00D4AA), size: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStoriesTab() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Top Stories'),
            _buildStoryCard('Liens intéressants', 'Aujourd\'hui'),
            _buildStoryCard('Actualité tech : nouvelles API publiques', 'Aujourd\'hui'),
            const SizedBox(height: 16),
            const Text(
              'Vos proches lisent:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            _buildStoryCard('Apprentissage de l\'application AnonSuperApp', 'Hier', isContact: true),
            _buildStoryCard('Atelier de développement iOS', 'Hier', isContact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildStoryCard(String text, String time, {bool isContact = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isContact)
                const CircleAvatar(
                  backgroundColor: Color(0xFF00D4AA),
                  child: Text('👤', size: 24),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.article, color: Colors.grey),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
