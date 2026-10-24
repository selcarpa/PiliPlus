/// 系统栏（状态栏 / 导航栏）显示相关的纯函数
///
/// 与平台通道解耦，便于单元测试
abstract final class SystemBarUtils {
  /// 是否应请求 immersive 以隐藏系统栏
  ///
  /// Android 15(API 35) 起，系统会忽略 immersive / immersiveSticky
  /// （本 App targetSdk >= 35 且未申请 edge-to-edge 豁免）。
  /// 而 Flutter 引擎在切到 immersive 时会先关闭 edge-to-edge
  /// （`WindowCompat.setDecorFitsSystemWindows(window, true)`），
  /// 于是系统栏依然可见、内容却被内缩，造成布局跳动。
  /// 因此在新系统上不再请求 immersive，保持 edge-to-edge 不做切换。
  static bool shouldRequestImmersive({
    required bool isAndroid,
    required int sdkInt,
  }) {
    return !(isAndroid && sdkInt >= 35);
  }
}
