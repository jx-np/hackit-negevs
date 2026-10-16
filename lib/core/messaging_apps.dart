const Map<String, String> kMessagingApps = {
  'com.google.android.apps.messaging': 'Google Messages',
  'com.samsung.android.messaging': 'Samsung Messages',
  'com.android.mms': 'Messaging',
  'com.android.messaging': 'Messaging',
  'com.motorola.messaging': 'Motorola Messages',
  'com.textra': 'Textra',
  'com.whatsapp': 'WhatsApp',
  'com.whatsapp.w4b': 'WhatsApp Business',
  'org.telegram.messenger': 'Telegram',
  'org.telegram.plus': 'Telegram Plus',
  'org.thunderdog.challegram': 'Telegram X',
  'org.thoughtcrime.securesms': 'Signal',
  'com.facebook.orca': 'Messenger',
  'com.facebook.mlite': 'Messenger Lite',
  'com.instagram.android': 'Instagram',
  'com.instafel.android': 'Instafel',
  'com.tencent.mm': 'WeChat',
  'com.viber.voip': 'Viber',
  'jp.naver.line.android': 'LINE',
  'com.kakao.talk': 'KakaoTalk',
  'com.discord': 'Discord',
  'com.slack': 'Slack',
  'com.microsoft.teams': 'Teams',
  'com.google.android.gm': 'Gmail',
  'com.skype.raider': 'Skype',
  'com.google.android.apps.dynamite': 'Google Chat',
};

bool isMessagingApp(String packageName) {
  if (kMessagingApps.containsKey(packageName)) return true;
  final lower = packageName.toLowerCase();
  return lower.contains('.messaging') ||
      lower.endsWith('.mms') ||
      lower.contains('whatsapp') ||
      lower.contains('telegram') ||
      lower.contains('messenger');
}

String appLabelFor(String packageName) =>
    kMessagingApps[packageName] ??
    packageName.split('.').last.replaceAll('_', ' ');
