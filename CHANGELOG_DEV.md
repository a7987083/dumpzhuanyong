# CHANGELOG_DEV

## 2026-09-15 — Phase 1: H5GG-style FloatUI v1

### Direction change

- 第一阶段改为只做悬浮窗基础设施。
- 不再从旧 HFAMap 分支提取 UI；直接复核 H5GG 官方仓库 `H5GG/H5GG`。
- 参考 commit：`b47b56676c89124362bd11aa3aaf95b02c07ca22`。

### Added

- `src/float/DZFloatWindow.*`
  - 独立透明 `UIWindow`。
  - iOS 13+ `UIWindowScene` 绑定。
  - 仅悬浮按钮/面板区域接收触摸，其余区域穿透。
  - RootController 跟随宿主 orientation mask。
- `src/float/DZFloatButton.*`
  - 52×52 圆形浮动按钮。
  - 点击回调、拖动、屏幕边界限制。
- `src/float/DZFloatPanel.*`
  - 原生 UIKit 面板。
  - 标题栏拖动与关闭。
- `src/float/DZFloatBootstrap.m`
  - constructor 启动。
  - Scene 变化重建 overlay window。
  - 窗口尺寸变化按比例迁移控件位置并 clamp。
  - 0.25s 前置维护。
- Makefile / CI 切为只构建 `DumpZhuanYongFloatUI.dylib`。

### Verification

- 源码提交：`a152eba94d65811fda6244b9160bbd09e694ab6f`。
- GitHub Actions run `34869124317`：Build / Verify Mach-O / SHA-256 / Artifact upload 全部通过。
- 产物：Mach-O 64-bit arm64 dylib。
- `LC_BUILD_VERSION`: platform iOS, min iOS 12.0, SDK 26.5。
- `LC_ID_DYLIB`: `@rpath/DumpZhuanYongFloatUI.dylib`。
- dylib SHA-256：`db6acd39d41ed176fcd1e0a65eaff7d3d5181c23074d2fab826e0870b45977d4`。
- 未实机注入；触摸穿透/旋转/多 Scene 尚未运行验证。

## Earlier work

旧广告 Trace 第一版保留在 `main` 历史中，本 FloatUI 分支不编译那些业务源码。
