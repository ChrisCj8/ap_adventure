from importlib import resources
from json import load

impliedcapabilities = load(resources.files(__package__).joinpath("impliedcapabilities.json").open())

def ProcessCapabs(capabin):
    newcapabs = capabin.copy()
    newamt = 0
    
    for capab in capabin:
        if capab in impliedcapabilities:
            implied = impliedcapabilities[capab]
            for newcap in implied:
                if not newcap in newcapabs:
                    newcapabs.add(newcap)
                    newamt += 1
    
    if newamt > 0:
        return ProcessCapabs(newcapabs)
    else:
        return newcapabs