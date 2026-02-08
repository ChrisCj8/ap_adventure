from BaseClasses import CollectionState

def eval_json_rule(rule,state : CollectionState,world,region):
    player = world.player
    #print("json rule evaluation",rule["type"])
    match rule["type"]:
        case "always":
            return True
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
            return state.has("Bunnyhop",player)
        case "capab":
            capab = rule["capab"]
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
                
            if not hascapabs and region.conditions:
                #print(f"couldn't fullfill normal capability check, trying conditional capabilities for region {region}")
                for cond in region.conditions:
                    #print(f"trying condition {cond}")
                    if cond in world.condcapabtbl:
        
                        for itemname,itemcapabs in world.condcapabtbl[cond].items():
                            #print(f"testing conditional capabilities for {itemname}")
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

nevernode = {
    "type": "never"
}

alwaysnode = {
    "type": "always"
}

def preprocess_json_rule(rule,world,region):
    rule = rule.copy()
    match rule["type"]:
        case "has":
            if rule["count"] <= 0:
                return alwaysnode
            return rule
        case "bhop":
            if world.bhop_logic:
                if world.bhop == 3:
                    return alwaysnode
                else:
                    return rule
            else:
                return nevernode
        case "and":
            i = 0
            nodes = rule["nodes"]
            for v in nodes:
                v = preprocess_json_rule(v,world,region)
                if v == nevernode:
                    return nevernode
                if v == alwaysnode:
                    nodes.pop(i)
                i += 1
            if not nodes:
                return alwaysnode
            if len(nodes) == 1:
                return nodes[0]
            return rule
        case "or":
            i = 0
            nodes = rule["nodes"]
            for v in nodes:
                v = preprocess_json_rule(v,world,region)
                if v == alwaysnode:
                    return alwaysnode
                elif v == nevernode:
                    nodes.pop(i)
                else:
                    i += 1
            if not nodes:
                return nevernode
            if len(nodes) == 1:
                return nodes[0]
            else:
                return rule
        case "capab":
            world.usedcapabs.update(rule["capab"])
            return rule
        case "mapitem":
            if rule["count"] <= 0:
                return alwaysnode
            rule["type"] = "has"
            rule["item"] = f"{region.mapgroup} - {region.mapname} - {rule["item"]}"
            return rule
        case _:
            return rule