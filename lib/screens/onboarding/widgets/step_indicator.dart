import 'package:flutter/material.dart';

/// Row of dots showing progress through the onboarding pages. The current
/// page is drawn as a wider pill. Purely visual; each page announces its own
/// "Step x of y" label for screen readers.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 28 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: i <= index ? color : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
        ],
      ),
    );
  }
}
