# DumpZhuanYong FloatUI + AD Trace v2

本仓库把**稳定悬浮窗基础层**和**项目业务层**分开维护。

- Stable FloatUI: `release/v1.0.0`
- Current development: `feature/adtrace-v2`
- `src/float/`: 稳定 UI 基线，Phase 2 不修改
- `src/adtrace/`: 当前目标 App 的只读广告诊断层

## Stable FloatUI

H5GG 风格 iOS 悬浮窗基础设施：

- 独立透明 `UIWindow`
- iOS 13+ `UIWindowScene` 绑定
- 非控件区域触摸穿透
- 52×52 可拖动悬浮按钮
- 可拖动面板
- 窗口尺寸变化适配
- 不调用 `makeKeyAndVisible`

稳定源码目录：

```text
src/float/
  DZFloatWindow.h/.m
  DZFloatButton.h/.m
  DZFloatPanel.h/.m
  DZFloatBootstrap.m
```

## AD Trace v2

第二阶段在不改 `src/float/` 的前提下新增：

```text
src/adtrace/
  DZAdTrace.h
  DZAdTraceInternal.h
  DZAdTraceStore.m
  DZAdTraceHooks.m
  DZAdTraceDashboard.m
```

能力：

- Flutter `AnythinkSdkPlugin` call Trace
- Native -> Flutter callback Trace
- Splash / Reward / Interstitial / Banner / Native bridge Trace
- `ATAdManager` / TopOn load/show Trace
- `ATF*Delegate` callback Trace
- `AT*Adapter` provider show Trace
- `placementID` / `sceneID` / provider 证据记录
- JSONL：`Documents/DumpZhuanYong_AdTrace_v2.jsonl`
- FloatUI 面板实时显示 hooks/events/最后事件

### 安全边界

v2 是诊断版：

- 不屏蔽广告
- 不修改返回值
- 不伪造激励奖励
- 不 patch 可执行代码
- 不写死目标 RVA/VA

Runtime Hook 安装前检查 Objective-C type encoding；只有 `void` 返回且显式参数 ABI 可以安全按对象指针处理的方法才安装。

## Optional Frida cross-check

`tools/frida/adtrace_probe.js` 是 Frida 17+ 只读验证脚本，只用 `Process.attachModuleObserver()` + `Interceptor.attach()`，并提供 `rpc.exports.stop()`。

## Build

```bash
make source-check
make clean all
make verify
```

输出：

```text
build/DumpZhuanYongAdTraceV2.dylib
```

## Evidence

目标样本的 SHA-256、Runner UUID、`cryptid`、关键 ObjC 符号地址和 TopOn upstream 交叉验证记录在：

`docs/ADTRACE_V2_ANALYSIS.md`

项目进度看 `PROJECT_STATE.json` / `ROADMAP.md` / `HANDOFF.md`。
