# apAdventure

**apAdventure** is a custom Archipelago gamemode for [Garry's Mod](https://store.steampowered.com/app/4000/Garrys_Mod/) designed so that people can play with its vast selection of Source Engine content (multiplayer supported). Being GMod, maps and assets from almost any Source Engine game ([Source 2013 engine branch](https://developer.valvesoftware.com/wiki/Source_2013#Source_2013_Singleplayer) and before) can be imported, in addition to the content from [GMod's Steam Workshop](https://steamcommunity.com/workshop/browse?appid=4000), allowing you to play, for example:

- Half-Life / Half-Life 2 maps
- Source movement maps (bunnyhopping and surfing for now, other Source movement tech may be implemented in the future)
- "Adventure saves" - Otherwise empty maps turned into mini-adventures with saved entities
- Minigames and more from the GMod Workshop

apAdventure provides players with a bunch of tools they can use in the Sandbox gamemode in any map to create a "Map Config", including...

- Entrances - Spawn points
- Exits - Map transitions
- Locations - Pickups or events
- Saving entities that support GMod's Duplication System

These map configs, made by the community, are fed into the Archipelago generator, which stitches all Entrances and Exits together to create a randomized campaign. Configs for some Half-Life 2 maps are included by default, though other map configs can be added by the player.

More advanced users can also...

- Use Lua to create custom items or [add additional behaviors](./cfglua_en.md) to the configs they make.
- Use Hammer, the Source Engine map editor, to incorporate a bunch of custom map entities into new custom maps, which add more complex behaviors without needing to know Lua.

## What items and locations are randomized in apAdventure?

Items in apAdventure are mainly weapons and 'Map Items'. Map items mostly take the form of door unlocks, though as their behaviour may be defined through Lua, they are able to do all sorts of things.

Items (especially weapons) have "Capabilities" assigned to them that access rules (e.g., locations and region connections) will look at to determine accessibility. Capabilities are designed this way (rather than being hard-coded item IDs) to allow custom items to fill in for their "vanilla" counterparts.

Locations are floating Archipelago icons by default, but it is possible for Lua coders and map makers to make any event (defined by code or Hammer I/O) into a "Dummy" location (these locations have no physical model). The built-in **Tracker** found in GMod's Context Menu lists all locations that exist and can be reached in all included maps.
