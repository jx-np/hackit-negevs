// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get commonReport => '举报';

  @override
  String get commonCancel => '取消';

  @override
  String get commonRetry => '重试';

  @override
  String get commonRefresh => '刷新';

  @override
  String get commonReviewed => '已审核';

  @override
  String get commonClear => '清除';

  @override
  String get commonUnknown => '未知';

  @override
  String get commonReportThis => '举报';

  @override
  String get commonNoPostsYet => '暂无帖子';

  @override
  String get commonShareWithCommunity => '分享';

  @override
  String get commonShare => '分享';

  @override
  String get commonSharing => '正在分享…';

  @override
  String get commonTitle => '标题';

  @override
  String get commonTitleHint => '简短摘要';

  @override
  String get commonMessage => '消息';

  @override
  String get commonMessageHint => '粘贴消息';

  @override
  String get commonWhatKindOfScam => '诈骗类型';

  @override
  String get commonShareIntro => '分享一个骗局。先删掉个人信息。';

  @override
  String get commonPhotos => '照片（可选）';

  @override
  String get commonAddPhoto => '添加照片';

  @override
  String get commonRemovePhoto => '移除照片';

  @override
  String get commonImageTooLarge => '每张图片不超过 10 MB。';

  @override
  String get reportTabPhotoProcessing => '检查中…';

  @override
  String get reportTabPhotoFailed => '无法检查';

  @override
  String get reportTabProcessingTitle => '正在处理。请勿关闭应用。';

  @override
  String get reportTabSignInToAddPhotos => '登录后才能加照片。';

  @override
  String get reportTabFailedDialogTitle => '有些照片失败';

  @override
  String reportTabFailedDialogBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张照片失败。重试，还是不放它们直接发布？',
      one: '1 张照片失败。重试，还是不放它直接发布？',
    );
    return '$_temp0';
  }

  @override
  String get reportTabFailedRetry => '重试';

  @override
  String get reportTabFailedPostWithout => '不带照片发布';

  @override
  String get reportTabWaitForImages => '等待照片';

  @override
  String get reportTabCheckImages => '检查照片';

  @override
  String get reportTabReviewCheckbox => '我同意发布这些照片';

  @override
  String get reportTabEditImage => '编辑照片';

  @override
  String get reportTabReuploading => '正在保存编辑后的照片…';

  @override
  String get reportTabPosting => '正在发布…';

  @override
  String get reportTabEditorSaveFailed => '无法保存编辑后的照片。请重试。';

  @override
  String get reportTabEditorLoadFailed => '无法打开这张照片。请重试。';

  @override
  String get reportTabViewPost => '查看你的帖子';

  @override
  String get homeTitle => '主页';

  @override
  String get homeWelcomePrefix => '你好，';

  @override
  String get homeWelcomeGuest => '你好';

  @override
  String get myProfileTitle => '我的';

  @override
  String get myProfileMemberSince => '注册于';

  @override
  String get myProfilePosts => '帖子';

  @override
  String get myProfileSignOut => '退出登录';

  @override
  String get myProfileSignOutHint => '随时可以重新登录';

  @override
  String get myProfileNotSignedInTitle => '还没登录';

  @override
  String get myProfileNotSignedInBody => '登录后查看账户。';

  @override
  String get myProfileSignIn => '登录';

  @override
  String get homeNewsTitle => '诈骗提醒';

  @override
  String get homeNewsError => '无法加载提醒。';

  @override
  String get homeNewsRetry => '重试';

  @override
  String get homeQuickActionsTitle => '你想做什么？';

  @override
  String get homeActionProfile => '我的';

  @override
  String get homeActionProfileBody => '你的资料和帖子';

  @override
  String get homeActionCalls => '通话';

  @override
  String get homeActionCallsBody => '查看陌生号码的来电';

  @override
  String get homeActionReport => '举报诈骗';

  @override
  String get homeActionReportBody => '提醒别人';

  @override
  String get homeStatusOnBody => '正在检查你的消息。';

  @override
  String get homeStatusOffBody => '开启即可收到诈骗提醒。';

  @override
  String get homeStatusProblemTitle => '防护需要修复';

  @override
  String get homeStatusProblemBody => '出了问题。点按修复。';

  @override
  String get homeStatusStartingTitle => '正在启动…';

  @override
  String get homeStatusStartingBody => '可能需要一分钟。';

  @override
  String get homeStatusOpen => '详情';

  @override
  String get homeStatusFix => '修复';

  @override
  String get homeNewsReadMore => '更多';

  @override
  String get homeNewsClose => '关闭';

  @override
  String homeNewsCount(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get homeNewsPrevious => '上一条';

  @override
  String get homeNewsNext => '下一条';

  @override
  String get settingsProtection => '防护';

  @override
  String get settingsStopProtection => '暂停防护';

  @override
  String get settingsServiceRunning => '已开启';

  @override
  String get settingsServiceStopped => '已暂停';

  @override
  String get settingsShowTutorial => '再看教程';

  @override
  String get settingsReplayTour => '快速了解本应用';

  @override
  String get settingsRemove => '移除';

  @override
  String settingsPercent(int pct) {
    return '$pct%';
  }

  @override
  String get settingsDownload => '下载';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '手机默认';

  @override
  String get settingsStatusTitle => '状态';

  @override
  String get settingsGettingReady => '正在启动…';

  @override
  String get settingsNeedsDownload => '需要下载';

  @override
  String settingsModelReady(String name) {
    return '$name 已就绪';
  }

  @override
  String settingsModelNotDownloaded(String name) {
    return '$name 尚未下载';
  }

  @override
  String settingsSettingUpPct(int pct) {
    return '正在设置…$pct%';
  }

  @override
  String settingsSettingUpMb(int mb) {
    return '正在设置…$mb MB';
  }

  @override
  String get settingsCheckerTitle => '诈骗检查器';

  @override
  String get settingsCheckerCaption => '在手机上检查消息。什么都不会传出去。';

  @override
  String get settingsCheckingSupport => '正在检查你的手机…';

  @override
  String get settingsNotAvailable => '此手机不支持';

  @override
  String get settingsReadyShort => '就绪';

  @override
  String get settingsBuiltInSubtitle => '已内置。无需下载。';

  @override
  String settingsAboutMb(int mb) {
    return '约 $mb MB';
  }

  @override
  String get settingsPrepare => '设置';

  @override
  String get settingsSpeedTitle => '速度';

  @override
  String get settingsSpeedCaption => '除非检查器有问题，请用“自动”。';

  @override
  String get settingsSpeedAuto => '自动';

  @override
  String get settingsSpeedAutoBody => '最适合大多数手机';

  @override
  String get settingsSpeedCpu => '兼容性最佳';

  @override
  String get settingsSpeedCpuBody => '适用于所有手机。速度最慢。';

  @override
  String get settingsSpeedGpu => '更快';

  @override
  String get settingsSpeedGpuBody => '使用图形芯片';

  @override
  String get settingsSpeedNpu => '最快';

  @override
  String get settingsSpeedNpuBody => '仅限较新的手机';

  @override
  String get settingsAppSection => '应用';

  @override
  String get settingsAppearance => '主题';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsPermissionsSubtitle => '查看应用能做什么';

  @override
  String get settingsSignInSubtitle => '发帖需要';

  @override
  String callIncoming(String who) {
    return '来自 $who 的来电';
  }

  @override
  String callBlocked(String number) {
    return '已拦截 $number';
  }

  @override
  String callUnblocked(String number) {
    return '已取消拦截 $number';
  }

  @override
  String callReported(String number) {
    return '已举报 $number';
  }

  @override
  String get callOutgoing => '呼出';

  @override
  String get callAnswered => '已接听';

  @override
  String get callRejected => '已拒接';

  @override
  String get callMissed => '未接';

  @override
  String get callBlockedLabel => '已拦截';

  @override
  String get navHome => '主页';

  @override
  String get navCalls => '通话';

  @override
  String get navSafety => '安全';

  @override
  String get navReport => '举报';

  @override
  String get navProfile => '我的';

  @override
  String get callHistoryTitle => '通话';

  @override
  String get callBlockedNumbers => '已拦截号码';

  @override
  String get callNoUnknown => '没有陌生号码来电';

  @override
  String get callPhonePermNeeded => '允许电话权限';

  @override
  String get callPhonePermBody => '用来显示来电和发现诈骗。';

  @override
  String get callGrantPhone => '允许';

  @override
  String get callCouldNotLoad => '无法显示通话';

  @override
  String callDurationSuffix(int seconds) {
    return ' • $seconds 秒';
  }

  @override
  String get callReportedSuffix => ' • 已举报';

  @override
  String get callUnblock => '取消拦截';

  @override
  String get callBlockNeedsScreening => '要拦截来电，请把本应用设为来电拦截应用。';

  @override
  String get callHighRiskTitle => '很可能是诈骗电话';

  @override
  String get callHighRiskBody => '有人举报这个号码是诈骗。别给钱，也别透露个人信息。';

  @override
  String callHighRiskScore(int score) {
    return '评分：$score/100';
  }

  @override
  String callHighRiskReports(int count) {
    return '$count 次举报';
  }

  @override
  String get callHighRiskDismiss => '知道了';

  @override
  String get callHighRiskBlock => '这是诈骗 – 拦截';

  @override
  String get callHighRiskSafe => '安全 / 关闭';

  @override
  String get callChecking => '检查中…';

  @override
  String get callCheckTitle => '检查号码';

  @override
  String get callCheckNumberLabel => '已检查的号码';

  @override
  String get callCheckResultHighRisk => '很可能是诈骗';

  @override
  String get callCheckResultUnknown => '没有举报';

  @override
  String get callCheckResultSafe => '看起来安全';

  @override
  String get callCheckResultFailed => '无法检查';

  @override
  String get callCheckDetailHighRisk => '有人举报这个号码是诈骗。别回拨。';

  @override
  String get callCheckDetailUnknown => '没有举报。还是要小心。';

  @override
  String get callCheckDetailSafe => '看起来安全。还是要小心。';

  @override
  String get callCheckDetailFailed => '请检查网络后重试。';

  @override
  String callCheckScore(int score) {
    return '评分：$score/100';
  }

  @override
  String callCheckReports(int count) {
    return '$count 次举报';
  }

  @override
  String get reportNotSent => '无法发送。举报功能还没设置好。';

  @override
  String get reportSpam => '垃圾信息';

  @override
  String get reportScam => '诈骗';

  @override
  String get reportOther => '其他';

  @override
  String get reportReason => '原因';

  @override
  String get shieldCheck => '检查';

  @override
  String get permDenied => '权限被拒绝';

  @override
  String get permConfirmScreening => '把本应用设为来电筛查应用';

  @override
  String get permScreeningUnavailable => '此手机不支持来电筛查';

  @override
  String get permNotificationAccess => '检查消息';

  @override
  String get permNotificationAccessSub => '读取新消息，查找诈骗';

  @override
  String get permOverlay => '来电提醒';

  @override
  String get permOverlaySub => '通话时显示提醒';

  @override
  String get permAlerts => '提醒';

  @override
  String get permAlertsSub => '发送诈骗提醒';

  @override
  String get permBackground => '保持运行';

  @override
  String get permBackgroundSub => '屏幕关闭时也能工作';

  @override
  String get permBatterySettings => '别让应用暂停';

  @override
  String get permBatterySettingsSub => '把本应用设为“不优化”。';

  @override
  String get permGranted => '已开启';

  @override
  String get permGrant => '开启';

  @override
  String get permScreeningRole => '检查来电';

  @override
  String get permScreeningRoleSub => '检查来电，拦截你选择的号码。';

  @override
  String get permScreeningActive => '已开启';

  @override
  String get permEnableScreening => '开启';

  @override
  String get permScreeningNotGranted => '来电检查已关闭';

  @override
  String get permScreeningTapHint => '点按上面的“开启”。';

  @override
  String get permTitle => '权限';

  @override
  String get permGrantFollowing => '开启这些，获得完整防护。';

  @override
  String get permPhoneCallLog => '电话';

  @override
  String get permPhoneGranted => '已允许电话权限';

  @override
  String get permContacts => '通讯录';

  @override
  String get permContactsGranted => '已允许通讯录';

  @override
  String get permNotifications => '通知';

  @override
  String get permNotificationsGranted => '已允许通知';

  @override
  String get permStillNotWorking => '还是不行？';

  @override
  String get permOpenSettingsBody => '在手机设置中开启权限。';

  @override
  String get permOpenAppSettings => '打开设置';

  @override
  String get permNotChecked => '未检查';

  @override
  String get permStatusDenied => '已关闭';

  @override
  String get permPermanentlyDenied => '已关闭。请在设置中开启';

  @override
  String get permNotGranted => '已关闭';

  @override
  String get contactsPermRequired => '允许通讯录，才能查看联系人。';

  @override
  String get contactsTitle => '通讯录';

  @override
  String get contactsSearchHint => '搜索姓名或号码';

  @override
  String get contactsCouldNotLoad => '无法加载通讯录';

  @override
  String get contactsNoneFound => '没有联系人';

  @override
  String get contactsNoDetails => '无详情';

  @override
  String get contactsCouldNotCall => '无法发起通话';

  @override
  String get safetyTitle => '安全';

  @override
  String get safetyRecentAlerts => '最近提醒';

  @override
  String get safetyProtectedOn => '已防护';

  @override
  String get safetyProtectedOff => '防护已关闭';

  @override
  String get safetyWeCheck => '检查你的消息是否有诈骗。';

  @override
  String get safetyTurnOnToCheck => '开启后检查消息。';

  @override
  String get safetyTurnOff => '关闭防护';

  @override
  String get safetyTurnOn => '开启防护';

  @override
  String get safetyPressToStart => '点按开始';

  @override
  String get safetyDownloadingModel => '正在下载…';

  @override
  String get safetySettingUpModel => '正在设置…';

  @override
  String get safetyNoScams => '没有诈骗';

  @override
  String get safetyNoScamsBody => '诈骗会显示在这里。';

  @override
  String get safetyMeteredTitle => '使用移动数据？';

  @override
  String safetyMeteredBody(int mb) {
    return '下载约 $mb MB。用 Wi-Fi 更好。';
  }

  @override
  String get safetyNotNow => '以后再说';

  @override
  String get safetyDownload => '下载';

  @override
  String get safetyCouldNotStart => '防护无法启动。请重试。';

  @override
  String get safetyShowMore => '显示更多';

  @override
  String get safetyShowLess => '收起';

  @override
  String get safetyPillOn => '已防护';

  @override
  String get safetyPillOff => '已关闭';

  @override
  String get safetyPillError => '需要修复';

  @override
  String get safetyPillChecking => '检查中';

  @override
  String get safetyHeroOnBody => '在你的手机上检查。';

  @override
  String get protectionChecked => '已检查';

  @override
  String get protectionAlerts => '提醒';

  @override
  String get protectionOn => '防护已开启';

  @override
  String get protectionOff => '防护已关闭';

  @override
  String activityAll(int count) {
    return '全部（$count）';
  }

  @override
  String activityScams(int count) {
    return '诈骗（$count）';
  }

  @override
  String activityUnchecked(int count) {
    return '未检查（$count）';
  }

  @override
  String get activityNoMessages => '还没有消息。';

  @override
  String get activityNotCheckedSuffix => ' · 未检查';

  @override
  String get activityCloudSuffix => ' · 在线';

  @override
  String get activityNotCheckedYet => '还没检查。';

  @override
  String get activityVerdict => '结果';

  @override
  String get activityConfidence => '可信度';

  @override
  String get activityCheckedBy => '检查者';

  @override
  String activityEscalatedSuffix(String wire) {
    return '$wire（在线）';
  }

  @override
  String get activityReason => '原因';

  @override
  String get activityAiThinking => '完整结果';

  @override
  String get activityNoOutput => '（无结果）';

  @override
  String get blockedNumbersTitle => '已拦截号码';

  @override
  String get blockedNoNumbers => '没有被拦截的号码';

  @override
  String get notificationsTitle => '通知';

  @override
  String get activityTitle => '活动';

  @override
  String get notificationsTestTitle => '测试消息';

  @override
  String get notificationsTestHint => '粘贴或输入消息';

  @override
  String get notificationsTestRun => '检查消息';

  @override
  String get notificationsTestServiceOff => '请先开启防护。';

  @override
  String get notificationsTestSent => '正在检查。结果会显示在下方。';

  @override
  String get settingsScreenTitle => '设置';

  @override
  String get settingsScreenPermissionsTab => '权限';

  @override
  String get onboardingContinue => '继续';

  @override
  String get onboardingBack => '返回';

  @override
  String get onboardingStart => '开始';

  @override
  String get onboardingAllow => '允许';

  @override
  String get onboardingOpenSettings => '打开设置';

  @override
  String get onboardingNotNow => '以后再说';

  @override
  String get onboardingFinish => '进入应用';

  @override
  String onboardingStepCount(int step, int total) {
    return '第 $step 步，共 $total 步';
  }

  @override
  String get onboardingWelcomeTitle => '远离诈骗';

  @override
  String get onboardingWelcomeBody => '我们会提醒你诈骗电话和消息。设置很快。';

  @override
  String get onboardingWelcomeNote => '以后可以在设置中更改。';

  @override
  String get onboardingPhoneTitle => '电话';

  @override
  String get onboardingPhoneBody => '看看是谁打来的。';

  @override
  String get onboardingContactsTitle => '联系人';

  @override
  String get onboardingContactsBody => '认识的人来电不会被标记。';

  @override
  String get onboardingScreeningTitle => '检查来电';

  @override
  String get onboardingScreeningBody => '检查来电，拦截你选择的号码。';

  @override
  String get onboardingNotificationsTitle => '提醒';

  @override
  String get onboardingNotificationsBody => '遇到可能的诈骗时收到提醒。';

  @override
  String get onboardingMessagesTitle => '检查消息';

  @override
  String get onboardingMessagesBody => '读取新消息，发现诈骗。';

  @override
  String get onboardingOverlayTitle => '来电提醒';

  @override
  String get onboardingOverlayBody => '通话有风险时显示提醒。';

  @override
  String get onboardingBackgroundTitle => '保持运行';

  @override
  String get onboardingBackgroundBody => '屏幕关闭时也继续检查。';

  @override
  String get onboardingBatterySettingsTitle => '别让应用暂停';

  @override
  String get onboardingBatterySettingsBody => '别让手机暂停本应用。';

  @override
  String get onboardingSettingsHint => '设置会打开。找到本应用并开启。';

  @override
  String get onboardingStatusOn => '已开启。';

  @override
  String get onboardingStatusSkipped => '未开启。可在设置中开启。';

  @override
  String get onboardingStatusBlocked => '手机不会再问。请点按“打开设置”。';

  @override
  String get onboardingDoneTitle => '都设置好了';

  @override
  String get onboardingDoneBody => '我们正在帮你留意诈骗。';

  @override
  String get onboardingDonePartialTitle => '快完成了';

  @override
  String get onboardingDonePartialBody => '有些功能没开。可在设置中开启。';

  @override
  String onboardingGrantedCount(int granted, int total) {
    return '已开启 $granted 项，共 $total 项';
  }

  @override
  String get onboardingWhy => '为什么？';

  @override
  String get onboardingScreeningWhy => '选择本应用，才能检查来电。';

  @override
  String get onboardingMessagesWhy => '我们会留意奇怪的链接或要钱的话。';

  @override
  String get onboardingBatterySettingsHint => '设置会打开。找到本应用并选择“不优化”。';

  @override
  String get onboardingModelTitle => '诈骗检查器';

  @override
  String get onboardingModelBody => '在手机上检查消息。请用 Wi‑Fi。';

  @override
  String onboardingModelDownload(String size) {
    return '下载（$size）';
  }

  @override
  String get onboardingModelDownloadShort => '下载';

  @override
  String onboardingModelDownloading(int percent) {
    return '正在下载…$percent%';
  }

  @override
  String get onboardingModelKeepGoing => '你可以继续。下载会继续进行。';

  @override
  String get onboardingModelReady => '就绪。';

  @override
  String get onboardingModelFailed => '下载没完成。请重试，或用设置。';

  @override
  String get onboardingModelMeteredTitle => '使用移动数据？';

  @override
  String onboardingModelMeteredBody(String size) {
    return '你不在 Wi‑Fi 上。这将用约 $size。';
  }

  @override
  String get setupOpenSettingsFailed => '无法打开设置。';

  @override
  String get authEnterEmail => '请输入邮箱。';

  @override
  String get authValidEmail => '请输入有效的邮箱。';

  @override
  String get authEnterPassword => '请输入你的密码。';

  @override
  String get authPasswordLength => '请至少使用 8 个字符。';

  @override
  String get authEnterName => '请输入你的姓名。';

  @override
  String get authNameInvalid => '只能有字母和数字，可有一个空格。';

  @override
  String get authCreateAccount => '创建账户';

  @override
  String get authSignIn => '登录';

  @override
  String get authRegisterIntro => '加入后可以分享骗局。';

  @override
  String get authLoginIntro => '登录后可发帖和评论。';

  @override
  String get authYourName => '你的姓名';

  @override
  String get authYourNameHint => '输入你的姓名';

  @override
  String get authEmail => '邮箱';

  @override
  String get authEmailHint => '输入邮箱';

  @override
  String get authPassword => '密码';

  @override
  String get authPasswordHint => '输入你的密码';

  @override
  String get authShowPassword => '显示密码';

  @override
  String get authHidePassword => '隐藏密码';

  @override
  String get authToggleToLogin => '已有账户？登录';

  @override
  String get authToggleToRegister => '新用户？创建账户';

  @override
  String get authGateTitle => '登录后继续';

  @override
  String get authGateBody => '需要一个账户，免费。';

  @override
  String get authGateAction => '登录';

  @override
  String get communityTitle => '社区';

  @override
  String get communityShareScam => '分享骗局';

  @override
  String get communityAll => '全部';

  @override
  String get communityNoPostsBody => '分享的骗局会显示在这里。';

  @override
  String get createChooseType => '请选择诈骗类型。';

  @override
  String get createAddTitle => '请添加标题。';

  @override
  String get createAddMessage => '请添加消息内容。';

  @override
  String get reportTabTitle => '举报';

  @override
  String get reportTabThankYou => '已分享。谢谢！';

  @override
  String get reportTabTrackIt => '已分享。可在“我的”中查看。';

  @override
  String get reportTabHeroTitle => '提醒别人防诈骗';

  @override
  String get reportTabNumberHeroTitle => '举报号码';

  @override
  String get reportTabNumberHeroBody => '说说这个号码为什么可疑。你的举报能帮到别人。';

  @override
  String get reportTabPaste => '粘贴';

  @override
  String get reportTabPasteEmpty => '没有可粘贴的内容。请先复制消息。';

  @override
  String get reportTabNumberLabel => '电话号码';

  @override
  String get reportTabNumberHint => '例如：+65 9123 4567';

  @override
  String get reportTabNumberRequired => '请输入电话号码。';

  @override
  String get reportTabReasonLabel => '发生了什么？';

  @override
  String get reportTabReasonSpamBody => '不想接的来电或广告';

  @override
  String get reportTabReasonScamBody => '想骗我或骗我的钱';

  @override
  String get reportTabReasonOtherBody => '其他问题';

  @override
  String get reportTabSuccessTitle => '谢谢';

  @override
  String get reportTabReportAnother => '再举报一个';

  @override
  String get reportTabDone => '完成';

  @override
  String get myPostsTitle => '我的帖子';

  @override
  String get myPostsNoneBody => '你分享的举报会显示在这里。';

  @override
  String get myPostsDelete => '删除';

  @override
  String get myPostsDeleteConfirm => '删除这个帖子？';

  @override
  String get myPostsDeleteConfirmBody => '所有人都会看不到。无法撤销。';

  @override
  String get myPostsEdit => '编辑';

  @override
  String get editPostTitle => '编辑帖子';

  @override
  String get editPostSave => '保存';

  @override
  String get editPostSaving => '正在保存…';

  @override
  String get editPostSaved => '已保存。';

  @override
  String get editPostReReview => '编辑后，帖子会重新审核。';

  @override
  String get postDetailThankYou => '谢谢。我们会审核这个帖子。';

  @override
  String get postDetailTitle => '帖子';

  @override
  String get postDetailReportTooltip => '举报此帖';

  @override
  String postDetailComments(int count) {
    return '评论（$count）';
  }

  @override
  String get postDetailNoComments => '暂无评论。';

  @override
  String get postDetailWriteComment => '写评论';

  @override
  String get postDetailPostComment => '发布';

  @override
  String get postDetailFlagPersonalInfo => '显示个人信息';

  @override
  String get postDetailFlagHarmful => '有害或危险';

  @override
  String get postDetailFlagSpam => '垃圾信息';

  @override
  String get postDetailFlagMisinfo => '错误信息';

  @override
  String get postDetailFlagOther => '其他';

  @override
  String get postDetailReply => '回复';

  @override
  String get postDetailEdit => '编辑';

  @override
  String get postDetailDelete => '删除';

  @override
  String get postDetailSave => '保存';

  @override
  String get postDetailCancel => '取消';

  @override
  String postDetailReplying(String name) {
    return '回复 $name';
  }

  @override
  String get postDetailWriteReply => '写回复';

  @override
  String get postDetailDeleteConfirm => '删除这条评论？';

  @override
  String get postDetailDeleteConfirmBody => '此操作无法撤销。';

  @override
  String get postDetailEdited => '已编辑';

  @override
  String get postDetailRemovedComment => '此评论已被移除。';

  @override
  String get postDetailAiBadge => 'AI';

  @override
  String get postDetailMentionHelpHint => 'Ask NegevAI about this post';

  @override
  String get postDetailBotThinking => 'NegevAI is thinking...';

  @override
  String get guidanceClickedLink => '我点了链接';

  @override
  String get guidanceGotMessage => '我收到了消息';

  @override
  String get guidanceSharedPassword => '我把密码给了别人';

  @override
  String get guidanceSentMoney => '我转了钱';

  @override
  String get guidanceCouldNotOpenLink => '无法打开该链接。';

  @override
  String get guidanceCouldNotCall => '无法发起通话。';

  @override
  String get guidanceTitle => '获取帮助';

  @override
  String get guidanceWhatHappened => '发生了什么？';

  @override
  String get guidanceWhoToContact => '该联系谁';

  @override
  String get guidanceShowAll => '显示全部';

  @override
  String get guidanceOpenWebsite => '打开网站';

  @override
  String get guidanceNoAdvice => '暂无建议';

  @override
  String get guidanceNoAdviceBody => '选择发生的事，看看该怎么做。';

  @override
  String get tourHomeTitle => '防护';

  @override
  String get tourHomeBody => '绿色表示正在防护。不是绿色就点按。';

  @override
  String get tourCallsTitle => '红色通话';

  @override
  String get tourCallsBody => '红色通话可能是诈骗。别接，也别回拨。';

  @override
  String get tourBlockedTitle => '已拦截号码';

  @override
  String get tourBlockedBody => '点按带斜线的盾牌，查看已拦截的号码。';

  @override
  String get tourHelpTitle => '需要帮助？';

  @override
  String get tourHelpBody => '在任何界面点按 ?。';

  @override
  String get tourSafetyTitle => '开启防护';

  @override
  String get tourSafetyBody => '在这里开启或关闭。我们会提醒你诈骗消息。';

  @override
  String get tourReportTitle => '举报诈骗';

  @override
  String get tourReportBody => '告诉大家，让大家注意安全。';

  @override
  String get tourReviewTitle => 'Tick the box';

  @override
  String get tourReviewBody =>
      'After you add photos, check them. Then tick this box to share.';

  @override
  String get tourPostHelpTitle => 'Ask the AI helper';

  @override
  String get tourPostHelpBody =>
      'Not sure if this is a scam? Type @help in a comment. Our AI scam helper will reply.';

  @override
  String get tourPostAiTitle => 'Read the replies';

  @override
  String get tourPostAiBody =>
      'Replies with an AI tag come from the helper. It can make mistakes, so ask someone you trust too.';

  @override
  String get tourPostSampleReply =>
      'This looks like a scam. Do not click the link.';

  @override
  String get tourProfileTitle => '我的';

  @override
  String get tourProfileBody => '在这里查看你的帖子和设置。可在设置中再看一次教程。';

  @override
  String tourStepCounter(int current, int total) {
    return '第 $current/$total 步';
  }

  @override
  String get tourSkip => '跳过';

  @override
  String get tourDone => '完成';

  @override
  String get tourNext => '下一步';

  @override
  String get tourBack => '返回';

  @override
  String get helpTooltip => '帮助';

  @override
  String get helpGotIt => '知道了';

  @override
  String get helpShowTour => '再看教程';

  @override
  String get helpCallsTitle => '各项含义';

  @override
  String get helpCallsHighRiskTitle => '红色通话 = 很可能是诈骗';

  @override
  String get helpCallsHighRiskBody => '别接，也别回拨。';

  @override
  String get helpCallsNormalTitle => '普通通话';

  @override
  String get helpCallsNormalBody => '没有诈骗举报。';

  @override
  String get helpCallsBlockedRowTitle => '已拦截的通话';

  @override
  String get helpCallsBlockedRowBody => '这个号码打不进来。';

  @override
  String get helpCallsBlockedListTitle => '已拦截号码';

  @override
  String get helpCallsBlockedListBody => '点按查看或取消拦截。';

  @override
  String get helpCallsMenuTitle => '更多选项';

  @override
  String get helpCallsMenuBody => '检查、拦截或举报号码。';

  @override
  String get helpCallsRefreshTitle => '刷新';

  @override
  String get helpCallsRefreshBody => '再检查一次通话。';

  @override
  String get helpCallsMissedBody => '你未接听此通话。';

  @override
  String get helpCallsAnsweredBody => '你已接听此通话。';

  @override
  String get helpCallsRejectedBody => '你已拒接此通话。';

  @override
  String get helpCallsBlockedIconBody => '这个来电被拦截了。';

  @override
  String get helpCallsOutgoingBody => '你拨打了此号码。';

  @override
  String get callsLikelyScam => '很可能是诈骗';

  @override
  String get callsMoreOptions => '更多选项';

  @override
  String get callsBlockNumber => '拦截号码';

  @override
  String get callsReportScam => '举报为诈骗';

  @override
  String get callsBlockAndReport => '拦截并举报';

  @override
  String get callsCheckNumber => '检查号码';

  @override
  String get callsLoadFailedBody => '请重试。';

  @override
  String get callsBlockedEmptyBody => '已拦截的号码会显示在这里。';

  @override
  String get callsContactsLoadFailed => '无法显示通讯录。请重试。';

  @override
  String get callsCallTooltip => '呼叫';
}
