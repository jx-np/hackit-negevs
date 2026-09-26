import 'dart:convert';

import 'scam_verdict.dart';

/// Conservative per-token estimate used when the runtime cannot count tokens.
/// Real tokenizers average ~4 characters per token for English, but a message
/// may carry CJK or symbols where a character can be a token, so this divides
/// by 3 to leave headroom rather than under-count.
int estimatePromptTokens(String text) => (text.length / 3).ceil();

/// Minimum context window that can hold a reasoning model's private thinking
/// block and still leave room for the JSON answer. Below this a thinking model
/// exhausts the KV cache mid-thought and never emits a readable verdict.
const int kMinThinkingContextTokens = 3000;

/// Tokens held back from the context window for the generated answer when the
/// runtime has no output cap (the MediaPipe `.task` path ignores
/// `maxOutputTokens`).
const int kReserveOutputTokens = 320;

/// Whether thinking should be enabled for a model with [contextTokens].
bool scamThinkingEnabled({
  required bool thinking,
  required int contextTokens,
}) =>
    thinking && contextTokens >= kMinThinkingContextTokens;

/// Tokens available for the prompt after reserving room for the answer. A
/// thinking model holds back half the window because its thinking block and the
/// answer share the same KV cache.
int scamInputTokenBudget({
  required bool thinking,
  required int contextTokens,
}) {
  final reserve =
      scamThinkingEnabled(thinking: thinking, contextTokens: contextTokens)
          ? contextTokens ~/ 2
          : kReserveOutputTokens;
  final budget = contextTokens - reserve;
  return budget < 128 ? 128 : budget;
}

/// Builds the classifier prompt. [compact] selects a short prompt for the
/// on-device model, whose context window is tiny (1024-1280 tokens total,
/// input plus output). The full prompt is kept for the cloud model, which has
/// ample context. Feeding the long prompt to a small on-device window starves
/// it of output room and produces no readable answer.
String buildScamPrompt({
  required String appLabel,
  required String sender,
  required String message,
  bool compact = false,
}) {
  if (compact) {
    return _compactScamPrompt(
      appLabel: appLabel,
      sender: sender,
      message: message,
    );
  }
  return _fullScamPrompt(
    appLabel: appLabel,
    sender: sender,
    message: message,
  );
}

String _compactScamPrompt({
  required String appLabel,
  required String sender,
  required String message,
}) {
  return '''
You are a conservative scam-message classifier. Reply with only one JSON object.

Default to "not_scam". Normal chat, group banter, jokes, plans, invitations, and ordinary business or service messages are not scams. A link, a money mention, or an unknown sender alone is not enough.

Mark a scam only when the message clearly contains deception plus a request, threat, or risky action. Categories:
- asks_app_install: asks to install an app/file or disable security.
- asks_credentials: asks for passwords, PINs, or one-time codes.
- urgent_threat: threatens or rushes you to force action.
- prize_lottery: claims a prize/win/refund and asks you to claim or pay.
- payment_request: suspiciously asks for money or payment details.
- impersonation: pretends to be a trusted person or organization.
- other_scam: clearly fraudulent but fits nothing above.
- not_scam: ordinary communication with no scam evidence.
- unsure: incomplete and cannot be classified.

Sender is only the sender's name, not message content. An unsaved international number (e.g. "+44 ...") is suspicious: when the message also asks, links, or pressures, prefer a scam label. A Message may be a chat log: each line "name: text" is one speaker, and those names are not scam signals.

Example:
App: Messages
Sender: +44 7700 900123
Message: "Your parcel is held. Pay 2.99 at bit.ly/xyz within 24h or it is returned."
{"label":"payment_request","confidence":0.96,"reason":"Urgent payment through a shortened link from an unsaved international number."}

Required format:
{"label":"<category>","confidence":<number between 0 and 1>,"reason":"<short reason>"}

App: $appLabel
Sender: $sender
Message: "$message"
JSON:
''';
}

