
include("apadventure/cl/mapiconmat.lua")

if engine.ActiveGamemode() == "sandbox" then 
    apAdventure.EditMode = true
    include("apadventure/editmode_shared.lua")
    include("apadventure/cl/editmode.lua")
end

concommand.Add("apadventure_save_manager",function(ply) 
    if !(ply:IsListenServerHost() or ply:IsUserGroup("superadmin")) then return end
    include("apadventure/ui/savemanage.lua")()
end)

net.Receive("APAdvSaveManageData",function() 
    if IsValid(apAdventure.SaveManager) then
        apAdventure.SaveManager:ReceiveData(net.ReadString())
    end
end)

local notifsnd = {
    [0] = "ambient/water/drip3.wav",
    [1] = "buttons/button10.wav",
    [2] = "buttons/button15.wav",
    [3] = "ambient/water/drip2.wav",
}

net.Receive("ApAdvNotif",function()
    local type = net.ReadUInt(3)
    local text = net.ReadString()
    local len = net.ReadFloat()
    local snd = net.ReadString()
    if text[1] == "#" then
        text = language.GetPhrase(string.sub(text,2,-1))
    end
    notification.AddLegacy(text,type,len)
    if snd == "_" then return end
    if snd == "" then snd = notifsnd[type] end
    if !snd then return end
    surface.PlaySound(snd)
end)

concommand.Add("apadventure_dump_ammotypes",function()
    for k,v in pairs(game.GetAmmoTypes()) do
        print(k,v)
    end
end)