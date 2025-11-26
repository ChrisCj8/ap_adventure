from BaseClasses import CollectionState

def eval_json_rule(rule,state : CollectionState,world,region):
    player = world.player
    #print("json rule evaluation",rule["type"])
    match rule["type"]:
        case "has":
            return state.has(rule["item"],player,rule["count"])
        case "or":
            #print(False)
            out = False
            for v in rule["nodes"]:
                if eval_json_rule(v,state,world,region):
                    out = True
                    #print(True)
                    break
            return out
        case "and":
            out = True
            for v in rule["nodes"]:
                if not eval_json_rule(v,state,world,region):
                    #print(False)
                    out = False
                    break
            return out
        case "bhop":
            if world.bhop_logic:
                if world.bhop == 3:
                    #print(True)
                    return True
                else:
                    #print(state.has("Bunnyhop",player))
                    return state.has("Bunnyhop",player)
            else:
                #print(False)
                return False
        case "mapitem":
            return state.has(f"{region.mapgroup} - {region.mapname} - {rule["item"]}",player,rule["count"])
        case "weapon":
            capab = list(rule["capab"].keys()) # could probably speed this up by doing this conversion earlier 
            #print(capab)
            #print(world.capabilitytbl)
            #print(world.capabilitytbl[capab[0]])
            if len(capab) == 0:
                #print(True)
                return True
            hascapabs = False
            if capab[0] in world.capabilitytbl:
                hascapabs = False
                #print(world.capabilitytbl[capab[0]])
                for item in world.capabilitytbl[capab[0]]:
                    #print(f"Do we have {item.name}? - {state.has(item.name,player)}")
                    if state.has(item.name,player):
                        allcapabs = True
                        for cap in capab:
                            #print(f"Is {cap} in {item.capabilities}? - {cap in item.capabilities}")
                            if not cap in item.capabilities:
                                allcapabs = False
                                break
                        if allcapabs:
                            hascapabs = True
                            break  
                
            if not hascapabs and region.ammo:
                #print(f"couldn't fullfill normal capability check, trying ammo capabilities for region {region}")
                for ammotype in region.ammo:
                    #print(f"trying ammo type {ammotype}")
                    if ammotype in world.ammocapabilitytbl:
        
                        for itemname,itemcapabs in world.ammocapabilitytbl[ammotype].items():
                            #print(f"testing ammo capabilities for {itemname}")
                            if state.has(itemname,player):
                                allcapabs = True
                                for cap in capab:
                                    if not cap in itemcapabs:
                                        allcapabs = False
                                        break
                                if allcapabs:
                                    hascapabs = True
                                    #print(f"{itemname} had the required capabilities")
                                    break
                                                     
            return hascapabs
        case _:
            #print(False)
            return False