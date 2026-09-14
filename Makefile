SHELL := /bin/bash
TARGET := DumpZhuanYongAdTraceV2
FLOAT_SRC := src/float/DZFloatWindow.m src/float/DZFloatButton.m src/float/DZFloatPanel.m src/float/DZFloatBootstrap.m
ADTRACE_SRC := src/adtrace/DZAdTraceStore.m src/adtrace/DZAdTraceHooks.m src/adtrace/DZAdTraceDashboard.m
SRC := $(FLOAT_SRC) $(ADTRACE_SRC)
BUILD_DIR := build
OUT := $(BUILD_DIR)/$(TARGET).dylib
SDK := $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
CLANG := $(shell xcrun -f clang 2>/dev/null)

.PHONY: all clean verify source-check

all: $(OUT)

$(OUT): $(SRC)
	@test -n "$(SDK)" || (echo "iphoneos SDK not found; build on macOS/Xcode" && exit 1)
	@mkdir -p $(BUILD_DIR)
	$(CLANG) -arch arm64 -dynamiclib $(SRC) -o $(OUT) \
		-isysroot "$(SDK)" -miphoneos-version-min=12.0 \
		-fobjc-arc -fmodules -fblocks -std=gnu17 -Os -Wall -Wextra \
		-Wno-deprecated-declarations -Wno-unused-function \
		-framework Foundation -framework UIKit -framework QuartzCore \
		-Wl,-install_name,@rpath/$(TARGET).dylib

source-check:
	bash scripts/check_source.sh

verify: $(OUT)
	file $(OUT)
	xcrun otool -hv $(OUT)
	xcrun otool -L $(OUT)
	@echo "required strings:"
	strings $(OUT) | grep -E 'AD Trace|DumpZhuanYong_AdTrace_v2.jsonl|AnythinkSdkPlugin|ATFSplashAdManger|ATAdManager|ATFSendSignalManger'

clean:
	rm -rf $(BUILD_DIR)
