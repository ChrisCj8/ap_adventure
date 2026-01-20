impliedcapabilities = {
    "WeakMelee": ["WimpyMelee"],
    "MidMelee": ["DecentMelee"],
    "DecentMelee": ["MidMelee","WeakMelee"],
    "StrongMelee": ["DecentMelee"],
    "WeakShortRange": ["WimpyShortRange"],
    "DecentShortRange": ["WeakShortRange"],
    "StrongShortRange": ["DecentShortRange"],
    "WeakMidRange": ["WimpyMidRange"],
    "DecentMidRange": ["WeakMidRange"],
    "StrongMidRange": ["DecentMidRange"],
    "WeakLongRange": ["WimpyLongRange"],
    "DecentLongRange": ["WeakLongRange"],
    "StrongLongRange": ["DecentLongRange"],
    "ShortArcProjectile": ["TinyArcProjectile"],
    "MediumArcProjectile":["ShortArcProjectile"],
    "LongArcProjectile":["MediumArcProjectile"],
    "TinyExplosion": ["SmallOrSmallerExplosion","TinyOrLargerExplosion"],
    "SmallExplosion": ["SmallOrSmallerExplosion","SmallOrLargerExplosion"],
    "MediumSizeExplosion": ["MediumSizeOrSmallerExplosion","MediumSizeOrLargerExplosion","MediumOrSmallerExplosion","MediumOrLargerExplosion"],
    "LargeExplosion": ["LargeOrSmallerExplosion","MediumSizeOrLargerExplosion"],
    "MediumSizeOrSmallerExplosion": ["SmallOrSmallerExplosion"],
    "LargeOrSmallerExplosion": ["MediumOrSmallerExplosion"],
    "TinyOrLargerExplosion": ["SmallOrLargerExplosion"],
    "SmallOrLargerExplosion": ["MediumSizeOrLargerExplosion"],
}

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