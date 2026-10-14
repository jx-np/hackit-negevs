import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

/// A soft, rounded surface with tinted elevation — the base container for the
/// redesigned UI. Reads [AppTokens] so it adapts to light/dark automatically.
///
/// Use [onTap] to make the whole card tappable (adds an ink ripple and keeps
/// the 44x44 min tap target via the padded content).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.border,
    this.raised = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;

  /// Use the stronger "raised" shadow instead of the resting card shadow.
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final radius = tokens.radii.lgRadius;
    final resolvedPadding =
        padding ?? EdgeInsets.all(tokens.space.xl); // 24

    final decoration = BoxDecoration(
      color: color ?? Theme.of(context).cardColor,
      borderRadius: radius,
      border: border,
      boxShadow: raised ? tokens.elevation.raised : tokens.elevation.card,
    );

    final content = Padding(padding: resolvedPadding, child: child);

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    return DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: scheme.primary.withValues(alpha: 0.08),
          highlightColor: scheme.primary.withValues(alpha: 0.04),
          child: content,
        ),
      ),
    );
  }
}
