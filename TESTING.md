# Verification ledger

## Executed 2026-10-21

Official Luau 0.743 Ubuntu binary from https://github.com/luau-lang/luau/releases/tag/0.743.
Downloaded archive SHA-256: 99d45afb4afaee00ba631c526c8e8c76c67b60f6f119953ce6409be6d6953663 (locally measured, not an independently signed vendor checksum).

- `luau tests/run.luau`: PASS 443 assertions, synthetic observations only.
- `luau-analyze src/GroundProbe.luau tests/run.luau`: exit 0, no diagnostics.
- `luau-compile studio/*.luau`: exit 0. Syntax compilation only; Roblox globals/API availability NOT checked.
- Tests cover distance/slope/rise boundaries, missing hits/unknown coverage, malformed numeric inputs, probe counts, synthetic replay and 402 sweep assertions.
- CLI fixtures remain synthetic, not real player recordings. [GitHub Actions](https://github.com/mizuho-Te/roblox-ground-probe-kit/actions/runs/39575296068) also passed on 2026-10-21: 443 pure Luau assertions, static analysis and Studio-script syntax compilation. Commit: `cdde75ec5003841164ea57baab41d4bb56daa361`. This CI does not execute Studio or engine physics. The separate limited Studio observation below does not turn these CLI assertions into physics tests.

## Studio observation appendix (2026-10-21)

### Scope and configuration

Observed in Studio **0.743.0.7431133**, a new unpublished Place (`PlaceId=0`). One local session used one server-owned R6 rig, HipHeight=0, root size 2×2×1, one scale only. Motion came from automatic Humanoid Move/Jump calls, **not manual keyboard play**. No production game was modified or published. The source's 11 files were checksum-verified and unchanged before the observation run. This appendix and README were updated afterward without changing code.

StreamingEnabled=false was recorded, but does **not** establish `coverage="known"`. Coverage stayed unknown except an explicitly controlled no-hit comparison. Five rays used radius=0.75, castLength=8, CollisionGroup=Default, RespectCanCollide=false, minHits=1, maxSlopeDegrees=45 and maxRiseSpeed=2. Initial supportDistance=3; a measured, rig-specific server adjustment used 3.1. The client comparison retained 3. This adjustment is not a universal recommendation.

### Observations, not independent test counts

The run collected **1,093 continuous Heartbeat frames across 12 segments**: 941 supported, 84 airborne, 68 unknown. These are correlated samples, **not 1,093 independent tests or proof of correctness**. Selected segment summaries:

| Segment | Frames / classifier output | Other observed information |
|---|---|---|
| Flat stationary sample | 120/120 supported | Initial configuration |
| Flat stationary calibrated | 121/121 supported | Rig-specific distance=3.1 |
| Flat walk | 72/72 supported | Automatic movement |
| Slope walk | 61: 13 supported, 48 airborne | All 61 Humanoid Running, FloorMaterial Plastic; max vertical velocity 3.03878 |
| Steps walk | 120: 91 supported, 29 airborne | All 120 Humanoid Running, FloorMaterial Plastic |
| Jump sequence | 121: 86 supported, 3 airborne, 32 unknown | Humanoid counts: Jumping 1, Freefall 31, Landed 2, Running 87 |

Slope and step results demonstrate disagreement with a possible interpretation of Humanoid Running/FloorMaterial, not an engine bug or a successful universal ground classifier. The upward-speed gate can label movement along a slope airborne despite nearby support. `supported` means nearby support rays, **not physical contact or a landed state**. No behavior change was made to hide these results.

### Controlled comparisons and boundary observations

- A non-collidable marker with CanQuery=false produced zero hits and unknown; CanQuery=true produced five hits at distance 2 and supported. Queryable decoration therefore can produce support even without physical collision.
- Collision-group inclusion → exclusion → restoration changed hits 5 → 0 → 5 and state supported → unknown → supported.
- A controlled no-hit observation was unknown with coverage unknown and airborne with explicitly asserted known coverage. This assertion is not automatically justified by disabled streaming.
- A client hit distance of **3.00015974** exceeded its configured threshold 3 and produced unknown. This is a direct threshold comparison; the experiment does not establish networking or rounding as its cause.
- In a jump observation, vertical velocity **50.55** and hit distance **3.86** exceeded supportDistance=3.1. With insufficient support and unknown coverage the result was **unknown**, not airborne. The rise gate runs only **after** the minimum supporting-hit count is met.

The no-hit and filter comparisons temporarily anchored the root. They test engine Raycast filtering, not Humanoid contact. Client and server samples used different distance thresholds, sampling cadences and time origins; their totals must not be treated as synchronized replication assertions.

### Evidence completeness

The long JSON output was truncated: 148 of 227 GPV records were truncated in the disk log; 79 were retrieved as complete JSON. All 12 SUMMARY records and DONE were complete; representative full observations were transcribed from the UI. The reported segment totals rely on these complete summaries. **A full raw replay of all 1,093 frames is not available**, and this package does not include or imply such a recording. Private UI logs and machine-specific paths are intentionally not distributed.

### Remaining acceptance work

Not tested: two clients / multiplayer, StreamingEnabled=true, R15, other avatar sizes/scales, moving floors, actual mobile hardware. Broader water/climb/rotation/latency behavior is not established. Single-session server/client observations do not establish general replication correctness.

Before game integration, record the chosen rig and configuration, the intended meaning of supported/airborne, expected outcomes per scenario, and explain slope/step discrepancies. Re-run in a disposable Place, compare client and server independently, and never use this diagnostic classifier alone for punishment or forced movement.
