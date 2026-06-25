from Utils import user_path, open_file
from pathlib import Path

apdir = Path(user_path("gmod_apadv/"))

def MapIndex(processout):

    mapgroups = processout[4]
    groupdata = processout[6]

    file = apdir.joinpath("mapindex.txt").open("w")

    for grname,gr in mapgroups.items():
        file.write(f"-------------------\n{grname}\n")
        if grname in groupdata:
            grdata = groupdata[grname]
            if "info" in grdata:
                grinfo = grdata["info"]
                if "requirements" in grinfo:
                    file.write(f"Requirements: {grinfo["requirements"]}\n")
                else:
                    file.write("Requirements: None\n")
            else:
                file.write("Requirements: None\n")
        else:
            file.write("Requirements: None\n")
        file.write("\n")

        for mapname,map in gr.items():
            file.write(f"\t{mapname}\n")
            mapinfo = map.info

            if "requirements" in mapinfo:
                file.write(f"\t\tRequirements: {mapinfo["requirements"]}\n")
            else:
                file.write("\t\tRequirements: None\n")

            itemtotal = 0
            itemunique = 0
            writequeue = list()

            for k,v in map.items.items():
                itemunique += 1
                itemtotal += v["amt"]
                writequeue.append(f"\t\t\t{k} x{v["amt"]}\n")

            if writequeue:
                file.write(f"\t\tMap Items: \t{itemtotal} total \t{itemunique} unique\n")
                file.writelines(writequeue)
                writequeue.clear()
            else:
                file.write("\t\tMap Items: None\n")

            loctotal = 0

            for k,v in map.regions.items():
                if "lctns" in v and v["lctns"]:
                    writequeue.append(f"\t\t\t{k}\n")
                    for loc in v["lctns"].keys():
                        writequeue.append(f"\t\t\t\t{loc}\n")
                        loctotal += 1

            if writequeue:
                file.write(f"\t\tLocations: \t{loctotal} total\n")
                file.writelines(writequeue)
                writequeue.clear()
            else:
                file.write("\t\tLocations: None\n")

            entrs = dict()
            exits = dict()
            twoways = dict()

            for k,v in map.entrances.items():
                reg = v["reg"]
                if reg in entrs:
                    entrs[reg].add(k)
                else:
                    entrs[reg] = {k}

            for k,v in map.exits.items():
                reg = v["reg"]
                if reg in entrs:
                    regentr = entrs[reg]
                    if k in regentr:
                        regentr.remove(k)
                        if not regentr:
                            del entrs[reg]
                        target = twoways
                    else:
                        target = entrs

                if reg in target:
                    target[reg].add(k)
                else:
                    target[reg] = {k}

            conntbls = [(entrs,"One-Way Entrance"),(exits,"One-Way Exit"),(twoways,"Two-Way Exits/Entrance")]

            for t in conntbls:
                if t[0]:
                    file.write(f"\t\t{t[1]}s:\n")
                    for k,v in t[0].items():
                        if v:
                            file.write(f"\t\t\t{k}\n")
                            for e in v:
                                file.write(f"\t\t\t\t{e}\n")
                else:
                    file.write(f"\t\t{t[1]}s: None\n")

            file.write("\n")

    open_file(apdir)

def ItemIndex(processout):

    from .ImpliedCapabilities import ProcessCapabs

    itemtbl = processout[0]
    file = apdir.joinpath("itemindex.txt").open("w")

    for setname,iset in itemtbl.items():
        file.write(f"-------------------\n{setname} - {iset.nicename}\n")
        if hasattr(iset,"requirements"):
            file.write(f"Requirements: {iset.requirements}\n")
        else:
            file.write("Requirements: None\n")

        file.write("\n")

        for iname,item in iset.items.items():
            file.write(f"\t{iname}\n")
            info = item.info

            if "capab" in info and info["capab"]:
                capabs = set(info["capab"])
                implied = ProcessCapabs(capabs).difference(capabs)
                file.write(f"\t\tBase Capabilities + (Implied): {info["capab"]} + ({implied or "None"})\n")
            else:
                file.write(f"\t\tBase Capabilities: None\n")

            if "condcapab" in info and info["condcapab"]:
                file.write(f"\t\tConditional Capabilities + (Implied):\n")
                for k,v in info["condcapab"].items():
                    capabs = set(v)
                    implied = ProcessCapabs(capabs).difference(capabs)
                    file.write(f"\t\t\t{k}: {v} + ({implied or "None"})\n")
            else:
                file.write("\t\tConditional Capabilities: None\n")

            #simplevals = [("wgt","Filler Weight"),("min","Minimum Placed"),("max","Maximum Placed")]
            #for val in simplevals:
            #    if val[0] in info and info[val[0]]:
            #        file.write(f"\t\t{val[1]}: {info[val[0]]}\n")

            if "wgt" in info:
                file.write(f"\t\tFiller Weight: {info["wgt"]}\n")
                mintxt = "min" in info and info["min"]
                maxtxt = "max" in info and info["max"]
                if mintxt or maxtxt:
                    file.write(f"\t\tMinimum/Maximum Placed: {mintxt or 0} / {maxtxt or "-"}\n")

            if "starttag" in info and info["starttag"]:
                file.write(f"\t\tStart Groups and Weight:\n")
                for k,v in info["starttag"].items():
                    file.write(f"\t\t\t{k}: \t{v}\n")
            file.write("\n")

    open_file(apdir)