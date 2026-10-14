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
  String get commonDownloadModelFirst => '请先在“设置”选项卡中下载模型';

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
  String get commonTagsOptional => '标签（可选）';

  @override
  String get commonShareIntro => '分享你收到的诈骗信息，帮助他人。请先删除所有个人信息。';

  @override
  String get commonPhotos => '照片（可选）';

  @override
  String get commonAddPhoto => '添加照片';

  @override
  String get commonRemovePhoto => '移除照片';

  @override
  String get commonImageTooLarge => '每张图片不得超过 20 MB。';

  @override
  String get settingsDetectionModel => '检测模型';

  @override
  String get settingsProtection => '防护';

  @override
  String get settingsClearNotifications => '清除已捕获的通知';

  @override
  String get settingsStopProtection => '停止后台防护';

  @override
  String get settingsServiceRunning => '服务运行中';

  @override
  String get settingsServiceStopped => '服务已停止';

  @override
  String get settingsAccount => '账户';

  @override
  String get settingsShowTutorial => '再次查看教程';

  @override
  String get settingsReplayTour => '重新播放应用功能概览';

  @override
  String get settingsLogOut => '退出登录';

  @override
  String get settingsSignOutSubtitle => '退出你的账户';

  @override
  String get settingsAdvanced => '高级';

  @override
  String get settingsAdvancedSubtitle => '开发者与模型调校选项';

  @override
  String get settingsModelFromDevice => '来自本设备的模型（测试）';

  @override
  String get settingsScanForModels => '扫描模型文件';

  @override
  String get settingsScanningStorage => '正在扫描存储…';

  @override
  String get settingsScanSubtitle => '在“下载”和“文档”中查找 .litertlm 和 .task 文件';

  @override
  String get settingsModelFilePath => '模型文件路径';

  @override
  String get settingsModelFilePathHelper => '也可手动输入路径。文件将就地使用，绝不会被复制。';

  @override
  String get settingsContextWindow => '上下文窗口（词元）';

  @override
  String settingsContextWindowHelper(int max) {
    return '加载时请求的上下文长度。不得超过转换时设定的 kv_cache_max_len（MiniCPM5-2B 最高支持 $max）。更大的窗口每个词元约占用 40 KB 内存。';
  }

  @override
  String settingsContextRange(int max) {
    return '请输入 1024 到 $max 之间的值';
  }

  @override
  String get settingsThinking => '思考（推理）';

  @override
  String get settingsThinkingHelper =>
      '让模型在回答前先推理。会使用更多词元且速度较慢；需要 3000 以上词元的上下文才有效。';

  @override
  String get settingsLoadModelFromFile => '从文件加载模型';

  @override
  String settingsCloudThreshold(int pct) {
    return '云端升级阈值 — 低于 $pct% 时升级';
  }

  @override
  String get settingsCloudReview => '云端审查';

  @override
  String get settingsForceCloud => '强制使用云端';

  @override
  String get settingsForceCloudHelper =>
      '将每条信息都发送到云端模型并跳过本地模型。仅在云端无法连接时才回退到本地模型。';

  @override
  String get settingsEndpoint => '接口地址';

  @override
  String get settingsEndpointHint => 'https://.../v1/chat/completions（留空 = 停用）';

  @override
  String get settingsModelName => '模型名称';

  @override
  String settingsOnDeviceModel(String name) {
    return '本地模型 — $name';
  }

  @override
  String settingsReadyKept(int mb) {
    return '就绪 · $mb MB · 保存在“下载”中（重装后仍保留）';
  }

  @override
  String settingsReadyOffline(int mb) {
    return '就绪 · $mb MB · 离线运行';
  }

  @override
  String settingsInstallingBundled(int pct) {
    return '正在安装内置模型 $pct%';
  }

  @override
  String settingsDownloadingPct(int pct) {
    return '正在下载 $pct%';
  }

  @override
  String get settingsBundledPreparing => '随应用捆绑 · 准备中';

  @override
  String settingsNotDownloaded(int mb) {
    return '尚未下载（$mb MB）';
  }

  @override
  String get settingsRemove => '移除';

  @override
  String settingsPercent(int pct) {
    return '$pct%';
  }

  @override
  String get settingsInstall => '安装';

  @override
  String get settingsDownload => '下载';

  @override
  String get settingsNoFilePicked => '尚未选择文件';

  @override
  String get settingsScanHint => '扫描本手机上已有的模型文件。';

  @override
  String settingsCustomModelMeta(String path, int mb, int tokens) {
    return '$path · $mb MB · $tokens 词元';
  }

  @override
  String get settingsForget => '忘记';

  @override
  String get settingsAllFilesAccess =>
      '请在 Android 设置中为 Scam Shield 授予“所有文件访问权限”，然后重新扫描。';

  @override
  String get settingsNoModelFiles =>
      '未找到 .litertlm 或 .task 文件。\n\n请将模型放入“下载”文件夹（或在下方输入其路径），然后重新扫描。';

  @override
  String settingsFileSizeMb(int mb) {
    return '$mb MB';
  }

  @override
  String get settingsEnterPathFirst => '请先输入模型文件路径';

  @override
  String settingsModelLoaded(String name) {
    return '$name 已加载';
  }

  @override
  String get settingsModelForgotten => '已忘记所选模型 — 文件仍保留在设备上';

  @override
  String settingsSizeFromDevice(int mb) {
    return '~$mb MB · 来自本设备';
  }

  @override
  String settingsSizeBundled(int mb) {
    return '~$mb MB · 内置';
  }

  @override
  String settingsSizeDownload(int mb) {
    return '~$mb MB · 下载';
  }

  @override
  String settingsFieldSaved(String label) {
    return '$label 已保存';
  }

  @override
  String get settingsSave => '保存';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '系统默认';

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
  String get callBlock => '拦截';

  @override
  String get callUnblock => '取消拦截';

  @override
  String get callBlockAndReport => '拦截并举报';

  @override
  String get callBlockNeedsScreening =>
      'To stop blocked numbers from ringing, choose this app for call screening.';

  @override
  String get reportPhone => '电话';

  @override
  String get reportUnknownApp => '未知应用';

  @override
  String get reportSent => '举报已发送';

  @override
  String get reportNotSent => '举报未发送 — 举报接口尚未配置';

  @override
  String get reportAddAppFirst => '请先添加一个应用。';

  @override
  String get reportAsScam => '将此信息举报为诈骗？';

  @override
  String get reportSuspiciousMessages => '可疑信息';

  @override
  String get reportTapHint => '对任何看起来像诈骗的信息点按“举报此项”。';

  @override
  String get reportNothingSuspicious => '目前没有可疑内容';

  @override
  String reportVerdictSummary(String label, int pct) {
    return '$label · $pct% 确定';
  }

  @override
  String get reportRecentCalls => '最近通话';

  @override
  String get reportNoCalls => '尚无通话记录';

  @override
  String get reportSomethingElse => '举报其他内容';

  @override
  String get reportWriteOwn => '撰写你自己的举报';

  @override
  String get reportNumberOptional => '号码（可选）';

  @override
  String get reportAppRequired => '应用（必填）';

  @override
  String get reportAppHint => 'WhatsApp、Telegram、电话…';

  @override
  String get reportMarkAs => '标记为';

  @override
  String get reportSpam => '垃圾信息';

  @override
  String get reportScam => '诈骗';

  @override
  String get reportOther => '其他';

  @override
  String get reportReason => '原因';

  @override
  String get reportReasonHint => '他们做了或说了什么？';

  @override
  String get reportOtherComments => '其他备注';

  @override
  String get reportOtherCommentsHint => '还有什么我们该知道的（可选）';

  @override
  String get reportSubmit => '提交举报';

  @override
  String reportSubjectTitle(String subject) {
    return '举报 $subject？';
  }

  @override
  String get reportReasonOptional => '原因（可选）';

  @override
  String get shieldTurnOnToRun => '开启防护以运行模型';

  @override
  String get shieldCheckingMessage => '正在检查信息…';

  @override
  String get shieldScamAi => '诈骗 AI';

  @override
  String get shieldModelReady => '本地模型已就绪';

  @override
  String get shieldNoModel => '未安装本地模型';

  @override
  String shieldStats(int evaluated, int alerts) {
    return '已检查 $evaluated 条信息，发出 $alerts 次警报';
  }

  @override
  String get shieldTryMessage => '试试一条信息';

  @override
  String get shieldPasteHint => '粘贴一条可疑信息…';

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
  String contactsLoadFailed(String error) {
    return '加载通讯录失败：$error';
  }

  @override
  String get contactsTitle => '通讯录';

  @override
  String get contactsOpenMenu => '打开菜单';

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
  String contactsCouldNotCallError(String error) {
    return '无法发起通话：$error';
  }

  @override
  String get safetyTitle => '安全';

  @override
  String get safetyRecentAlerts => '最近警报';

  @override
  String get safetyProtectedOn => '你已受到保护';

  @override
  String get safetyProtectedOff => '防护已关闭';

  @override
  String get safetyDownloadFirstPeriod => '请先在“设置”选项卡中下载模型。';

  @override
  String get safetyWeCheck => '我们会检查你的信息是否为诈骗。';

  @override
  String get safetyTurnOnToCheck => '开启此项以检查信息是否为诈骗。';

  @override
  String get safetyTurnOff => '关闭防护';

  @override
  String get safetyTurnOn => '开启防护';

  @override
  String get safetyNoScams => '未发现诈骗';

  @override
  String get safetyNoScamsBody => '可疑信息将显示在这里。';

  @override
  String get protectionChecked => '已检查';

  @override
  String get protectionAlerts => '警报';

  @override
  String get protectionOn => '防护已开启';

  @override
  String get protectionOff => '防护已关闭';

  @override
  String get protectionReadsNotifications => '读取来自信息应用的通知';

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
  String settingsScreenModelInstalled(String name) {
    return '$name 已安装';
  }

  @override
  String get settingsScreenTitle => '设置';

  @override
  String get settingsScreenModelTab => '模型';

  @override
  String get settingsScreenPermissionsTab => '权限';

  @override
  String get loginAppName => 'Call Manager';

  @override
  String get loginTagline => '保护你远离诈骗电话和信息。';

  @override
  String get loginGetStarted => '开始使用';

  @override
  String get onboardingTitle => '权限';

  @override
  String get onboardingContinue => '继续';

  @override
  String get onboardingBack => '返回';

  @override
  String get onboardingStart => '开始';

  @override
  String get onboardingNext => '下一步';

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
  String postDetailShowMoreReplies(int count) {
    return 'Show $count more replies';
  }

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
  String get tourCallsTitle => '通话';

  @override
  String get tourCallsBody =>
      '陌生号码的来电会显示在这里。点按某条通话可查看详情，使用右上角的拦截图标来管理你再也不想接到的号码。';

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
  String get tourMyPostsTitle => '我的帖子';

  @override
  String get tourMyPostsBody => '你举报的所有内容都会汇总到这里。追踪讨论，查看版主何时审核了你的帖子。';

  @override
  String get tourSettingsTitle => '设置';

  @override
  String get tourSettingsBody => '下载防护模型、管理权限，并可随时从“账户”区域重新播放本导览。';

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
}
