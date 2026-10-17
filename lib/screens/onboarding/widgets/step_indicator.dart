import 'package:flutter/material.dart';

/// Progress through the onboarding pages: an optional "Step x of y" line
/// above a row of dots. The current page is drawn as a wider pill. The dots
/// wrap onto a second line instead of overflowing on narrow screens.
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.count,
    required this.index,
    this.label,
  });

  final int count;
  final int index;

  /// Readable progress text, e.g. "Step 2 of 9". Hidden when null.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ExcludeSemantics(
          child: Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 6,
            children: [
              for (var i = 0; i < count; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == index ? 28 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: i <= index ? color : color.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