String _fullScamPrompt({
  required String appLabel,
  required String sender,
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

The Message may be a chat log: several lines, each beginning with a speaker name, for example "natasha: where are we going ah". The speaker names are ordinary people in a conversation, not scam signals, and the words after the colon are what that person said. Casual group banter, jokes, plans, and stickers are not scams, even when many people are talking.

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
Give a short reason based only on words that actually appear in the message. Never mention a prize, link, phone number, account, or request that is not written there.
Reply with exactly one valid JSON object and nothing else.

The Sender line is only the name or number of whoever sent the message. It is not part of the message content, so never treat the sender name as an app, a link, or a request.

If the Sender is shown as an international phone number (for example "+44 7700 900123" or "+234 ..."), treat that as an aggravating factor. Judge such senders more harshly than a saved contact name: when the message also contains any request, link, payment, or urgency, prefer a scam label over "not_scam". Plain small talk from an international number may still be "not_scam".

Examples:

App: Discord
Sender: Alex
Message: "look at this meme lol"
{"label":"not_scam","confidence":0.99,"reason":"Normal social message with no request for money, credentials, or risky action."}

App: Messages
Sender: Mom
Message: "Can you send me 20 dollars for dinner?"
{"label":"not_scam","confidence":0.88,"reason":"A normal personal request for money with no clear evidence of fraud."}

App: Messages
Sender: +44 7700 900123
Message: "Your parcel is held. Pay 2.99 at bit.ly/xyz within 24h or it is returned."
{"label":"payment_request","confidence":0.96,"reason":"Requests urgent payment through a shortened link for a supposedly held parcel, from an unsaved international number."}

App: Messages
Sender: +1 202 555 0143
Message: "Hi, I got your number from a friend. Can you help me with a small transfer?"
{"label":"payment_request","confidence":0.82,"reason":"Unsaved international number asks for a money transfer."}

Required format:
{"label":"<category>","confidence":<number between 0 and 1>,"reason":"<short reason>"}

App: $appLabel
Sender: $sender
Message: "$message"
JSON:
''';
}

/// Closing markers of a reasoning model's private thinking block. Everything up
/// to and including the last one is discarded so only the final answer is
/// parsed.
const List<String> _thinkingEndMarkers = [
  '</' 'think>',
  '<｜end▁of▁thinking｜>',
];

/// LiteRT-LM streams a model's reasoning channel as literal markers:
/// `<|channel>thought` opens it and `<channel|>` closes it. A hybrid model such
/// as MiniCPM5 emits one open/close pair per streamed token, so the markers are
/// interleaved with every word instead of wrapping a single block. Dropping each
/// occurrence — including the newline the opener carries — restores the prose;
/// slicing at the last marker would throw the answer away with the thinking.
final RegExp _channelOpen = RegExp(r'<\|channel>thought\r?\n?');
const String _channelClose = '<channel|>';

String _stripChannelMarkers(String text) => text
    .replaceAll(_channelOpen, '')
    .replaceAll(_channelClose, '');

String _stripThinking(String text) {
  var result = text;
  for (final marker in _thinkingEndMarkers) {
    final index = result.lastIndexOf(marker);
    if (index >= 0) {
      result = result.substring(index + marker.length);
    }
  }
  return result;
}

/// Finds the last `{...}` object in [text] that decodes to a JSON map. Scanning
/// from the end keeps the model's final answer when prose or an unterminated
/// thinking block also contains braces — a greedy first-to-last match would
/// merge them into invalid JSON and lose the verdict. Each start brace is
/// tried against each closing brace after it (largest span first) so a literal
/// `}` inside the reason string does not break decoding.
Map<String, dynamic>? _lastJsonObject(String text) {
  for (var start = text.lastIndexOf('{');
      start >= 0;
      start = text.lastIndexOf('{', start - 1)) {
    for (var end = text.lastIndexOf('}');
        end > start;
        end = text.lastIndexOf('}', end - 1)) {
      try {
        final decoded = jsonDecode(text.substring(start, end + 1));
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
  }
  return null;
}

ScamVerdict parseScamVerdict(
  String raw, {
  required EvaluationSource source,
}) {
  final cleaned = _stripChannelMarkers(raw.trim());
  final answer = _stripThinking(cleaned);
  final decoded = _lastJsonObject(answer);
  if (decoded != null) {
    try {
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
    } catch (_) {}
  }
  return _keywordFallback(answer, source: source, raw: cleaned);
}

ScamVerdict _keywordFallback(
  String answer, {
  required EvaluationSource source,
  required String raw,
}) {
  final lower = answer.toLowerCase();
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
