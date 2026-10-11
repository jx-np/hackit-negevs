class DetectionSignal {
  const DetectionSignal({
    required this.code,
    required this.evidenceExcerpt,
    required this.explanation,
  });

  final String code;
  final String evidenceExcerpt;
  final String explanation;

  factory DetectionSignal.fromJson(Map<String, dynamic> json) {
    return DetectionSignal(
      code: (json['code'] as String?) ?? '',
      evidenceExcerpt: (json['evidence_excerpt'] as String?) ?? '',
      explanation: (json['explanation'] as String?) ?? '',
    );
  }
}

class RecommendedAction {
  const RecommendedAction({
    required this.scenario,
    required this.title,
    required this.urgency,
  });

  final String scenario;
  final String title;
  final String urgency;

  factory RecommendedAction.fromJson(Map<String, dynamic> json) {
    return RecommendedAction(
      scenario: (json['scenario'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      urgency: (json['urgency'] as String?) ?? 'normal',
    );
  }
}

class SimilarReport {
  const SimilarReport({
    required this.reportId,
    required this.excerpt,
    required this.rationale,
    required this.reviewStatus,
  });

  final String reportId;
  final String excerpt;
  final String rationale;
  final String reviewStatus;

  factory SimilarReport.fromJson(Map<String, dynamic> json) {
    return SimilarReport(
      reportId: '${json['report_id']}',
      excerpt: (json['excerpt'] as String?) ?? '',
      rationale: (json['rationale'] as String?) ?? '',
      reviewStatus: (json['review_status'] as String?) ?? 'unverified',
    );
  }
}

class DetectionResult {
  const DetectionResult({
    required this.checkId,
    required this.status,
    this.verdict,
    this.limitations,
    this.signals = const [],
    this.uncertainty,
    this.recommendedActions = const [],
    this.similarReports = const [],
    this.suggestedTags = const [],
    this.createdAt,
  });

  final String checkId;
  final String status;
  final String? verdict;
  final String? limitations;
  final List<DetectionSignal> signals;
  final String? uncertainty;
  final List<RecommendedAction> recommendedActions;
  final List<SimilarReport> similarReports;
  final List<String> suggestedTags;
  final DateTime? createdAt;

  bool get isReady => status == 'ready';
  bool get isProcessing => status == 'processing';
  bool get isFailed => status == 'failed';

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    final assessment = json['assessment'];
    final created = json['created_at'];
    return DetectionResult(
      checkId: '${json['check_id']}',
      status: (json['status'] as String?) ?? 'processing',
      verdict: json['verdict'] as String?,
      limitations: assessment is Map ? assessment['limitations'] as String? : null,
      signals: _list(json['signals'], DetectionSignal.fromJson),
      uncertainty: json['uncertainty'] as String?,
      recommendedActions:
          _list(json['recommended_actions'], RecommendedAction.fromJson),
      similarReports: _list(json['similar_reports'], SimilarReport.fromJson),
      suggestedTags: (json['suggested_tags'] as List?)
              ?.map((e) => '$e')
              .toList(growable: false) ??
          const [],
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }

  static List<T> _list<T>(
    Object? raw,
    T Function(Map<String, dynamic>) build,
  ) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(build)
        .toList(growable: false);
  }
}

class PhoneTrustScore {
  const PhoneTrustScore({
    required this.phoneNumber,
    required this.trustScore,
    required this.rating,
    required this.reportCount,
    required this.known,
  });

  final String phoneNumber;
  final int trustScore;
  final String rating;
  final int reportCount;
  final bool known;

  bool get isHighRisk => rating == 'high_risk';
  bool get isTrusted => rating == 'trusted';

  factory PhoneTrustScore.fromJson(Map<String, dynamic> json) {
    return PhoneTrustScore(
      phoneNumber: (json['phone_number'] as String?) ?? '',
      trustScore: (json['trust_score'] as num?)?.toInt() ?? 60,
      rating: (json['rating'] as String?) ?? 'unknown',
      reportCount: (json['report_count'] as num?)?.toInt() ?? 0,
      known: (json['known'] as bool?) ?? false,
    );
  }
}
