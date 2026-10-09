import 'package:flutter_contacts/flutter_contacts.dart';

/// Resolves the phone number behind a notification sender.
///
/// Unknown senders surface as a bare number on some apps (WhatsApp) and as a
/// display name on others (Telegram). Reporting a number is more useful than
/// reporting the app, so try the sender string itself first, then the device
/// contacts, and fall back to the app when neither yields a number.
class ContactDirectory {
  ContactDirectory._();

  static List<Contact>? _contacts;
  static Future<List<Contact>?>? _loading;

  static bool looksLikePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final stripped = trimmed.replaceAll(RegExp(r'[\s+\-().]'), '');
    if (stripped.length < 5) return false;
    return RegExp(r'^[0-9]+$').hasMatch(stripped);
  }

  static Future<String?> phoneForName(String name) async {
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return null;
    final contacts = await _loadContacts();
    if (contacts == null) return null;
    for (final contact in contacts) {
      if (contact.displayName.trim().toLowerCase() != wanted) continue;
      for (final phone in contact.phones) {
        final number = phone.number.trim();
        if (number.isNotEmpty) return number;
      }
    }
    return null;
  }

  static Future<List<Contact>?> _loadContacts() async {
    final cached = _contacts;
    if (cached != null) return cached;
    final pending = _loading;
    if (pending != null) return pending;
    final future = _readContacts();
    _loading = future;
    try {
      final result = await future;
      _contacts = result;
      return result;
    } finally {
      _loading = null;
    }
  }

  static Future<List<Contact>?> _readContacts() async {
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) return null;
      return await FlutterContacts.getContacts(
        withProperties: true,
        sorted: true,
        deduplicateProperties: true,
      );
    } catch (_) {
      return null;
    }
  }
}
