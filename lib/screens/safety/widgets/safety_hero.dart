import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

/// What the hero shield is showing.
enum SafetyHeroStatus { off, on, error, checking }

/// The protection status area at the top of the Safety screen: a large glowing
/// shield, a short title and line, and the main [action] button.
class SafetyHero extends StatefulWidget {
  const SafetyHero({
    super.key,
    required this.status,
    required this.title,
    this.subtitle,
    required this.action,
    this.accentOverride,
  });

  final SafetyHeroStatus status;
  final String title;
  final String? subtitle;
  final Widget action;

  /// Replaces the status colour, e.g. for the shimmer while a message is
  /// being checked.
  final Color? accentOverride;

  @override
  State<SafetyHero> createState() => _SafetyHeroState();
}

class _SafetyHeroState extends State<SafetyHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  bool get _shouldPulse =>
      widget.status == SafetyHeroStatus.on ||
      widget.status == SafetyHeroStatus.checking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncGlow();
  }

  @override
  void didUpdateWidget(SafetyHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncGlow();
  }

  void _syncGlow() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_shouldPulse && !reduceMotion) {
      if (!_glow.isAnimating) _glow.repeat(reverse: true);
    } else {
      _glow.stop();
      _glow.value = _shouldPulse ? 0.5 : 0;
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Color _accent(ColorScheme scheme, AppRiskColors risk) {
    if (widget.accentOverride != null) return widget.accentOverride!;
    switch (widget.status) {
      case SafetyHeroStatus.on:
        return risk.safe;
      case SafetyHeroStatus.error:
        return risk.danger;
      case SafetyHeroStatus.checking:
        return scheme.primary;
      case SafetyHeroStatus.off:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _accent(scheme, context.tokens.risk);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: CustomPaint(
        painter: _DotGridPainter(scheme.onSurface.withValues(alpha: 0.07)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            children: [
              ExcludeSemantics(
                child: _GlowingShield(
                  color: accent,
                  glow: _glow,
                  muted: widget.status == SafetyHeroStatus.off,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              widget.action,
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowingShield extends StatelessWidget {
  const _GlowingShield({
    required this.color,
    required this.glow,
    required this.muted,
  });

  final Color color;
  final Animation<double> glow;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 168,
      height: 168,
      child: AnimatedBuilder(
        animation: glow,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(glow.value);
          final glowAlpha = muted ? 0.10 : 0.22 + 0.18 * t;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Soft halo that breathes while protection is on.
              Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: glowAlpha),
                      color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              // Thin outer ring.
              Container(
                width: 116 + 6 * t,
                height: 116 + 6 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: muted ? 0.25 : 0.45),
                    width: 1.5,
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: muted ? 0.18 : 0.38),
                color.withValues(alpha: muted ? 0.08 : 0.18),
              ],
            ),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
          ),
          child: Icon(
            muted ? Icons.shield_outlined : Icons.verified_user_rounded,
            size: 48,
            color: muted ? scheme.onSurfaceVariant : color,
          ),
        ),
      ),
    );
  }
}

/// Faint dotted texture behind the hero.
class _DotGridPainter extends CustomPainter {
  _DotGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 18.0;
    final paint = Paint()..color = color;
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => oldDelegate.color != color;
}
