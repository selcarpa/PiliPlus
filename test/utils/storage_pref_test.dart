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
    DeviceUtils.debugSizeOverride = null;
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Pref.horizontalScreen', () {
    test('平板未显式设置时默认开启并写回存储', () {
      DeviceUtils.debugSizeOverride = const Size(1280, 800);

      expect(Pref.horizontalScreen, isTrue);
      expect(settingBox.get(SettingBoxKey.horizontalScreen), isTrue);
    });

    test('手机未显式设置时默认关闭并写回存储', () {
      DeviceUtils.debugSizeOverride = const Size(360, 800);

      expect(Pref.horizontalScreen, isFalse);
      expect(settingBox.get(SettingBoxKey.horizontalScreen), isFalse);
    });

    test('显式设置优先于设备默认值', () async {
      DeviceUtils.debugSizeOverride = const Size(1280, 800);
      await settingBox.put(SettingBoxKey.horizontalScreen, false);

      expect(Pref.horizontalScreen, isFalse);

      DeviceUtils.debugSizeOverride = const Size(360, 800);
      await settingBox.put(SettingBoxKey.horizontalScreen, true);

      expect(Pref.horizontalScreen, isTrue);
    });
  });

  group('Pref.fullScreenMode', () {
    test('无显式设置时按环境计算默认值并写回存储', () {
      final mode = Pref.fullScreenMode;

      expect(settingBox.get(SettingBoxKey.fullScreenMode), mode.index);
      // 多次读取结果一致
      expect(Pref.fullScreenMode, mode);
    });

    test('有显式设置时读取存储值', () async {
      await settingBox.put(SettingBoxKey.fullScreenMode, 1);

      expect(Pref.fullScreenMode.index, 1);
    });
  });
}
