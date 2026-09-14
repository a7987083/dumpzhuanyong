# HANDOFF

## 当前目标

Phase 2：在稳定 `release/v1.0.0` FloatUI 基线上开发只读广告运行时 Trace。目标是闭合：

`Flutter -> AnyThink bridge -> ATAdManager / TopOn -> Adapter -> Delegate callback -> Flutter callback`。

## 当前分支

- repo: `a7987083/dumpzhuanyong`
- branch: `feature/adtrace-v2`
- stable FloatUI: `release/v1.0.0`

## 稳定层约束

`src/float/` 不修改。业务通过 `src/adtrace/DZAdTraceDashboard.m` 在运行时找到 `DZFloatPanel` 并覆盖 body 区域；按钮文字通过公开的 `setDisplayText:` 运行时调用改为 `AD`。

## 使用技能

- `rev-symbol`: 用真实 Runner 符号、类、selector 和地址做静态证据，不从单个字符串下结论。
- `rev-ios-dump`: 重新检查 Mach-O 加密状态和样本身份；当前 Runner `cryptid=0`。
- `rev-frida`: 采用观察优先、可停止、无 mutation 的动态验证策略，并提供 Frida 17+ probe。

## 目标二进制证据

- IPA SHA-256: `2b81549fc41576bd9d7209240d9210cfc6dac034afd98be3ce8ef3025d73827c`
- Runner SHA-256: `509583df95221e004d97612aa183ea4091ac75e4c6c137d2da56b7051edcf268`
- Runner UUID: `79F4AEE2-24AC-3D2F-BA53-BE5669D52212`
- Runner: arm64, `cryptid=0`, min iOS 13.0
- AnyThinkSDK SHA-256: `d46f1c443f57245055fd4dff43894fc8d7c19be4d38f5cf36c43d712027b6426`

关键本地符号地址仅作为这个 build 的证据，运行代码不写死：

- `0x1002e0574` `-[AnythinkSdkPlugin handleMethodCall:result:]`
- `0x1002ee44c` `-[ATFInterstitialManger loadInterstitialAd:extraDic:]`
- `0x1002fa114` `-[ATFRewardedVideoManger loadRewardedVideo:extraDic:]`
- `0x1002fc2a0` `-[ATFSendSignalManger sendMethod:arguments:result:]`
- `0x1002fc474` `-[ATFSplashAdManger loadSplashAd:extraDic:]`
- `0x1002fcae4` `-[ATFSplashAdManger showSplashAd:]`
- `0x1002fcc54` `-[ATFSplashAdManger showSplashAd:sceneID:]`

## 当前实现

- `src/adtrace/DZAdTraceStore.m`: event ring + counters + JSONL logger.
- `src/adtrace/DZAdTraceHooks.m`: ObjC runtime hook engine with ABI gate.
- `src/adtrace/DZAdTraceDashboard.m`: live dashboard attached to stable FloatUI.
- `tools/frida/adtrace_probe.js`: independent read-only runtime cross-check.
- `docs/ADTRACE_V2_ANALYSIS.md`: evidence and design rationale.

## Hook 安全条件

每个 IMP hook 在安装前必须同时满足：

1. class + selector 实际存在；
2. 显式参数数量完全匹配；
3. 返回类型为 `void`；
4. 所有显式参数 type encoding 是 object/class/SEL pointer-compatible；
5. 保存原 IMP 并原样调用。

不满足则跳过。禁止 return patch、广告屏蔽、奖励伪造。

## 接手顺序

1. `git status` / 当前 branch / HEAD。
2. 看 `PROJECT_STATE.json` 和 `ROADMAP.md`。
3. 看当前 GitHub Actions 的第一处真实错误；不要根据最后一行猜。
4. CI 通过后取 `DumpZhuanYongAdTraceV2.dylib` 和 SHA256。
5. 注入目标 IPA，冷启动一次。
6. 打开 AD 面板确认 `hooks > 0`，回收 `Documents/DumpZhuanYong_AdTrace_v2.jsonl`。
7. 用 Frida probe 做一次对照验证（有授权设备时）。
8. 只在真实日志证明字段稳定后做 provider/session 聚合。
