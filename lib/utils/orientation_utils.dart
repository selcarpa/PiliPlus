import 'package:PiliPlus/plugin/pl_player/models/fullscreen_mode.dart';

/// 与窗口方向相关的纯函数计算
///
/// 独立于任何平台绑定，便于单元测试
abstract final class OrientationUtils {
  /// 计算「横屏适配」的有效值
  ///
  /// 用户显式设置（override）优先，否则按环境推导
  static bool resolveHorizontalScreen({
    required bool? override,
    required bool isTablet,
    required bool isChromeOS,
  }) {
    return override ?? (isTablet || isChromeOS);
  }

  /// 根据视图宽高判断是否处于横向（宽 > 高）
  ///
  /// 宽高相等时视为纵向
  static bool isLandscape(double width, double height) => width > height;

  /// 是否为「宽高互换」的方向变化（设备旋转）
  ///
  /// 设备旋转后新的宽高等于旧的宽、旧的高等于旧的高；
  /// 而普通的窗口缩放、折叠屏展开等不会互换宽高。
  /// 据此可把「设备旋转」与「窗口尺寸变化」区分开——
  /// ChromeOS 上窗口可自由缩放，不能只凭宽高比跨越 1:1 就切换全屏。
  static bool isAxisSwapped({
    required double oldWidth,
    required double oldHeight,
    required double newWidth,
    required double newHeight,
    double tolerance = 2.0,
  }) {
    return (oldWidth - newHeight).abs() <= tolerance &&
        (oldHeight - newWidth).abs() <= tolerance;
  }

  /// 计算默认全屏方向
  static FullScreenMode defaultFullScreenMode({
    required bool horizontalScreen,
    required bool isTablet,
    required bool isChromeOS,
  }) {
    // ChromeOS 上由系统决定方向，不做改变
    if (isChromeOS) return .none;
    return horizontalScreen && isTablet ? .none : .auto;
  }

  /// 是否应跳过旧 `horizontalScreen` 存储键的迁移
  ///
  /// Android 上若 ChromeOS 判定失败，迁移会把依赖判定结果的值固化进存储，
  /// 且旧键随即被删除，无法自愈，因此此时应跳过迁移并留待下次启动重试
  static bool shouldSkipHorizontalScreenMigration({
    required bool isAndroid,
    required bool isDeviceInfoAvailable,
  }) {
    return isAndroid && !isDeviceInfoAvailable;
  }

  /// 迁移旧的 `horizontalScreen` 存储键时，是否应保留旧值
  ///
  /// 旧实现首次读取时会把自动推导值写入同一个 key，
  /// 因此旧值既可能是用户显式设置，也可能只是自动推导结果，无法直接区分。
  /// 这里把旧值与「两种可能的自动推导值」比较：
  /// - 等于当前推导值（[isTablet] || [isChromeOS]）：按新规则推导即可，丢弃旧值
  /// - 等于旧规则推导值（[legacyIsTablet]，旧实现按窗口尺寸判定）：
  ///   按旧规则推导即可，丢弃旧值
  /// - 两者都不等：用户显式修改过，保留为 override 以尊重用户意图
  static bool shouldKeepHorizontalScreenOverride({
    required bool oldValue,
    required bool isTablet,
    required bool isChromeOS,
    required bool legacyIsTablet,
  }) {
    final derived = isTablet || isChromeOS;
    return oldValue != derived && oldValue != legacyIsTablet;
  }
}
