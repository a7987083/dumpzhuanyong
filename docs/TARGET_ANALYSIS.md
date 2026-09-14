# Target analysis — 516415ecaa177dbc217b251d8871204e.ipa

## 已静态确认

目标 App：Flutter iOS App，版本 `1.1.5 (17)`。主二进制 `Runner` 的 `LC_ENCRYPTION_INFO_64 cryptid=0`，当前样本可直接静态分析。

广告链：

```text
Flutter
 -> FlutterMethodChannel("anythink_sdk")
 -> AnythinkSdkPlugin
 -> ATFAdManger
 -> ATFSplashAdManger / ATFRewardedVideoManger / ATFInterstitialManger / ATFBannerManger / ATFNativeManger
 -> ATAdManager
 -> AT*Adapter
```

IPA 内确认存在 AnyThink/TopOn 聚合层，以及 GDT、KS、Mintegral、Smartdigimkt 等 Adapter/SDK 痕迹。

### 关键入口

- `AnythinkSdkPlugin handleMethodCall:result:`
- `ATFSendSignalManger sendMethod:arguments:result:`
- `ATFSplashAdManger loadSplashAd:extraDic:`
- `ATFSplashAdManger showSplashAd:`
- `ATFSplashAdManger showSplashAd:sceneID:`
- `ATFRewardedVideoManger loadRewardedVideo:extraDic:`
- `ATFRewardedVideoManger showRewardedVideo:`
- `ATFInterstitialManger loadInterstitialAd:extraDic:`
- `ATFInterstitialManger showInterstitialAd:`
- `ATFBannerManger loadBannerWith:extraDic:`
- `ATFNativeManger loadNativeWith:extraDic:`
- `ATAdManager loadADWithPlacementID:extra:delegate:`
- `ATAdManager showSplashWithPlacementID:config:window:inViewController:extra:delegate:`
- `ATAdManager showRewardedVideoWithPlacementID:inViewController:delegate:`
- `ATAdManager showInterstitialWithPlacementID:inViewController:delegate:`

### 实际广告源观察点

第一版不根据字符串直接宣称某次展示命中了哪家网络，而是在运行时动态枚举 `AT*Adapter`，对以下展示 selector 做只读 Trace：

- `showSplashAdInWindow:inViewController:parameter:`
- `showRewardedVideoInViewController:`
- `showInterstitialInViewController:`

因此真正出现 `ATGDTSplashAdapter`、`ATKSSplashAdapter`、`ATMintegralSplashAdapter` 等事件时，才把它记录为该次实际 Adapter show。

## 第一版不做

- 不修改广告加载/展示结果。
- 不屏蔽广告。
- 不伪造 `rewardedVideoDidRewardSuccess`。
- 不修改 TopOn Waterfall / bidding。
- 不写死旧版本 RVA/VA。
