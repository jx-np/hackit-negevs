import 'dart:convert';

import 'scam_verdict.dart';

String buildScamPrompt({
  required String appLabel,
  required String message,
}) {
  return '''
You are a conservative scam-message classifier.

Classify only the message content. Do not judge whether it is appropriate, unusual, romantic, rude, or suitable for the app.

Use "not_scam" by default. Casual conversations, group chats, plans, jokes, invitations, names, and normal business or service messages are not scams.

Do not infer a scam merely because the message:
- mentions money, a link, a parcel, an account, or a specific person;
- comes from an unknown sender;
- asks a normal favor;
- uses unusual or informal wording.

Mark a message as a scam only when it clearly contains deception plus a suspicious request, threat, or risky action.

Categories:
- asks_app_install: asks to install an APK, unknown app/file, or disable security.
- asks_credentials: asks for passwords, PINs, one-time codes, or sensitive account details.
- urgent_threat: threatens account closure, legal action, fines, arrest, or loss of access to force urgent action.
- prize_lottery: claims an unexpected prize, lottery win, reward, or refund and asks the user to claim it, pay, or provide information.
- payment_request: suspiciously asks for money, fees, transfers, gift cards, cryptocurrency, or payment details.
- impersonation: pretends to be a trusted person or organization to obtain money, credentials, codes, or sensitive action.
- other_scam: clearly fraudulent but does not fit another category.
- not_scam: ordinary or legitimate communication with no clear scam evidence.
- unsure: use only when the message is incomplete and cannot reasonably be classified.

If the message is ambiguous but has no clear scam signal, choose "not_scam".
Give a short reason based only on evidence in the message. Do not invent facts.
Reply with exactly one valid JSON object and nothing else.

Examples:

App: Discord
Message: "look at this meme lol"
{"label":"not_scam","confidence":0.99,"reason":"Normal social message with no request for money, credentials, or risky action."}

App: Messages
Message: "Can you send me 20 dollars for dinner?"
{"label":"not_scam","confidence":0.88,"reason":"A normal personal request for money with no clear evidence of fraud."}

App: Messages
Message: "Your parcel is held. Pay 2.99 at bit.ly/xyz within 24h or it is returned."
{"label":"payment_request","confidence":0.96,"reason":"Requests urgent payment through a shortened link for a supposedly held parcel."}

Required format:
{"label":"<category>","confidence":<number between 0 and 1>,"reason":"<short reason>"}

App: $appLabel
Message: "$message"
JSON:
''';
}

final RegExp _jsonObjectPattern = RegExp(r'\{[\s\S]*\}');

ScamVerdict parseScamVerdict(
  String raw, {
  required EvaluationSource source,
}) {
  final cleaned = raw.trim();
  final match = _jsonObjectPattern.firstMatch(cleaned);
  if (match != null) {
    try {
      final decoded = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      final label = ScamLabel.fromWire(decoded['label'] as String?);
      final confidence = (decoded['confidence'] as num?)?.toDouble() ?? 0.0;
      final reason = (decoded['reason'] as String?)?.trim() ?? '';
      return ScamVerdict(
        label: label,
        confidence: confidence.clamp(0.0, 1.0),
        reason: reason.isNotEmpty ? reason : label.title,
        source: source,
        raw: cleaned,
      );
    } catch (_) {
      return _keywordFallback(cleaned, source: source);
    }
  }
  return _keywordFallback(cleaned, source: source);
}

ScamVerdict _keywordFallback(
  String raw, {
  required EvaluationSource source,
}) {
  final lower = raw.toLowerCase();
  for (final label in ScamLabel.values) {
    if (lower.contains(label.wire)) {
      return ScamVerdict(
        label: label,
        confidence: 0.35,
        reason: label.title,
        source: source,
        raw: raw,
      );
    }
  }
  return ScamVerdict(
    label: ScamLabel.unsure,
    confidence: 0.0,
    reason: 'Could not read the model output',
    source: source,
    raw: raw,
  );
}
