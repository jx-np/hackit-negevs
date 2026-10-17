import 'package:flutter/material.dart';

/// Shared layout for every onboarding page: illustration, optional small
/// label, title, body and an optional footer, centred and scrollable so large
/// text sizes never overflow.
///
/// While the user swipes, each layer slides at a slightly different speed and
/// the page fades, giving a soft, staggered transition. Motion is turned off
/// when the system "remove animations" setting is on.
class OnboardingPageLayout extends StatelessWidget {
  const OnboardingPageLayout({
    super.key,
    required this.controller,
    required this.index,
    required this.illustration,
    required this.title,
    required this.body,
    this.label,
    this.footer,
  });

  final PageController controller;
  final int index;
  final Widget illustration;
  final String title;
  final String body;
  final String? label;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final width = MediaQuery.sizeOf(context).width;

    final labelText = label == null
        ? null
        : Text(
            label!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          );
    final titleText = Semantics(
      header: true,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final bodyText = Text(
      body,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
    );

    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final delta = reduceMotion ? 0.0 : _pageDelta();

          // Deeper layers travel further, so they leave first and arrive last.
          Widget layer(Widget child, double depth) {
            if (delta == 0) return child;
            return Transform.translate(
              offset: Offset(-delta * width * depth, 0),
              child: child,
            );
          }

          return Opacity(
            opacity: (1 - delta.abs() * 1.4).clamp(0.0, 1.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 32).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    layer(illustration, 0.1),
                    const SizedBox(height: 24),
                    if (labelText != null) ...[
                      layer(labelText, 0.2),
                      const SizedBox(height: 8),
                    ],
                    layer(titleText, 0.25),
                    const SizedBox(height: 16),
                    layer(bodyText, 0.4),
                    if (footer != null) ...[
                      const SizedBox(height: 24),
                      layer(footer!, 0.5),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// How far this page is from the centre of the screen: 0 when fully shown,
  /// -1 / 1 when a full page away.
  double _pageDelta() {
    if (!controller.hasClients || !controller.position.haveDimensions) {
      return 0;
    }
    final page = controller.page ?? index.toDouble();
    return (page - index).clamp(-1.0, 1.0);
  }
}
