import 'dart:io';

import 'package:kit/kit.dart';
import 'package:kit/kit_io.dart';
import 'package:path_provider/path_provider.dart';

/// 移动端 / 桌面：落到 app 私有目录。
///
/// 用 `getApplicationSupportDirectory()` 而不是临时目录 ——
/// 临时目录会被系统清理，节流状态一没就要重新联网。
Future<UpdateStateStore> createUpdateStateStore() async {
  final Directory dir = await getApplicationSupportDirectory();
  return FileUpdateStateStore(dir);
}
