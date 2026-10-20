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
  name('name'),

  /// Singapore carriers relabel every unregistered sender ID "Likely-SCAM", so
  /// the real sender is unknown and real brands land here too. It says nothing
  /// about the text, so it is shown but never counted as a signal.
  unregistered('unregistered_id');

  const SenderType(this.wire);

  /// The token written into the prompt, e.g. `sender=unsaved_international`.
  final String wire;
}

final RegExp _likelyScamLabel = RegExp(
  r'^\W*likely[\s_-]*scam\W*$',
  caseSensitive: false,
);

/// Whether [sender] is the carrier's "Likely-SCAM" header for unregistered SMS
/// sender IDs rather than a real sender name.
bool isLikelyScamLabel(String sender) => _likelyScamLabel.hasMatch(sender.trim());

/// The kind of link found in a message, if any.
enum LinkType {
  none('none'),
  normal('normal'),
  shortened('shortened'),
  oddTld('odd_tld'),

  /// The message is nothing but a single URL. On its own it carries no ask, but
  /// it is still a link, and in a thread it is usually the payload of an
  /// earlier "click now" style hook.
  bareLinkOnly('bare_link_only');

  const LinkType(this.wire);

  final String wire;
}

/// A recognisable scam script the message follows, rendered as `lure=<wire>`.
/// One value per message (first match wins) keeps the hints line short while
/// still pointing the model at the right label.
enum LureType {
  none('none', counts: false),

  /// Task / commission / part-time job hook.
  job('job'),

  /// Prize, lottery, voucher or refund you must claim.
  prize('prize'),

  /// Guaranteed returns, trading or crypto groups.
  invest('invest'),

  /// Unsolicited fast loan or credit offer.
  loan('loan'),

  /// Account alert wording (unauthorised login, suspended, delivery fee). Real
  /// banks and couriers use it too, so it is shown but not counted as a signal.
  account('account', counts: false),

  /// "Hi mum, this is my new number" openers. Family really do this, so it is
  /// shown but not counted as a signal.
  newNumber('new_number', counts: false);

  const LureType(this.wire, {this.counts = true});

  final String wire;

