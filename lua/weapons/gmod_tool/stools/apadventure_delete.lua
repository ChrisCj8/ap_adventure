
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
        cPnl:Help("#tool.apadventure_delete.help_point_template")
        local idlistcontainer = vgui.Create("DCollapsibleCategory",cPnl)
        idlistcontainer:SetLabel("#tool.apadventure_delete.idlist.label")
        cPnl:AddItem(idlistcontainer)

            local cIdList = vgui.Create("DListView",idlistcontainer)
            
            local idcol = cIdList:AddColumn("#tool.apadventure_delete.idlist.cid")
            cIdList:SetPos(5,25)
            cIdList:SetHeight(300)
            idcol:SetFixedWidth(40)
            cIdList:AddColumn("#tool.apadventure_delete.idlist.classname")
            cIdList:AddColumn("#tool.apadventure_delete.lists.targetname")

            function cIdList:ProcessDelMark() 
                for k,v in ipairs(self:GetLines()) do
                    self:RemoveLine(v:GetID())
                end
                for k,v in pairs(apAdventure.EditCfg.DelMark) do
                    self:AddLine(k,v.class,v.name)
                end
            end
            cIdList:ProcessDelMark()

            local iddelbtn = vgui.Create("DButton",idlistcontainer)
            iddelbtn:SetText("#tool.apadventure_delete.lists.delbtn")
            function iddelbtn:DoClick()
                for k,v in ipairs(cIdList:GetSelected()) do
                    net.Start("APAdvDelMark")
                        net.WriteUInt(v:GetValue(1),14)
                        net.WriteBool(false)
                    net.SendToServer()
                end
            end
            iddelbtn:SetPos(5,330)

            local idmarkin = vgui.Create("DTextEntry",idlistcontainer)
            idmarkin:SetNumeric(true)
            idmarkin:SetPos(5,357)
            idmarkin:SetHeight(22)
            idmarkin:SetWidth(80)

            local idmarkbtn = vgui.Create("DButton",idlistcontainer)
            idmarkbtn:SetText("#tool.apadventure_delete.idlist.markbtn")
            idmarkbtn:SetPos(90,357)
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

        local namelistcontainer = vgui.Create("DCollapsibleCategory",cPnl)
        namelistcontainer:SetLabel("#tool.apadventure_delete.namelist.label")
        cPnl:AddItem(namelistcontainer)

            local namelist = vgui.Create("DListView",namelistcontainer)
            namelist:SetPos(5,25)
            namelist:SetHeight(300)
            namelist:AddColumn("#tool.apadventure_delete.lists.targetname")

            function namelist:ProcessDelMark() 
                for k,v in ipairs(self:GetLines()) do
                    self:RemoveLine(v:GetID())
                end
                for k,v in pairs(apAdventure.EditCfg.DelName) do
                    self:AddLine(k)
                end
            end
            namelist:ProcessDelMark()

            local namedelbtn = vgui.Create("DButton",namelistcontainer)
            namedelbtn:SetText("#tool.apadventure_delete.lists.delbtn")
            function namedelbtn:DoClick()
                for k,v in ipairs(namelist:GetSelected()) do
                    net.Start("APAdvDelNameMark")
                        net.WriteString(v:GetValue(1))
                        net.WriteBool(false)
                    net.SendToServer()
                end
            end
            namedelbtn:SetPos(5,330)

            local namemarkin = vgui.Create("DTextEntry",namelistcontainer)
            namemarkin:SetPos(5,357)
            namemarkin:SetHeight(22)

            local namemarkbtn = vgui.Create("DButton",namelistcontainer)
            namemarkbtn:SetText("#tool.apadventure_delete.namelist.markbtn")
            namemarkbtn:SetPos(90,357)
            namemarkbtn:SetSize(150,22)
            function namemarkbtn:DoClick()
                local name = namemarkin:GetValue()
                if name == "" then 
                    surface.PlaySound("buttons/button10.wav")
                    return 
                end
                net.Start("APAdvDelNameMark") 
                    net.WriteString(name)
                    net.WriteBool(true)
                net.SendToServer()
            end

            local oldlayout = namelistcontainer.PerformLayout
            function namelistcontainer:PerformLayout(w,h)
                oldlayout(self,w,h)
                namelist:SetWidth(w-10)
                namedelbtn:SetWidth(w-10)
                namemarkin:SetWidth(w-165)
                namemarkbtn:SetPos(w-155,357)
            end

        apAdventure.DeleteByNameList = namelist

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
        if !apAdventure.NameDelMark(name,true) then return end
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
        if !apAdventure.NameDelMark(name,false) then return end
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