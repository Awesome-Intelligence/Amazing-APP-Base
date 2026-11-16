import 'storage.dart';
import 'membership_state.dart';

/// 会员状态的本地持久化：一个 JSON 文件（app 内部存储）。
///
/// 目录/后端由调用方给（Android 传文件后端，iOS 传另一个，Web 传 localStorage 后端）。
class MembershipStore {
  final JsonFile<Membership> _file;

  MembershipStore(StorageBackend backend)
      : _file = JsonFile<Membership>(
          backend,
          Membership.fromJson,
          (m) => m.toJson(),
          Membership.free(),
        );

  /// 读会员状态；文件不存在或读坏了都返回免费档。
  Future<Membership> load() => _file.read();

  /// 写会员状态（覆盖整个文件）。
  Future<void> save(Membership membership) => _file.write(membership);
}
