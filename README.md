# DumpZhuanYong Ad Trace

iOS / Flutter 广告运行时只读诊断工具。第一版（v0.1.0）使用 HFAMapUniversal 历史版本中验证过的 H5GG 风格悬浮窗交互作为 UI 基线，针对目标 App 的 AnyThink / TopOn 广告桥接链进行运行时 Trace。

## v0.1.0 范围

- H5GG 风格悬浮按钮：拖动、点击显隐、面板拖动、跨 UIWindow 重挂载、置顶。
- Hook Flutter -> Native 入口：`AnythinkSdkPlugin handleMethodCall:result:`。
- Hook Native -> Flutter 回调：`ATFSendSignalManger sendMethod:arguments:result:`。
- Hook Splash / RewardedVideo / Interstitial / Banner 的桥接层 load/show。
- Hook `ATAdManager` 聚合层 load/show。
- 动态枚举 `AT*Adapter` 并观察实际 Splash / Reward / Interstitial provider 展示入口。
- 记录 `placementID`、`sceneID`、Flutter method/callback、TopOn extra、实际 Adapter 类。
- JSONL 日志：`Documents/DumpZhuanYong_AdTrace.jsonl`。
- 第一版严格只读：不拦截广告、不篡改返回值、不伪造奖励。

## 构建

要求 macOS + Xcode iPhoneOS SDK：

```bash
make clean all
make verify
```

GitHub Actions 会在 `main` push / PR 时构建并上传 `DumpZhuanYongAdTrace-v0.1.0` artifact。

## 目标 App 静态基线

- App: 栗子漫画
- Version: 1.1.5
- Build: 17
- Runner `cryptid=0`
- Flutter MethodChannel: `anythink_sdk`
- 聚合层: AnyThink / TopOn
- 已验证广告类型: Splash / RewardedVideo / Interstitial / Banner；Native 能力存在但第一版仅跟踪 load/callback。

详见 `docs/TARGET_ANALYSIS.md`、`docs/FLOATING_UI_BASELINE.md` 和项目状态文件。
