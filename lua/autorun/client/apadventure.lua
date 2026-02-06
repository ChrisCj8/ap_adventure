
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