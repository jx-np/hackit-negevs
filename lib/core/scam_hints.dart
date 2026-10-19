/// Cheap, reliable facts about a message, computed in Dart so the on-device
/// model only has to do the judgment part. The regexes are deliberately
/// conservative: a hint being set is a nudge, not a verdict.
///
/// Ported from the project's reference `HintBuilder` design. The hints are
/// rendered into the classifier prompt as the `Hints:` line.
library;

import 'contact_directory.dart';
import 'messaging_apps.dart';
import 'notification_record.dart';

/// The classification of a notification sender.
enum SenderType {
  savedContact('saved_contact'),
  unsavedLocal('unsaved_local'),
  unsavedInternational('unsaved_international'),
  shortCode('short_code'),
  name('name');

  const SenderType(this.wire);

  /// The token written into the prompt, e.g. `sender=unsaved_international`.
  final String wire;
}

/// The kind of link found in a message, if any.
enum LinkType {
  none('none'),
  normal('normal'),
  shortened('shortened'),
  oddTld('odd_tld'),

  /// The message is nothing but a single URL. A bare link with no surrounding
  /// text carries no ask or pressure, so on its own it is not evidence of a
  /// scam — even when the domain looks unusual.
  bareLinkOnly('bare_link_only');

  const LinkType(this.wire);

  final String wire;
}

/// A compact set of signals about one message. Only true signals are rendered
/// into the prompt so the model sees a short, high-signal line.
class ScamHints {
  const ScamHints({
    required this.senderType,
    required this.linkType,
    required this.asksForCode,
    required this.deliversCode,
    required this.apkOrRemoteApp,
    required this.urgency,
    required this.moneyAsk,
    required this.movesOffPlatform,
    required this.brandMentioned,
    required this.callbackRequest,
    required this.legalThreat,
    this.includeSender = true,
  });

  final SenderType senderType;
  final LinkType linkType;

  /// Whether [senderType] describes the sender of an SMS-like message. False
  /// for chat apps (Telegram, WhatsApp, Instagram, ...), where the notification
  /// title is a display name rather than a phone number or carrier sender ID.
  /// In that case no `sender=` token is rendered and the sender type never
  /// counts as a corroborating signal.
  final bool includeSender;

  /// "send me the OTP" — an ask for a secret code.
  final bool asksForCode;

  /// "Your code is 123456" — delivers a code, which is not an ask.
  final bool deliversCode;
  final bool apkOrRemoteApp;
  final bool urgency;
  final bool moneyAsk;

  /// Moves the conversation to Telegram / WhatsApp / t.me and similar.
  final bool movesOffPlatform;

  /// A bank / courier / government / big-brand name appears.
  final bool brandMentioned;

  /// "call this number" / "dial 1800..." — pushes you to phone a number, a
  /// common vishing / callback-fraud hook.
  final bool callbackRequest;

  /// Threatens police / court / arrest / warrant / lawsuit to scare you into
  /// acting — a classic authority-impersonation pressure tactic.
  final bool legalThreat;

  /// Compact string that goes into the prompt as `$hints`. Only true signals
  /// are listed, so an ordinary message renders just its sender type. Chat
  /// apps render no sender token at all, leaving `signals=0` for an ordinary
  /// message; the prompt treats a missing sender token as "chat app".
  String render() {
    final parts = <String>[];
    if (includeSender) parts.add('sender=${senderType.wire}');
    if (linkType != LinkType.none) parts.add('link=${linkType.wire}');
    if (asksForCode) parts.add('asks_for_code=yes');
    if (deliversCode) parts.add('delivers_code=yes');
    if (apkOrRemoteApp) parts.add('apk_or_remote_app=yes');
    if (urgency) parts.add('urgency=yes');
    if (moneyAsk) parts.add('money_ask=yes');
    if (movesOffPlatform) parts.add('moves_off_platform=yes');
    if (brandMentioned) parts.add('brand_mentioned=yes');
    if (callbackRequest) parts.add('callback_request=yes');
    if (legalThreat) parts.add('legal_threat=yes');
    parts.add('signals=$strongSignalCount');
    return parts.join(', ');
  }

