--!nonstrict
local Probe = require("../src/GroundProbe")
local config = {supportDistance = 3, maxSlopeDegrees = 45, maxRiseSpeed = 2, minHits = 1}
local cases = 0
local function check(label, observation, expected, cfg, reason)
    local got = Probe.evaluate(observation, cfg or config)
    assert(got.state == expected, label .. ": " .. got.state .. " ~= " .. expected)
    if reason then assert(got.reason == reason, label .. ": " .. got.reason) end
    cases += 1
end
local function frame(distance, normal, velocity, coverage)
    return {hits = if distance then {{distance=distance, normalY=normal or 1}} else {}, verticalVelocity=velocity or 0, coverage=coverage or "known", probeCount=5, castLength=8}
end
check("flat", frame(3), "supported")
check("above distance", frame(3.001), "airborne")
check("below distance", frame(2.999), "supported")
check("slope boundary", frame(3, math.cos(math.rad(45))), "supported")
check("steep", frame(3, .7), "airborne")
check("wall", frame(2, 0), "airborne")
check("ceiling", frame(2, -1), "airborne")
check("rise boundary", frame(3, 1, 2), "supported")
check("jump", frame(3, 1, 2.001), "airborne")
check("fall", frame(3, 1, -30), "supported") -- nearby support, NOT landed!
check("known no hit", frame(nil), "airborne")
check("unknown no hit", frame(nil, nil, nil, "unknown"), "unknown")
check("unknown distant hit", frame(7, 1, 0, "unknown"), "unknown")
check("observed hit unknown coverage", frame(2, 1, 0, "unknown"), "supported")
check("nan hit", frame(0/0), "unknown")
check("infinite hit", frame(math.huge), "unknown")
check("negative distance", frame(-1), "unknown")
check("beyond cast", frame(9), "unknown")
check("invalid normal", frame(2, 1.1), "unknown")
check("nan velocity", frame(2, 1, 0/0), "unknown")
check("bad config", frame(2), "unknown", {supportDistance=-1, maxSlopeDegrees=45, maxRiseSpeed=2,minHits=1})
for _, field in ipairs({"supportDistance", "maxSlopeDegrees", "maxRiseSpeed", "minHits"}) do
    local cfg = table.clone(config); cfg[field] = 0/0
    check("nan config "..field, frame(2), "unknown", cfg)
end
local a=frame(2); a.castLength=2; check("short cast",a,"unknown")
a=frame(2); a.probeCount=0; check("zero probes",a,"unknown")
a=frame(2); a.coverage="maybe"; check("invalid coverage",a,"unknown")
a=frame(2); a.hits[2]={distance=2, normalY=1}; a.probeCount=1; check("too many",a,"unknown")
local two=table.clone(config); two.minHits=2
check("single edge insufficient",frame(2),"airborne",two)
a=frame(2); a.hits[2]={distance=3,normalY=1}; check("two hits",a,"supported",two)
a=frame(2); a.hits={[100]={distance=2,normalY=1}}; check("sparse hits",a,"unknown")
for _, badFrames in ipairs({{[1]=frame(2),[3]=frame(2)}, {foo=frame(2)}, {[0]=frame(2)}}) do
    local ok = pcall(function() Probe.replay(badFrames, config) end)
    assert(not ok, "malformed replay must fail explicitly"); cases+=1
end
assert(#Probe.replay({}, config)==0, "empty replay"); cases+=1
local results=Probe.replay(require("./synthetic-recording"), config)
for i, state in ipairs({"supported","airborne","airborne","supported","unknown"}) do
    assert(results[i].state==state, "replay "..i); cases+=1
end
-- Sweeps distance and velocity around boundaries without external dependencies.
for i=-100,100 do
    local d=3+i/1000
    check("distance sweep "..i,frame(d),if i<=0 then "supported" else "airborne")
    check("velocity sweep "..i,frame(3,1,2+i/1000),if i<=0 then "supported" else "airborne")
end
print("PASS "..cases.." pure Luau assertions; synthetic observations only, NOT Studio physics")
