import uuid
import time
from typing import Dict, Any

class LowKYCPrepaidCardService:
    """Service d'émission de cartes virtuelles prépayées avec un minimum/aucun KYC."""
    
    SUPPORTED_PROVIDERS = ["CakePay", "Moon", "Trocador"]

    def __init__(self, provider: str = "CakePay"):
        if provider not in self.SUPPORTED_PROVIDERS:
            raise ValueError(f"Provider {provider} non supporté. Choisir parmi {self.SUPPORTED_PROVIDERS}")
        self.provider = provider

    def quote_card(self, amount_usd: float, crypto_symbol: str = "XMR") -> Dict[str, Any]:
        """Obtenir un devis pour l'achat d'une carte prépayée en Crypto sans KYC."""
        rates = {"XMR": 0.0065, "BTC": 0.000015, "LTC": 0.012} # Exemple de taux de conversion
        crypto_amount = amount_usd * rates.get(crypto_symbol, 0.0065)
        fee_usd = amount_usd * 0.02 # 2% d'anonymisation / de frais de traitement
        
        return {
            "provider": self.provider,
            "card_amount_usd": amount_usd,
            "crypto_symbol": crypto_symbol,
            "crypto_amount_due": round(crypto_amount, 6),
            "fee_usd": round(fee_usd, 2),
            "total_usd": round(amount_usd + fee_usd, 2),
            "kyc_required": False,
            "expires_in_minutes": 15
        }

    def create_prepaid_card_order(self, amount_usd: float, crypto_symbol: str = "XMR", email_optional: str | None = None) -> Dict[str, Any]:
        """Créer une commande de carte virtuelle prépayée sans KYC."""
        quote = self.quote_card(amount_usd, crypto_symbol)
        order_id = f"ORD-{uuid.uuid4().hex[:10].upper()}"
        payment_address = f"monero:888tXmo1234567890abcdef{uuid.uuid4().hex[:16]}" if crypto_symbol == "XMR" else f"bc1q{uuid.uuid4().hex[:20]}"
        
        return {
            "order_id": order_id,
            "status": "pending_payment",
            "provider": self.provider,
            "deposit_address": payment_address,
            "crypto_symbol": crypto_symbol,
            "crypto_amount_due": quote["crypto_amount_due"],
            "card_amount_usd": amount_usd,
            "kyc_level": "ZERO_KYC",
            "created_at": int(time.time()),
            "instructions": f"Envoyez {quote['crypto_amount_due']} {crypto_symbol} à l'adresse ci-dessus pour recevoir instantanément votre carte Visa/Mastercard virtuelle."
        }
