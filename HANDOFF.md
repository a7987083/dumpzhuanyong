# HANDOFF

## 当前目标

对 `516415ecaa177dbc217b251d8871204e.ipa` 的广告链进行运行时只读 Trace，闭合 Flutter -> AnyThink/TopOn -> Adapter -> callback -> Flutter 的真实调用时间线。

## 稳定基线

悬浮 UI 基线：

- `a7987083/UnitXP_SP3-Moonstone`
- `feature/login-ip-tracer-dylib-v2-hfamap187-v1920-menu`
- `b9c1f48882f41090446f48b7dac1229495524043`
- `hfamap/src/HFAMapLegacy.m`

目标二进制静态基线：

- App `1.1.5 (17)`
- `Runner` cryptid=0
- Flutter MethodChannel `anythink_sdk`
- 聚合层 AnyThink/TopOn

## 实现边界

`DZTraceCore.m` 使用 Objective-C runtime 按类名 + selector 动态安装 hook；不链接广告 SDK headers，因此宿主没有对应类时不会产生硬依赖。周期性 rescan 处理 SDK 类延迟加载。

第一版所有 hook 都要求：

- 方法返回类型为 `void`
- Objective-C 参数数量与 hook spec 一致

不满足就跳过，避免错误 ABI hook。

## 风险

- App/SDK 升级后 selector 参数 ABI 可能变化，必须重新读取真实 Method type encoding；不能复用旧 offset。
- 某些 Adapter 可能继承 show 方法；hook engine 会在具体 class 上 `class_addMethod` 覆盖，避免直接篡改 superclass。
- 还没有实机验证 Window/Scene 切换、广告全屏窗口期间的触摸层级。

## 接手顺序

1. 看 `PROJECT_STATE.json`。
2. 看 Git HEAD/status/Actions。
3. 取得 CI 生成 dylib。
4. 注入目标 IPA 并签名安装。
5. 冷启动后打开 AD 悬浮面板，确认 Hooks > 0。
6. 回收 `Documents/DumpZhuanYong_AdTrace.jsonl`。
7. 按 `ROADMAP.md` Phase 2 做结构化会话聚合。
