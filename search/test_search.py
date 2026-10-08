"""
Unit tests for the Anonymous Web Search API module.

Run with: python3 -m unittest search.test_search
"""

import unittest
import json
from unittest.mock import patch, MagicMock
from typing import List

from fastapi.testclient import TestClient

# Import the module under test
from search import api as search_api
from search.api import (
    SearchRequest,
    SearchResult,
    _run_chain,
    _extract_ddg_url,
    _search_duckduckgo,
    _search_wikipedia,
    router,
)


class TestDDGUrlExtraction(unittest.TestCase):
    """Test DuckDuckGo URL extraction logic."""

    def test_simple_uddg_redirect(self):
        raw = "//duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.com%2Fpage&other=params"
        result = _extract_ddg_url(raw)
        self.assertEqual(result, "https://example.com/page")

    def test_u3_redirect(self):
        raw = "//example.com?u3=https%3A%2F%2Ftarget.org%2Fpath"
        result = _extract_ddg_url(raw)
        self.assertEqual(result, "https://target.org/path")

    def test_plain_url_unchanged(self):
        raw = "https://python.org/about/"
        result = _extract_ddg_url(raw)
        self.assertEqual(result, "https://python.org/about/")

    def test_empty_returns_empty(self):
        self.assertEqual(_extract_ddg_url(""), "")
        self.assertEqual(_extract_ddg_url(None), "")


class TestSearchResultModel(unittest.TestCase):
    """Test Pydantic models."""

    def test_search_result_valid(self):
        result = SearchResult(
            title="Test Title",
            url="https://example.com",
            snippet="Test snippet",
            category="general",
            engine="test"
        )
        self.assertEqual(result.title, "Test Title")
        self.assertEqual(result.engine, "test")

    def test_search_result_minimal(self):
        result = SearchResult(
            title="T",
            url="https://x.com",
            snippet="",
            category="general",
            engine="test"
        )
        self.assertTrue(result.title)  # required


class TestEngineChaining(unittest.TestCase):
    """Test fallback chain logic."""

    def test_searxng_succeeds(self):
        original_searxng = search_api.ENGINES["searxng"]["fn"]
        original_ddg = search_api.ENGINES["duckduckgo"]["fn"]
        
        def success_searxng(*a, **kw):
            return [
                SearchResult(title="A", url="https://a.com", snippet="", category="general", engine="searxng")
            ]
        
        try:
            search_api.ENGINES["searxng"]["fn"] = success_searxng
            engine_used, results, fallback = _run_chain(
                "test query", "general", "en", 10, ["searxng", "duckduckgo"]
            )
            self.assertEqual(engine_used, "searxng")
            self.assertEqual(len(results), 1)
            self.assertEqual(fallback, [])
        finally:
            search_api.ENGINES["searxng"]["fn"] = original_searxng
            search_api.ENGINES["duckduckgo"]["fn"] = original_ddg

    def test_searxng_falls_back_to_ddg(self):
        original_searxng = search_api.ENGINES["searxng"]["fn"]
        original_ddg = search_api.ENGINES["duckduckgo"]["fn"]
        
        def fail_searxng(*a, **kw):
            raise RuntimeError("SearXNG down")
        
        def success_ddg(*a, **kw):
            return [
                SearchResult(title="B", url="https://b.com", snippet="", category="general", engine="duckduckgo")
            ]
        
        try:
            search_api.ENGINES["searxng"]["fn"] = fail_searxng
            search_api.ENGINES["duckduckgo"]["fn"] = success_ddg
            engine_used, results, fallback = _run_chain(
                "test query", "general", "en", 10, ["searxng", "duckduckgo"]
            )
            self.assertEqual(engine_used, "duckduckgo")
            self.assertEqual(len(results), 1)
            self.assertIn("searxng", fallback)
        finally:
            search_api.ENGINES["searxng"]["fn"] = original_searxng
            search_api.ENGINES["duckduckgo"]["fn"] = original_ddg

    def test_all_fail_returns_empty(self):
        original_searxng = search_api.ENGINES["searxng"]["fn"]
        original_ddg = search_api.ENGINES["duckduckgo"]["fn"]
        
        def fail_searxng(*a, **kw):
            raise RuntimeError("fail")
        
        def fail_ddg(*a, **kw):
            raise RuntimeError("fail")
        
        try:
            # Both fail
            search_api.ENGINES["searxng"]["fn"] = fail_searxng
            search_api.ENGINES["duckduckgo"]["fn"] = fail_ddg
            engine_used, results, fallback = _run_chain(
                "test query", "general", "en", 10, ["searxng", "duckduckgo"]
            )
            self.assertEqual(engine_used, "none")
            self.assertEqual(len(results), 0)
            self.assertEqual(len(fallback), 2)
        finally:
            search_api.ENGINES["searxng"]["fn"] = original_searxng
            search_api.ENGINES["duckduckgo"]["fn"] = original_ddg


