import typing
import json
import os
from worlds.AutoWorld import World
from BaseClasses import Item, ItemClassification, Region, Location, CollectionState
from Options import OptionError
from .Settings import GMADVSettings
from .Options import GMADVGameOptions
from .JsonRule import eval_json_rule, preprocess_json_rule
from settings import get_settings
from entrance_rando import randomize_entrances
from .ImpliedCapabilities import ProcessCapabs
#from .CfgProcessor import item_set_table, item_name_to_id, base_item_table, duplicate_item_names, map_table
from .CfgProcessor import ProcessCfgs

class GMADVItem(Item):
    game = "GMod - apAdventure"

class GMADVLocation(Location):
    game = "GMod - apAdventure"

class CapabTblEntry:
    def __init__(self,name,capabs):
        self.name = name
        self.capabilities = set(capabs)

class connectiongroup:
    def __init__(self,members,entr,exit,twoway):
        self.members = members
        self.entr = entr
        self.exit = exit
        self.twoway = twoway
        self.just_connected = False

class SetItem:
    def __init__(self,id,name,idef):
        self.id = id
        self.name = name
        self.info = idef

class StartRegion:
    def __init__(self,region,map,regname):
        self.region = region
        self.map = map
        self.regname = regname

class GMADVItemSet:
    def __init__(self,name,nicename):
        self.name = name
        self.nicename = nicename
        self.items = list()

class GMADVMap:
    def __init__(self,bspname,group):
        self.bspname = bspname
        self.group = group
        self.regions = dict()
        self.entrances = dict()
        self.exits = dict()
        self.internalConnections = dict()
        self.items = dict()
        self.info = dict()

def reachtest(canreach: set,checked: set):
    done = True
    newreach = canreach.copy()
    for reg in canreach:
        if not reg in checked:
            done = False
            for exit in reg.exits:
                newreach.add(exit.connected_region)
            checked.add(reg)
    if done:
        return newreach
    else:
        return reachtest(newreach,checked)
    
def test_accessibility(canaccess: set,checked: set):
    done = True
    newaccess = canaccess.copy()
    for reg in canaccess:
        if not reg in checked:
            done = False
            if reg.has_entr:
                return True
            for entr in reg.entrances:
                newaccess.add(entr.parent_region)
            checked.add(reg)
    if done:
        return False
    else:
        return test_accessibility(newaccess,checked)


