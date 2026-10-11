class HelpResource {
  const HelpResource({
    required this.id,
    required this.slug,
    required this.countryCode,
    this.url,
    this.contactInstructions,
    required this.name,
    this.description,
    this.verifiedAt,
    this.ownerName,
  });

  final String id;
  final String slug;
  final String countryCode;
  final String? url;
  final String? contactInstructions;
  final String name;
  final String? description;
  final DateTime? verifiedAt;
  final String? ownerName;

  bool get hasUrl => (url ?? '').trim().isNotEmpty;
  bool get hasContact => (contactInstructions ?? '').trim().isNotEmpty;

  factory HelpResource.fromJson(Map<String, dynamic> json) {
    final verified = json['verified_at'];
    return HelpResource(
      id: '${json['id']}',
      slug: (json['slug'] as String?) ?? '',
      countryCode: (json['country_code'] as String?) ?? 'SG',
      url: json['url'] as String?,
      contactInstructions: json['contact_instructions'] as String?,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      verifiedAt: verified is String ? DateTime.tryParse(verified) : null,
      ownerName: json['owner_name'] as String?,
    );
  }
}

class GuidanceItem {
  const GuidanceItem({
    required this.id,
    required this.scenario,
    required this.urgency,
    required this.title,
    required this.body,
    this.resources = const [],
  });

  final String id;
  final String scenario;
  final String urgency;
  final String title;
  final String body;
  final List<HelpResource> resources;

  bool get isEmergency => urgency == 'emergency';
  bool get isUrgent => urgency == 'urgent';

  factory GuidanceItem.fromJson(Map<String, dynamic> json) {
    final raw = json['resources'];
    final resources = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(HelpResource.fromJson)
            .toList(growable: false)
        : <HelpResource>[];
    return GuidanceItem(
      id: '${json['id']}',
      scenario: (json['scenario'] as String?) ?? '',
      urgency: (json['urgency'] as String?) ?? 'normal',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      resources: resources,
    );
  }
}
