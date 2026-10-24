import 'dart:io';

import 'package:PiliPlus/utils/device_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// 手机的显示尺寸 / 窗口尺寸（逻辑像素）
const _phoneSize = Size(360, 800);

/// 平板的显示尺寸 / 窗口尺寸（逻辑像素）
const _tabletSize = Size(1280, 800);

void main() {
  late Directory tempDir;
  late Box<dynamic> settingBox;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('piliplus-pref-test-');
    Hive.init(tempDir.path);
    GStorage.regAdapter();
    settingBox = await Hive.openBox('setting');
    GStorage.setting = settingBox;
  });

  setUp(() async {
    await settingBox.clear();
    // 冻结值是静态字段，会在用例之间残留
    Pref.resetDerivedHorizontalScreen();
    DeviceUtils.debugDisplaySizeOverride = null;
    DeviceUtils.debugWindowSizeOverride = null;
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Pref.migrateHorizontalScreen', () {
    test('旧值等于自动推导值时丢弃旧值，回归自动推导', () async {
      // 手机：显示尺寸与窗口尺寸都是手机 -> 推导值为 false
      DeviceUtils.debugDisplaySizeOverride = _phoneSize;
      DeviceUtils.debugWindowSizeOverride = _phoneSize;
      await settingBox.put(SettingBoxKey.horizontalScreen, false);

      await Pref.migrateHorizontalScreen();

      expect(settingBox.get(SettingBoxKey.horizontalScreenOverride), isNull);
      expect(settingBox.get(SettingBoxKey.horizontalScreen), isNull);
      expect(settingBox.get(SettingBoxKey.horizontalScreenMigrated), isTrue);
    });

    test('旧值等于旧规则推导值时也丢弃旧值', () async {
      // 旧实现按窗口尺寸判定平板并写入该值；
      // 现在显示尺寸判定为手机，两者推导值不同，但旧值仍是自动写入的
      DeviceUtils.debugDisplaySizeOverride = _phoneSize;
      DeviceUtils.debugWindowSizeOverride = _tabletSize;
      await settingBox.put(SettingBoxKey.horizontalScreen, true);

      await Pref.migrateHorizontalScreen();

      expect(settingBox.get(SettingBoxKey.horizontalScreenOverride), isNull);
      expect(settingBox.get(SettingBoxKey.horizontalScreen), isNull);
      expect(settingBox.get(SettingBoxKey.horizontalScreenMigrated), isTrue);
    });

    test('旧值不同于任何自动推导值时保留为显式设置', () async {
      // 手机环境下旧值为 true，与两种自动推导值都不同 -> 用户显式设置
      DeviceUtils.debugDisplaySizeOverride = _phoneSize;
      DeviceUtils.debugWindowSizeOverride = _phoneSize;
      await settingBox.put(SettingBoxKey.horizontalScreen, true);

      await Pref.migrateHorizontalScreen();

      expect(
        settingBox.get(SettingBoxKey.horizontalScreenOverride),
        isTrue,
      );
      expect(settingBox.get(SettingBoxKey.horizontalScreen), isNull);
      expect(settingBox.get(SettingBoxKey.horizontalScreenMigrated), isTrue);
    });

    test('全新安装不写入显式设置', () async {
      await Pref.migrateHorizontalScreen();

      expect(settingBox.get(SettingBoxKey.horizontalScreenOverride), isNull);
      expect(settingBox.get(SettingBoxKey.horizontalScreenMigrated), isTrue);
    });

    test('已迁移过时不再重复迁移', () async {
      await settingBox.put(SettingBoxKey.horizontalScreenMigrated, true);
      await settingBox.put(SettingBoxKey.horizontalScreen, true);

      await Pref.migrateHorizontalScreen();

      expect(settingBox.get(SettingBoxKey.horizontalScreenOverride), isNull);
      // 旧键保持不变，说明没有再次执行迁移
      expect(settingBox.get(SettingBoxKey.horizontalScreen), isTrue);
    });

    test('迁移后旧键被删除', () async {
      await settingBox.put(SettingBoxKey.horizontalScreen, true);

      await Pref.migrateHorizontalScreen();

      expect(settingBox.containsKey(SettingBoxKey.horizontalScreen), isFalse);
    });
  });

  group('Pref.horizontalScreen', () {
    test('显式设置优先于环境推导', () async {
      await settingBox.put(SettingBoxKey.horizontalScreenOverride, true);

      expect(Pref.horizontalScreen, isTrue);

      await settingBox.put(SettingBoxKey.horizontalScreenOverride, false);

      expect(Pref.horizontalScreen, isFalse);
    });

    test('删除显式设置后回归自动推导', () async {
      DeviceUtils.debugDisplaySizeOverride = _tabletSize;
      DeviceUtils.debugWindowSizeOverride = _tabletSize;
      await settingBox.put(SettingBoxKey.horizontalScreenOverride, false);

      expect(Pref.horizontalScreen, isFalse);

      // 「恢复自动」= 删除显式设置
      await settingBox.delete(SettingBoxKey.horizontalScreenOverride);

      expect(Pref.horizontalScreen, isTrue);
      expect(Pref.derivedHorizontalScreen, isTrue);
    });

    test('initEnvironment 冻结环境推导值，不随显示尺寸变化', () async {
      // 冻结为「手机尺寸」
      DeviceUtils.debugDisplaySizeOverride = _phoneSize;
      await Pref.initEnvironment();
      final frozen = Pref.horizontalScreen;
      expect(frozen, isFalse);

      // 显示尺寸变为「平板尺寸」后，推导值不应随之改变
      DeviceUtils.debugDisplaySizeOverride = _tabletSize;
      expect(DeviceUtils.isTablet, isTrue);
      expect(Pref.horizontalScreen, frozen);
    });
  });

  group('Pref.fullScreenMode', () {
    test('无显式设置时不写回存储，避免固化环境推导值', () {
      final mode = Pref.fullScreenMode;

      // 默认值只计算不落盘
      expect(settingBox.containsKey(SettingBoxKey.fullScreenMode), isFalse);
      // 多次读取结果一致（不会因写回而固化成用户设置）
      expect(Pref.fullScreenMode, mode);
    });

    test('有显式设置时读取存储值', () async {
      await settingBox.put(SettingBoxKey.fullScreenMode, 1);

      expect(Pref.fullScreenMode.index, 1);
    });
  });
}
