// 契约样例 —— 各端跑同一批样例，谁改了行为或文案，红的就是谁。
//
// 跑法（不需要装任何依赖）：
//   node --test apps/<app>/miniprogram/test
// 或整个仓库一起跑：
//   bash scripts/ci.sh miniprogram
const test = require('node:test')
const assert = require('node:assert')
const path = require('node:path')

const { createActions } = require('../logic/actions.js')
const { memoryStorage } = require('../logic/storage.js')

// 契约文件在 miniprogram/ 的外面 —— 它是「各端共享」的东西，不属于任何一端
const contract = require(path.join(__dirname, '..', '..', 'contract', 'actions.json'))

test('契约样例全部通过', () => {
  contract.actions.forEach((sample) => {
    // 每条样例一份全新的动作表 —— 样例之间互不影响
    const actions = createActions(memoryStorage())
    const action = actions[sample.action]
    assert.ok(action, '动作表里没有动作 "' + sample.action + '"')
    const result = action(sample.input || {})
    assert.ok(
      result.indexOf(sample.expect) >= 0,
      sample.action + ' 的返回里没有 "' + sample.expect + '"，实际是：' + result,
    )
  })
})
