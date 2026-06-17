
apAdventure.MapIconMats = apAdventure.MapIconMats or {}

timer.Create("ApAdvMapIconMatReload",2,0, function() 
    timer.Stop("ApAdvMapIconMatReload")
    for k,v in ipairs(ents.FindByClass("apadventure_exit")) do
        v:ResetIcon()
    end
end)

local rescvar = CreateClientConVar("apadventure_mapiconmat_resolution",8,true,false,
    [[What the resolution for Map Icon Materials should be, as a power of two. (8 = 256, 9 = 512, ...)
    Map Icons are rarely bigger than 512x512, so there's not much of a benefit to setting this higher than 9.
    This won't update until you load another map.]],4,12)

function apAdventure.GetMapIconMat(map,loadedcb)
    if apAdventure.MapIconMats[map] then
        if isfunction(loadedcb) then
            loadedcb(mat)
        end
    else
        local iconexists = file.Exists("maps/thumb/"..map..".png","GAME")
        local html = vgui.Create("DHTML")
        local res = 2^rescvar:GetInt()
        html:SetSize(res,res)
        local fontsize = ((res/#map)*1.5)
        local htmlcontent = [[
            <head>
                <style>
                    body {
                        background-image: url("asset://garrysmod/maps/thumb/]]..(iconexists and map or 'noicon')..[[.png");
                        background-size: cover;
                        image-rendering: pixelated;
                        overflow: hidden;
                        padding: 0;
                    }]]..(iconexists and "" or [[

                    @font-face {
                        font-family: titlefont;
                        src: url(asset://garrysmod/resource/fonts/Roboto-Medium.ttf);
                    }
                    
                    h1 {
                        font-family: titlefont;
                        position: fixed;
                        text-align: center;
                        left: 0;
                        right: 0;
                        top: ]]..(-fontsize*.5+res/2)..[[px;
                        bottom: 0;
                        margin: 0;
                        padding: 0;
                        color: white;
                        text-shadow: 0 0 ]]..(fontsize*.2)..[[px black;
                        font-size: ]]..(fontsize)..[[px;
                    }]])..[[
                </style>
            </head>
        ]]
        if !iconexists then
            htmlcontent = htmlcontent.."<body><h1>"..map.."</h1></body>"
        end
        html:SetHTML(htmlcontent)
        local olddocready = html.OnDocumentReady
        function html:OnFinishLoadingDocument()
            --print("html loaded") 
            html:UpdateHTMLTexture()
            local timername = "apadventure_mapiconmat_"..map
            timer.Create(timername,.5,0, function()
                html:UpdateHTMLTexture()
                local origmat = html:GetHTMLMaterial()
                if !origmat then print(html,origmat) return end
                local mat = CreateMaterial("apAdventure_MapIcon_"..map,"VertexLitGeneric",{
                    ["$basetexture"] = origmat:GetString("$basetexture"),
                    ["$selfillum"] = 1,
                    ["$selfillummask"] = "apadventure/models/selfillum_10",
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