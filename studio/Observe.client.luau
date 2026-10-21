-- LocalScript under StarterPlayerScripts in a disposable blank Place.
-- ReplicatedStorage/GroundProbeKit contains GroundProbe and Observer ModuleScripts.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Observer=require(game:GetService("ReplicatedStorage").GroundProbeKit.Observer)
local config={supportDistance=3,maxSlopeDegrees=45,maxRiseSpeed=2,minHits=1} -- SAMPLE ONLY, calibrate!
local options={castLength=8,radius=0.75,collisionGroup="Default",coverageKnown=false}
local elapsed=0
local frames={}
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt
    if elapsed<0.2 then return end
    elapsed=0
    local character=Players.LocalPlayer.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local result,observation,diagnostics=Observer.evaluate(root,character,options,config)
    -- Bounded in-memory diagnostic capture. No network, file writes, player IDs, or enforcement.
    if #frames>=100 then table.remove(frames,1) end
    table.insert(frames,observation)
    print(result.state,result.reason,"streaming",diagnostics.streamingEnabled,
        "group",diagnostics.collisionGroup,HttpService:JSONEncode(observation))
end)
