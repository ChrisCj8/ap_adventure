
APADV_TRACKER = APADV_TRACKER or {}

util.AddNetworkString("APAdvTrackerReset")
util.AddNetworkString("APAdvTrackerLocation")
util.AddNetworkString("APAdvTrackerExit")

local netstart = net.Start
local netstring = net.WriteString
local netuint = net.WriteUInt
local netsend = net.Send
local netbroadcast = net.Broadcast

local fromJSON = util.JSONToTable
local rfile = file.Read

local function trackerreset(ply)
    netstart("APAdvTrackerReset")
        netstring(APADV_MAPGROUP)
    if ply then
        netsend(ply)
    else
        netbroadcast()
    end
end

function APADV_TRACKER:SendLocationUpdate(group,map,loc,state,ply)
    netstart("APAdvTrackerLocation")
        netstring(group)
        netstring(map)
        netstring(loc)
        netuint(state,3)
    if ply then
        netsend(ply)
    else
        netbroadcast()
    end
end

function APADV_TRACKER:SendExitUpdate(group,map,name,tgtgr,tgtmap,tgtentr,ply)
    netstart("APAdvTrackerExit")
        netstring(group)
        netstring(map)
        netstring(name)
        netstring(tgtgr)
        netstring(tgtmap)
        netstring(tgtentr)
    if ply then
        netsend(ply)
    else
        netbroadcast()
    end
end

function APADV_TRACKER:UpdateLocationByName(name,state)
    if !self.locnametomap then return end
    local tomap = self.locnametomap[name]
    local gr, map, reg = tomap.g, tomap.m, tomap.r
    self.regs[gr][map][reg].locs[name].reach = state
    self:SendLocationUpdate(gr,map,name,state)
end

function APADV_TRACKER:SendTrackerData(ply)
    trackerreset(ply)
    for grn,gr in pairs(self.regs) do
        for mapn,map in pairs(gr) do
            for regn,reg in pairs(map) do
                if reg.exit then
                    for k,v in pairs(reg.exit) do
                        local tgt = v.tgt
                        self:SendExitUpdate(grn,mapn,k,tgt.group,tgt.map,tgt.entr,ply)
                    end
                end
                if reg.locs then
                    PrintTable(reg.locs)
                    for k,v in pairs(reg.locs) do
                        self:SendLocationUpdate(grn,mapn,k,v.reach,ply)
                    end
                end
            end
        end
    end
end

