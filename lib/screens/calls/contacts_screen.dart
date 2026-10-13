import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:url_launcher/url_launcher.dart';

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
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _error = l10n.contactsLoadFailed(e.toString());
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
    return FScaffold(
      header: FHeader.nested(
        title: Text(l10n.contactsTitle),
        titleAlignment: Alignment.centerLeft,
        prefixes: [
          FHeaderAction(
            icon: const Icon(Icons.menu),
            semanticsLabel: l10n.contactsOpenMenu,
            onPress: () => Scaffold.of(context).openDrawer(),
          ),
        ],
        suffixes: [
          FHeaderAction(
            icon: const Icon(Icons.refresh),
            semanticsLabel: l10n.commonRefresh,
            onPress: _loadContacts,
          ),
        ],
      ),
      child: Column(
        children: [
          FTextField(
            control: FTextFieldControl.managed(
              controller: _searchController,
              onChange: (value) => _filterContacts(value.text),
            ),
            hint: l10n.contactsSearchHint,
            prefixBuilder: (context, style, variants) =>
                FTextField.prefixIconBuilder(
                  context,
                  style,
                  variants,
                  context.theme.icons.search(context),
                ),
          ),
          const SizedBox(height: 8),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FAlert(
                variant: FAlertVariant.destructive,
                title: Text(l10n.contactsCouldNotLoad),
                subtitle: Text(_error!),
              ),
              const SizedBox(height: 16),
              FButton(onPress: _loadContacts, child: Text(l10n.commonRetry)),
            ],
          ),
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(child: Text(l10n.contactsNoneFound));
    }

    return FTileGroup.builder(
      count: _filteredContacts.length,
      tileBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return FTile(
          prefix: FAvatar.raw(
            size: 40,
            child: Text(_getInitials(contact.displayName)),
          ),
          title: Text(contact.displayName),
          subtitle: Text(_getContactDetails(contact)),
          suffix: contact.phones.isNotEmpty
              ? FButton.icon(
                  onPress: () => _callNumber(contact.phones.first.number),
                  variant: FButtonVariant.ghost,
                  size: FButtonSizeVariant.sm,
                  child: const Icon(Icons.phone),
                )
              : null,
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
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contactsCouldNotCallError(e.toString()))),
      );
    }
  }
}
