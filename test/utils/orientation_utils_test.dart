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

  group('OrientationUtils.isAxisSwapped', () {
    test('宽高互换视为设备旋转', () {
      expect(
        OrientationUtils.isAxisSwapped(
          oldWidth: 1080,
          oldHeight: 1920,
          newWidth: 1920,
          newHeight: 1080,
        ),
        isTrue,
      );
    });

    test('普通缩放（未互换宽高）不是旋转', () {
      expect(
        OrientationUtils.isAxisSwapped(
          oldWidth: 1080,
          oldHeight: 1920,
          newWidth: 900,
          newHeight: 1920,
        ),
        isFalse,
      );
      // 窗口从宽拖到窄但没有跨过 1:1
      expect(
        OrientationUtils.isAxisSwapped(
          oldWidth: 1200,
          oldHeight: 700,
          newWidth: 800,
          newHeight: 600,
        ),
        isFalse,
      );
    });

    test('折叠屏展开（宽高不成比例）不是旋转', () {
      expect(
        OrientationUtils.isAxisSwapped(
          oldWidth: 360,
          oldHeight: 800,
          newWidth: 883,
          newHeight: 707,
        ),
        isFalse,
      );
    });

    test('允许细微的取整误差', () {
      expect(
        OrientationUtils.isAxisSwapped(
          oldWidth: 1080,
          oldHeight: 1920,
          newWidth: 1921,
          newHeight: 1081,
        ),
        isTrue,
      );
    });
  });

  group('OrientationUtils.shouldKeepHorizontalScreenOverride', () {
    test('旧值等于当前推导值时丢弃，回归自动推导', () {
      expect(
        OrientationUtils.shouldKeepHorizontalScreenOverride(
          oldValue: true,
          isTablet: true,
          isChromeOS: false,
          legacyIsTablet: true,
        ),
        isFalse,
      );
      expect(
        OrientationUtils.shouldKeepHorizontalScreenOverride(
          oldValue: false,
          isTablet: false,
          isChromeOS: false,
          legacyIsTablet: false,
        ),
        isFalse,
      );
    });

    test('旧值等于旧规则推导值时也丢弃', () {
      // 旧实现按窗口尺寸判定平板并写入该值；
      // 即使按新规则（显示尺寸 + ChromeOS）推导值不同，也不应固化成用户设置
      expect(
        OrientationUtils.shouldKeepHorizontalScreenOverride(
          oldValue: true,
          isTablet: false,
          isChromeOS: false,
          legacyIsTablet: true,
        ),
        isFalse,
      );
      expect(
        OrientationUtils.shouldKeepHorizontalScreenOverride(
          oldValue: false,
          isTablet: true,
          isChromeOS: false,
          legacyIsTablet: false,
        ),
        isFalse,
      );
    });

    test('ChromeOS 上旧值等于旧规则推导值时丢弃', () {
      // ChromeOS 上新规则推导值为真，而旧实现按窗口尺寸写入的是假；
      // 旧值与旧规则推导值相同，说明是旧实现自动写入的，不能固化成用户设置
      expect(
        OrientationUtils.shouldKeepHorizontalScreenOverride(
          oldValue: false,
          isTablet: false,
          isChromeOS: true,
          legacyIsTablet: false,
        ),
        isFalse,
      );
    });

    test('旧值不同于两种自动推导值时保留，尊重用户显式设置', () {
      expect(
        OrientationUtils.shouldKeepHorizontalScreenOverride(
          oldValue: true,
          isTablet: false,
          isChromeOS: false,
          legacyIsTablet: false,
        ),
        isTrue,
      );
      expect(
        OrientationUtils.shouldKeepHorizontalScreenOverride(
          oldValue: false,
          isTablet: true,
          isChromeOS: false,
          legacyIsTablet: true,
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
