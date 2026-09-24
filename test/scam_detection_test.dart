import 'package:flutter_test/flutter_test.dart';
import 'package:call_log_app/core/notification_record.dart';
import 'package:call_log_app/core/scam_prompt.dart';
import 'package:call_log_app/core/scam_verdict.dart';
import 'package:call_log_app/services/evaluation_router.dart';
import 'package:call_log_app/services/scam_evaluator.dart';

class _FakeEvaluator implements ScamEvaluator {
  _FakeEvaluator(this._verdict);

  final ScamVerdict _verdict;

  @override
  String get name => 'fake';

  @override
  Future<void> warmUp() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<ScamVerdict> evaluate(NotificationRecord record) async => _verdict;
}

NotificationRecord _record() => NotificationRecord(
      packageName: 'com.whatsapp',
      appLabel: 'WhatsApp',
      title: 'Account',
      content: 'You won a prize, click here',
      postedAt: DateTime(2026, 1, 1),
    );

void main() {
  test('parses a JSON verdict from the model', () {
    final verdict = parseScamVerdict(
      '{"label":"asks_app_install","confidence":0.9,"reason":"asks for an APK"}',
      source: EvaluationSource.local,
    );
    expect(verdict.label, ScamLabel.asksAppInstall);
    expect(verdict.confidence, 0.9);
    expect(verdict.source, EvaluationSource.local);
    expect(verdict.shouldAlert, isTrue);
  });

  test('extracts JSON surrounded by prose', () {
    final verdict = parseScamVerdict(
      'Sure: {"label":"not_scam","confidence":0.8,"reason":"normal"} done',
      source: EvaluationSource.local,
    );
    expect(verdict.label, ScamLabel.notScam);
    expect(verdict.isScam, isFalse);
  });

  test('falls back to keyword matching when JSON is missing', () {
    final verdict = parseScamVerdict(
      'this looks like other_scam to me',
      source: EvaluationSource.local,
    );
    expect(verdict.label, ScamLabel.otherScam);
    expect(verdict.confidence, lessThan(0.6));
  });

  test('router escalates a low-confidence local verdict to the remote', () async {
    final router = EvaluationRouter(
      local: _FakeEvaluator(
        const ScamVerdict(
          label: ScamLabel.unsure,
          confidence: 0.2,
          reason: 'unclear',
          source: EvaluationSource.local,
        ),
      ),
      remote: _FakeEvaluator(
        const ScamVerdict(
          label: ScamLabel.prizeLottery,
          confidence: 0.95,
          reason: 'cloud says scam',
          source: EvaluationSource.remote,
        ),
      ),
    );
    final verdict = await router.evaluate(_record());
    expect(verdict.label, ScamLabel.prizeLottery);
    expect(verdict.source, EvaluationSource.remote);
    expect(verdict.escalated, isTrue);
  });

  test('router keeps a confident local verdict and skips the remote', () async {
    final router = EvaluationRouter(
      local: _FakeEvaluator(
        const ScamVerdict(
          label: ScamLabel.asksCredentials,
          confidence: 0.9,
          reason: 'wants an OTP',
          source: EvaluationSource.local,
        ),
      ),
      remote: _FakeEvaluator(
        const ScamVerdict(
          label: ScamLabel.notScam,
          confidence: 1,
          reason: 'should not be used',
          source: EvaluationSource.remote,
        ),
      ),
    );
    final verdict = await router.evaluate(_record());
    expect(verdict.label, ScamLabel.asksCredentials);
    expect(verdict.source, EvaluationSource.local);
    expect(verdict.escalated, isFalse);
  });

  test('verdict JSON keeps the raw model output', () {
    const verdict = ScamVerdict(
      label: ScamLabel.notScam,
      confidence: 0.9,
      reason: 'casual chat',
      source: EvaluationSource.local,
      raw: '{"label":"not_scam","confidence":0.9,"reason":"casual chat"}',
    );
    final restored = ScamVerdict.fromJson(verdict.toJson());
    expect(restored.label, ScamLabel.notScam);
    expect(restored.raw, verdict.raw);
  });

  test('prompt steers ordinary chat towards not_scam', () {
    final prompt = buildScamPrompt(
      appLabel: 'Discord',
      message: 'hey are we still on for dinner?',
    );
    expect(prompt, contains('not_scam'));
    expect(prompt, contains('App: Discord'));
    expect(prompt, contains('dinner'));
  });
}