function APADV_TRACKER:Build()
    local starttime = SysTime()
    local slot = APADV_SLOT
    local slotdata = slot.slotData
    local slotlocs = slot.Locations
    local slotconn = slotdata.connections
    local locnametoid = APADV_DATAPACK_LOCAL.location_name_to_id

    local grouptbls = {}
    local regs = {}
    local mapitems = {}
    local entrs = {}
    local locnametomap = {}

    trackerreset()

    local function buildmaptracker(groupn,mapn)
        --print("building tracker table for "..mapn.." in "..groupn)
        local maptbl = {}

        local gtbl = grouptbls[groupn]

        if !gtbl then
            gtbl = fromJSON(rfile("apadventure/cfg/"..groupn.."/group.json","DATA"))
            grouptbls[groupn] = gtbl
        end

        local path = "apadventure/cfg/"..groupn.."/"..mapn.."/sv.json"
        local json = assert(rfile(path,"DATA"),"couldn't find config for map "..mapn.." in group "..groupn)
        local svcfg = fromJSON(json)
        path = "apadventure/cfg/"..groupn.."/"..mapn.."/cl.json"
        json = assert(rfile(path,"DATA"),"couldn't find config for map "..mapn.." in group "..groupn)
        local clcfg = fromJSON(json)

        local locsbyreg = {}
        local locacc = svcfg.lctnaccess or {}
        local locpre = groupn.." - "..mapn.." - "
        

        --PrintTable(svcfg.lctn)

        for k,v in pairs(svcfg.lctn) do
            local locn = locpre..v.name
            local locid = locnametoid[locn]
            --print(locn,locid,slotlocs[locid])
            if slotlocs[locid] != nil then

                local reach = slotlocs[locid] and 0 or 3
                local loc = {
                    reach = reach,
                    acc = locacc[locn]
                }
                
                local reg = v.reg

                if locsbyreg[reg] then
                    locsbyreg[reg][locn] = loc
                else
                    locsbyreg[reg] = {
                        [locn] = loc
                    }
                end

                locnametomap[locn] = {
                    m = mapn,
                    g = groupn,
                    r = reg,
                }

                self:SendLocationUpdate(groupn,mapn,locn,reach)
            end
        end

        --[[ if clcfg.item then
            local items = {}
            for k,v in pairs(clcfg.item) do
                
            end
        end ]]

        local conntbl = {}

        if clcfg.connect then
            for k,v in pairs(clcfg.connect) do
                conntbl[k] = conntbl[k] or {}
                for ik,iv in pairs(v) do
                    conntbl[k][ik] = iv.access or {}
                    if iv.twoway then
                        conntbl[ik] = conntbl[ik] or {}
                        conntbl[ik][k] = iv.access or {}
                    end
                end
            end
        end

        local exittbl = {}

        --print(groupn,mapn)
        local groupconndata = slotconn[groupn]
        if groupconndata then
            local conndata = groupconndata[mapn]

            if conndata then
                local exitacc = svcfg.exitaccess or {}

                for k,v in pairs(svcfg.exit) do
                    local regn = v.reg
                    exittbl[regn] = exittbl[regn] or {}
                    local regexits = exittbl[regn]
                    
                    local exitn = v.name
                    local exitdata = conndata[exitn]
                    if exitdata and !regexits[exitn] then
                        regexits[exitn] = {
                            tgt = exitdata,
                            acc = exitacc[exitn],
                        }
                        self:SendExitUpdate(groupn,mapn,regn,exitdata.group,exitdata.map,exitdata.entr)
                    end
                end
            end
        end

        local entrtbl = {}
        local entracc = svcfg.entraccess or {}

        for k,v in pairs(svcfg.entr) do
            local entrn = v.name
            if !entrtbl[entrn] then
                entrtbl[entrn] = {
                    reg = v.reg,
                    acc = entracc[entrn] or {}
                }
            end
        end

        entrs[groupn] = entrs[groupn] or {}
        entrs[groupn][mapn] = entrtbl

        local mapregs = {}

        for k,v in pairs(clcfg.reg) do
            local reg = {
                cond = v.ammo,
                locs = locsbyreg[k],
                conn = conntbl[k],
                exit = exittbl[k],
                reach = 3
            }

            mapregs[k] = reg
        end

        return {
            reg = mapregs,
            entr = entrtbl,
        }

    end

    local startgroup = slotdata.startgroup
    local startmap = buildmaptracker(slotdata.startgroup,slotdata.startmap)
    startmap.reg[slotdata.startregion].reach = 1

    regs[startgroup] = {[slotdata.startmap] = startmap.reg}

    local function processconnected(curregs)
        for k,v in pairs(curregs) do
            if v.exit then
                for ik,iv in pairs(v.exit) do
                    local tgt = iv.tgt
                    if tgt then
                        local tgtgr = tgt.group
                        local tgtmap = tgt.map
                        regs[tgtgr] = regs[tgtgr] or {}
                        if !regs[tgtgr][tgtmap] then
                            local map = buildmaptracker(tgtgr,tgtmap)
                            local mapregs = map.reg
                            regs[tgtgr] = regs[tgtgr] or {}
                            regs[tgtgr][tgtmap] = mapregs
                            processconnected(mapregs)
                        end
                    end
                end
            end
        end
    end

    processconnected(startmap.reg)

    self.regs = regs
    self.entr = entrs
    self.query = {
        {
            gr = slotdata.startgroup,
            map = slotdata.startmap,
            reg = slotdata.startregion
        }
    }
    
    self.locnametomap = locnametomap
    self.built = true

    self:Query()

    print("built tracking table in "..tostring(SysTime()-starttime).." seconds")
end

local min = math.min
local max = math.max

local function resort(tbl)
    local out = {}
    local i = 0
    for k,v in pairs(tbl) do
        i = i+1
        out[i] = v
    end
end

local evalmeta = {__index = function()
    return function()
        return 3,3
    end
end}

