APADV = APADV or {}

APADV_ITEMHANDLERS = APADV_ITEMHANDLERS or {}

function ApAdvItemHandler(slot,id,itemlist)
    if APADV_ITEMHANDLERS[id] then 
        APADV_ITEMHANDLERS[id](itemlist)
    end
    
end

local handlers_registered = handlers_registered or false

APADV_ITEMSUSED = APADV_ITEMSUSED or {}

function ApAdvRegisterItemHandlers()
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
                    handle[itemid] = function(iList)
                        if !APADV_ITEMSUSED[itemid] or APADV_ITEMSUSED[itemid] < #iList then
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
end

local dp_loaded = dp_loaded or false


function ApAdvDPLoad(slot,datapackage)
    dp_loaded = true
    APADV_DATAPACK = datapackage
    APADV_DATAPACK_LOCAL = datapackage.games.gmAdventure
    if APADV_SLOT.slotData and !handlers_registered then
        ApAdvRegisterItemHandlers()
    end
end

function ApAdvCreateApSlot(addr,slotn,pw,slotdata)
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
        
        if APADV_RUNID or !next(ApAdv_LastMapTbl) then
            local map = game.GetMap()
            if map == slotdata.startmap then
                APADV_USESTART = slotdata.startregion
                LoadCfg(slotdata.startgroup)
            elseif APADV_SAVEDATA.visited and APADV_SAVEDATA.visited[map] then
                local groupname, grouptbl = next(APADV_SAVEDATA.visited[map])
                ApAdv_EntrName = next(grouptbl)
                LoadCfg(groupname)
            else
                ApAdv_NextMapTbl.SentToStart = slotdata.startregion
                DoMapTransition(slotdata.startmap,slotdata.startgroup)
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

function ApAdvSendLocation(lctn)
    if !APADV_SLOT or !APADV_SLOT.Connected then return false end

    print("sending location",lctn)
    APADV_SLOT:SendLocation(lctn)
    return true
end

function ApAdvAddTracker(type,trackedID,hookID,method)
    GMAP.AddTracker("APADV",type,trackedID,hookID,method)
end

function ApAdvRemoveTracker(type,trackedID,hookID)
    GMAP.RemoveTracker("APADV",type,trackedID,hookID)
end

hook.Add("AP_Connect","APADV",function(slotID) 

    local room = APADV_SLOT.Room

    if slotID != "APADV" then return end

    APADV_SLOT:DataStoreSet("gmadv_runid",room.seed_name.."_"..math.floor(room.time),OnRunID,{{operation="default",value=""}})

end)

net.Receive("apAdvConnectionInfo",function(len,ply)
    local addr = net.ReadString()
    local slotn = net.ReadString()
    local pw = net.ReadString()

    print("received connection info",addr,slotn,pw)

    ApAdvCreateApSlot(addr,slotn,pw)
end)
