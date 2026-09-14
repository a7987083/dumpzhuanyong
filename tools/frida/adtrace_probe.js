'use strict';

// Read-only validation probe for DumpZhuanYong AD Trace v2.
// Frida 17+ compatible: ObjC method interception only; no replacement/patching.

const listeners = [];
const installed = new Set();

function safeObject(pointer) {
  if (pointer === undefined || pointer === null || pointer.isNull()) return null;
  try {
    const object = new ObjC.Object(pointer);
    return {
      class: object.$className,
      text: object.toString().slice(0, 1200)
    };
  } catch (_) {
    return { pointer: pointer.toString() };
  }
}

function hookMethod(className, selector, argumentCount) {
  if (!ObjC.available) return false;
  const key = `${className}::${selector}`;
  if (installed.has(key)) return true;

  const cls = ObjC.classes[className];
  if (cls === undefined) return false;
  const method = cls[`- ${selector}`];
  if (method === undefined) return false;

  const listener = Interceptor.attach(method.implementation, {
    onEnter(args) {
      const values = [];
      for (let i = 0; i < argumentCount; i++) values.push(safeObject(args[i + 2]));
      send({
        type: 'adtrace',
        className,
        selector,
        args: values
      });
    }
  });
  listeners.push(listener);
  installed.add(key);
  return true;
}

function installKnown() {
  const specs = [
    ['AnythinkSdkPlugin', 'handleMethodCall:result:', 2],
    ['ATFSendSignalManger', 'sendMethod:arguments:result:', 3],
    ['ATFSplashAdManger', 'loadSplashAd:extraDic:', 2],
    ['ATFSplashAdManger', 'showSplashAd:', 1],
    ['ATFSplashAdManger', 'showSplashAd:sceneID:', 2],
    ['ATFRewardedVideoManger', 'loadRewardedVideo:extraDic:', 2],
    ['ATFRewardedVideoManger', 'showRewardedVideo:', 1],
    ['ATFRewardedVideoManger', 'showRewardedVideo:sceneID:', 2],
    ['ATFInterstitialManger', 'loadInterstitialAd:extraDic:', 2],
    ['ATFInterstitialManger', 'showInterstitialAd:', 1],
    ['ATFInterstitialManger', 'showInterstitialAd:sceneID:', 2],
    ['ATFBannerManger', 'loadBannerWith:extraDic:', 2],
    ['ATFNativeManger', 'loadNativeWith:extraDic:', 2],
    ['ATAdManager', 'loadADWithPlacementID:extra:delegate:', 3],
    ['ATAdManager', 'loadADWithPlacementID:extra:delegate:containerView:', 4],
    ['ATAdManager', 'showSplashWithPlacementID:config:window:inViewController:extra:delegate:', 6],
    ['ATAdManager', 'showRewardedVideoWithPlacementID:inViewController:delegate:', 3],
    ['ATAdManager', 'showRewardedVideoWithPlacementID:scene:inViewController:delegate:', 4],
    ['ATAdManager', 'showInterstitialWithPlacementID:inViewController:delegate:', 3],
    ['ATAdManager', 'showInterstitialWithPlacementID:scene:inViewController:delegate:', 4]
  ];

  let count = 0;
  for (const [className, selector, argc] of specs) {
    if (hookMethod(className, selector, argc)) count++;
  }
  send({ type: 'adtrace-status', installed: count, totalKnown: specs.length });
}

if (!ObjC.available) {
  send({ type: 'adtrace-error', message: 'Objective-C runtime is unavailable' });
} else {
  Process.attachModuleObserver({
    onAdded(module) {
      if (module.name === 'Runner' || module.name === 'AnyThinkSDK') {
        setImmediate(installKnown);
      }
    }
  });
  setImmediate(installKnown);
}

rpc.exports = {
  rescan() {
    installKnown();
    return { installed: installed.size };
  },
  stop() {
    for (const listener of listeners.splice(0)) listener.detach();
    installed.clear();
    return true;
  }
};
