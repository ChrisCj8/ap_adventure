
apAdventure.MapIconMats = apAdventure.MapIconMats or {}

util.AddNetworkString("APAdvMapIconMat")

local function addnewmat(map)
    apAdventure.MapIconMats[map] = true
    net.Start("APAdvMapIconMat")
        net.WriteString(map)
    net.Broadcast()
end

function apAdventure.GetMapIconMat(map,loadedcb)
    if !apAdventure.MapIconMats[map] then
        addnewmat(map)
    end
    if isfunction(loadedcb) then
        loadedcb("!apadventure_mapicon_"..map)
    end
end



hook.Add("PlayerInitialSpawn","apAdventureLoadMapIconMats",function(ply) 
    for k,v in pairs(apAdventure.MapIconMats) do
        net.Start("APAdvMapIconMat")
            net.WriteString(k)
        net.Send(ply)
    end
end)