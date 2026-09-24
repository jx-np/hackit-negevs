enum ScamLabel {
  asksAppInstall('asks_app_install'),
  asksCredentials('asks_credentials'),
  urgentThreat('urgent_threat'),
  prizeLottery('prize_lottery'),
  paymentRequest('payment_request'),
  impersonation('impersonation'),
  otherScam('other_scam'),
  notScam('not_scam'),
  unsure('unsure');

  const ScamLabel(this.wire);

  final String wire;

  static ScamLabel fromWire(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final label in ScamLabel.values) {
      if (label.wire == normalized) return label;
      if (label.name.toLowerCase() == normalized) return label;
    }
    return ScamLabel.unsure;
  }

  bool get isScam =>
      this != ScamLabel.notScam && this != ScamLabel.unsure;

  String get title => switch (this) {
        ScamLabel.asksAppInstall => 'Asks you to install an app',
        ScamLabel.asksCredentials => 'Asks for passwords or codes',
        ScamLabel.urgentThreat => 'Threatens or rushes you',
        ScamLabel.prizeLottery => 'Fake prize or lottery',
        ScamLabel.paymentRequest => 'Asks for a payment',
        ScamLabel.impersonation => 'Pretends to be someone you trust',
        ScamLabel.otherScam => 'Looks like a scam',
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
