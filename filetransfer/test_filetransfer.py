import os
import pytest
from fastapi.testclient import TestClient
from filetransfer.api import app, DOWNLOADS_DIR, store

client = TestClient(app)

def test_get_codephrase():
    response = client.get("/filetransfer/codephrase")
    assert response.status_code == 200
    data = response.json()
    assert "code_phrase" in data
    assert "-" in data["code_phrase"]

def test_initiate_send_transfer():
    test_file = "/tmp/croc_test_send.txt"
    with open(test_file, "w") as f:
        f.write("Secret data to send over croc relay")

    response = client.post("/filetransfer/send", json={
        "file_path": test_file,
        "code_phrase": "99-alpha-bravo-charlie"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "initiated"
    assert data["code_phrase"] == "99-alpha-bravo-charlie"
    assert data["file_path"] == test_file
    assert "transfer_id" in data
    assert "command" in data

def test_initiate_receive_transfer():
    dest_dir = "/tmp/croc_test_downloads"
    response = client.post("/filetransfer/receive", json={
        "code_phrase": "99-alpha-bravo-charlie",
        "destination_dir": dest_dir
    })
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ready_to_receive"
    assert data["code_phrase"] == "99-alpha-bravo-charlie"
    assert data["destination_dir"] == dest_dir
    assert "transfer_id" in data

def test_get_transfer_status():
    # Create send transfer
    test_file = "/tmp/croc_status_test.txt"
    send_resp = client.post("/filetransfer/send", json={"file_path": test_file})
    transfer_id = send_resp.json()["transfer_id"]

    # Check single status
    status_resp = client.get(f"/filetransfer/status/{transfer_id}")
    assert status_resp.status_code == 200
    assert status_resp.json()["transfer_id"] == transfer_id

    # List all statuses
    list_resp = client.get("/filetransfer/status")
    assert list_resp.status_code == 200
    statuses = list_resp.json()
    assert any(s["transfer_id"] == transfer_id for s in statuses)

def test_download_received_file():
    os.makedirs(DOWNLOADS_DIR, exist_ok=True)
    sample_file = os.path.join(DOWNLOADS_DIR, "test_download_doc.txt")
    with open(sample_file, "w") as f:
        f.write("Content of received croc file")

    # Success download
    dl_resp = client.get("/filetransfer/download/test_download_doc.txt")
    assert dl_resp.status_code == 200
    assert dl_resp.text == "Content of received croc file"

    # Non-existent file
    not_found_resp = client.get("/filetransfer/download/nonexistent_file_123.txt")
    assert not_found_resp.status_code == 404
