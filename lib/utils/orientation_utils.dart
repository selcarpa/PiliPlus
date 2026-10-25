import 'package:PiliPlus/plugin/pl_player/models/fullscreen_mode.dart';

/// 与窗口方向相关的纯函数计算
///
/// 独立于任何平台绑定，便于单元测试
abstract final class OrientationUtils {
  /// 根据视图宽高判断是否处于横向（宽 > 高）
  ///
  /// 宽高相等时视为纵向
  static bool isLandscape(double width, double height) => width > height;

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
}
