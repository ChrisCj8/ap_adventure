
if CLIENT then
    TOOL.Name = "#tool.apadventure_inspector.shortname"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left",icon="gui/lmb.png"},
        {name="reload",icon="gui/r.png"}
    }

    apAdventure.InspectorInfo = apAdventure.InspectorInfo or {}

    local inspectorinfo = apAdventure.InspectorInfo
    local inspectorinfoamt = 0

    local class2icon = {
        point_template = Material("editor/point_template")
    }
    local obsolete = Material("editor/obsolete")
    net.Receive("APAdvInspectorInfo",function() 
        if net.ReadBool() then
            apAdventure.InspectorInfo = {}
            inspectorinfo = apAdventure.InspectorInfo
            inspectorinfoamt = 0
        end
        inspectorinfoamt = inspectorinfoamt + 1
        inspectorinfo[inspectorinfoamt] = {
            name = net.ReadString(),
            class = net.ReadString(),
            pos = net.ReadVector(),
            creationid = net.ReadInt(15),
            deleted = net.ReadBool(),
        }
        inspectorinfo[inspectorinfoamt].icon = class2icon[inspectorinfo[inspectorinfoamt].class] or  obsolete
        PrintTable(inspectorinfo)
    end)

    apAdventureHideInspectorInfo = true
    local deletedicon = Material("icon16/bin.png")
    -- i think this should help reduce the amount of lookups and make the code run faster
    local setmat = surface.SetMaterial
    local drawtexrect = surface.DrawTexturedRect
    local drawtext = draw.DrawText
    local start3d2d = cam.Start3D2D
    local end3d2d = cam.End3D2D

    hook.Add("PreDrawEffects","APAdvInspector",function()
        if apAdventureHideInspectorInfo then return end
        local textfacing = apAdventure.TextFacing
        for k,v in ipairs(inspectorinfo) do
            start3d2d(v.pos,textfacing,.5)
                setmat(v.icon)
                drawtexrect(-16,-16,32,32)
                drawtext(v.class..
                    "\n Name: "..v.name..
                    "\n Creation ID: "..v.creationid,
                    "BudgetLabel",0,-100,color_white,TEXT_ALIGN_CENTER)
                if v.deleted then
                    setmat(deletedicon)
                    drawtexrect(-8,-130,16,16)
                end
            end3d2d()
        end
        
    end)

    if game.SinglePlayer() then
        net.Receive("APAdvInspectorToggleInfo",function()
            apAdventureHideInspectorInfo = !apAdventureHideInspectorInfo
        end)

    else
        function TOOL:LeftClick()
            apAdventureHideInspectorInfo = !apAdventureHideInspectorInfo
        end
    end

end

if SERVER then
    util.AddNetworkString("APAdvInspectorInfo")

   --[[  net.Receive("APAdvInspectorInfo",function(len,ply) 
        
    end) ]]

    function TOOL:Reload()
        local first = true
        local delmarks = apAdventure.EditCfg.DelMark
        for k,v in ipairs(ents.FindByClass("point_template")) do
            net.Start("APAdvInspectorInfo")
                net.WriteBool(first)
                first = false
                net.WriteString(v:GetName() or "")
                net.WriteString(v:GetClass())
                net.WriteVector(v:GetPos())
                net.WriteInt(v:MapCreationID(),15)
                net.WriteBool(delmarks[v:MapCreationID()])
            net.Send(self:GetOwner())
        end
    end

    if game.SinglePlayer() then
        util.AddNetworkString("APAdvInspectorToggleInfo")

        function TOOL:LeftClick()
            net.Start("APAdvInspectorToggleInfo")
            net.Broadcast()
        end
    
    end
end
