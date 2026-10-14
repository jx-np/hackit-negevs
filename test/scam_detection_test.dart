import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:call_log_app/core/model_catalog.dart';
import 'package:call_log_app/core/notification_record.dart';
import 'package:call_log_app/core/scam_prompt.dart';
import 'package:call_log_app/core/scam_verdict.dart';
import 'package:call_log_app/services/evaluation_router.dart';
import 'package:call_log_app/services/notification_stream.dart';
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
      sender: 'Alex',
      message: 'hey are we still on for dinner?',
    );
    expect(prompt, contains('not_scam'));
    expect(prompt, contains('App: Discord'));
    expect(prompt, contains('Sender: Alex'));
    expect(prompt, contains('dinner'));
  });

  test('force cloud sends even confident messages to the remote', () async {
    final router = EvaluationRouter(
      local: _FakeEvaluator(
        const ScamVerdict(
          label: ScamLabel.notScam,
          confidence: 1,
          reason: 'local says safe',
          source: EvaluationSource.local,
        ),
      ),
      remote: _FakeEvaluator(
        const ScamVerdict(
          label: ScamLabel.prizeLottery,
          confidence: 0.9,
          reason: 'cloud says scam',
          source: EvaluationSource.remote,
        ),
      ),
      forceCloud: true,
    );
    final verdict = await router.evaluate(_record());
    expect(verdict.label, ScamLabel.prizeLottery);
    expect(verdict.source, EvaluationSource.remote);
    expect(verdict.escalated, isTrue);
  });

  test('force cloud falls back to local when the cloud fails', () async {
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
          label: ScamLabel.unsure,
          confidence: 0,
          reason: 'cloud is down',
          source: EvaluationSource.remote,
        ),
      ),
      forceCloud: true,
    );
    final verdict = await router.evaluate(_record());
    expect(verdict.label, ScamLabel.asksCredentials);
    expect(verdict.source, EvaluationSource.local);
    expect(verdict.escalated, isFalse);
  });

  test('strips LiteRT-LM channel markers wrapped around every token', () {
    // MiniCPM5 streams one open/close pair per token, so the markers sit
    // between each word rather than around a single block.
    const raw = '<|channel>thought\n\n'
        '<channel|><|channel>thought\nWe<channel|><|channel>thought\n'
        ' need<channel|><|channel>thought\n to<channel|>'
        '{"label":"not_scam","confidence":0.91,"reason":"casual chat"}'
        '<channel|>';
    final verdict = parseScamVerdict(raw, source: EvaluationSource.local);
    expect(verdict.label, ScamLabel.notScam);
    expect(verdict.confidence, 0.91);
    expect(verdict.reason, 'casual chat');
    expect(verdict.raw, isNot(contains('<|channel>')));
    expect(verdict.raw, isNot(contains('<channel|>')));
    expect(verdict.raw, contains('We need to'));
  });

  test('strips channel markers even when no JSON follows', () {
    const raw = '<|channel>thought\n<channel|><|channel>thought\n'
        'No answer here<channel|>';
    final verdict = parseScamVerdict(raw, source: EvaluationSource.local);
    expect(verdict.label, ScamLabel.unsure);
    expect(verdict.reason, 'Could not read the model output');
    expect(verdict.raw, 'No answer here');
  });

  test('strips a reasoning model thinking block before parsing', () {
    final verdict = parseScamVerdict(
      'The sender asks to install an unknown APK, so this is a scam.\n'
      '</' 'think>\n'
      '{"label":"asks_app_install","confidence":0.93,"reason":"asks to install an APK"}',
      source: EvaluationSource.local,
    );
    expect(verdict.label, ScamLabel.asksAppInstall);
    expect(verdict.confidence, 0.93);
  });

  test('ignores JSON-looking braces inside the thinking block', () {
    final verdict = parseScamVerdict(
      'Draft: {"label":"not_scam"} but on reflection it claims a prize.\n'
      '</' 'think>\n'
      '{"label":"prize_lottery","confidence":0.9,"reason":"claims a prize"}',
      source: EvaluationSource.local,
    );
    expect(verdict.label, ScamLabel.prizeLottery);
  });

  test('router keeps the local verdict when the cloud is unavailable', () async {
    final router = EvaluationRouter(
      local: _FakeEvaluator(
        const ScamVerdict(
          label: ScamLabel.asksAppInstall,
          confidence: 0.99,
          reason: 'asks to install an app',
          source: EvaluationSource.local,
        ),
      ),
      remote: _FakeEvaluator(
        const ScamVerdict(
          label: ScamLabel.unsure,
          confidence: 0,
          reason: 'Cloud review is not configured yet',
          source: EvaluationSource.remote,
        ),
      ),
      confidenceThreshold: 1.0,
    );
    final verdict = await router.evaluate(_record());
    expect(verdict.label, ScamLabel.asksAppInstall);
    expect(verdict.source, EvaluationSource.local);
    expect(verdict.escalated, isFalse);
  });

  test('drops a one-to-one sender prefix already carried by the title', () {
    final notification = IncomingNotification.fromMap({
      'title': 'Ywx',
      'content': 'Ywx: nigga',
    });
    expect(notification.content, 'nigga');
  });

  test('drops a repeated prefix on every bundled line', () {
    final notification = IncomingNotification.fromMap({
      'title': 'Ywx',
      'content': 'Ywx: first\nYwx: second',
    });
    expect(notification.content, 'first\nsecond');
  });

  test('keeps distinct speakers in a group chat log', () {
    final notification = IncomingNotification.fromMap({
      'title': 'Family',
      'content': 'Alex: hi\nMom: ok',
    });
    expect(notification.content, 'Alex: hi\nMom: ok');
  });

  test('drops the conversation title prefix when it matches the sender', () {
    final notification = IncomingNotification.fromMap({
      'title': 'Family',
      'conversationTitle': 'Alex',
      'content': 'Alex: hi\nBob: yo',
    });
    expect(notification.content, 'hi\nBob: yo');
  });

  test('leaves content untouched when there is no sender prefix', () {
    final notification = IncomingNotification.fromMap({
      'title': 'Mom',
      'content': 'Can you send me 20 dollars?',
    });
    expect(notification.content, 'Can you send me 20 dollars?');
  });

  test('compact prompt is much shorter than the full prompt', () {
    final full = buildScamPrompt(
      appLabel: 'WhatsApp',
      sender: 'Ywx',
      message: 'hello',
    );
    final compact = buildScamPrompt(
      appLabel: 'WhatsApp',
      sender: 'Ywx',
      message: 'hello',
      compact: true,
    );
    expect(compact.length, lessThan(full.length ~/ 2));
    expect(compact, contains('not_scam'));
    expect(compact, contains('payment_request'));
    expect(compact, contains('App: WhatsApp'));
    expect(compact, contains('Sender: Ywx'));
  });

  test('compact prompt fits a 1024-token window with a short message', () {
    final compact = buildScamPrompt(
      appLabel: 'WhatsApp',
      sender: 'Ywx',
      message: 'hello how are you',
      compact: true,
    );
    expect(estimatePromptTokens(compact), lessThan(1024 - 320));
  });

  test('thinking is enabled only on a large enough context', () {
    expect(
      scamThinkingEnabled(thinking: true, contextTokens: 1280),
      isFalse,
    );
    expect(
      scamThinkingEnabled(thinking: true, contextTokens: 4096),
      isTrue,
    );
    expect(
      scamThinkingEnabled(thinking: false, contextTokens: 4096),
      isFalse,
    );
  });

  test('input budget reserves answer room for both modes', () {
    expect(
      scamInputTokenBudget(thinking: false, contextTokens: 1280),
      1280 - kReserveOutputTokens,
    );
    expect(
      scamInputTokenBudget(thinking: true, contextTokens: 4096),
      2048,
    );
    // A tiny window never yields a non-positive budget.
    expect(
      scamInputTokenBudget(thinking: false, contextTokens: 200),
      greaterThan(0),
    );
  });

  test('recovers the answer when thinking braces precede the JSON', () {
    final verdict = parseScamVerdict(
      'Let me weigh {prize} vs {link}. '
      '{"label":"prize_lottery","confidence":0.9,"reason":"claims a prize"}',
      source: EvaluationSource.local,
    );
    expect(verdict.label, ScamLabel.prizeLottery);
    expect(verdict.confidence, 0.9);
  });

  test('recovers JSON when the reason contains a closing brace', () {
    final verdict = parseScamVerdict(
      '{"label":"other_scam","confidence":0.8,"reason":"asks to send {gift}"}',
      source: EvaluationSource.local,
    );
    expect(verdict.label, ScamLabel.otherScam);
    expect(verdict.reason, 'asks to send {gift}');
  });

  test('picks the final JSON object when the model emits two', () {
    final verdict = parseScamVerdict(
      'Draft: {"label":"not_scam","confidence":0.5}\n'
      'Final: {"label":"payment_request","confidence":0.88,"reason":"asks for money"}',
      source: EvaluationSource.local,
    );
    expect(verdict.label, ScamLabel.paymentRequest);
  });

  group('custom model picked from the device', () {
    tearDown(clearCustomModelSpec);

    test('declares litertlm for a .litertlm file', () {
      final spec = buildCustomModelSpec(
        path: '/storage/emulated/0/Download/MiniCPM5-2B.litertlm',
        name: 'MiniCPM5 2B',
        contextTokens: 8192,
        thinking: false,
        sizeMb: 1500,
      );
      expect(spec.fileType, ModelFileType.litertlm);
      expect(spec.modelType, ModelType.llama);
      expect(spec.id, kCustomModelId);
      expect(spec.filePath, '/storage/emulated/0/Download/MiniCPM5-2B.litertlm');
      expect(spec.fileName, 'MiniCPM5-2B.litertlm');
      expect(spec.contextTokens, 8192);
    });

    test('picks a chat template the engine will actually accept', () {
      ModelType typeFor(String name) => buildCustomModelSpec(
            path: '/sdcard/$name',
            name: 'x',
            contextTokens: 1024,
            thinking: false,
            sizeMb: 1,
          ).modelType;

      expect(typeFor('Qwen3-4B.litertlm'), ModelType.qwen3);
      expect(typeFor('qwen2.5-1.5b.task'), ModelType.qwen);
      expect(typeFor('DeepSeek-R1-Distill.task'), ModelType.deepSeek);
      expect(typeFor('gemma-3n-int4.task'), ModelType.gemmaIt);
      expect(typeFor('MiniCPM5-2B.litertlm'), ModelType.llama);
    });

    test('falls back to MediaPipe for a .task file', () {
      final spec = buildCustomModelSpec(
        path: 'C:\\models\\test.task',
        name: '',
        contextTokens: 4096,
        thinking: true,
        sizeMb: 10,
      );
      expect(spec.fileType, ModelFileType.task);
      expect(spec.fileName, 'test.task');
      expect(spec.thinking, isTrue);
    });

    test('resolves through modelById only while it is registered', () {
      expect(allModels.length, modelCatalog.length);
      expect(modelById(kCustomModelId), modelCatalog.first);

      final spec = buildCustomModelSpec(
        path: '/sdcard/Download/minicpm.litertlm',
        name: 'MiniCPM',
        contextTokens: 8192,
        thinking: false,
        sizeMb: 1200,
      );
      customModelSpec = spec;

      expect(allModels.length, modelCatalog.length + 1);
      expect(modelById(kCustomModelId), same(spec));

      clearCustomModelSpec();
      expect(allModels.length, modelCatalog.length);
      expect(modelById(kCustomModelId), modelCatalog.first);
    });
  });
}
