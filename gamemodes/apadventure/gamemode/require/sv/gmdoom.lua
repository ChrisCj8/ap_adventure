return {
    DoCheck = function(info)
        local addoninfo = info.addons["133300986"]
        if !addoninfo or !addoninfo.mounted then
            return { 
                checkaddon = "133300986",
                msg = "noinstall",
                status = 3,
            }
        end
        local files = file.Find("*.wad","GAME")
        local haswad = files[1] != nil
        return {
            checkaddon = "133300986",
            msg = haswad and "haswad" or "nowad",
            status = !haswad and 3 or nil
        }
    end
}