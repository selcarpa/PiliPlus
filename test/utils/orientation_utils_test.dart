import 'package:PiliPlus/plugin/pl_player/models/fullscreen_mode.dart';
import 'package:PiliPlus/utils/orientation_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrientationUtils.defaultFullScreenMode', () {
    test('ChromeOS 默认为不改变当前方向', () {
      expect(
        OrientationUtils.defaultFullScreenMode(
          horizontalScreen: true,
          isTablet: false,
          isChromeOS: true,
        ),
        FullScreenMode.none,
      );
    });

    test('Android 手机默认为按视频方向', () {
      expect(
        OrientationUtils.defaultFullScreenMode(
          horizontalScreen: false,
          isTablet: false,
          isChromeOS: false,
        ),
        FullScreenMode.auto,
      );
    });

    test('Android 平板且开启横屏适配时默认为不改变当前方向', () {
      expect(
        OrientationUtils.defaultFullScreenMode(
          horizontalScreen: true,
          isTablet: true,
          isChromeOS: false,
        ),
        FullScreenMode.none,
      );
    });
  });
}
