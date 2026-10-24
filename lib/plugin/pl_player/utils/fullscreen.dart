import 'dart:async';
import 'dart:io' show Platform;

import 'package:PiliPlus/utils/desktop/window_controller.dart';
import 'package:PiliPlus/utils/device_utils.dart';
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
Future<void>? _setPreferredOrientations(List<DeviceOrientation> orientations) {
  if (listEquals(_lastOrientation, orientations)) {
    return null;
  }
  _lastOrientation = orientations;
  return SystemChrome.setPreferredOrientations(orientations);
}

Future<void>? portraitUpMode() {
  return _setPreferredOrientations(const [.portraitUp]);
}

Future<void>? portraitDownMode() {
  return _setPreferredOrientations(const [.portraitDown]);
}

Future<void>? landscapeLeftMode() {
  return _setPreferredOrientations(const [.landscapeLeft]);
}

Future<void>? landscapeRightMode() {
  return _setPreferredOrientations(const [.landscapeRight]);
}

/// 不请求任何方向，由系统（ChromeOS / 手机系统）决定
Future<void>? unspecifiedMode() {
  return _setPreferredOrientations(const []);
}

Future<void>? fullMode() {
  return _setPreferredOrientations(
    const [.portraitUp, .portraitDown, .landscapeLeft, .landscapeRight],
  );
}

bool _showSystemBar = true;
bool get showSystemBar_ => _showSystemBar;
Future<void>? hideSystemBar() {
  if (!_showSystemBar) {
    return null;
  }
  _showSystemBar = false;
  // Android 15(API 35) 起，系统会忽略 immersive / immersiveSticky
  // （本 App targetSdk >= 35 且未申请 edge-to-edge 豁免）。
  // 而 Flutter 引擎在切到 immersive 时会先关闭 edge-to-edge，
  // 于是系统栏依然可见、内容却被内缩，造成布局跳动。
  // 因此在新系统上不再请求 immersive，保持 edge-to-edge 不做切换。
  if (Platform.isAndroid && DeviceUtils.sdkInt >= 35) {
    return null;
  }
  return SystemChrome.setEnabledSystemUIMode(.immersiveSticky);
}

//退出全屏显示
Future<void>? showSystemBar() {
  if (_showSystemBar) {
    return null;
  }
  _showSystemBar = true;
  return SystemChrome.setEnabledSystemUIMode(
    Platform.isAndroid && DeviceUtils.sdkInt < 29 ? .manual : .edgeToEdge,
    overlays: SystemUiOverlay.values,
  );
}
