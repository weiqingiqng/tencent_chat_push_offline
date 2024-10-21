import 'dart:async';

import 'package:flutter/services.dart';
import 'package:tencent_chat_push_for_china/channel/flutter_push_base_impl.dart';
import 'package:tencent_chat_push_for_china/channel/huawei_apns_impl.dart';
import 'package:tencent_chat_push_for_china/model/push_device_config.dart';
import 'package:tencent_im_base/class/tencent_im_class.dart';
import 'package:tencent_im_base/tencent_im_base.dart';
import 'package:tencent_chat_push_for_china/model/appInfo.dart';
import 'package:tencent_chat_push_for_china/channel/apple_apns_impl.dart';
import 'package:tencent_chat_push_for_china/utils/utils.dart';
import 'dart:io' show Platform;

typedef PushClickAction = void Function(Map<String, dynamic> msg);

class TimUiKitPushPlugin extends TencentIMClass {
  static TimUiKitPushPlugin? _instance;
  TimUiKitPushPlugin._internal() {
    _initPlugin();
  }

  factory TimUiKitPushPlugin() {
    _instance ??= TimUiKitPushPlugin._internal();
    return _instance!;
  }

  static const MethodChannel _channel = MethodChannel('tim_ui_kit_push_plugin');

  /// [Developers should not use this field directly] Flutter push implement
  late FlutterPushBase flutterPush;

  /// [Developers should not use this field directly] Bind the click callback
  PushClickAction? onClickNotification;

  /// [Developers should not use this field directly] Determine whether to execute the push logic in the Dart layer
  bool isUseFlutterPlugin = false;

  /// [Developers should not use this field directly] Constructor, initialize the plug-in
  _initPlugin() async {
    _channel.setMethodCallHandler(_handleMethod);
    if (Platform.isIOS) {
      print("TUIKitPush | Dart Plugin | USE_iOS");
      isUseFlutterPlugin = true;
      flutterPush = AppleAPNSImpl();
    }
  }