function APADV_TRACKER:Query()
    local slot = APADV_SLOT
    local slotdata = slot.slotData
    local slotitems = slot.Items
    local slotlocs = slot.Locations
    local inametoid = APADV_DATAPACK_LOCAL.item_name_to_id
    local locnametoid = APADV_DATAPACK_LOCAL.location_name_to_id
    local newquery = {}
    local newqueries = 0
    local regtbl = APADV_TRACKER.regs
    local locquery = {}
    local locqueries = 0
    local entrs = APADV_TRACKER.entr
    local id2capab = APADV.id2capab
    local capabtbl = APADV.capabtbl
    local condcapabtbl = APADV.condcapabtbl

    local function evalrule(rule,conds,map,group)
        local nodeeval
        nodeeval = {
            ["or"] = function(node)
                local out = node.min or 8
                local sub = node.nodes
                local doresort
                if !sub[1] then return 3 end
                for k,v in ipairs(node.nodes) do
                    --print("testing type",v.type)
                    local subout, override = nodeeval[v.type](v)
                    if subout == 1 then return 1,1 end
                    if override then
                        if isnumber(override) then
                            sub[k] = nil
                            node.min = !node.min and override or min(node.min,override)
                            doresort = true
                        else
                            sub[k] = override
                        end
                    end
                    --print(out,subout)
                    min(out,subout)
                end
                if doresort then
                    if !next(sub) then return out,out end
                    node.nodes = resort(sub)
                end
                return out
            end,
            ["and"] = function(node)
                local out = node.min or 1
                local sub = node.nodes
                local doresort
                if !sub[1] then return out,out end
                for k,v in ipairs(node.nodes) do
                    local subout, override = nodeeval[v.type](v)
                    max(out,subout)
                    if override then
                        if override == 3 then return 3,3 end
                        if isnumber(override) then
                            sub[k] = nil
                            node.min = !node.min and override or min(node.min,override)
                            doresort = true
                        else
                            sub[k] = override
                        end
                    end
                end
                if doresort then
                    if !next(sub) then return out,out end
                    node.nodes = resort(sub)
                end
                if out == 1 then return 1,1 end
                return out
            end,
            ["fix"] = function(node)
                return node.val
            end,
            ["bhop"] = function(node)
                local bhop = APADV_SLOT.slotData.bhop
                if bhop == 2 then return APADV_BHOP and 1,1 or 3 end
                if bhop == 3 then return 1,1 else return 3,3 end
            end,
            ["has"] = function(node)
                local ilist = slotitems[node.id]
                if !ilist then return 3 end
                if #ilist >= node.amt then return 1,1 end
                return 3
            end,
            ["mapitem"] = function(node)
                local id = inametoid[group.." - "..map.." - "..node.item]
                if !id then return 3,3 end
                local newnode = {
                    type = "has",
                    id = id,
                    amt = node.count,
                }
                local eval = nodeeval["has"](newnode)
                if eval == 1 then return 1,1 end
                return eval, newnode
            end,
            ["capab"] = function(node)
                local capabs = node.capab
                local first = capabs[1]
                if !first then return 1,1 end

                local function checkitem(id)
                    local itemtbl = id2capab[id]
                    local itemcap = itemtbl.cap
                    local itemcond = itemtbl.cond
                    for k,v in ipairs(capabs) do
                        if !itemcap or !itemcap[v] then
                            if !itemcond then return false end
                            local missing = true
                            for ik,iv in pairs(itemcond) do
                                if iv[k] then
                                    missing = false
                                    break
                                end
                            end
                            if missing then return false end
                        end
                    end
                    return true
                end

                local candidates = capabtbl[first]
                --print("candidates for the first capability",first)
                if candidates then
                    --PrintTable(candidates)
                    for k,v in ipairs(candidates) do
                        --print(slotitems[v])
                        --print(checkitem(v))
                        if slotitems[v] and checkitem(v) then return 1,1 end
                    end
                end

                for k,v in ipairs(conds) do
                    local condtbl = condcapabtbl[v]
                    if condtbl then
                        local candidates = condtbl[v]
                        if candidates then
                            for ik,iv in ipairs(candidates) do
                                if slotitems[v] and checkitem(v) then return 1,1 end
                            end
                        end
                    end
                end
                return 3
            end
        }
        setmetatable(nodeeval,evalmeta)
        --print("evaluating rule:")
        --PrintTable(rule)
        return nodeeval[rule.type](rule)
    end

    local function queryregion(group,map,regn)
        local mapregs = regtbl[group][map]
        local reg = mapregs[regn]
        local basereach = reg.reach
        local requery

        if reg.locs then
            for ik,iv in pairs(reg.locs) do
                if iv.reach > basereach then
                    local reach
                    if slotlocs[locnametoid[ik]] then
                        reach = 0
                    else
                        if istable(iv.acc) then
                            local out, override = evalrule(iv.acc,reg.cond,map,group)
                            reach = max(out,basereach)
                            if override then
                                iv.acc = override
                            end
                        else
                            reach = iv.acc or basereach
                        end
                    end
                    iv.reach = reach
                    self:SendLocationUpdate(group,map,ik,reach)
                end
            end
        end

        local conntbl = reg.conn
        if conntbl then
            for ik,iv in pairs(conntbl) do
                local tgtreg = mapregs[ik]
                if tgtreg.reach > basereach then
                    if !next(iv) then
                        tgtreg.reach = basereach
                        queryregion(group,map,ik)
                    else
                        local out, override = evalrule(iv,reg.cond,map,group)
                        tgtreg.reach = out
                        if override then
                            conntbl[ik] = !isnumber(override) and override or nil
                        elseif out == 1 then
                            conntbl[ik] = nil
                        end
                        if out > 1 then
                            requery = true
                        end
                        if out < 3 then
                            queryregion(group,map,ik)
                        end
                    end
                end
            end
        end

        local exittbl = reg.exit

        if exittbl then
            for ik,iv in pairs(exittbl) do
                local tgt = iv.tgt
                local tgtgr = tgt.group
                local tgtmap = tgt.map
                local tgtentr = entrs[tgtgr][tgtmap][tgt.entr]
                local tgtregn = tgtentr.reg
                local tgtreg = regtbl[tgtgr][tgtmap][tgtregn]
                if tgtreg.reach > basereach then
                    
                    local reachinner, override

                    if !iv.acc or !next(iv.acc) then
                        reachinner = 1
                    else
                        reachinner, override = evalrule(iv.acc,reg.cond,map,group)
                    end

                    if override then
                        if isnumber(override) then
                            if override > 2 then
                                exittbl[ik] = nil
                            else
                                iv.acc = nil
                            end
                        else
                            iv.acc = override
                        end
                    end

                    if reachinner < 3 then
                        local reachouter

                        if !tgtentr.acc or !next(tgtentr.acc) then
                            reachouter = 1
                        else
                            reachouter, override = evalrule(tgtentr.acc,tgtreg.cond,tgtmap,tgtgr)
                        end

                        if override then
                            if isnumber(override) then
                                if override > 2 then
                                    exittbl[ik] = nil
                                else
                                    tgtentr.acc = nil
                                end
                            else
                                tgtentr.acc = override
                            end
                        end

                        local finalreach = max(reachinner,reachouter,basereach)

                        tgtreg.reach = min(finalreach,tgtreg.reach)

                        if finalreach < 3 then
                            queryregion(tgtgr,tgtmap,tgtregn)
                        end

                        if finalreach > 1 then
                            requery = true
                        end
                    end
                end
            end

            if !next(exittbl) then reg.exit = nil end
        end

        if requery then
            newqueries = newqueries + 1
            newquery[newqueries] = {
                gr = group,
                map = map,
                reg = regn
            }
        end

    end

    for k,v in ipairs(self.query) do
        queryregion(v.gr,v.map,v.reg)
    end

    self.query = newquery
end

function APADV_TRACKER:SaveToFile(path)
    file.Write(path,util.TableToJSON{
        entr = self.entr,
        regs = self.regs,
        query = self.query,
        locnametomap = self.locnametomap,
    })
end

function APADV_TRACKER:LoadFromTable(data)
    self.entr = data.entr
    self.regs = data.regs
    self.query = data.query
    self.locnametomap = data.locnametomap
    self.built = true
end