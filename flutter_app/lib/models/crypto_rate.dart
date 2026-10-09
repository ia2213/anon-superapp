class CryptoRate {
  final String symbol;
  final String name;
  final double usd;
  final double change24h;

  CryptoRate({
    required this.symbol,
    required this.name,
    required this.usd,
    required this.change24h,
  });

  factory CryptoRate.fromJson(String symbol, Map<String, dynamic> json) {
    return CryptoRate(
      symbol: symbol.toUpperCase(),
      name: json['name'] ?? symbol,
      usd: (json['usd'] ?? 0).toDouble(),
      change24h: (json['usd_24h_change'] ?? 0).toDouble(),
    );
  }
}
