# KNOWN_ISSUES

## KI-001 — AD Trace v2 未实机验证

- 状态：OPEN
- 已完成：目标静态二次校验、v2 源码实现、只读安全策略。
- 未完成：真实 IPA 注入后的冷启动 Splash / Reward / Interstitial / Banner 时间线。
- 风险：目标进程中的实际 method type encoding 若与静态 selector 预期不同，对应 hook 会被 ABI gate 跳过。
- 下一步：CI 通过后实机检查 dashboard 中 `hooks` 数量与 JSONL。

## KI-002 — provider 字段尚未建立稳定映射

- 状态：OPEN
- 当前策略：优先以真正执行的 `AT*Adapter` 类名作为 provider 证据；callback/extra 中仅记录可观察字段，不把单个 key 强行解释为广告网络名称。
- 风险：不同 TopOn 版本的 `extra` key 名可能变化。
- 下一步：用真实运行日志收集 GDT / KS / Mintegral 等实际样本后建立映射。

## KI-003 — 部分 Native / SDK API 含 primitive 参数

- 状态：BY_DESIGN
- 当前 v2 通用 wrapper 只 hook `void` 返回且显式参数都是 object/class/SEL pointer-compatible 的方法。
- 结果：含 `BOOL`、整数、结构体等参数的方法会自动跳过。
- 原因：避免错误 ABI wrapper 导致宿主崩溃。
- 下一步：只有真实业务需要且已经恢复精确签名时，才增加专用 wrapper。

## KI-004 — FloatUI 横竖屏 / 多 Scene 未单独回归

- 状态：OPEN
- 用户已确认当前 UI 可用。
- 尚未单独声明验证：Stage Manager、外接屏、多 foreground Scene、宿主更高 windowLevel。
- 原则：Phase 2 不修改 `src/float/`；若出现 UI 问题，回到 FloatUI bugfix 流程处理。

## KI-005 — GitHub Actions 历史 startup_failure

- 状态：MONITOR
- 历史 `main` 发布工作流曾出现 `BuildFailed + startup_failure + 0 jobs`。
- 当前 `feature/adtrace-v2` 已恢复为之前成功过的最小 build workflow，不包含 Release 发布步骤。
- 验证标准：必须看到实际 Build / Verify Mach-O / Artifact steps 执行并成功，不能只看 workflow 已创建。
