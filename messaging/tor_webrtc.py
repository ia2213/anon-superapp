from typing import Dict, Any

class BertyTorWebRTCNode:
    """Gestionnaire de configuration Berty P2P avec WebRTC et Tor Always-On."""
    
    def __init__(self, tor_socks_proxy: str = "127.0.0.1:9050", tor_control_port: int = 9051):
        self.tor_socks_proxy = tor_socks_proxy
        self.tor_control_port = tor_control_port

    def get_berty_config(self) -> Dict[str, Any]:
        """Générer la configuration Berty sécurisée forçant le routage Tor & WebRTC."""
        return {
            "node": {
                "protocol": "berty_p2p_v1",
                "tor": {
                    "mode": "always_on", # Forcer Tor en permanence
                    "socks_proxy": self.tor_socks_proxy,
                    "isolation": True,
                    "deny_clearnet": True # Bloquer tout trafic hors Tor
                },
                "webrtc": {
                    "enabled": True,
                    "ice_servers": [
                        {"urls": "stun:stun.l.google.com:19302", "proxied_via": "socks5://127.0.0.1:9050"}
                    ],
                    "force_encrypted_datachannels": True
                },
                "privacy": {
                    "ip_leak_protection": True,
                    "anonymize_peer_id": True,
                    "zero_logs": True
                }
            }
        }
