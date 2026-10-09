class PrepaidCard {
  final String orderId;
  final String status;
  final String provider;
  final String depositAddress;
  final String cryptoSymbol;
  final double cryptoAmountDue;
  final double cardAmountUsd;
  final String kycLevel;
  final String? cardNumber;
  final String? expiryDate;

  PrepaidCard({
    required this.orderId,
    required this.status,
    required this.provider,
    required this.depositAddress,
    required this.cryptoSymbol,
    required this.cryptoAmountDue,
    required this.cardAmountUsd,
    required this.kycLevel,
    this.cardNumber,
    this.expiryDate,
  });

  factory PrepaidCard.fromJson(Map<String, dynamic> json) {
    return PrepaidCard(
      orderId: json['order_id'] ?? '',
      status: json['status'] ?? 'unknown',
      provider: json['provider'] ?? '',
      depositAddress: json['deposit_address'] ?? '',
      cryptoSymbol: json['crypto_symbol'] ?? 'XMR',
      cryptoAmountDue: (json['crypto_amount_due'] ?? 0).toDouble(),
      cardAmountUsd: (json['card_amount_usd'] ?? 0).toDouble(),
      kycLevel: json['kyc_level'] ?? 'unknown',
      cardNumber: json['card_number'],
      expiryDate: json['expiry_date'],
    );
  }
}
