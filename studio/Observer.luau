-- Studio-only ModuleScript. Sibling GroundProbe must contain src/GroundProbe.luau.
local Probe = require(script.Parent.GroundProbe)
local Observer = {}
-- Root offset and support distance MUST be calibrated for the developer's rig.
function Observer.capture(root, character, options)
    local world = game:GetService("Workspace")
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.CollisionGroup = options.collisionGroup or "Default"
    params.RespectCanCollide = false -- query uses CanQuery; non-collidable queryable objects can hit
    params.IgnoreWater = true
    local radius = options.radius or 0.75
    local offsets = {Vector3.zero,Vector3.new(radius,0,0),Vector3.new(-radius,0,0),Vector3.new(0,0,radius),Vector3.new(0,0,-radius)}
    local hits = {}
    local hitDetails = {}
    for _, offset in ipairs(offsets) do
        local hit = world:Raycast(root.Position + offset, Vector3.new(0,-options.castLength,0), params)
        if hit then
            table.insert(hits, {distance=hit.Distance,normalY=hit.Normal.Y})
            table.insert(hitDetails, {
                name=hit.Instance.Name,
                canQuery=if hit.Instance:IsA("BasePart") then hit.Instance.CanQuery else nil,
                canCollide=if hit.Instance:IsA("BasePart") then hit.Instance.CanCollide else nil,
                collisionGroup=hit.Instance:IsA("BasePart") and hit.Instance.CollisionGroup or "Terrain",
            })
        end
    end
    -- StreamingEnabled=false does NOT prove adequate coverage. Opt-in requires a controlled scene.
    local observation = {hits=hits,verticalVelocity=root.AssemblyLinearVelocity.Y,
        coverage=options.coverageKnown == true and "known" or "unknown",
        probeCount=#offsets,castLength=options.castLength}
    local diagnostics = {streamingEnabled=world.StreamingEnabled,collisionGroup=params.CollisionGroup,
        respectCanCollide=params.RespectCanCollide, hitDetails=hitDetails}
    return observation, diagnostics
end
function Observer.evaluate(root, character, options, config)
    local observation, diagnostics = Observer.capture(root, character, options)
    return Probe.evaluate(observation, config), observation, diagnostics
end
return Observer
