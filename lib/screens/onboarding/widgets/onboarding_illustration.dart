import 'package:flutter/material.dart';

/// Calm green used to show that something is turned on.
const Color kOnboardingDoneColor = Color(0xFF2E7D32);

/// Large icon in a soft circle. Switches to a check mark with a gentle
/// scale-and-fade when [done] becomes true.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.icon,
    this.done = false,
  });

  final IconData icon;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final accent = done
        ? kOnboardingDoneColor
        : Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.12),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            done ? Icons.check_rounded : icon,
            key: ValueKey<bool>(done),
            size: 64,
            color: accent,
          ),
        ),
      ),
    );
  }
}
