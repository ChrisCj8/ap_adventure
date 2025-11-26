
apAdventure.MapIconMats = apAdventure.MapIconMats or {}

timer.Create("ApAdvMapIconMatReload",2,0, function() 
    timer.Stop("ApAdvMapIconMatReload")
    for k,v in ipairs(ents.FindByClass("apadventure_exit")) do
        v:ResetIcon()
    end
end)

function apAdventure.GetMapIconMat(map,loadedcb)
    print(map)
    if apAdventure.MapIconMats[map] then
        --return apAdventure.MapIconMats[map].mat
        if isfunction(loadedcb) then
            loadedcb(mat)
        end
    else
        local bgstring = 'background-image: url("asset://garrysmod/maps/thumb/noicon.png");'
        if file.Exists("maps/thumb/"..map..".png","GAME") then
            bgstring = 'background-image: url("asset://garrysmod/maps/thumb/'..map..'.png");'
        end
        local html = vgui.Create("DHTML")
        html:SetSize(128,128)
        html:SetHTML([[
            <head>
                <style>
                    body {
                        ]]..bgstring..[[
                        background-size: cover;
                        overflow: hidden;
                    }
                </style>
            </head>
        ]])
        local olddocready = html.OnDocumentReady
        function html:OnFinishLoadingDocument()
            print("html loaded") 
            html:UpdateHTMLTexture()
            local timername = "apadventure_mapiconmat_"..map
            timer.Create(timername,1,0, function()
                html:UpdateHTMLTexture()
                local origmat = html:GetHTMLMaterial()
                if !origmat then print(html,origmat) return end
                local mat = CreateMaterial("apAdventure_MapIcon_"..map,"VertexLitGeneric",{
                    ["$basetexture"] = origmat:GetString("$basetexture"),
                    ["$lightwarptexture"] = "apadventure/models/frame_lightwarp"
                })

                apAdventure.MapIconMats[map] = {
                    html = html,
                    origmat = origmat,
                    mat = mat
                }
                if isfunction(loadedcb) then
                    loadedcb(mat)
                end
                timer.Start("ApAdvMapIconMatReload")
                timer.Remove(timername)
            end)
        end
        html:Hide()
        html:UpdateHTMLTexture()
    end
end

net.Receive("APAdvMapIconMat",function() 
    local map = net.ReadString()
    apAdventure.GetMapIconMat(map)
end)

print("yeah")