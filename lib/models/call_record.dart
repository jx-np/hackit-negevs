class CallRecord {
  const CallRecord({
    this.id,
    required this.rawNumber,
    required this.normalizedNumber,
    required this.timestamp,
    required this.status,
    required this.direction,
    this.durationSeconds = 0,
    this.reported = false,
    this.reportReason,
    this.reportedAt,
    this.trustScore,
    this.trustRating,
    this.trustCheckedAt,
  });

  final int? id;
  final String rawNumber;
  final String normalizedNumber;
  final int timestamp;
  final String status;
  final String direction;
  final int durationSeconds;
  final bool reported;
  final String? reportReason;
  final int? reportedAt;

  /// Cached phone trust score (0-100) from the last lookup, or null if the
  /// number has never been checked. Persisted on the `calls` table so a known
  /// number isn't re-checked on every load.
  final int? trustScore;

  /// Cached trust rating from the last lookup: `high_risk`, `unknown`, or
  /// `trusted`. Null when never checked.
  final String? trustRating;

  /// When the trust score was last fetched (epoch millis), or null if never.
  final int? trustCheckedAt;

  static const String ratingHighRisk = 'high_risk';
  static const String ratingUnknown = 'unknown';
  static const String ratingTrusted = 'trusted';

  /// True when the cached rating marks this number as high risk.
  bool get isHighRisk => trustRating == ratingHighRisk;

  /// True once a trust lookup has been recorded for this number.
  bool get hasTrustCheck => trustRating != null;

  static const String statusAnswered = 'answered';
  static const String statusRejected = 'rejected';
  static const String statusMissed = 'missed';
  static const String statusBlocked = 'blocked';
  static const String statusUnknown = 'unknown';

  static const String directionIncoming = 'incoming';
  static const String directionOutgoing = 'outgoing';

  CallRecord copyWith({
    int? id,
    String? rawNumber,
    String? normalizedNumber,
    int? timestamp,
    String? status,
    String? direction,
    int? durationSeconds,
    bool? reported,
    String? reportReason,
    int? reportedAt,
    int? trustScore,
    String? trustRating,
    int? trustCheckedAt,
  }) {
    return CallRecord(
      id: id ?? this.id,
      rawNumber: rawNumber ?? this.rawNumber,
      normalizedNumber: normalizedNumber ?? this.normalizedNumber,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      reported: reported ?? this.reported,
      reportReason: reportReason ?? this.reportReason,
      reportedAt: reportedAt ?? this.reportedAt,
      trustScore: trustScore ?? this.trustScore,
      trustRating: trustRating ?? this.trustRating,
      trustCheckedAt: trustCheckedAt ?? this.trustCheckedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'raw_number': rawNumber,
      'normalized_number': normalizedNumber,
      'timestamp': timestamp,
      'status': status,
      'direction': direction,
      'duration_seconds': durationSeconds,
      'reported': reported ? 1 : 0,
      'report_reason': reportReason,
      'reported_at': reportedAt,
      'trust_score': trustScore,
      'trust_rating': trustRating,
      'trust_checked_at': trustCheckedAt,
    };
  }

  factory CallRecord.fromMap(Map<String, Object?> map) {
    return CallRecord(
      id: map['id'] as int?,
      rawNumber: (map['raw_number'] as String?) ?? '',
      normalizedNumber: (map['normalized_number'] as String?) ?? '',
      timestamp: (map['timestamp'] as int?) ?? 0,
      status: (map['status'] as String?) ?? statusUnknown,
      direction: (map['direction'] as String?) ?? directionIncoming,
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
      reported: ((map['reported'] as int?) ?? 0) == 1,
      reportReason: map['report_reason'] as String?,
      reportedAt: map['reported_at'] as int?,
      trustScore: map['trust_score'] as int?,
      trustRating: map['trust_rating'] as String?,
      trustCheckedAt: map['trust_checked_at'] as int?,
    );
  }
}
