local ITEM = {}

ITEM.Name = "Bugbait"
ITEM.Type = "Weapon"
ITEM.MinAmt = 1
ITEM.Capabilities = {"AntlionFriendly","AntlionControl","BugbaitTrigger"}
ITEM.ConditionalCapabilities = {
    ["Antlions_Controllable"] = {}
}
ITEM.RequireCondition = true

ITEM.Class = "weapon_bugbait"

local oldstate = game.GetGlobalState("antlion_allied")

function ITEM.Handle(iList)
    local val = iList[1] != nil
    game.SetGlobalState("antlion_allied",val and 1 or 0)
    APADV.AntlionFriendly = val
    if isfunction(APADV_CFGLUA.OnAntlionStatusUpdate) then
        APADV_CFGLUA:OnAntlionStatusUpdate(val)
    end
end

function ITEM.Unregister()
    APADV.AntlionFriendly = nil
    game.SetGlobalState("antlion_allied",oldstate)
end

-- might just have the gamemode always do this
hook.Add("ShutDown","APADV_KillAntlionGlobal",function() 
    game.SetGlobalState("antlion_allied",GLOBAL_DEAD)
end)

return ITEM