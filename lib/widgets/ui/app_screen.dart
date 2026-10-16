import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

/// A consistent screen scaffold for the redesigned UI.
///
/// Provides a themed app bar (flat, card-colored), the themed background, and
/// a body area with standard horizontal padding. Pass [scrollable] (default
/// true) to wrap the body in a scroll view; pair with [onRefresh] to add
/// pull-to-refresh. Use [bottomBar] for a pinned thumb-zone action.
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.title,
    required this.body,
    this.titleWidget,
    this.actions,
    this.leading,
    this.scrollable = true,
    this.onRefresh,
    this.bottomBar,
    this.padBody = true,
  });

  final String title;

  /// Optional custom widget rendered in place of the plain [title] text in the
  /// app bar. Use this when a page needs a tappable or styled header (e.g. the
  /// home greeting) while keeping the standard app-bar size and placement.
  /// The [title] is still required and used as the semantic/fallback label.
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;

  /// Wrap [body] in a scroll view. Set false when the body manages its own
  /// scrolling (e.g. a ListView.builder for long feeds).
  final bool scrollable;

  /// Pull-to-refresh handler. Only applied when [scrollable] is true.
  final Future<void> Function()? onRefresh;

  /// Pinned bottom action area (lives in the thumb zone, inside SafeArea).
  final Widget? bottomBar;

  /// Apply standard horizontal screen padding to the body.
  final bool padBody;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    Widget content = body;
    if (padBody) {
      content = Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.space.lg),
        child: content,
      );
    }

    if (scrollable) {
      content = SingleChildScrollView(
        padding: EdgeInsets.only(
          top: tokens.space.sm,
          bottom: tokens.space.xl2,
        ),
        child: content,
      );
      if (onRefresh != null) {
        content = RefreshIndicator(onRefresh: onRefresh!, child: content);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: titleWidget ?? Text(title),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        centerTitle: false,
        actions: actions,
        leading: leading,
      ),
      body: SafeArea(child: content),
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.space.lg,
                  tokens.space.sm,
                  tokens.space.lg,
                  tokens.space.md,
                ),
                child: bottomBar,
              ),
            ),
    );
  }
}
