# Floating UI baseline

## 官方参考

第一阶段不再依赖旧 HFAMap 分支，直接以 H5GG 官方仓库为架构参考：

- repo: `H5GG/H5GG`
- branch: `main`
- verified commit: `b47b56676c89124362bd11aa3aaf95b02c07ca22`
- files: `FloatButton.h`, `FloatWindow.h`, `makeWindow.h`, `Tweak.mm`

## 从 H5GG 复核出的关键机制

1. 悬浮按钮本身处理拖动，并把位置限制在父窗口范围。
2. iOS 13+ 新悬浮窗口应通过 `initWithWindowScene:` 绑定前台 `UIWindowScene`；旧系统使用屏幕 bounds 创建。
3. 悬浮层使用独立 `UIWindow`，而不是长期把所有 UI 强塞进宿主 keyWindow。
4. 独立窗口不调用 `makeKeyAndVisible`，避免改变宿主 keyWindow 行为。
5. `UIWindow` 需要做 hit-test/pointInside 过滤，只在悬浮控件区域接收触摸，让窗口其他透明区域穿透。
6. 悬浮按钮/面板需要持续保持在悬浮窗口内部最前层。
7. Window/Scene 尺寸变化时要重新约束控件位置。

## 本项目实现差异

- 不引入 H5GG 的 `UIWebView` / JavaScriptCore / Html 菜单。
- 不引入 H5GG 内存搜索引擎。
- 不引入 GlobalView 跨进程窗口、SpringBoard 或越狱组件。
- 使用纯 UIKit 原生面板，最小化依赖和崩溃面。
- 第一阶段 dylib 只编译 `src/float/*`。

目标是先验证稳定的 App 内悬浮窗口基础设施，再在后续阶段挂业务模块。
