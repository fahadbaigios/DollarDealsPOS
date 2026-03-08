import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search...',
    this.debounceMs = 300,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final int debounceMs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          isDense: true,
        ),
        onChanged: (value) {
          Future.delayed(Duration(milliseconds: debounceMs), () {
            if (controller.text == value) onChanged(value);
          });
        },
      ),
    );
  }
}
