import 'dart:io' show Platform, exit;

import 'package:PiliPlus/utils/android/bindings.g.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/widgets.dart' show WidgetsBinding, Size;
import 'package:nativeapi/nativeapi.dart' as nativeapi show Size;
import 'package:win32/win32.dart' as kernel32;

abstract final class DeviceUtils {
  static final int sdkInt = AndroidHelper.sdkInt();

  /// 当前是否运行在 ChromeOS(ARC / ARCVM) 上
  ///
  /// ChromeOS 的窗口方向由系统决定，App 不应再主动请求方向
  static bool isChromeOS = false;

  static bool get isTablet {
    return size.shortestSide >= 600;
  }

  static Size get size {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }

  static String get platformName => PlatformUtils.isDesktop
      ? 'desktop'
      : isTablet
      ? 'pad'
      : 'phone';

  /// 初始化设备信息，用于识别 ChromeOS
  ///
  /// 需在读取 [Pref] 相关设置前调用
  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      isChromeOS = _detectChromeOS(info);
      if (kDebugMode) {
        debugPrint(
          'DeviceUtils.init: isChromeOS=$isChromeOS, '
          'fingerprint=${info.fingerprint}, product=${info.product}, '
          'device=${info.device}, brand=${info.brand}, '
          'manufacturer=${info.manufacturer}',
        );
      }
    } catch (e) {
      debugPrint('DeviceUtils.init error: $e');
    }
  }

  static bool _detectChromeOS(AndroidDeviceInfo info) {
    for (final value in [info.fingerprint, info.product, info.device]) {
      final lower = value.toLowerCase();
      // arcvm / cheets 为 ARCVM 设备特征
      if (lower.contains('arcvm') || lower.contains('cheets')) return true;
      // cros 为 ChromeOS 设备代号，如 cros_cheets
      if (_tokens(lower).contains('cros')) return true;
    }
    if (info.brand.toLowerCase() == 'chromium' &&
        info.manufacturer.toLowerCase() == 'chromium') {
      return true;
    }
    for (final feature in info.systemFeatures) {
      final lower = feature.toLowerCase();
      if (lower == 'com.google.android.feature.cros_device_management' ||
          lower == 'android.hardware.type.chromebook') {
        return true;
      }
    }
    return false;
  }

  static Set<String> _tokens(String value) => value
      .split(RegExp('[^a-z0-9]+'))
      .where((element) => element.isNotEmpty)
      .toSet();

  static void exitApp() {
    if (Platform.isWindows) {
      // flutter_inappwebview
      // 6.2.0-beta.2+ https://github.com/pichillilorenzo/flutter_inappwebview/issues/2482
      // 6.1.5 https://github.com/pichillilorenzo/flutter_inappwebview/issues/2512#issuecomment-3031039587
      final hProcess = kernel32.GetCurrentProcess();
      kernel32.TerminateProcess(hProcess, 0);
    } else {
      exit(0);
    }
  }

  static const desktopMinSize = nativeapi.Size(width: 400, height: 720);
}
