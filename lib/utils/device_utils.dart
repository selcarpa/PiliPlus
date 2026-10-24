import 'dart:io' show Platform, exit;

import 'package:PiliPlus/utils/android/bindings.g.dart';
import 'package:PiliPlus/utils/chromeos_detector.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, visibleForTesting;
import 'package:flutter/widgets.dart' show WidgetsBinding, Size;
import 'package:nativeapi/nativeapi.dart' as nativeapi show Size;
import 'package:win32/win32.dart' as kernel32;

abstract final class DeviceUtils {
  /// Android API 级别
  ///
  /// 非 Android 平台没有 JNI 环境，取 0；
  /// 否则任何读取该值的代码都会在桌面/iOS 上因 JNI 加载失败而崩溃
  static final int sdkInt = Platform.isAndroid ? AndroidHelper.sdkInt() : 0;

  /// ChromeOS 判定结果
  ///
  /// null 表示尚未完成判定或判定失败，此时 [isChromeOS] 退化为 false，
  /// 但调用方应通过 [isDeviceInfoAvailable] 判断结果是否可信，
  /// 避免在判定失败时执行不可逆操作（如一次性存储迁移）
  static bool? _isChromeOS;

  /// 当前是否运行在 ChromeOS(ARC / ARCVM) 上
  ///
  /// ChromeOS 的窗口方向由系统决定，App 不应再主动请求方向
  static bool get isChromeOS => _isChromeOS ?? false;

  /// 设备信息是否获取成功并完成 ChromeOS 判定
  ///
  /// 为 false 时判定结果不可信，不应固化任何依赖 [isChromeOS] 的存储值
  static bool get isDeviceInfoAvailable => _isChromeOS != null;

  /// 设备是否为平板
  ///
  /// 基于显示设备尺寸而非窗口尺寸，避免分屏/自由窗口下判定结果随窗口漂移
  static bool get isTablet {
    return displaySize.shortestSide >= 600;
  }

  /// 旧版的平板判定：基于窗口尺寸
  ///
  /// 旧实现用它来决定写入 `horizontalScreen` 存储键的自动推导值，
  /// 仅在迁移该旧键时用于识别「旧实现自动写入的值」，新逻辑不再使用
  static bool get legacyIsTablet {
    return size.shortestSide >= 600;
  }

  /// 当前窗口尺寸
  ///
  /// 随窗口/分屏变化，适合判断当前朝向
  static Size get size {
    final override = debugWindowSizeOverride;
    if (override != null) return override;
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }

  /// 当前显示设备尺寸
  ///
  /// 描述设备本身，不随分屏/自由窗口变化，适合判断设备形态（手机/平板）
  static Size get displaySize {
    final override = debugDisplaySizeOverride;
    if (override != null) return override;
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final display = view.display;
    return display.size / display.devicePixelRatio;
  }

  /// 测试用：覆盖[displaySize]
  ///
  /// 便于在不依赖平台实际显示尺寸的前提下验证设备形态相关逻辑
  @visibleForTesting
  static Size? debugDisplaySizeOverride;

  /// 测试用：覆盖[size]（窗口尺寸）
  ///
  /// 便于在不依赖平台实际窗口尺寸的前提下验证窗口相关的判定逻辑
  @visibleForTesting
  static Size? debugWindowSizeOverride;

  static String get platformName => PlatformUtils.isDesktop
      ? 'desktop'
      : isTablet
      ? 'pad'
      : 'phone';

  /// 初始化设备信息，用于识别 ChromeOS
  ///
  /// 需在读取 [Pref] 相关设置前调用
  static Future<void> init() async {
    if (!Platform.isAndroid) {
      // 非 Android 平台可确定不是 ChromeOS
      _isChromeOS = false;
      return;
    }
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      _isChromeOS = ChromeOSDetector.isChromeOS(
        fingerprint: info.fingerprint,
        product: info.product,
        device: info.device,
        brand: info.brand,
        manufacturer: info.manufacturer,
        systemFeatures: info.systemFeatures,
      );
      if (kDebugMode) {
        debugPrint(
          'DeviceUtils.init: isChromeOS=$_isChromeOS, '
          'fingerprint=${info.fingerprint}, product=${info.product}, '
          'device=${info.device}, brand=${info.brand}, '
          'manufacturer=${info.manufacturer}',
        );
      }
    } catch (e) {
      debugPrint('DeviceUtils.init error: $e');
      // 保持 _isChromeOS 为 null，判定结果不可信，
      // 依赖 isChromeOS 的不可逆操作应被跳过
    }
  }

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
