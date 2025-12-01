local function Label(parent,text)
    local lbl = vgui.Create("DLabel",parent)
    lbl:SetText(text)
    lbl:SetDark(true)
    return lbl
end


return function(window)
    window:SetSizable(true)
    
    local background = vgui.Create("DPanel",window)
    background:Dock(FILL)

    local adrlbl = Label(background,"#apadventure.connect.address")
    adrlbl:SetPos(5,5)
    local adrin = vgui.Create("DTextEntry",background)
    adrin:SetPos(90,5)
    adrin:SetPlaceholderText("ws://localhost:38281")

    local namelbl = Label(background,"#apadventure.connect.slotname")
    namelbl:SetPos(5,35)
    local namein = vgui.Create("DTextEntry",background)
    namein:SetPos(90,35)

    local pwlbl = Label(background,"#apadventure.connect.password")
    pwlbl:SetPos(5,65)
    local pwin = vgui.Create("DTextEntry",background)
    pwin:SetPos(90,65)
    pwin:SetTextHidden(true)

    local sendbtn = vgui.Create("DButton",background)
    sendbtn:SetPos(5,95)
    sendbtn:SetText("#apadventure.connect.connect")
    function sendbtn:DoClick()
        net.Start("apAdvConnectionInfo")
            net.WriteString(adrin:GetValue())
            net.WriteString(namein:GetValue())
            net.WriteString(pwin:GetValue())
        net.SendToServer()
    end

    function background:PerformLayout(w,h)
        adrin:SetSize(w-95,22)
        namein:SetSize(w-95,22)
        pwin:SetSize(w-95,22)
        sendbtn:SetSize(w-10,22)
    end
end