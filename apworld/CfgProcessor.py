from settings import get_settings
import os
import json
from BaseClasses import ItemClassification


def ProcessCfgs():
    gmodpath = get_settings().gmod_apadv_options["gmodpath"]

    defdir = gmodpath+"/garrysmod/data/apadventure/logic/item/"
    defgroups = os.listdir(defdir)

    class ItemSet:
        def __init__(self,name,nicename):
            self.name = name
            self.nicename = nicename
            self.items = dict()

    class SetItem:
        def __init__(self,name,set,idef):
            self.name = name
            self.set = set
            self.long_name = f"{iname} - {set.nicename}"
            self.info = idef

    itemtypes = 0

    base_item_table = {
        "Nothing":( 1, ItemClassification.filler, None ),
        "McGuffin":( 2, ItemClassification.progression, None ),
        "Bunnyhop":( 3, ItemClassification.progression, None )
    }

    item_name_to_id = dict()

    locations = 0
    location_name_to_id = dict()

    for item in base_item_table:
        item_name_to_id[item] = base_item_table[item][0]
        itemtypes += 1

    duplicate_item_names = set()

    item_set_table = dict()

    for iset in defgroups:
        setpath = defdir+iset
        
        if os.path.isfile(setpath):
            print(f"processing {setpath}")
            setjson = json.load(open(setpath))
            nicename = setjson["name"]
            newiset = ItemSet(iset,nicename)
            if "items" in setjson and isinstance(setjson["items"], dict):
                
                for iname, idef in setjson["items"].items():
                    print(f"processing {iname}")
                    newitem = SetItem(iname,newiset,idef)
                    if iname in item_name_to_id:
                        duplicate_item_names.add(iname)
                    else:
                        itemtypes += 1
                        item_name_to_id[iname] = itemtypes

                    itemtypes += 1
                    item_name_to_id[newitem.long_name] = itemtypes

                    print("added item "+newitem.long_name)
                    newiset.items[iname] = newitem 
            item_set_table[iset[:-5]] = newiset
        else:
            print(f"{setpath} does not exist")

    cfgdir = gmodpath+"/garrysmod/data/apadventure/logic/cfg/"
    cfggroups = os.listdir(cfgdir)

    map_table = dict()

    foundgroups = 0

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

    for gr in cfggroups:
        grdir = cfgdir+gr
        if os.path.isdir(grdir):
            print("found group "+gr+" at "+grdir)
            foundgroups += 1
            foundmaps = os.listdir(grdir)
            
            groupmaps = dict()

            for map in foundmaps:
                print("processing "+map)

                newmap = GMADVMap(map,gr)
                mapdir = grdir+"/"+map
                if not os.path.isfile(mapdir+"/sv.json"):
                    #self.add_warning(f"could not find serverside save for {map} from {gr}")
                    continue
                if not os.path.isfile(mapdir+"/cl.json"):
                    #self.add_warning(f"could not find clientside save for {map} from {gr}")
                    continue
                cljson = json.load(open(mapdir+"/cl.json"))

                if "info" in cljson:
                    newmap.info = cljson["info"]

                for k,v in cljson["reg"].items():
                    v["lctns"] = dict()
                    newmap.regions[k] = v

                if not newmap.regions:
                    #self.add_warning(f"map {map} from {gr} has no regions, discarded")
                    continue
                
                newmap.internalConnections = cljson["connect"]

                svjson = json.load(open(mapdir+"/sv.json"))


                if "entr" in svjson:
                    for k,v in svjson["entr"].items():
                        if v["reg"] in newmap.regions:
                            newmap.entrances[k] = v
                            print("adding entrance "+k+" to map "+map)
                        else: 
                            print(f"map {map} from {gr} has an entrance placed in non-existing region \"{k}\"")

                if not newmap.entrances:
                    print(f"map {map} from {gr} has no entrances, discarded")
                    continue
                
                if "exit" in svjson:
                    for k,v in svjson["exit"].items():
                        if v["reg"] in newmap.regions:
                            newmap.exits[k] = v
                        else: 
                            print(f"map {map} from {gr} has an exit placed in non-existing region \"{k}\"")

                if "lctn" in svjson:
                    for k,v in svjson["lctn"].items():
                        if k in newmap.regions:
                            newmap.regions[k]["lctns"] = v
                            for lctnname in v.keys():
                                locations += 1
                                location_name_to_id[f"{gr} - {map} - {lctnname}"] = locations

                        else:
                            print(f"map {map} from {gr} has locations assigned to non-existing region \"{k}\"")

                if "start" in svjson:                    
                    for v in svjson["start"]:
                        if v in newmap.regions:
                            newmap.regions[v]["startcandidate"] = True
                        else:
                            print(f"map {map} from {gr} has starts defined for non-existing region \"{v}\"")

                if "item" in cljson:
                    mapitems = cljson["item"]
                    newmap.items = mapitems
                    for iname, item in mapitems.items():
                        itemtypes += 1
                        item_name_to_id[f"{gr} - {map} - {iname}"] = itemtypes
                    


                groupmaps[map] = newmap
                #del newmap, cljson, svjson
            map_table[gr] = groupmaps
        else:
            print("couldn't find group "+gr+" at "+grdir)
        

    if foundgroups == 0:
        raise RuntimeError("could not find any valid config groups")
    
    print(str(item_set_table))
    
    return (item_set_table, item_name_to_id, base_item_table, duplicate_item_names, map_table, location_name_to_id) # this sucks !
