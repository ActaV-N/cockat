import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';

/// Canny 피드백 위젯을 WebView로 표시하는 화면
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initializeWebView();
    }
  }

  Future<void> _initializeWebView() async {
    final cannyService = ref.read(cannyServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final cannyUrl = await cannyService.buildCannyUrl(isDarkMode: isDark);

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(
          isDark ? const Color(0xFF1A1A1A) : Colors.white,
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              }
            },
            onPageFinished: (url) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            onWebResourceError: (error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = error.description;
                });
              }
            },
            onNavigationRequest: (request) {
              // Canny 도메인만 허용
              if (request.url.contains('canny.io')) {
                return NavigationDecision.navigate;
              }
              // 외부 링크는 차단 (필요시 url_launcher로 열기)
              return NavigationDecision.prevent;
            },
          ),
        )
        ..loadRequest(Uri.parse(cannyUrl));

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _controller = null;
    });
    await _initializeWebView();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sendFeedback),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          if (_controller != null && !_hasError)
            WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.coralPeach,
              ),
            ),
          if (_hasError)
            _ErrorView(
              message: _errorMessage,
              onRetry: _retry,
            ),
        ],
      ),
    );
  }
}

/// 에러 표시 위젯
class _ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _ErrorView({
    this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              l10n.feedbackLoadError,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppTheme.spacingLg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
