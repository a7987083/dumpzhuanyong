#!/bin/sh
set -eu

for f in \
  src/float/DZFloatWindow.h src/float/DZFloatWindow.m \
  src/float/DZFloatButton.h src/float/DZFloatButton.m \
  src/float/DZFloatPanel.h src/float/DZFloatPanel.m \
  src/float/DZFloatBootstrap.m \
  src/adtrace/DZAdTrace.h src/adtrace/DZAdTraceInternal.h \
  src/adtrace/DZAdTraceStore.m src/adtrace/DZAdTraceHooks.m \
  src/adtrace/DZAdTraceDashboard.m tools/frida/adtrace_probe.js; do
  test -f "$f"
done

# Stable FloatUI invariants.
grep -q 'pointInside:' src/float/DZFloatWindow.m
grep -q 'initWithWindowScene:' src/float/DZFloatBootstrap.m
grep -q 'makeKeyAndVisible' src/float/DZFloatBootstrap.m
grep -q 'UIPanGestureRecognizer' src/float/DZFloatButton.m
grep -q 'bringSubviewToFront' src/float/DZFloatBootstrap.m

# AD Trace v2 safety and evidence invariants.
grep -q 'method_copyReturnType' src/adtrace/DZAdTraceHooks.m
grep -q 'method_copyArgumentType' src/adtrace/DZAdTraceHooks.m
grep -q 'ATFSplashAdManger' src/adtrace/DZAdTraceHooks.m
grep -q 'ATFRewardedVideoManger' src/adtrace/DZAdTraceHooks.m
grep -q 'ATFInterstitialManger' src/adtrace/DZAdTraceHooks.m
grep -q 'ATAdManager' src/adtrace/DZAdTraceHooks.m
grep -q 'DumpZhuanYong_AdTrace_v2.jsonl' src/adtrace/DZAdTraceStore.m
grep -q 'DZFloatPanel' src/adtrace/DZAdTraceDashboard.m
grep -q 'Process.attachModuleObserver' tools/frida/adtrace_probe.js
grep -q 'Interceptor.attach' tools/frida/adtrace_probe.js
grep -q 'rpc.exports' tools/frida/adtrace_probe.js

# Read-only guardrails: no replacement or binary patching in the validation probe.
if grep -Eq 'Interceptor\.replace|Memory\.patchCode|retval\.replace' tools/frida/adtrace_probe.js; then
  echo 'unsafe mutation primitive found in readonly Frida probe' >&2
  exit 1
fi

python3 -m json.tool PROJECT_STATE.json >/dev/null

echo "AD Trace v2 source checks: PASS"
