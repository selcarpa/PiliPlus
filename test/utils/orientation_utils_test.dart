import 'package:PiliPlus/plugin/pl_player/models/fullscreen_mode.dart';
import 'package:PiliPlus/utils/orientation_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrientationUtils.resolveHorizontalScreen', () {
    test('存在用户显式设置时优先使用显式设置', () {
      expect(
        OrientationUtils.resolveHorizontalScreen(
          override: false,
          isTablet: true,
          isChromeOS: true,
        ),
        isFalse,
      );
      expect(
        OrientationUtils.resolveHorizontalScreen(
          override: true,
          isTablet: false,
          isChromeOS: false,
        ),
        isTrue,
      );
    });

    test('无显式设置时按环境推导', () {
      expect(
        OrientationUtils.resolveHorizontalScreen(
          override: null,
          isTablet: true,
          isChromeOS: false,
        ),
        isTrue,
      );
      expect(
        OrientationUtils.resolveHorizontalScreen(
          override: null,
          isTablet: false,
          isChromeOS: true,
        ),
        isTrue,
      );
      expect(
        OrientationUtils.resolveHorizontalScreen(
          override: null,
          isTablet: false,
          isChromeOS: false,
        ),
        isFalse,
      );
    });
  });

  group('OrientationUtils.isLandscape', () {
    test('宽大于高为横向', () {
      expect(OrientationUtils.isLandscape(1920, 1080), isTrue);
    });

    test('高大于宽为纵向', () {
      expect(OrientationUtils.isLandscape(1080, 1920), isFalse);
    });

    test('宽高相等为纵向', () {
      expect(OrientationUtils.isLandscape(1080, 1080), isFalse);
    });
  });

  group('OrientationUtils.shouldKeepHorizontalScreenOverride', () {
    test('旧值等于自动推导值时丢弃，回归自动推导', () {
      expect(
        OrientationUtils.shouldKeepHorizontalScreenOverride(
          oldValue: true,
          isTablet: true,
        ),
        isFalse,
      );
      expect(
        OrientationUtils.shouldKeepHorizontalScreenOverride(
          oldValue: false,
          isTablet: false,
        ),
        isFalse,
      );
    });

    test('旧值不同于自动推导值时保留，尊重用户显式设置', () {
      expect(
        OrientationUtils.shouldKeepHorizontalScreenOverride(
          oldValue: true,
          isTablet: false,
        ),
        isTrue,
      );
      expect(
        OrientationUtils.shouldKeepHorizontalScreenOverride(
          oldValue: false,
          isTablet: true,
        ),
        isTrue,
      );
    });
  });

  group('OrientationUtils.shouldSkipHorizontalScreenMigration', () {
    test('Android 上判定失败时跳过迁移', () {
      expect(
        OrientationUtils.shouldSkipHorizontalScreenMigration(
          isAndroid: true,
          isDeviceInfoAvailable: false,
        ),
        isTrue,
      );
    });

    test('Android 上判定成功时不跳过迁移', () {
      expect(
        OrientationUtils.shouldSkipHorizontalScreenMigration(
          isAndroid: true,
          isDeviceInfoAvailable: true,
        ),
        isFalse,
      );
    });

    test('非 Android 平台不跳过迁移', () {
      expect(
        OrientationUtils.shouldSkipHorizontalScreenMigration(
          isAndroid: false,
          isDeviceInfoAvailable: false,
        ),
        isFalse,
      );
    });
  });

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
