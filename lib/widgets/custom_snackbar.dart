import 'package:flutter/material.dart';

class CustomSnackbar extends StatelessWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const CustomSnackbar({
    super.key,
    required this.message,
    this.isSuccess = true,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSuccess 
          ? const Color(0xFF0A1F14) // Darker green background
          : const Color(0xFF1F0F0F), // Darker red background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess 
            ? const Color(0xFF22C55E).withOpacity(0.5) // Softer green border
            : const Color(0xFFEF4444).withOpacity(0.5), // Softer red border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSuccess 
              ? const Color(0xFF22C55E).withOpacity(0.15)
              : const Color(0xFFEF4444).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess 
              ? const Color(0xFF22C55E) // Matching green icon
              : const Color(0xFFEF4444), // Matching red icon
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFE5E7EB), // Lighter text for better contrast
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onActionPressed,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: isSuccess 
                  ? const Color(0xFF22C55E).withOpacity(0.1)
                  : const Color(0xFFEF4444).withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: isSuccess 
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void showCustomSnackbar({
  required BuildContext context,
  required String message,
  bool isSuccess = true,
  Duration duration = const Duration(seconds: 4),
  VoidCallback? onActionPressed,
  String? actionLabel,
}) {
  final snackBar = SnackBar(
    content: CustomSnackbar(
      message: message,
      isSuccess: isSuccess,
      onActionPressed: onActionPressed,
      actionLabel: actionLabel,
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    duration: duration,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    padding: EdgeInsets.zero,
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}
