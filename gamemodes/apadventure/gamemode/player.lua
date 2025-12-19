
ApAdvPly = ApAdvPly or {}

util.AddNetworkString("apAdv_BHopUpdate")

local BASEGM = baseclass.Get("gamemode_base")

local allowedcolgroups = {
    [COLLISION_GROUP_NONE] = true,
    [COLLISION_GROUP_DEBRIS] = true,
    [COLLISION_GROUP_DEBRIS_TRIGGER] = true,
    [COLLISION_GROUP_IN_VEHICLE] = true,
    [COLLISION_GROUP_WEAPON] = true,
    [COLLISION_GROUP_VEHICLE_CLIP] = true,
    [COLLISION_GROUP_DOOR_BLOCKER] = true,
    [COLLISION_GROUP_PASSABLE_DOOR] = true,
    [COLLISION_GROUP_DISSOLVING] = true,
    [COLLISION_GROUP_NPC_ACTOR] = true,
    [COLLISION_GROUP_WORLD] = true,
}

function GM:IsSpawnpointSuitable()
    return true
end

function GM:PlayerSpawn(ply,trans)
    player_manager.SetPlayerClass(ply,"player_apadv")
    BASEGM.PlayerSpawn(self,ply,trans)

    if APADV_SPAWNS and next(APADV_SPAWNS) then
        local boundmins, boundmaxs = ply:GetCollisionBounds()
        local spawnpick = false
        for k,v in ipairs(APADV_SPAWNS) do
            local canspawn = true
            for ik,iv in ipairs(ents.FindInBox(v.pos+boundmins,v.pos+boundmaxs)) do
                if !allowedcolgroups[iv:GetCollisionGroup()] then
                    canspawn = false 
                    break
                end
            end 
            if canspawn then
                spawnpick = v
                break
            end
        end

        if !spawnpick then -- should try to make the player temporarily not collide with the things that obstructed them instead but this works for now
            spawnpick = APADV_SPAWNS[math.random(#APADV_SPAWNS)]
        end

        ply:SetPos(spawnpick.pos)
        ply:SetAngles(spawnpick.ang)

    end
end

function GM:PlayerInitialSpawn(ply)
    local connected = tobool(APADV_SLOT and APADV_SLOT.Connected)
    net.Start("ApAdvConnectionState")
        net.WriteBool(connected)
    net.Send(ply) 
end

function GM:PlayerLoadout(ply)
    if !APADV_WEPS then return true end

        for k,v in pairs(APADV_WEPS) do
            if v then
                ply:Give(k)
            end
        end

    return true
end

local plymeta = player_manager.GetPlayerClasses().player_apadv

APADV_PLYSTATS = APADV_PLYSTATS or {}

function ApAdvPly.UpdateBHop(val)
    if !isbool(val) then return end
    APADV_BHOP = val

    net.Start("apAdv_BHopUpdate")
        net.WriteBool(val)
    net.Broadcast()
end

function ApAdvPly.SetWalkSpeed(val)
    --if !plymeta then plymeta = player_manager.GetPlayerClasses().player_apadv end
    APADV_PLYSTATS.SlowWalkSpeed = val
    for k,v in ipairs(player.GetAll()) do
        v:SetSlowWalkSpeed(val)
    end
end

function ApAdvPly.SetRunSpeed(val)
    --if !plymeta then plymeta = player_manager.GetPlayerClasses().player_apadv end
    APADV_PLYSTATS.WalkSpeed = val
    for k,v in ipairs(player.GetAll()) do
        v:SetWalkSpeed(val)
    end
end

function ApAdvPly.SetSprintSpeed(val)
    --if !plymeta then plymeta = player_manager.GetPlayerClasses().player_apadv end
    APADV_PLYSTATS.RunSpeed = val
    for k,v in ipairs(player.GetAll()) do
        v:SetRunSpeed(val)
    end
end

function ApAdvPly.SetJumpPower(val)
    --if !plymeta then plymeta = player_manager.GetPlayerClasses().player_apadv end
    APADV_PLYSTATS.JumpPower = val
    for k,v in ipairs(player.GetAll()) do
        v:SetJumpPower(val)
    end
end