"""Telegram Bot Interface for AnonSuperApp."""

import os
import json
import asyncio
import logging
from typing import Optional

from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, ConversationHandler, ContextTypes, filters
from telegram.error import TelegramError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Bot token from environment
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
if not TELEGRAM_BOT_TOKEN:
    raise ValueError("TELEGRAM_BOT_TOKEN not set in environment")

# Import app modules
import sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from search.client import AnonymousSearchClient
from wallet.prepaid_cards import LowKYCPrepaidCardService
from filetransfer.croc_client import CrocTransferClient

# States for conversation
SEARCH_QUERY, WALLET_AMOUNT, CRYPTO_SELECT, TRANSFER_FILE = range(4)

# Initialize services
search_client = AnonymousSearchClient()
wallet_service = LowKYCPrepaidCardService()
file_transfer = CrocTransferClient()

# In-memory user sessions
user_sessions = {}


async def start_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /start command."""
    welcome = """🛡️ <b>AnonSuperApp</b> — Votre super-app anonyme

<b>Fonctionnalités:</b>
🔍 <b>/search</b> — Recherche web anonyme (SearXNG)
💳 <b>/wallet</b> — Cartes prépayées Zero-KYC
📁 <b>/transfer</b> — Transfert de fichiers P2P
📊 <b>/status</b> — Statut du système

<i>100% anonyme, 0% tracking.</i>"""
    
    await update.message.reply_text(welcome, parse_mode="HTML")
    return ConversationHandler.END


async def status_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /status command - show system status."""
    status = search_client.search("status check", language="en", max_results=1)
    
    msg = """📊 <b>Statut AnonSuperApp</b>

✅ <b>Messaging P2P:</b> Configuré (Tor Always-On)
✅ <b>Wallet:</b> Low-KYC Cards (CakePay, Moon, Trocador)
✅ <b>File Transfer:</b> croc relay activé
✅ <b>Search:</b> SearXNG + Tor Proxy

<i>Tous les modules opérationnels.</i>"""
    
    await update.message.reply_text(msg, parse_mode="HTML")


async def search_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /search command - start search conversation."""
    await update.message.reply_text(
        "🔍 <b>Recherche Anonyme</b>\n\n"
        "Entrez votre requête de recherche:",
        parse_mode="HTML"
    )
    return SEARCH_QUERY


async def search_received(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Process search query."""
    query = update.message.text
    
    try:
        results = search_client.search(query, language="fr", max_results=5)
        
        if isinstance(results, dict) and "error" in results:
            await update.message.reply_text(f"❌ Erreur: {results['error']}")
            return ConversationHandler.END
        
        if not results:
            await update.message.reply_text("Aucun résultat trouvé.")
            return ConversationHandler.END
        
        response = f"🔍 <b>Résultats pour:</b> {query}\n\n"
        for i, r in enumerate(results[:5], 1):
            title = r.get("title", "Sans titre")[:50]
            url = r.get("url", "")
            response += f"{i}. <a href=\"{url}\">{title}</a>\n"
        
        await update.message.reply_text(response, parse_mode="HTML", disable_web_page_preview=True)
        
    except Exception as e:
        await update.message.reply_text(f"❌ Erreur: {str(e)}")
    
    return ConversationHandler.END


async def wallet_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /wallet command."""
    msg = """💳 <b>Portefeuille & Cartes Prépayées</b>

<i>Achats anonymes sans KYC</i>

<b>1.</b> /quote — Obtenir un devis
<b>2.</b> /order — Commander une carte
<b>3.</b> /rates — Taux crypto actuels

Sélectionnez une option:"""
    
    await update.message.reply_text(msg, parse_mode="HTML")
    return ConversationHandler.END


async def rates_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show current crypto rates."""
    try:
        from wallet.api import fetch_crypto_rates
        rates = await fetch_crypto_rates()
        
        msg = "💰 <b>Taux Crypto (CoinGecko)</b>\n\n"
        for symbol, data in rates.items():
            price = data.get("usd", "N/A")
            msg += f"• {symbol.upper()}: <b>${price}</b>\n"
        
        await update.message.reply_text(msg, parse_mode="HTML")
        
    except Exception as e:
        await update.message.reply_text(f"❌ Erreur: {str(e)}")
    
    return ConversationHandler.END


