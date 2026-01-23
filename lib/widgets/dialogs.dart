import 'package:flutter/material.dart';

/// A confirmation dialog with customizable actions.
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final bool isDangerous;
  final bool isLoading;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.isDangerous = false,
    this.isLoading = false,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDangerous: isDangerous,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: isLoading
              ? null
              : () {
                  Navigator.pop(context, true);
                  onConfirm?.call();
                },
          style: isDangerous
              ? FilledButton.styleFrom(backgroundColor: Colors.red)
              : null,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(confirmLabel),
        ),
      ],
    );
  }
}

/// A delete confirmation dialog.
class DeleteConfirmDialog extends StatelessWidget {
  final String itemName;
  final VoidCallback? onConfirm;

  const DeleteConfirmDialog({
    super.key,
    required this.itemName,
    this.onConfirm,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String itemName,
  }) {
    return ConfirmDialog.show(
      context: context,
      title: 'Delete $itemName',
      message:
          'Are you sure you want to delete this $itemName? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDangerous: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmDialog(
      title: 'Delete $itemName',
      message:
          'Are you sure you want to delete this $itemName? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDangerous: true,
      onConfirm: onConfirm,
    );
  }
}

/// Utility functions for showing snackbars.
class AppSnackBar {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showResult(
    BuildContext context, {
    required bool success,
    required String successMessage,
    required String errorMessage,
  }) {
    if (success) {
      showSuccess(context, successMessage);
    } else {
      showError(context, errorMessage);
    }
  }
}