class TestAPIRoutes(unittest.TestCase):
    """Test FastAPI routes."""

    def setUp(self):
        # Create a minimal FastAPI app for testing
        from fastapi import FastAPI
        self.app = FastAPI()
        self.app.include_router(router)
        self.client = TestClient(self.app)

    @patch("search.api._run_chain")
    def test_search_endpoint_returns_results(self, mock_run):
        mock_run.return_value = (
            "duckduckgo",
            [
                SearchResult(
                    title="Python",
                    url="https://python.org",
                    snippet="A programming language",
                    category="general",
                    engine="duckduckgo"
                )
            ],
            ["searxng"]
        )
        response = self.client.post(
            "/search",
            json={"query": "python", "max_results": 5}
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["query"], "python")
        self.assertEqual(data["engine_used"], "duckduckgo")
        self.assertEqual(len(data["results"]), 1)
        self.assertEqual(data["results"][0]["title"], "Python")

    @patch("search.api._run_chain")
    def test_search_endpoint_no_results_returns_503(self, mock_run):
        mock_run.return_value = ("none", [], ["searxng", "duckduckgo"])
        response = self.client.post(
            "/search",
            json={"query": "nonexistent_query_12345"}
        )
        self.assertEqual(response.status_code, 503)

    def test_search_endpoint_validation(self):
        # Empty query should fail validation
        response = self.client.post(
            "/search",
            json={"query": ""}
        )
        self.assertEqual(response.status_code, 422)

    def test_health_endpoint(self):
        response = self.client.get("/search/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("status", data)
        self.assertIn("searxng", data)
        self.assertIn("duckduckgo", data)

    def test_engines_endpoint(self):
        response = self.client.get("/search/engines")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIsInstance(data, list)
        engine_names = [e["name"] for e in data]
        self.assertIn("searxng", engine_names)
        self.assertIn("duckduckgo", engine_names)
        self.assertIn("wikipedia", engine_names)


class TestWikipediaEngine(unittest.TestCase):
    """Test Wikipedia search engine."""

    @patch("search.api._session_with_tor")
    def test_wikipedia_returns_results(self, mock_session):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            "query": {
                "search": [
                    {"title": "Python", "snippet": "A programming language"},
                    {"title": "Python (programming language)", "snippet": "High-level language"},
                ]
            }
        }
        mock_session.return_value.get.return_value = mock_resp

        results = _search_wikipedia("python", "general", "en", 10)
        self.assertEqual(len(results), 2)
        self.assertEqual(results[0].engine, "wikipedia")
        self.assertIn("wikipedia.org", results[0].url)

    @patch("search.api._session_with_tor")
    def test_wikipedia_handles_http_error(self, mock_session):
        mock_resp = MagicMock()
        mock_resp.status_code = 500
        mock_session.return_value.get.return_value = mock_resp

        with self.assertRaises(RuntimeError) as ctx:
            _search_wikipedia("test", "general", "en", 10)
        self.assertIn("HTTP 500", str(ctx.exception))


class TestDDGEngine(unittest.TestCase):
    """Test DuckDuckGo HTML search engine."""

    @patch("search.api._session_with_tor")
    def test_ddg_parses_results(self, mock_session):
        html = '''
        <html><body>
        <div class="result">
            <a class="result__a" href="?uddg=https%3A%2F%2Fexample.com">Example</a>
            <a class="result__snippet">Example site snippet</a>
        </div>
        </body></html>
        '''
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.text = html
        mock_session.return_value.post.return_value = mock_resp

        results = _search_duckduckgo("test", "general", "en", 10)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0].title, "Example")
        self.assertEqual(results[0].url, "https://example.com")
        self.assertEqual(results[0].engine, "duckduckgo")

    @patch("search.api._session_with_tor")
    def test_ddg_skips_ads(self, mock_session):
        html = '''
        <html><body>
        <div class="result">
            <a class="result__a" href="?uddg=https%3A%2F%2Fduckduckgo.com%2Fy.js%3Fad_domain=ads.com">Ad Link</a>
        </div>
        </body></html>
        '''
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.text = html
        mock_session.return_value.post.return_value = mock_resp

        results = _search_duckduckgo("test", "general", "en", 10)
        self.assertEqual(len(results), 0)  # ad filtered out


class TestSearchRequestModel(unittest.TestCase):
    """Test SearchRequest Pydantic model."""

    def test_valid_request(self):
        req = SearchRequest(query="test", category="news", language="fr", max_results=20)
        self.assertEqual(req.query, "test")
        self.assertEqual(req.category, "news")
        self.assertEqual(req.max_results, 20)

    def test_defaults(self):
        req = SearchRequest(query="test")
        self.assertEqual(req.category, "general")
        self.assertEqual(req.language, "en")
        self.assertEqual(req.max_results, 10)

    def test_max_results_validation(self):
        with self.assertRaises(ValueError):
            SearchRequest(query="test", max_results=0)
        with self.assertRaises(ValueError):
            SearchRequest(query="test", max_results=100)


if __name__ == "__main__":
    unittest.main()