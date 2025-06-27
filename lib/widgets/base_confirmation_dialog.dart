import 'package:flutter/material.dart';
import '../core/colors.dart';

class BaseConfirmationDialog extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final String message;
  final String? warningMessage;
  final String cancelText;
  final String confirmText;
  final Color? cancelColor;
  final Color? confirmColor;

  const BaseConfirmationDialog({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.message,
    this.warningMessage,
    this.cancelText = 'Cancelar',
    this.confirmText = 'Confirmar',
    this.cancelColor,
    this.confirmColor,
  });

  /// Muestra un diálogo de confirmación genérico
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required IconData titleIcon,
    required String message,
    String? warningMessage,
    String cancelText = 'Cancelar',
    String confirmText = 'Confirmar',
    Color? cancelColor,
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BaseConfirmationDialog(
          title: title,
          titleIcon: titleIcon,
          message: message,
          warningMessage: warningMessage,
          cancelText: cancelText,
          confirmText: confirmText,
          cancelColor: cancelColor,
          confirmColor: confirmColor,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            titleIcon,
            color: accentBlue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          if (warningMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 152, 0, 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color.fromRGBO(255, 152, 0, 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warningMessage!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: ElevatedButton.styleFrom(
            backgroundColor: cancelColor ?? Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? accentBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
