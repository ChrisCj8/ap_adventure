local settings = {
    {
        name = "walkspd",
        type = "numwpreset",
        preset = "speed",
        default = 100,
        min = 10
    },
    {
        name = "runspd",
        type = "numwpreset",
        preset = "speed",
        default = 200,
        min = 10
    },
    {
        name = "sprintspd",
        type = "numwpreset",
        preset = "speed",
        default = 400,
        min = 10
    },
    {
        name = "jump",
        type = "numwpreset",
        default = 200,
        min = 10
    },
    {
        name = "grav",
        type = "numwpreset",
        default = 600,
        min = 10
    },
    {
        name = "frctn",
        type = "numwpreset",
        default = 8,
        min = 1
    },
    {
        name = "accel",
        type = "numwpreset",
        default = 10,
        min = 1
    },
    {
        name = "airaccel",
        type = "numwpreset",
        default = 10,
        min = 10
    },
    {
        name = "stopspd",
        type = "numwpreset",
        default = 10,
        min = 10
    },
    {
        name = "hev",
        type = "check"
    },
}

if CLIENT then
    local needpreset = {
        numwpreset = true
    }

    local loadedtbls = {}

    for k,v in ipairs(settings) do
        if needpreset[v.type] then
            local preset = v.preset or v.name
            local presettbl = loadedtbls[preset]
            if presettbl then
                v.presets = presettbl
                v.preset = nil
            else
                local presetfile = "apadventure/ui/settingpreset/"..preset..".lua"
                if file.Exists(presetfile,"lcl") then
                    v.presets = include(presetfile)
                    v.preset = nil
                end
            end
        end
    end
    apAdventure.CfgSettings = settings
else
    local processed = {}
    for k,v in ipairs(settings) do
        processed[v.name] = {
            default = v.default
        }
    end
    apAdventure.CfgSettings = processed
end