import os
import pytest
from fastapi.testclient import TestClient
from messaging.api import app, store

client = TestClient(app)

def test_generate_keypair():
    response = client.post("/messaging/keys/generate")
    assert response.status_code == 200
    data = response.json()
    assert "private_key" in data
    assert "public_key" in data
    assert len(data["private_key"]) == 64
    assert len(data["public_key"]) == 64
    assert data["key_type"] == "Curve25519"

def test_encrypt_and_decrypt_message():
    # Generate Keypair A (Sender)
    kp_a = client.post("/messaging/keys/generate").json()
    # Generate Keypair B (Recipient)
    kp_b = client.post("/messaging/keys/generate").json()

    plaintext = "Secret P2P Message over Tor WebRTC"

    # Encrypt: sender_priv_A + recipient_pub_B
    enc_resp = client.post("/messaging/keys/encrypt", json={
        "sender_private_key": kp_a["private_key"],
        "recipient_public_key": kp_b["public_key"],
        "plaintext": plaintext
    })
    assert enc_resp.status_code == 200
    enc_data = enc_resp.json()
    assert "ciphertext" in enc_data
    assert "nonce" in enc_data

    # Decrypt: recipient_priv_B + sender_pub_A
    dec_resp = client.post("/messaging/keys/decrypt", json={
        "recipient_private_key": kp_b["private_key"],
        "sender_public_key": kp_a["public_key"],
        "ciphertext": enc_data["ciphertext"],
        "nonce": enc_data["nonce"]
    })
    assert dec_resp.status_code == 200
    dec_data = dec_resp.json()
    assert dec_data["plaintext"] == plaintext

def test_room_lifecycle_and_messaging():
    # 1. Create Room
    create_resp = client.post("/messaging/rooms", json={
        "name": "Secret Ops Channel",
        "topic": "Tor WebRTC discussion"
    })
    assert create_resp.status_code == 200
    room_data = create_resp.json()
    room_id = room_data["room_id"]
    assert room_data["name"] == "Secret Ops Channel"

    # 2. List Rooms
    list_resp = client.get("/messaging/rooms")
    assert list_resp.status_code == 200
    rooms = list_resp.json()
    assert any(r["room_id"] == room_id for r in rooms)

    # 3. Send Message via REST
    msg_resp = client.post(f"/messaging/rooms/{room_id}/messages", json={
        "sender_id": "peer-alice",
        "content": "Hello P2P room!",
        "encrypted": False
    })
    assert msg_resp.status_code == 200
    msg_data = msg_resp.json()
    assert msg_data["room_id"] == room_id
    assert msg_data["sender_id"] == "peer-alice"
    assert msg_data["content"] == "Hello P2P room!"

    # 4. Fetch Message History
    hist_resp = client.get(f"/messaging/rooms/{room_id}/messages")
    assert hist_resp.status_code == 200
    messages = hist_resp.json()
    assert len(messages) >= 1
    assert messages[-1]["content"] == "Hello P2P room!"

def test_websocket_chat():
    room_id = "general"
    with client.websocket_connect(f"/messaging/rooms/{room_id}/ws") as websocket:
        # Test Ping
        websocket.send_json({"action": "ping"})
        response = websocket.receive_json()
        assert response == {"type": "pong"}

        # Send Chat Message
        websocket.send_json({
            "action": "send_message",
            "sender_id": "bob-node",
            "content": "Encrypted WebRTC test",
            "encrypted": True
        })
        broadcast = websocket.receive_json()
        assert broadcast["type"] == "chat_message"
        assert broadcast["data"]["sender_id"] == "bob-node"
        assert broadcast["data"]["content"] == "Encrypted WebRTC test"

def test_peer_discovery():
    response = client.get("/messaging/peers")
    assert response.status_code == 200
    data = response.json()
    assert "tor_socks_proxy" in data
    assert "tor_connected" in data
    assert isinstance(data["peers"], list)
    assert len(data["peers"]) >= 1

def test_message_relay():
    relay_req = {
        "target_peer_onion": "xyz123abcdef456789.onion",
        "payload": "48656c6c6f20546f72",
        "sender_id": "sender-onion-01"
    }
    response = client.post("/messaging/relay", json=relay_req)
    assert response.status_code == 200
    data = response.json()
    assert data["target_peer_onion"] == "xyz123abcdef456789.onion"
    assert "relay_id" in data
    assert "status" in data

    # Check relay status
    status_resp = client.get("/messaging/relay/status")
    assert status_resp.status_code == 200
    status_data = status_resp.json()
    assert status_data["total_relayed"] >= 1
