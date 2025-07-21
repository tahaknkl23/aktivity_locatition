import 'package:flutter/material.dart';

class SnackbarHelper {
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: duration,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      duration: duration,
    );
  }

  // GÜNCELLENMIŞ: backgroundColor parametresi eklendi
  static void showInfo({
    required BuildContext context,
    required String message,
    Color? backgroundColor, // EKLENEN PARAMETRE
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: backgroundColor ?? Colors.blue, // Default blue
      icon: Icons.info,
      duration: duration,
    );
  }

  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    // 🔧 GÜVENLİ KONTROL: Context'in mounted olup olmadığını kontrol et
    if (!_isContextValid(context)) {
      debugPrint('[SNACKBAR] Context is not valid, skipping SnackBar');
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () {
              // 🔧 GÜVENLİ KONTROL: Hide işlemi için de kontrol
              if (_isContextValid(context)) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('[SNACKBAR] Error showing SnackBar: $e');
    }
  }

  // 🔧 YENİ: Context'in geçerli olup olmadığını kontrol et
  static bool _isContextValid(BuildContext context) {
    try {
      // Context'in mounted olup olmadığını kontrol et
      if (context.mounted) {
        // ScaffoldMessenger'ın mevcut olup olmadığını kontrol et
        ScaffoldMessenger.of(context);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SNACKBAR] Context validation error: $e');
      return false;
    }
  }
}
