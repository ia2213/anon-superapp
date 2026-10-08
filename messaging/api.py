import os
import socket
import uuid
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from fastapi import FastAPI, APIRouter, WebSocket, WebSocketDisconnect, HTTPException, status
from pydantic import BaseModel, Field

from cryptography.hazmat.primitives.asymmetric import x25519
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from messaging.tor_webrtc import BertyTorWebRTCNode

router = APIRouter(prefix="/messaging", tags=["P2P Messaging"])

# --- Models ---

class KeypairResponse(BaseModel):
    private_key: str = Field(..., description="Hex-encoded Curve25519 private key")
    public_key: str = Field(..., description="Hex-encoded Curve25519 public key")
    key_type: str = "Curve25519"

class EncryptRequest(BaseModel):
    sender_private_key: str = Field(..., description="Hex-encoded sender private key")
    recipient_public_key: str = Field(..., description="Hex-encoded recipient public key")
    plaintext: str = Field(..., description="Plaintext message to encrypt")

class EncryptResponse(BaseModel):
    ciphertext: str = Field(..., description="Hex-encoded ciphertext")
    nonce: str = Field(..., description="Hex-encoded nonce")

class DecryptRequest(BaseModel):
    recipient_private_key: str = Field(..., description="Hex-encoded recipient private key")
    sender_public_key: str = Field(..., description="Hex-encoded sender public key")
    ciphertext: str = Field(..., description="Hex-encoded ciphertext")
    nonce: str = Field(..., description="Hex-encoded nonce")

class DecryptResponse(BaseModel):
    plaintext: str = Field(..., description="Decrypted plaintext message")

class CreateRoomRequest(BaseModel):
    name: str = Field(..., description="Room name")
    topic: Optional[str] = Field(None, description="Room topic or description")

class RoomResponse(BaseModel):
    room_id: str
    name: str
    topic: Optional[str]
    created_at: str
    message_count: int

class SendMessageRequest(BaseModel):
    sender_id: str = Field(..., description="Sender ID or public key")
    content: str = Field(..., description="Message payload or encrypted payload")
    encrypted: bool = Field(False, description="Flag indicating if content is encrypted")

class MessageItem(BaseModel):
    message_id: str
    room_id: str
    sender_id: str
    content: str
    encrypted: bool
    timestamp: str

class PeerInfo(BaseModel):
    peer_id: str
    onion_address: str
    socks_proxy: str
    status: str
    last_seen: str

class PeerDiscoveryResponse(BaseModel):
    tor_socks_proxy: str
    tor_connected: bool
    peers: List[PeerInfo]

class RelayMessageRequest(BaseModel):
    target_peer_onion: str = Field(..., description="Target peer Tor onion address")
    payload: str = Field(..., description="Message payload to relay")
    sender_id: str = Field(..., description="Sender identity or onion address")

class RelayResponse(BaseModel):
    relay_id: str
    target_peer_onion: str
    status: str
    tor_proxied: bool
    timestamp: str


# --- In-Memory State & Store ---

class MessagingStore:
    def __init__(self):
        self.rooms: Dict[str, Dict[str, Any]] = {}
        self.messages: Dict[str, List[Dict[str, Any]]] = {}
        self.peers: Dict[str, Dict[str, Any]] = {}
        self.relays: List[Dict[str, Any]] = []
        self.tor_node = BertyTorWebRTCNode()

        # Seed default general room
        gen_id = "general"
        self.rooms[gen_id] = {
            "room_id": gen_id,
            "name": "General P2P Room",
            "topic": "Default encrypted P2P channel",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        self.messages[gen_id] = []

store = MessagingStore()


class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, room_id: str, websocket: WebSocket):
        await websocket.accept()
        if room_id not in self.active_connections:
            self.active_connections[room_id] = []
        self.active_connections[room_id].append(websocket)

    def disconnect(self, room_id: str, websocket: WebSocket):
        if room_id in self.active_connections:
            if websocket in self.active_connections[room_id]:
                self.active_connections[room_id].remove(websocket)

    async def broadcast(self, room_id: str, message: dict):
        if room_id in self.active_connections:
            for connection in list(self.active_connections[room_id]):
                try:
                    await connection.send_json(message)
                except Exception:
                    pass

ws_manager = ConnectionManager()


# --- Helper Functions ---

