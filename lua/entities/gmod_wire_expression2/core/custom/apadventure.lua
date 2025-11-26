if !GMAP then return end

E2Lib.RegisterExtension("apadventure",true,"Allows E2 Chips to interact with Archipelago")
-- I think enabling this by default and not including any additional warnings should be fine, this can't do much more than what the regular AP Wire Entities already can

--[[ local bool2tonum = {
    [true] = 1,
    [false] = 0
}]]

__e2setcost(5)

e2function void apAdvSendChat(string msg)
    if APADV_SLOT != nil and APADV_SLOT.Connected then
        APADV_SLOT:SendChatMessage(msg)
    end
end

e2function number apAdvIsConnected()
    if APADV_SLOT != nil and APADV_SLOT.Connected then
        return 1
    else
        return 0
    end
end

e2function number apAdvIsRegistered()
    if APADV_SLOT != nil then
        return 1
    else
        return 0
    end
end

e2function void apAdvSendLctn(lctn)
    if APADV_SLOT != nil and APADV_SLOT.Connected then
        APADV_SLOT:SendLocation(lctn)
    end
end

e2function void apAdvSendLctn(string lctn)
    if APADV_SLOT != nil and APADV_SLOT.Connected then
        APADV_SLOT:SendLocation(lctn)
    end
end

e2function number apAdvItemAmount(item)
    if APADV_SLOT != nil and APADV_SLOT.Connected and APADV_SLOT.Items and APADV_SLOT.Items[item] then
        return #APADV_SLOT.Items[item]
    end
    return 0
end

e2function number apAdvItemAmount(string item)
    if !APADV_SLOT or !APADV_SLOT.Room or !APADV_SLOT.Room.DataPackage or !APADV_SLOT.Room.DataPackage.games.gmAdventure then
        
    end
    local item
    if APADV_SLOT != nil and APADV_SLOT.Connected then
        APADV_SLOT:SendLocation(lctn)
    end
    return 0
end