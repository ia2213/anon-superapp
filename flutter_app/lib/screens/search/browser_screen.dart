import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/search_result.dart';

class AnonymousBrowserScreen extends StatefulWidget {
  final SearchResult result;

  const AnonymousBrowserScreen({super.key, required this.result});

  @override
  State<AnonymousBrowserScreen> createState() => _AnonymousBrowserScreenState();
}

class _AnonymousBrowserScreenState extends State<AnonymousBrowserScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F0F1A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onProgress: (int progress) {
            setState(() => _progress = progress / 100.0);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.result.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final uri = Uri.parse(widget.result.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFF0F0F1A),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF0F0F1A),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Color(0xFF00D4AA), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.result.url,
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text('TOR SOCKS5', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