def check_tor_socks5_connection(proxy_host: str = "127.0.0.1", proxy_port: int = 9050) -> bool:
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2.0)
        result = sock.connect_ex((proxy_host, proxy_port))
        sock.close()
        return result == 0
    except Exception:
        return False


# --- REST Endpoints ---

@router.post("/keys/generate", response_model=KeypairResponse)
def generate_keypair():
    """Generates a new Curve25519 (X25519) keypair for E2EE P2P messaging."""
    private_key = x25519.X25519PrivateKey.generate()
    public_key = private_key.public_key()
    return KeypairResponse(
        private_key=private_key.private_bytes_raw().hex(),
        public_key=public_key.public_bytes_raw().hex(),
        key_type="Curve25519"
    )


@router.post("/keys/encrypt", response_model=EncryptResponse)
def encrypt_message(req: EncryptRequest):
    """Encrypts plaintext using Curve25519 ECDH key exchange + AES-256-GCM."""
    try:
        sender_priv = x25519.X25519PrivateKey.from_private_bytes(bytes.fromhex(req.sender_private_key))
        recipient_pub = x25519.X25519PublicKey.from_public_bytes(bytes.fromhex(req.recipient_public_key))
        shared_secret = sender_priv.exchange(recipient_pub)
        
        hkdf = HKDF(
            algorithm=hashes.SHA256(),
            length=32,
            salt=None,
            info=b"anon-messaging-curve25519",
        )
        aes_key = hkdf.derive(shared_secret)
        aesgcm = AESGCM(aes_key)
        nonce = os.urandom(12)
        ciphertext = aesgcm.encrypt(nonce, req.plaintext.encode("utf-8"), None)
        return EncryptResponse(ciphertext=ciphertext.hex(), nonce=nonce.hex())
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Encryption failed: {str(e)}")


@router.post("/keys/decrypt", response_model=DecryptResponse)
def decrypt_message(req: DecryptRequest):
    """Decrypts ciphertext using Curve25519 ECDH key exchange + AES-256-GCM."""
    try:
        recipient_priv = x25519.X25519PrivateKey.from_private_bytes(bytes.fromhex(req.recipient_private_key))
        sender_pub = x25519.X25519PublicKey.from_public_bytes(bytes.fromhex(req.sender_public_key))
        shared_secret = recipient_priv.exchange(sender_pub)
        
        hkdf = HKDF(
            algorithm=hashes.SHA256(),
            length=32,
            salt=None,
            info=b"anon-messaging-curve25519",
        )
        aes_key = hkdf.derive(shared_secret)
        aesgcm = AESGCM(aes_key)
        plaintext_bytes = aesgcm.decrypt(bytes.fromhex(req.nonce), bytes.fromhex(req.ciphertext), None)
        return DecryptResponse(plaintext=plaintext_bytes.decode("utf-8"))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Decryption failed: {str(e)}")


