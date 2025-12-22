return function(gtbl,dodelete)
    local cfgtab = {
        Saved = {},
        DelMark = {},
        DelName = {},
        Group = gname,
        Regions = {},
    }
    game.CleanUpMap()

    local newsav = cfgtab.Saved
    local presav = duplicator.Paste(nil,gtbl.sav.Entities or gtbl.sav ,gtbl.sav.Constraints or {})

    for k,v in pairs(presav) do
        newsav[v] = true
    end

    local newdel = cfgtab.DelMark
    for k,v in ipairs(gtbl.del) do
        local ent = ents.GetMapCreatedEntity(v)
        apAdventure.SendDelMark(v,ent,true)
        newdel[v] = ent
        if dodelete then
            newdel[v]:Remove()
        end
    end

    local newdelname = cfgtab.DelName
    for k,v in ipairs(gtbl.delname) do
        newdelname[v] = true
        if dodelete then
            timer.Simple(.2,function() 
                for ik,iv in ipairs(ents.FindByName(v)) do
                    iv:Remove()
                end
            end)
        end
    end

    for k,v in ipairs(gtbl.exit) do
        local ent = ents.Create("apadventure_exit_editor")
        ent:SetPos(v.pos)
        ent:SetAngles(v.ang)
        ent:SetRegion(v.reg)
        ent:SetExitName(v.name)
        ent:Spawn()
    end

    for k,v in ipairs(gtbl.entr) do
        local ent = ents.Create("apadventure_entrance_editor")
        ent:SetPos(v.pos)
        ent:SetAngles(v.ang)
        ent:SetRegion(v.reg)
        ent:SetEntrName(v.name)
        ent:Spawn()
    end

    for k,v in ipairs(gtbl.lctn) do
        local ent = ents.Create("apadventure_location_editor")
        ent:SetPos(v.pos)
        --ent:SetAngles(v.ang)
        ent:SetRegion(v.reg)
        ent:SetLctnName(v.name)
        ent:SetIsDummy(v.dummy)
        ent:Spawn()
    end

    for k,v in ipairs(gtbl.start) do
        local ent = ents.Create("apadventure_start_editor")
        ent:SetPos(v.pos)
        ent:SetAngles(v.ang)
        ent:SetRegion(v.reg)
        ent:Spawn()
    end

    apAdventure.SetCfgTbl(cfgtab)
    timer.Simple(.1,apAdventure.UpdateSaveMarks)
end