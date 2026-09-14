# ROADMAP

## Phase 1 — H5GG-style FloatUI v1 (current)

目标：只验证悬浮窗基础设施，不接任何广告/Hook 业务。

- [x] 独立透明 UIWindow
- [x] iOS 13+ UIWindowScene 绑定
- [x] 非 key-window 显示策略（不调用 makeKeyAndVisible）
- [x] 窗口空白区域触摸穿透
- [x] 52×52 圆形悬浮按钮
- [x] 按钮拖动与边界限制
- [x] 点击显示/隐藏面板
- [x] 面板标题栏拖动
- [x] 横竖屏/窗口尺寸变化位置修正
- [x] 定时前置按钮与面板
- [x] macOS/Xcode CI 构建
- [ ] 实机注入验证：按钮显示
- [ ] 实机验证：宿主空白区域触摸不受影响
- [ ] 实机验证：拖动/开关面板/旋转/多 Scene

## Phase 2

在 Phase 1 实机稳定后，再接入广告 Trace 数据模型与业务页面；不提前把 Hook 混进窗口基线。

## Next Task

下载 `DumpZhuanYongFloatUI.dylib`，注入目标 IPA，完成纯悬浮窗实机验证。
