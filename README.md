# AnonSuperApp 🛡️

**Super-App occidentale 100% anonyme** — Une alternative occidentale aux super-apps chinoises (WeChat, Alipay), built with privacy-first architecture.

## Fonctionnalités

| Module | Description | Technologies |
|--------|-------------|--------------|
| **Messagerie P2P** | Chat chiffré de bout en bout, peer discovery via Tor | Berty Protocol, libp2p, Tor, WebRTC |
| **Portefeuille Crypto** | Portefeuille multi-devises + Cartes prépayées Zero-KYC | XMR, BTC, LTC, CakePay/Moon/Trocador API |
| **Transfert de Fichiers** | Envoi/réception P2P sécurisé par mot de passe éphémère | croc (PAKE, Curve25519, AES-256) |
| **Recherche Web** | Moteur méta-recherche anonyme via Tor | SearXNG + DuckDuckGo + Wikipedia |

## Installation

```bash
git clone https://github.com/ia2213/anon-superapp.git
cd anon-superapp
pip install -r requirements.txt

# Optionnel: Lancer les services Docker (Tor, SearXNG, croc relay)
docker compose up -d
```

## Lancement

```bash
# API Server
python3 -m core.app

# Ou avec uvicorn directement
uvicorn core.app:app --host 0.0.0.0 --port 8000 --reload
```

## API Endpoints

### Recherche Anonyme
- `POST /search` — Rechercher via SearXNG/Tor
- `GET /search/engines` — Liste des moteurs disponibles
- `GET /search/health` — État des services

### Messagerie P2P
- `POST /messaging/keys/generate` — Générer paire de clés Curve25519
- `POST /messaging/keys/encrypt` — Chiffrer un message (AES-256-GCM)
- `POST /messaging/keys/déchiffrer` — Déchiffrer un message
- `GET /messaging/rooms` — Lister les salons
- `POST /messaging/rooms` — Créer un salon
- `GET /messaging/peers/discover` — Découvrir les pairs via Tor
- `WS /messaging/ws/rooms/{{room_id}}` — WebSocket pour chat en temps réel

### Transfert de Fichiers
- `GET /filetransfer/codephrase` — Générer une phrase-code secrète
- `POST /filetransfer/send` — Initier un transfert
- `POST /filetransfer/receive` — Réceptionner un fichier
- `GET /filetransfer/status` — Statut des transferts

### Portefeuille & Cartes
- `GET /wallet/rates` — Taux crypto en temps réel (CoinGecko)
- `POST /wallet/prepaid-card/quote` — Devis carte prépayée
- `POST /wallet/prepaid-card/order` — Commander une carte virtuelle
- `GET /wallet/prepaid-card/order/{{order_id}}` — Statut de la commande

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AnonSuperApp Core                        │
├─────────────┬─────────────┬──────────────┬─────────────────┤
│  Messaging  │   Wallet    │ FileTransfer │     Search      │
│  (Berty)    │  (Cake)     │    (croc)    │   (SearXNG)     │
├─────────────┴─────────────┴──────────────┴─────────────────┤
│                    Tor SOCKS5 Proxy                         │
│                    (Always-On, No Clearnet)                 │
└─────────────────────────────────────────────────────────────┘
```

## Tests

```bash
pytest -v
# 44 tests - tous passent
```

## Tech Stack

- **Backend**: Python 3.14, FastAPI, uvicorn
- **Crypto**: cryptography (Curve25519, AES-256-GCM)
- **Messaging**: WebSockets, libp2p concepts
- **Search**: SearXNG, BeautifulSoup, requests
- **Wallet**: CoinGecko API, QR code generation

## License

MIT — Pour une internet libre et anonyme.
