APADV = APADV or {}

APADV_SAVEDATA = APADV_SAVEDATA or {}
APADV_PLYSAVE = ADADV_SAVEPLYS or {}

function APADV.InitSaveData(saveid)
    print("Initializing Save Data", saveid)
    local savedir = "apadventure/sav/"..saveid.."/"
    APADV_SAVEDATA = {}
    APADV_PLYSAVE = {}
    if file.IsDir(savedir,"DATA") then
        local savfiles = file.Find(savedir.."*.json","DATA")
        for k,v in ipairs(savfiles) do
            local croppedname = string.sub(v,0,-6)
            APADV_SAVEDATA[croppedname] = util.JSONToTable(file.Read(savedir..v,"DATA"))
        end
        local plydir = savedir.."ply/"
        local plysav = file.Find(plydir.."*.json","DATA")
        for k,v in ipairs(plysav) do
            local croppedname = string.sub(v,0,-6)
            APADV_PLYSAVE[croppedname] = util.JSONToTable(file.Read(plydir..v,"DATA"))
        end

        if APADV_SAVEDATA.itemsused then
            APADV_ITEMSUSED = APADV_SAVEDATA.itemsused
        end
    else
        file.CreateDir(savedir.."ply/")
    end
end

local function StorePlyData(ply)

    local sid = ply:SteamID64()
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
        APADV_SAVEDATA.itemsused = APADV_ITEMSUSED
    end

    for k,v in pairs(APADV_SAVEDATA) do
        file.Write(savedir..k..".json",util.TableToJSON(v))
    end

    for k,v in player.Iterator() do
        StorePlyData(v)
    end

    local plydir = savedir.."ply/"
    for k,v in pairs(APADV_PLYSAVE) do
        file.Write(plydir..k..".json",util.TableToJSON(v))
    end
end)

hook.Add("DoPlayerDeath","apAdvStoreSaveData",function(ply) 
    StorePlyData(ply)
end)

hook.Add("PlayerDisconnected","apAdvStoreSaveData",function(ply) 
    StorePlyData(ply)
end)

hook.Add("PlayerSpawn","apAdvApplyPlySave", function(ply)
    local sid = ply:SteamID64()
    local plysav = APADV_PLYSAVE[sid]
    if plysav then
        timer.Simple(0,function()
            ply:SetArmor(math.max(ply:Armor(),plysav.armor))

            for k,v in pairs(plysav.ammo) do
                ply:SetAmmo(math.max(v,ply:GetAmmoCount(k)),k)
            end
        end)
    end
end)