/// 一次异步加载的 UI 状态 —— **底座只认这一套**。
/// 为什么要有它：底座会派生很多 app，如果每个页面各写一个 `XxxUiState`
/// （`isLoading` / `data` / `error` 三个字段自己拼），分支处理和空态早晚分叉。
/// 这里给一个四态密封类，页面 `switch` 一下就能穷举。
///
/// ```dart
/// UiState<List<Todo>> state = const UiLoading();
///
/// switch (state) {
///   case UiIdle() || UiLoading():
///     return const LoadingSkeleton();
///   case UiError(:final message):
///     return ErrorState(message: message, onRetry: reload);
///   case UiSuccess(:final data):
///     return TodoList(data);
/// }
/// ```
///
/// 它是**纯 UI 状态**，不携带仓库/网络类型；放在 data 层的加载结果由页面映射成它。
/// 纯 Dart，不依赖 Flutter —— 可以在任何地方构造和测试。
sealed class UiState<T> {
  const UiState();
}

/// 还没开始加载（首帧、或用户还没触发）。
///
/// 和 [UiLoading] 分开，是为了区分「空屏」和「转圈」——
/// 首帧就转圈，用户会以为一直在加载。
class UiIdle<T> extends UiState<T> {
  const UiIdle();
}

/// 正在加载。
class UiLoading<T> extends UiState<T> {
  const UiLoading();
}

/// 成功。[data] 是这次的结果（可以为空集合，空集合不是 [UiError]）。
class UiSuccess<T> extends UiState<T> {
  final T data;

  const UiSuccess(this.data);
}

/// 失败。[message] 是给用户看的一句话；[cause] 留着排查（日志/上报），别直接展示。
class UiError<T> extends UiState<T> {
  final String message;
  final Object? cause;

  const UiError(this.message, [this.cause]);
}

/// 成功时的数据；其余状态都是 null。
extension UiStateData<T> on UiState<T> {
  T? get dataOrNull => switch (this) {
        final UiSuccess<T> s => s.data,
        _ => null,
      };

  /// 是否正在加载（[UiIdle] 不算）。
  bool get isLoading => this is UiLoading<T>;

  /// 是否失败。
  bool get hasError => this is UiError<T>;
}

/// 只映射成功值，其余状态原样透传 ——
/// 用来把 `UiState<Entity>` 变成 `UiState<UiModel>`。
UiState<R> mapUiState<T, R>(UiState<T> state, R Function(T data) transform) =>
    switch (state) {
      UiIdle<T>() => UiIdle<R>(),
      UiLoading<T>() => UiLoading<R>(),
      UiSuccess<T>(:final data) => UiSuccess<R>(transform(data)),
      final UiError<T> e => UiError<R>(e.message, e.cause),
    };

/// 成功拿数据，其余状态用 [fallback]（列表页常用：加载中先给空列表）。
T orElseUiData<T>(UiState<T> state, T Function() fallback) =>
    state.dataOrNull ?? fallback();

/// 把一次异步调用包成 [UiState]。
///
/// 只捕获 [Exception]：`Error`（编程错误）必须冒出去，否则会被当成"加载失败"
/// 静默吞掉，bug 再也查不出来。
///
/// 文案兜底交给调用方：`UiError.message` 可能为空，UI 补一句默认文案更合适。
Future<UiState<T>> uiStateOf<T>(Future<T> Function() block) async {
  try {
    return UiSuccess<T>(await block());
  } on Exception catch (e) {
    return UiError<T>(e.toString(), e);
  }
}
