import 'package:PiliPlus/utils/system_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SystemBarUtils.shouldRequestImmersive', () {
    test('Android 15 以下请求 immersive', () {
      expect(
        SystemBarUtils.shouldRequestImmersive(isAndroid: true, sdkInt: 34),
        isTrue,
      );
      expect(
        SystemBarUtils.shouldRequestImmersive(isAndroid: true, sdkInt: 21),
        isTrue,
      );
    });

    test('Android 15 及以上不再请求 immersive', () {
      // Android 15(API 35) 起系统会忽略 immersive，
      // 而引擎切到 immersive 时会先关闭 edge-to-edge，导致内容被内缩而跳动
      expect(
        SystemBarUtils.shouldRequestImmersive(isAndroid: true, sdkInt: 35),
        isFalse,
      );
      expect(
        SystemBarUtils.shouldRequestImmersive(isAndroid: true, sdkInt: 37),
        isFalse,
      );
    });

    test('非 Android 平台保持原行为', () {
      expect(
        SystemBarUtils.shouldRequestImmersive(isAndroid: false, sdkInt: 35),
        isTrue,
      );
      expect(
        SystemBarUtils.shouldRequestImmersive(isAndroid: false, sdkInt: 0),
        isTrue,
      );
    });
  });
}
