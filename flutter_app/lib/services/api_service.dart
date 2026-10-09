import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_result.dart';
import '../models/crypto_rate.dart';
import '../models/prepaid_card.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/file_transfer.dart';

/// API Service for AnonSuperApp Backend
class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000"; // Android emulator
  //static const String baseUrl = "http://localhost:8000"; // iOS simulator / local
  
  final http.Client _client = http.Client();
  
  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  // ==================== SEARCH ====================
  
  Future<List<SearchResult>> search(String query, {String language = "fr", int maxResults = 10}) async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/search"),
        headers: _headers,
        body: jsonEncode({
          "query": query,
          "language": language,
          "max_results": maxResults,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List? ?? [];
        return results.map((r) => SearchResult.fromJson(r)).toList();
      }
      return [];
    } catch (e) {
      print("Search error: $e");
      return [];
    }
  }
  
  Future<Map<String, bool>> checkEngines() async {
    try {
      final response = await _client.get(
        Uri.parse("$baseUrl/search/engines"),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return {for (var e in data) e['name'] as String: e['available'] as bool};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ==================== WALLET ====================
  
  Future<Map<String, CryptoRate>> getCryptoRates() async {
    try {
      final response = await _client.get(
        Uri.parse("$baseUrl/api/wallet/rates"),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>? ?? {};
        return rates.map((k, v) => MapEntry(k, CryptoRate.fromJson(k, v)));
      }
      return {};
    } catch (e) {
      print("Rates error: $e");
      return {};
    }
  }
  
  Future<Map<String, dynamic>> getCardQuote(double amountUsd, String cryptoSymbol) async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/api/wallet/prepaid-card/quote"),
        headers: _headers,
        body: jsonEncode({
          "amount_usd": amountUsd,
          "crypto_symbol": cryptoSymbol,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print("Quote error: $e");
      return {};
    }
  }
  
  Future<PrepaidCard?> createCardOrder(double amountUsd, String cryptoSymbol) async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/api/wallet/prepaid-card/order"),
        headers: _headers,
        body: jsonEncode({
          "amount_usd": amountUsd,
          "crypto_symbol": cryptoSymbol,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return PrepaidCard.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Order error: $e");
      return null;
    }
  }
  
  Future<PrepaidCard?> getOrderStatus(String orderId) async {
    try {
      final response = await _client.get(
        Uri.parse("$baseUrl/api/wallet/prepaid-card/order/$orderId"),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return PrepaidCard.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Order status error: $e");
      return null;
    }
  }

  // ==================== MESSAGING ====================
  
  Future<Map<String, String>> generateKeyPair() async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/messaging/keys/generate"),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print("KeyGen error: $e");
      return {};
    }
  }
  
  Future<String> encryptMessage(String plaintext, String publicKey) async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/messaging/keys/encrypt"),
        headers: _headers,
        body: jsonEncode({
          "plaintext": plaintext,
          "public_key": publicKey,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ciphertext'] ?? '';
      }
      return '';
    } catch (e) {
      print("Encrypt error: $e");
      return '';
    }
  }
  
  Future<String> decryptMessage(String ciphertext, String privateKey) async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/messaging/keys/decrypt"),
        headers: _headers,
        body: jsonEncode({
          "ciphertext": ciphertext,
          "private_key": privateKey,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['plaintext'] ?? '';
      }
      return '';
    } catch (e) {
      print("Decrypt error: $e");
      return '';
    }
  }
  
  Future<ChatRoom?> createRoom(String name) async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/messaging/rooms"),
        headers: _headers,
        body: jsonEncode({"name": name}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return ChatRoom.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Create room error: $e");
      return null;
    }
  }
  
  Future<List<ChatRoom>> getRooms() async {
    try {
      final response = await _client.get(
        Uri.parse("$baseUrl/messaging/rooms"),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((r) => ChatRoom.fromJson(r)).toList();
      }
      return [];
    } catch (e) {
      print("Get rooms error: $e");
      return [];
    }
  }
  
  Future<List<ChatMessage>> getMessages(String roomId) async {
    try {
      final response = await _client.get(
        Uri.parse("$baseUrl/messaging/rooms/$roomId/messages"),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((m) => ChatMessage.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      print("Get messages error: $e");
      return [];
    }
  }
  
  Future<ChatMessage?> sendMessage(String roomId, String content, String senderId) async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/messaging/rooms/$roomId/messages"),
        headers: _headers,
        body: jsonEncode({
          "content": content,
          "sender_id": senderId,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return ChatMessage.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Send message error: $e");
      return null;
    }
  }

  // ==================== FILE TRANSFER ====================
  
  Future<String> generateCodephrase() async {
    try {
      final response = await _client.get(
        Uri.parse("$baseUrl/filetransfer/codephrase"),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['codephrase'] ?? '';
      }
      return '';
    } catch (e) {
      print("Codephrase error: $e");
      return '';
    }
  }
  
  Future<FileTransfer?> sendFile(String filePath) async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/filetransfer/send"),
        headers: _headers,
        body: jsonEncode({"file_path": filePath}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return FileTransfer.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Send file error: $e");
      return null;
    }
  }
  
  Future<FileTransfer?> receiveFile(String codephrase) async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/filetransfer/receive"),
        headers: _headers,
        body: jsonEncode({"codephrase": codephrase}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return FileTransfer.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Receive file error: $e");
      return null;
    }
  }
  
  Future<FileTransfer?> getTransferStatus(String transferId) async {
    try {
      final response = await _client.get(
        Uri.parse("$baseUrl/filetransfer/status/$transferId"),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return FileTransfer.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Transfer status error: $e");
      return null;
    }
  }

  // ==================== SYSTEM ====================
  
  Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final response = await _client.get(
        Uri.parse("$baseUrl/status"),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print("Status error: $e");
      return {};
    }
  }
}
