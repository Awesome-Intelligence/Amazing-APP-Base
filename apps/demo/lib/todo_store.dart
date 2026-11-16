import 'package:kit/kit.dart';

/// 业务数据 + 业务动作。纯 Dart，不碰 UI。
///
/// 关键：**UI 的「删」按钮和 agent 的 `delete_todo` 工具调的是同一个 `remove`**，
/// 连结果文案都是同一句（见 `todo_skill.dart` 的 `DeleteTodoTool`）。
///
/// 存储走 `kit` 的 [EntityStore]（这里注入 [MemoryEntityStore]，可换文件实现），
/// 每个待办是一个实体：`{id, fields: {title, done}, body: ""}`。
class Todo {
  final String id;
  final String title;
  final bool done;
  Todo(this.id, this.title, [this.done = false]);
}

class TodoStore {
  final EntityStore _store;
  static const String _subdir = 'todos';

  TodoStore(this._store);

  /// 业务查询：返回不可变视图（按 id 排序）。
  Future<List<Todo>> list() async {
    final entities = await _store.loadAll(_subdir);
    entities.sort((a, b) => a.id.compareTo(b.id));
    return entities
        .map((e) => Todo(
              e.id,
              e.fields.strOrEmpty('title'),
              e.fields.boolOr('done', false),
            ))
        .toList();
  }

  /// 业务动作：新增。校验、结果文案都在这层。
  Future<String> add(String title) async {
    final t = title.trim();
    if (t.isEmpty) return '标题不能为空';
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _store.write(
      _subdir,
      StoredEntity(id: id, fields: {'title': t, 'done': false}),
    );
    return '已添加：$t';
  }

  /// 业务动作：删除。UI 按钮与 agent 工具共用此函数。
  Future<String> remove(String id) async {
    final ok = await _store.delete(_subdir, id);
    return ok ? '已删除' : '没找到要删的待办';
  }

  /// 列表摘要 —— **只有这一处**格式。
  ///
  /// agent 的 `list_todos` 工具和契约样例的 `list_todos` 动作都走它，
  /// 所以「模型看到的」和「契约钉住的」是同一句，不会各自拼一份。
  /// 空列表给一句人话而不是空串：模型拿到空串会以为自己没查到。
  Future<String> summary() async {
    final items = await list();
    if (items.isEmpty) return '（还没有待办）';
    return items.map((e) => '- ${e.title}').join('\n');
  }
}
