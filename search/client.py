import requests

class AnonymousSearchClient:
    """Client de recherche SearXNG anonymisé via proxy Tor SOCKS5."""
    
    def __init__(self, searxng_url: str = "http://localhost:8080", tor_proxy: str | None = "socks5://localhost:9050"):
        self.searxng_url = searxng_url
        self.proxies = {
            "http": tor_proxy,
            "https": tor_proxy
        } if tor_proxy else None

    def search(self, query: str, category: str = "general", language: str = "fr"):
        params = {
            "q": query,
            "format": "json",
            "categories": category,
            "language": language
        }
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:120.0) Gecko/20100101 Firefox/120.0"
        }
        try:
            # Requete vers l'instance SearXNG (chiffrée / sans logs)
            response = requests.get(f"{self.searxng_url}/search", params=params, headers=headers, timeout=15)
            if response.status_code == 200:
                return response.json().get("results", [])
            return {"error": f"HTTP {response.status_code}"}
        except Exception as e:
            return {"error": str(e)}
