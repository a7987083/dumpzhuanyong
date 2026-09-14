#!/bin/sh
set -eu
for f in src/DZAdTrace.h src/DZTraceCore.m src/DZFloatingUI.m; do
  test -f "$f"
done
grep -q 'AnythinkSdkPlugin' src/DZTraceCore.m
grep -q 'ATFSplashAdManger' src/DZTraceCore.m
grep -q 'ATFSendSignalManger' src/DZTraceCore.m
grep -q 'showSplashAdInWindow:inViewController:parameter:' src/DZTraceCore.m
grep -q 'DumpZhuanYong_AdTrace.jsonl' src/DZTraceCore.m
grep -q 'UIPanGestureRecognizer' src/DZFloatingUI.m
grep -q 'bringSubviewToFront' src/DZFloatingUI.m
python3 -m json.tool PROJECT_STATE.json >/dev/null
echo "source checks: PASS"
