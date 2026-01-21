import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchBarField extends ConsumerStatefulWidget {
  final String hintText;
  final StateProvider<String> searchQueryProvider;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const SearchBarField({
    super.key,
    required this.hintText,
    required this.searchQueryProvider,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  ConsumerState<SearchBarField> createState() => _SearchBarFieldState();
}

class _SearchBarFieldState extends ConsumerState<SearchBarField> {
  late final TextEditingController _controller;
  bool _isInitialized = false;
  bool _isClearingProgrammatically = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // Add listener to sync controller → provider
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Initialize controller with provider's initial value on first build
      final initialValue = ref.read(widget.searchQueryProvider);
      if (_controller.text != initialValue) {
        _controller.text = initialValue;
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Don't sync when clearing programmatically to avoid loops
    if (_isClearingProgrammatically) return;

    final currentProviderValue = ref.read(widget.searchQueryProvider);
    if (_controller.text != currentProviderValue) {
      ref.read(widget.searchQueryProvider.notifier).state = _controller.text;
    }
  }

  void _clearSearch() {
    _isClearingProgrammatically = true;
    _controller.clear();
    ref.read(widget.searchQueryProvider.notifier).state = '';
    _isClearingProgrammatically = false;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Provider changes and sync to TextField
    ref.listen<String>(widget.searchQueryProvider, (previous, next) {
      if (next != _controller.text) {
        _controller.text = next;
        // Move cursor to end after programmatic text change
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: next.length),
        );
      }
    });

    final query = ref.watch(widget.searchQueryProvider);

    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction ?? TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
                tooltip: 'Clear search',
              )
            : null,
      ),
      // onChanged removed - now using controller listener for sync
    );
  }
}
