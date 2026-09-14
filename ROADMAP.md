# ROADMAP

## Phase 1 — H5GG-style FloatUI v1

稳定基线：`release/v1.0.0`

- [x] 独立透明 UIWindow
- [x] iOS 13+ UIWindowScene 绑定
- [x] 非 key-window 显示策略
- [x] 窗口空白区域触摸穿透
- [x] 52×52 悬浮按钮、拖动、边界限制
- [x] 面板显示/隐藏、标题栏拖动
- [x] 尺寸变化位置修正
- [x] macOS/Xcode CI 构建
- [x] 用户实机确认 UI 可用

`src/float/` 作为稳定层冻结；除 UI bugfix 外不修改。

## Phase 2 — AD Trace v2 (current)

目标：在不修改稳定 FloatUI 的前提下，建立 Flutter -> AnyThink/TopOn -> Adapter -> callback 的只读时间线。

- [x] 重新校验目标 IPA / Runner / AnyThinkSDK 哈希与 Mach-O 加密状态
- [x] 重新校验关键 ObjC 类、selector 和本地符号地址
- [x] 新建 `src/adtrace/` 模块
- [x] JSONL 事件存储与最近事件环形缓存
- [x] Objective-C runtime ABI gate：void 返回 + object-compatible args
- [x] Flutter MethodChannel call/callback Trace
- [x] Splash / Reward / Interstitial / Banner / Native bridge Trace
- [x] `ATAdManager` TopOn 层 Trace
- [x] Delegate callback 动态 Trace
- [x] `AT*Adapter` show 动态 Trace
- [x] 在现有 FloatUI 面板上运行时覆盖 AD Trace Dashboard，不改 `src/float/`
- [x] Frida 17+ 只读对照探针
- [x] 只读安全检查：不 replace、不 patch、不改 retval
- [ ] GitHub Actions 编译通过
- [ ] 回收 v2 dylib SHA-256 / Mach-O 验证结果
- [ ] 实机冷启动闭合 Splash 时间线
- [ ] 实机激励广告闭合 load -> show -> reward -> close
- [ ] 实机插屏/Banner 验证
- [ ] 从真实 callback extra 提取稳定 provider/source 字段

## Phase 3

在 Phase 2 有真实运行日志后，再做会话聚合、过滤和导出；没有运行证据前不增加广告修改功能。

## Next Task

等待 `feature/adtrace-v2` 的首次 CI 结果；若失败，以第一处真实编译错误为准修复。CI 通过后注入目标 IPA，先做一次冷启动 Splash Trace。
