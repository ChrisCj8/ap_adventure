local NODE = {
    Icon = "icon16/gun.png"
}

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

    local capselectiontypebtn = vgui.Create("DImageButton",parent)
    capselectiontypebtn:SetSize(16,16)
    capselectiontypebtn:SetImage("icon16/pencil.png")
    capselectiontypebtn:SetPos(5,7)
    
    local textinputactive = false

    local capselect = vgui.Create("DComboBox",parent)
    capselect:SetPos(25,5)
    local first = true
    for k,v in ipairs(capabs) do
        capselect:AddChoice(v,v,first)
        first = false
    end

    local capnamein = vgui.Create("DTextEntry",parent)
    capnamein:SetPos(25,5)
    capnamein:SetVisible(false)

    local capaddbtn = vgui.Create("DImageButton",parent)
    capaddbtn:SetSize(16,16)
    capaddbtn:SetImage("icon16/add.png")

    local capdelbtn = vgui.Create("DImageButton",parent)
    capdelbtn:SetSize(16,16)
    capdelbtn:SetImage("icon16/delete.png")

    local caplist = vgui.Create("DListView",parent)
    caplist:SetPos(5,30)
    caplist:AddColumn("Capability")

    for k,v in ipairs(parent.nodetbl.capab) do
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
        local captbl = parent.nodetbl.capab
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
        captbl = parent.nodetbl.capab
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
            parent.nodetbl.capab = newlist
        end
    end

    function parent:PerformLayout(w,h)
        --itemnamein:SetSize(w-10,22)

        capselect:SetSize(w-70,22)
        capnamein:SetSize(w-70,22)
        caplist:SetSize(w-10,h-35)
        capaddbtn:SetPos(w-5-16-20,7)
        capdelbtn:SetPos(w-5-16,7)
    end
end

function NODE.InitNode()
    return {
        capab = {},
        type = "capab"
    }
end

return NODE