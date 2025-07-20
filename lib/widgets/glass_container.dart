import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double blur;
  final Color color;
  final double border;
  final VoidCallback? onTap;
  final double height;
  final double? width;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.blur = 10,
    this.color = Colors.white,
    this.border = 1.5,
    this.onTap,
    this.height = 0,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode 
        ? Colors.black.withOpacity(0.2) 
        : color.withOpacity(0.2);
    final borderColor = isDarkMode 
        ? Colors.white.withOpacity(0.2) 
        : Colors.white.withOpacity(0.8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height > 0 ? height : null,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: AppTheme.glassShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: border,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

