# Floating UI baseline

## 来源

复用旧项目 HFAMapUniversal 的 H5GG 风格悬浮层实现思路。当前 GitHub 可访问的对应代码位于：

- repo: `a7987083/UnitXP_SP3-Moonstone`
- ref: `feature/login-ip-tracer-dylib-v2-hfamap187-v1920-menu`
- commit: `b9c1f48882f41090446f48b7dac1229495524043`
- file: `hfamap/src/HFAMapLegacy.m`

旧实现的关键行为：

1. 52×52 圆形浮动按钮。
2. `UIPanGestureRecognizer` 拖动按钮并限制在窗口边界。
3. 面板自身也支持拖动。
4. 点击浮动按钮切换面板 hidden 状态。
5. 周期性寻找当前窗口；窗口变化时把按钮/面板重新挂载。
6. 每个 tick 对面板和按钮执行 `bringSubviewToFront:`，避免被宿主 UI 覆盖。

v0.1 保留以上生命周期与交互模型，但业务内容完全替换为广告 Trace，不带入 HFAMap 的旧扫描/patch 逻辑。

> 注：当前仓库列表中没有名为 `hfamapuniversal` 的活动 branch ref；但 `HFAMapUniversal` 产物和上述悬浮 UI 源码都仍可在旧仓库历史分支中验证到，因此以真实可读取 commit 固定基线。
