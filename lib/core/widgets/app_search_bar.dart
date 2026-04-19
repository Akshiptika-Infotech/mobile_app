import 'dart:async';

import 'package:flutter/material.dart';

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search...',
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final TextEditingController? controller;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onTextChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                _debounce?.cancel();
                widget.onChanged('');
              },
            );
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
      ),
    );
  }
}
