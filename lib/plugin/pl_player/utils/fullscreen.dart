import 'dart:async';
import 'dart:io' show Platform;

import 'package:PiliPlus/utils/desktop/window_controller.dart';
import 'package:PiliPlus/utils/device_utils.dart';
import 'package:PiliPlus/utils/system_bar.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart'
    show SystemChrome, SystemUiOverlay, DeviceOrientation;

bool _isDesktopFullScreen = false;

void enterDesktopFullScreen({bool inAppFullScreen = false}) {
  if (!inAppFullScreen && !_isDesktopFullScreen) {
    WindowController.instance.window?.isFullScreen = _isDesktopFullScreen =
        true;
  }
}

void exitDesktopFullScreen() {
  if (_isDesktopFullScreen) {
    WindowController.instance.window?.isFullScreen = _isDesktopFullScreen =
        false;
  }
}

List<DeviceOrientation>? _lastOrientation;

/// 设置首选方向
///
/// 用 [listEquals] 比较而非引用比较，保证「内容相同」时不再重复下发，
/// 避免同一方向被反复设置。[const] 列表在 Dart 中是规范化的，
/// 引用比较在多数情况下也能得到相同结果，这里统一按内容比较。
///
/// 返回值永不为 null：即使本次无需下发也返回一个已完成的 Future，
/// 调用方无需处理可空 Future（否则强制解包会引入崩溃风险）。
Future<void> _setPreferredOrientations(List<DeviceOrientation> orientations) {
  if (listEquals(_lastOrientation, orientations)) {
    return Future.value();
  }
  _lastOrientation = orientations;
  return SystemChrome.setPreferredOrientations(orientations);
}

Future<void> portraitUpMode() {
  return _setPreferredOrientations(const [.portraitUp]);
}

Future<void> portraitDownMode() {
  return _setPreferredOrientations(const [.portraitDown]);
}

Future<void> landscapeLeftMode() {
  return _setPreferredOrientations(const [.landscapeLeft]);
}

Future<void> landscapeRightMode() {
  return _setPreferredOrientations(const [.landscapeRight]);
}

/// 不请求任何方向，由系统（ChromeOS / 手机系统）决定
Future<void> unspecifiedMode() {
  return _setPreferredOrientations(const []);
}

Future<void> fullMode() {
  return _setPreferredOrientations(
    const [.portraitUp, .portraitDown, .landscapeLeft, .landscapeRight],
  );
}

bool _showSystemBar = true;
bool get showSystemBar_ => _showSystemBar;

/// 隐藏系统栏
///
/// 返回值永不为 null。调用方可能直接 await 或链式调用，
/// 若在「本次无需操作」时返回 null，调用方的强制解包会直接崩溃。
///
/// [isAndroid] / [sdkInt] 仅供测试注入平台信息，
/// 默认取当前平台的真实值
Future<void> hideSystemBar({bool? isAndroid, int? sdkInt}) {
  if (!_showSystemBar) {
    return Future.value();
  }
  _showSystemBar = false;
  if (!SystemBarUtils.shouldRequestImmersive(
    isAndroid: isAndroid ?? Platform.isAndroid,
    sdkInt: sdkInt ?? DeviceUtils.sdkInt,
  )) {
    return Future.value();
  }
  return SystemChrome.setEnabledSystemUIMode(.immersiveSticky);
}

//退出全屏显示
Future<void> showSystemBar() {
  if (_showSystemBar) {
    return Future.value();
  }
  _showSystemBar = true;
  return SystemChrome.setEnabledSystemUIMode(
    Platform.isAndroid && DeviceUtils.sdkInt < 29 ? .manual : .edgeToEdge,
    overlays: SystemUiOverlay.values,
  );
}
