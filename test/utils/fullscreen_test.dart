import 'package:PiliPlus/plugin/pl_player/utils/fullscreen.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回归测试：`hideSystemBar()` / `showSystemBar()` 曾返回可空 Future，
/// 而图片查看器对其做了强制解包 `hideSystemBar()!`，
/// 在 Android 15+（不请求 immersive，直接返回 null）时会抛
/// `Null check operator used on a null value`。
///
/// 现在返回类型为非空 `Future<void>`，调用方无法再解包出 null，
/// 该测试同时锁定「返回值永不为 null」这一契约。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Android 15+ 隐藏系统栏仍返回非空 Future', () {
    // 回归用例：Android 15+ 分支曾直接 return null，
    // 图片查看器对返回值做了强制解包 `hideSystemBar()!`，
    // 在 Android 15+ 上会抛 `Null check operator used on a null value`
    expect(hideSystemBar(isAndroid: true, sdkInt: 35), isNotNull);
    // 复位内部状态，避免影响后续用例
    expect(showSystemBar(), isNotNull);
  });

  test('Android 15 以下隐藏系统栏返回非空 Future', () {
    expect(hideSystemBar(isAndroid: true, sdkInt: 34), isNotNull);
    expect(showSystemBar(), isNotNull);
  });

  test('showSystemBar 返回非空 Future', () {
    expect(showSystemBar(), isNotNull);
  });

  test('重复调用 hideSystemBar 仍返回非空 Future', () {
    expect(hideSystemBar(), isNotNull);
    expect(hideSystemBar(), isNotNull);
    expect(showSystemBar(), isNotNull);
  });
}
