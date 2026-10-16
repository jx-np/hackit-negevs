import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/api/community_models.dart';
import '../../models/api/detection_models.dart';

/// Raised before hitting the network when a chosen file fails the `/uploads`
/// contract (unsupported media type or over the 10 MiB cap). Mirrors the
/// server's `422`/`413` so callers can treat it like any other [ApiException].
class UploadValidationException extends ApiException {
  UploadValidationException({
    required super.statusCode,
    required super.code,
    required super.message,
  });

  factory UploadValidationException.unsupportedType() =>
      UploadValidationException(
        statusCode: 422,
        code: 'unprocessable_entity',
        message: 'That image type is not supported. Use JPEG, PNG, or WebP.',
      );

  factory UploadValidationException.tooLarge() => UploadValidationException(
        statusCode: 413,
        code: 'payload_too_large',
        message: 'That image is larger than 10 MB.',
      );
}

class DetectionService {
  DetectionService(this._client);

  final ApiClient _client;

  /// Allowed upload media types, per `POST /uploads`.
  static final Map<String, MediaType> _allowedTypes = {
    'jpg': MediaType('image', 'jpeg'),
    'jpeg': MediaType('image', 'jpeg'),
    'png': MediaType('image', 'png'),
    'webp': MediaType('image', 'webp'),
  };

  /// 10 MiB, matching the server's hard limit.
  static const int maxUploadBytes = 10 * 1024 * 1024;

  /// Uploads a screenshot to `POST /uploads` and returns the created [Upload].
  ///
  /// Uploading automatically schedules a detection check, so there is no need
  /// to call [checkScreenshot] afterwards — poll [get] with the returned
  /// [Upload.checkId] until its status is `ready` or `failed`. An optional
  /// [locale] tunes the analysis.
  ///
  /// Validates the media type and size client-side first so an obviously bad
  /// file never leaves the device; the server remains the source of truth and
  /// its `413`/`422` responses surface as [ApiException]s too.
  ///
  /// Although the server tolerates anonymous uploads, the created detection
  /// check can only be polled back via the owner-only `GET /detection/{id}`
  /// endpoint. An anonymous upload therefore produces a check the signed-in
  /// poller can never read ("check not found"). To avoid that mismatch, this
  /// refuses to upload unless a bearer token is physically present (not just
  /// the `isSignedIn` UI flag) and throws a clear `401` otherwise. Pass
  /// [requireAuth] `false` only for a genuinely fire-and-forget anonymous
  /// upload that is never polled.
  Future<Upload> uploadImage(
    File file, {
    String? locale,
    bool requireAuth = true,
  }) async {
    if (requireAuth && !await _client.hasAccessToken()) {
      throw ApiException(
        statusCode: 401,
        code: 'unauthorized',
        message: 'Sign in before attaching photos so we can analyze them.',
      );
    }

    final int length = await file.length();
    if (length > maxUploadBytes) {
      throw UploadValidationException.tooLarge();
    }

    // Resolve the media type from the extension first; if that's missing or
    // unrecognised (e.g. image_picker hands back a cache path with no/odd
    // extension), sniff the file's leading bytes. Only reject when we still
    // can't recognise a supported image, so valid JPEG/PNG/WebP uploads aren't
    // dropped over a cosmetic filename quirk.
    final String ext = _extension(file.path);
    MediaType? mediaType = _allowedTypes[ext];
    mediaType ??= await _sniffMediaType(file);
    if (mediaType == null) {
      throw UploadValidationException.unsupportedType();
    }

    final String filename = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'upload.${mediaType.subtype}';

    final multipartFile = http.MultipartFile(
      'image',
      file.openRead(),
      length,
      filename: filename,
      contentType: mediaType,
    );

    final response = await _client.multipart(
      '/uploads',
      files: {'image': multipartFile},
      fields: {'locale': ?locale},
    );
    return Upload.fromJson(response.json);
  }

  static String _extension(String path) {
    final int dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }

  /// Detects a supported image type from the file's leading bytes (magic
  /// numbers) when the extension is missing or unrecognised. Returns null if
  /// the content isn't a JPEG, PNG, or WebP. This keeps uploads working for
  /// picker cache paths that drop or mangle the extension.
  static Future<MediaType?> _sniffMediaType(File file) async {
    final List<int> head;
    try {
      final raf = await file.open();
      try {
        head = await raf.read(16);
      } finally {
        await raf.close();
      }
    } catch (_) {
      return null;
    }
    if (head.length < 12) return null;

    // JPEG: FF D8 FF
    if (head[0] == 0xFF && head[1] == 0xD8 && head[2] == 0xFF) {
      return MediaType('image', 'jpeg');
    }
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (head[0] == 0x89 &&
        head[1] == 0x50 &&
        head[2] == 0x4E &&
        head[3] == 0x47 &&
        head[4] == 0x0D &&
        head[5] == 0x0A &&
        head[6] == 0x1A &&
        head[7] == 0x0A) {
      return MediaType('image', 'png');
    }
    // WebP: "RIFF" .... "WEBP"
    if (head[0] == 0x52 &&
        head[1] == 0x49 &&
        head[2] == 0x46 &&
        head[3] == 0x46 &&
        head[8] == 0x57 &&
        head[9] == 0x45 &&
        head[10] == 0x42 &&
        head[11] == 0x50) {
      return MediaType('image', 'webp');
    }
    return null;
  }

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
