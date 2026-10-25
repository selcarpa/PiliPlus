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

  tearDown(() {
    DeviceUtils.debugDisplaySizeOverride = null;
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Pref.horizontalScreen', () {
    test('平板未显式设置时默认开启，且不写回存储', () {
      DeviceUtils.debugDisplaySizeOverride = const Size(1280, 800);

      expect(Pref.horizontalScreen, isTrue);
      expect(settingBox.containsKey(SettingBoxKey.horizontalScreen), isFalse);
    });

    test('手机未显式设置时默认关闭', () {
      DeviceUtils.debugDisplaySizeOverride = const Size(360, 800);

      expect(Pref.horizontalScreen, isFalse);
      expect(settingBox.containsKey(SettingBoxKey.horizontalScreen), isFalse);
    });

    test('显式设置优先于设备默认值', () async {
      DeviceUtils.debugDisplaySizeOverride = const Size(1280, 800);
      await settingBox.put(SettingBoxKey.horizontalScreen, false);

      expect(Pref.horizontalScreen, isFalse);

      DeviceUtils.debugDisplaySizeOverride = const Size(360, 800);
      await settingBox.put(SettingBoxKey.horizontalScreen, true);

      expect(Pref.horizontalScreen, isTrue);
    });
  });

  group('Pref.fullScreenMode', () {
    test('无显式设置时不写回存储', () {
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
