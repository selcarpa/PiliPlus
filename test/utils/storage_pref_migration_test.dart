import 'dart:io';

import 'package:PiliPlus/utils/device_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

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
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Pref.migrateHorizontalScreen', () {
    test('旧值与自动推导值相同时丢弃旧值，回归自动推导', () async {
      final isTablet = DeviceUtils.isTablet;
      await settingBox.put(SettingBoxKey.horizontalScreen, isTablet);

      await Pref.migrateHorizontalScreen();

      expect(settingBox.get(SettingBoxKey.horizontalScreenOverride), isNull);
      expect(settingBox.get(SettingBoxKey.horizontalScreen), isNull);
      expect(settingBox.get(SettingBoxKey.horizontalScreenMigrated), isTrue);
    });

    test('旧值与自动推导值不同时保留为显式设置', () async {
      final isTablet = DeviceUtils.isTablet;
      await settingBox.put(SettingBoxKey.horizontalScreen, !isTablet);

      await Pref.migrateHorizontalScreen();

      expect(
        settingBox.get(SettingBoxKey.horizontalScreenOverride),
        !isTablet,
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

    test('initEnvironment 冻结环境推导值，不随显示尺寸变化', () async {
      addTearDown(() => DeviceUtils.debugDisplaySizeOverride = null);

      // 冻结为「手机尺寸」
      DeviceUtils.debugDisplaySizeOverride = const Size(360, 800);
      await Pref.initEnvironment();
      final frozen = Pref.horizontalScreen;
      expect(frozen, isFalse);

      // 显示尺寸变为「平板尺寸」后，推导值不应随之改变
      DeviceUtils.debugDisplaySizeOverride = const Size(1280, 800);
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
