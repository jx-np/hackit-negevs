//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<background_downloader/BackgroundDownloaderPlugin.h>)
#import <background_downloader/BackgroundDownloaderPlugin.h>
#else
@import background_downloader;
#endif

#if __has_include(<connectivity_plus/ConnectivityPlusPlugin.h>)
#import <connectivity_plus/ConnectivityPlusPlugin.h>
#else
@import connectivity_plus;
#endif

#if __has_include(<flutter_contacts/FlutterContactsPlugin.h>)
#import <flutter_contacts/FlutterContactsPlugin.h>
#else
@import flutter_contacts;
#endif

#if __has_include(<flutter_edge_ai/FlutterEdgeAiPlugin.h>)
#import <flutter_edge_ai/FlutterEdgeAiPlugin.h>
#else
@import flutter_edge_ai;
#endif

#if __has_include(<flutter_edge_ai_mediapipe/FlutterEdgeAiMediaPipePlugin.h>)
#import <flutter_edge_ai_mediapipe/FlutterEdgeAiMediaPipePlugin.h>
#else
@import flutter_edge_ai_mediapipe;
#endif

#if __has_include(<flutter_local_ai/FlutterLocalAiPlugin.h>)
#import <flutter_local_ai/FlutterLocalAiPlugin.h>
#else
@import flutter_local_ai;
#endif

#if __has_include(<flutter_secure_storage/FlutterSecureStoragePlugin.h>)
#import <flutter_secure_storage/FlutterSecureStoragePlugin.h>
#else
@import flutter_secure_storage;
#endif

#if __has_include(<image_picker_ios/FLTImagePickerPlugin.h>)
#import <image_picker_ios/FLTImagePickerPlugin.h>
#else
@import image_picker_ios;
#endif

#if __has_include(<large_file_handler/LargeFileHandlerPlugin.h>)
#import <large_file_handler/LargeFileHandlerPlugin.h>
#else
@import large_file_handler;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

#if __has_include(<pro_image_editor/ProImageEditorPlugin.h>)
#import <pro_image_editor/ProImageEditorPlugin.h>
#else
@import pro_image_editor;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

#if __has_include(<sqflite_darwin/SqflitePlugin.h>)
#import <sqflite_darwin/SqflitePlugin.h>
#else
@import sqflite_darwin;
#endif

#if __has_include(<url_launcher_ios/URLLauncherPlugin.h>)
#import <url_launcher_ios/URLLauncherPlugin.h>
#else
@import url_launcher_ios;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [BackgroundDownloaderPlugin registerWithRegistrar:[registry registrarForPlugin:@"BackgroundDownloaderPlugin"]];
  [ConnectivityPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"ConnectivityPlusPlugin"]];
  [FlutterContactsPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterContactsPlugin"]];
  [FlutterEdgeAiPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterEdgeAiPlugin"]];
  [FlutterEdgeAiMediaPipePlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterEdgeAiMediaPipePlugin"]];
  [FlutterLocalAiPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterLocalAiPlugin"]];
  [FlutterSecureStoragePlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterSecureStoragePlugin"]];
  [FLTImagePickerPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTImagePickerPlugin"]];
  [LargeFileHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"LargeFileHandlerPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
  [ProImageEditorPlugin registerWithRegistrar:[registry registrarForPlugin:@"ProImageEditorPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
  [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]];
  [URLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"URLLauncherPlugin"]];
}

@end
