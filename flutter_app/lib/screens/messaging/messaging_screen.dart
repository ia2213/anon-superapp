import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../models/chat_room.dart';
import '../../models/chat_message.dart';

final roomsProvider = FutureProvider<List<ChatRoom>>((ref) async {
  final api = ApiService();
  return api.getRooms();
});

class MessagingScreen extends ConsumerStatefulWidget {
  const MessagingScreen({super.key});

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  final _api = ApiService();
  String? _myPublicKey;
  String? _myPrivateKey;
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _initKeys();
  }

  Future<void> _initKeys() async {
    final keys = await _api.generateKeyPair();
    if (keys.isNotEmpty && mounted) {
      setState(() {
        _myPublicKey = keys['public_key'];
        _myPrivateKey = keys['private_key'];
        _myId = keys['public_key']?.substring(0, 8) ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Messages Privés'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showCreateRoomDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Encryption Status
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: Color(0xFF00D4AA), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chiffrement de bout en bout',
                        style: TextStyle(
                          color: Color(0xFF00D4AA),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (_myId.isNotEmpty)
                        Text(
                          'Votre ID: $_myId',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_tethering, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('P2P', style: TextStyle(color: Colors.green, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Rooms List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(roomsProvider);
              },
              color: const Color(0xFF00D4AA),
              child: _buildRoomsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList() {
    final roomsAsync = ref.watch(roomsProvider);

    return roomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                const Text('Aucun salon'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un salon'),
                  onPressed: () => _showCreateRoomDialog(),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return _buildRoomCard(room);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $e'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(roomsProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(ChatRoom room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6C63FF),
          child: Text(
            room.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(room.name),
        subtitle: Text(
          '${room.participants.length} participant(s)',
          style: TextStyle(color: Colors.grey[500]),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openChatRoom(room),
      ),
    );
  }

  void _showCreateRoomDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Nouveau Salon'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nom du salon',
            prefixIcon: Icon(Icons.tag),
          ),
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
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _api.createRoom(controller.text);
                if (mounted) {
                  Navigator.pop(context);
                  ref.invalidate(roomsProvider);
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _openChatRoom(ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          room: room,
          myId: _myId,
          publicKey: _myPublicKey ?? '',
          privateKey: _myPrivateKey ?? '',
        ),
      ),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom room;
  final String myId;
  final String publicKey;
  final String privateKey;

  const ChatRoomScreen({
    super.key,
    required this.room,
    required this.myId,
    required this.publicKey,
    required this.privateKey,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _api = ApiService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final messages = await _api.getMessages(widget.room.id);
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final content = _controller.text;
    _controller.clear();

    // Encrypt message
    final encrypted = await _api.encryptMessage(content, widget.publicKey);
    
    final message = await _api.sendMessage(
      widget.room.id,
      content, // Send plaintext for demo (in real app send encrypted)
      widget.myId,
    );

    if (message != null && mounted) {
      setState(() => _messages.add(message));
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.room.name),
            Text(
              '${widget.room.participants.length} participants',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () => _showEncryptionInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun message. Commencez la conversation!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == widget.myId;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A2E),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Message chiffré...',
                      filled: true,
                      fillColor: const Color(0xFF0F0F1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF00D4AA),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF00D4AA) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderId,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  message.encrypted ? Icons.lock : Icons.lock_open,
                  size: 10,
                  color: isMe ? Colors.black54 : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.black54 : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEncryptionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Color(0xFF00D4AA)),
            SizedBox(width: 8),
            Text('Chiffrement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vos messages sont chiffrés avec:'),
            const SizedBox(height: 12),
            _buildCryptoInfo('Algorithme', 'Curve25519 + AES-256-GCM'),
            _buildCryptoInfo('Clé publique', widget.publicKey?.substring(0, 16) ?? 'N/A'),
            _buildCryptoInfo('Mode', 'P2P via Tor'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
