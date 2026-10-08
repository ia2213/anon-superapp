"""
Anonymous Web Search API — SearXNG + Tor SOCKS5 with fallbacks.

Engines (tried in order until at least one returns results):
  1. Local SearXNG instance (routed through Tor SOCKS5 proxy when configured)
  2. DuckDuckGo HTML scraping (fallback if SearXNG is unavailable)
  3. Wikipedia API (fallback for encyclopedic queries)

All responses are normalised to the same JSON shape:
  { title, url, snippet, category, engine }
"""

import os
import logging
from typing import List, Optional, Dict, Any
from urllib.parse import urlparse, parse_qs, unquote, quote

import requests
from bs4 import BeautifulSoup
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from search.client import AnonymousSearchClient

logger = logging.getLogger("search.api")

router = APIRouter(prefix="/search", tags=["Anonymous Web Search"])

# --------------------------------------------------------------------------- #
# Configuration                                                                #
# --------------------------------------------------------------------------- #

SEARXNG_URL = os.getenv("SEARXNG_URL", "http://localhost:8080")
TOR_PROXY = os.getenv("TOR_PROXY", "socks5://localhost:9050")  # set to "" to disable
REQUEST_TIMEOUT = int(os.getenv("SEARCH_TIMEOUT", "15"))
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:120.0) "
    "Gecko/20100101 Firefox/120.0"
)

# --------------------------------------------------------------------------- #
# Pydantic models                                                              #
# --------------------------------------------------------------------------- #

class SearchRequest(BaseModel):
    query: str = Field(..., min_length=1, description="Search query")
    category: str = Field("general", description="SearXNG category (general, news, images, …)")
    language: str = Field("en", description="ISO language code")
    engines: Optional[List[str]] = Field(
        None,
        description="Optional ordered list of engines to try. Defaults to [searxng, duckduckgo, wikipedia].",
    )
    max_results: int = Field(10, ge=1, le=50, description="Max results to return")


class SearchResult(BaseModel):
    title: str
    url: str
    snippet: str
    category: str
    engine: str


class SearchResponse(BaseModel):
    query: str
    engine_used: str
    total: int
    results: List[SearchResult]
    fallback_chain: List[str]


class EngineInfo(BaseModel):
    name: str
    description: str
    available: bool


class HealthResponse(BaseModel):
    status: str
    searxng: str
    tor_proxy: Optional[str]
    duckduckgo: str
    wikipedia: str


# --------------------------------------------------------------------------- #
# Engine implementations                                                       #
# --------------------------------------------------------------------------- #

def _session_with_tor() -> requests.Session:
    """Return a requests.Session routed through Tor SOCKS5 when configured."""
    s = requests.Session()
    if TOR_PROXY:
        s.proxies = {"http": TOR_PROXY, "https": TOR_PROXY}
    s.headers.update({"User-Agent": USER_AGENT})
    return s


def _search_searxng(query: str, category: str, language: str, max_results: int) -> List[SearchResult]:
    """Primary engine: local SearXNG instance (optionally via Tor)."""
    client = AnonymousSearchClient(searxng_url=SEARXNG_URL, tor_proxy=TOR_PROXY or None)
    raw = client.search(query, category=category, language=language)
    if isinstance(raw, dict) and "error" in raw:
        raise RuntimeError(raw["error"])
    if not isinstance(raw, list):
        raise RuntimeError(f"Unexpected SearXNG response: {type(raw).__name__}")

    results: List[SearchResult] = []
    for item in raw[:max_results]:
        results.append(
            SearchResult(
                title=item.get("title", "").strip(),
                url=item.get("url", ""),
                snippet=(item.get("content") or "").strip(),
                category=item.get("category", category),
                engine=item.get("engine", "searxng"),
            )
        )
    return [r for r in results if r.title and r.url]


def _extract_ddg_url(raw_href: str) -> str:
    """Resolve a DuckDuckGo redirect href to the final destination URL."""
    if not raw_href:
        return ""
    if raw_href.startswith("//"):
        raw_href = "https:" + raw_href
    parsed = urlparse(raw_href)
    qs = parse_qs(parsed.query)
    for key in ("uddg", "u3", "u"):
        if key in qs:
            return unquote(qs[key][0])
    return raw_href


