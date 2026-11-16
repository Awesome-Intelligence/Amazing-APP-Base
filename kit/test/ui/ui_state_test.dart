import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit_ui.dart';

void main() {
  group('UiState', () {
    test('四种状态的 dataOrNull / isLoading / hasError', () {
      const UiState<String> idle = UiIdle();
      const UiState<String> loading = UiLoading();
      const UiState<String> success = UiSuccess('数据');
      const UiState<String> error = UiError('炸了');

      expect(idle.dataOrNull, isNull);
      expect(idle.isLoading, isFalse, reason: '首帧不是加载中');
      expect(idle.hasError, isFalse);

      expect(loading.dataOrNull, isNull);
      expect(loading.isLoading, isTrue);

      expect(success.dataOrNull, '数据');
      expect(success.isLoading, isFalse);
      expect(success.hasError, isFalse);

      expect(error.dataOrNull, isNull);
      expect(error.hasError, isTrue);
    });

    test('空集合是 Success，不是 Error', () {
      const UiState<List<String>> state = UiSuccess(<String>[]);
      expect(state.dataOrNull, isEmpty);
      expect(state.hasError, isFalse);
    });

    test('mapUiState 只动成功值，其余原样透传', () {
      expect(mapUiState<int, String>(const UiIdle(), (i) => '$i'), isA<UiIdle<String>>());
      expect(mapUiState<int, String>(const UiLoading(), (i) => '$i'),
          isA<UiLoading<String>>());
      expect(mapUiState<int, String>(const UiSuccess(7), (i) => '值$i').dataOrNull,
          '值7');

      final mapped = mapUiState<int, String>(const UiError('断了'), (i) => '$i');
      expect(mapped, isA<UiError<String>>());
      expect((mapped as UiError<String>).message, '断了');
    });

    test('orElseUiData 在没数据时给兜底', () {
      expect(orElseUiData<int>(const UiLoading(), () => -1), -1);
      expect(orElseUiData<int>(const UiSuccess(3), () => -1), 3);
    });

    test('switch 能穷举四态（编译期保障）', () {
      String describe(UiState<int> state) => switch (state) {
            UiIdle() => 'idle',
            UiLoading() => 'loading',
            UiSuccess(:final data) => 'ok:$data',
            UiError(:final message) => 'err:$message',
          };

      expect(describe(const UiIdle()), 'idle');
      expect(describe(const UiLoading()), 'loading');
      expect(describe(const UiSuccess(1)), 'ok:1');
      expect(describe(const UiError('x')), 'err:x');
    });
  });

  group('uiStateOf', () {
    test('正常返回 → Success', () async {
      final state = await uiStateOf(() async => 42);
      expect(state, isA<UiSuccess<int>>());
      expect(state.dataOrNull, 42);
    });

    test('抛 Exception → Error，cause 留着排查', () async {
      final state = await uiStateOf<int>(() async => throw Exception('网络断了'));
      expect(state, isA<UiError<int>>());
      final error = state as UiError<int>;
      expect(error.message, contains('网络断了'));
      expect(error.cause, isNotNull);
    });

    test('抛 Error（编程错误）→ 不吞，直接冒出去', () async {
      // StateError 是 Error 不是 Exception：吞掉会把 bug 伪装成"加载失败"
      expect(
        () => uiStateOf<int>(() async => throw StateError('写错了')),
        throwsA(isA<StateError>()),
      );
    });
  });
}
