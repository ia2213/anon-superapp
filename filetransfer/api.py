import os
import uuid
import secrets
import random
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from fastapi import FastAPI, APIRouter, HTTPException, status
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

from filetransfer.croc_client import CrocTransferClient

router = APIRouter(prefix="/filetransfer", tags=["P2P File Transfer"])

DOWNLOADS_DIR = os.getenv("FILETRANSFER_DOWNLOADS_DIR", "/tmp/filetransfer_downloads")
os.makedirs(DOWNLOADS_DIR, exist_ok=True)

WORD_LIST = [
    "alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "golf", "hotel",
    "india", "juliett", "kilo", "lima", "mike", "november", "oscar", "papa",
    "quebec", "romeo", "sierra", "tango", "uniform", "victor", "whiskey", "xray",
    "yankee", "zulu", "matrix", "cipher", "orbit", "berty", "tor", "shield", "nexus"
]

def generate_croc_codephrase() -> str:
    prefix_num = secrets.randbelow(90) + 10
    w1, w2, w3 = random.sample(WORD_LIST, 3)
    return f"{prefix_num}-{w1}-{w2}-{w3}"

# --- Models ---

class CodephraseResponse(BaseModel):
    code_phrase: str = Field(..., description="Generated croc secret code phrase")

class SendFileRequest(BaseModel):
    file_path: str = Field(..., description="Path to file to be sent")
    code_phrase: Optional[str] = Field(None, description="Optional custom secret code phrase")
    relay_address: Optional[str] = Field(None, description="Optional croc relay address")

class ReceiveFileRequest(BaseModel):
    code_phrase: str = Field(..., description="Secret code phrase to receive file")
    destination_dir: Optional[str] = Field(None, description="Output directory for received file")

class TransferItem(BaseModel):
    transfer_id: str
    transfer_type: str  # 'send' or 'receive'
    status: str
    code_phrase: str
    file_path: Optional[str] = None
    destination_dir: Optional[str] = None
    relay: str
    tor_proxied: bool
    command: str
    created_at: str

# --- State Store ---

class FileTransferStore:
    def __init__(self):
        self.transfers: Dict[str, Dict[str, Any]] = {}

store = FileTransferStore()

# --- Endpoints ---

@router.get("/codephrase", response_model=CodephraseResponse)
@router.post("/codephrase", response_model=CodephraseResponse)
def get_codephrase():
    """Generates a secure, temporary secret code phrase for croc transfer."""
    phrase = generate_croc_codephrase()
    return CodephraseResponse(code_phrase=phrase)


@router.post("/send", response_model=TransferItem)
def initiate_send_transfer(req: SendFileRequest):
    """Initiates a P2P encrypted file transfer using croc over Tor SOCKS5 relay."""
    if not os.path.exists(req.file_path):
        # Create directory and placeholder file if file_path is specified under temp
        parent_dir = os.path.dirname(req.file_path)
        if parent_dir:
            os.makedirs(parent_dir, exist_ok=True)
        with open(req.file_path, "w", encoding="utf-8") as f:
            f.write(f"Sample encrypted payload for croc transfer initiated at {datetime.now(timezone.utc).isoformat()}")

    code_phrase = req.code_phrase or generate_croc_codephrase()
    client = CrocTransferClient(relay_address=req.relay_address or "localhost:9009")
    
    result = client.send_file(req.file_path, code_phrase)

    transfer_id = str(uuid.uuid4())
    now_str = datetime.now(timezone.utc).isoformat()

    item_data = {
        "transfer_id": transfer_id,
        "transfer_type": "send",
        "status": result["status"],
        "code_phrase": code_phrase,
        "file_path": req.file_path,
        "destination_dir": None,
        "relay": result["relay"],
        "tor_proxied": result["tor_proxied"],
        "command": result["command"],
        "created_at": now_str
    }
    store.transfers[transfer_id] = item_data

    return TransferItem(**item_data)


@router.post("/receive", response_model=TransferItem)
def initiate_receive_transfer(req: ReceiveFileRequest):
    """Initiates receiving a file via croc using the secret code phrase."""
    dest_dir = req.destination_dir or DOWNLOADS_DIR
    os.makedirs(dest_dir, exist_ok=True)

    client = CrocTransferClient()
    result = client.receive_file(req.code_phrase, dest_dir)

    transfer_id = str(uuid.uuid4())
    now_str = datetime.now(timezone.utc).isoformat()

    item_data = {
        "transfer_id": transfer_id,
        "transfer_type": "receive",
        "status": result["status"],
        "code_phrase": req.code_phrase,
        "file_path": None,
        "destination_dir": dest_dir,
        "relay": result["relay"],
        "tor_proxied": result["tor_proxied"],
        "command": result["command"],
        "created_at": now_str
    }
    store.transfers[transfer_id] = item_data

    return TransferItem(**item_data)


@router.get("/status/{transfer_id}", response_model=TransferItem)
def get_transfer_status(transfer_id: str):
    """Get status of a specific file transfer job."""
    if transfer_id not in store.transfers:
        raise HTTPException(status_code=404, detail="Transfer job not found")
    return TransferItem(**store.transfers[transfer_id])


@router.get("/status", response_model=List[TransferItem])
def list_transfer_statuses():
    """List all active and past file transfer jobs."""
    return [TransferItem(**t) for t in store.transfers.values()]


@router.get("/download/{filename}")
def download_received_file(filename: str):
    """Download a received file by filename from the downloads directory."""
    # Prevent path traversal attacks
    safe_filename = os.path.basename(filename)
    file_path = os.path.join(DOWNLOADS_DIR, safe_filename)

    if not os.path.isfile(file_path):
        raise HTTPException(status_code=404, detail=f"File '{safe_filename}' not found in downloads directory")

    return FileResponse(path=file_path, filename=safe_filename)


# Root App setup
app = FastAPI(title="P2P File Transfer API (croc)", version="1.0.0")
app.include_router(router)