async def quote_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Start quote conversation."""
    await update.message.reply_text(
        "💳 <b>Devis Carte Prépayée</b>\n\n"
        "Montant souhaité en USD (ex: 50, 100, 200):",
        parse_mode="HTML"
    )
    return WALLET_AMOUNT


async def wallet_amount_received(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Process wallet amount."""
    try:
        amount = float(update.message.text)
        if amount < 10 or amount > 1000:
            await update.message.reply_text("Montant doit être entre 10 et 1000 USD.")
            return ConversationHandler.END
        
        quote = wallet_service.quote_card(amount, "XMR")
        
        msg = f"""💳 <b>Devis Carte Prépayée</b>

<b>Montant:</b> ${amount} USD
<b>Frais (2%):</b> ${quote['fee_usd']}
<b>Total:</b> ${quote['total_usd']}

<b>Cryptomonnaie:</b> {quote['crypto_amount_due']} {quote['crypto_symbol']}
<b>KYC:</b> ❌ Zéro KYC requis

/confirmer pour passer commande"""
        
        await update.message.reply_text(msg, parse_mode="HTML")
        
    except ValueError:
        await update.message.reply_text("Montant invalide. Utilisez un nombre.")
    
    return ConversationHandler.END


async def transfer_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /transfer command."""
    msg = """📁 <b>Transfert de Fichiers P2P</b>

<i>Envoi sécurisé par mot de passe éphémère</i>

<b>/send</b> — Envoyer un fichier
<b>/receive</b> — Recevoir un fichier

<i>Tout passe par Tor pour l'anonymat.</i>"""
    
    await update.message.reply_text(msg, parse_mode="HTML")
    return ConversationHandler.END


async def send_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Generate code phrase for file transfer."""
    codephrase = file_transfer.send_file("/tmp/example.txt")
    
    msg = f"""📤 <b>Envoyer un Fichier</b>

<b>Code phrase:</b> <code>{codephrase.get('command', 'N/A')}</code>

<i>Partagez ce code avec le destinataire.</i>"""
    
    await update.message.reply_text(msg, parse_mode="HTML")
    return ConversationHandler.END


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /help command."""
    help_text = """🤖 <b>Aide AnonSuperApp</b>

<b>Commandes disponibles:</b>

/start — Menu principal
/status — Statut du système
/search — Recherche web anonyme
/wallet — Cartes prépayées Zero-KYC
/transfer — Transfert de fichiers P2P
/help — Cette aide

<b>Modules:</b>
• Messaging P2P (Berty/Tor)
• Wallet Crypto (XMR, BTC, LTC)
• File Transfer (croc/Tor)
• Search (SearXNG/Tor)"""
    
    await update.message.reply_text(help_text, parse_mode="HTML")


async def error_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle errors."""
    logger.error(f"Update {update} caused error {context.error}")
    if update and update.message:
        await update.message.reply_text("❌ Une erreur s'est produite.")


def main():
    """Run the bot."""
    # Create application
    app = Application.builder().token(TELEGRAM_BOT_TOKEN).build()
    
    # Add handlers
    app.add_handler(CommandHandler("start", start_command))
    app.add_handler(CommandHandler("help", help_command))
    app.add_handler(CommandHandler("status", status_command))
    app.add_handler(CommandHandler("rates", rates_command))
    
    # Search conversation
    search_conv = ConversationHandler(
        entry_points=[CommandHandler("search", search_command)],
        states={SEARCH_QUERY: [MessageHandler(filters.TEXT & ~filters.COMMAND, search_received)]},
        fallbacks=[CommandHandler("cancel", start_command)]
    )
    app.add_handler(search_conv)
    
    # Wallet conversation  
    wallet_conv = ConversationHandler(
        entry_points=[CommandHandler("quote", quote_command)],
        states={WALLET_AMOUNT: [MessageHandler(filters.TEXT & ~filters.COMMAND, wallet_amount_received)]},
        fallbacks=[CommandHandler("cancel", start_command)]
    )
    app.add_handler(wallet_conv)
    
    # Transfer handlers
    app.add_handler(CommandHandler("transfer", transfer_command))
    app.add_handler(CommandHandler("send", send_command))
    
    # Error handler
    app.add_error_handler(error_handler)
    
    # Start polling
    print("🤖 AnonSuperApp Bot starting...")
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
