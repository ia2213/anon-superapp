import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildBalanceCard(),
          _buildPaymentMethods(),
          _buildTransactions(),
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
          hintText: 'Rechercher un contact ou un QR...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00D4AA)),
          suffixIcon: const Icon(Icons.qr_code, color: Color(0xFF00D4AA)),
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

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Solde Totale', style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 8),
          Text('0.00 EUR', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('100% Anonyme & Zero-KYC', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Méthodes de paiement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 12),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListTile(
            leading: const Icon(Icons.credit_card, color: Color(0xFF00D4AA)),
            title: const Text('Carte Virtuelle 4242', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Zero-KYC • CVV: **', style: TextStyle(color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF00D4AA)),
            title: const Text('Portefeuille', style: TextStyle(color: Colors.white)),
            subtitle: const Text('XMR + BTC + LTC', style: TextStyle(color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Transactions récentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 12),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildTransactionItem('Carte 4242', 'Encaissement', '100 EUR', const Color(0xFF00D4AA)),
              _buildTransactionItem('Carte 4242', 'Paiement', '12 EUR', Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount, Color color) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.currency_bitcoin, color: Color(0xFF00D4AA)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white)),
                    Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    amount.startsWith('-') ? '−' : '+',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
