#!/usr/bin/env python3
import sys
import os
import argparse
import json

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from search.client import AnonymousSearchClient
from wallet.prepaid_cards import LowKYCPrepaidCardService
from filetransfer.croc_client import CrocTransferClient
from messaging.tor_webrtc import BertyTorWebRTCNode

def main():
    parser = argparse.ArgumentParser(description="Super-App Anonyme - CLI & Core Unified Hub")
    subparsers = parser.add_subparsers(dest="command", help="Module à exécuter")

    # Status
    subparsers.add_parser("status", help="Afficher l'état des modules")

    # Wallet (Cartes Prépayées)
    wallet_parser = subparsers.add_parser("wallet", help="Portefeuille & Cartes Prépayées sans KYC")
    wallet_parser.add_argument("--usd", type=float, default=50.0, help="Montant en USD pour la carte prépayée")
    wallet_parser.add_argument("--crypto", type=str, default="XMR", help="Symbole Crypto (XMR, BTC, LTC)")
    wallet_parser.add_argument("--provider", type=str, default="CakePay", help="Fournisseur (CakePay, Moon, Trocador)")

    # Search
    search_parser = subparsers.add_parser("search", help="Recherche Web Anonyme SearXNG")
    search_parser.add_argument("query", type=str, help="Terme de recherche")

    # File transfer
    transfer_parser = subparsers.add_parser("transfer", help="Transfert P2P croc")
    transfer_parser.add_argument("path", type=str, help="Chemin du fichier à envoyer")
    transfer_parser.add_argument("--code", type=str, default=None, help="Code phrase secret")

    # Messaging
    msg_parser = subparsers.add_parser("messaging", help="Configuration Berty + Tor WebRTC")

    args = parser.parse_args()

    if args.command == "status" or not args.command:
        from core.app import AnonymousSuperAppEngine
        engine = AnonymousSuperAppEngine()
        print(json.dumps(engine.get_system_status(), indent=2, ensure_ascii=False))

    elif args.command == "wallet":
        service = LowKYCPrepaidCardService(provider=args.provider)
        order = service.create_prepaid_card_order(amount_usd=args.usd, crypto_symbol=args.crypto)
        print(json.dumps(order, indent=2, ensure_ascii=False))

    elif args.command == "search":
        client = AnonymousSearchClient(tor_proxy=None) # direct local probe
        results = client.search(args.query)
        print(json.dumps(results, indent=2, ensure_ascii=False))

    elif args.command == "transfer":
        client = CrocTransferClient()
        print(json.dumps(client.send_file(args.path, args.code), indent=2, ensure_ascii=False))

    elif args.command == "messaging":
        node = BertyTorWebRTCNode()
        print(json.dumps(node.get_berty_config(), indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()
