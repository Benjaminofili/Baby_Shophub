import 'package:flutter/material.dart';
import '../theme.dart';

class SearchSection extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  final VoidCallback? onTap;

  const SearchSection({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap:
            onTap ??
            () {
              // Navigate to dedicated search page
              Navigator.pushNamed(
                context,
                '/search',
                arguments: {'query': controller.text},
              );
            },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.backgroundGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitted,
            onTap:
                onTap ??
                () {
                  Navigator.pushNamed(
                    context,
                    '/search',
                    arguments: {'query': controller.text},
                  );
                },
            decoration: InputDecoration(
              hintText: 'Search for baby products...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.primary,
                size: 20,
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: () {
                        controller.clear();
                      },
                    )
                  : Icon(Icons.tune, size: 20, color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }
}
