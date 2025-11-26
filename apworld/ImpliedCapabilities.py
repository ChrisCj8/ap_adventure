impliedcapabilities = {
    "WeakMelee": ["WimpyMelee"],
    "MidMelee": ["DecentMelee","WeakMelee","WimpyMelee"],
    "DecentMelee": ["MidMelee","WeakMelee","WimpyMelee"],
    "StrongMelee": ["DecentMelee","MidMelee","WeakMelee","WimpyMelee"],
    "WeakShortRange": ["WimpyShortRange"],
    "DecentShortRange": ["WeakShortRange","WimpyShortRange"],
    "StrongShortRange": ["DecentShortRange","WeakShortRange","WimpyShortRange"],
}