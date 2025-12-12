
if CLIENT then
    TOOL.Name = "#tool.apadventure_delete.shortname"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left"},
        {name="right"},
        {name="reload"},
        {name="creationmode",op=0},
        {name="namemode",op=1},
    }

    function TOOL.BuildCPanel(cPnl)
        cPnl:Help("#tool.apadventure_delete.help1")
        cPnl:Help("#tool.apadventure_delete.help_cid")
        cPnl:Help("#tool.apadventure_delete.help_targetname")
        local idlistcontainer = vgui.Create("DCollapsibleCategory",cPnl)
        idlistcontainer:SetLabel("#tool.apadventure_delete.idlist.label")
        cPnl:AddItem(idlistcontainer)

            cIdList = vgui.Create("DListView",idlistcontainer)
            
            local idcol = cIdList:AddColumn("#tool.apadventure_delete.idlist.cid")
            cIdList:SetPos(5,25)
            cIdList:SetHeight(400)
            idcol:SetFixedWidth(40)
            cIdList:AddColumn("#tool.apadventure_delete.idlist.classname")
            cIdList:AddColumn("#tool.apadventure_delete.idlist.targetname")

            function cIdList:ProcessDelMark() 
                for k,v in ipairs(self:GetLines()) do
                    self:RemoveLine(v:GetID())
                end
                for k,v in pairs(apAdventure.EditCfg.DelMark) do
                    self:AddLine(k,v.class,v.name)
                end
            end
            cIdList:ProcessDelMark()

            iddelbtn = vgui.Create("DButton",idlistcontainer)
            iddelbtn:SetText("#tool.apadventure_delete.idlist.delbtn")
            function iddelbtn:DoClick()
                for k,v in ipairs(cIdList:GetSelected()) do
                    net.Start("APAdvDelMark")
                        net.WriteUInt(v:GetValue(1),14)
                        net.WriteBool(false)
                    net.SendToServer()
                end
            end
            iddelbtn:SetPos(5,430)

            idmarkin = vgui.Create("DTextEntry",idlistcontainer)
            idmarkin:SetNumeric(true)
            idmarkin:SetPos(5,457)
            idmarkin:SetHeight(22)
            idmarkin:SetWidth(80)

            idmarkbtn = vgui.Create("DButton",idlistcontainer)
            idmarkbtn:SetText("#tool.apadventure_delete.idlist.markbtn")
            idmarkbtn:SetPos(90,457)
            function idmarkbtn:DoClick()
                local id = idmarkin:GetFloat()
                if !id or id < 1 then 
                    surface.PlaySound("buttons/button10.wav")
                    return 
                end
                local id = math.floor(id)
                net.Start("APAdvDelMark") 
                    net.WriteUInt(id,14)
                    net.WriteBool(true)
                net.SendToServer()
            end
            

            local oldlayout = idlistcontainer.PerformLayout
            function idlistcontainer:PerformLayout(w,h)
                oldlayout(self,w,h)
                cIdList:SetWidth(w-10)
                iddelbtn:SetWidth(w-10)
                idmarkbtn:SetWidth(w-95)
            end

        apAdventure.DeleteByCIdList = cIdList

        cPnl:CheckBox("#tool.apadventure_delete.dohalos","apadventure_editor_show_delete_halos")
    end
    return
end

local EntFilter = {
    worldspawn=true
}

function TOOL:LeftClick(tr)
    local hitent = tr.Entity
    if !hitent or EntFilter[hitent:GetClass()] then return end
    local op = self:GetOperation()
    if op == 0 then
        if !apAdventure.DelMark(hitent,true) then return end
    else
        local name = hitent:GetName()
        if name == "" then return end
        apAdventure.EditCfg.DelName[name] = true
    end
    return apAdventure.SpoofToolShot(self,tr)
end

function TOOL:RightClick(tr)
    local hitent = tr.Entity
    if !hitent or EntFilter[hitent:GetClass()] or hitent:MapCreationID() == -1 then return end
    local op = self:GetOperation()
    if op == 0 then
        if !apAdventure.DelMark(hitent,false) then return end
    else
        local name = hitent:GetName()
        if name == "" then return end
        apAdventure.EditCfg.DelName[name] = nil
    end
    return apAdventure.SpoofToolShot(self,tr)
end

function TOOL:Reload()
    local curop = self:GetOperation()
    if curop == 1 then
        self:SetOperation(0)
    else
        self:SetOperation(curop+1)
    end
end