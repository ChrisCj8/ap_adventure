APADV = APADV or {}

APADV_SAVEDATA = APADV_SAVEDATA or {}
APADV_PLYSAVE = ADADV_SAVEPLYS or {}

local saveinit
local awaitingdata = {}

local max = math.max

local FromJSON = util.JSONToTable
local ToJSON = util.TableToJSON
local fileR = file.Read
local fileW = file.Write

local function applysave(ply,sav)
    ply:SetHealth(max(ply:GetMaxHealth()/3,sav.health))
    ply:SetArmor(max(ply:Armor(),sav.armor))

    for k,v in pairs(sav.ammo) do
        ply:SetAmmo(max(v,ply:GetAmmoCount(k)),k)
    end
end

function APADV.InitSaveData(saveid)
    print("Initializing Save Data", saveid)
    saveinit = true
    local savedir = "apadventure/sav/"..saveid.."/"
    APADV_SAVEDATA = {}
    APADV_PLYSAVE = {}
    if file.IsDir(savedir,"DATA") then
        local savfiles = file.Find(savedir.."*.json","DATA")
        for k,v in ipairs(savfiles) do
            local croppedname = string.sub(v,0,-6)
            APADV_SAVEDATA[croppedname] = FromJSON(fileR(savedir..v,"DATA"))
        end
        local plydir = savedir.."ply/"
        local plysav = file.Find(plydir.."*.json","DATA")
        for k,v in ipairs(plysav) do
            local croppedname = string.sub(v,0,-6)
            local plydata = FromJSON(fileR(plydir..v,"DATA"))
            APADV_PLYSAVE[croppedname] = plydata
            local awaiting = awaitingdata[croppedname]
            if awaiting then
                applysave(awaiting,plydata)
            end
        end

        if APADV_SAVEDATA._itemsused then
            APADV_ITEMSUSED = APADV_SAVEDATA._itemsused
        end

        if APADV_SAVEDATA._tracker then
            APADV_TRACKER:LoadFromTable(APADV_SAVEDATA._tracker)
            APADV_SAVEDATA._tracker = nil
        end

    else
        file.CreateDir(savedir.."ply/")
    end
    saveinit = true
    awaitingdata = nil
end

local function StorePlyData(ply)

    local sid = ply.APADV_STEAMID64
    local ammotypes = game.GetAmmoTypes()

    APADV_PLYSAVE[sid] = APADV_PLYSAVE[sid] or {}
    local plytbl = APADV_PLYSAVE[sid]
    plytbl.health = ply:Health()
    plytbl.armor = ply:Armor()

    plytbl.ammo = {}
    local ammotbl = plytbl.ammo
    
    for ik,iv in pairs(ply:GetAmmo()) do
        ammotbl[ammotypes[ik]] = iv 
    end

end

hook.Add("ShutDown","apAdvStoreSaveData",function() 
    if !APADV_SAVEID then return end 
    local savedir = "apadventure/sav/"..APADV_SAVEID.."/"

    if APADV_ITEMSUSED and next(APADV_ITEMSUSED) != nil then
        APADV_SAVEDATA._itemsused = APADV_ITEMSUSED
    end

    for k,v in pairs(APADV_SAVEDATA) do
        fileW(savedir..k..".json",ToJSON(v))
    end

    for k,v in player.Iterator() do
        StorePlyData(v)
    end

    local plydir = savedir.."ply/"
    for k,v in pairs(APADV_PLYSAVE) do
        fileW(plydir..k..".json",ToJSON(v))
    end

    APADV_TRACKER:SaveToFile(savedir.."_tracker.json")
end)

hook.Add("DoPlayerDeath","apAdvStoreSaveData",function(ply) 
    StorePlyData(ply)
end)

hook.Add("PlayerDisconnected","apAdvStoreSaveData",function(ply) 
    StorePlyData(ply)
end)

hook.Add("PlayerSpawn","apAdvApplyPlySave", function(ply)
    local sid = ply.APADV_STEAMID64
    local plysav = APADV_PLYSAVE[sid]
    if plysav then
        timer.Simple(0,function() applysave(ply,plysav) end)
    elseif !saveinit then
        awaitingdata[sid] = ply
    end
end)