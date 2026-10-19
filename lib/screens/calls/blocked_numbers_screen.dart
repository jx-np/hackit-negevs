import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_tokens.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_screen.dart';
import '../../widgets/ui/empty_state.dart';

class BlockedNumbersScreen extends StatefulWidget {
  const BlockedNumbersScreen({super.key});

  @override
  State<BlockedNumbersScreen> createState() => _BlockedNumbersScreenState();
}

class _BlockedNumbersScreenState extends State<BlockedNumbersScreen> {
  static const String _prefsKey = 'spam_blocked_numbers';
  static const String _protectionEnabledPrefsKey = 'spam_protection_enabled';

  final Set<String> _blocked = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final stored = prefs.getString(_prefsKey) ?? '';
    if (!mounted) return;
    setState(() {
      _blocked
        ..clear()
        ..addAll(stored.split(',').where((e) => e.isNotEmpty));
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _blocked.join(','));
    await prefs.setBool(_protectionEnabledPrefsKey, _blocked.isNotEmpty);
  }

  Future<void> _unblock(String number) async {
    setState(() => _blocked.remove(number));
    await _save();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.callUnblocked(number))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final numbers = _blocked.toList()..sort();
    return AppScreen(
      title: l10n.blockedNumbersTitle,
      scrollable: false,
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.refreshCw),
          tooltip: l10n.commonRefresh,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: _load,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : numbers.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: LucideIcons.shieldBan,
                  title: l10n.blockedNoNumbers,
                  message: l10n.callsBlockedEmptyBody,
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.only(
                top: context.tokens.space.sm,
                bottom: context.tokens.space.xl2,
              ),
              itemCount: numbers.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: context.tokens.space.md),
              itemBuilder: (context, index) {
                final number = numbers[index];
                final scheme = Theme.of(context).colorScheme;
                final theme = Theme.of(context);
                // Number on top, Unblock below its right edge, so both fit
                // at large text sizes.
                return AppCard(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.tokens.space.lg,
                    vertical: context.tokens.space.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          ExcludeSemantics(
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: context.tokens.risk.dangerContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.ban,
                                size: 22,
                                color: context.tokens.risk.danger,
                              ),
                            ),
                          ),
                          SizedBox(width: context.tokens.space.md),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                number,
                                maxLines: 1,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton.icon(
                          onPressed: () => _unblock(number),
                          icon: const Icon(LucideIcons.lockOpen, size: 20),
                          label: Text(l10n.callUnblock),
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.primary,
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
