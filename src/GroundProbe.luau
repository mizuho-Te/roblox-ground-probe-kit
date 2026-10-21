--!strict
-- Pure observation classifier. No Roblox services and no enforcement actions.
local Probe = {}
export type Config = { supportDistance: number, maxSlopeDegrees: number, maxRiseSpeed: number, minHits: number }
export type Hit = { distance: number, normalY: number }
export type Observation = { hits: {Hit}, verticalVelocity: number, coverage: string, probeCount: number, castLength: number }
export type Result = { state: string, reason: string, supportHits: number }
local function finite(x: any): boolean
    return type(x) == "number" and x == x and math.abs(x) < math.huge
end
local function result(state: string, reason: string, hits: number): Result
    return {state = state, reason = reason, supportHits = hits}
end
function Probe.evaluate(observation: Observation, config: Config): Result
    if type(config) ~= "table" or not finite(config.supportDistance) or config.supportDistance < 0
        or not finite(config.maxSlopeDegrees) or config.maxSlopeDegrees < 0 or config.maxSlopeDegrees >= 90
        or not finite(config.maxRiseSpeed) or config.maxRiseSpeed < 0
        or not finite(config.minHits) or config.minHits < 1 or config.minHits % 1 ~= 0 then
        return result("unknown", "invalid-config", 0)
    end
    if type(observation) ~= "table" or type(observation.hits) ~= "table"
        or not finite(observation.verticalVelocity)
        or not finite(observation.probeCount) or observation.probeCount < config.minHits
        or observation.probeCount % 1 ~= 0 or not finite(observation.castLength)
        or observation.castLength < config.supportDistance
        or (observation.coverage ~= "known" and observation.coverage ~= "unknown") then
        return result("unknown", "invalid-observation", 0)
    end
    local count = 0
    local support = 0
    local threshold = math.cos(math.rad(config.maxSlopeDegrees))
    for key, hit in pairs(observation.hits) do
        count += 1
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0
            or type(hit) ~= "table" or not finite(hit.distance) or hit.distance < 0
            or hit.distance > observation.castLength or not finite(hit.normalY)
            or hit.normalY < -1 or hit.normalY > 1 then
            return result("unknown", "invalid-hit", 0)
        end
        if hit.distance <= config.supportDistance and hit.normalY >= threshold then
            support += 1
        end
    end
    for index = 1, count do
        if observation.hits[index] == nil then
            return result("unknown", "sparse-hits", 0)
        end
    end
    if count > observation.probeCount then
        return result("unknown", "too-many-hits", 0)
    end
    if support >= config.minHits then
        if observation.verticalVelocity > config.maxRiseSpeed then
            return result("airborne", "rising-away-from-support", support)
        end
        return result("supported", "support-observed", support)
    end
    if observation.coverage ~= "known" then
        return result("unknown", "insufficient-observation-coverage", support)
    end
    return result("airborne", "insufficient-support-in-configured-probes", support)
end
-- Replays developer-authored or captured primitive observations; does not run physics.
function Probe.replay(frames: {Observation}, config: Config): {Result}
    assert(type(frames) == "table", "replay frames must be a dense array")
    local count = 0
    for key in pairs(frames) do
        assert(type(key) == "number" and key >= 1 and key % 1 == 0, "replay frames must be a dense array")
        count += 1
    end
    for index = 1, count do
        assert(frames[index] ~= nil, "replay frames must be a dense array; missing frame")
    end
    local results = {}
    for _, frame in ipairs(frames) do
        table.insert(results, Probe.evaluate(frame, config))
    end
    return results
end
return Probe
