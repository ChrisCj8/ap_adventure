return function(parent,targettbl,desiredh)

desiredh = desiredh or 250

local condpnl = vgui.Create("DCollapsibleCategory",parent) 
condpnl:SetPos(5,5)
condpnl:SetLabel("#apadventure.editor.condpnl")

local condselect = vgui.Create("DComboBox",condpnl)
condselect:SetPos(5,25)

for k,v in ipairs(game.GetAmmoTypes()) do
    condselect:AddChoice("Ammo_"..v)
end

local otherconds = {
    "Props",
    "Props_Sharp",
    "Props_Explosive",
    "Antlions_Controllable"
}

for k,v in ipairs(otherconds) do
    condselect:AddChoice(v)
end

local addbtn = vgui.Create("DImageButton",condpnl)
addbtn:SetSize(16,16)
addbtn:SetImage("icon16/add.png")

local delbtn = vgui.Create("DImageButton",condpnl)
delbtn:SetSize(16,16)
delbtn:SetImage("icon16/delete.png")

local condlist = vgui.Create("DListView",condpnl)
condlist:SetPos(5,52)
condlist:AddColumn("#apadventure.editor.reg.condcol")

function addbtn:DoClick()
    local newcondtext, newconddata = condselect:GetSelected()
    local newcond = newcondtext or newconddata
    if newcond and !targettbl[newcond] then
        condlist:AddLine(newcond)
        targettbl[newcond] = true
    end
end

function delbtn:DoClick()
    for k,v in ipairs(condlist:GetSelected()) do
        local cond = v:GetValue(1)
        condlist:RemoveLine(v:GetID())
        targettbl[cond] = nil
    end
end

function condpnl:SetTargetTbl(tbl)
    targettbl = tbl
    for k,v in pairs(condlist:GetLines()) do
        condlist:RemoveLine(v:GetID())
    end
    for k,v in pairs(tbl) do
        condlist:AddLine(k)
    end
end
condpnl:SetTargetTbl(targettbl or {})

local oldlayout = condpnl.PerformLayout
function condpnl:PerformLayout(w,h)
    oldlayout(self,w,h)

    addbtn:SetPos(w-26-18,28)
    delbtn:SetPos(w-26,28)
    condselect:SetSize(w-52,22)
    condlist:SetSize(w-10,desiredh)
end

return condpnl end