# DumpZhuanYong FloatUI

第一阶段只做 iOS 悬浮窗，不接广告 Trace、Hook、日志或其他业务逻辑。

本分支以 H5GG 官方仓库 `H5GG/H5GG` 的悬浮层架构为参考，重新实现一套最小原生版本：

- 独立透明 `UIWindow`，不把面板直接塞进宿主 keyWindow。
- iOS 13+ 绑定当前前台 `UIWindowScene`。
- 不调用 `makeKeyAndVisible`，避免抢宿主 key window / responder。
- 窗口仅在悬浮按钮或面板区域响应触摸；其余区域穿透给宿主 App。
- 52×52 圆形悬浮按钮，可拖动并限制在屏幕范围内。
- 点击按钮显示/隐藏面板。
- 面板标题栏可拖动，至少保留标题区域在屏幕内。
- 横竖屏/窗口尺寸变化后按比例迁移位置并重新 clamp。
- 定时 `bringSubviewToFront:`，保持按钮和面板在本悬浮窗口内部最前层。

## H5GG 参考源码

- `H5GG/H5GG/FloatButton.h`
- `H5GG/H5GG/FloatWindow.h`
- `H5GG/H5GG/makeWindow.h`
- `H5GG/H5GG/Tweak.mm`

本项目没有引入 H5GG 的 UIWebView/JavaScriptCore/内存搜索引擎，也没有复制其 GlobalView 跨进程模块；第一阶段只实现 App 内独立悬浮窗口。

## 构建

要求 macOS + Xcode iPhoneOS SDK：

```bash
make clean all
make verify
```

输出：

```text
build/DumpZhuanYongFloatUI.dylib
```

当前开发分支：`feature/h5gg-floating-window-v1`。