class GMADVWorld(World):
    """\"I wish someone would make a mod.\"
    
    Garry:"""

    game = "GMod - apAdventure"

    processout = ProcessCfgs()

    # i hate this

    item_set_table = processout[0]
    item_name_to_id = processout[1]
    base_item_table = processout[2]
    duplicate_item_names = processout[3]
    map_table = processout[4]
    location_name_to_id = processout[5]

    locs = int(0)
    itemtypes = int(1)

    registereditemsets = dict()

    settings: typing.ClassVar[GMADVSettings]
    options_dataclass = GMADVGameOptions
    options: GMADVGameOptions

    def __init__(self, multiworld, player):
        super().__init__(multiworld, player)
        self.maps = dict()
        self.fillers = dict()
        self.filleramt = 0
        self.locallocs = 0
        self.loadeditemsets = list()
        self.capabilitytbl = dict()
        self.condcapabtbl = dict()
        self.warnings = list()
        self.connectiongroups = set()
        self.entranceinfo = list()
        self.rando_entrances = dict()
        self.item_table = self.base_item_table.copy()
        self.usedcapabs = set()
        self.usedcapabs_known = False
        self.regconds = set()
        self.regconds_known = False
        self.items_to_reflag = list()
        
    def add_warning(self,warning):
        self.warnings.append(warning)
        print(warning)
        if self.dodebug:
            self.debuginfo.append(warning) 


    def debuglog(self,debug: str):
        if self.dodebug:
            self.debuginfo.append(debug)
            print(debug)

    def get_item_flags(self,name):
        if not name in self.item_table:
            return None
        data = self.item_table[name]
        flags = data[1]
        info = data[2]
        if flags == None:
            if info:
                flags = ItemClassification.filler
                if self.usedcapabs_known:
                    if "capab" in info:
                        capab = info["capab"]
                        if self.usedcapabs.intersection(capab):
                            flags = ItemClassification.progression
                        else:
                            flags = ItemClassification.useful
                    if not flags == ItemClassification.progression and "condcapab" in info:
                        if not self.regconds_known:
                            return None
                        flags = ItemClassification.useful
                        condcapab = info["condcapab"]
                        for k,v in condcapab.items():
                            if k in self.regconds and self.usedcapabs.intersection(v):
                                flags = ItemClassification.progression
                                break                        
                else:
                    return None
            else:
                match data[0]:
                    case "Bunnyhop":
                        if self.bhop_logic:
                            flags = ItemClassification.progression
                        else:
                            flags = ItemClassification.useful
        return flags
    
    def create_item(self, name):
        flags = self.get_item_flags(name)
        reflag = False
        if flags == None:
            flags = ItemClassification.progression
            reflag = True
        item = GMADVItem(name, flags, self.item_name_to_id[name], self.player)
        if reflag:
            self.items_to_reflag.append(item)
        self.debuglog(f"created item {name} with flags {flags}")
        return item

    def get_filler_item_name(self):
        if self.filleramt == 0:
            return "Nothing"
        else:
            return self.random.choices(list(self.fillers.keys()),self.fillers.values())[0] # took this from ahit, seems like it'd be kinda slow but what do i know
    
    def generate_early(self):

        options = self.options

        if options.write_debug:
            self.dodebug = True
            self.debuginfo = list()
        else:
            self.dodebug = False

        self.bhop = options.bhop

        if self.bhop ==  1:
            self.bhop_logic = False
        else:
            self.bhop_logic = options.bhop_logic

        maps = dict()
        maptbl = self.map_table

        for group in options.config_groups:
            if group in maptbl:
                maps[group] = maptbl[group]
            else:
                self.add_warning(f"config_groups tried to add group {group}, which does not exist")

        for pickgroup, pickmaps in options.config_cherrypick.items():
            if pickgroup in maps:
                continue
            newmaps = dict()
            mapgroup = maptbl[pickgroup]

            for map in pickmaps:
                if map in mapgroup:
                    newmaps[map] = mapgroup[map]
                else:
                    self.add_warning(f"config_cherrypick tried to add map {map}, which was not present in group {pickgroup}")

            maps[pickgroup] = newmaps

        for blgroup, blmaps in options.config_blacklist.items():
            if not blgroup in maps:
                continue
            delgroup = maps[blgroup]

            for map in blmaps:
                if map in delgroup:
                    del delgroup[map]
                else:
                    self.add_warning(f"config_blacklist tried to remove map {map}, which was not present in group {blgroup}")

        emptygroups = list()

        for k,v in maps.items():
            if not v:
                emptygroups.append(k)
        
        for k in emptygroups:
            del maps[k]

        if not maps:
            raise OptionError(f"Slot {self.player_name} did not have any valid maps selected in their Options.")

        self.chosen_maps = maps

        chosenisets = options.item_sets

        items_to_load = dict()
        items_dontload = dict()
        item_blacklist = options.item_blacklist
        duplicate_item_names = set()

        itempool = dict()

        def register_item(item):
            name = item.name
            if name in self.duplicate_item_names:
                duplicate_item_names.add(name)
            name = item.long_name # move this into the last if condition when implementing short item names

            self.item_table[name] = (self.item_name_to_id[name],None,item.info)

            if "wgt" in item.info:
                self.fillers[name] = item.info["wgt"]
                self.filleramt += 1
            if "min" in item.info and item.info["min"] > 0:
                itempool[name] = item.info["min"]
            if "capab" in item.info:
                finalcapabs = ProcessCapabs(set(item.info["capab"]))
                item.info["capab"] = finalcapabs
                capabentry = CapabTblEntry(name,finalcapabs)
                for capab in finalcapabs:
                    if not capab in self.capabilitytbl:
                        self.capabilitytbl[capab] = list()
                    
                    self.capabilitytbl[capab].append(capabentry)
            if "condcapab" in item.info:
                for cond,capabs in item.info["condcapab"].items():
                    if not cond in self.condcapabtbl:
                        self.condcapabtbl[cond] = dict()
                    capabs = ProcessCapabs(set(capabs))
                    item.info["condcapab"][cond] = capabs
                    self.condcapabtbl[cond][name] = capabs

        for isetname in chosenisets:
            if isetname in self.item_set_table:        
                iset = self.item_set_table[isetname]
                isetitems = iset.items
                blacklist = False
                if isetname in item_blacklist:
                    blacklist = item_blacklist[isetname]
                for iname,item in isetitems.items():
                    if blacklist and iname in blacklist:
                        if not isetname in items_dontload:
                            items_dontload[isetname] = set()
                        items_dontload[isetname].add(item.info["file"])
                        continue
                    register_item(item)
                self.loadeditemsets.append(isetname)
            else:
                self.add_warning(f"itemset {isetname} could not be loaded")

        for isetname,picks in options.item_cherrypick.items():
            if not picks or isetname in chosenisets:
                continue
            if isetname in self.item_set_table:
                iset = self.item_set_table[isetname]
                load = set()
                for iname in picks:
                    if iname in iset.items:
                        item = iset.items[iname]
                        register_item(item)
                        load.add(item.info["file"])
                if load:
                    items_to_load[isetname] = load
            else:
                self.add_warning(f"itemset {isetname} could not be loaded")

        self.items_to_create = itempool
        self.items_dontload = items_dontload
        self.items_to_load = items_to_load

        ammomergeopt = list()
        
        for v in options.ammo_merge:
            ammomergeopt.append(set(v))

        unfinished = True
        while unfinished:
            unfinished = False
            for v in ammomergeopt:
                iunfinished = False
                for iv in ammomergeopt:
                    if v != iv and v.intersection(iv):
                        v.update(iv)
                        ammomergeopt.remove(iv)
                        iunfinished = True
                        break
                if iunfinished:
                    unfinished = True
                    break
        
        self.debuglog(f"processed ammo merge options: {ammomergeopt}")

        ammomergedict = dict()

        for v in ammomergeopt:
            for iv in v:
                entry = v.copy()
                entry.remove(iv)
                ammomergedict[iv] = entry

        self.debuglog(f"ammo merge dictionary: {ammomergedict}")

        self.ammomerge_out = ammomergedict

        ammomerge_int = dict()

        for k,v in ammomergedict.items():
            newset = set()
            for iv in v:
                newset.add("Ammo_"+iv)
            ammomerge_int["Ammo_"+k] = newset

        self.ammomerge = ammomerge_int

                    

    def create_regions(self):
        menu = Region("Menu",self.player,self.multiworld)
        self.multiworld.regions.append(menu)
        self.menuregion = menu

        self.debuglog(f"creating regions for {self.player_name}")
        startcandidates = list()

        ammomerge = self.ammomerge

        mapitems = dict()
        entrs = dict()

        maps = self.chosen_maps

        for groupname,groupmaps in maps.items():

            if not groupname in self.map_table:
                self.add_warning(f"map group {groupname} does not exist")
                continue

            for mapname,map in groupmaps.items():
                self.debuglog(f"processing regions for {mapname} in {groupname}")
                mapregs = dict()
                
                for k,v in map.regions.items():
                    newreg = Region(f"{map.group} - {map.bspname} - {k}",self.player,self.multiworld)
                    newreg.locdata = v["lctns"]
                    newreg.priotize_entrances = False
                    if "prioentr" in v:
                        newreg.priotize_entrances = True
                    newreg.mapname = map.bspname
                    newreg.mapgroup = map.group
                    newreg.has_entr = False
                    newreg.has_exit = False
                    newreg.onewayins = dict()
                    newreg.onewayouts = dict()
                    newreg.twoways = dict()
                    if "cond" in v:
                        conds = set()
                        for iv in v["cond"]:
                            conds.add(iv)
                            if iv in ammomerge:
                                conds.update(ammomerge[iv])
                        newreg.conditions = conds


                    mapregs[k] = newreg

                    if "startcandidate" in v:
                        self.debuglog(f"{k} is a starting candidate")
                        startcandidates.append(StartRegion(newreg,map,k))

                    self.debuglog("creating region "+map.bspname+" - "+ k)

                for k,v in map.entrances.items():
                    reg = mapregs[v["reg"]]
                    access = None
                    if "access" in v:
                        access = preprocess_json_rule(v["access"],self,reg)
                        acctype = access["type"]
                        if acctype == "never":
                            continue
                        elif acctype == "always":
                            access = None
                    reg.has_entr = True
                    name = reg.name+" - "+k
                    entrdata = (reg,access)
                    entrs[name] = entrdata
                    reg.onewayins[name] = entrdata
                    self.debuglog("adding entrace "+k+" to "+v["reg"])

                for k,v in map.exits.items():
                    reg = mapregs[v["reg"]]
                    access = None
                    if "access" in v:
                        access = preprocess_json_rule(v["access"],self,reg)
                        acctype = access["type"]
                        if acctype == "never":
                            continue
                        elif acctype == "always":
                            access = None
                    reg.has_exit = True
                    name = reg.name+" - "+k
                    if name in reg.onewayins:
                        newdata = (reg,reg.onewayins[name][1],access)
                        reg.twoways[name] = newdata
                        entrs[name] = newdata
                        del reg.onewayins[name]
                    else:
                        reg.onewayouts[name] = (reg,access)

                for k,v in map.internalConnections.items():
                    if not k in mapregs:
                        self.add_warning(f"{map.bspname} in {map.group} tried to make an internal connection to non-existing region \"{k}\"")
                        continue
                    for ik, iv in v.items():
                        if not ik in mapregs:
                            self.add_warning(f"{map.bspname} in {map.group} tried to make an internal connection to non-existing region \"{ik}\"")
                            continue
                        
                        reg_a = mapregs[k]
                        reg_b = mapregs[ik]
                        rule_a = None
                        rule_b = None
                        if "access" in iv:
                            #self.debuglog(f"preprocessing access rule: {str(iv["access"])}")
                            acctbl = preprocess_json_rule(iv["access"],self,reg_a)
                            #self.debuglog(f"processed access rule: {str(acctbl)}")
                            acctype = acctbl["type"]
                            if acctype == "never":
                                rule_a = False
                                self.add_warning(f"access rule between {ik} and {k} can never be fullfilled with current options and was removed")
                            elif acctype != "always":
                                rule_a = lambda state, acctbl=acctbl, world=self, region=reg_a: eval_json_rule(acctbl,state,world,region)
                                self.debuglog(f"registering access rule for {ik} and {k}" )
                            if iv["twoway"]:
                                #self.debuglog(f"preprocessing access rule: {str(iv["access"])}")
                                acctbl = preprocess_json_rule(iv["access"],self,reg_b)
                                #self.debuglog(f"processed access rule: {str(acctbl)}")
                                acctype = acctbl["type"]
                                if acctype == "never":
                                    rule_b = False
                                    self.add_warning(f"access rule between {k} and {ik} can never be fullfilled with current options and was removed")
                                elif acctype != "always":
                                    rule_b = lambda state, acctbl=acctbl, world=self, region=reg_b: eval_json_rule(acctbl,state,world,region)
                                    self.debuglog(f"registering access rule for {k} and {ik}" )
                            else:
                                rule_b = False
                        elif not iv["twoway"]:
                            rule_b = False
                        
                        if rule_a != False:
                            reg_a.connect(reg_b,f"{map.bspname} - {k} -> {ik}",rule_a)
                        if rule_b != False:
                            reg_b.connect(reg_a,f"{map.bspname} - {ik} -> {k}",rule_b)

                for k,v in mapregs.items():
                    if test_accessibility({v},set()):
                        reglocs = list()
                        for ik,iv in v.locdata.items():
                            newlocname = f"{map.group} - {map.bspname} - {ik}"
                            newloc = GMADVLocation(self.player,newlocname,self.location_name_to_id[newlocname],v)
                            if iv and iv["access"]:
                                acctbl = preprocess_json_rule(iv["access"],self,v)
                                acctype = acctbl["type"]
                                if acctype == "never":
                                    continue
                                elif acctype != "always":
                                    newloc.access_rule = lambda state, acctbl=acctbl, world=self, region=v: eval_json_rule(acctbl,state,world,region)
                            reglocs.append(newloc)
                            self.locallocs += 1
                        v.locations = reglocs
                        self.multiworld.regions.append(v)
                        self.regconds.update(v.conditions)
                    else:
                        self.add_warning(f"Region {v.name} was removed because it was impossible to reach")

                for k,v in map.items.items():
                    mapitems[f"{groupname} - {mapname} - {k}"] = v

        if not startcandidates:
            raise RuntimeError(self.player_name+" had no configs with valid starting regions selected")

        self.startingcandidates = startcandidates

        self.map_items = mapitems
        self.rando_entrances = entrs
        self.usedcapabs_known = True
        self.regconds_known = True

    def create_items(self):

        itempool = [self.create_item("McGuffin")]
        item_table = self.item_table
        fillers = list[GMADVItem]()
        usefuls = list[GMADVItem]()

        if self.bhop == 2:
            bhop = self.create_item("Bunnyhop")
            itempool.append(bhop)
            if not self.bhop_logic:
                usefuls.append(bhop)
                

        for iname,info in self.map_items.items():
            item_table[iname] = (self.item_name_to_id[iname],ItemClassification(info["fl"]),None)
            i = 0
            while i < info["amt"]:
                itempool.append(self.create_item(iname))
                i += 1

        for iname,amt in self.items_to_create.items():
            info =  item_table[iname][2]
            if "req_cond" in info:
                if not "condcapab" in info:
                    self.add_warning(f"item {iname} requires conditions to be fulfilled in order to be placed, but has no conditional capabilities defined")
                    continue
                req = False
                for cap in info["condcapab"].keys():
                    if cap in self.regconds:
                        req = True
                        break
                if not req:
                    continue
                
            i = 0
            while i < amt:
                newitem = self.create_item(iname)
                itempool.append(newitem)
                i += 1
                flags = newitem.classification
                if flags & ItemClassification.progression == 0:
                    if flags & ItemClassification.useful == 0:
                        fillers.append(newitem)
                    else:
                        usefuls.append(newitem)

        poolsize = len(itempool)
        rand = self.random

        if poolsize < self.locallocs:
            missingitems = self.locallocs - poolsize
            while missingitems > 0:
                itempool.append(self.create_item(self.get_filler_item_name()))
                missingitems -= 1

        elif poolsize > self.locallocs:
            overflow = poolsize - self.locallocs

            filleramt = len(fillers)
            while fillers and overflow > 0:
                itempool.remove(fillers.pop(rand.randint(0,filleramt-1)))
                filleramt -= 1
                overflow -= 1
            
            usefulamt = len(usefuls)
            while usefuls and overflow > 0:
                itempool.remove(usefuls.pop(rand.randint(0,usefulamt-1)))
                usefulamt -= 1
                overflow -= 1
            
            if overflow != 0:
                raise RuntimeError(f"{self.player_name} had {overflow} more items than locations which could not be removed")

        for v in self.items_to_reflag:
            oldflag = v.classification
            v.classification = self.get_item_flags(v.name)
            self.debuglog(f"update flags for {v.name} from {oldflag} to {v.classification}")

        self.multiworld.itempool.extend(itempool)

    def make_intermap_rule(self,entr_reg,entr_acctbl,exit_reg,exit_acctbl):
        if entr_acctbl != None:
            if exit_acctbl == None:
                return lambda state, acctbl=entr_acctbl, world=self, region=entr_reg: eval_json_rule(acctbl,state,world,region)
            else:
                return lambda state, acc_a=entr_acctbl, acc_b=exit_acctbl, world=self, reg_a=entr_reg, reg_b=exit_reg: \
                    eval_json_rule(acc_a,state,world,reg_a) and eval_json_rule(acc_b,state,world,reg_b)
        elif exit_acctbl != None:
            return lambda state, acctbl=exit_acctbl, world=self, region=exit_reg: eval_json_rule(acctbl,state,world,region)
        return None

    def connect_entrances(self):

        rand = self.random

        #unplacedconnectiongroups = self.connectiongroups.copy()
        entrs = self.rando_entrances
        unplacedentrs = entrs.copy()
        unconnectedtwoways = dict()
        unconnectedexits = dict()
        unconnectedentrs = dict()
        connectedtwoways = set()
        connectedexits = set()

        available_exits = 0 

        startcandidates = self.startingcandidates
        menu = self.menuregion
        candidateamt = len(startcandidates)
        startpick = startcandidates[rand.randint(0,candidateamt-1)]
        startreg = startpick.region
        self.startpick = startpick
        reach = reachtest({startreg},set())
        for reg in reach:
            for twoway,exitdata in reg.twoways.items():
                unconnectedtwoways[twoway] = exitdata
                del unplacedentrs[twoway]
                available_exits += 1
            for exit,exitdata in reg.onewayouts.items():
                unconnectedexits[exit] = exitdata
                available_exits += 1
            for entr,exitdata in reg.onewayins.items():
                unconnectedentrs[entr] = exitdata
                del unplacedentrs[entr]

        untriedentrs = set(unplacedentrs.keys())

        deadends = set()
        deadcount = 0
        placedeadends = False

        unfinished = bool(unplacedentrs)

        while unfinished:
            
            if not untriedentrs:
                if deadcount <= available_exits:
                    placedeadends = True
                    untriedentrs = set(unplacedentrs.keys())
                else:
                    raise RuntimeError(f"""apAdventure ran out of placeable entrances for {self.player_name}, 
                                        their config selections probably contain too many dead ends""")
            trying = rand.choice(list(untriedentrs))
            trying_data = unplacedentrs[trying]
            trying_reg = trying_data[0]

            untriedentrs.remove(trying)
            reach = reachtest({trying_reg},set())

            can_place = True
            exit_reach = 0
            deadendscleared = 0

            for reg in reach:
                for twowayname in reg.twoways.keys():
                    if twowayname != trying and not (twowayname in unconnectedexits):
                        exit_reach += 1
                    if twowayname in deadends:
                        self.debuglog(f"placing this would clear a dead end")
                        deadendscleared += 1
                for exitname in reg.onewayouts.keys():
                    if not (exitname in unconnectedexits):
                        exit_reach += 1
            if not placedeadends and not exit_reach and available_exits - deadcount + deadendscleared >= 0:
                if not trying in deadends:
                    deadends.add(trying)
                    deadcount += 1
                    self.debuglog(f"amount of dead ends: {deadcount}, {str(deadends)}")
                else:
                    self.debuglog(f"{trying} was already in our dead ends")
                can_place = False

            self.debuglog(f"can we place {trying} with a reach of {exit_reach}? {can_place}")
            
            if can_place:
                twoway = trying in trying_reg.twoways
                target_reg = None

                targetexitacctbl = None

                if twoway and unconnectedtwoways:
                    target_name = rand.choice(list(unconnectedtwoways.keys()))
                    target_data = unconnectedtwoways[target_name]
                    target_reg = target_data[0]
                    del unconnectedtwoways[target_name]
                    connectedtwoways.add(target_name)
                    connectedtwoways.add(trying)
                    self.debuglog(f"trying to connect {trying_reg.name} and {target_reg.name}")
                    targetentracctbl = target_data[1]
                    targetexitacctbl = target_data[2]
                    tryingexitacctbl = trying_data[2]
                    trying_reg.connect(target_reg,f"{trying} -> {target_name}",
                        self.make_intermap_rule(target_reg,targetentracctbl,trying_reg,tryingexitacctbl))
                    
                    self.entranceinfo.append((trying,target_name))
                elif unconnectedexits:
                    target_name = rand.choice(list(unconnectedexits.keys()))
                    target_data = unconnectedexits[target_name]
                    del unconnectedexits[target_name]
                    target_reg = target_data[0]
                    connectedexits.add(target_name)
                    if twoway:
                        connectedtwoways.add(trying)
                else:
                    self.debuglog(f"couldn't find a place to connect {trying}")
                    continue

                self.debuglog(f"trying to connect {target_reg.name} and {trying_reg.name}")
                entracctbl = trying_data[1]
                
                target_reg.connect(trying_reg,f"{target_name} -> {trying}",
                    self.make_intermap_rule(trying_reg,entracctbl,target_reg,targetexitacctbl))
                self.entranceinfo.append((target_name,trying))
                available_exits = len(unconnectedtwoways) + len(unconnectedexits)
                self.debuglog(f"available exits before checking new reachables: {available_exits}")
                del unplacedentrs[trying]

                if trying in deadends:
                    deadends.remove(trying)
                    deadcount -= 1
                    self.debuglog(f"amount of dead ends: {deadcount}, {str(deadends)}")
                
                for reg in reach:
                    for twoway,homereg in reg.twoways.items():
                        if not twoway in connectedtwoways:
                            unconnectedtwoways[twoway] = homereg
                            if twoway in unplacedentrs:
                                del unplacedentrs[twoway]
                            if twoway in deadends:
                                deadends.remove(twoway)
                                deadcount -= 1
                                self.debuglog(f"amount of dead ends: {deadcount}, {str(deadends)}")
                            available_exits += 1
                    for exit,homereg in reg.onewayouts.items():
                        if not exit in connectedexits:
                            unconnectedexits[exit] = homereg
                            available_exits += 1
                    for entr,homereg in reg.onewayins.items():
                        if entr != trying:
                            unconnectedentrs[entr] = homereg
                            self.debuglog(f"removing {entr} from unplaced entrances")
                            if entr in unplacedentrs:
                                del unplacedentrs[entr]

                self.debuglog(f"available exits after checking new reachables: {available_exits}")

                untriedentrs = set(unplacedentrs.keys())
        
            if not unplacedentrs:
                unfinished = False

        self.debuglog(f"dead ends left after first placements: {str(deadends)}")

        self.debuglog(f"Unconnected Entrances: {str(unconnectedentrs)}")
        self.debuglog(f"Unconnected Exits: {str(unconnectedexits)}")
        self.debuglog(f"Unconnected Two-Ways: {str(unconnectedtwoways)}")

        twowaysleft = len(unconnectedtwoways)
        while twowaysleft > 1:
            keys = list(unconnectedtwoways.keys())
            pick1 = rand.randint(0,twowaysleft-1)
            pick2 = rand.randint(0,twowaysleft-1)
            if pick1 == pick2:
                while pick1 == pick2:
                    pick2 = rand.randint(0,twowaysleft-1)

            key1 = keys[pick1]
            key2 = keys[pick2]

            data_a = unconnectedtwoways[key1]
            data_b = unconnectedtwoways[key2]
            
            reg1 = data_a[0]
            reg2 = data_b[0]

            reg1.connect(reg2,f"{key1} -> {key2} (from remaining)",
                self.make_intermap_rule(reg2,data_b[1],reg1,data_a[2]))
            self.entranceinfo.append((key1,key2))
            reg2.connect(reg1,f"{key2} -> {key1} (from remaining)",
                self.make_intermap_rule(reg1,data_a[1],reg2,data_b[2]))
            self.entranceinfo.append((key2,key1))

            del unconnectedtwoways[key1]
            del unconnectedtwoways[key2]
            twowaysleft -= 2

        entrsleft = len(unconnectedentrs)
        exitsleft = len(unconnectedexits)

        if unconnectedtwoways and (entrsleft or exitsleft):
            last = unconnectedtwoways.popitem()
            last_data = last[1]
            if entrsleft > exitsleft:
                last_data = (last_data[0],last_data[2])
                unconnectedexits[last[0]] = last_data
                exitsleft += 1
            else:
                unconnectedentrs[last[0]] = last_data
                entrsleft += 1

        onewaysleft = min(entrsleft,exitsleft)
        while onewaysleft > 0:
            keys1 = list(unconnectedentrs.keys())
            keys2 = list(unconnectedexits.keys())
            pick1 = rand.randint(0,entrsleft-1)
            pick2 = rand.randint(0,exitsleft-1)

            data_a = unconnectedentrs[keys1[pick1]]
            data_b = unconnectedexits[keys2[pick2]]

            reg1 = data_a[0]
            reg2 = data_b[0]

            reg2.connect(reg1,f"{reg2.name} -> {reg1.name} (from remaining)",
                self.make_intermap_rule(reg1,data_a[1],reg2,data_b[1]))
            self.entranceinfo.append((keys2[pick2],keys1[pick1]))

            del unconnectedentrs[keys1[pick1]]
            del unconnectedexits[keys2[pick2]]
            onewaysleft -= 1
            entrsleft -= 1
            exitsleft -= 1

        self.debuglog(f"Unconnected Entrances: {str(unconnectedentrs)}")
        self.debuglog(f"Unconnected Exits: {str(unconnectedexits)}")

        # the menu is connected at the end because the reachtest function can't handle it 
        # and doing it like this is probably faster than making it check if every region it tests is not the menu

        startreg.connect(menu)
        menu.connect(startreg)

        

    def set_rules(self):
        self.multiworld.completion_condition[self.player] = lambda state: state.has("McGuffin", self.player)

    def fill_slot_data(self):

        cfgs = dict()

        for k,v in self.maps.items():
            if v.bspname in cfgs:
                cfgs[v.bspname].append(v.group)
            else:
                cfgs[v.bspname] = [v.group]

        slotdata = {
            "bhop":int(self.bhop),
            "skill":int(self.options.skill),
            "entrances":self.entranceinfo,
            "cfgs":cfgs,
            "itemsets":self.loadeditemsets,
            "items_dontload":self.items_dontload,
            "items_to_load":self.items_to_load,
            "startmap":self.startpick.map.bspname,
            "startgroup":self.startpick.map.group,
            "startregion":self.startpick.regname,
            "ammomerge":self.ammomerge_out,
        }

        return slotdata

    def generate_output(self, output_directory: str):
        filenamestart = f"{output_directory}/AP_{self.multiworld.seed_name}_{self.player_name}_"
        if self.options.generate_puml:
            from Utils import visualize_regions
            state = self.multiworld.get_all_state(False)
            state.update_reachable_regions(self.player)
            visualize_regions(self.get_region("Menu"), filenamestart+"regions.puml", show_entrance_names=True,
                            regions_to_highlight=state.reachable_regions[self.player])
        if len(self.warnings) > 0:
            warnlog = open(filenamestart+"warnings.txt","x")
            for warn in self.warnings:
                warnlog.write(warn+"\n")
        if self.dodebug and len(self.debuginfo) > 0:
            debugfile = open(filenamestart+"debug.txt","x")
            for debug in self.debuginfo:
                debugfile.write(debug+"\n")


