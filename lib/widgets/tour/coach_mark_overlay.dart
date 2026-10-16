import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';

import 'tour_controller.dart';
import 'tour_models.dart';

/// Full-screen interactive coach-mark overlay driven by [TourController].
///
/// Wraps [child] (the app's HomePage body + nav) and, while the tour is active,
/// paints a dimming scrim with a rounded hole cut around the current step's
/// target. A tooltip bubble explains the step and offers Skip / Next.
///
/// The target rect is resolved from the [CoachMarkTargets] nav key for the
/// current step. Because switching tabs and laying out the destination takes a
/// frame, the overlay re-measures on each post-frame and animates the hole to
/// the new rect.
class CoachMarkOverlay extends StatefulWidget {
  const CoachMarkOverlay({
    super.key,
    required this.controller,
    required this.targets,
    required this.child,
  });

  final TourController controller;
  final CoachMarkTargets targets;
  final Widget child;

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTourChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTourChanged);
    super.dispose();
  }

  void _onTourChanged() {
    // Tab switches need a frame to lay out the new destination before we can
    // measure it. Re-measure after this frame and after a short settle delay
    // so the spotlight lands on the freshly laid-out target.
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measure();
      // A second measure after the tab-switch animation settles.
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _measure();
      });
    });
  }

  void _measure() {
    final step = widget.controller.currentStep;
    if (step == null) {
      if (_targetRect != null) setState(() => _targetRect = null);
      return;
    }
    final rect = _rectForStep(step);
    if (rect != _targetRect) setState(() => _targetRect = rect);
  }

  Rect? _rectForStep(TourStep step) {
    final key = widget.targets.keyForTab(step.tabIndex);
    final context = key?.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final step = widget.controller.currentStep;
        final showOverlay = widget.controller.active && step != null;
        return Stack(
          children: [
            widget.child,
            if (showOverlay)
              Positioned.fill(
                child: _CoachMarkLayer(
                  controller: widget.controller,
                  step: step,
                  targetRect: _targetRect,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CoachMarkLayer extends StatelessWidget {
  const _CoachMarkLayer({
    required this.controller,
    required this.step,
    required this.targetRect,
  });

  final TourController controller;
  final TourStep step;
  final Rect? targetRect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    // Inflate the hole a little so the target is comfortably framed.
    final hole = targetRect?.inflate(8);

    return Stack(
      children: [
        // Dimming scrim with a hole cut around the target. Tapping the scrim
        // advances the tour, matching the Next button.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.next,
            child: CustomPaint(
              painter: _SpotlightPainter(
                hole: hole,
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),
          ),
        ),
        _buildBubble(context, theme, size, hole),
      ],
    );
  }

  Widget _buildBubble(
    BuildContext context,
    ThemeData theme,
    Size size,
    Rect? hole,
  ) {
    final media = MediaQuery.of(context);
    final l10n = AppLocalizations.of(context);
    final total = controller.steps.length;
    final current = controller.index + 1;
    final (title, body) = _stepText(l10n, controller.index);

    // Place the bubble above the target when the target sits in the lower half
    // (the nav bar always does), otherwise below it. Falls back to centre.
    final bubble = Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tourStepCounter(current, total),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: controller.skip,
                child: Text(l10n.tourSkip),
              ),
              FilledButton(
                onPressed: controller.next,
                child: Text(controller.isLastStep ? l10n.tourDone : l10n.tourNext),
              ),
            ],
          ),
        ],
      ),
    );

    // Position: if we have a hole in the bottom portion of the screen (nav bar),
    // anchor the bubble just above it. Otherwise centre vertically.
    if (hole != null && hole.top > size.height * 0.5) {
      final bottomGap = size.height - hole.top + 12;
      return Positioned(
        left: 0,
        right: 0,
        bottom: bottomGap.clamp(media.padding.bottom + 12, size.height * 0.6),
        child: bubble,
      );
    }
    if (hole != null && hole.bottom < size.height * 0.5) {
      return Positioned(
        left: 0,
        right: 0,
        top: (hole.bottom + 12).clamp(media.padding.top + 12, size.height * 0.6),
        child: bubble,
      );
    }
    return Center(child: bubble);
  }

  /// Resolves the localized (title, body) for the step at list index [i].
  ///
  /// The index maps to each step's identity in [kTourSteps]:
  /// 0=Home, 1=Calls, 2=Safety, 3=Report, 4=My Posts, 5=Settings. Any
  /// out-of-range index falls back to the first step's copy to stay render-safe.
  (String, String) _stepText(AppLocalizations l10n, int i) {
    switch (i) {
      case 1:
        return (l10n.tourCallsTitle, l10n.tourCallsBody);
      case 2:
        return (l10n.tourSafetyTitle, l10n.tourSafetyBody);
      case 3:
        return (l10n.tourReportTitle, l10n.tourReportBody);
      case 4:
        return (l10n.tourMyPostsTitle, l10n.tourMyPostsBody);
      case 5:
        return (l10n.tourSettingsTitle, l10n.tourSettingsBody);
      case 0:
      default:
        return (l10n.tourHomeTitle, l10n.tourHomeBody);
    }
  }
}

/// Paints a translucent scrim over the whole screen, cutting a rounded-rect
/// hole so the target element shows through at full brightness.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole, required this.color});

  final Rect? hole;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final paint = Paint()..color = color;
    if (hole == null) {
      canvas.drawRect(full, paint);
      return;
    }
    final rrect = RRect.fromRectAndRadius(hole!, const Radius.circular(12));
    // Even-odd fill: outer rect minus the hole leaves everything but the hole.
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(full)
      ..addRRect(rrect);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.color != color;
}