  /// Whether this lure adds one to the signal count.
  final bool counts;
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
    this.phoneInBody = false,
    this.callToAction = false,
    this.secrecy = false,
    this.lure = LureType.none,
    this.priorSignals = 0,
    this.eventCues = 0,
    this.includeSender = true,
    this.isGroup = false,
  });

  /// Every link counts this many signals. Links are the payload of nearly every
  /// phishing message, so one outweighs any single text-only tell.
  static const int linkWeight = 2;

  final SenderType senderType;
  final LinkType linkType;

  /// Whether [senderType] describes the sender of an SMS-like message. False
  /// for chat apps (Telegram, WhatsApp, Instagram, ...), where the notification
  /// title is a display name rather than a phone number or carrier sender ID.
  /// In that case no `sender=` token is rendered and the sender type never
  /// counts as a corroborating signal.
  final bool includeSender;

  /// The message came from a group chat. Rendered as `group_chat=yes` so the
  /// model reads a favour or bill split among several people as ordinary chat.
  /// It never counts as a signal.
  final bool isGroup;

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

  /// Threatens police / court / arrest / warrant / lawsuit, or uses a
  /// government-official script ("safe account", "money laundering"), to scare
  /// you into acting — a classic authority-impersonation pressure tactic.
  final bool legalThreat;

  /// A phone number appears in the body. Weak on its own (companies list their
  /// own), but it is the usual payload of a callback or WhatsApp lure.
  final bool phoneInBody;

  /// "click now", "tap here", "verify now" — an imperative aimed at a link.
  final bool callToAction;

  /// "don't tell anyone", "keep this confidential", "do not hang up".
  final bool secrecy;

  /// The scam script the message follows, if any.
  final LureType lure;

  /// Signals found in EARLIER messages of the same thread that this message
  /// does not repeat (a link counts [linkWeight]). Zero for a one-off message
  /// and for saved contacts. It is already included in [strongSignalCount].
  final int priorSignals;

  /// How many of the three event cues (event word, date/time, venue) appear in
  /// a message long enough to be a real notice. See [announcement].
  final int eventCues;

  /// A community / event notice (workshop, meet-up, sign-up call) that carries
  /// no scam signal at all: no money, code, install, urgency, callback, odd or
  /// shortened link, or brand name. A plain link is allowed because sign-up
  /// forms are normal. It is positive evidence for the model that a sign-up
  /// link or deadline here is ordinary, not a lure. It is a nudge, not a
  /// verdict.
  bool get announcement =>
      eventCues >= 2 &&
      messageSignalCount == 0 &&
      priorSignals == 0 &&
      !brandMentioned &&
      !deliversCode &&
      (linkType == LinkType.none || linkType == LinkType.normal);

  /// Code found nothing a scam could use: no tell, link, lure or phone number
  /// in this message or its thread. A scam label from the model on such a
  /// message is treated as a misread of ordinary chat and downgraded.
  bool get noScamEvidence =>
      strongSignalCount == 0 && lure == LureType.none && !phoneInBody;

  /// The sender line for the prompt. A chat app's notification title is a
  /// username or "account:name" header, not a sender identity, and the model
  /// read it as impersonation. The app label already names the app, so chat
  /// apps get a neutral placeholder instead. A phone-number title is kept,
  /// since an unknown number is real sender evidence.
  String promptSender(String title) =>
      includeSender || ContactDirectory.looksLikePhone(title.trim())
          ? title
          : 'chat user';

  /// Compact string that goes into the prompt as `$hints`. Only true signals
  /// are listed, so an ordinary message renders just its sender type. Chat
  /// apps render no sender token at all, leaving `signals=0` for an ordinary
  /// message; the prompt treats a missing sender token as "chat app".
  String render() {
    final parts = <String>[];
    if (includeSender) parts.add('sender=${senderType.wire}');
    if (isGroup) parts.add('group_chat=yes');
    if (linkType != LinkType.none) parts.add('link=${linkType.wire}');
    if (asksForCode) parts.add('asks_for_code=yes');
    if (deliversCode) parts.add('delivers_code=yes');
    if (apkOrRemoteApp) parts.add('apk_or_remote_app=yes');
    if (urgency) parts.add('urgency=yes');
    if (moneyAsk) parts.add('money_ask=yes');
    if (movesOffPlatform) parts.add('moves_off_platform=yes');
    if (brandMentioned && strongSignalCount > 0) {
      parts.add('brand_mentioned=yes');
    }
    if (callbackRequest) parts.add('callback_request=yes');
    if (legalThreat) parts.add('legal_threat=yes');
    if (phoneInBody) parts.add('phone_in_body=yes');
    if (callToAction) parts.add('cta=yes');
    if (secrecy) parts.add('secrecy=yes');
    if (lure != LureType.none) parts.add('lure=${lure.wire}');
    if (announcement) parts.add('announcement=yes');
    if (priorSignals > 0) parts.add('prior_signals=$priorSignals');
    parts.add('signals=$strongSignalCount');
    return parts.join(', ');
  }

  /// The distinct text-only signals in this message, by name. Used for the
  /// count and to tell which tells an earlier message adds to the thread.
  Set<String> get _signalKeys => {
        if (asksForCode) 'asks_for_code',
        if (apkOrRemoteApp) 'apk',
        if (urgency) 'urgency',
        if (moneyAsk) 'money',
        if (movesOffPlatform) 'off_platform',
        if (callbackRequest) 'callback',
        if (legalThreat) 'legal',
        if (callToAction) 'cta',
        if (secrecy) 'secrecy',
        if (lure.counts) 'lure',
        if (includeSender && senderType == SenderType.unsavedInternational)
          'sender',
      };

  /// Signals from this message alone, links excluded.
  int get messageSignalCount => _signalKeys.length;

  /// Counts the strong, independently-computed signals in these hints. This is
  /// rendered as `signals=N` for the model, which uses it as one more piece of
  /// evidence. It does not gate alerts: the model's scam label is enough to
  /// raise one. Any link counts [linkWeight] signals, and tells found in
  /// earlier messages of the thread are added through [priorSignals].
  int get strongSignalCount =>
      messageSignalCount +
      (linkType == LinkType.none ? 0 : linkWeight) +
      priorSignals;

  /// Same hints with [priorSignals] set.
  ScamHints withPriorSignals(int count) => ScamHints(
        senderType: senderType,
        linkType: linkType,
        asksForCode: asksForCode,
        deliversCode: deliversCode,
        apkOrRemoteApp: apkOrRemoteApp,
        urgency: urgency,
        moneyAsk: moneyAsk,
        movesOffPlatform: movesOffPlatform,
        brandMentioned: brandMentioned,
        callbackRequest: callbackRequest,
        legalThreat: legalThreat,
        phoneInBody: phoneInBody,
        callToAction: callToAction,
        secrecy: secrecy,
        lure: lure,
        priorSignals: count,
        eventCues: eventCues,
        includeSender: includeSender,
        isGroup: isGroup,
      );

  /// True when there is nothing suspicious at all, so the caller may skip the
  /// model entirely and treat the message as not a scam. Chat apps have no
  /// meaningful sender type, so a display name — or a phone-number-shaped
  /// display name — counts as known and does not block the shortcut.
  bool looksTrivial() =>
      (!includeSender ||
          senderType == SenderType.savedContact ||
          senderType == SenderType.unregistered ||
          senderType == SenderType.name) &&
      linkType == LinkType.none &&
      !asksForCode &&
      !apkOrRemoteApp &&
      !moneyAsk &&
      !movesOffPlatform &&
      priorSignals == 0;
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
    r"(?<!\b(?:not|never|don.t|dont|cannot|can.t)\s)(?<!\b(?:not|never|don.t|dont)\s+(?:ever|to)\s)\b(send|reply|share|tell|give|provide|forward|read)\b.{0,40}\b(otp|codes?|pin|password|passcode)\b",
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _deliversCode = RegExp(
    r'\b(your|the)\b.{0,20}\b(otp|code|pin)\b.{0,10}\b(is|:)\s*\d{4,8}\b|\b\d{4,8}\b.{0,20}\b(is your|verification code)\b',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _apk = RegExp(
    r'\.apk\b|install (the |this )?(app|apk)|unknown sources|anydesk|teamviewer|quicksupport|remote (access|support)|screen.?shar\w*',
    caseSensitive: false,
  );
  static final RegExp _urgent = RegExp(
    r'\b(urgent(ly)?|immediately|asap|last chance|final notice|final warning|last warning|act now|overdue|within \d+\s?(h|hr|hrs|hours|min|minutes)|expires?|suspended|locked|blocked|legal action|arrest)\b',
    caseSensitive: false,
  );
  // Money that is a scam tell on its own. A currency amount needs an explicit
  // marker ($50, S$50, SGD 50): a bare "s" followed by a digit ("has 5 slots")
  // must not count as money.
  static final RegExp _moneyStrong = RegExp(
    r'\b(gift ?cards?|crypto|usdt|bitcoin)\b',
    caseSensitive: false,
  );
  static final RegExp _moneyAmount = RegExp(
    r'\$\s?\d|\bsgd\s?\d',
    caseSensitive: false,
  );
  // Friends settling a debt: "pay me back $20", "you owe me $20", "I owe you
  // $15". An amount in such a sentence is chat. "You owe $450 in fines" and
  // "we owe you a refund" are not matched on purpose.
  static final RegExp _peerSettle = RegExp(
    r"\bpay(ing)?\s+(me|him|her|them|us|you|u|ya)\s+back\b|\b(you|u|ya)\s+(?:still\s+|also\s+|already\s+|now\s+)?(?:owe|own)\s+(?:me|us)\b|\bowe[sd]?\s+(?:me|us)\b|\bi\s+(?:still\s+)?owe\s+(?:you|u)\b|\bi(?:'ll|'d| will)\s+pay\s+(you|u|ya)\b",
    caseSensitive: false,
  );
  // Payment words that only count as an ask in the right sentence, see
  // [_hasMoneyAsk].
  static final RegExp _moneyWord = RegExp(
    r'\b(pay|payment|fee|transfer|deposit|top.?up)\b',
    caseSensitive: false,
  );
  // Friends settling up: "I'll pay", "we pay you", "pay me back".
  static final RegExp _peerPay = RegExp(
    r"\b(i|we)(?:'ll|'d|'m| will| can| shall)?\s+pay\b|\bpay\s+(you|u|ya)\b|\bpay(ing)?\s+(me|him|her|them|us)\s+back\b",
    caseSensitive: false,
  );
  static final RegExp _question = RegExp(
    r'\?|\b(can|could|would|will|should|shall)\s+(you|i|we|u)\b|^\W*(where|how|when|what|do|did|is|are)\b',
    caseSensitive: false,
  );
  static final RegExp _sentenceBreak = RegExp(r'(?<=[!?\n])|(?<=\.)(?=\s)');

  /// A strong money tell anywhere, or a payment word in a sentence that is a
  /// concrete ask: it carries a number, or it is a statement rather than a
  /// question. "Where can I pay you" and "can you pay me back" are chat;
  /// "pay the customs fee" and "can you pay the 50 fee?" are asks.
  static bool _hasMoneyAsk(String message) {
    if (_moneyStrong.hasMatch(message)) return true;
    for (final sentence in message.split(_sentenceBreak)) {
      if (_peerSettle.hasMatch(sentence)) continue;
      if (_moneyAmount.hasMatch(sentence)) return true;
      if (!_moneyWord.hasMatch(sentence) || _peerPay.hasMatch(sentence)) {
        continue;
      }
      if (sentence.contains(RegExp(r'\d')) || !_question.hasMatch(sentence)) {
        return true;
      }
    }
    return false;
  }

  // "click here", "tap now", "verify now", "open the link" — an imperative
  // aimed at a link, the usual first half of a two-message lure.
  static final RegExp _cta = RegExp(
    r'\b(click|tap)\b.{0,15}\b(here|now|link|below|this)\b|\bopen (the |this )?link\b|\b(verify|confirm|update|log ?in|claim|track|re-?schedule)\s+(now|here|today|immediately|below)\b',
    caseSensitive: false,
    dotAll: true,
  );

  // A phone number in the body: international (+65 8123 4567), SG mobile or
  // landline (8123 4567), toll-free (1800 123 4567) or a 0-prefixed number.
  // Letters or dots on either side rule out reference codes and decimals.
  static final RegExp _phoneNumber = RegExp(
    r'(?<![\w.])(?:\+\d[\d\s-]{7,16}\d|0\d{9,10}|1[389]00[\s-]?\d{3}[\s-]?\d{3,4}|[3689]\d{3}[\s-]?\d{4})(?!\w)',
  );

  // "don't tell anyone", "keep this confidential", "do not hang up" — scripts
  // that isolate the victim from family, bank and police.
  static final RegExp _secrecy = RegExp(
    r'\b(do not|dont|don.t)\s+(tell|inform|disclose)\b.{0,25}\b(anyone|family|bank|police|staff)\b|\bkeep (this|it)\b.{0,10}\b(confidential|secret|private)\b|\bconfidential (case|matter)\b|\bdo not hang up\b',
    caseSensitive: false,
    dotAll: true,
  );

  // Scam scripts. Each is checked in the order of [_lure]; the first match wins.
  static final RegExp _lureJob = RegExp(
    r'\bpart.?time (job|work|role)\b|\bwork from home\b|\b(simple|easy) (task|job|work)s?\b|\bcommission\b|\bno experience\b|\bearn\b.{0,30}\b(a day|per day|daily|per hour|hourly)\b|\b(liking|boosting|rating)\b.{0,20}\b(videos?|products?|shops?|pages?)\b',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _lurePrize = RegExp(
    r"\b(you|u)(['’]?ve|\s+have)?\s+won\b|\bcongratulations\b.{0,40}\b(claim|selected|winner|prize)\b|\bclaim your\b|\b(tax )?refund\b|\brebate\b|\b(cdc|gst) voucher\b|\blucky (draw|winner)\b|\bunclaimed\b|\bcash prize\b",
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _lureInvest = RegExp(
    r'\bguaranteed (returns?|profits?|income)\b|\b(daily|weekly|monthly) (returns?|profits?|roi)\b|\b(trading|investment|vip|stock) (group|signals?|platform|tips|expert)\b|\bdouble your\b|\bhigh returns?\b',
    caseSensitive: false,
  );
  static final RegExp _lureLoan = RegExp(
    r'\b(instant|fast|quick) (loan|approval|cash)\b|\bpre.?approved\b|\bloan\b.{0,25}\b(approved|offer|available)\b|\bno (credit )?check\b|\blow interest\b|\bdebt consolidation\b',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _lureNewNumber = RegExp(
    r'\bhi (mum|mom|dad|mama|papa)\b|\bnew number\b|\b(lost|broke|broken|dropped|cracked) my (phone|sim)\b|\bsave (this|my)( new)? number\b|\bwrong number\b',
    caseSensitive: false,
  );
  static final RegExp _lureAccount = RegExp(
    r'\bunauthori[sz]ed\b|\bunusual (login|activity|sign.?in)\b|\bverify your (identity|account|details|information)\b|\baccount\b.{0,25}\b(suspend|lock|block|restrict|deactivat|compromis)\w*|\b(toll|fine|parcel|delivery|redelivery|customs|shipping) fee\b|\bunpaid\b|\bsecurity alert\b',
    caseSensitive: false,
    dotAll: true,
  );

  // Event-notice cues. Any two of these in a longer message, with no scam
  // signal at all, mark an ordinary community announcement.
  static final RegExp _eventWord = RegExp(
    r'\b(workshop|seminar|webinar|meet-?up|talk|session|event|class|lesson|tournament|orientation|briefing|bazaar|gathering|rehearsal|training|camp|hackathon|meeting|rsvp)\b',
    caseSensitive: false,
  );
  static final RegExp _dateTime = RegExp(
    r'\b\d{1,2}([.:]\d{2})?\s?(am|pm)\b|\b\d{1,2}(st|nd|rd|th)?\s(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\b|\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    caseSensitive: false,
  );
  static final RegExp _venue = RegExp(
    r'\b(location|venue|room|hall|blk|block|studio|library|auditorium|campus)\b|#\d{1,3}-\d{1,3}',
    caseSensitive: false,
  );

  // Shortest message that can carry a real event notice; a one-line "join our
  // event" lure stays below it.
  static const int _announcementMinLength = 60;

  // Most signals a thread can add on top of the current message, so a long
  // chatty history cannot swamp the count.
  static const int _maxPriorSignals = 4;

  static final RegExp _offPlatform = RegExp(
    r'\b(t\.me|wa\.me)\b|\b(add|message|msg|text|contact|chat|dm|reach|join|ping|talk|write)\b.{0,30}\b(telegram|whatsapp|signal)\b|\b(telegram|whatsapp|signal)\b.{0,15}(@\w|\+?\d{5,})',
    dotAll: true,
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

  // Government-official impersonation script: a "crime" tied to your identity,
  // then a "safe account" to move money into.
  static final RegExp _officialScript = RegExp(
    r'\b(safe(ty)?|security) account\b|\bmoney laundering\b|\bunder investigation\b|\b(nric|identity|particulars)\b.{0,25}\b(misused|linked|involved)\b',
    caseSensitive: false,
    dotAll: true,
  );

  // Market-specific brand list. Scammers copy local names, so this leans toward
  // the Singapore/SEA market the app targets.
  static final RegExp _brands = RegExp(
    r'\b(dbs|ocbc|uob|posb|maybank|hsbc|citibank|singpost|dhl|fedex|j&t|ninja ?van|ica|iras|cpf|singpass|spf|lta|hdb|ntuc|singtel|starhub|lazada|shopee|qoo10|carousell|foodpanda|grab|netflix|paypal|apple|amazon)\b',
    caseSensitive: false,
  );

  /// Computes hints for a message. [isSavedContact] comes from the device
  /// contacts; [homeCountryCode] marks which `+` prefix counts as local.
  /// [isSmsSender] is false for chat apps, whose notification title is a
  /// display name: the sender hint is then omitted entirely. It defaults to
  /// true so direct callers keep the SMS behaviour.
  ///
  /// [priorMessages] are earlier messages of the same thread. Tells in them
  /// that [message] does not repeat are added to the signal count, so a
  /// "click now" followed by a bare link scores as one scam. They are ignored
  /// for saved contacts.
  static ScamHints build({
    required String sender,
    required String message,
    required bool isSavedContact,
    String homeCountryCode = '+65',
    bool isSmsSender = true,
    List<String> priorMessages = const [],
    bool isGroup = false,
  }) {
    final hints = _buildSingle(
      sender: sender,
      message: message,
      isSavedContact: isSavedContact,
      homeCountryCode: homeCountryCode,
      isSmsSender: isSmsSender,
      isGroup: isGroup,
    );
    // Earlier group messages come from other speakers, so pooling their tells
    // would pin one person's link on another's harmless reply.
    if (priorMessages.isEmpty || isGroup) return hints;
    final prior = _priorSignalCount(
      hints,
      priorMessages,
      sender: sender,
      isSavedContact: isSavedContact,
      homeCountryCode: homeCountryCode,
      isSmsSender: isSmsSender,
    );
    return prior == 0 ? hints : hints.withPriorSignals(prior);
  }

  static ScamHints _buildSingle({
    required String sender,
    required String message,
    required bool isSavedContact,
    required String homeCountryCode,
    required bool isSmsSender,
    bool isGroup = false,
  }) {
    final senderType = _senderType(
      sender: sender,
      isSavedContact: isSavedContact,
      homeCountryCode: homeCountryCode,
    );

    // A message that is just a single URL (one whitespace-delimited token) is
    // flagged as a bare link rather than by its TLD, so the model can see there
    // is no surrounding text. A shortener still wins because hidden
    // destinations are a stronger signal than the surrounding text.
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

    final deliversCode = _deliversCode.hasMatch(message);

    return ScamHints(
      senderType: senderType,
      linkType: linkType,
      asksForCode: _asksCode.hasMatch(message),
      deliversCode: deliversCode,
      apkOrRemoteApp: _apk.hasMatch(message),
      urgency: _urgent.hasMatch(message),
      moneyAsk: _hasMoneyAsk(message),
      movesOffPlatform: _offPlatform.hasMatch(message),
      brandMentioned: _brands.hasMatch(message),
      callbackRequest: _callback.hasMatch(message),
      legalThreat:
          _legalThreat.hasMatch(message) || _officialScript.hasMatch(message),
      // An 8-digit one-time code looks like a phone number; a message that
      // delivers a code is not advertising a number.
      phoneInBody: !deliversCode && _phoneNumber.hasMatch(message),
      callToAction: _cta.hasMatch(message),
      secrecy: _secrecy.hasMatch(message),
      lure: _lure(message),
      eventCues: _eventCues(message),
      includeSender: isSmsSender,
      isGroup: isGroup,
    );
  }

  static LureType _lure(String message) {
    if (_lureJob.hasMatch(message)) return LureType.job;
    if (_lurePrize.hasMatch(message)) return LureType.prize;
    if (_lureInvest.hasMatch(message)) return LureType.invest;
    if (_lureLoan.hasMatch(message)) return LureType.loan;
    if (_lureNewNumber.hasMatch(message)) return LureType.newNumber;
    if (_lureAccount.hasMatch(message)) return LureType.account;
    return LureType.none;
  }

  /// Signals the earlier messages add beyond [current]: each distinct text
  /// tell once, plus [ScamHints.linkWeight] when an earlier message carried a
  /// link and the current one does not. Zero for a saved contact, whose chat
  /// history should never accumulate into an alarm.
  static int _priorSignalCount(
    ScamHints current,
    List<String> priorMessages, {
    required String sender,
    required bool isSavedContact,
    required String homeCountryCode,
    required bool isSmsSender,
  }) {
    if (current.includeSender && current.senderType == SenderType.savedContact) {
      return 0;
    }
    final seen = <String>{};
    var priorLink = false;
    for (final prior in priorMessages) {
      final hints = _buildSingle(
        sender: sender,
        message: prior,
        isSavedContact: isSavedContact,
        homeCountryCode: homeCountryCode,
        isSmsSender: isSmsSender,
      );
      seen.addAll(hints._signalKeys);
      if (hints.linkType != LinkType.none) priorLink = true;
    }
    // The sender is the same on every turn, so it is not new evidence.
    seen.remove('sender');
    seen.removeAll(current._signalKeys);
    var total = seen.length;
    if (priorLink && current.linkType == LinkType.none) {
      total += ScamHints.linkWeight;
    }
    return total > _maxPriorSignals ? _maxPriorSignals : total;
  }

  static int _eventCues(String message) {
    if (message.trim().length < _announcementMinLength) return 0;
    return [_eventWord, _dateTime, _venue]
        .where((cue) => cue.hasMatch(message))
        .length;
  }

  static SenderType _senderType({
    required String sender,
    required bool isSavedContact,
    required String homeCountryCode,
  }) {
    final trimmed = sender.trim();
    if (isSavedContact) return SenderType.savedContact;
    if (isLikelyScamLabel(trimmed)) return SenderType.unregistered;
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
  /// SMS-style apps get a sender hint resolved against the contacts. WhatsApp
  /// also gets one, read from the title alone: it shows the saved contact name,
  /// or the bare number when the sender is not saved. Other chat apps get no
  /// `sender=` token, since their title is a display name with no number behind
  /// it.
  ///
  /// [priorMessages] are earlier messages of the same thread (see [build]).
  static Future<ScamHints> fromRecord(
    NotificationRecord record, {
    String homeCountryCode = '+65',
    List<String> priorMessages = const [],
  }) async {
    final group = record.isGroup;
    // A group title names the group, not the speaker, so it says nothing about
    // whether the sender is saved: groups get no sender hint at all.
    final isSms = !group && isSmsApp(record.packageName);
    final byPhone = !group && identifiesByPhone(record.packageName);
    final sender = record.title.trim();
    // WhatsApp shows the saved contact name, or the bare number when the
    // sender is not in the contacts, so the title alone tells which it is.
    final isSaved = isSms
        ? await _isSavedContact(sender)
        : byPhone
            ? sender.isNotEmpty && !ContactDirectory.looksLikePhone(sender)
            : false;
    return build(
      sender: sender,
      message: record.content,
      isSavedContact: isSaved,
      homeCountryCode: homeCountryCode,
      isSmsSender: isSms || byPhone,
      priorMessages: priorMessages,
      isGroup: group,
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
