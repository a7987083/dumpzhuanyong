# CHANGELOG_DEV

## 2026-09-15 — v0.1.0

### Added

- 新建 `dumpzhuanyong` 广告诊断工程。
- `src/DZTraceCore.m`：只读 runtime hook 与 JSONL logger；`src/DZFloatingUI.m`：HFAMap/H5GG 风格悬浮 UI。
- 动态 Adapter show 观察，避免静态字符串直接推断实际命中广告源。
- `.github/workflows/build.yml`：macOS/Xcode arm64 iOS dylib 构建与 Mach-O 验证。
- 项目状态文档：`ROADMAP.md`、`HANDOFF.md`、`PROJECT_STATE.json`、`KNOWN_ISSUES.md`。

### Verification

- 已完成目标 IPA 静态 selector/class 复核。
- 已完成源码结构检查与 JSON 校验。
- Linux 当前环境无 iPhoneOS SDK，本地未执行 iOS dylib 编译；以 GitHub Actions macOS 构建结果为准。
- 尚未实机注入/运行。
