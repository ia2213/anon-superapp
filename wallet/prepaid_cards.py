import uuid
import time
from typing import Dict, Any, Optional, List
import httpx

# Default fallback rates (USD per 1 coin)
DEFAULT_RATES_USD = {
    "XMR": 160.0,
    "BTC": 65000.0,
    "LTC": 85.0
}

SUPPORTED_CRYPTOS = ["XMR", "BTC", "LTC"]
SUPPORTED_PROVIDERS = ["CakePay", "Moon", "Trocador"]

class LowKYCPrepaidCardService:
    """Service d'émission de cartes virtuelles prépayées avec un minimum/aucun KYC."""
    
    SUPPORTED_PROVIDERS = SUPPORTED_PROVIDERS
    SUPPORTED_CRYPTOS = SUPPORTED_CRYPTOS

    def __init__(self, provider: str = "CakePay"):
        if provider not in self.SUPPORTED_PROVIDERS:
            raise ValueError(f"Provider {provider} non supporté. Choisir parmi {self.SUPPORTED_PROVIDERS}")
        self.provider = provider
        self.orders: Dict[str, Dict[str, Any]] = {}

    def fetch_live_rates(self) -> Dict[str, Any]:
        """Fetch live rates for XMR, BTC, LTC from CoinGecko with fallback."""
        url = "https://api.coingecko.com/api/v3/simple/price?ids=monero,bitcoin,litecoin&vs_currencies=usd"
        try:
            with httpx.Client(timeout=4.0) as client:
                response = client.get(url)
                if response.status_code == 200:
                    data = response.json()
                    rates = {
                        "XMR": data.get("monero", {}).get("usd", DEFAULT_RATES_USD["XMR"]),
                        "BTC": data.get("bitcoin", {}).get("usd", DEFAULT_RATES_USD["BTC"]),
                        "LTC": data.get("litecoin", {}).get("usd", DEFAULT_RATES_USD["LTC"]),
                    }
                    return {
                        "rates": rates,
                        "source": "coingecko",
                        "timestamp": int(time.time())
                    }
        except Exception:
            pass

        # Fallback if API fails or times out
        return {
            "rates": DEFAULT_RATES_USD.copy(),
            "source": "fallback",
            "timestamp": int(time.time())
        }

    def quote_card(self, amount_usd: float, crypto_symbol: str = "XMR") -> Dict[str, Any]:
        """Obtenir un devis pour l'achat d'une carte prépayée en Crypto sans KYC."""
        crypto_symbol = crypto_symbol.upper()
        if crypto_symbol not in self.SUPPORTED_CRYPTOS:
            raise ValueError(f"Crypto {crypto_symbol} non supportée. Choisir parmi {self.SUPPORTED_CRYPTOS}")
        if amount_usd <= 0:
            raise ValueError("Le montant USD doit être supérieur à 0.")

        rates_info = self.fetch_live_rates()
        rate_usd = rates_info["rates"].get(crypto_symbol, DEFAULT_RATES_USD.get(crypto_symbol, 100.0))

        fee_rate = 0.02 # 2% d'anonymisation / frais de traitement
        fee_usd = round(max(amount_usd * fee_rate, 1.0), 2)
        total_usd = round(amount_usd + fee_usd, 2)
        
        crypto_amount = round(total_usd / rate_usd, 6)

        return {
            "provider": self.provider,
            "card_amount_usd": amount_usd,
            "crypto_symbol": crypto_symbol,
            "crypto_rate_usd": rate_usd,
            "crypto_amount_due": crypto_amount,
            "fee_usd": fee_usd,
            "total_usd": total_usd,
            "kyc_required": False,
            "expires_in_minutes": 15,
            "rate_source": rates_info["source"]
        }

    def generate_deposit_address(self, crypto_symbol: str) -> str:
        crypto_symbol = crypto_symbol.upper()
        if crypto_symbol == "XMR":
            return f"888tXmo1234567890abcdef{uuid.uuid4().hex[:16]}"
        elif crypto_symbol == "BTC":
            return f"bc1q{uuid.uuid4().hex[:20]}"
        elif crypto_symbol == "LTC":
            return f"ltc1q{uuid.uuid4().hex[:20]}"
        return f"addr_{uuid.uuid4().hex[:20]}"

    def generate_qr_code_text(self, crypto_symbol: str, address: str, amount: float) -> str:
        crypto_symbol = crypto_symbol.lower()
        if crypto_symbol == "xmr":
            scheme = "monero"
        elif crypto_symbol == "btc":
            scheme = "bitcoin"
        elif crypto_symbol == "ltc":
            scheme = "litecoin"
        else:
            scheme = crypto_symbol
        return f"{scheme}:{address}?amount={amount}"

    def create_prepaid_card_order(self, amount_usd: float, crypto_symbol: str = "XMR", email_optional: Optional[str] = None) -> Dict[str, Any]:
        """Créer une commande de carte virtuelle prépayée sans KYC."""
        quote = self.quote_card(amount_usd, crypto_symbol)
        order_id = f"ORD-{uuid.uuid4().hex[:10].upper()}"
        payment_address = self.generate_deposit_address(quote["crypto_symbol"])
        qr_code_text = self.generate_qr_code_text(quote["crypto_symbol"], payment_address, quote["crypto_amount_due"])
        
        created_at = int(time.time())
        expires_at = created_at + 15 * 60

        card_details = {
            "card_type": "Virtual Visa Prepaid",
            "card_number": f"4111****{uuid.uuid4().hex[:4].upper()}",
            "expiration_date": "12/28",
            "cvv": "***",
            "card_status": "pending_activation",
            "balance_usd": amount_usd
        }

        order = {
            "order_id": order_id,
            "status": "pending_payment",
            "provider": self.provider,
            "deposit_address": payment_address,
            "qr_code_text": qr_code_text,
            "crypto_symbol": quote["crypto_symbol"],
            "crypto_amount_due": quote["crypto_amount_due"],
            "card_amount_usd": amount_usd,
            "fee_usd": quote["fee_usd"],
            "total_usd": quote["total_usd"],
            "email_optional": email_optional,
            "kyc_level": "ZERO_KYC",
            "created_at": created_at,
            "expires_at": expires_at,
            "instructions": f"Envoyez {quote['crypto_amount_due']} {quote['crypto_symbol']} à l'adresse ci-dessus pour recevoir instantanément votre carte Visa/Mastercard virtuelle.",
            "card_details": card_details
        }

        self.orders[order_id] = order
        return order

    def get_order(self, order_id: str) -> Optional[Dict[str, Any]]:
        return self.orders.get(order_id)
