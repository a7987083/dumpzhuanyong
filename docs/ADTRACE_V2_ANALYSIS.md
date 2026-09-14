# AD Trace v2 — verified target evidence

## Target sample

- IPA: `516415ecaa177dbc217b251d8871204e.ipa`
- IPA SHA-256: `2b81549fc41576bd9d7209240d9210cfc6dac034afd98be3ce8ef3025d73827c`
- Runner SHA-256: `509583df95221e004d97612aa183ea4091ac75e4c6c137d2da56b7051edcf268`
- Runner UUID: `79F4AEE2-24AC-3D2F-BA53-BE5669D52212`
- Architecture: arm64
- `LC_ENCRYPTION_INFO_64 cryptid=0`
- Runner `LC_BUILD_VERSION`: iOS, min iOS 13.0, SDK 26.0
- `AnyThinkSDK.framework/AnyThinkSDK` SHA-256: `d46f1c443f57245055fd4dff43894fc8d7c19be4d38f5cf36c43d712027b6426`

## Symbol evidence from this exact Runner build

These addresses are evidence only; v2 does **not** hardcode them.

| Address | Symbol |
|---|---|
| `0x1002e0574` | `-[AnythinkSdkPlugin handleMethodCall:result:]` |
| `0x1002ee44c` | `-[ATFInterstitialManger loadInterstitialAd:extraDic:]` |
| `0x1002fa114` | `-[ATFRewardedVideoManger loadRewardedVideo:extraDic:]` |
| `0x1002fc2a0` | `-[ATFSendSignalManger sendMethod:arguments:result:]` |
| `0x1002fc474` | `-[ATFSplashAdManger loadSplashAd:extraDic:]` |
| `0x1002fcae4` | `-[ATFSplashAdManger showSplashAd:]` |
| `0x1002fcc54` | `-[ATFSplashAdManger showSplashAd:sceneID:]` |

Additional target strings/selectors confirm:

- Flutter bridge channel family: `AnythinkSdkPlugin` / `anythink_sdk`.
- Splash / RewardedVideo / Interstitial / Banner / Native bridge managers.
- `ATAdManager` load APIs including `loadADWithPlacementID:extra:delegate:` and splash container variant.
- TopOn show APIs for Splash / RewardedVideo / Interstitial.
- Provider adapters including `AT*Adapter` classes.

## Upstream cross-check

Reference repository: `toponteam/TopOn-iOS-SDK`, pinned for corroboration at commit `07d4cdf77d1f0cf49ead841d428f7da9e73d0838`.

Upstream headers independently confirm the same API family:

- `ATAdManager+Splash.h`: `loadADWithPlacementID:extra:delegate:containerView:` and Splash show API.
- `ATAdManager+RewardedVideo.h`: rewarded-video show APIs with and without `scene:`.
- `ATAdManager+Interstitial.h`: interstitial show APIs with and without `scene:`.

The target bundled SDK is newer/different from that historical upstream snapshot, so upstream source is corroboration only. Runtime selector existence and Objective-C type encoding from the target process remain authoritative.

## v2 hook policy

1. No fixed RVA/VA in runtime code.
2. Resolve Objective-C class + selector at runtime.
3. Before replacing an IMP, require:
   - method exists;
   - return type is `void`;
   - explicit argument count matches;
   - every explicit argument is object/class/SEL pointer-compatible.
4. If ABI validation fails, skip the hook.
5. Preserve and call the original IMP.
6. No return-value modification, no ad blocking, no reward forging.
7. Dynamically enumerate known `ATF*Delegate` callbacks and `AT*Adapter` `show*` methods, but apply the same ABI gate.

## Runtime event layers

```text
Flutter call
  -> AnythinkSdkPlugin
  -> ATF* manager bridge
  -> ATAdManager / TopOn
  -> AT*Adapter provider show
  -> ATF*Delegate callback
  -> ATFSendSignalManger
  -> Flutter callback
```

v2 records each layer as JSONL to:

`Documents/DumpZhuanYong_AdTrace_v2.jsonl`

The dashboard shows hook count, event count, latest event, placement ID and provider when evidence is present.

## Optional Frida validation

`tools/frida/adtrace_probe.js` provides a separate, read-only Frida 17+ validation path. It uses `Process.attachModuleObserver()` and `Interceptor.attach()` only, exposes `rpc.exports.stop()`, and does not replace functions or patch code.
