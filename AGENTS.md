## 项目测试技能

- 不要在每次任务完成后默认执行编译、`build`、`flutter analyze`、`flutter test` 或类似全量验证。
- 仅在以下情况才主动执行编译或较重验证：用户明确要求、改动直接影响构建链路或编译结果、需要复现或确认编译错误、准备交付发布相关变更。
- 对提示词、文档、注释、纯配置微调或可静态确认的小改动，优先做静态检查和针对性验证，不要习惯性在收尾时自动编译。
- 在 `D:\Project\re_w847tool` 中运行、调试、加速或解释测试前，先使用 `re-w847tool-testing` skill。
- 若测试失败、超时、卡住、锁定 `sqlite3.dll`，或出现明显延长测试时长的问题，按该 skill 的 `Self-Evolution` 流程记录事件。
- 记录位置：`C:\Users\w847\.codex\skills\re-w847tool-testing\references\test-history.md`。
- 可复用经验应同步整理到 `C:\Users\w847\.codex\skills\re-w847tool-testing\references\test-pitfalls.md`，避免下次重复排查。

## 搜索与查证优先级

- 简单搜索优先使用 `agentic-search` skill；复杂、多来源、需要深度整理或可复用研究会话的搜索优先使用 `multi-search-engine` skill。
- 简单搜索不要直接使用 `web` 工具，除非 `agentic-search` 不可用或明确无法满足需求。
- 对模型不确定、容易猜错、依赖最新信息或需要权威信源确认的内容，不要直接猜测；先使用合适的搜索 skill 查找并确认信源和关键信息，再继续执行后续任务。