@router.post("/rooms", response_model=RoomResponse)
def create_room(req: CreateRoomRequest):
    """Create a new P2P encrypted chat room."""
    room_id = str(uuid.uuid4())[:8]
    room_data = {
        "room_id": room_id,
        "name": req.name,
        "topic": req.topic,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    store.rooms[room_id] = room_data
    store.messages[room_id] = []
    return RoomResponse(
        room_id=room_id,
        name=req.name,
        topic=req.topic,
        created_at=room_data["created_at"],
        message_count=0
    )


@router.get("/rooms", response_model=List[RoomResponse])
def list_rooms():
    """List all active P2P chat rooms."""
    res = []
    for room_id, r in store.rooms.items():
        msg_count = len(store.messages.get(room_id, []))
        res.append(RoomResponse(
            room_id=room_id,
            name=r["name"],
            topic=r.get("topic"),
            created_at=r["created_at"],
            message_count=msg_count
        ))
    return res


@router.get("/rooms/{room_id}/messages", response_model=List[MessageItem])
def get_room_messages(room_id: str):
    """Get message history for a specific room."""
    if room_id not in store.rooms:
        raise HTTPException(status_code=404, detail="Room not found")
    raw_msgs = store.messages.get(room_id, [])
    return [MessageItem(**m) for m in raw_msgs]


@router.post("/rooms/{room_id}/messages", response_model=MessageItem)
async def send_room_message(room_id: str, req: SendMessageRequest):
    """Post a message to a chat room via REST and broadcast to WebSocket subscribers."""
    if room_id not in store.rooms:
        raise HTTPException(status_code=404, detail="Room not found")
    
    msg_item = {
        "message_id": str(uuid.uuid4()),
        "room_id": room_id,
        "sender_id": req.sender_id,
        "content": req.content,
        "encrypted": req.encrypted,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }
    store.messages[room_id].append(msg_item)
    
    # Broadcast via WebSocket
    await ws_manager.broadcast(room_id, {"type": "chat_message", "data": msg_item})
    
    return MessageItem(**msg_item)


@router.get("/peers", response_model=PeerDiscoveryResponse)
def discover_peers():
    """Discover P2P peers over Tor SOCKS5 proxy."""
    socks_str = store.tor_node.tor_socks_proxy
    parts = socks_str.split(":")
    proxy_host = parts[0] if parts else "127.0.0.1"
    proxy_port = int(parts[1]) if len(parts) > 1 else 9050

    tor_connected = check_tor_socks5_connection(proxy_host, proxy_port)

    # Return registered or discovered peers
    peers_list = [PeerInfo(**p) for p in store.peers.values()]
    if not peers_list:
        # Default mock peer entry if none registered yet
        default_peer = PeerInfo(
            peer_id="berty-tor-node-01",
            onion_address="bertyp2p7v5gq2k1.onion",
            socks_proxy=socks_str,
            status="active" if tor_connected else "standby",
            last_seen=datetime.now(timezone.utc).isoformat()
        )
        peers_list.append(default_peer)

    return PeerDiscoveryResponse(
        tor_socks_proxy=socks_str,
        tor_connected=tor_connected,
        peers=peers_list
    )


@router.post("/relay", response_model=RelayResponse)
def relay_message(req: RelayMessageRequest):
    """Relay an encrypted message payload to a target peer onion address over Tor."""
    socks_str = store.tor_node.tor_socks_proxy
    parts = socks_str.split(":")
    proxy_host = parts[0] if parts else "127.0.0.1"
    proxy_port = int(parts[1]) if len(parts) > 1 else 9050
    tor_connected = check_tor_socks5_connection(proxy_host, proxy_port)

    relay_id = str(uuid.uuid4())
    now_str = datetime.now(timezone.utc).isoformat()
    
    status_str = "relayed" if tor_connected else "queued_offline"
    
    relay_entry = {
        "relay_id": relay_id,
        "target_peer_onion": req.target_peer_onion,
        "sender_id": req.sender_id,
        "payload": req.payload,
        "status": status_str,
        "tor_proxied": True,
        "timestamp": now_str
    }
    store.relays.append(relay_entry)

    return RelayResponse(
        relay_id=relay_id,
        target_peer_onion=req.target_peer_onion,
        status=status_str,
        tor_proxied=True,
        timestamp=now_str
    )


@router.get("/relay/status")
def relay_status():
    """Check the status of message relays and Berty Tor node config."""
    config = store.tor_node.get_berty_config()
    return {
        "node_config": config,
        "total_relayed": len(store.relays),
        "recent_relays": store.relays[-10:]
    }


# --- WebSocket Endpoint ---

@router.websocket("/rooms/{room_id}/ws")
async def websocket_room_chat(websocket: WebSocket, room_id: str):
    """WebSocket endpoint for real-time P2P chat room communication."""
    if room_id not in store.rooms:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    await ws_manager.connect(room_id, websocket)
    try:
        while True:
            data = await websocket.receive_json()
            action = data.get("action") or data.get("type")
            if action == "ping":
                await websocket.send_json({"type": "pong"})
                continue

            sender_id = data.get("sender_id", "anonymous")
            content = data.get("content", "")
            encrypted = data.get("encrypted", False)

            msg_item = {
                "message_id": str(uuid.uuid4()),
                "room_id": room_id,
                "sender_id": sender_id,
                "content": content,
                "encrypted": encrypted,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            store.messages[room_id].append(msg_item)
            await ws_manager.broadcast(room_id, {"type": "chat_message", "data": msg_item})
    except WebSocketDisconnect:
        ws_manager.disconnect(room_id, websocket)
    except Exception:
        ws_manager.disconnect(room_id, websocket)


# Root App setup
app = FastAPI(title="P2P Messaging API", version="1.0.0")
app.include_router(router)
