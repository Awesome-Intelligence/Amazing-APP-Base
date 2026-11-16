const { createStore } = require('../../logic/store.js')
const { wxStorage } = require('../../logic/storage.js')
const zh = require('../../i18n/zh.js')
const en = require('../../i18n/en.js')

// 界面文案跟随系统语言：英文系统用 en.js，其余（含中文）落 zh.js 兜底。
// 跟 native 端一致 —— composeResources 的 values/ 是中文，values-en/ 是英文。
// 两个 require 都写成静态路径，小程序的打包器才能静态分析到。
function systemLanguage() {
  if (typeof wx === 'undefined') return '' // Node 里跑契约样例时没有 wx
  try {
    const info = wx.getAppBaseInfo ? wx.getAppBaseInfo() : wx.getSystemInfoSync()
    return (info.language || '').toLowerCase()
  } catch (e) {
    return ''
  }
}

const t = systemLanguage().startsWith('en') ? en : zh

// 页面只做「取数据 + 调动作」，逻辑在 logic/ 里 —— 界面不写业务规则。
Page({
  data: {
    todos: [],
    draft: '',
    addText: t.add,
    removeText: t.remove,
    emptyText: t.empty,
    placeholder: t.placeholder,
  },

  onShow() {
    this.refresh()
  },

  refresh() {
    this.setData({ todos: createStore(wxStorage()).items() })
  },

  onDraft(e) {
    this.setData({ draft: e.detail.value })
  },

  onAdd() {
    const draft = this.data.draft
    if (!draft) return
    createStore(wxStorage()).add(draft)
    this.setData({ draft: '' })
    this.refresh()
  },

  onRemove(e) {
    createStore(wxStorage()).remove(e.currentTarget.dataset.id)
    this.refresh()
  },
})
