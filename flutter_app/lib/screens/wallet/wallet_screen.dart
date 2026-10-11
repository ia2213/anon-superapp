import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
        title: const Text('💳 Portefeuille'),
        backgroundColor: const Color(0xFF1A1A2E),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00D4AA),
          labelColor: const Color(0xFF00D4AA),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Crypto', icon: Icon(Icons.currency_bitcoin)),
            Tab(text: 'Cartes', icon: Icon(Icons.credit_card)),
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
            // Balance Card
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Balance Totale',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '0.00 EUR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildQuickAction(Icons.add, 'Ajouter'),
                      const SizedBox(width: 12),
                      _buildQuickAction(Icons.send, 'Envoyer'),
                      const SizedBox(width: 12),
                      _buildQuickAction(Icons.qr_code, 'Scanner'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Crypto Rates
            const Text(
              'Taux en Temps Réel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (rates.isEmpty)
              const Center(child: Text('Erreur de chargement des taux'))
            else
              ...rates.values.map((rate) => _buildCryptoCard(rate)),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
        ),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCryptoCard(CryptoRate rate) {
    final isPositive = rate.change24h >= 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getCryptoColor(rate.symbol).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              rate.symbol.substring(0, 1),
              style: TextStyle(
                color: _getCryptoColor(rate.symbol),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        title: Text(rate.name),
        subtitle: Text(rate.symbol),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\${rate.usd.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                Text(
                  '${rate.change24h.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCryptoColor(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'BTC': return Colors.orange;
      case 'XMR': return const Color(0xFFFF6600);
      case 'LTC': return Colors.grey;
      default: return const Color(0xFF00D4AA);
    }
  }

  Widget _buildCardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zero KYC Banner
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
                    'Cartes prépayées Zero-KYC\nAcheter avec crypto, recevoir une carte virtuelle',
                    style: TextStyle(color: Color(0xFF00D4AA)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Amount Selector
          const Text(
            'Montant de la carte',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            children: [25, 50, 100, 200, 500].map((amount) {
              final isSelected = _cardAmount == amount.toDouble();
              return ChoiceChip(
                label: Text('\$$amount'),
                selected: isSelected,
                selectedColor: const Color(0xFF00D4AA),
                onSelected: (selected) {
                  setState(() => _cardAmount = amount.toDouble());
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Crypto Selector
          const Text(
            'Cryptomonnaie de paiement',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: ['XMR', 'BTC', 'LTC'].map((crypto) {
              final isSelected = _selectedCrypto == crypto;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected 
                          ? _getCryptoColor(crypto) 
                          : const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => setState(() => _selectedCrypto = crypto),
                    child: Text(crypto),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Order Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.credit_card),
              label: const Text(
                'Commander ma carte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _createCardOrder,
            ),
          ),
          
          // Current Order
          if (_currentOrder != null) ...[
            const SizedBox(height: 24),
            _buildOrderCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard() {
    return Card(
      color: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Commande en attente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const Divider(),
            Text('Order ID: ${_currentOrder!.orderId}'),
            Text('Montant: \${_currentOrder!.cardAmountUsd}'),
            Text('Cryptomonnaie: ${_currentOrder!.cryptoSymbol}'),
            Text('À payer: ${_currentOrder!.cryptoAmountDue} ${_currentOrder!.cryptoSymbol}'),
            const SizedBox(height: 12),
            
            // QR Code
            Center(
              child: QrImageView(
                data: _currentOrder!.depositAddress,
                version: QrVersions.auto,
                size: 150,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // Copy Address
            Row(
              children: [
                Expanded(
                  child: Text(
                    _currentOrder!.depositAddress,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _currentOrder!.depositAddress));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Adresse copiée!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCardOrder() async {
    setState(() {});
    
    final api = ApiService();
    final order = await api.createCardOrder(_cardAmount, _selectedCrypto);
    
    if (order != null && mounted) {
      setState(() => _currentOrder = order);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la commande')),
      );
    }
  }
}
