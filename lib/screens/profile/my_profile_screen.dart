import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/models/api/auth_models.dart';
import 'package:scamwatch_mobile_app/state/auth_controller.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/auth/require_login.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_screen.dart';
import 'package:scamwatch_mobile_app/widgets/ui/empty_state.dart';

/// Signed-in user's profile. Reached by tapping the home-page greeting.
///
/// Users can't upload a photo, so the header uses a large tinted initials
/// avatar instead of a picture. The screen leans elderly-friendly: big text,
/// generous spacing, and a single clear action (sign out) in the thumb zone.
class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.user;

    // Signed-out fallback. The greeting normally routes signed-out users to
    // login, but guard here too so the screen never looks broken.
    if (!auth.isSignedIn || user == null) {
      return AppScreen(
        title: l10n.myProfileTitle,
        scrollable: false,
        body: EmptyState(
          icon: LucideIcons.circleUserRound,
          title: l10n.myProfileNotSignedInTitle,
          message: l10n.myProfileNotSignedInBody,
          action: FilledButton.icon(
            onPressed: () => requireLogin(context),
            icon: const Icon(LucideIcons.logIn),
            label: Text(l10n.myProfileSignIn),
          ),
        ),
      );
    }

    final tokens = context.tokens;

    return AppScreen(
      title: l10n.myProfileTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeader(user: user),
          SizedBox(height: tokens.space.xl2),
          _AccountDetails(user: user),
          SizedBox(height: tokens.space.xl2),
          _SignOutButton(),
        ],
      ),
    );
  }
}

/// Large tinted initials avatar + name + email. No photo upload, so initials
/// stand in for a picture.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = user.displayName.trim();
    final initials = _initialsFor(name, user.email);

    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: theme.textTheme.displaySmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: tokens.space.lg),
        Text(
          name.isNotEmpty ? name : user.email,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (name.isNotEmpty) ...[
          SizedBox(height: tokens.space.xs),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Read-only account facts, drawn as large rows inside one calm card.
class _AccountDetails extends StatelessWidget {
  const _AccountDetails({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);

    final rows = <Widget>[
      _DetailRow(
        icon: LucideIcons.user,
        label: l10n.myProfileName,
        value: user.displayName.trim().isNotEmpty
            ? user.displayName.trim()
            : '—',
      ),
      _DetailRow(
        icon: LucideIcons.mail,
        label: l10n.myProfileEmail,
        value: user.email.isNotEmpty ? user.email : '—',
      ),
      _DetailRow(
        icon: LucideIcons.shieldCheck,
        label: l10n.myProfileRole,
        value: _roleLabel(l10n, user.role),
      ),
      if (user.createdAt != null)
        _DetailRow(
          icon: LucideIcons.calendar,
          label: l10n.myProfileMemberSince,
          value: _formatMemberSince(context, user.createdAt!),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: tokens.space.xs, bottom: tokens.space.md),
          child: Text(
            l10n.myProfileAccountSection,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      minVerticalPadding: 12,
      minLeadingWidth: 40,
      leading: Icon(icon, size: 28, color: scheme.primary),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 15,
          color: scheme.onSurfaceVariant,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 60,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
            ),
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(LucideIcons.logOut, size: 24),
            label: Text(
              l10n.myProfileSignOut,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SizedBox(height: tokens.space.sm),
        Text(
          l10n.myProfileSignOutHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

String _roleLabel(AppLocalizations l10n, String role) {
  switch (role) {
    case 'admin':
      return l10n.myProfileRoleAdmin;
    case 'moderator':
      return l10n.myProfileRoleModerator;
    default:
      return l10n.myProfileRoleResident;
  }
}

String _formatMemberSince(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return intl.DateFormat.yMMMM(locale).format(date.toLocal());
}

String _initialsFor(String name, String email) {
  final source = name.isNotEmpty ? name : email;
  final parts = source
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return p.characters.take(2).toString().toUpperCase();
  }
  final first = parts.first.characters.first;
  final last = parts.last.characters.first;
  return '$first$last'.toUpperCase();
}
