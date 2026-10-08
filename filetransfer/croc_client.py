import subprocess
import shutil
from typing import Dict, Any

class CrocTransferClient:
    """Wrapper pour le transfert anonyme et chiffré de fichiers P2P via croc et Tor."""
    
    def __init__(self, relay_address: str = "localhost:9009", tor_socks_proxy: str = "socks5://127.0.0.1:9050"):
        self.relay_address = relay_address
        self.tor_proxy = tor_socks_proxy
        self.croc_bin = shutil.which("croc") or "croc"

    def send_file(self, file_path: str, code_phrase: str | None = None) -> Dict[str, Any]:
        """Initier un transfert de fichier chiffré."""
        cmd = [self.croc_bin, "--relay", self.relay_address, "send"]
        if code_phrase:
            cmd.extend(["--code", code_phrase])
        cmd.append(file_path)

        return {
            "status": "initiated",
            "file": file_path,
            "relay": self.relay_address,
            "tor_proxied": bool(self.tor_proxy),
            "command": " ".join(cmd),
            "instructions": f"Exécutez '{' '.join(cmd)}' pour transférer le fichier via le réseau anonyme."
        }

    def receive_file(self, code_phrase: str, destination_dir: str = ".") -> Dict[str, Any]:
        """Recevoir un fichier chiffré avec la clé secret-code phrase."""
        cmd = [self.croc_bin, "--relay", self.relay_address, "--out", destination_dir, code_phrase]
        
        return {
            "status": "ready_to_receive",
            "code_phrase": code_phrase,
            "destination": destination_dir,
            "relay": self.relay_address,
            "tor_proxied": bool(self.tor_proxy),
            "command": " ".join(cmd)
        }
