# KNOWN_ISSUES

## KI-001 — 未实机验证

- 状态：OPEN
- 条件：当前只有静态 IPA 与 Linux 工作环境。
- 风险：无法确认宿主实际 Scene/Window 生命周期和广告全屏窗口时悬浮层表现。
- 下一步：注入 v0.1.0 实机冷启动验证。

## KI-002 — exact branch `hfamapuniversal` 当前不可见

- 状态：DOCUMENTED
- 现象：当前账号可访问仓库的活动 branch refs 中没有精确名为 `hfamapuniversal` 的分支。
- 已确认：旧仓库历史中存在 `HFAMapUniversal_*` 产物，并在 `feature/login-ip-tracer-dylib-v2-hfamap187-v1920-menu` 的 `HFAMapLegacy.m` 找到用户描述的 H5GG 风格悬浮按钮/面板实现。
- 处理：v0.1 固定上述真实 commit 为 UI baseline，不依赖不存在的 ref 名。

## KI-003 — Native show 未纳入 v0.1 hook

- 状态：OPEN
- 原因：Native show selector 含 `BOOL` 等非对象参数；v0.1 的通用 wrapper 仅处理 object ABI，避免错误调用约定。
- 当前覆盖：Native load + Flutter callback 仍可记录。
- 下一步：为 Native show 写精确 ABI wrapper 后再启用。
