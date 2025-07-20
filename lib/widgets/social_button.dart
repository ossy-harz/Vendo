import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String text;
  final String? icon;
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            // Use a placeholder icon if the asset is not available
            Icon(Icons.login),
            const SizedBox(width: 12),
          ],
          Text(text),
        ],
      ),
    );
  }
}

