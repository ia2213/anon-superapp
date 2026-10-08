import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Service for AnonSuperApp Backend
class ApiService {
  static const String baseUrl = "http://localhost:8000";
  
  final http.Client _client = http.Client();
  
  // Search endpoints
  Future<Map<String, dynamic>> search(String query) async {
    final response = await _client.post(
      Uri.parse("$baseUrl/search"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "query": query,
        "language": "fr",
        "max_results": 10,
      }),
    );
    return jsonDecode(response.body);
  }
  
  // Wallet endpoints
  Future<Map<String, dynamic>> getRates() async {
    final response = await _client.get(Uri.parse("$baseUrl/api/wallet/rates"));
    return jsonDecode(response.body);
  }
  
  Future<Map<String, dynamic>> createPrepaidCardOrder(
    double amountUsd,
    String cryptoSymbol,
  ) async {
    final response = await _client.post(
      Uri.parse("$baseUrl/api/wallet/prepaid-card/order"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "amount_usd": amountUsd,
        "crypto_symbol": cryptoSymbol,
      }),
    );
    return jsonDecode(response.body);
  }
  
  Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    final response = await _client.get(
      Uri.parse("$baseUrl/api/wallet/prepaid-card/order/$orderId"),
    );
    return jsonDecode(response.body);
  }
  
  // Messaging endpoints
  Future<Map<String, dynamic>> generateKeys() async {
    final response = await _client.post(
      Uri.parse("$baseUrl/messaging/keys/generate"),
    );
    return jsonDecode(response.body);
  }
  
  Future<Map<String, dynamic>> createRoom(String name) async {
    final response = await _client.post(
      Uri.parse("$baseUrl/messaging/rooms"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name}),
    );
    return jsonDecode(response.body);
  }
  
  // File transfer endpoints
  Future<String> generateCodephrase() async {
    final response = await _client.get(Uri.parse("$baseUrl/filetransfer/codephrase"));
    final data = jsonDecode(response.body);
    return data["codephrase"];
  }
  
  Future<Map<String, dynamic>> sendFile(String filePath) async {
    final response = await _client.post(
      Uri.parse("$baseUrl/filetransfer/send"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"file_path": filePath}),
    );
    return jsonDecode(response.body);
  }
  
  Future<Map<String, dynamic>> getTransferStatus(String transferId) async {
    final response = await _client.get(
      Uri.parse("$baseUrl/filetransfer/status/$transferId"),
    );
    return jsonDecode(response.body);
  }
}
