import typing
import json
import os
from worlds.AutoWorld import World
from BaseClasses import Item, ItemClassification, Region, Location, CollectionState
from .Settings import GMADVSettings
from .Options import GMADVGameOptions
from .JsonRule import eval_json_rule, preprocess_json_rule
from settings import get_settings
from entrance_rando import randomize_entrances
from .ImpliedCapabilities import ProcessCapabs
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

    game = "gmAdventure"

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

        self.bhop = self.options.bhop

        if self.bhop ==  1:
            self.bhop_logic = False
        else:
            self.bhop_logic = self.options.bhop_logic

        chosenisets = self.options.item_sets

        itempool = dict()

        for isetname in chosenisets:
            if isetname in self.item_set_table:        
                iset = self.item_set_table[isetname]
                isetitems = iset.items
                for item in isetitems:
                    name = item.name
                    if name in self.duplicate_item_names:
                        name = item.long_name
                    """ if "condcapab" in item.info or "capab" in item.info:
                        flags = flags | 1 """

                    self.item_table[name] = (self.item_name_to_id[name],None,item.info)

                    if "wgt" in item.info:
                        self.fillers[item.name] = item.info["wgt"]
                        self.filleramt += 1
                    if "min" in item.info and item.info["min"] > 0:
                        itempool[item.name] = item.info["min"]
                    if "capab" in item.info:
                        finalcapabs = ProcessCapabs(set(item.info["capab"]))
                        capabentry = CapabTblEntry(name,finalcapabs)
                        for capab in finalcapabs:
                            if not capab in self.capabilitytbl:
                                self.capabilitytbl[capab] = list()
                            
                            self.capabilitytbl[capab].append(capabentry)
                    if "condcapab" in item.info:
                        print(item.info["condcapab"])
                        for cond,capabs in item.info["condcapab"].items():
                            if not cond in self.condcapabtbl:
                                self.condcapabtbl[cond] = dict()
                            self.condcapabtbl[cond][name] = ProcessCapabs(set(capabs))
                self.loadeditemsets.append(isetname)
            else:
                self.add_warning(f"itemset {isetname} could not be loaded")

            self.items_to_create = itempool

    def create_item(self, name):
        data = self.item_table[name]
        flags = data[1]
        info = data[2]
        if flags == None:
            if info:
                print(info)
                flags = ItemClassification.filler
                if "capab" in info: # and self.usedcapabs.intersect(capab) or ( condcapab and self.usedcapabs.intersect(condcapab)):
                    print(f"{name} had capabs")
                    capab = info["capab"]
                    if self.usedcapabs.intersection(capab):
                        flags = ItemClassification.progression
                    else:
                        flags = ItemClassification.useful
                if not flags == ItemClassification.progression and "condcapab" in info:
                    print(f"{name} had condcapabs")
                    condcapab = info["condcapab"]
                    for k,v in condcapab.items():
                        if self.usedcapabs.intersection(v):
                            flags = ItemClassification.progression
                            break
                        else:
                            flags = ItemClassification.useful
            else:
                match data[0]:
                    case "Bunnyhop":
                        if self.bhop_logic:
                            flags = ItemClassification.progression
                        else:
                            flags = ItemClassification.useful
            
        print(f"creating item {name} with flags {flags}")
        return GMADVItem(name, flags, data[0], self.player)
    
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
                        newreg.conditions = set(v["cond"])


                    mapregs[k] = newreg

                    if "startcandidate" in v:
                        print(k, "is a starting candidate")
                        startcandidates.append(StartRegion(newreg,map,k))

                    print("creating region "+map.bspname+" - "+ k)

                for k,v in map.entrances.items():
                    reg = mapregs[v]
                    reg.has_entr = True
                    name = reg.name+" - "+k
                    entrs[name] = reg
                    reg.onewayins[name] = reg
                    print("adding exit "+k+" to "+v)

                for k,v in map.exits.items():
                    reg = mapregs[v]
                    reg.has_exit = True
                    name = reg.name+" - "+k
                    if name in reg.onewayins:
                        del reg.onewayins[name]
                        reg.twoways[name] = reg
                    else:
                        reg.onewayouts[name] = reg

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
                            acctbl = preprocess_json_rule(iv["access"],self,reg_a)
                            print(acctbl)
                            if acctbl["type"] == "never":
                                rule_a = False
                                print(f"access rule between {ik} and {k} can never be fullfilled with current options and was removed")
                            else:
                                rule_a = lambda state, acctbl=acctbl, world=self, region=reg_a: eval_json_rule(acctbl,state,world,region)
                                print(f"registering access rule for {ik} and {k}" )
                            if iv["twoway"]:
                                acctbl = preprocess_json_rule(iv["access"],self,reg_b)
                                print(acctbl)
                                if acctbl["type"] == "never":
                                    rule_b = False
                                    print(f"access rule between {k} and {ik} can never be fullfilled with current options and was removed")
                                else:
                                    rule_b = lambda state, acctbl=acctbl, world=self, region=reg_b: eval_json_rule(acctbl,state,world,region)
                                    print(f"registering access rule for {k} and {ik}" )
                            else:
                                rule_b = False
                        
                        if rule_a != False:
                            reg_a.connect(reg_b,f"{map.bspname} - {k} -> {ik}",rule_a)
                        if rule_b != False:
                            reg_b.connect(reg_a,f"{map.bspname} - {ik} -> {k}",rule_b)

                for k,v in mapregs.items():
                    if test_accessibility({v},set()):
                        reglocs = list()
                        print(v.locdata)
                        for ik,iv in v.locdata.items():
                            newlocname = f"{map.group} - {map.bspname} - {ik}"
                            reglocs.append(GMADVLocation(self.player,newlocname,self.location_name_to_id[newlocname],newreg))
                            self.locallocs += 1
                            print(f"created location {newlocname}")
                        v.locations = reglocs
                        self.multiworld.regions.append(v)
                    else:
                        self.add_warning(f"{v.name} was removed because it was impossible to reach")

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
            self.item_table[iname] = (self.item_name_to_id[iname],ItemClassification(info["fl"]),None)
            i = 0
            while i < info["amt"]:
                itempool.append(self.create_item(iname))
                i += 1

        for iname,amt in self.items_to_create.items():
            i = 0
            while i < amt:
                itempool.append(self.create_item(iname))
                i += 1

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

        self.add_warning(f"Unconnected Entrances: {str(unconnectedentrs)}")
        self.add_warning(f"Unconnected Exits: {str(unconnectedexits)}")
        self.add_warning(f"Unconnected Two-Ways: {str(unconnectedtwoways)}")

        # the menu is connected at the end because the reachtest function can't handle it 
        # and doing it like this is probably faster than making it check if every region it tests is not the menu

        print("connecting ",startreg, menu)
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


