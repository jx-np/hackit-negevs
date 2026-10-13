import '../../api/api_client.dart';
import '../../models/api/community_models.dart';
import '../../models/api/detection_models.dart';

class DetectionService {
  DetectionService(this._client);

  final ApiClient _client;

  Future<DetectionResult> checkText({
    required String text,
    String locale = 'en-SG',
  }) async {
    final response = await _client.post(
      '/detection',
      body: {
        'text': text,
        'locale': locale,
      },
    );
    return DetectionResult.fromJson(response.json);
  }

  Future<DetectionResult> checkScreenshot({
    required String uploadId,
    String locale = 'en-SG',
  }) async {
    final response = await _client.post(
      '/detection',
      body: {
        'upload_id': uploadId,
        'locale': locale,
      },
    );
    return DetectionResult.fromJson(response.json);
  }

  Future<DetectionResult> get(String checkId) async {
    final response = await _client.get('/detection/$checkId');
    return DetectionResult.fromJson(response.json);
  }

  Future<Paginated<DetectionResult>> history({
    int? limit,
    String? cursor,
  }) async {
    final response = await _client.get(
      '/me/detection',
      query: {
        'limit': ?limit,
        'cursor': ?cursor,
      },
    );
    return Paginated.fromJson(response.json, DetectionResult.fromJson);
  }

  Future<void> recordResourceOpen({
    required String checkId,
    required String resourceId,
    String? guidanceId,
  }) async {
    await _client.post(
      '/detection/$checkId/resource-opens',
      body: {
        'resource_id': resourceId,
        'guidance_id': ?guidanceId,
      },
    );
  }

  Future<PhoneTrustScore> phoneTrustScore(String phoneNumber) async {
    final response = await _client.get(
      '/detection/phone-number/trust-score',
      query: {'phone_number': phoneNumber},
    );
    return PhoneTrustScore.fromJson(response.json);
  }

  Future<void> reportPhoneNumber({
    required String phoneNumber,
    required String reason,
  }) async {
    await _client.post(
      '/detection/phone-number/report',
      body: {
        'phone_number': phoneNumber,
        'reason': reason,
      },
    );
  }
}
