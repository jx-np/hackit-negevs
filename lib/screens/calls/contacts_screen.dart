import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_tokens.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_screen.dart';
import '../../widgets/ui/empty_state.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> _contacts = [];
  bool _isLoading = false;
  String? _error;
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        setState(() {
          _error = l10n.contactsPermRequired;
          _isLoading = false;
        });
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        sorted: true,
        deduplicateProperties: true,
      );
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _filteredContacts = List.from(contacts);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _error = l10n.callsContactsLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = List.from(_contacts);
      } else {
        _filteredContacts = _contacts
            .where((contact) {
              final displayName = contact.displayName.toLowerCase();
              final phones = contact.phones
                  .where((phone) =>
                      phone.number.toLowerCase().contains(query.toLowerCase()))
                  .toList();
              return displayName.contains(query.toLowerCase()) ||
                  phones.isNotEmpty;
            })
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScreen(
      title: l10n.contactsTitle,
      scrollable: false,
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.refreshCw),
          tooltip: l10n.commonRefresh,
          onPressed: _loadContacts,
        ),
      ],
      body: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _filterContacts,
            decoration: InputDecoration(
              hintText: l10n.contactsSearchHint,
              prefixIcon: const Icon(LucideIcons.search),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: context.tokens.radii.mdRadius,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          SizedBox(height: context.tokens.space.sm),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: LucideIcons.circleAlert,
            tint: Theme.of(context).colorScheme.error,
            title: l10n.contactsCouldNotLoad,
            message: _error,
            action: Padding(
              padding: EdgeInsets.only(top: context.tokens.space.lg),
              child: FilledButton(
                onPressed: _loadContacts,
                child: Text(l10n.commonRetry),
              ),
            ),
          ),
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return EmptyState(
        icon: LucideIcons.users,
        title: l10n.contactsNoneFound,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(
        top: context.tokens.space.sm,
        bottom: context.tokens.space.xl2,
      ),
      itemCount: _filteredContacts.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: context.tokens.space.md),
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return AppCard(
          padding: EdgeInsets.symmetric(
            horizontal: context.tokens.space.lg,
            vertical: context.tokens.space.md,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitials(contact.displayName),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.tokens.space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.tokens.space.xs),
                    Text(
                      _getContactDetails(contact),
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (contact.phones.isNotEmpty)
                IconButton(
                  onPressed: () => _callNumber(contact.phones.first.number),
                  icon: Icon(LucideIcons.phone, color: scheme.primary),
                  tooltip: AppLocalizations.of(context).callsCallTooltip,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    return parts[0][0].toUpperCase();
  }

  String _getContactDetails(Contact contact) {
    final details = <String>[];

    if (contact.phones.isNotEmpty) {
      for (final phone in contact.phones) {
        if (phone.number.isNotEmpty) {
          details.add(phone.number);
        }
      }
    }

    if (contact.emails.isNotEmpty) {
      for (final email in contact.emails) {
        if (email.address.isNotEmpty) {
          details.add(email.address);
        }
      }
    }

    final l10n = AppLocalizations.of(context);
    return details.isNotEmpty ? details.join(' • ') : l10n.contactsNoDetails;
  }

  void _callNumber(String number) async {
    try {
      final uri = Uri.parse('tel:$number');
      if (!mounted) return;
      final result = await launchUrl(uri);
      if (!result) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.contactsCouldNotCall)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contactsCouldNotCall)),
      );
    }
  }
}
