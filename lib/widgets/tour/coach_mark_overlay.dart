import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_controller.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_models.dart';

/// Full-screen coach-mark overlay driven by [TourController].
///
/// Wraps [child] and, while the tour is active, paints a dimming scrim with a
/// rounded hole around the current step's target plus a bubble with
/// Back / Skip / Next. The scrim swallows taps so an accidental tap never
/// advances the tour or triggers the app underneath.
///
/// Target resolution per step: the step's [TourStep.target] key, then the
/// nav-tab key for [TourStep.tabIndex], then no spotlight (centred bubble).
/// Targets inside a scroll view are scrolled into view first. Because tab
/// switches need a frame to lay out, the overlay re-measures after the frame
/// and again after a short settle delay.
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

class _CoachMarkOverlayState extends State<CoachMarkOverlay>
    with WidgetsBindingObserver {
  Rect? _targetRect;
  final List<Timer> _timers = [];
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onTourChanged);
  }

  @override
  void didUpdateWidget(CoachMarkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_onTourChanged);
      widget.controller.addListener(_onTourChanged);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onTourChanged);
    _cancelTimers();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (widget.controller.active) _scheduleMeasure(scroll: false);
  }

  void _onTourChanged() {
    final active = widget.controller.active;
    if (active && !_wasActive) _bringToFront();
    _wasActive = active;
    _scheduleMeasure(scroll: true);
  }

  /// When the tour starts from a pushed route (e.g. Settings or a help sheet),
  /// pop back to the route hosting this overlay so the tour is visible.
  void _bringToFront() {
    final route = ModalRoute.of(context);
    final navigator = Navigator.maybeOf(context);
    if (route == null || navigator == null || route.isCurrent) return;
    navigator.popUntil((r) => r == route || r.isFirst);
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _scheduleMeasure({required bool scroll}) {
    _cancelTimers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measure(scroll: scroll);
      // Measure again once the tab fade and any scroll animation settle.
      _timers.add(Timer(const Duration(milliseconds: 250), () {
        if (mounted) _measure(scroll: false);
      }));
      _timers.add(Timer(const Duration(milliseconds: 600), () {
        if (mounted) _measure(scroll: false);
      }));
    });
  }

  void _measure({required bool scroll}) {
    final step = widget.controller.currentStep;
    if (step == null) {
      if (_targetRect != null) setState(() => _targetRect = null);
      return;
    }
    final target = _resolveTarget(step);
    if (target != null && scroll && Scrollable.maybeOf(target) != null) {
      Scrollable.ensureVisible(
        target,
        alignment: 0.1,
        duration: const Duration(milliseconds: 200),
      );
    }
    final rect = target == null ? null : _rectInOverlay(target);
    if (rect != _targetRect) setState(() => _targetRect = rect);
  }

  /// First attached, laid-out context among the step's candidate keys.
  BuildContext? _resolveTarget(TourStep step) {
    final candidates = <GlobalKey?>[
      widget.targets.keyFor(step.target),
      widget.targets.keyForTab(step.tabIndex),
    ];
    for (final key in candidates) {
      final ctx = key?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      if (box.size.isEmpty) continue;
      if (_rectInOverlay(ctx) == null) continue;
      return ctx;
    }
    return null;
  }

  /// The target's rect in this overlay's coordinates, or null when it is off
  /// screen or not a descendant (e.g. hidden in an inactive tab).
  Rect? _rectInOverlay(BuildContext target) {
    final box = target.findRenderObject();
    final overlay = context.findRenderObject();
    if (box is! RenderBox || overlay is! RenderBox) return null;
    if (!box.attached || !box.hasSize || !overlay.hasSize) return null;
    try {
      final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
      final rect = topLeft & box.size;
      final bounds = Offset.zero & overlay.size;
      if (!rect.overlaps(bounds)) return null;
      return rect;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final step = widget.controller.currentStep;
        return Stack(
          children: [
            widget.child,
            if (widget.controller.active && step != null)
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

  static const double _gap = 12;
  static const double _edge = 12;
  static const double _minBubbleHeight = 220;

  @override
  Widget build(BuildContext context) {
    final hole = targetRect?.inflate(8);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Stack(
          children: [
            // The scrim absorbs every tap; only the bubble buttons move on.
            Positioned.fill(
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  onHorizontalDragEnd: (_) {},
                  onVerticalDragEnd: (_) {},
                  child: TweenAnimationBuilder<Rect?>(
                    // No target: shrink the hole to nothing at the centre.
                    tween: _NullableRectTween(
                      end: hole ?? Rect.fromCenter(
                        center: size.center(Offset.zero),
                        width: 0,
                        height: 0,
                      ),
                    ),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedHole, _) => CustomPaint(
                      painter: _SpotlightPainter(
                        hole: animatedHole,
                        color: Colors.black.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _positionedBubble(context, size, hole),
          ],
        );
      },
    );
  }

  Widget _positionedBubble(BuildContext context, Size size, Rect? hole) {
    final padding = MediaQuery.paddingOf(context);
    final topLimit = padding.top + _edge;
    final bottomLimit = size.height - padding.bottom - _edge;
    final fullHeight = (bottomLimit - topLimit).clamp(0.0, double.infinity);

    Widget place({double? top, double? bottom, required double maxHeight}) {
      return Positioned(
        left: 0,
        right: 0,
        top: top,
        bottom: bottom,
        child: Align(
          alignment: top != null ? Alignment.topCenter : Alignment.bottomCenter,
          heightFactor: 1,
          child: _Bubble(
            controller: controller,
            step: step,
            maxHeight: maxHeight,
          ),
        ),
      );
    }

    if (hole == null) {
      return Positioned.fill(
        top: topLimit,
        bottom: size.height - bottomLimit,
        child: Center(
          child: _Bubble(
            controller: controller,
            step: step,
            maxHeight: fullHeight,
          ),
        ),
      );
    }

    final spaceAbove = (hole.top - _gap - topLimit).clamp(0.0, fullHeight);
    final spaceBelow = (bottomLimit - hole.bottom - _gap).clamp(0.0, fullHeight);
    final preferAbove = spaceAbove >= spaceBelow;
    final best = preferAbove ? spaceAbove : spaceBelow;

    if (best >= _minBubbleHeight) {
      return preferAbove
          ? place(bottom: size.height - (hole.top - _gap), maxHeight: best)
          : place(top: hole.bottom + _gap, maxHeight: best);
    }
    // Target is too tall to fit the bubble beside it: pin the bubble to the
    // roomier edge and let it overlap the target.
    final cap = (fullHeight * 0.6).clamp(0.0, fullHeight);
    return preferAbove
        ? place(top: topLimit, maxHeight: cap)
        : place(bottom: size.height - bottomLimit, maxHeight: cap);
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.controller,
    required this.step,
    required this.maxHeight,
  });

  final TourController controller;
  final TourStep step;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final illustration = step.illustration;
    const buttonSize = Size(64, 48);

    final buttons = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!controller.isFirstStep)
          OutlinedButton(
            onPressed: controller.back,
            style: OutlinedButton.styleFrom(minimumSize: buttonSize),
            child: Text(l10n.tourBack),
          ),
        if (!controller.isLastStep)
          TextButton(
            onPressed: controller.skip,
            style: TextButton.styleFrom(minimumSize: buttonSize),
            child: Text(l10n.tourSkip),
          ),
        FilledButton(
          onPressed: controller.next,
          style: FilledButton.styleFrom(minimumSize: buttonSize),
          child: Text(controller.isLastStep ? l10n.tourDone : l10n.tourNext),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 480, maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Material(
          color: theme.colorScheme.surface,
          elevation: 12,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            liveRegion: true,
            container: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.tourStepCounter(
                            controller.index + 1,
                            controller.steps.length,
                          ),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          step.title(l10n),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (illustration != null) ...[
                          const SizedBox(height: 12),
                          IgnorePointer(child: illustration(context)),
                        ],
                        const SizedBox(height: 8),
                        Text(step.body(l10n), style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: buttons,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rect tween that tolerates null ends (no spotlight) via [Rect.lerp].
class _NullableRectTween extends Tween<Rect?> {
  _NullableRectTween({super.end});

  @override
  Rect? lerp(double t) => Rect.lerp(begin, end, t);
}

/// Paints a translucent scrim, cutting a rounded-rect hole so the target
/// shows through at full brightness.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole, required this.color});

  final Rect? hole;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final paint = Paint()..color = color;
    final h = hole;
    if (h == null || h.width < 1 || h.height < 1) {
      canvas.drawRect(full, paint);
      return;
    }
    // Even-odd fill: outer rect minus the hole.
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(full)
      ..addRRect(RRect.fromRectAndRadius(h, const Radius.circular(12)));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.color != color;
}
