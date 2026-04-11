local NODE = {
    Icon = "icon16/gun.png"
}

local UImake = vgui.Create

local capabs = {
    "WimpyMelee",
    "WeakMelee",
    "DecentMelee",
    "StrongMelee",
    "WimpyShortRange",
    "WeakShortRange",
    "DecentShortRange",
    "StrongShortRange",
    "WimpyMidRange",
    "WeakMidRange",
    "DecentMidRange",
    "StrongMidRange",
    "WimpyLongRange",
    "WeakLongRange",
    "DecentLongRange",
    "StrongLongRange",
    "WeakAOE",
    "MidAOE",
    "StrongAOE",
    "TinyArcProjectile",
    "ShortArcProjectile",
    "MediumArcProjectile",
    "LongArcProjectile",
    "PhysicsProjectile",
    "FlyingProjectile",
    "TinyExplosion",
    "SmallExplosion",
    "MediumExplosion",
    "LargeExplosion",
    "WeakSpam",
    "MidSpam",
    "StrongSpam",
    "HeliKiller",
    "Waterproof",
    "AntlionFriendly",
    "AntlionControl",
    "BugbaitTrigger",
    "MediumSizeOrSmallerExplosion", 
    "SmallOrSmallerExplosion",
    "LargeOrSmallerExplosion", 
    "MediumOrSmallerExplosion",
    "TinyOrLargerExplosion", 
    "SmallOrLargerExplosion",
    "MediumSizeOrLargerExplosion",
}

function NODE.Panel(parent)

    local nodetbl = parent.nodetbl

    local capselectiontypebtn = UImake("DImageButton",parent)
    capselectiontypebtn:SetSize(16,16)
    capselectiontypebtn:SetImage("icon16/pencil.png")
    capselectiontypebtn:SetPos(5,7)
    
    local textinputactive = false

    local capselect = UImake("DComboBox",parent)
    capselect:SetPos(25,5)
    local first = true
    for k,v in ipairs(capabs) do
        capselect:AddChoice(v,v,first)
        first = false
    end

    local capnamein = UImake("DTextEntry",parent)
    capnamein:SetPos(25,5)
    capnamein:SetVisible(false)

    local capaddbtn = UImake("DImageButton",parent)
    capaddbtn:SetSize(16,16)
    capaddbtn:SetImage("icon16/add.png")

    local capdelbtn = UImake("DImageButton",parent)
    capdelbtn:SetSize(16,16)
    capdelbtn:SetImage("icon16/delete.png")

    local caplist = UImake("DListView",parent)
    caplist:SetPos(5,30)
    caplist:AddColumn("Capability")

    for k,v in ipairs(nodetbl.capab) do
        caplist:AddLine(v)
    end

    /*
        these next two functions kinda suck because it'd normally be better to use
        a lookup table here but having it as a list is better for the generator and
        doing the conversion when the client config is being converted to logic was
        also surprisingly expensive so i think this justifiable because these lists
        really shouldn't be that long anyways
    */

    function capselectiontypebtn:DoClick()
        textinputactive = !textinputactive
        capselect:SetVisible(!textinputactive)
        capnamein:SetVisible(textinputactive)
        self:SetImage(textinputactive and "icon16/text_list_bullets.png" or "icon16/pencil.png")
    end

    function capaddbtn:DoClick()
        local data, _
        if textinputactive then
            data = capnamein:GetText()
        else
            _, data = capselect:GetSelected()
        end
        local captbl = nodetbl.capab
        local add = true
        for k,v in ipairs(captbl) do
            if v == data then
                add = false
                break
            end
        end
        if add then
            captbl[#captbl+1] = data
            caplist:AddLine(data)
        end
    end

    function capdelbtn:DoClick()
        captbl = nodetbl.capab
        local changed
        for k,v in ipairs(caplist:GetSelected()) do
            local val = v:GetValue(1)
            for ik,iv in ipairs(captbl) do
                if iv == val then 
                    captbl[ik] = nil
                    changed = true
                end
            end
            caplist:RemoveLine(v:GetID())
        end
        if changed then
            local newlist = {}
            local i = 0
            for k,v in pairs(captbl) do
                i = i + 1
                newlist[i] = v
            end
            nodetbl.capab = newlist
        end
    end

    local hasoverride = istable(nodetbl.override)

    local overridecheck = UImake("DCheckBoxLabel",parent)
    overridecheck:SetDark(true)
    overridecheck:SetText("#apadventure.editor.capab.override")
    overridecheck:SetValue(hasoverride)

    local storedtbl = nodetbl.override or {}
    local condpnl = include("apadventure/ui/condpnl.lua")(parent,storedtbl,150)
    condpnl:SetExpanded(hasoverride)

    function overridecheck:OnChange(val)
        nodetbl.override = val and storedtbl or nil
    end

    local helppnl = UImake("DForm",parent)
    helppnl:SetLabel("#apadventure.editor.capab.help")
    helppnl:Help("#apadventure.editor.capab.helpbase")
    local helplink1 = helppnl:Help("#apadventure.editor.capab.helpideflink")
    helplink1:SetColor(Color(56,56,255))
    function helplink1:DoClick() gui.OpenURL("https://github.com/ChrisCj8/ap_adventure/tree/main/lua/apadventure/itemsets") end
    helplink1:SetCursor("hand")
    local helplink2 = helppnl:Help("#apadventure.editor.capab.helpimplied")
    helplink2:SetColor(Color(56,56,255))
    function helplink2:DoClick() gui.OpenURL("https://github.com/ChrisCj8/ap_adventure/blob/main/data_static/apadventure/impliedcapabilities.json") end
    helplink2:SetCursor("hand")
    helppnl:Help("#apadventure.editor.capab.helpmulti")
    helppnl:Help("#apadventure.editor.capab.helpcond")
    helppnl:Help("#apadventure.editor.capab.helpoverride")
    helppnl:Help("#apadventure.editor.capab.helpsave")

    local oldlayout = parent.PerformLayout
    function parent:PerformLayout(w,h)
        --itemnamein:SetSize(w-10,22)
        self:OldLayout(self,w,h)
        w = self:InnerWidth()
        local capabh = h-100

        capselect:SetSize(w-70,22)
        capnamein:SetSize(w-70,22)
        caplist:SetSize(w-10,capabh-35)
        capaddbtn:SetPos(w-5-16-20,7)
        capdelbtn:SetPos(w-5-16,7)

        overridecheck:SetPos(5,capabh)
        overridecheck:SetSize(w-10,22)

        condpnl:SetPos(5,capabh+22)
        condpnl:SetWidth(w-10)

        helppnl:SetPos(5,condpnl:GetTall()+capabh+27)
        helppnl:SetWidth(w-10)
    end
end

function NODE.InitNode()
    return {
        capab = {},
        type = "capab"
    }
end

return NODE