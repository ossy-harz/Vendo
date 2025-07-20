import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ButtonType { primary, secondary, outline, text }
enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final IconData? icon;
  final ButtonType type;
  final ButtonSize size;
  final bool isFullWidth;
  final bool isDisabled;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.icon,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isFullWidth = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine button style based on type
    ButtonStyle getButtonStyle() {
      switch (type) {
        case ButtonType.primary:
          return ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? theme.colorScheme.primary,
            foregroundColor: textColor ?? Colors.white,
            disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.5),
            disabledForegroundColor: Colors.white.withOpacity(0.7),
          );
        case ButtonType.secondary:
          return ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? theme.colorScheme.secondary,
            foregroundColor: textColor ?? Colors.white,
            disabledBackgroundColor: theme.colorScheme.secondary.withOpacity(0.5),
            disabledForegroundColor: Colors.white.withOpacity(0.7),
          );
        case ButtonType.outline:
          return OutlinedButton.styleFrom(
            foregroundColor: textColor ?? theme.colorScheme.primary,
            side: BorderSide(
              color: (backgroundColor ?? theme.colorScheme.primary).withOpacity(isDisabled ? 0.5 : 1),
              width: 1.5,
            ),
          );
        case ButtonType.text:
          return TextButton.styleFrom(
            foregroundColor: textColor ?? theme.colorScheme.primary,
            disabledForegroundColor: theme.colorScheme.primary.withOpacity(0.5),
          );
      }
    }

    // Determine padding based on size
    EdgeInsetsGeometry getPadding() {
      switch (size) {
        case ButtonSize.small:
          return const EdgeInsets.symmetric(vertical: 8, horizontal: 16);
        case ButtonSize.medium:
          return const EdgeInsets.symmetric(vertical: 12, horizontal: 24);
        case ButtonSize.large:
          return const EdgeInsets.symmetric(vertical: 16, horizontal: 32);
      }
    }

    // Build button content
    Widget buttonContent = isLoading
        ? SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: type == ButtonType.outline || type == ButtonType.text
            ? theme.colorScheme.primary
            : Colors.white,
      ),
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: size == ButtonSize.small ? 16 : 20),
          SizedBox(width: size == ButtonSize.small ? 4 : 8),
        ],
        Text(
          text,
          style: AppTheme.buttonText.copyWith(
            fontSize: size == ButtonSize.small ? 14 : 16,
          ),
        ),
      ],
    );

    // Build the appropriate button type
    Widget button;
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        button = ElevatedButton(
          onPressed: isDisabled || isLoading ? null : onPressed,
          style: getButtonStyle().copyWith(
            padding: MaterialStateProperty.all(getPadding()),
          ),
          child: buttonContent,
        );
        break;
      case ButtonType.outline:
        button = OutlinedButton(
          onPressed: isDisabled || isLoading ? null : onPressed,
          style: getButtonStyle().copyWith(
            padding: MaterialStateProperty.all(getPadding()),
          ),
          child: buttonContent,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: isDisabled || isLoading ? null : onPressed,
          style: getButtonStyle().copyWith(
            padding: MaterialStateProperty.all(getPadding()),
          ),
          child: buttonContent,
        );
        break;
    }

    // Apply width constraints
    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    } else if (width != null) {
      return SizedBox(
        width: width,
        child: button,
      );
    } else {
      return button;
    }
  }
}

