enum ScamLabel {
  asksAppInstall('asks_app_install'),
  asksCredentials('asks_credentials'),
  urgentThreat('urgent_threat'),
  prizeLottery('prize_lottery'),
  paymentRequest('payment_request'),
  impersonation('impersonation'),
  otherScam('other_scam'),
  abusive('abusive'),
  notScam('not_scam'),
  unsure('unsure');

  const ScamLabel(this.wire);

  final String wire;

  static ScamLabel fromWire(String? value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return ScamLabel.unsure;
    for (final label in ScamLabel.values) {
      if (label.wire == normalized) return label;
      if (_normalize(label.name) == normalized) return label;
    }
    // Aliases for out-of-vocabulary labels the model invents when it ignores
    // the label list: synonyms ("scam", "fraud", "safe") and hint names it
    // echoes back as a verdict (see `callback_request` below). Resolving them
    // keeps a high-confidence verdict alerting instead of decaying to
    // `unsure`, which suppresses the alert entirely.
    final alias = _aliases[normalized];
    if (alias != null) return alias;
    return ScamLabel.unsure;
  }

  /// Lowercases and collapses anything that is not a letter or digit into a
  /// single underscore, so `"Not Scam"`, `"not-scam"` and `"NOT_SCAM"` all
  /// normalize to the same key.
  static String _normalize(String? value) => (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  static const Map<String, ScamLabel> _aliases = {
    // Hint name some models echo back as a label; the observed cases all
    // describe a benign "call me back" message, so it is not a scam.
    'callback_request': ScamLabel.notScam,
    // Scam synonyms.
    'scam': ScamLabel.otherScam,
    'likely_scam': ScamLabel.otherScam,
    'scam_likely': ScamLabel.otherScam,
    'confirmed_scam': ScamLabel.otherScam,
    'definite_scam': ScamLabel.otherScam,
    'fraud': ScamLabel.otherScam,
    'fraudulent': ScamLabel.otherScam,
    'phishing': ScamLabel.otherScam,
    'phishing_scam': ScamLabel.otherScam,
    'spam': ScamLabel.otherScam,
    'suspicious': ScamLabel.otherScam,
    // Safe synonyms.
    'safe': ScamLabel.notScam,
    'legit': ScamLabel.notScam,
    'legitimate': ScamLabel.notScam,
    'benign': ScamLabel.notScam,
    'no_scam': ScamLabel.notScam,
    'not_a_scam': ScamLabel.notScam,
    'not_scam_message': ScamLabel.notScam,
    // Rude or offensive text that asks for nothing: shown, never alerted.
    'abuse': ScamLabel.abusive,
    'abusive_language': ScamLabel.abusive,
    'offensive': ScamLabel.abusive,
    'offensive_language': ScamLabel.abusive,
    'profanity': ScamLabel.abusive,
    'harassment': ScamLabel.abusive,
    'hate_speech': ScamLabel.abusive,
  };

  bool get isScam =>
      this != ScamLabel.notScam &&
      this != ScamLabel.abusive &&
      this != ScamLabel.unsure;

  String get title => switch (this) {
        ScamLabel.asksAppInstall => 'Asks you to install an app',
        ScamLabel.asksCredentials => 'Asks for passwords or codes',
        ScamLabel.urgentThreat => 'Threatens or rushes you',
        ScamLabel.prizeLottery => 'Fake prize or lottery',
        ScamLabel.paymentRequest => 'Asks for a payment',
        ScamLabel.impersonation => 'Pretends to be someone you trust',
        ScamLabel.otherScam => 'Looks like a scam',
        ScamLabel.abusive => 'Rude language, not a scam',
        ScamLabel.notScam => 'Looks legitimate',
        ScamLabel.unsure => 'Cannot tell for sure',
      };
}

enum EvaluationSource {
  local('local'),
  remote('remote');

  const EvaluationSource(this.wire);

  final String wire;

  static EvaluationSource fromWire(String? value) {
    for (final source in EvaluationSource.values) {
      if (source.wire == value) return source;
    }
    return EvaluationSource.local;
  }
}

class ScamVerdict {
  const ScamVerdict({
    required this.label,
    required this.confidence,
    required this.reason,
    required this.source,
    this.escalated = false,
    this.raw = '',
  });

  const ScamVerdict.unsure({
    this.source = EvaluationSource.local,
    this.reason = 'No verdict produced',
  })  : label = ScamLabel.unsure,
        confidence = 0.0,
        escalated = false,
        raw = '';

  final ScamLabel label;
  final double confidence;
  final String reason;
  final EvaluationSource source;
  final bool escalated;
  final String raw;

  bool get isScam => label.isScam;

  bool get shouldAlert => isScam && confidence >= 0.5;

  ScamVerdict copyWith({
    ScamLabel? label,
    double? confidence,
    String? reason,
    EvaluationSource? source,
    bool? escalated,
    String? raw,
  }) {
    return ScamVerdict(
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      source: source ?? this.source,
      escalated: escalated ?? this.escalated,
      raw: raw ?? this.raw,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label.wire,
        'confidence': confidence,
        'reason': reason,
        'source': source.wire,
        'escalated': escalated,
        'raw': raw,
      };

  static ScamVerdict fromJson(Map<String, dynamic> json) => ScamVerdict(
        label: ScamLabel.fromWire(json['label'] as String?),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        reason: json['reason'] as String? ?? '',
        source: EvaluationSource.fromWire(json['source'] as String?),
        escalated: json['escalated'] as bool? ?? false,
        raw: json['raw'] as String? ?? '',
      );

  @override
  String toString() =>
      'ScamVerdict(${label.wire}, conf=${confidence.toStringAsFixed(2)}, '
      'source=${source.wire}, escalated=$escalated)';
}
