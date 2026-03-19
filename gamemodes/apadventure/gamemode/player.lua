
APADV.PermaDeath = APADV.PermaDeath or false
APADV.DeadPlys = APADV.DeadPlys or {}

ApAdvPly = ApAdvPly or {}

util.AddNetworkString("apAdv_BHopUpdate")

local BASEGM = baseclass.Get("gamemode_base")
local SBOX = baseclass.Get("gamemode_sandbox")

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

    if APADV.DeadPlys[ply:SteamID64()] then
        GAMEMODE:PlayerSpawnAsSpectator(ply)
        return
    end

    ply:SetTeam( TEAM_UNASSIGNED )
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
        ply:SetEyeAngles(spawnpick.ang)

    end
end

function GM:PlayerInitialSpawn(ply)
    local connected = tobool(APADV_SLOT and APADV_SLOT.Connected)
    net.Start("ApAdvConnectionState")
        net.WriteBool(connected)
    net.Send(ply) 

    if APADV_TRACKER.built then
        APADV_TRACKER:SendTrackerData(ply)
    end
end

local resettext_color = Color(222,44,44)

function GM:PostPlayerDeath(ply)

    if !APADV.PermaDeath then return end

    local deadplys = APADV.DeadPlys

    deadplys[ply:SteamID64()] = true

    local remaining
    for k,v in player.Iterator() do
        if !deadplys[v:SteamID64()] then
            remaining = true
            break
        end
    end

    if !remaining then
        GMAP.SendChatMessage("All players have died. Config will be reloaded.",resettext_color,true)
        if APADV_MAPGROUP then
            timer.Simple(3, function() APADV.LoadCfg() end)
        end
    end
end

function GM:PlayerShouldTakeDamage(ply,attkr)
    if APADV_GODMODE then
        return false
    end
    return true
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

function GM:PlayerAmmoChanged(ply,ammoID,old,new)
    if !APADV_AMMOMERGE then return end
    ammodata = APADV_AMMOMERGE[ammoID]
    if ammodata then
        for k,v in ipairs(ammodata) do
            ply:SetAmmo(new,v)
        end
    end
end

local sv_cheats = GetConVar("sv_cheats")

local permhooks = {
    "PlayerSpawnSENT",
    "PlayerSpawnEffect",
    "PlayerSpawnNPC",
    "PlayerSpawnObject",
    "PlayerSpawnProp",
    "PlayerSpawnRagdoll",
    "PlayerSpawnSWEP",
    "PlayerSpawnVehicle",
    "PlayerGiveSWEP"
}

for k,v in ipairs(permhooks) do
    local ogfunc = SBOX[v]
    GM[v] = function (self,ply,...)
        if !sv_cheats:GetBool() then return false end
        return ogfunc(self,ply,...)
    end
end

local plymeta = FindMetaTable("Player")

plymeta.ApAdvCollector = true
plymeta.ApAdvDoKillFeed = true

APADV_PLYSTATS = APADV_PLYSTATS or {}

function ApAdvPly.UpdateBHop(val)
    if !isbool(val) then return end
    APADV_BHOP = val

    net.Start("apAdv_BHopUpdate")
        net.WriteBool(val)
    net.Broadcast()
end

function ApAdvPly.SetWalkSpeed(val)
    APADV_PLYSTATS.SlowWalkSpeed = val
    for k,v in player.Iterator() do
        v:SetSlowWalkSpeed(val)
    end
end

function ApAdvPly.SetRunSpeed(val)
    APADV_PLYSTATS.WalkSpeed = val
    for k,v in player.Iterator() do
        v:SetWalkSpeed(val)
    end
end

function ApAdvPly.SetSprintSpeed(val)
    APADV_PLYSTATS.RunSpeed = val
    for k,v in player.Iterator() do
        v:SetRunSpeed(val)
    end
end

function ApAdvPly.SetJumpPower(val)
    APADV_PLYSTATS.JumpPower = val
    for k,v in player.Iterator() do
        v:SetJumpPower(val)
    end
end