def _search_duckduckgo(query: str, category: str, language: str, max_results: int) -> List[SearchResult]:
    """Fallback engine: DuckDuckGo HTML-only endpoint (no JS, Tor-friendly)."""
    session = _session_with_tor()
    resp = session.post(
        "https://html.duckduckgo.com/html/",
        data={"q": query, "kl": f"{language}-{language.upper()}"},
        timeout=REQUEST_TIMEOUT,
    )
    if resp.status_code != 200:
        raise RuntimeError(f"DDG HTTP {resp.status_code}")

    soup = BeautifulSoup(resp.text, "html.parser")
    results: List[SearchResult] = []
    for res in soup.find_all("div", class_="result"):
        title_tag = res.find("a", class_="result__a")
        if not title_tag:
            continue
        snippet_tag = res.find("a", class_="result__snippet")
        url = _extract_ddg_url(title_tag.get("href", ""))
        if not url or "duckduckgo.com/y.js" in url:
            # skip ads
            continue
        results.append(
            SearchResult(
                title=title_tag.get_text(strip=True),
                url=url,
                snippet=(snippet_tag.get_text(strip=True) if snippet_tag else ""),
                category=category,
                engine="duckduckgo",
            )
        )
        if len(results) >= max_results:
            break
    return results


def _search_wikipedia(query: str, category: str, language: str, max_results: int) -> List[SearchResult]:
    """Fallback engine: Wikipedia OpenSearch API (Tor-routed)."""
    session = _session_with_tor()
    params = {
        "action": "query",
        "list": "search",
        "srsearch": query,
        "srlimit": max_results,
        "format": "json",
    }
    resp = session.get(
        f"https://{language}.wikipedia.org/w/api.php",
        params=params,
        timeout=REQUEST_TIMEOUT,
    )
    if resp.status_code != 200:
        raise RuntimeError(f"Wikipedia HTTP {resp.status_code}")
    data = resp.json()
    items = data.get("query", {}).get("search", [])
    results: List[SearchResult] = []
    for item in items:
        title = item.get("title", "")
        raw_snippet = item.get("snippet", "")
        snippet = BeautifulSoup(raw_snippet, "html.parser").get_text(strip=True)
        results.append(
            SearchResult(
                title=title,
                url=f"https://{language}.wikipedia.org/wiki/{quote(title.replace(' ', '_'))}",
                snippet=snippet,
                category="wikipedia",
                engine="wikipedia",
            )
        )
    return results


ENGINES: Dict[str, Any] = {
    "searxng": {
        "fn": _search_searxng,
        "description": "Local SearXNG instance routed through Tor SOCKS5",
    },
    "duckduckgo": {
        "fn": _search_duckduckgo,
        "description": "DuckDuckGo HTML-only endpoint (no JS required)",
    },
    "wikipedia": {
        "fn": _search_wikipedia,
        "description": "Wikipedia OpenSearch API",
    },
}

DEFAULT_CHAIN = ["searxng", "duckduckgo", "wikipedia"]


def _run_chain(query: str, category: str, language: str, max_results: int, chain: List[str]) -> tuple[str, List[SearchResult], List[str]]:
    """Try engines in order; return (engine_used, results, fallback_chain)."""
    fallback_chain: List[str] = []
    for name in chain:
        if name not in ENGINES:
            continue
        try:
            results = ENGINES[name]["fn"](query, category, language, max_results)
            if results:
                return name, results, fallback_chain
        except Exception as exc:
            logger.warning("Engine %s failed: %s", name, exc)
            fallback_chain.append(name)
    return "none", [], fallback_chain


# --------------------------------------------------------------------------- #
# Routes                                                                       #
# --------------------------------------------------------------------------- #

@router.post("", response_model=SearchResponse)
async def search(req: SearchRequest):
    chain = req.engines or DEFAULT_CHAIN
    engine_used, results, fallback_chain = _run_chain(
        req.query, req.category, req.language, req.max_results, chain
    )
    if not results:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="All search engines failed or returned no results",
        )
    return SearchResponse(
        query=req.query,
        engine_used=engine_used,
        total=len(results),
        results=results,
        fallback_chain=fallback_chain,
    )


@router.get("/engines", response_model=List[EngineInfo])
async def list_engines():
    out: List[EngineInfo] = []
    for name, meta in ENGINES.items():
        available = True
        if name == "searxng":
            try:
                requests.get(SEARXNG_URL, timeout=3)
            except Exception:
                available = False
        out.append(EngineInfo(name=name, description=meta["description"], available=available))
    return out


@router.get("/health", response_model=HealthResponse)
async def health():
    def probe(url: str) -> str:
        try:
            r = requests.get(url, timeout=3)
            return "up" if r.status_code < 500 else f"down({r.status_code})"
        except Exception as exc:
            return f"down({type(exc).__name__})"

    return HealthResponse(
        status="ok",
        searxng=probe(SEARXNG_URL),
        tor_proxy=TOR_PROXY or "disabled",
        duckduckgo=probe("https://html.duckduckgo.com/html/"),
        wikipedia=probe("https://en.wikipedia.org/w/api.php"),
    )


# --------------------------------------------------------------------------- #
# Standalone runner                                                            #
# --------------------------------------------------------------------------- #

if __name__ == "__main__":
    import uvicorn
    from fastapi import FastAPI

    app = FastAPI(title="Anonymous Web Search API", version="1.0.0")
    app.include_router(router)
    uvicorn.run(app, host="0.0.0.0", port=8091)
