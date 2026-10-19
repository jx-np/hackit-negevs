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
  String get commonReportThis => '举报此项';

  @override
  String get commonNoPostsYet => '暂无帖子';

  @override
  String get commonShareWithCommunity => '分享到社区';

  @override
  String get commonShare => '分享';

  @override
  String get commonSharing => '正在分享…';

  @override
  String get commonTitle => '标题';

  @override
  String get commonTitleHint => '简短摘要';

  @override
  String get commonMessage => '信息内容';

  @override
  String get commonMessageHint => '在此粘贴诈骗信息';

  @override
  String get commonWhatKindOfScam => '是哪种诈骗？';

  @override
  String get commonShareIntro => '分享你收到的诈骗信息，帮助他人。请先删除所有个人信息。';

  @override
  String get commonPhotos => '照片（可选）';

  @override
  String get commonAddPhoto => '添加照片';

  @override
  String get commonRemovePhoto => '移除照片';

  @override
  String get commonImageTooLarge => '每张图片不得超过 10 MB。';

  @override
  String get reportTabPhotoProcessing => '分析中...';

  @override
  String get reportTabPhotoFailed => '无法分析';

  @override
  String get reportTabProcessingTitle => '请勿关闭应用。正在处理';

  @override
  String get reportTabSignInToAddPhotos => '登录以附加照片。';

  @override
  String get reportTabFailedDialogTitle => '部分图片无法分析';

  @override
  String reportTabFailedDialogBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张图片上传或分析失败。重试，还是不含它们直接发布？',
      one: '1 张图片上传或分析失败。重试，还是不含它直接发布？',
    );
    return '$_temp0';
  }

  @override
  String get reportTabFailedRetry => '重试';

  @override
  String get reportTabFailedPostWithout => '不含图片发布';

  @override
  String get reportTabWaitForImages => '请等待图片处理完成';

  @override
  String get reportTabCheckImages => '检查图片';

  @override
  String get reportTabReviewCheckbox => '我已检查图片，个人信息已正确隐藏';

  @override
  String get reportTabEditImage => '编辑图片';

  @override
  String get reportTabReuploading => '正在重新上传编辑后的图片…';

  @override
  String get reportTabPosting => '正在发布…';

  @override
  String get reportTabEditorSaveFailed => '无法重新上传编辑后的图片。请重试。';

  @override
  String get reportTabEditorLoadFailed =>
      'Couldn\'t load the image to edit. Try again.';

  @override
  String get reportTabViewPost => '查看你的帖子';

  @override
  String get homeTitle => '主页';

  @override
  String get homeWelcomePrefix => '欢迎， ';

  @override
  String get homeWelcomeGuest => 'Welcome';

  @override
  String get myProfileTitle => '我的个人资料';

  @override
  String get myProfileMemberSince => '注册于';

  @override
  String get myProfilePosts => '帖子';

  @override
  String get myProfileSignOut => '退出登录';

  @override
  String get myProfileSignOutHint => '您可以随时重新登录';

  @override
  String get myProfileNotSignedInTitle => '您尚未登录';

  @override
  String get myProfileNotSignedInBody => '登录后即可查看您的账户详情并管理您的个人资料。';

  @override
  String get myProfileSignIn => '登录';

  @override
  String get homeNewsTitle => '诈骗警报与新闻';

  @override
  String get homeNewsError => '无法加载最新警报。';

  @override
  String get homeNewsRetry => '重试';

  @override
  String get homeQuickActionsTitle => '您想做什么？';

  @override
  String get homeActionProfile => '我的个人资料';

  @override
  String get homeActionProfileBody => '查看您的个人信息和帖子';

  @override
  String get homeActionCalls => '最近通话';

  @override
  String get homeActionCallsBody => '查看来自陌生号码的来电';

  @override
  String get homeActionReport => '举报诈骗';

  @override
  String get homeActionReportBody => '提醒社区里的其他人';

  @override
  String get homeStatusOnBody => '我们正在检查您的消息中是否存在诈骗。';

  @override
  String get homeStatusOffBody => '请开启它，以便我们向您发出诈骗消息警报。';

  @override
  String get homeStatusProblemTitle => '防护需要注意';

  @override
  String get homeStatusProblemBody => '出现问题。请点击下方进行修复。';

  @override
  String get homeStatusStartingTitle => '正在准备';

  @override
  String get homeStatusStartingBody => '防护正在启动，可能需要一分钟。';

  @override
  String get homeStatusOpen => '查看详情';

  @override
  String get homeStatusFix => '立即修复';

  @override
  String get homeNewsReadMore => '阅读更多';

  @override
  String get homeNewsClose => '关闭';

  @override
  String homeNewsCount(Object current, Object total) {
    return '第 $current 条，共 $total 条';
  }

  @override
  String get homeNewsPrevious => '上一条警报';

  @override
  String get homeNewsNext => '下一条警报';

  @override
  String get settingsProtection => '防护';

  @override
  String get settingsStopProtection => '停止后台防护';

  @override
  String get settingsServiceRunning => '服务运行中';

  @override
  String get settingsServiceStopped => '服务已停止';

  @override
  String get settingsShowTutorial => '再次查看教程';

  @override
  String get settingsReplayTour => '重新播放应用功能概览';

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
  String get settingsLanguageSystem => '系统默认';

  @override
  String get settingsStatusTitle => '状态';

  @override
  String get settingsGettingReady => '正在准备…';

  @override
  String get settingsNeedsDownload => '防护需要下载';

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
  String get settingsCheckerCaption => '在你的手机上检查信息。不会向外部发送任何内容。';

  @override
  String get settingsCheckingSupport => '正在检查你的手机…';

  @override
  String get settingsNotAvailable => '此手机不支持';

  @override
  String get settingsReadyShort => '就绪';

  @override
  String get settingsBuiltInSubtitle => '内置于你的手机。无需下载。';

  @override
  String settingsAboutMb(int mb) {
    return '约 $mb MB';
  }

  @override
  String get settingsPrepare => '设置';

  @override
  String get settingsSpeedTitle => '速度';

  @override
  String get settingsSpeedCaption => '除非检查器出现问题，请保持“自动”。';

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
  String get settingsSpeedGpuBody => '使用手机的图形芯片';

  @override
  String get settingsSpeedNpu => '最快';

  @override
  String get settingsSpeedNpuBody => '仅部分较新的手机支持';

  @override
  String get settingsAppSection => '应用';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsPermissionsSubtitle => '查看应用被允许执行的操作';

  @override
  String get settingsSignInSubtitle => '在社区发帖需要登录';

  @override
  String callIncoming(String who) {
    return '来电：$who';
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
  String get callHistoryTitle => '通话记录';

  @override
  String get callBlockedNumbers => '已拦截号码';

  @override
  String get callNoUnknown => '未找到陌生号码来电';

  @override
  String get callPhonePermNeeded => '需要电话权限';

  @override
  String get callPhonePermBody => 'Call Manager 需要电话权限才能读取你的通话记录。';

  @override
  String get callGrantPhone => '授予电话权限';

  @override
  String get callCouldNotLoad => '无法加载通话记录';

  @override
  String callDurationSuffix(int seconds) {
    return ' • $seconds 秒';
  }

  @override
  String get callReportedSuffix => ' • 已举报';

  @override
  String get callUnblock => '取消拦截';

  @override
  String get callBlockNeedsScreening => '要阻止已屏蔽的号码响铃，请选择此应用进行来电筛选。';

  @override
  String get callHighRiskTitle => '高风险来电者';

  @override
  String get callHighRiskBody => '此号码已被举报为诈骗。请勿透露个人信息或转账。';

  @override
  String callHighRiskScore(int score) {
    return '信任评分：$score/100';
  }

  @override
  String callHighRiskReports(int count) {
    return '已被举报 $count 次';
  }

  @override
  String get callHighRiskDismiss => '关闭';

  @override
  String get callChecking => '正在检查号码...';

  @override
  String get callCheckTitle => '号码检查';

  @override
  String get callCheckNumberLabel => '正在检查的号码';

  @override
  String get callCheckResultHighRisk => '高风险号码';

  @override
  String get callCheckResultUnknown => '暂无记录';

  @override
  String get callCheckResultSafe => '看起来安全';

  @override
  String get callCheckResultFailed => '检查失败';

  @override
  String get callCheckDetailHighRisk => '此号码曾被举报为诈骗。请勿透露个人信息或转账。';

  @override
  String get callCheckDetailUnknown => '此号码没有举报记录。请保持警惕。';

  @override
  String get callCheckDetailSafe => '此号码没有诈骗举报记录。';

  @override
  String get callCheckDetailFailed => '目前无法检查此号码。请重试。';

  @override
  String callCheckScore(int score) {
    return '信任评分：$score/100';
  }

  @override
  String callCheckReports(int count) {
    return '被举报 $count 次';
  }

  @override
  String get reportNotSent => '举报未发送 — 举报接口尚未配置';

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
  String get permConfirmScreening => '确认由 Call Manager 进行来电筛查';

  @override
  String get permScreeningUnavailable => '此设备不支持来电筛查';

  @override
  String get permNotificationAccess => '通知访问权限';

  @override
  String get permNotificationAccessSub => '从通知中读取信息';

  @override
  String get permOverlay => '显示在其他应用之上';

  @override
  String get permOverlaySub => '在来电响铃时显示诈骗警报';

  @override
  String get permAlerts => '允许警报';

  @override
  String get permAlertsSub => '以通知形式发布诈骗警报';

  @override
  String get permBackground => '在后台运行';

  @override
  String get permBackgroundSub => '忽略电池优化，让防护持续运行';

  @override
  String get permBatterySettings => '电池优化设置';

  @override
  String get permBatterySettingsSub => '有些手机仍会限制应用。请打开列表，将本应用设为\"不优化\"。';

  @override
  String get permGranted => '已授予';

  @override
  String get permGrant => '授予';

  @override
  String get permScreeningRole => '来电筛查角色';

  @override
  String get permScreeningRoleSub => '让应用筛查来电并拦截你标记为垃圾的号码。';

  @override
  String get permScreeningActive => '筛查已启用';

  @override
  String get permEnableScreening => '启用来电筛查';

  @override
  String get permScreeningNotGranted => '尚未授予来电筛查权限';

  @override
  String get permScreeningTapHint => '请点按上方的“启用来电筛查”，否则来电仍会正常响铃。';

  @override
  String get permTitle => '权限';

  @override
  String get permGrantFollowing => '授予以下权限以获得完整功能。';

  @override
  String get permPhoneCallLog => '电话与通话记录';

  @override
  String get permPhoneGranted => '已授予电话权限';

  @override
  String get permContacts => '通讯录';

  @override
  String get permContactsGranted => '已授予通讯录权限';

  @override
  String get permNotifications => '通知';

  @override
  String get permNotificationsGranted => '已授予通知权限';

  @override
  String get permStillNotWorking => '仍然无法使用？';

  @override
  String get permOpenSettingsBody => '打开此应用的系统设置，手动分配来电筛查角色和权限。';

  @override
  String get permOpenAppSettings => '打开应用设置';

  @override
  String get permNotChecked => '未检查';

  @override
  String get permStatusDenied => '已拒绝';

  @override
  String get permPermanentlyDenied => '已永久拒绝';

  @override
  String get permNotGranted => '未授予';

  @override
  String get contactsPermRequired => '查看通讯录需要通讯录权限';

  @override
  String get contactsTitle => '通讯录';

  @override
  String get contactsSearchHint => '搜索通讯录…';

  @override
  String get contactsCouldNotLoad => '无法加载通讯录';

  @override
  String get contactsNoneFound => '未找到联系人';

  @override
  String get contactsNoDetails => '无详情';

  @override
  String get contactsCouldNotCall => '无法发起通话';

  @override
  String get safetyTitle => '安全';

  @override
  String get safetyRecentAlerts => '最近警报';

  @override
  String get safetyProtectedOn => '你已受到保护';

  @override
  String get safetyProtectedOff => '防护已关闭';

  @override
  String get safetyWeCheck => '我们会检查你的信息是否为诈骗。';

  @override
  String get safetyTurnOnToCheck => '开启此项以检查信息是否为诈骗。';

  @override
  String get safetyTurnOff => '关闭防护';

  @override
  String get safetyTurnOn => '开启防护';

  @override
  String get safetyPressToStart => '点按以开始';

  @override
  String get safetyDownloadingModel => '正在下载模型…';

  @override
  String get safetySettingUpModel => '正在设置模型…';

  @override
  String get safetyNoScams => '未发现诈骗';

  @override
  String get safetyNoScamsBody => '可疑信息将显示在这里。';

  @override
  String get safetyMeteredTitle => '使用移动数据？';

  @override
  String safetyMeteredBody(int mb) {
    return '此下载约 $mb MB。建议使用 Wi-Fi。';
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
  String get safetyShowLess => '显示更少';

  @override
  String get safetyPillOn => '已防护';

  @override
  String get safetyPillOff => '已关闭';

  @override
  String get safetyPillError => '需要注意';

  @override
  String get safetyPillChecking => '检查中';

  @override
  String get safetyHeroOnBody => '在你的手机上私密检查。';

  @override
  String get protectionChecked => '已检查';

  @override
  String get protectionAlerts => '警报';

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
  String get activityNoMessages => '尚未捕获任何信息。';

  @override
  String get activityNotCheckedSuffix => ' · 未检查';

  @override
  String get activityCloudSuffix => ' · 云端';

  @override
  String get activityNotCheckedYet => '尚未检查。';

  @override
  String get activityVerdict => '判定';

  @override
  String get activityConfidence => '置信度';

  @override
  String get activityCheckedBy => '检查方';

  @override
  String activityEscalatedSuffix(String wire) {
    return '$wire（已升级）';
  }

  @override
  String get activityReason => '原因';

  @override
  String get activityAiThinking => 'AI 思考过程';

  @override
  String get activityNoOutput => '（模型未产生可读的输出）';

  @override
  String get blockedNumbersTitle => '已拦截号码';

  @override
  String get blockedNoNumbers => '没有已拦截的号码';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsTestTitle => '测试信息';

  @override
  String get notificationsTestHint => '粘贴或输入信息';

  @override
  String get notificationsTestRun => '检查信息';

  @override
  String get notificationsTestServiceOff => '请先开启防护。';

  @override
  String get notificationsTestSent => '正在检查。结果将显示在下方。';

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
  String get onboardingWelcomeTitle => '欢迎';

  @override
  String get onboardingWelcomeBody =>
      '本应用帮助您识别诈骗电话和短信。为此，它需要手机授予几项权限。我们会一项一项地完成。';

  @override
  String get onboardingWelcomeNote => '所有内容都保留在您的手机上。您可以随时在设置中更改这些选择。';

  @override
  String get onboardingPhoneTitle => '电话';

  @override
  String get onboardingPhoneBody => '这让应用可以看到谁在给您打电话，从而告诉您这个号码是否与诈骗有关。';

  @override
  String get onboardingContactsTitle => '联系人';

  @override
  String get onboardingContactsBody => '这让应用可以识别您认识的人，他们的来电不会被标记为可疑。';

  @override
  String get onboardingScreeningTitle => '来电检查';

  @override
  String get onboardingScreeningBody =>
      '这让应用可以检查来电，并安静地拦截您已屏蔽的号码。手机会请您选择本应用作为来电筛选应用。';

  @override
  String get onboardingNotificationsTitle => '提醒';

  @override
  String get onboardingNotificationsBody => '当有内容看起来像诈骗时，应用可以给您发送简短提醒。';

  @override
  String get onboardingMessagesTitle => '短信检查';

  @override
  String get onboardingMessagesBody => '这让应用可以在新消息到达时读取它们，以便提醒您注意可疑链接或要钱的请求。';

  @override
  String get onboardingOverlayTitle => '通话时显示提醒';

  @override
  String get onboardingOverlayBody => '当可疑来电响铃时，应用可以在屏幕上显示一条小提示。';

  @override
  String get onboardingBackgroundTitle => '在后台持续运行';

  @override
  String get onboardingBackgroundBody => '允许应用忽略电池优化，这样即使屏幕关闭，它也能持续监测诈骗。';

  @override
  String get onboardingBatterySettingsTitle => '停止电池优化';

  @override
  String get onboardingBatterySettingsBody =>
      '有些手机在首次提示后仍会限制应用。请打开电池设置，找到本应用，将其设为\"不优化\"，让防护永不中断。';

  @override
  String get onboardingSettingsHint => '将打开手机设置。在列表中找到本应用，将其开启，然后返回这里。';

  @override
  String get onboardingStatusOn => '已开启。';

  @override
  String get onboardingStatusSkipped => '尚未开启。您可以再试一次，或稍后在设置中开启。';

  @override
  String get onboardingStatusBlocked => '手机不会再询问。请点击“打开设置”自行开启。';

  @override
  String get onboardingDoneTitle => '设置完成';

  @override
  String get onboardingDoneBody => '应用现在会为您留意诈骗电话和短信。';

  @override
  String get onboardingDonePartialTitle => '快完成了';

  @override
  String get onboardingDonePartialBody => '部分保护尚未开启。应用仍可使用，您可以稍后在设置中开启其余项目。';

  @override
  String onboardingGrantedCount(int granted, int total) {
    return '已开启 $granted 项，共 $total 项';
  }

  @override
  String get onboardingWhy => '为什么？';

  @override
  String get onboardingScreeningWhy => '手机会要求你选择此应用。请选择它，以便检查来电。';

  @override
  String get onboardingMessagesWhy => '我们会寻找诈骗迹象，例如可疑链接或索要钱财。';

  @override
  String get onboardingBatterySettingsHint => '设置将打开。找到此应用并选择“不优化”。';

  @override
  String get onboardingModelTitle => '诈骗检查器';

  @override
  String get onboardingModelBody => '在你的手机上检查信息。建议使用 Wi‑Fi。';

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
  String get onboardingModelReady => '可以使用了。';

  @override
  String get onboardingModelFailed => '下载未完成。请重试，或稍后在设置中进行。';

  @override
  String get onboardingModelMeteredTitle => '使用移动数据？';

  @override
  String onboardingModelMeteredBody(String size) {
    return '你当前不在 Wi‑Fi 上。这将使用约 $size 的数据流量。';
  }

  @override
  String get setupOpenSettingsFailed => '无法打开设置。';

  @override
  String get authEnterEmail => '请输入你的电子邮箱。';

  @override
  String get authValidEmail => '请输入有效的电子邮箱。';

  @override
  String get authEnterPassword => '请输入你的密码。';

  @override
  String get authPasswordLength => '请至少使用 8 个字符。';

  @override
  String get authEnterName => '请输入你的姓名。';

  @override
  String get authNameInvalid => '只能使用字母和数字，两个词之间最多一个空格。';

  @override
  String get authCreateAccount => '创建账户';

  @override
  String get authSignIn => '登录';

  @override
  String get authRegisterIntro => '加入社区，分享并了解诈骗信息。';

  @override
  String get authLoginIntro => '登录以发帖并参与讨论。';

  @override
  String get authYourName => '你的姓名';

  @override
  String get authYourNameHint => '输入你的姓名';

  @override
  String get authEmail => '电子邮箱';

  @override
  String get authEmailHint => '输入你的电子邮箱';

  @override
  String get authPassword => '密码';

  @override
  String get authPasswordHint => '输入你的密码';

  @override
  String get authToggleToLogin => '已有账户？登录';

  @override
  String get authToggleToRegister => '初次使用？创建账户';

  @override
  String get authGateTitle => '需要登录';

  @override
  String get authGateBody => '您需要登录才能使用此功能。';

  @override
  String get authGateAction => '登录';

  @override
  String get communityTitle => '社区';

  @override
  String get communityShareScam => '分享诈骗';

  @override
  String get communityAll => '全部';

  @override
  String get communityNoPostsBody => '社区分享的诈骗举报将显示在这里。';

  @override
  String get createChooseType => '请选择诈骗类型。';

  @override
  String get createAddTitle => '请添加标题。';

  @override
  String get createAddMessage => '请添加信息内容。';

  @override
  String get reportTabTitle => '举报';

  @override
  String get reportTabThankYou => '已分享到社区。谢谢你！';

  @override
  String get reportTabTrackIt => '已分享到社区。可在“我的帖子”中追踪。';

  @override
  String get reportTabHeroTitle => '举报诈骗';

  @override
  String get reportTabNumberHeroTitle => '举报号码';

  @override
  String get reportTabNumberHeroBody => '举报曾对您实施诈骗或骚扰的电话号码。';

  @override
  String get reportTabPaste => '粘贴';

  @override
  String get reportTabPasteEmpty => '剪贴板是空的';

  @override
  String get reportTabNumberLabel => '电话号码';

  @override
  String get reportTabNumberHint => '例如：+65 8123 4567';

  @override
  String get reportTabNumberRequired => '请输入电话号码';

  @override
  String get reportTabReasonLabel => '发生了什么？';

  @override
  String get reportTabReasonSpamBody => '不需要的推销或反复来电';

  @override
  String get reportTabReasonScamBody => '企图窃取钱财或个人信息';

  @override
  String get reportTabReasonOtherBody => '其他';

  @override
  String get reportTabSuccessTitle => '感谢您的举报';

  @override
  String get reportTabReportAnother => '再举报一个';

  @override
  String get reportTabDone => '完成';

  @override
  String get myPostsTitle => '我的帖子';

  @override
  String get myPostsNoneBody => '你举报的诈骗将显示在这里，方便你追踪。';

  @override
  String get myPostsDelete => '删除';

  @override
  String get myPostsDeleteConfirm => '删除这个帖子？';

  @override
  String get myPostsDeleteConfirmBody => '这会将其从社区中移除。此操作无法撤销。';

  @override
  String get myPostsEdit => '编辑';

  @override
  String get editPostTitle => '编辑帖子';

  @override
  String get editPostSave => '保存更改';

  @override
  String get editPostSaving => '正在保存…';

  @override
  String get editPostSaved => '更改已保存。';

  @override
  String get editPostReReview => '编辑信息后，帖子将重新提交审核。';

  @override
  String get postDetailThankYou => '谢谢你。我们的团队将审核此帖。';

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
  String get postDetailWriteComment => '撰写评论';

  @override
  String get postDetailPostComment => '发表评论';

  @override
  String get postDetailFlagPersonalInfo => '显示个人信息';

  @override
  String get postDetailFlagHarmful => '有害或危险';

  @override
  String get postDetailFlagSpam => '垃圾信息';

  @override
  String get postDetailFlagMisinfo => '虚假信息';

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
  String get guidanceClickedLink => '我点了一个链接';

  @override
  String get guidanceGotMessage => '我刚收到一条信息';

  @override
  String get guidanceSharedPassword => '我泄露了密码';

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
  String get guidanceNoAdviceBody => '在上方选择发生的情况，查看你可以采取的步骤。';

  @override
  String get tourHomeTitle => '欢迎使用 ScamWatch';

  @override
  String get tourHomeBody => '您的主页会显示您的防护状态和快捷操作。';

  @override
  String get tourCallsTitle => '通话';

  @override
  String get tourCallsBody =>
      '陌生号码的来电会显示在这里。点按某条通话可查看详情，使用右上角的拦截图标来管理你再也不想接到的号码。';

  @override
  String get tourBlockedTitle => '你的已拦截号码';

  @override
  String get tourBlockedBody => '点按带斜线的盾牌图标，查看你已拦截的号码。';

  @override
  String get tourHelpTitle => '需要帮助？';

  @override
  String get tourHelpBody => '在任意界面点按 ? 了解各项含义。';

  @override
  String get tourSafetyTitle => '安全';

  @override
  String get tourSafetyBody =>
      '在这里开启防护。下载模型后，Scam Shield 会在你的设备上读取收到的信息，并对可能的诈骗发出警告。';

  @override
  String get tourReportTitle => '举报';

  @override
  String get tourReportBody => '发现诈骗了？在此选项卡将它分享到社区，让其他人也能识别同样的伎俩并保持警惕。';

  @override
  String get tourProfileTitle => '您的个人资料';

  @override
  String get tourProfileBody => '在这里查看您的账户详情和您举报过的诈骗。';

  @override
  String tourStepCounter(int current, int total) {
    return '第 $current / $total 步';
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
  String get helpShowTour => '再次显示应用教程';

  @override
  String get helpCallsTitle => '各项含义';

  @override
  String get helpCallsHighRiskTitle => '红色通话 = 很可能是诈骗';

  @override
  String get helpCallsHighRiskBody => '请勿接听或回拨。';

  @override
  String get helpCallsNormalTitle => '普通通话';

  @override
  String get helpCallsNormalBody => '此号码没有诈骗举报记录。';

  @override
  String get helpCallsBlockedRowTitle => '已拦截的通话';

  @override
  String get helpCallsBlockedRowBody => '你已拦截此号码。它无法再打扰你。';

  @override
  String get helpCallsBlockedListTitle => '你的已拦截号码';

  @override
  String get helpCallsBlockedListBody => '点按此项可查看或取消拦截号码。';

  @override
  String get helpCallsMenuTitle => '更多选项';

  @override
  String get helpCallsMenuBody => '检查、拦截或举报号码。';

  @override
  String get helpCallsRefreshTitle => '刷新';

  @override
  String get helpCallsRefreshBody => '重新检查你的通话。';

  @override
  String get helpCallsMissedBody => '你未接听此通话。';

  @override
  String get helpCallsAnsweredBody => '你已接听此通话。';

  @override
  String get helpCallsRejectedBody => '你已拒接此通话。';

  @override
  String get helpCallsBlockedIconBody => '此通话已被阻止。';

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
  String get callsBlockedEmptyBody => '你拦截的号码将显示在这里。';

  @override
  String get callsContactsLoadFailed => '无法显示你的通讯录。请重试。';

  @override
  String get callsCallTooltip => '呼叫';
}
