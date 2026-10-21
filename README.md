# Roblox Ground Probe Kit

[日本語](README.ja.md) · [Verification record](TESTING.md)

A small diagnostic kit for testing **your own game's** ground-support assumptions. It separates recorded ray observations from a deterministic classifier so boundary mistakes can be reproduced without a running game.

MIT License. Copyright (c) 2026 mizuho-Te. See [LICENSE](LICENSE).

## What it is / is not

- Pure Luau classifier with configurable distance, surface normal, upward speed and minimum supporting probes.
- Synthetic observation replay, 443 executable assertions, Studio observation example and disposable test-scene generator.
- Not a universal grounded/airborne detector, anti-cheat, exploit, kick/ban system, or replacement for Roblox physics.
- `supported` means nearby ray support under your chosen thresholds, **not confirmed physical contact or landing**. A fast fall near a floor can still be `supported`.
- `airborne` means insufficient support in your configured probes with known coverage, or rising faster than the configured limit **after the minimum supporting-hit count has been met**. High upward speed alone does not force `airborne`: insufficient support with unknown coverage remains `unknown`. It is not evidence of cheating.
- `unknown` is fail-open: do not punish, teleport or reject gameplay based on it. A no-hit observation does not distinguish empty space from filtered or unloaded geometry.

## Run pure tests

Download the official [Luau CLI](https://github.com/luau-lang/luau/releases/tag/0.743), unpack outside this repository, and put the executables on your PATH:

```sh
luau tests/run.luau
luau-analyze src/GroundProbe.luau tests/run.luau
luau-compile studio/Observer.luau studio/CreateTestScene.server.luau studio/Observe.client.luau > /dev/null
```

These commands were run locally using official Luau 0.743 on 2026-10-21. CI is provided but has not run remotely as of this validation. Compilation is not a Studio API/physics test.

## Pure API

```lua
local Probe = require("./src/GroundProbe")
local config = {supportDistance=3, maxSlopeDegrees=45, maxRiseSpeed=2, minHits=1}
local frame = {
    hits={{distance=2.9, normalY=1}}, verticalVelocity=0,
    coverage="known", probeCount=5, castLength=8,
}
print(Probe.evaluate(frame, config).state) -- supported
local results = Probe.replay({frame}, config)
```

All distances are studs from the ray origin, speed is studs/second along world Y, and normals must be normalized by the producing adapter. `normalY` is the upward component. Distance and slope thresholds are inclusive; rising speed is exclusive (`>`). One hit per ray at most. Input hit arrays should be dense; each is a successful ray, not a unique surface. Repeated rays hitting the same surface count independently. Numeric invalidity produces `unknown`. Config errors also produce `unknown` rather than throwing; the observation is not an untrusted network security boundary.

`coverage="known"` is a developer assertion: all intended probes ran, their length and placement cover the intended support area, and relevant geometry/filter configuration is available. **Do not infer it from StreamingEnabled=false.** The Studio example defaults to unknown coverage. Valid observed support can still produce `supported` even when global coverage is unknown.

## Studio setup (limited engine observations completed)

Use a **new disposable blank Place**, never the production game:

1. Create `ReplicatedStorage/GroundProbeKit` (Folder).
2. Create sibling ModuleScripts `GroundProbe` and `Observer`. Paste `src/GroundProbe.luau` and `studio/Observer.luau` respectively.
3. Add `studio/CreateTestScene.server.luau` as a Script in ServerScriptService. It creates a new folder on Play and refuses to overwrite an existing one. It never deletes objects. For no-floor void tests, set BOTH CanCollide=false and CanQuery=false on the template Baseplate in this disposable blank Place only. Never apply this to a production floor.
4. Add `studio/Observe.client.luau` as a LocalScript in StarterPlayerScripts. Play and inspect Output.
5. Manually calibrate `supportDistance`, radius, castLength and thresholds for **each rig/scale**. Sample 3-stud distance is not a default for all avatars. Root position is the origin; offsets are world-aligned, not foot joints.
6. Walk flat floor, slope, steps and platform edge; jump and land. Record expected vs observed results using TESTING.md. Test moving platforms, fast falls, swimming and climbing separately before considering game-specific use.
7. Repeat with StreamingEnabled and a second client in Studio. Record client and server observations separately; no authoritative networking is implemented here.

A single local Studio session with one R6 rig has now been observed; it exposed slope/step disagreement with Humanoid Running and threshold-sensitive results. This is not a general engine-validation pass. See [the Studio verification appendix](TESTING.md#studio-observation-appendix-2026-10-21).

The adapter excludes the character and displays StreamingEnabled, ray CollisionGroup, and per-hit CanQuery/CanCollide/group values. `RespectCanCollide=false` means queryable non-collidable decoration can be hit; choose a collision group/filter for your own intended support surfaces. Excluded and absent objects cannot be diagnosed from a hit that never occurred. CanQuery=false geometry and collision-group exclusions must be tested deliberately. The script prints primitive frame JSON with no player IDs, retains only 100 frames in memory, and sends nothing over the network. To replay a captured frame, manually copy its primitive values into a Luau table like `tests/synthetic-recording.luau`; JSON output is not directly a Luau module.

## Known false positives and gaps

Thin edges, narrow feet, moving/rotating platforms, large avatars, slopes, changing velocity, root offsets, water and queryable decoration need game-specific adapters. Five downward point rays do not prove whole-body support. No hysteresis, foot contact solver, swept collision, lag compensation or Humanoid state integration is claimed. Custom rigs require manual thresholds. Filters and streaming can hide a floor. No enforcement hooks are included.

## Primary references

- [Roblox raycasting: filters, normal/distance, streaming and CanQuery](https://create.roblox.com/docs/workspace/raycasting)
- [Studio testing modes](https://create.roblox.com/docs/studio/testing-modes)
- [Luau CLI introduction](https://luau.org/getting-started/)

This independent project is not affiliated with Roblox. It uses only new synthetic examples, not any customer's game code, characters, telemetry or assets.

Replay requires a dense array of frames; sparse or non-array keys raise an explicit error instead of silently truncating a recording. Sparse hit arrays return unknown. Studio Observer is a developer-only adapter: supply an existing character/root, valid registered collision-group name, positive finite castLength (at most Roblox’s 15,000-stud ray limit), and a nonnegative finite radius. Invalid options may raise a Roblox API error before reaching the pure classifier; it is not an untrusted-input API.
