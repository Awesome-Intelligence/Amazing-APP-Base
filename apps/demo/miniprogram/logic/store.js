// 业务逻辑 —— **纯逻辑，不认识 wx**。
//
// 想换存储（内存 / 文件 / 云端）就换传入的 storage，逻辑一行不用改。
// ponytail: 这是个待办示例。换成你自己的业务时，保持「动作返回一句结果文案」这个约定：
// 那句话会同时出现在界面上和契约里，是各端唯一不许分叉的东西。
const KEY = 'todos'

function createStore(storage) {
  function all() {
    const raw = storage.get(KEY)
    return Array.isArray(raw) ? raw : []
  }

  function save(list) {
    storage.set(KEY, list)
  }

  // id 形如 t1、t2 —— 从已有数据里推下一个号，重启后不会重号
  function nextId(list) {
    let max = 0
    list.forEach((item) => {
      const n = Number(String(item.id).replace(/^t/, ''))
      if (!Number.isNaN(n) && n > max) max = n
    })
    return 't' + (max + 1)
  }

  return {
    items() {
      return all()
    },

    // 新增一条待办，返回一句结果文案
    //
    // 文案要和 Flutter 端的 `TodoStore.add` 一字不差 —— 契约
    // （../../contract/actions.json）钉的就是这句话。
    add(title) {
      const text = String(title === undefined || title === null ? '' : title).trim()
      if (!text) return '标题不能为空'
      const list = all()
      const todo = { id: nextId(list), title: text }
      save(list.concat([todo]))
      return '已添加：' + todo.title
    },

    // 删除一条待办，返回一句结果文案
    remove(id) {
      const list = all()
      const hit = list.some((item) => item.id === id)
      if (!hit) return '没找到要删的待办'
      save(list.filter((item) => item.id !== id))
      return '已删除'
    },

    // 列表摘要 —— 一行一条，空的时候给一句话
    //
    // 和 Flutter 的 `TodoStore.summary` 同格式（`- 标题`）：
    // agent 看到的、契约钉住的、小程序界面显示的，是同一份文本。
    summary() {
      const list = all()
      if (!list.length) return '（还没有待办）'
      return list.map((item) => '- ' + item.title).join('\n')
    },
  }
}

module.exports = { createStore }
