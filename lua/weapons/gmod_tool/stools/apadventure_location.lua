
TOOL.ClientConVar = {
    region = "base",
    name = "default",
    isdummy = "0",
}

if CLIENT then
    TOOL.Name = "#tool.apadventure_location.shortname"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left"},
        {name="right"}
    }

    local AccessPanel = include("apadventure/ui/access.lua")
    
    apAdventure.LocationAccessTbl = apAdventure.LocationAccessTbl or {}

    local accesspnl

    function TOOL.BuildCPanel(cPnl)
        cPnl:TextEntry("#apadventure.toolui.region","apadventure_location_region")
        cPnl:ControlHelp("#tool.apadventure_location.region_help")
        cPnl:TextEntry("#tool.apadventure_location.name_ui","apadventure_location_name")
        cPnl:ControlHelp("#tool.apadventure_location.name_help")
        cPnl:CheckBox("#tool.apadventure_location.isdummy","apadventure_location_isdummy")
        cPnl:ControlHelp("#tool.apadventure_location.isdummy_help")
        accesspnl = include("apadventure/ui/access.lua")(cPnl,400)
        accesspnl:LoadTbl(apAdventure,"LocationAccessTbl")
        accesspnl:DockMargin(5,5,5,5)
        accesspnl:Dock(TOP)
    end

    net.Receive("APAdvLocationAccess",function()
        local acctbl = apAdventure.LocationAccessTbl
        local json = "[]"
        if acctbl then json = util.TableToJSON(acctbl) end
        local done

        repeat
            local msg = string.sub(json,1,60000)
            json = string.sub(json,60001,-1)
            done = #json <= 0
            net.Start("APAdvLocationAccess")
                net.WriteString(msg)
                net.WriteBool(done)
            net.SendToServer()
        until done
    end)

    local jsonmsg = ""

    net.Receive("APAdvLocationAccessCopy",function()
        jsonmsg = jsonmsg..net.ReadString()

        print(jsonmsg)

        if net.ReadBool() then
            local accesstbl = util.JSONToTable(jsonmsg)
            if accesstbl then
                apAdventure.LocationAccessTbl = accesstbl
            else
                apAdventure.LocationAccessTbl = {}
                if jsonmsg != "" then
                    ErrorNoHalt("Received Invalid Access JSON Table from the Server when copying Settings from the Location Entity.\n")
                end
            end
            PrintTable(apAdventure.LocationAccessTbl)
            if IsValid(accesspnl) then
                accesspnl:LoadTbl(apAdventure,"LocationAccessTbl")
            end
            jsonmsg = ""
        end
    end)

    return
end

util.AddNetworkString("APAdvLocationAccess")
util.AddNetworkString("APAdvLocationAccessCopy")

local reqname
local jsonmsg = ""

net.Receive("APAdvLocationAccess",function() 
    jsonmsg = jsonmsg..net.ReadString()

    if net.ReadBool() then
        if reqname then
            local accesstbl = util.JSONToTable(jsonmsg)
            if accesstbl then
                if next(accesstbl) then
                    apAdventure.EditCfg.LocationAccess[reqname] = accesstbl
                else
                    apAdventure.EditCfg.LocationAccess[reqname] = nil
                end
            else
                ErrorNoHalt("Received Location Access Table for "..reqname.." was not a valid JSON Table.\n")
                print(jsonmsg)
            end
            jsonmsg = ""
        else
            jsonmsg = ""
            ErrorNoHalt("Received a Location Access Table despite not making a request for it.\n")
        end
        reqname = nil
    end
end)



function TOOL:LeftClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    local region = self:GetClientInfo("region")
    local name = self:GetClientInfo("name")
    local isdummy = self:GetClientBool("isdummy")
    local changerule = self:GetClientBool("hasrule")
    if ent:GetClass() == "apadventure_location_editor" then
        ent:SetRegion(region)
        ent:SetLctnName(name)
        ent:SetIsDummy(isdummy)
    else
        ent = ents.Create("apadventure_location_editor")
        if !IsValid(ent) then return end
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        local curpos = ent:GetPos()
        ent:SetPos(tr.HitPos+curpos-ent:NearestPoint(curpos-(tr.HitNormal*512)))
        ent:SetRegion(region)
        ent:SetLctnName(name)
        ent:SetIsDummy(isdummy)
        undo.Create("apadventure_location_editor")
            undo.AddEntity(ent)
            undo.SetPlayer(self:GetOwner())
        undo.Finish()    
    end
    -- kinda sucks that were sending an entire json table every time the user wants to place or update a location
    -- but in theory i don't think people will be editing their configs in multiplayer much so this *should* be fine
    reqname = name
    net.Start("APAdvLocationAccess")
    net.Send(self:GetOwner())
end

function TOOL:RightClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    if !IsValid(ent) then return end
    local owner = self:GetOwner()
    if isfunction(ent.CopyRegionName) then
        owner:ConCommand("apadventure_location_region \""..ent:CopyRegionName().."\"")
    end
    if ent:GetClass() == "apadventure_location_editor" then
        local name = ent:GetLctnName()
        owner:ConCommand("apadventure_location_name \""..name.."\"")
        owner:ConCommand("apadventure_location_isdummy \""..(ent:GetIsDummy() and 1 or 0).."\"")
        local accesstbl = apAdventure.EditCfg.LocationAccess[name]
        local receiver = self:GetOwner()
        local json = util.TableToJSON(accesstbl or {})
        local done

        repeat
            local msg = string.sub(json,1,60000)
            json = string.sub(json,60001,-1)
            done = #json <= 0
            net.Start("APAdvLocationAccessCopy")
                net.WriteString(msg)
                net.WriteBool(done)
            net.Send(receiver)
        until done
    end
end