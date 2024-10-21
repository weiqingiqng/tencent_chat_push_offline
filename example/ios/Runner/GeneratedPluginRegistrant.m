//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<flutter_apns_only/FlutterApnsPlugin.h>)
#import <flutter_apns_only/FlutterApnsPlugin.h>
#else
@import flutter_apns_only;
#endif

#if __has_include(<path_provider_foundation/PathProviderPlugin.h>)
#import <path_provider_foundation/PathProviderPlugin.h>
#else
@import path_provider_foundation;
#endif

#if __has_include(<plain_notification_token_for_us/PlainNotificationTokenPlugin.h>)
#import <plain_notification_token_for_us/PlainNotificationTokenPlugin.h>
#else
@import plain_notification_token_for_us;
#endif

#if __has_include(<tencent_chat_push_for_china/TimUiKitPushPlugin.h>)
#import <tencent_chat_push_for_china/TimUiKitPushPlugin.h>
#else
@import tencent_chat_push_for_china;
#endif

#if __has_include(<tencent_cloud_chat_sdk/TencentCloudChatSdkPlugin.h>)
#import <tencent_cloud_chat_sdk/TencentCloudChatSdkPlugin.h>
#else
@import tencent_cloud_chat_sdk;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FlutterApnsPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterApnsPlugin"]];
  [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
  [PlainNotificationTokenPlugin registerWithRegistrar:[registry registrarForPlugin:@"PlainNotificationTokenPlugin"]];
  [TimUiKitPushPlugin registerWithRegistrar:[registry registrarForPlugin:@"TimUiKitPushPlugin"]];
  [TencentCloudChatSdkPlugin registerWithRegistrar:[registry registrarForPlugin:@"TencentCloudChatSdkPlugin"]];
}

@end
