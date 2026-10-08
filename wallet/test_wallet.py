import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient

from wallet.api import app, wallet_service
from wallet.prepaid_cards import LowKYCPrepaidCardService, DEFAULT_RATES_USD

client = TestClient(app)

# Reset wallet_service orders before each test if needed
@pytest.fixture(autouse=True)
def clear_orders():
    wallet_service.orders.clear()
    yield
    wallet_service.orders.clear()


# --- Unit tests for LowKYCPrepaidCardService ---

def test_service_init():
    service = LowKYCPrepaidCardService(provider="Moon")
    assert service.provider == "Moon"
    
    with pytest.raises(ValueError):
        LowKYCPrepaidCardService(provider="InvalidProvider")

def test_service_fetch_live_rates():
    service = LowKYCPrepaidCardService()
    rates_info = service.fetch_live_rates()
    assert "rates" in rates_info
    assert "source" in rates_info
    assert rates_info["source"] in ["coingecko", "fallback"]
    for crypto in ["XMR", "BTC", "LTC"]:
        assert crypto in rates_info["rates"]
        assert rates_info["rates"][crypto] > 0

def test_service_fetch_live_rates_fallback():
    service = LowKYCPrepaidCardService()
    with patch("httpx.Client.get", side_effect=Exception("Network error")):
        rates_info = service.fetch_live_rates()
        assert rates_info["source"] == "fallback"
        assert rates_info["rates"]["XMR"] == DEFAULT_RATES_USD["XMR"]
        assert rates_info["rates"]["BTC"] == DEFAULT_RATES_USD["BTC"]
        assert rates_info["rates"]["LTC"] == DEFAULT_RATES_USD["LTC"]

def test_service_quote_card():
    service = LowKYCPrepaidCardService(provider="CakePay")
    quote = service.quote_card(amount_usd=100.0, crypto_symbol="XMR")
    
    assert quote["provider"] == "CakePay"
    assert quote["card_amount_usd"] == 100.0
    assert quote["crypto_symbol"] == "XMR"
    assert quote["fee_usd"] == 2.0  # 2% of 100
    assert quote["total_usd"] == 102.0
    assert quote["kyc_required"] is False
    assert quote["crypto_amount_due"] > 0

def test_service_quote_card_invalid_inputs():
    service = LowKYCPrepaidCardService()
    with pytest.raises(ValueError):
        service.quote_card(amount_usd=-50.0, crypto_symbol="XMR")
    with pytest.raises(ValueError):
        service.quote_card(amount_usd=50.0, crypto_symbol="ETH")

def test_service_create_order_and_get():
    service = LowKYCPrepaidCardService(provider="Trocador")
    order = service.create_prepaid_card_order(amount_usd=75.0, crypto_symbol="BTC", email_optional="anon@example.com")
    
    assert order["order_id"].startswith("ORD-")
    assert order["status"] == "pending_payment"
    assert order["provider"] == "Trocador"
    assert order["deposit_address"].startswith("bc1q")
    assert "bitcoin:bc1q" in order["qr_code_text"]
    assert order["crypto_symbol"] == "BTC"
    assert order["kyc_level"] == "ZERO_KYC"
    assert order["email_optional"] == "anon@example.com"
    assert order["card_details"]["card_status"] == "pending_activation"

    retrieved = service.get_order(order["order_id"])
    assert retrieved == order


# --- API Endpoint tests ---

def test_api_get_rates():
    response = client.get("/api/wallet/rates")
    assert response.status_code == 200
    data = response.json()
    assert "rates" in data
    assert "simple_rates" in data
    assert "source" in data
    assert "timestamp" in data
    assert "XMR" in data["rates"]
    assert data["rates"]["XMR"]["usd"] > 0
    assert "BTC" in data["rates"]
    assert "LTC" in data["rates"]

def test_api_prepaid_card_quote_success():
    response = client.post("/api/wallet/prepaid-card/quote", json={
        "amount_usd": 50.0,
        "crypto_symbol": "XMR",
        "provider": "CakePay"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["provider"] == "CakePay"
    assert data["card_amount_usd"] == 50.0
    assert data["crypto_symbol"] == "XMR"
    assert data["fee_usd"] == 1.0  # max(50*0.02, 1.0) = 1.0
    assert data["total_usd"] == 51.0
    assert data["kyc_required"] is False

def test_api_prepaid_card_quote_invalid_crypto():
    response = client.post("/api/wallet/prepaid-card/quote", json={
        "amount_usd": 50.0,
        "crypto_symbol": "DOGE",
        "provider": "CakePay"
    })
    assert response.status_code == 400
    assert "Crypto non supportée" in response.json()["detail"]

def test_api_prepaid_card_quote_invalid_amount():
    response = client.post("/api/wallet/prepaid-card/quote", json={
        "amount_usd": -10.0,
        "crypto_symbol": "XMR",
        "provider": "CakePay"
    })
    assert response.status_code == 422  # Pydantic validation error gt=0

def test_api_prepaid_card_order_creation_and_retrieval():
    # 1. Create order
    order_req = {
        "amount_usd": 100.0,
        "crypto_symbol": "XMR",
        "provider": "Moon",
        "email_optional": "user@anon.org"
    }
    create_resp = client.post("/api/wallet/prepaid-card/order", json=order_req)
    assert create_resp.status_code == 200
    order_data = create_resp.json()
    order_id = order_data["order_id"]
    
    assert order_id.startswith("ORD-")
    assert order_data["status"] == "pending_payment"
    assert order_data["provider"] == "Moon"
    assert order_data["deposit_address"].startswith("888tXmo")
    assert order_data["qr_code_text"].startswith("monero:888tXmo")
    assert "amount=" in order_data["qr_code_text"]
    assert order_data["kyc_level"] == "ZERO_KYC"
    assert order_data["card_details"]["card_number"].startswith("4111****")

    # 2. Get order status
    get_resp = client.get(f"/api/wallet/prepaid-card/order/{order_id}")
    assert get_resp.status_code == 200
    retrieved_data = get_resp.json()
    assert retrieved_data["order_id"] == order_id
    assert retrieved_data["status"] == "pending_payment"
    assert retrieved_data["card_details"]["balance_usd"] == 100.0

def test_api_get_order_not_found():
    response = client.get("/api/wallet/prepaid-card/order/ORD-NONEXISTENT")
    assert response.status_code == 404
    assert "non trouvée" in response.json()["detail"]
