# HANDOFF

## 当前目标

第一阶段只做 iOS 悬浮窗基础设施。不要接广告 Trace、Hook、日志业务，先把窗口生命周期和触摸行为做稳定。

## 当前分支

- repo: `a7987083/dumpzhuanyong`
- branch: `feature/h5gg-floating-window-v1`

## H5GG 官方参考基线

- repo: `H5GG/H5GG`
- branch: `main`
- commit: `b47b56676c89124362bd11aa3aaf95b02c07ca22`
- files: `FloatButton.h`, `FloatWindow.h`, `makeWindow.h`, `Tweak.mm`

## 当前实现

- `src/float/DZFloatWindow.*`：独立透明窗口、Scene/宿主窗口查找、非悬浮区域触摸穿透。
- `src/float/DZFloatButton.*`：52×52 圆形按钮、点击、拖动、边界限制。
- `src/float/DZFloatPanel.*`：原生面板、标题栏拖动、关闭按钮。
- `src/float/DZFloatBootstrap.m`：constructor 启动、独立 Window 生命周期、Scene 切换、旋转尺寸变化、持续前置。
- `Makefile`：只编译上述 FloatUI，不编译旧广告 Trace。

## 关键设计约束

1. 不调用 `makeKeyAndVisible`。
2. 不修改宿主 keyWindow/rootViewController。
3. iOS 13+ 使用 `initWithWindowScene:`。
4. 透明窗口空白区域必须触摸穿透。
5. Scene 变化时销毁旧 overlay window 并在新 Scene 重建。
6. 后续业务必须在悬浮窗实机稳定后再接。

## 未完成验证

- 实机是否显示按钮。
- 空白区域是否完全不拦截宿主触摸。
- 面板开关与拖动。
- 横竖屏、iPad 分屏/多 Scene。
- 全屏系统弹窗或宿主高 windowLevel 场景下的层级。

## Next Task

下载 CI 产出的 `DumpZhuanYongFloatUI.dylib`，只注入该 dylib 进行第一轮实机验证。