  /// get version
  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    if (!(await checkStatus())) {
      return;
    }
    switch (call.method) {
      case "TIMPushClickAction":
        print(
            "TUIKitPush | Dart Plugin | on_handleMethod | TIMPushClickAction");
        return onClickNotification!(call.arguments.cast<String, dynamic>());
      default:
        throw UnsupportedError("Unrecongnized Event");
    }
  }

  /// Upload Token to Tencent IM Server
  Future<bool> uploadToken(PushAppInfo appInfo) async {
    int? businessID = await TimUiKitPushPlugin.getBuzId(appInfo);
    String token = await getDevicePushToken();
    if (token != "") {
      final res = await TencentImSDKPlugin.v2TIMManager
          .getOfflinePushManager()
          .setOfflinePushConfig(
              businessID: businessID?.toDouble() ?? 0, token: token);
      if (res.code == 0) {
        return true;
      } else {
        print("Error: ${res.code} - ${res.desc}");
        return false;
      }
    }
    return false;
  }

  /// Upload Token to Tencent IM Server
  Future<bool> clearToken(PushAppInfo appInfo) async {
    int? businessID = await TimUiKitPushPlugin.getBuzId(appInfo);
    final res = await TencentImSDKPlugin.v2TIMManager
        .getOfflinePushManager()
        .setOfflinePushConfig(
        businessID: businessID?.toDouble() ?? 0, token: "");
    if (res.code == 0) {
      return true;
    } else {
      print("Error: ${res.code} - ${res.desc}");
      return false;
    }
  }

  /// Initialize the push capobility for each channel
  Future<bool> init(
      {required PushClickAction pushClickAction, PushAppInfo? appInfo}) async {
    final res = await TencentImSDKPlugin.v2TIMManager.getLoginUser();
    if(res.code != 0){
      print("Make sure you initilize this plugin, after logging to Tencent IM.");
      return false;
    }
    if (Platform.isAndroid &&
        await _channel.invokeMethod("isEmuiRom")) {
      // 因华为需要使用native异步校验，放到这边进行
      print("TUIKitPush | Dart Plugin | USE HUAWEI");
      isUseFlutterPlugin = true;
      flutterPush = HuaweiImpl();
    }

    print("TUIKitPush | DART | INIT, isUseFlutterPlugin: $isUseFlutterPlugin");
    onClickNotification = pushClickAction;

    if (isUseFlutterPlugin) {
      await flutterPush.init(pushClickAction);
    }

    if (Platform.isAndroid && appInfo != null) {
      await Utils.setAppInfoForChannel(_channel, appInfo);
    }

    await _channel.invokeMethod("initPush");
    return true;
  }

  /// Require the notification permission
  Future<void> requireNotificationPermission() async {
    if (!(await checkStatus())) {
      return;
    }
    if (isUseFlutterPlugin) {
      flutterPush.requirePermission();
    }
    await _channel.invokeMethod("getNotificationPermission");
    return;
  }

  /// Set badge number, only works with XIAOMI(MIUI6 - MIUI 11), HUAWEI, HONOR, vivo and OPPO devices
  void setBadgeNum(int badgeNum) async {
    if (!(await checkStatus())) {
      return;
    }
    _channel.invokeMethod("setBadgeNum", {
      "badgeNum": Platform.isAndroid ? "$badgeNum" : badgeNum,
    });
  }

  /// Clear all the notification for current application
  void clearAllNotification() async {
    _channel.invokeMethod("clearAllNotification");
  }

  /// Get the push config for current device, includes manufacturer, business ID and device Token.
  Future<PushDeviceConfig> getDevicePushConfig(PushAppInfo appInfo) async {
    return PushDeviceConfig(
      deviceManufacturer: await getOtherPushType(),
      deviceToken: await getDevicePushToken(),
      businessID: await getBuzId(appInfo),
    );
  }

  /// Get the Device Push token
  Future<String> getDevicePushToken([int times = 0]) async {
    if (!(await checkStatus())) {
      return "";
    }
    String token = "";
    try {
      if (isUseFlutterPlugin) {
        print("TUIKitPush | Dart | getTokenByFlutter");
        token = await flutterPush.getToken() ?? flutterPush.token;
        print("TUIKitPush | Dart | getTokenByFlutter | DeviceToken: $token");
      } else {
        print("TUIKitPush | Dart | getTokenByNative");
        token = await _channel.invokeMethod("getPushToken");
        print("TUIKitPush | Dart | getTokenByNative | DeviceToken: $token");
      }
    } catch (err) {
      print("getDevicePushToken err $err");
    }
    if(token.isEmpty && times < 10){
      times++;
      return await Future.delayed(const Duration(seconds: 2), ()async{
        return await getDevicePushToken(times);
      });
    }
    return token;
  }

  /// Get the brand of the manufacturer in lowercase letter format, only works for Android device
  static Future<String?> getOtherPushType() async {
    return await _channel.invokeMethod("getDeviceManufacturer");
  }

  /// Find the buz_id for current device from `PushAppInfo`.
  /// It is the business ID from Tencent Cloud IM console.
  static Future<int?> getBuzId(PushAppInfo appInfo) async {
    if (Platform.isIOS) {
      return appInfo.apple_buz_id;
    }
    String device = await getOtherPushType() ?? "";
    print("TUIKitPush | Dart | getOtherPushType | device: $device");
    switch (device) {
      case 'oppo':
      case 'oneplus':
      case 'realme':
        if (appInfo.oppo_buz_id != null) {
          return appInfo.oppo_buz_id;
        }
        break;
      case 'xiaomi':
      case 'mi':
      case 'blackshark':
        if (appInfo.mi_buz_id != null) {
          return appInfo.mi_buz_id;
        }
        break;
      case 'huawei':
        if (appInfo.hw_buz_id != null) {
          return appInfo.hw_buz_id;
        }
        break;
      case 'honor':
        if (appInfo.honor_buz_id != null) {
          return appInfo.honor_buz_id;
        }
        break;
      case 'meizu':
        if (appInfo.mz_buz_id != null) {
          return appInfo.mz_buz_id;
        }
        break;
      case 'vivo':
      case 'iqoo':
        if (appInfo.vivo_buz_id != null) {
          return appInfo.vivo_buz_id;
        }
        break;
      default:
        return 0;
        break;
    }

    if (await _channel.invokeMethod("isOppoRom") &&
        appInfo.oppo_buz_id != null) {
      return appInfo.oppo_buz_id;
    }
    if (await _channel.invokeMethod("isMiuiRom") && appInfo.mi_buz_id != null) {
      return appInfo.mi_buz_id;
    }
    if (await _channel.invokeMethod("isEmuiRom") && appInfo.hw_buz_id != null) {
      return appInfo.hw_buz_id;
    }
    if (await _channel.invokeMethod("isMeizuRom") &&
        appInfo.mz_buz_id != null) {
      return appInfo.mz_buz_id;
    }
    if (await _channel.invokeMethod("isVivoRom") &&
        appInfo.vivo_buz_id != null) {
      return appInfo.vivo_buz_id;
    }

    return 0;
  }

  /// Create notification channel, only works for Android device
  void createNotificationChannel(
      {required String channelId,
      required String channelName,
      required String channelDescription}) async {
    if (Platform.isAndroid) {
      _channel.invokeMethod("createNotificationChannel", {
        "channelId": channelId,
        "channelName": channelName,
        "channelDescription": channelDescription
      });
    }
  }
}
