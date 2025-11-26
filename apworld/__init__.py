import typing
import json
import os
from worlds.AutoWorld import World
from BaseClasses import Item, ItemClassification, Region, Location, CollectionState
from .Settings import GMADVSettings
from .Options import GMADVGameOptions
from .JsonRule import eval_json_rule
from settings import get_settings
from entrance_rando import randomize_entrances
from .ImpliedCapabilities import impliedcapabilities
#from .CfgProcessor import item_set_table, item_name_to_id, base_item_table, duplicate_item_names, map_table
from .CfgProcessor import ProcessCfgs

class GMADVItem(Item):
    game = "gmAdventure"

class GMADVLocation(Location):
    game = "gmAdventure"

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
    #print(f"current reach: {str(canreach)}")
    for reg in canreach:
        if not reg in checked:
            done = False
            for exit in reg.exits:
                newreach.add(exit.connected_region)
                #print(f"{reg} is connected to {exit.connected_region}")
            """ for targetreg in reg.onewayouts.values():
                newreach.add(targetreg)
                print(f"{reg} is connected to {targetreg}") """
            checked.add(reg)
    if done:
        return newreach
    else:
        return reachtest(newreach,checked)

class GMADVWorld(World):
    """\"I wish someone would make a mod.\"
    
    Garry:"""

    game = "gmAdventure"

    processout = ProcessCfgs(get_settings())

    # i hate this

    item_set_table = processout[0]
    item_name_to_id = processout[1]
    base_item_table = processout[2]
    duplicate_item_names = processout[3]
    map_table = processout[4]
    location_name_to_id = processout[5]

    #item_name_to_id = {}

    #location_name_to_id = {}

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
        self.ammocapabilitytbl = dict()
        self.warnings = list()
        self.connectiongroups = set()
        self.entranceinfo = list()
        self.rando_entrances = dict()
        self.item_table = self.base_item_table.copy()     

    def add_warning(self,warning):
        self.warnings.append(warning)
        print(warning)
        if self.dodebug:
            self.debuginfo.append(warning) 


    def debuglog(self,debug: str):
        if self.dodebug:
            self.debuginfo.append(debug)
            print(debug)

    def get_filler_item_name(self):
        if self.filleramt == 0:
            return "Nothing"
        else:
            return self.random.choices(list(self.fillers.keys()),self.fillers.values())[0] # took this from ahit, seems like it'd be kinda slow but what do i know
    
    def generate_early(self):
        if self.options.write_debug:
            self.dodebug = True
            self.debuginfo = list()
        else:
            self.dodebug = False

        gmodpath = get_settings().gmadv_options.gmodpath
        cfgdir = gmodpath+"/garrysmod/data/apadventure/cfgs/ap/"
        cfggroups = os.listdir(cfgdir)

        for gr in cfggroups:
            print(gr)

        #chosencfgr = self.options.config_groups

        self.bhop = self.options.bhop

        if self.bhop ==  1:
            self.bhop_logic = False
        else:
            self.bhop_logic = self.options.bhop_logic

        #foundgroups = 0

        """ for gr in chosencfgr:
            grdir = cfgdir+gr
            if os.path.isdir(grdir):
                print("found group "+gr+" at "+grdir)
                foundgroups += 1
        
                groupmaps = os.listdir(grdir)

                for map in groupmaps:
                    if map in self.maps:
                        print("map "+map+" already processed, skipping")
                        continue

                    print("processing "+map)

                    newmap = GMADVMap(map,gr)
                    mapdir = grdir+"/"+map
                    if not os.path.isfile(mapdir+"/sav.json"):
                        self.add_warning(f"could not find serverside save for {map} from {gr}")
                        continue
                    if not os.path.isfile(mapdir+"/sav_cl.json"):
                        self.add_warning(f"could not find clientside save for {map} from {gr}")
                        continue
                    cljson = json.load(open(mapdir+"/sav_cl.json"))

                    if "info" in cljson:
                        newmap.info = cljson["info"]

                    for k,v in cljson["reg"].items():
                        v["lctns"] = dict()
                        newmap.regions[k] = v

                    if not newmap.regions:
                        self.add_warning(f"map {map} from {gr} has no regions, discarded")
                        continue
                    
                    newmap.internalConnections = cljson["connect"]

                    svjson = json.load(open(mapdir+"/sav.json"))

                    for k,v in svjson["entr"].items():
                        if v in newmap.regions:
                            newmap.entrances[k] = v
                            print("adding entrace "+k+" to map "+map)
                        else: 
                            self.add_warning(f"map {map} from {gr} has an entrance placed in non-existing region \"{k}\"")

                    if not newmap.entrances:
                        self.add_warning(f"map {map} from {gr} has no entrances, discarded")
                        continue
                    
                    for k,v in svjson["exit"].items():
                        if v in newmap.regions:
                            newmap.exits[k] = v
                        else: 
                            self.add_warning(f"map {map} from {gr} has an exit placed in non-existing region \"{k}\"")

                    if "lctn" in svjson and isinstance(svjson["lctn"], dict): # should probably have these removed completely if they're empty so i don't have to check if they're a dict
                        for k,v in svjson["lctn"].items():
                            if k in newmap.regions:
                                newmap.regions[k]["lctns"] = v
                            else:
                                self.add_warning(f"map {map} from {gr} has locations assigned to non-existing region \"{k}\"")

                    if "start" in svjson:                    
                        for k,v in svjson["start"].items():
                            if k in newmap.regions:
                                newmap.regions[k]["startcandidate"] = True
                            else:
                                self.add_warning(f"map {map} from {gr} has starts defined for non-existing region \"{k}\"")

                    if "item" in cljson:
                        newmap.items = cljson["item"]

                    self.maps[map] = newmap
                    del newmap, cljson, svjson
            else:
                print("couldn't find group "+gr+" at "+grdir)

        if foundgroups == 0:
            raise RuntimeError(self.player_name+" has no valid config groups in their yaml")

        for k,map in self.maps.items():
            print(f"{map.bspname}\tRegions: {str(len(map.regions))}\tEntrances: {str(len(map.entrances))}\tExits: {str(len(map.exits))}")
            for k,v in map.entrances.items():
                print(k,v) """

    def create_item(self, name):
        data = self.item_table[name]
        if data[1] == None:
            match data[0]:
                case "Bunnyhop":
                    if self.bhop_logic:
                        data[1] = ItemClassification.progression
                    else:
                        data[1] = ItemClassification.useful


        return GMADVItem(name, data[1], data[0], self.player)
    
    def create_regions(self):
        menu = Region("Menu",self.player,self.multiworld)
        self.multiworld.regions.append(menu)
        self.menuregion = menu

        chosencfgr = self.options.config_groups

        print("creating regions")
        startcandidates = list()

        mapitems = dict()

        entrs = dict()

        for groupname in chosencfgr:

            if not groupname in self.map_table:
                self.add_warning(f"map group {groupname} does not exist")
                continue

            groupmaps = self.map_table[groupname]

            for mapname,map in groupmaps.items():
                print(mapname)
                mapregs = dict()
                
                for k,v in map.regions.items():
                    newreg = Region(f"{map.group} - {map.bspname} - {k}",self.player,self.multiworld)
                    reglocs = list()
                    for ik,iv in v["lctns"].items():
                        #self.__class__.locs += 1
                        newlocname = f"{map.group} - {map.bspname} - {ik}"
                        #self.location_name_to_id[newlocname] =  self.locs
                        
                        reglocs.append(GMADVLocation(self.player,newlocname,self.location_name_to_id[newlocname],newreg))
                        self.locallocs += 1
                    newreg.priotize_entrances = False
                    if "prioentr" in v:
                        newreg.priotize_entrances = True
                    newreg.locations = reglocs
                    newreg.mapname = map.bspname
                    newreg.mapgroup = map.group
                    newreg.has_entr = False
                    newreg.has_exit = False
                    newreg.connected_to = set()
                    newreg.onewayins = dict()
                    newreg.onewayouts = dict()
                    newreg.twoways = dict()
                    if "ammo" in v:
                        if type(v["ammo"]) is list:
                            newreg.ammo = set(v["ammo"])
                        else:
                            newreg.ammo = set(v["ammo"].keys()) # could also do this conversion when saving the config in lua to save the generator some work

                    mapregs[k] = newreg

                    if "startcandidate" in v:
                        print(k, "is a starting candidate")
                        startcandidates.append(StartRegion(newreg,map,k))

                    print("creating region "+map.bspname+" - "+ k)

                

                for k,v in map.entrances.items():
                    reg = mapregs[v]
                    reg.has_entr = True
                    name = reg.name+" - "+k
                    #entr = reg.create_exit(name)
                    entrs[name] = reg
                    reg.onewayins[name] = reg
                    print("adding exit "+k+" to "+v)

                for k,v in map.exits.items():
                    reg = mapregs[v]
                    reg.has_exit = True
                    name = reg.name+" - "+k
                    #exit = reg.create_er_target(name)
                    if name in entrs:
                        pass
                        #entrs[name].randomization = 2
                        #exit.randomization_type = 2
                    if name in reg.onewayins:
                        del reg.onewayins[name]
                        reg.twoways[name] = reg
                    else:
                        reg.onewayouts[name] = reg


                for k,v in mapregs.items():
                    """ print(self.locs,len(self.location_name_to_id))
                    self.__class__.locs += 1
                    newlocname = map.bspname+" - "+str(self.locs)
                    self.location_name_to_id[self.locs] = newlocname
                    print("locs: "+str(self.locs),len(self.location_name_to_id))
                    v.locations = [GMADVLocation(self.player,newlocname,None,v)]
                    self.locallocs += 1 """
                    self.multiworld.regions.append(v)

                for k,v in map.internalConnections.items():
                    if not k in mapregs:
                        self.add_warning(f"{map.bspname} in {map.group} tried to make an internal connection to non-existing region \"{k}\"")
                        continue
                    for ik, iv in v.items():
                        if not ik in mapregs:
                            self.add_warning(f"{map.bspname} in {map.group} tried to make an internal connection to non-existing region \"{ik}\"")
                            continue

                        rule_a = None
                        rule_b = None
                        if "access" in iv:
                            rule_a = lambda state, acctbl=iv["access"], world=self, region=mapregs[k]: eval_json_rule(acctbl,state,world,region)
                            print(f"registering access rule for {ik} and {k}" )
                            if iv["twoway"]:
                                rule_b = lambda state, acctbl=iv["access"], world=self, region=mapregs[ik]: eval_json_rule(acctbl,state,world,region)

                        mapregs[k].connect(mapregs[ik],f"{map.bspname} - {k} -> {ik}",rule_a)
                        mapregs[k].connected_to.add(mapregs[ik])
                        mapregs[ik].connected_to.add(mapregs[k])
                        if iv["twoway"] and iv["twoway"] == True:
                            mapregs[ik].connect(mapregs[k],f"{map.bspname} - {ik} -> {k}",rule_b)

                for k,v in map.items.items():
                    mapitems[f"{groupname} - {mapname} - {k}"] = v

        self.map_items = mapitems
        self.rando_entrances = entrs
        self.startingcandidates = startcandidates

    def create_items(self):
        itempool = [self.create_item("McGuffin")]

        if self.bhop == 2:
            itempool.append(self.create_item("Bunnyhop"))

        for iname,info in self.map_items.items():
            self.item_table[iname] = (self.item_name_to_id[iname],ItemClassification(info["fl"]))
            i = 0
            while i < info["amt"]:
                itempool.append(self.create_item(iname))
                i += 1
                
        """ gmodpath = get_settings().gmadv_options.gmodpath
        defdir = gmodpath+"/garrysmod/data/apadventure/itemdefs/" """

        chosenisets = self.options.item_sets

        for isetname in chosenisets:

            """ if not iset in self.registereditemsets:
                setpath = defdir+iset+".json"
                if os.path.isfile(setpath):
                    setjson = json.load(open(setpath))
                    setname = setjson["name"]
                    newiset = GMADVItemSet(iset,setname)
                    if "items" in setjson and isinstance(setjson["items"], dict):
                        for iname, idef in setjson["items"].items():
                            self.__class__.itemtypes += 1
                            newitemname = f"{iname} - {setname}"
                            itemclass = 0
                            if "ammocapab" in idef or "capab" in idef:
                                itemclass = itemclass | 1

                             if newitemname in self.item_name_to_id:
                                newitemname = f"{iname} - {setname}" 
                            self.item_name_to_id[newitemname] = self.itemtypes
                            self.item_table[newitemname] = (self.itemtypes,ItemClassification(itemclass))
                            newitem = SetItem(self.itemtypes,newitemname,idef)
                            print("added item "+newitemname)
                            newiset.items.append(newitem)

                            
                    self.registereditemsets[iset] = newiset
 """
            """ if iset in self.registereditemsets:        
                for item in self.registereditemsets[iset].items:
                    if "wgt" in item.info:
                        self.fillers[item.name] = item.info["wgt"]
                        self.filleramt += 1
                    if "min" in item.info and item.info["min"] > 0:
                        i = 0
                        while i < item.info["min"]:
                            itempool.append(self.create_item(item.name))
                            i += 1
                    if "capab" in item.info:
                        finalcapabs = set()
                        for capab in item.info["capab"]:
                            finalcapabs.add(capab)
                            if capab in impliedcapabilities:
                                for cap in impliedcapabilities[capab]:
                                    finalcapabs.add(cap)
                        capabentry = CapabTblEntry(item.name,finalcapabs)
                        for capab in finalcapabs:
                            if not capab in self.capabilitytbl:
                                self.capabilitytbl[capab] = list()
                            
                            self.capabilitytbl[capab].append(capabentry)
                    if "ammocapab" in item.info:
                        print(item.info["ammocapab"])
                        for ammotype,capabs in item.info["ammocapab"].items():
                            if not ammotype in self.ammocapabilitytbl:
                                self.ammocapabilitytbl[ammotype] = dict()
                            self.ammocapabilitytbl[ammotype][item.name] = capabs

                self.loadeditemsets.append(iset)
            else:
                self.add_warning(f"itemset {iset} could not be loaded") """
            
            if isetname in self.item_set_table:        
                iset = self.item_set_table[isetname]
                isetitems = iset.items
                for item in isetitems:
                    name = item.name
                    if name in self.duplicate_item_names:
                        name = item.long_name
                    flags = 0
                    if "ammocapab" in item.info or "capab" in item.info:
                        flags = flags | 1

                    self.item_table[name] = (self.item_name_to_id[name],ItemClassification(flags))

                    if "wgt" in item.info:
                        self.fillers[item.name] = item.info["wgt"]
                        self.filleramt += 1
                    if "min" in item.info and item.info["min"] > 0:
                        i = 0
                        while i < item.info["min"]:
                            itempool.append(self.create_item(item.name))
                            i += 1
                    if "capab" in item.info:
                        finalcapabs = set()
                        for capab in item.info["capab"]:
                            finalcapabs.add(capab)
                            if capab in impliedcapabilities:
                                for cap in impliedcapabilities[capab]:
                                    finalcapabs.add(cap)
                        capabentry = CapabTblEntry(name,finalcapabs)
                        for capab in finalcapabs:
                            if not capab in self.capabilitytbl:
                                self.capabilitytbl[capab] = list()
                            
                            self.capabilitytbl[capab].append(capabentry)
                    if "ammocapab" in item.info:
                        print(item.info["ammocapab"])
                        for ammotype,capabs in item.info["ammocapab"].items():
                            if not ammotype in self.ammocapabilitytbl:
                                self.ammocapabilitytbl[ammotype] = dict()
                            self.ammocapabilitytbl[ammotype][name] = capabs
                self.loadeditemsets.append(isetname)
            else:
                self.add_warning(f"itemset {isetname} could not be loaded")
                
            
                        
            

        if len(itempool) < self.locallocs:
            missingitems = self.locallocs - len(itempool)

            while missingitems > 0:
                itempool.append(self.create_item(self.get_filler_item_name()))
                missingitems -= 1

        self.multiworld.itempool += itempool

    def connect_entrances(self):

        rand = self.random

        #unplacedconnectiongroups = self.connectiongroups.copy()
        unplacedentrs = self.rando_entrances
        unconnectedtwoways = dict()
        unconnectedexits = dict()
        unconnectedentrs = dict()
        connectedtwoways = set()
        connectedexits = set()

        available_exits = 0 

        startcandidates = self.startingcandidates
        menu = self.menuregion
        candidateamt = len(startcandidates)
        startreg = None
        print("candidate amount",candidateamt)
        if candidateamt == 0:
            RuntimeError(self.player_name+" had no maps with valid starting regions in their selected map groups")
        else:
            startpick = startcandidates[self.random.randint(0,candidateamt-1)]
            startreg = startpick.region
            self.startpick = startpick
            reach = reachtest({startreg},set())
            for reg in reach:
                for twoway,homereg in reg.twoways.items():
                    unconnectedtwoways[twoway] = homereg
                    del unplacedentrs[twoway]
                    available_exits += 1
                for exit,homereg in reg.onewayouts.items():
                    unconnectedexits[exit] = homereg
                    available_exits += 1
                for entr,homereg in reg.onewayins.items():
                    unconnectedentrs[entr] = homereg
                    print(f"removing {entr} from unplaced entrances")
                    del unplacedentrs[entr]

        untriedentrs = set(unplacedentrs.keys())

        deadends = set()
        deadcount = 0

        print(str(untriedentrs))

        unfinished = True

        exit_reach_strictness = 3

        while unfinished:
            
            if not untriedentrs:
                print("this isn't working")
                
                if exit_reach_strictness > 0:
                    exit_reach_strictness -= 1
                    print(f"reduced strictness to {exit_reach_strictness}")
                    untriedentrs = set(unplacedentrs.keys())
                print(f"available exits: {available_exits}\nremaining: {str(unplacedentrs)}\ndead ends: {str(deadends)}")


            trying = rand.choice(list(untriedentrs))

            untriedentrs.remove(trying)

            trying_reg = unplacedentrs[trying]

            reach = reachtest({trying_reg},set())

            can_place = True
            exit_reach = 0
            deadendscleared = 0

            #if available_exits < exit_reach_strictness:
            if True:
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
                if exit_reach < 1 and available_exits - deadcount + deadendscleared >= 0:
                    deadends.add(trying)
                    deadcount += 1
                    self.debuglog(f"amount of dead ends: {deadcount}, {str(deadends)}")
                    # del unplacedentrs[trying]
                    can_place = False

            self.debuglog(f"can we place {trying} with a reach of {exit_reach}? {can_place}")
            
            if can_place:
                twoway = trying in trying_reg.twoways
                target_reg = None

                if twoway and unconnectedtwoways:
                    target_name = rand.choice(list(unconnectedtwoways.keys()))
                    target_reg = unconnectedtwoways[target_name]
                    del unconnectedtwoways[target_name]
                    connectedtwoways.add(target_name)
                    connectedtwoways.add(trying)
                    self.debuglog(f"trying to connect {trying_reg.name} and {target_reg.name}")
                    trying_reg.connect(target_reg,f"{trying} -> {target_name}")
                    self.entranceinfo.append((trying,target_name))
                elif unconnectedexits:
                    target_name = rand.choice(list(unconnectedexits.keys()))
                    target_reg = unconnectedexits[target_name]
                    del unconnectedexits[target_name]
                    connectedexits.add(target_name)
                    if twoway:
                        connectedtwoways.add(trying)
                else:
                    self.debuglog(f"couldn't find a place to connect {trying}")
                    continue

                self.debuglog(f"trying to connect {target_reg.name} and {trying_reg.name}")
                
                target_reg.connect(trying_reg,f"{target_name} -> {trying}")
                self.entranceinfo.append((target_name,trying))
                #self.debuglog(f"connected {target_reg.name} and {trying_reg.name}")
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
                            print(f"removing {entr} from unplaced entrances")
                            if entr in unplacedentrs:
                                del unplacedentrs[twoway]

                self.debuglog(f"available exits after checking new reachables: {available_exits}")

                untriedentrs = set(unplacedentrs.keys())
        
            if not unplacedentrs:
                unfinished = False

        self.debuglog(f"dead ends left after first placements: {str(deadends)}")

        """ conngroup = startpick.region.connectiongroup
        unplacedconnectiongroups.discard(conngroup)
        for entr, reg in conngroup.entr.items():
            unconnectedentrs[entr] = reg
        for exit, reg in conngroup.exit.items():
            unconnectedexits[exit] = reg
        for twoway, reg in conngroup.twoway.items():
            unconnectedtwoways[twoway] = reg """

        """ need_multi_entr = dict()
        highest_entr_req = 1
        entr_reqs = set()
        multientrsleft = 0
        deadends = list()
        #noreturndeadends = list()
        straights = list()
        junctions = list()

        for conngroup in unplacedconnectiongroups:
            openingreq = conngroup.openings_needed
            entrcount = len(conngroup.entr)
            exitcount = len(conngroup.exit)
            twowaycount = len(conngroup.twoway)
            #outcount = exitcount + twowaycount
            incount = entrcount + twowaycount
            if openingreq > 1:
                if not openingreq in need_multi_entr:
                    need_multi_entr[openingreq] = list()
                    entr_reqs.add(openingreq)
                need_multi_entr[openingreq].append
                multientrsleft += 1
                if highest_entr_req < openingreq:
                    highest_entr_req = openingreq


            elif incount == 1 and exitcount == 0:
               # if twowaycount == 1:
                    deadends.append(conngroup)
                #else:
                #    noreturndeadends.append(conngroup)
            elif (twowaycount == 1 and exitcount == 1) or (twowaycount == 2 and exitcount == 0):
                straights.append(conngroup)
            else:
                junctions.append(conngroup)

        conngroupsleft = len(unplacedconnectiongroups)

        done = False

        

        failedactions = set()

        while not done:
            availabletwoways = len(unconnectedtwoways)
            availableexits = len(unconnectedexits)
            connectables = availabletwoways + availableexits
            
            deadendsleft = len(deadends)
            junctionsleft = len(junctions)
            straightsleft = len(straights)
            action = "done"
            
            possibleactions = set()

            if connectables < highest_entr_req:
                if junctionsleft > 0 and not "junction" in failedactions:
                    action = "junction"
                else:
                    if highest_entr_req == 1:
                        if straightsleft > 0 and not "straight" in failedactions:
                            action = "straight"
                        elif deadendsleft > 0 and not "deadend" in failedactions:
                            action = "deadend"

            elif connectables == highest_entr_req:
                if junctionsleft > 0 and not "junction" in failedactions:
                    possibleactions.add("junction")
                if straightsleft > 0 and not "straight" in failedactions:
                    possibleactions.add("straight")

            else:
                if multientrsleft > 0 and not "multentr" in failedactions:
                    possibleactions.add("multientr")
                if junctionsleft > 0 and not "junction" in failedactions:
                    possibleactions.add("junction")
                if straightsleft > 0 and not "straight" in failedactions:
                    possibleactions.add("straight")
                if deadendsleft > 0 and not "deadend" in failedactions:
                    possibleactions.add("deadend")
                    
            if action != "done" and len(possibleactions) != 0:
                action = rand.choice(list(possibleactions))
            
            action2block = {
                "junction":junctions,
                "straight":straights,
                "deadend":deadends,
            }

            self.add_warning(f"action: {action}")

            match action:
                case "junction" | "straight" | "deadend":
                    unfinished = True
                    untried = action2block[action].copy()
                    untriedamt = len(untried) - 1
                    while unfinished:
                        pick = 0 
                        if untriedamt > 0:
                            pick = rand.randint(0,untriedamt)
                        print(pick,untried)
                        block = untried[pick]
                        untried.pop(pick)
                        untriedamt -= 1
                        

                        if availabletwoways > 0 and block.connectfirst.twoways:
                            connfirst: Region = block.connectfirst
                            key1 = rand.choice(list(unconnectedtwoways.keys()))
                            key2 = rand.choice(list(connfirst.twoways.keys()))

                            reg1: Region = unconnectedtwoways[key1]
                            reg2: Region = connfirst

                            reg1.connect(reg2)
                            reg2.connect(reg1)
                            self.entranceinfo.append((key1,key2))
                            self.entranceinfo.append((key2,key1))
                            self.add_warning(f"{key1} connected to {key2}")

                            del unconnectedtwoways[key1]
                            del block.twoway[key2]

                            for entr, reg in block.entr.items():
                                unconnectedentrs[entr] = reg
                            for exit, reg in block.exit.items():
                                unconnectedexits[exit] = reg
                            for twoway, reg in block.twoway.items():
                                unconnectedtwoways[twoway] = reg

                            action2block[action].remove(block)
                            unplacedconnectiongroups.remove(block)
                            #junctionsleft -= 1
                            unfinished = False
                            failedactions = set()
                        elif availableexits > 0 and block.connectfirst.onewayins:
                            connfirst: Region = block.connectfirst
                            key1 = rand.choice(list(unconnectedexits.keys()))
                            key2 = rand.choice(list(connfirst.onewayins.keys()))

                            reg1 = unconnectedexits[key1]
                            reg2 = connfirst

                            reg1.connect(reg2)
                            self.entranceinfo.append((key1,key2))

                            del unconnectedexits[key1]
                            del block.entr[key2]

                            for entr, reg in block.entr.items():
                                unconnectedentrs[entr] = reg
                            for exit, reg in block.exit.items():
                                unconnectedexits[exit] = reg
                            for entr, reg in block.entr.items():
                                unconnectedtwoways[entr] = reg

                            action2block[action].remove(block)
                            #junctionsleft -= 1
                            unfinished = False
                            failedactions = set()
                        elif availableexits > 0 and block.connectfirst.twoways:
                            connfirst: Region = block.connectfirst
                            key1 = rand.choice(list(unconnectedexits.keys()))
                            key2 = rand.choice(list(connfirst.twoways.keys()))

                            reg1 = unconnectedexits[key1]
                            reg2 = connfirst

                            reg1.connect(reg2)
                            self.entranceinfo.append((key1,key2))

                            del unconnectedexits[key1]
                            del block.twoway[key2]

                            for entr, reg in block.entr.items():
                                unconnectedentrs[entr] = reg
                            for exit, reg in block.exit.items():
                                unconnectedexits[exit] = reg
                            for entr, reg in block.entr.items():
                                unconnectedtwoways[entr] = reg

                            action2block[action].remove(block)
                            #junctionsleft -= 1
                            unfinished = False
                            failedactions = set()
                        
                        if untriedamt <= 0:
                            failedactions.add(action)
                            unfinished = False                    
                case "done":
                    done = True


            if conngroupsleft == 0:
                done = True
            

        for conngroup in unplacedconnectiongroups:
            for entr, reg in conngroup.entr.items():
                unconnectedentrs[entr] = reg
            for exit, reg in conngroup.exit.items():
                unconnectedexits[exit] = reg
            for twoway, reg in conngroup.twoway.items():
                unconnectedtwoways[twoway] = reg


         """

        self.add_warning(f"Unconnected Entrances: {str(unconnectedentrs)}")
        self.add_warning(f"Unconnected Exits: {str(unconnectedexits)}")
        self.add_warning(f"Unconnected Two-Ways: {str(unconnectedtwoways)}")

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
            
            reg1 = unconnectedtwoways[key1]
            reg2 = unconnectedtwoways[key2]
            reg1.connect(reg2,f"{key1} -> {key2} (from remaining)")
            self.entranceinfo.append((key1,key2))
            reg2.connect(reg1,f"{key2} -> {key1} (from remaining)")
            self.entranceinfo.append((key2,key1))

            del unconnectedtwoways[key1]
            del unconnectedtwoways[key2]
            twowaysleft -= 2

        if unconnectedtwoways:
            last = list(unconnectedtwoways.items())[0]
            unconnectedentrs[last[0]] = last[1]
            unconnectedexits[last[0]] = last[1]

        entrsleft = len(unconnectedentrs)
        exitsleft = len(unconnectedexits)
        onewaysleft = min(entrsleft,exitsleft)
        while onewaysleft > 0:
            keys1 = list(unconnectedentrs.keys())
            keys2 = list(unconnectedexits.keys())
            pick1 = rand.randint(0,entrsleft-1)
            pick2 = rand.randint(0,exitsleft-1)

            print(pick1,unconnectedentrs)
            reg1 = unconnectedentrs[keys1[pick1]]
            reg2 = unconnectedexits[keys2[pick2]]
            reg2.connect(reg1)
            self.entranceinfo.append((keys2[pick2],keys1[pick1]))

            del unconnectedentrs[keys1[pick1]]
            del unconnectedexits[keys2[pick2]]
            onewaysleft -= 1
            entrsleft -= 1
            exitsleft -= 1


        """ for entr, reg in unconnectedentrs.items():
            reg.create_exit(entr)
        for exit, reg in unconnectedexits.items():
            reg.create_er_target(exit)
        for twoway, reg in unconnectedtwoways.items():
            reg.create_exit(twoway)
            reg.create_er_target(twoway) """

        """ self.add_warning(f"Dead Ends: {str(deadends)}")
        self.add_warning(f"Straights: {str(straights)}")
        self.add_warning(f"Junctions: {str(junctions)}") """
        self.add_warning(f"Unconnected Entrances: {str(unconnectedentrs)}")
        self.add_warning(f"Unconnected Exits: {str(unconnectedexits)}")
        self.add_warning(f"Unconnected Two-Ways: {str(unconnectedtwoways)}")

        # the menu is connected at the end because the reachtest function can't handle it 
        # and doing it like this is probably faster than making it check if every region it tests is not the menu

        print("connecting ",startreg, menu)
        startreg.connect(menu)
        menu.connect(startreg)

        #self.ERPlacements = randomize_entrances(self,True,{0:[0]})

        

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
            #"entrances":self.ERPlacements.pairings,
            "entrances":self.entranceinfo,
            "cfgs":cfgs,
            "itemsets":self.loadeditemsets,
            "startmap":self.startpick.map.bspname,
            "startgroup":self.startpick.map.group,
            "startregion":self.startpick.regname,
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


