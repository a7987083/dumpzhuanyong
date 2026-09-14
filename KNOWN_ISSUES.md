# KNOWN_ISSUES

## KI-001 — FloatUI 未实机验证

- 状态：OPEN
- 已完成：源码实现、macOS/Xcode 编译验证。
- 未完成：真实 IPA 注入、启动、触摸穿透、拖动、旋转、多 Scene 回归。
- 风险：某些宿主会创建比 `UIWindowLevelAlert - 1` 更高的业务窗口，可能遮挡 FloatUI。
- 下一步：只注入 FloatUI dylib 实机验证。

## KI-002 — iPad 分屏/Stage Manager 未验证

- 状态：OPEN
- 当前实现：使用当前 `UIWindowScene` bounds，并在尺寸变化时按比例迁移按钮/面板位置后 clamp。
- 风险：Stage Manager / 外接屏场景可能存在多个 foreground Scene。
- 下一步：实机收集 Scene/window 状态后决定是否需要 scene affinity 规则。

## KI-003 — 宿主全屏高层级 Window

- 状态：OPEN
- 当前策略：FloatUI 使用独立 `UIWindow`，level=`UIWindowLevelAlert - 1`，且不抢 keyWindow。
- 风险：宿主自建更高 level 的全屏窗口可能盖住按钮。
- 原则：先验证真实目标；没有证据前不提高 level、不 hook UIWindow。

## KI-004 — 旧广告 Trace 源码仍存在于仓库历史/工作树

- 状态：EXPECTED
- 当前分支 Makefile 只编译 `src/float/*`，旧 Trace 不进入 `DumpZhuanYongFloatUI.dylib`。
- 后续：Phase 1 完成后再决定如何模块化接回，不在悬浮窗阶段混编。
