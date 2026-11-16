import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';

void main() {
  group('SettingsStore', () {
    test('默认设置', () async {
      final store = SettingsStore(MemoryStorageBackend());
      final s = await store.load();
      expect(s.themeStyle, ThemeStyle.mono);
      expect(s.appearanceMode, AppearanceMode.system);
      expect(s.reducedMotion, false);
      expect(s.language, AppLanguage.system);
    });

    test('落盘往返', () async {
      final store = SettingsStore(MemoryStorageBackend());
      await store.save(const AppSettings(
        themeStyle: ThemeStyle.eInk,
        appearanceMode: AppearanceMode.dark,
        reducedMotion: true,
        language: AppLanguage.english,
      ));

      final loaded = await store.load();
      expect(loaded.themeStyle, ThemeStyle.eInk);
      expect(loaded.appearanceMode, AppearanceMode.dark);
      expect(loaded.reducedMotion, true);
      expect(loaded.language, AppLanguage.english);
    });

    test('损坏内容回默认', () async {
      final backend = MemoryStorageBackend();
      await backend.write('not json{{{');
      expect((await SettingsStore(backend).load()).themeStyle, ThemeStyle.mono);
    });
  });

  group('AppearanceMode.resolveDark', () {
    test('system 跟随，light/dark 强制', () {
      expect(AppearanceMode.system.resolveDark(true), true);
      expect(AppearanceMode.system.resolveDark(false), false);
      expect(AppearanceMode.light.resolveDark(true), false);
      expect(AppearanceMode.dark.resolveDark(false), true);
    });
  });
}
