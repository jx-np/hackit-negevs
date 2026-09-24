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
    );
  }
}
