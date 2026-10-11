import '../../api/api_client.dart';
import '../../models/api/community_models.dart';
import '../../models/api/guidance_models.dart';

class GuidanceService {
  GuidanceService(this._client);

  final ApiClient _client;

  Future<List<GuidanceItem>> guidance({
    String? scenario,
    String? locale,
  }) async {
    final response = await _client.get(
      '/guidance',
      query: {
        'scenario': ?scenario,
        'locale': ?locale,
      },
    );
    return response.list
        .whereType<Map<String, dynamic>>()
        .map(GuidanceItem.fromJson)
        .toList(growable: false);
  }

  Future<List<HelpResource>> resources({
    String? country,
    String? scenario,
    String? locale,
  }) async {
    final response = await _client.get(
      '/guidance/resources',
      query: {
        'country': ?country,
        'scenario': ?scenario,
        'locale': ?locale,
      },
    );
    return response.list
        .whereType<Map<String, dynamic>>()
        .map(HelpResource.fromJson)
        .toList(growable: false);
  }

  Future<List<ScamCategory>> scamTypes() async {
    final response = await _client.get('/community/scam-types', auth: false);
    return response.list
        .whereType<Map<String, dynamic>>()
        .map(ScamCategory.fromJson)
        .toList(growable: false);
  }

  Future<List<ScamTag>> tags({String? query, int? limit}) async {
    final response = await _client.get(
      '/community/tags',
      query: {
        'q': ?query,
        'limit': ?limit,
      },
      auth: false,
    );
    return response.list
        .whereType<Map<String, dynamic>>()
        .map(ScamTag.fromJson)
        .toList(growable: false);
  }
}
