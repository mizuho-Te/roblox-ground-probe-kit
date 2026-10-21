-- Run ONLY in a new, disposable blank Studio Place. Creates a folder; never deletes anything.
assert(not workspace:FindFirstChild("GroundProbeTestScene"), "Scene already exists; use a new blank Place")
local scene = Instance.new("Folder")
scene.Name = "GroundProbeTestScene"
scene.Parent = workspace
local function block(name, size, cf, color)
    local part = Instance.new("Part")
    part.Name=name; part.Size=size; part.CFrame=cf; part.Anchored=true
    part.CanCollide=true; part.CanQuery=true; part.Color=color
    part.Parent=scene
    return part
end
local blue=Color3.fromRGB(65,130,200)
block("Flat",Vector3.new(20,1,20),CFrame.new(0,0,0),blue)
block("Slope30",Vector3.new(12,1,20),CFrame.new(22,3,0)*CFrame.Angles(0,0,math.rad(30)),blue)
for i=1,4 do block("Step"..i,Vector3.new(4,i,10),CFrame.new(i*4, i/2,24),blue) end
block("EdgePlatform",Vector3.new(6,1,12),CFrame.new(-20,5,0),blue)
block("JumpLanding",Vector3.new(10,1,10),CFrame.new(-20,5,18),blue)
local ignored=block("NonQueryableMarker",Vector3.new(6,1,6),CFrame.new(0,8,-20),Color3.fromRGB(220,90,90))
ignored.CanCollide=false; ignored.CanQuery=false
print("Disposable GroundProbeTestScene created. StreamingEnabled:",workspace.StreamingEnabled)
