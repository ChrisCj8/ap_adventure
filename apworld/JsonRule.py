from BaseClasses import CollectionState

def eval_json_rule(rule,state : CollectionState,world,region):
    player = world.player
    #print("json rule evaluation",rule["type"])
    match rule["type"]:
        case "always":
            return True
        case "has":
            return state.has(rule["item"],player,rule["count"])
        case "hasany":
            for v in rule["items"]:
                if state.has(v,player):
                    return True
            return False
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
            capab = "capab" in rule and rule["capab"]
            if not capab:
                return alwaysnode
            if "override" in rule:
                ammomerge = world.ammomerge
                conds = set()
                for v in rule["override"]:
                    conds.add(v)
                    if v in ammomerge:
                        conds.update(ammomerge[v])
            else:
                conds = region.conditions

            candidates = set()
            capab1 = capab[0]

            if capab1 in world.capabilitytbl:
                for item in world.capabilitytbl[capab1]:
                    allcapabs = True
                    for cap in capab:
                        if not cap in item.capabilities:
                            allcapabs = False
                            break
                    if allcapabs:
                        candidates.add(item.name)

            for cond in conds:
                if cond in world.condcapabtbl:
                    for itemname,itemcapabs in world.condcapabtbl[cond].items():
                        allcapabs = True
                        for cap in capab:
                            if not cap in itemcapabs:
                                allcapabs = False
                                break
                        if allcapabs:
                            candidates.add(itemname)

            if not candidates:
                return nevernode

            world.usedcapabs.update(capab)
            if len(candidates) == 1:
                return {
                    "type":"has",
                    "item":candidates.pop(),
                    "count":1
                }
            return {
                "type":"hasany",
                "items":candidates
            }
        case "mapitem":
            if rule["count"] <= 0:
                return alwaysnode
            rule["type"] = "has"
            rule["item"] = f"{region.mapgroup} - {region.mapname} - {rule["item"]}"
            return rule
        case _:
            return rule