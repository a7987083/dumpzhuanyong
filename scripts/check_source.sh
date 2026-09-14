#!/bin/sh
set -eu
for f in \
  src/float/DZFloatWindow.h src/float/DZFloatWindow.m \
  src/float/DZFloatButton.h src/float/DZFloatButton.m \
  src/float/DZFloatPanel.h src/float/DZFloatPanel.m \
  src/float/DZFloatBootstrap.m; do
  test -f "$f"
done
grep -q 'pointInside:' src/float/DZFloatWindow.m
grep -q 'initWithWindowScene:' src/float/DZFloatBootstrap.m
grep -q 'makeKeyAndVisible' src/float/DZFloatBootstrap.m
grep -q 'UIPanGestureRecognizer' src/float/DZFloatButton.m
grep -q 'bringSubviewToFront' src/float/DZFloatBootstrap.m
python3 -m json.tool PROJECT_STATE.json >/dev/null
echo "FloatUI source checks: PASS"
