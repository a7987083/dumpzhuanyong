# CHANGELOG_DEV

## 2026-09-15 — Phase 2: AD Trace v2 dev1

### Skills used

- `rev-symbol`
- `rev-ios-dump`
- `rev-frida`

### Target re-validation

- IPA SHA-256: `2b81549fc41576bd9d7209240d9210cfc6dac034afd98be3ce8ef3025d73827c`.
- Runner SHA-256: `509583df95221e004d97612aa183ea4091ac75e4c6c137d2da56b7051edcf268`.
- Runner UUID: `79F4AEE2-24AC-3D2F-BA53-BE5669D52212`.
- Runner: arm64, `LC_ENCRYPTION_INFO_64 cryptid=0`, min iOS 13.0.
- AnyThinkSDK SHA-256: `d46f1c443f57245055fd4dff43894fc8d7c19be4d38f5cf36c43d712027b6426`.
- Reconfirmed real symbols for Flutter bridge, Splash, Reward, Interstitial and `ATFSendSignalManger`.
- Cross-checked TopOn API family against `toponteam/TopOn-iOS-SDK` commit `07d4cdf77d1f0cf49ead841d428f7da9e73d0838`.

### Added

- `src/adtrace/DZAdTrace.h` / `DZAdTraceInternal.h`.
- `src/adtrace/DZAdTraceStore.m`:
  - thread-safe event store;
  - 200-event recent ring;
  - kind/stage counters;
  - JSONL log at `Documents/DumpZhuanYong_AdTrace_v2.jsonl`.
- `src/adtrace/DZAdTraceHooks.m`:
  - runtime class + selector resolution;
  - return/argument type encoding checks before IMP replacement;
  - Flutter call/callback, bridge manager, `ATAdManager`, delegate and Adapter observation;
  - original IMP preservation and forwarding;
  - dyld image-add rescan.
- `src/adtrace/DZAdTraceDashboard.m`:
  - attaches at runtime to existing `DZFloatPanel`;
  - does not modify `src/float/`;
  - shows hook/event counts, latest event, placement and provider;
  - trace on/off, rescan, clear and copy-log controls.
- `tools/frida/adtrace_probe.js`:
  - Frida 17+ read-only validation probe;
  - `Process.attachModuleObserver()` + `Interceptor.attach()`;
  - deterministic `rpc.exports.stop()`.
- `docs/ADTRACE_V2_ANALYSIS.md` with binary evidence and hook policy.

### Build / CI changes

- Build target changed on `feature/adtrace-v2` to `DumpZhuanYongAdTraceV2.dylib`.
- CI returned to the previously proven minimal build pipeline; release publishing is not part of this feature-branch build.
- Source checks reject Frida mutation primitives such as `Interceptor.replace`, `Memory.patchCode`, and `retval.replace`.

### Verification state

- Source implementation: completed.
- Target static re-validation: completed.
- CI compile: pending at time of this entry.
- Runtime injection: not yet tested for v2.

---

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
- 用户已确认 UI 可用。
