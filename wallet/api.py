import time
from typing import Dict, Any, Optional
from fastapi import FastAPI, APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from wallet.prepaid_cards import LowKYCPrepaidCardService, SUPPORTED_CRYPTOS, SUPPORTED_PROVIDERS

router = APIRouter(prefix="/api/wallet", tags=["Crypto Wallet & Low-KYC Prepaid Cards"])

# Global service instance
wallet_service = LowKYCPrepaidCardService()

# --- Pydantic Schemas ---

class RateDetail(BaseModel):
    usd: float

class RatesResponse(BaseModel):
    rates: Dict[str, RateDetail]
    simple_rates: Dict[str, float]
    source: str
    timestamp: int

class PrepaidCardQuoteRequest(BaseModel):
    amount_usd: float = Field(..., gt=0, description="Montant de la carte en USD (doit être > 0)")
    crypto_symbol: str = Field("XMR", description="Symbole de la crypto-monnaie (XMR, BTC, LTC)")
    provider: str = Field("CakePay", description="Fournisseur de carte prépayée (CakePay, Moon, Trocador)")

class PrepaidCardQuoteResponse(BaseModel):
    provider: str
    card_amount_usd: float
    crypto_symbol: str
    crypto_rate_usd: float
    crypto_amount_due: float
    fee_usd: float
    total_usd: float
    kyc_required: bool = False
    expires_in_minutes: int = 15
    rate_source: str

class PrepaidCardOrderRequest(BaseModel):
    amount_usd: float = Field(..., gt=0, description="Montant de la carte en USD (doit être > 0)")
    crypto_symbol: str = Field("XMR", description="Symbole crypto (XMR, BTC, LTC)")
    provider: str = Field("CakePay", description="Fournisseur (CakePay, Moon, Trocador)")
    email_optional: Optional[str] = Field(None, description="Email optionnel pour livraison de carte")

class CardDetails(BaseModel):
    card_type: str
    card_number: str
    expiration_date: str
    cvv: str
    card_status: str
    balance_usd: float

class PrepaidCardOrderResponse(BaseModel):
    order_id: str
    status: str
    provider: str
    deposit_address: str
    qr_code_text: str
    crypto_symbol: str
    crypto_amount_due: float
    card_amount_usd: float
    fee_usd: float
    total_usd: float
    email_optional: Optional[str] = None
    kyc_level: str = "ZERO_KYC"
    created_at: int
    expires_at: int
    instructions: str
    card_details: Optional[CardDetails] = None

# --- API Endpoints ---

@router.get("/rates", response_model=RatesResponse)
def get_crypto_rates():
    """Obtenir les taux de change crypto en direct (XMR, BTC, LTC) via CoinGecko avec fallback."""
    rates_info = wallet_service.fetch_live_rates()
    rates_map = rates_info["rates"]
    
    formatted_rates = {
        symbol: RateDetail(usd=float(price))
        for symbol, price in rates_map.items()
    }
    simple_rates = {
        symbol: float(price)
        for symbol, price in rates_map.items()
    }
    
    return RatesResponse(
        rates=formatted_rates,
        simple_rates=simple_rates,
        source=rates_info["source"],
        timestamp=rates_info.get("timestamp", int(time.time()))
    )

@router.post("/prepaid-card/quote", response_model=PrepaidCardQuoteResponse)
def calculate_prepaid_card_quote(request: PrepaidCardQuoteRequest):
    """Calculer le prix d'une carte prépayée avec frais zero-KYC."""
    symbol = request.crypto_symbol.upper()
    if symbol not in SUPPORTED_CRYPTOS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Crypto non supportée '{request.crypto_symbol}'. Choisir parmi {SUPPORTED_CRYPTOS}"
        )
    if request.provider not in SUPPORTED_PROVIDERS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Fournisseur non supporté '{request.provider}'. Choisir parmi {SUPPORTED_PROVIDERS}"
        )
    if request.amount_usd <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le montant USD doit être supérieur à 0."
        )

    try:
        service = LowKYCPrepaidCardService(provider=request.provider)
        quote = service.quote_card(amount_usd=request.amount_usd, crypto_symbol=symbol)
        return PrepaidCardQuoteResponse(**quote)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/prepaid-card/order", response_model=PrepaidCardOrderResponse)
def create_prepaid_card_order(request: PrepaidCardOrderRequest):
    """Créer une commande de carte virtuelle avec adresse de dépôt et texte QR code."""
    symbol = request.crypto_symbol.upper()
    if symbol not in SUPPORTED_CRYPTOS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Crypto non supportée '{request.crypto_symbol}'. Choisir parmi {SUPPORTED_CRYPTOS}"
        )
    if request.provider not in SUPPORTED_PROVIDERS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Fournisseur non supporté '{request.provider}'. Choisir parmi {SUPPORTED_PROVIDERS}"
        )
    if request.amount_usd <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le montant USD doit être supérieur à 0."
        )

    try:
        service = LowKYCPrepaidCardService(provider=request.provider)
        order = service.create_prepaid_card_order(
            amount_usd=request.amount_usd,
            crypto_symbol=symbol,
            email_optional=request.email_optional
        )
        # Store in global service for retrieval
        wallet_service.orders[order["order_id"]] = order
        return PrepaidCardOrderResponse(**order)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.get("/prepaid-card/order/{order_id}", response_model=PrepaidCardOrderResponse)
def get_prepaid_card_order_status(order_id: str):
    """Consulter le statut d'une commande et les détails de la carte."""
    order = wallet_service.get_order(order_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Commande '{order_id}' non trouvée."
        )
    return PrepaidCardOrderResponse(**order)

app = FastAPI(
    title="Crypto Wallet & Low-KYC Prepaid Card API",
    version="1.0.0",
    description="API pour consultation des taux crypto et émission de cartes prépayées virtuelles low-KYC."
)

app.include_router(router)
