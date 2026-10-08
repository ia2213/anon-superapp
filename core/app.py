import sys
import json
from typing import Dict, Any
from fastapi import FastAPI

from search.client import AnonymousSearchClient
from wallet.prepaid_cards import LowKYCPrepaidCardService
from filetransfer.croc_client import CrocTransferClient
from messaging.tor_webrtc import BertyTorWebRTCNode

from messaging.api import router as messaging_router
from filetransfer.api import router as filetransfer_router
from search.api import router as search_router
from wallet.api import router as wallet_router

class AnonymousSuperAppEngine:
    """Moteur central d'intégration de la Super-App Anonyme."""
    
    def __init__(self):
        self.search = AnonymousSearchClient()
        self.wallet = LowKYCPrepaidCardService()
        self.file_transfer = CrocTransferClient()
        self.messaging = BertyTorWebRTCNode()

    def get_system_status(self) -> Dict[str, Any]:
        return {
            "app_name": "AnonSuperApp Unified Core",
            "version": "1.0.0",
            "modules": {
                "messaging_p2p": {
                    "protocol": "berty_p2p_v1",
                    "tor": "always_on",
                    "webrtc": True,
                    "privacy": self.messaging.get_berty_config()["node"]["privacy"]
                },
                "wallet_cards": {
                    "providers": self.wallet.SUPPORTED_PROVIDERS,
                    "kyc_level": "ZERO_KYC"
                },
                "file_transfer": {
                    "engine": "croc",
                    "relay": self.file_transfer.relay_address,
                    "tor_proxied": True
                },
                "search": {
                    "engine": "searxng",
                    "proxy": self.search.proxies,
                    "fallbacks": ["duckduckgo", "wikipedia"]
                }
            }
        }

engine = AnonymousSuperAppEngine()

app = FastAPI(
    title="AnonSuperApp Unified Core API",
    version="1.0.0",
    description="Anonymous Super-App: Messaging (Berty/Tor/WebRTC), Wallet (Crypto/Low-KYC Cards), File Transfer (croc/Tor), Search (SearXNG/Tor)"
)

app.include_router(search_router)
app.include_router(messaging_router)
app.include_router(filetransfer_router)
app.include_router(wallet_router)

@app.get("/")
def root():
    return {"app": "AnonSuperApp", "version": "1.0.0", "status": "running"}

@app.get("/status")
def system_status():
    return engine.get_system_status()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
