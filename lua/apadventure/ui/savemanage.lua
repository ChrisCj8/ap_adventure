return function()
    if IsValid(apAdventure.SaveManager) then return end
    local window = vgui.Create("DFrame")
    window:SetSize(450,500)
    window:Center()
    window:MakePopup()
    window:SetSizable(true)
    window:SetTitle("#apadventure.savemanage.title")

    apAdventure.SaveManager = window

    local savlist = vgui.Create("DListView",window)
    savlist:SetPos(5,30)

    local slotcol = savlist:AddColumn("#apadventure.savemanage.slot")
    slotcol:SetFixedWidth(128)

    local seedcol = savlist:AddColumn("#apadventure.savemanage.seedname")
    seedcol:SetFixedWidth(135)

    local timecol = savlist:AddColumn("#apadventure.savemanage.time")

    local delbtn = vgui.Create("DButton",window)
    delbtn:SetText("#apadventure.savemanage.del")

    function delbtn:DoClick()
        for k,v in ipairs(savlist:GetSelected()) do
            net.Start("APAdvSaveManageCmd")
                net.WriteString("del")
                net.WriteString(v.savename)
            net.SendToServer()
            savlist:RemoveLine(v:GetID())
        end
    end

    local sfind = string.find
    local ssub = string.sub

    function window:ReceiveData(data)
        local sep1pos = sfind(data,"_")
        local sep2pos = sfind(data,"_",sep1pos+1)

        local time = tonumber(ssub(data,1,sep1pos-1))
        local timestr = os.date("%c",time)
        local seed = ssub(data,sep1pos+1,sep2pos-1)
        local slot = ssub(data,sep2pos+1,-1)

        local ln = savlist:AddLine(slot,seed,timestr)
        ln.savename = data
        ln:SetSortValue(3,time)
    end

    net.Start("APAdvSaveManageCmd")
        net.WriteString("data")
    net.SendToServer()

    local oldlayout = window.PerformLayout
    function window:PerformLayout(w,h)
        oldlayout(self,w,h)

        savlist:SetSize(w-10,h-62)
        -- the delete button gets some extra padding so people don't
        -- click it by accident when adjusting the window size
        delbtn:SetSize(w-60,22)
        delbtn:SetPos(30,h-27)
    end

    return window
end