APADV = APADV or {}

APADV_ITEMHANDLERS = APADV_ITEMHANDLERS or {}

local function ApAdvItemHandler(slot,id,itemlist)
    if APADV_ITEMHANDLERS[id] then 
        APADV_ITEMHANDLERS[id](itemlist)
    end
    
    print(id,APADV_MAPITEMCOUNTERS[id])

    if APADV_MAPITEMCOUNTERS[id] then
        PrintTable(APADV_MAPITEMCOUNTERS[id])
        for k,v in pairs(APADV_MAPITEMCOUNTERS[id]) do
            print(k,"finding ",v.target)
            for ik,iv in ipairs(ents.FindByName(v.target)) do
                print("firing ",iv,v.input,#itemlist,v.delay)
                iv:Fire(v.input,#itemlist,v.delay)
            end
        end
    end
end

APADV_LOCENTS = APADV_LOCENTS or {}

local function ApAdvLocationHandler(slot,id,state)
    local locname = APADV_DATAPACK_LOCAL.location_id_to_name[id]
    if !locname then 
        ErrorNoHalt("Received a Location update for an ID that's not in the DataPackage")
        return 
    end
    local loctbl = APADV_LOCENTS[locname]
    if loctbl and state then
        for k,v in pairs(loctbl) do
            if IsValid(k) then
                k:Remove()
            end
            loctbl[k] = nil
        end
        if !next(loctbl) then
            APADV_LOCENTS[locname] = nil
        end
    end
end

local handlers_registered = handlers_registered or false

APADV_ITEMSUSED = APADV_ITEMSUSED or {}

function APADV.RegisterMapItems(itemtbl)
    if !itemtbl then
        itemtbl = APADV.MapItemTbl
        APADV.MapItemTbl = nil
    end

    local map = game.GetMap()
    local toID = APADV_DATAPACK_LOCAL.item_name_to_id
    for k,v in pairs(APADV.MapItemCounters) do
        local id = toID[APADV_MAPGROUP.." - "..map.." - "..k]
        if id then
            local outtbl = {}
            for ik,iv in ipairs(v) do
                outtbl[ik] = iv
                for iik,iiv in ipairs(ents.FindByName(iv.target)) do
                    iiv:Fire(iv.input,iv.param,iv.delay)
                end
            end
            print("new mapitem table")
            PrintTable(outtbl)
            if next(outtbl) then
                APADV_MAPITEMCOUNTERS[id] = outtbl
            end
        end 
    end
end

local function ApAdvRegisterItemHandlers()
    local dp = APADV_SLOT.Room.DataPackage.games.gmAdventure
    local toID = dp.item_name_to_id

    local handle = APADV_ITEMHANDLERS

    local slotdata = APADV_SLOT.slotData

    handle[toID["McGuffin"]] = function(iList)
        if iList[1] != nil then
            APADV_SLOT:SendGoal()
        end
    end

    if slotdata.bhop == 2 then
        handle[toID["Bunnyhop"]] = function(iList) 
            ApAdvPly.UpdateBHop(iList[1] != nil)
        end
    end

    for k,v in ipairs(slotdata.itemsets) do
        local setpath = "apadventure/itemsets/"..v
        local setdata = include(setpath..".lua")
        local setfiles = file.Find(setpath.."/*.lua","LUA")
        for ik,iv in ipairs(setfiles) do
            local itemtbl = include(setpath.."/"..iv)
            local itemid = toID[itemtbl.Name.." - "..setdata.Name]
            if itemid then
                if itemtbl.OneUse then
                    APADV_ITEMSUSED[itemid] = APADV_ITEMSUSED[itemid] or 0
                    handle[itemid] = function(iList)
                        if APADV_ITEMSUSED[itemid] < #iList then
                            local redeem = itemtbl.RedeemCheck()
                            print(itemtbl.Name,"redeem:",redeem)
                            if redeem == true then
                                itemtbl.Redeem()
                                APADV_ITEMSUSED[itemid] = (APADV_ITEMSUSED[itemid] or 0) + 1
                                handle[itemid](iList)
                            elseif isnumber(redeem) then
                                timer.Simple(redeem,function() handle[itemid](iList) end)
                            end
                        end
                    end
                elseif itemtbl.Weapon then
                    handle[itemid] = function(iList)
                        ApAdvWeps.SetAvailable(itemtbl.Class,iList[1] != nil)
                    end
                end
            end
        end
    end

    handlers_registered = true

    local empty = {} -- kinda hacky but this means item handlers don't have to do nil checks

    if APADV.MapItemTbl then
        APADV.RegisterMapItems()
    end

    for k,v in pairs(handle) do
        v(APADV_SLOT.Items[k] or empty)
    end
end

local dp_loaded = dp_loaded or false

local function ApAdvDPLoad(slot,datapackage)
    dp_loaded = true
    APADV_DATAPACK = datapackage
    APADV_DATAPACK_LOCAL = datapackage.games.gmAdventure
    if APADV_SLOT.slotData and !handlers_registered then
        ApAdvRegisterItemHandlers()
    end
end

function APADV.CreateApSlot(addr,slotn,pw,slotdata)
    local getslotdata = true
    

    if !APADV_SLOT or (!APADV_SLOT.Connected and !APADV_SLOT.Reconnecting) then

        if slotdata then
            getslotdata = false
        end

        dp_loaded = false
        handlers_registered = false

        APADV_ITEMHANDLERS = {}

        APADV_SLOT = GMAP.NewSlot({
            ID = "APADV",
            address = addr,
            slotName = slotn,
            password = pw,
            game = "gmAdventure",
            receiveAPchat = true,
            forwardAPchat = true,
            forwardGMODchat = true,
            deathlink = false,
            getSlotData = getslotdata,
            dontStore = true,
            slotData = slotdata
        })

        APADV_SLOT.OnItemUpdate = ApAdvItemHandler
        APADV_SLOT.OnDataPackageLoad = ApAdvDPLoad
        APADV_SLOT.OnLocationUpdate = ApAdvLocationHandler

        APADV_SLOT:Connect()
    end
end

local function OnRunID(packet)
    PrintTable(packet)
    local runid = packet.value
    if APADV_RUNID != runid then
        
        local slotdata = APADV_SLOT.slotData
        local room = APADV_SLOT.Room

        APADV.InitSaveData(runid)
        
        if APADV_RUNID or !next(APADV_LASTMAPTBL) then
            local map = game.GetMap()
            if map == slotdata.startmap then
                APADV_USESTART = slotdata.startregion
                APADV.LoadCfg(slotdata.startgroup)
            elseif APADV_SAVEDATA.visited and APADV_SAVEDATA.visited[map] then
                local groupname, grouptbl = next(APADV_SAVEDATA.visited[map])
                APADV_ENTRNAME = next(grouptbl)
                APADV.LoadCfg(groupname)
            else
                APADV_NEXTMAPTBL.SentToStart = slotdata.startregion
                APADV.DoMapTransition(slotdata.startmap,slotdata.startgroup)
            end
        end

        handlers_registered = false

        ApAdvPly.UpdateBHop(slotdata.bhop == 3)
        game.SetSkillLevel(slotdata.skill)

        APADV_ENTRANCES = {}

        for k,v in ipairs(slotdata.entrances) do
            local from = string.Explode(" - ",v[1])
            local to = string.Explode(" - ",v[2])

            APADV_ENTRANCES[from[1]] = APADV_ENTRANCES[from[1]] or {}
            APADV_ENTRANCES[from[1]][from[2]] = APADV_ENTRANCES[from[1]][from[2]] or {}
            APADV_ENTRANCES[from[1]][from[2]][from[4]] = {
                group = to[1],
                map = to[2],
                entr = to[4],
            }
        end

        if APADV_ENTRANCES and APADV_ENTRANCES[APADV_MAPGROUP] and APADV_ENTRANCES[APADV_MAPGROUP][APADV_MAP] then
            local mapexits = APADV_ENTRANCES[APADV_MAPGROUP][APADV_MAP]
            for k,v in pairs(APADV_EXITENTS) do
                if mapexits[v] then 
                    -- the Advanced Color Tool throws errors if this isn't wrapped in a timer
                    timer.Simple(1,function() k:SetMapIcon(mapexits[v].map) end)
                end
            end
        end

        if dp_loaded then
            ApAdvRegisterItemHandlers()
        end
        
        APADV_RUNID = runid
    end
end

function APADV.SendLocation(lctn)
    if !APADV_SLOT or !APADV_SLOT.Connected then return false end

    print("sending location",lctn)
    APADV_SLOT:SendLocation(lctn)
    return true
end

function APADV.SendMapLocation(lctn)
    if !APADV_SLOT or !APADV_SLOT.Connected or !APADV_DATAPACK_LOCAL or !APADV_MAPGROUP then return false end
    local locname = APADV_MAPGROUP.." - "..game.GetMap().." - "..lctn
    local ID = APADV_DATAPACK_LOCAL.location_name_to_id[locname]   
    if !ID then return false end
    APADV_SLOT:SendLocation(ID)
    return true
end

function APADV.AddTracker(type,trackedID,hookID,method)
    GMAP.AddTracker("APADV",type,trackedID,hookID,method)
end

function APADV.RemoveTracker(type,trackedID,hookID)
    GMAP.RemoveTracker("APADV",type,trackedID,hookID)
end

hook.Add("AP_Connect","APADV",function(slotID) 

    if slotID != "APADV" then return end

    local room = APADV_SLOT.Room

    net.Start("ApAdvConnectionState")
        net.WriteBool(true)
    net.Broadcast()

    APADV_SLOT:DataStoreSet("gmadv_runid",room.seed_name.."_"..math.floor(room.time),OnRunID,{{operation="default",value=""}})

end)

hook.Add("AP_Disconnect","APADV",function(slotID) 

    if slotID != "APADV" then return end

    local room = APADV_SLOT.Room

    net.Start("ApAdvConnectionState")
        net.WriteBool(false)
    net.Broadcast()

end)

net.Receive("apAdvConnectionInfo",function(len,ply)
    local addr = net.ReadString()
    local slotn = net.ReadString()
    local pw = net.ReadString()

    print("received connection info",addr,slotn,pw)

    APADV.CreateApSlot(addr,slotn,pw)
end)
