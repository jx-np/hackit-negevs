import 'package:flutter/foundation.dart';

/// Package of the throwaway test sender in `tools/notif_sender`. It is honoured
/// in debug builds only, as an SMS-style source: its notification title is the
/// sender and its text is the message. Release builds ignore it entirely.
const String kDebugSenderPackage = 'com.scamwatch.notifsender';

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

/// Packages whose notification title is an SMS sender (a phone number or a
/// carrier alphanumeric sender ID), so the title can be matched against the
/// device contacts and described as a `sender=` hint. Chat apps are excluded
/// because their title is the other user's display name, which has no phone
/// number behind it and is never in the contacts.
const Set<String> kSmsPackageNames = {
  'com.google.android.apps.messaging',
  'com.samsung.android.messaging',
  'com.android.mms',
  'com.android.messaging',
  'com.oneplus.mms',
  'com.miui.mms',
  'com.motorola.messaging',
  'com.textra',
};

/// Chat apps whose notification title is the saved contact name when the
/// sender is in the phone's contacts, and the bare phone number when not. For
/// these the title itself says whether the sender is known.
const Set<String> kPhoneIdentityPackages = {
  'com.whatsapp',
  'com.whatsapp.w4b',
};

bool identifiesByPhone(String packageName) =>
    kPhoneIdentityPackages.contains(packageName);

bool _isDebugSender(String packageName) =>
    kDebugMode && packageName == kDebugSenderPackage;

bool isSmsApp(String packageName) =>
    kSmsPackageNames.contains(packageName) || _isDebugSender(packageName);

bool isMessagingApp(String packageName) {
  if (kMessagingApps.containsKey(packageName)) return true;
  if (_isDebugSender(packageName)) return true;
  final lower = packageName.toLowerCase();
  return lower.contains('.messaging') ||
      lower.endsWith('.mms') ||
      lower.contains('whatsapp') ||
      lower.contains('telegram') ||
      lower.contains('messenger');
}

String appLabelFor(String packageName) =>
    (_isDebugSender(packageName) ? 'Test SMS' : null) ??
    kMessagingApps[packageName] ??
    packageName.split('.').last.replaceAll('_', ' ');
