return {
    DoCheck = function(info)
        if !WireLib then
            return { checkaddon = "160250458" }
        elseif !file.Exists("lua/wire/wireshared.lua","WORKSHOP") then 
            return { msg = "manual", status = 1 }
        end
        local canary = info.addons["3066780663"]
        if canary and canary.mounted then
            return { checkaddon = "3066780663" }
        end
        return { checkaddon = "160250458" }
    end,
}