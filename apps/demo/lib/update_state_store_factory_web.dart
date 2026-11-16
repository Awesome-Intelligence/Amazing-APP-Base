import 'package:kit/kit.dart';

/// Web：没有文件系统，用内存实现。
///
/// 代价是刷新页面后节流状态丢失（会多打一次网络）——
/// 要跨刷新保留就自己实现一个基于 `window.localStorage` 的 `UpdateStateStore`。
Future<UpdateStateStore> createUpdateStateStore() async =>
    MemoryUpdateStateStore();
