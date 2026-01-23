import 'package:flutter/material.dart';

/// A reusable bottom sheet with a standard header layout.
class AppBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final String? submitLabel;
  final String? cancelLabel;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.submitLabel,
    this.cancelLabel = 'Cancel',
    this.onSubmit,
    this.onCancel,
    this.isLoading = false,
    this.initialChildSize = 0.9,
    this.minChildSize = 0.5,
    this.maxChildSize = 0.95,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    String? submitLabel,
    String cancelLabel = 'Cancel',
    VoidCallback? onSubmit,
    bool isLoading = false,
    double initialChildSize = 0.9,
    double minChildSize = 0.5,
    double maxChildSize = 0.95,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AppBottomSheet(
        title: title,
        submitLabel: submitLabel,
        cancelLabel: cancelLabel,
        onSubmit: onSubmit,
        isLoading: isLoading,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onCancel ?? () => Navigator.pop(context),
                  child: Text(cancelLabel!),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (submitLabel != null)
                  FilledButton(
                    onPressed: isLoading ? null : onSubmit,
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(submitLabel!),
                  )
                else
                  const SizedBox(width: 72),
              ],
            ),
          ),
          const Divider(),
          // Content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// A form field specifically styled for bottom sheets.
class BottomSheetFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final IconData? icon;
  final String? hint;
  final String? helperText;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const BottomSheetFormField({
    super.key,
    this.controller,
    required this.label,
    this.icon,
    this.hint,
    this.helperText,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
