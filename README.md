# DumpZhuanYong FloatUI

可复用的 iOS H5GG 风格悬浮窗基线。当前稳定版本只负责 UI 基础层，不包含广告 Trace、Hook、内存修改或其他业务逻辑。

## Stable baseline

- Branch: `main`
- FloatUI source baseline: `a152eba94d65811fda6244b9160bbd09e694ab6f`
- H5GG upstream reference: `H5GG/H5GG@b47b56676c89124362bd11aa3aaf95b02c07ca22`
- Minimum iOS: 12.0
- Architecture: arm64

## 能力

- 独立透明 `UIWindow`
- iOS 13+ `UIWindowScene` 绑定
- 透明区域触摸穿透
- 52x52 圆形悬浮按钮
- 按钮拖动并约束在可视区域
- 点击展开/收起面板
- 面板拖动
- 横竖屏 / Scene 尺寸变化适配
- 周期性置顶
- 不调用 `makeKeyAndVisible`，不主动抢宿主 keyWindow

## 复用方式

其他项目优先复用 `src/float/` 目录：

```text
src/float/
  DZFloatWindow.h/.m
  DZFloatButton.h/.m
  DZFloatPanel.h/.m
  DZFloatBootstrap.m
```

业务项目只需要把自己的功能控件、日志、Hook 状态等接到 `DZFloatPanel`，无需重新实现 Window / Scene / 拖动 / 触摸穿透。

## Build

```bash
make clean all
make verify
```

输出：

```text
build/DumpZhuanYongFloatUI.dylib
```

## 验证状态

- GitHub Actions 编译：PASS
- Mach-O arm64 dylib：PASS
- iOS min version 12.0：PASS
- 用户实机 UI 验证：PASS

后续项目应把这一版视为稳定 UI 基线；新业务功能在独立分支上开发，避免修改稳定基线。
