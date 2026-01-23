import 'package:flutter/material.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final Color? color;
  final Widget? trailing;
  final double? elevation;
  final Color? borderColor;
  final double? borderWidth;

  const BentoCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.onTap,
    this.padding,
    this.height,
    this.color,
    this.trailing,
    this.elevation,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? colorScheme.onSurface.withValues(alpha: 0.1),
          width: borderWidth ?? 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: (elevation ?? 2.0) * 0.05),
            blurRadius: (elevation ?? 2.0) * 2,
            offset: Offset(0, (elevation ?? 2.0)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null || icon != null) ...[
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: colorScheme.primary),
                        const SizedBox(width: 8),
                      ],
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                // Content
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
