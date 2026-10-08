# SuperApp Anonyme - Spécification Architecture

## 1. Vision Globale
Création d'une Super-App occidentale 100% axée sur la confidentialité et l'anonymat absolu, fusionnant 4 piliers technologiques open-source majeurs :
- **Berty Protocol** (Messagerie P2P chiffrée, WebRTC + routage Tor systématique).
- **Cake Wallet Core** (Portefeuille Crypto multi-devises + API Cartes Prépayées sans KYC).
- **croc Engine** (Transfert de fichiers P2P chiffré de bout en bout par clé temporaire).
- **SearXNG** (Moteur de recherche méta-anonyme via proxy Tor).

---

## 2. Piliers & Modifications Spécifiques

### A. Messagerie P2P (Berty + Tor + WebRTC)
- **Base** : Protocole Berty (libp2p, OrbitDB, chiffrement Berty Protocol Engine).
- **Modifications** :
  - Routage **Tor obligatoire (Always-On)** : Interdiction de toutes connexions directes hors réseau Tor.
  - Integration **WebRTC DataChannels** via proxys SOCKS5 Tor pour masquage IP complet.
  - Anonymisation totale du trafic réseau (aucun leak d'adresse IP publique).

### B. Portefeuille & Finance (Cake Wallet + Cartes Prépayées Low-KYC)
- **Base** : Engine Cake Wallet (XMR / BTC / LTC / Haven).
- **Modifications** :
  - Intégration d'API de cartes virtuelles prépayées (CakePay, Moon, Trocador) sans vérification d'identité (Low/No-KYC).
  - Échange direct Crypto (ex: Monero XMR) -> Carte prépayée Visa/Mastercard en 1-click.

### C. Transfert de Fichiers (croc Engine)
- **Base** : Engine `croc` (PAKE / Curve25519 / chiffrement AES-256).
- **Modifications** :
  - Client embedded avec relais routé à travers le réseau Tor.
  - Envoi et réception de fichiers volumineux sécurisés par mots de passe éphémères.

### D. Moteur de Recherche Anonyme (SearXNG)
- **Base** : SearXNG Meta-Search Engine.
- **Modifications** :
  - Proxy local/embedded exécutant SearXNG via Tor circuits indépendants.
  - Suppression totale des logs, cookies, scripts de suivi et identifiants navigateurs.

---

## 3. Structure du Répertoire
```
anon-superapp/
├── ARCHITECTURE.md         # Spécification d'architecture
├── docker-compose.yml       # Déploiement local SearXNG + Tor Relay + croc relay
├── messaging/              # Module Berty + Tor WebRTC Engine
├── wallet/                 # Module Cake Wallet + Prepaid Card API
├── filetransfer/           # Module croc P2P Transfer Engine
├── search/                 # Client & Proxy SearXNG
└── core/                   # SDK / Interface d'intégration unifiée
```
