import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../models/file_transfer.dart';

final transfersProvider = StateNotifierProvider<TransfersNotifier, List<FileTransfer>>((ref) {
  return TransfersNotifier();
});

class TransfersNotifier extends StateNotifier<List<FileTransfer>> {
  TransfersNotifier() : super([]);

  void addTransfer(FileTransfer transfer) {
    state = [...state, transfer];
  }

  void updateTransfer(FileTransfer transfer) {
    state = state.map((t) => t.transferId == transfer.transferId ? transfer : t).toList();
  }
}

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();
  String _currentCodePhrase = '';
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📁 Transfert P2P'),
        backgroundColor: const Color(0xFF1A1A2E),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00D4AA),
          labelColor: const Color(0xFF00D4AA),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Envoyer', icon: Icon(Icons.upload_file)),
            Tab(text: 'Recevoir', icon: Icon(Icons.download)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendTab(),
          _buildReceiveTab(),
        ],
      ),
    );
  }

  Widget _buildSendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  const Color(0xFF00D4AA).withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: Color(0xFF00D4AA)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transfert chiffré de bout en bout',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Via croc relay + Tor pour anonymat',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // File Picker
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[800]!,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sélectionnez un fichier à envoyer',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Parcourir'),
                  onPressed: _isTransferring ? null : _pickAndSendFile,
                ),
              ],
            ),
          ),

          // Transfer Progress
          if (_isTransferring) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00D4AA)),
                    const SizedBox(height: 16),
                    const Text('Génération du code phrase...'),
                  ],
                ),
              ),
            ),
          ],

          // Result
          if (_currentCodePhrase.isNotEmpty && !_isTransferring) ...[
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFF1A1A2E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF00D4AA)),
                        SizedBox(width: 8),
                        Text(
                          'Prêt à envoyer!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00D4AA),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text(
                      'Partagez ce code avec le destinataire:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _currentCodePhrase,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00D4AA),
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D4AA),
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.copy),
                          label: const Text('Copier'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _currentCodePhrase));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copié!')),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Nouveau'),
                          onPressed: () => setState(() => _currentCodePhrase = ''),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Recent Transfers
          const SizedBox(height: 24),
          const Text(
            'Transferts récents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, _) {
              final transfers = ref.watch(transfersProvider);
              if (transfers.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 48, color: Colors.grey[700]),
                          const SizedBox(height: 8),
                          Text(
                            'Aucun transfert récent',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: transfers.reversed.take(5).map((t) => _buildTransferCard(t)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveTab() {
    final codeController = TextEditingController();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF6C63FF)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Entrez le code phrase pour télécharger le fichier',
                    style: TextStyle(color: Color(0xFF6C63FF)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Code Input
          TextField(
            controller: codeController,
            decoration: InputDecoration(
              labelText: 'Code phrase',
              hintText: 'Entrez le code à 4 mots',
              prefixIcon: const Icon(Icons.key, color: Color(0xFF00D4AA)),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            textCapitalization: TextCapitalization.none,
          ),

          const SizedBox(height: 24),

          // Download Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.download),
              label: const Text(
                'Télécharger',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _receiveFile(codeController.text),
            ),
          ),

          const SizedBox(height: 32),

          // How it works
          const Text(
            'Comment ça marche?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildHowItWorks(1, "L'expéditeur sélectionne un fichier", Icons.upload_file),
          _buildHowItWorks(2, 'Un code phrase secret est généré', Icons.key),
          _buildHowItWorks(3, 'Vous entrez le code pour télécharger', Icons.download),
          _buildHowItWorks(4, 'Le fichier est chiffré P2P', Icons.lock),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(int step, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Color(0xFF00D4AA),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildTransferCard(FileTransfer transfer) {
    IconData icon;
    Color color;
    
    switch (transfer.status) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'pending':
        icon = Icons.pending;
        color = Colors.orange;
        break;
      case 'failed':
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.hourglass_empty;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(transfer.fileName ?? 'Transfert'),
        subtitle: Text(transfer.status),
        trailing: transfer.codePhrase != null
            ? IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: transfer.codePhrase!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copié!')),
                  );
                },
              )
            : null,
      ),
    );
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      
      if (result != null && result.files.single.path != null) {
        setState(() => _isTransferring = true);
        
        final transfer = await _api.sendFile(result.files.single.path!);
        
        if (transfer != null && mounted) {
          setState(() {
            _currentCodePhrase = transfer.codePhrase ?? '';
            _isTransferring = false;
          });
          ref.read(transfersProvider.notifier).addTransfer(transfer);
        } else if (mounted) {
          setState(() => _isTransferring = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de l'envoi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTransferring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _receiveFile(String codePhrase) async {
    if (codePhrase.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez un code phrase')),
      );
      return;
    }

    setState(() => _isTransferring = true);

    try {
      final transfer = await _api.receiveFile(codePhrase);
      
      if (transfer != null && mounted) {
        ref.read(transfersProvider.notifier).addTransfer(transfer);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fichier reçu: ${transfer.fileName}')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code invalide ou expiré')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTransferring = false);
      }
    }
  }
}