  /// Counts the strong, independently-computed signals in these hints. Used by
  /// [shouldAlert] as a hard gate so a weak model cannot raise an alert on a
  /// message that carries no corroborating evidence.
  int get strongSignalCount => [
        asksForCode,
        apkOrRemoteApp,
        urgency,
        moneyAsk,
        movesOffPlatform,
        callbackRequest,
        legalThreat,
        linkType == LinkType.shortened,
        includeSender && senderType == SenderType.unsavedInternational,
      ].where((signal) => signal).length;

  /// Whether a verdict should actually raise an alert. The model's label and
  /// confidence are necessary but not sufficient: a small model misfires on
  /// short, vague or odd-looking messages, so an alert also requires high
  /// confidence AND at least two corroborating signals from the cheap local
  /// hints. `not_scam` and `unsure` never alert.
  bool shouldAlert(String label, double confidence) {
    if (label == 'not_scam' || label == 'unsure') return false;
    return confidence >= 0.8 && strongSignalCount >= 2;
  }

  /// True when there is nothing suspicious at all, so the caller may skip the
  /// model entirely and treat the message as not a scam. Chat apps have no
  /// meaningful sender type, so a display name — or a phone-number-shaped
  /// display name — counts as known and does not block the shortcut.
  bool looksTrivial() =>
      (!includeSender ||
          senderType == SenderType.savedContact ||
          senderType == SenderType.name) &&
      linkType == LinkType.none &&
      !asksForCode &&
      !apkOrRemoteApp &&
      !moneyAsk &&
      !movesOffPlatform;
}

/// Builds [ScamHints] from the cheap, local facts about a message.
class ScamHintBuilder {
  const ScamHintBuilder._();

  static final RegExp _shortener = RegExp(
    r'\b(bit\.ly|tinyurl\.com|t\.co|cutt\.ly|is\.gd|rb\.gy|shorturl\.at|ow\.ly|rebrandly\.com)/\S+',
    caseSensitive: false,
  );
  static final RegExp _oddTld = RegExp(
    r'\b[a-z0-9-]+(\.[a-z0-9-]+)*\.(top|xyz|click|icu|vip|cc|site|online|support|work)\b',
    caseSensitive: false,
  );
  static final RegExp _anyUrl = RegExp(
    r'(https?://|www\.)\S+',
    caseSensitive: false,
  );

