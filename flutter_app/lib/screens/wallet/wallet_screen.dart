import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../models/crypto_rate.dart';
import '../../models/prepaid_card.dart';

final ratesProvider = FutureProvider<Map<String, CryptoRate>>((ref) async {
  final api = ApiService();
  return api.getCryptoRates();
});

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCrypto = 'XMR';
  double _cardAmount = 100;
  PrepaidCard? _currentOrder;
  bool _isLoadingCard = false;

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

  Future<void> _orderCard() async {
    setState(() => _isLoadingCard = true);
    final api = ApiService();
    final order = await api.createCardOrder(_cardAmount, _selectedCrypto);
    setState(() {
      _currentOrder = order;
      _isLoadingCard = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💳 Portefeuille & Cartes Zero-KYC'),
        backgroundColor: const Color(0xFF1A1A2E),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00D4AA),
          labelColor: const Color(0xFF00D4AA),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Crypto Live', icon: Icon(Icons.currency_bitcoin)),
            Tab(text: 'Cartes Virtuelles', icon: Icon(Icons.credit_card)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCryptoTab(),
          _buildCardsTab(),
        ],
      ),
    );
  }

  Widget _buildCryptoTab() {
    final ratesAsync = ref.watch(ratesProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ratesProvider);
      },
      color: const Color(0xFF00D4AA),
      child: ratesAsync.when(
        data: (rates) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cours en direct (CoinGecko)',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '100% Anonyme & Live',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Actifs Numériques',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rates.entries.map((entry) {
              final rate = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1A1A2E),
                    child: Text(rate.symbol, style: const TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold)),
                  ),
                  title: Text(rate.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('1 ${rate.symbol} = \$${rate.usd.toStringAsFixed(2)} USD'),
                  trailing: Text(
                    '${rate.change24h >= 0 ? "+" : ""}${rate.change24h.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: rate.change24h >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00D4AA))),
        error: (e, _) => Center(child: Text('Erreur de chargement: $e')),
      ),
    );
  }

  Widget _buildCardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield, color: Color(0xFF00D4AA)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cartes prépayées virtuelles avec le moins de KYC possible (Zero-KYC / CakePay).',
                    style: TextStyle(color: Color(0xFF00D4AA)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Sélectionnez la cryptomonnaie de paiement:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: ['XMR', 'BTC', 'LTC'].map((crypto) {
              bool isSelected = _selectedCrypto == crypto;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? const Color(0xFF00D4AA) : const Color(0xFF1A1A2E),
                      foregroundColor: isSelected ? Colors.black : Colors.white,
                    ),
                    onPressed: () => setState(() => _selectedCrypto = crypto),
                    child: Text(crypto, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Montant de la carte (\$): \$${_cardAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _cardAmount,
            min: 20,
            max: 500,
            divisions: 48,
            activeColor: const Color(0xFF00D4AA),
            label: '\$${_cardAmount.toInt()}',
            onChanged: (val) => setState(() => _cardAmount = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.add_card),
              label: _isLoadingCard 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('Générer la commande de carte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: _isLoadingCard ? null : _orderCard,
            ),
          ),
          if (_currentOrder != null) ...[
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFF1A1A2E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📦 Commande générée avec succès !', style: TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    Text('ID: ${_currentOrder!.orderId}'),
                    const SizedBox(height: 8),
                    Text('Montant dû: ${_currentOrder!.cryptoAmountDue.toString(precision: 4)} ${_currentOrder!.cryptoSymbol}'),
                    const SizedBox(height: 8),
                    const Text('Adresse de dépôt :'),
                    SelectableText(_currentOrder!.depositAddress, style: const TextStyle(color: Color(0xFF00D4AA), fontFamily: 'monospace')),
                    const SizedBox(height: 8),
                    Text('Statut: ${_currentOrder!.status}'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
