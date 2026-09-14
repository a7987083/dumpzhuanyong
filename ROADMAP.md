# ROADMAP

## Phase 1 — v0.1.0 (current)

目标：建立稳定、只读的广告运行时 Trace 基线。

- [x] HFAMap/H5GG 风格悬浮按钮与面板
- [x] Flutter method call Trace
- [x] AnyThink bridge load/show Trace
- [x] TopOn `ATAdManager` load/show Trace
- [x] Adapter show Trace
- [x] Flutter callback Trace
- [x] JSONL 文件日志
- [x] macOS/Xcode CI build workflow
- [ ] 实机注入验证
- [ ] 用一次完整启动闭合 Splash 时间线

## Phase 2

- 按 placementID 聚合一次广告会话的 load -> ready -> show -> click -> close/reward。
- 从 callback `extra` 中结构化提取 network/source/request 信息。
- 增加运行时 SDK/Adapter 版本快照。
- 增加日志导出/复制按钮。

## Next Task

在目标 IPA 注入 v0.1.0，完成一次冷启动 + 一次激励广告 + 一次插屏流程，回收 `DumpZhuanYong_AdTrace.jsonl` 做第一轮实机验证。
