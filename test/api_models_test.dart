import 'package:flutter_test/flutter_test.dart';
import 'package:scamwatch_mobile_app/api/api_exception.dart';
import 'package:scamwatch_mobile_app/models/api/auth_models.dart';
import 'package:scamwatch_mobile_app/models/api/community_models.dart';
import 'package:scamwatch_mobile_app/models/api/detection_models.dart';
import 'package:scamwatch_mobile_app/models/api/guidance_models.dart';

void main() {
  group('AuthUser.fromJson', () {
    test('parses full payload', () {
      final user = AuthUser.fromJson({
        'id': 42,
        'email': 'a@b.com',
        'display_name': 'Alice',
        'role': 'moderator',
        'locale': 'en-SG',
        'created_at': '2024-01-02T03:04:05Z',
      });
      expect(user.id, '42');
      expect(user.email, 'a@b.com');
      expect(user.displayName, 'Alice');
      expect(user.role, 'moderator');
      expect(user.isModerator, isTrue);
      expect(user.isAdmin, isFalse);
      expect(user.createdAt, isNotNull);
    });

    test('applies defaults for missing fields', () {
      final user = AuthUser.fromJson({'id': 1});
      expect(user.email, '');
      expect(user.role, 'resident');
      expect(user.locale, 'en-SG');
      expect(user.createdAt, isNull);
    });
  });

  group('AuthSession.fromJson', () {
    test('parses session with nested user', () {
      final session = AuthSession.fromJson({
        'user': {'id': 7, 'email': 'x@y.com'},
        'access_token': 'acc',
        'refresh_token': 'ref',
        'expires_in': 900,
      });
      expect(session.user.id, '7');
      expect(session.accessToken, 'acc');
      expect(session.refreshToken, 'ref');
      expect(session.expiresIn, 900);
    });

    test('defaults expiresIn to 900', () {
      final session = AuthSession.fromJson({'user': <String, dynamic>{}});
      expect(session.expiresIn, 900);
    });
  });

  group('FeedPost.fromJson', () {
    test('parses post with category and tags', () {
      final post = FeedPost.fromJson({
        'post_id': 10,
        'title': 'Fake bank SMS',
        'redacted_excerpt': 'Your account is locked...',
        'category': {'slug': 'phishing', 'name_key': 'scam.phishing'},
        'tags': [
          {'slug': 'bank', 'name_key': 'tag.bank'},
        ],
        'review_status': 'reviewed',
        'comment_count': 3,
      });
      expect(post.postId, '10');
      expect(post.title, 'Fake bank SMS');
      expect(post.category?.slug, 'phishing');
      expect(post.category?.displayName, 'Phishing');
      expect(post.tags.single.slug, 'bank');
      expect(post.isReviewed, isTrue);
      expect(post.commentCount, 3);
    });

    test('defaults review status and empty tags', () {
      final post = FeedPost.fromJson({'post_id': 11});
      expect(post.reviewStatus, 'unverified');
      expect(post.isReviewed, isFalse);
      expect(post.tags, isEmpty);
      expect(post.category, isNull);
      expect(post.commentCount, 0);
    });
  });

  group('PostDetail.fromJson', () {
    test('parses reactions and vote', () {
      final detail = PostDetail.fromJson({
        'post_id': 5,
        'title': 'Lottery scam',
        'redacted_text': 'You won...',
        'reactions': {'up': 4, 'down': 1},
        'my_vote': 1,
      });
      expect(detail.postId, '5');
      expect(detail.reactions.up, 4);
      expect(detail.reactions.down, 1);
      expect(detail.myVote, 1);
    });

    test('defaults reactions when missing', () {
      final detail = PostDetail.fromJson({'post_id': 6});
      expect(detail.reactions.up, 0);
      expect(detail.reactions.down, 0);
      expect(detail.myVote, 0);
    });
  });

  group('Paginated.fromJson', () {
    test('builds items and reports hasMore', () {
      final page = Paginated.fromJson(
        {
          'items': [
            {'slug': 'a', 'name_key': 'tag.a'},
            {'slug': 'b', 'name_key': 'tag.b'},
          ],
          'next_cursor': 'cursor123',
        },
        ScamTag.fromJson,
      );
      expect(page.items, hasLength(2));
      expect(page.items.first.slug, 'a');
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'cursor123');
    });

    test('empty cursor means no more pages', () {
      final page = Paginated.fromJson(
        {'items': const [], 'next_cursor': ''},
        ScamTag.fromJson,
      );
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });
  });

  group('DetectionResult.fromJson', () {
    test('parses ready verdict with signals and actions', () {
      final result = DetectionResult.fromJson({
        'check_id': 99,
        'status': 'ready',
        'verdict': 'suspicious',
        'assessment': {'limitations': 'Short text'},
        'signals': [
          {
            'code': 'urgency',
            'evidence_excerpt': 'act now',
            'explanation': 'Creates pressure',
          },
        ],
        'uncertainty': 'low',
        'recommended_actions': [
          {'scenario': 'clicked_link', 'title': 'Change password', 'urgency': 'urgent'},
        ],
        'similar_reports': [
          {'report_id': 1, 'excerpt': 'same scam', 'rationale': 'match'},
        ],
        'suggested_tags': ['bank', 'sms'],
      });
      expect(result.checkId, '99');
      expect(result.isReady, isTrue);
      expect(result.verdict, 'suspicious');
      expect(result.limitations, 'Short text');
      expect(result.signals.single.code, 'urgency');
      expect(result.recommendedActions.single.urgency, 'urgent');
      expect(result.similarReports.single.reportId, '1');
      expect(result.suggestedTags, ['bank', 'sms']);
    });

    test('defaults status to processing', () {
      final result = DetectionResult.fromJson({'check_id': 1});
      expect(result.isProcessing, isTrue);
      expect(result.signals, isEmpty);
    });
  });

  group('PhoneTrustScore.fromJson', () {
    test('parses stubbed unknown score', () {
      final score = PhoneTrustScore.fromJson({
        'phone_number': '+6591234567',
        'trust_score': 60,
        'rating': 'unknown',
        'report_count': 0,
        'known': false,
      });
      expect(score.phoneNumber, '+6591234567');
      expect(score.trustScore, 60);
      expect(score.rating, 'unknown');
      expect(score.isHighRisk, isFalse);
      expect(score.isTrusted, isFalse);
      expect(score.known, isFalse);
    });
  });

  group('GuidanceItem.fromJson', () {
    test('parses item with resources', () {
      final item = GuidanceItem.fromJson({
        'id': 3,
        'scenario': 'sent_money',
        'urgency': 'emergency',
        'title': 'Call your bank',
        'body': 'Contact them immediately.',
        'resources': [
          {
            'id': 8,
            'slug': 'police',
            'country_code': 'SG',
            'url': 'https://police.gov.sg',
            'name': 'Police',
          },
        ],
      });
      expect(item.id, '3');
      expect(item.isEmergency, isTrue);
      expect(item.resources.single.name, 'Police');
      expect(item.resources.single.hasUrl, isTrue);
    });
  });

  group('ApiException.fromResponse', () {
    test('parses standard error shape with fields', () {
      final error = ApiException.fromResponse(422, {
        'error': {
          'code': 'unprocessable_entity',
          'message': 'Some details were not valid.',
          'fields': {'email': 'already taken'},
        },
        'request_id': 'req-123',
      });
      expect(error.statusCode, 422);
      expect(error.code, 'unprocessable_entity');
      expect(error.message, 'Some details were not valid.');
      expect(error.fields['email'], 'already taken');
      expect(error.requestId, 'req-123');
      expect(error.isValidation, isTrue);
    });

    test('falls back to defaults when error body missing', () {
      final error = ApiException.fromResponse(401, const {});
      expect(error.code, 'unauthorized');
      expect(error.message, 'Please sign in again.');
      expect(error.isUnauthorized, isTrue);
      expect(error.fields, isEmpty);
    });

    test('network factory produces offline-friendly message', () {
      final error = ApiException.network(Exception('no route'));
      expect(error.statusCode, 0);
      expect(error.code, 'network_error');
      expect(error.message, contains('Could not reach the server'));
    });
  });
}