  static final RegExp _asksCode = RegExp(
    r'\b(send|reply|share|tell|give|provide|forward|read)\b.{0,40}\b(otp|code|pin|password|passcode)\b',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _deliversCode = RegExp(
    r'\b(your|the)\b.{0,20}\b(otp|code|pin)\b.{0,10}\b(is|:)\s*\d{4,8}\b|\b\d{4,8}\b.{0,20}\b(is your|verification code)\b',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _apk = RegExp(
    r'\.apk\b|install (the |this )?(app|apk)|unknown sources|anydesk|teamviewer|quicksupport|remote (access|support)',
    caseSensitive: false,
  );
  static final RegExp _urgent = RegExp(
    r'\b(urgent|immediately|asap|last chance|final notice|within \d+\s?(h|hr|hrs|hours|min|minutes)|expires?|suspended|locked|blocked|legal action|arrest)\b',
    caseSensitive: false,
  );
  static final RegExp _money = RegExp(
    r'\b(pay|payment|fee|transfer|deposit|gift ?card|crypto|usdt|bitcoin|top.?up)\b|[$S]\$?\s?\d+',
    caseSensitive: false,
  );
  static final RegExp _offPlatform = RegExp(
    r'\b(telegram|t\.me|wa\.me|whatsapp|signal)\b',
    caseSensitive: false,
  );

  // "call this number", "call 1800...", "dial", "please call back on ..." — a
  // push to phone a number, the hook in callback / vishing fraud.
  static final RegExp _callback = RegExp(
    r'\b(call|dial|phone|ring)\b.{0,20}\b(back|now|us|this number|immediately|\d{3,})\b|\bcall\s+(?:on\s+)?[+(]?\d',
    caseSensitive: false,
    dotAll: true,
  );

  // police / court / arrest / warrant / lawsuit threats used to scare the
  // recipient into complying — classic authority-impersonation pressure.
  static final RegExp _legalThreat = RegExp(
    r'\b(police|court|arrest(ed)?|warrant|lawsuit|summons|subpoena|prosecut\w*|legal action|law ?suit|detain\w*|deportation)\b',
    caseSensitive: false,
  );

  // Market-specific brand list. Scammers copy local names, so this leans toward
  // the Singapore/SEA market the app targets.
  static final RegExp _brands = RegExp(
    r'\b(dbs|ocbc|uob|posb|singpost|dhl|fedex|ica|iras|cpf|singpass|spf|lazada|shopee|grab|netflix|paypal|apple|amazon)\b',
    caseSensitive: false,
  );

  /// Computes hints for a message. [isSavedContact] comes from the device
  /// contacts; [homeCountryCode] marks which `+` prefix counts as local.
  /// [isSmsSender] is false for chat apps, whose notification title is a
  /// display name: the sender hint is then omitted entirely. It defaults to
  /// true so direct callers keep the SMS behaviour.
  static ScamHints build({
    required String sender,
    required String message,
    required bool isSavedContact,
    String homeCountryCode = '+65',
    bool isSmsSender = true,
  }) {
    final senderType = _senderType(
      sender: sender,
      isSavedContact: isSavedContact,
      homeCountryCode: homeCountryCode,
    );

    // A message that is just a single URL (one whitespace-delimited token) is
    // flagged as a bare link rather than by its TLD, so an odd domain on its
    // own does not nudge the model toward a scam. A shortener still wins because
    // hidden destinations are a stronger signal than the surrounding text.
    final isBareLink = _anyUrl.hasMatch(message) &&
        message.trim().split(RegExp(r'\s+')).length == 1;
    final LinkType linkType;
    if (_shortener.hasMatch(message)) {
      linkType = LinkType.shortened;
    } else if (isBareLink) {
      linkType = LinkType.bareLinkOnly;
    } else if (_oddTld.hasMatch(message)) {
      linkType = LinkType.oddTld;
    } else if (_anyUrl.hasMatch(message)) {
      linkType = LinkType.normal;
    } else {
      linkType = LinkType.none;
    }

    return ScamHints(
      senderType: senderType,
      linkType: linkType,
      asksForCode: _asksCode.hasMatch(message),
      deliversCode: _deliversCode.hasMatch(message),
      apkOrRemoteApp: _apk.hasMatch(message),
      urgency: _urgent.hasMatch(message),
      moneyAsk: _money.hasMatch(message),
      movesOffPlatform: _offPlatform.hasMatch(message),
      brandMentioned: _brands.hasMatch(message),
      callbackRequest: _callback.hasMatch(message),
      legalThreat: _legalThreat.hasMatch(message),
      includeSender: isSmsSender,
    );
  }

  static SenderType _senderType({
    required String sender,
    required bool isSavedContact,
    required String homeCountryCode,
  }) {
    final trimmed = sender.trim();
    if (isSavedContact) return SenderType.savedContact;
    if (trimmed.startsWith('+') && !trimmed.startsWith(homeCountryCode)) {
      return SenderType.unsavedInternational;
    }
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (trimmed.startsWith('+') || digits.length >= 7) {
      return SenderType.unsavedLocal;
    }
    // A purely numeric, short sender is a carrier short code (e.g. "8841").
    final isAllDigits =
        trimmed.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(trimmed);
    if (isAllDigits && trimmed.length <= 6) return SenderType.shortCode;
    // An alphanumeric sender ID like "MyBank".
    return SenderType.name;
  }

  /// Computes hints for a notification. The saved-contact flag is resolved from
  /// the device contacts: a sender that is not a phone-looking string and
  /// matches a contact name, or a number that maps to a saved contact, counts
  /// as saved. Contact lookup failures (no permission, etc.) degrade to
  /// "not saved" rather than throwing.
  ///
  /// Only SMS-style apps get a sender hint. For a chat app the title is the
  /// other user's display name, so the contacts are not consulted at all and
  /// no `sender=` token is produced.
  static Future<ScamHints> fromRecord(
    NotificationRecord record, {
    String homeCountryCode = '+65',
  }) async {
    final isSms = isSmsApp(record.packageName);
    final sender = record.title.trim();
    final isSaved = isSms ? await _isSavedContact(sender) : false;
    return build(
      sender: sender,
      message: record.content,
      isSavedContact: isSaved,
      homeCountryCode: homeCountryCode,
      isSmsSender: isSms,
    );
  }

  static Future<bool> _isSavedContact(String sender) async {
    if (sender.isEmpty) return false;
    try {
      // A name-style sender (e.g. "Mom") is saved when it matches a contact.
      if (!ContactDirectory.looksLikePhone(sender)) {
        final phone = await ContactDirectory.phoneForName(sender);
        return phone != null;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
