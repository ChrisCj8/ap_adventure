# Config Scripts

Config Scripts can be used to add additional functionality to your configs using Lua.

## Organization

Whenever a config is loaded, the apAdventure gamemode checks for a Lua file at `**/lua/apadventure/cfglua/<config_group_name>/<map_name>.lua` and runs it if it can find it.

> [!NOTE]
> Because all addon folders, workshop addons and mounted games are combined into a single file system when the game loads, you should **NOT** put your config scripts into the base Lua folder (`GarrysMod/garrysmod/lua/`) or apAdventure's Lua folder (`GarrysMod/garrysmod/addons/ap_adventure/lua/`), as this will cause problems when GMod or apAdventure updates. Instead, create a new addon folder for your config scripts (e.g., `GarrysMod/garrysmod/addons/<addon_name>/lua/apadventure/cfglua/<config_group_name>/<map_name>.lua`).

## Execution

While you could theoretically run any code you want when your script is loaded into the config file, you most likely don't want your code to execute immediately, because if your config is loaded after a map transition, GMAP may not have re-established the connection to the Archipelago Server yet. Instead, your config can return a table containing the functions that will be run at different times during and after the config loading process.

The below code snippets are functionally identical. It is recommended you use the second snippet as a base, unless you know what you're doing.

```lua
local CFGLUA = {}

function CFGLUA:OnFullConnect()
  print('Run your code here')
end

return CFGLUA
```

```lua
return {
  OnFullConnect = function(self)
    print('Run your code here')
  end
}
```

## Testing your Scripts

The gamemode loads your config script every time the config is loaded or reloaded, so you don't have to restart the map to test changes you've made to your script. The `apadv_loadcfg` console command reloads your config instantly. You can also pass the name of a specific config group to load that group's config for the current map, but keep in mind that configs that aren't part of your current run won't have locations on them and may not behave correctly in other ways.

> [!NOTE]
> If you're reading this before the release of version 0.4.0, `apadv_loadcfg` is actually `apadventure_loadcfg`, and it uses the wrong path to check if a config exists for the current map, so it will only work if you don't pass in any arguments.

## Available Events

### `CFGLUA:PreDupe( dupedata )`

This is the first apAdventure config script function that is run. It occurs after your config has initially loaded, its rules (convars, player movement speed, etc.) have been applied, and all entities that were marked with the Deletion Marker Tool are deleted. Importantly, saved entities have not been placed at this point in time.

The `dupedata` argument is a table containing an `Entities` and `Constraints` field, which are later passed to [`duplicator.Paste()`](https://wiki.facepunch.com/gmod/duplicator.Paste) to load in the entities that were saved using the Save Marker Tool.

The function should return `dupedata`, unless you want to prevent these entities from being created or want to return a different table containing different duplication data. If nothing is returned, the config loader will skip the duplication step.

> [!NOTE]
> You are not guaranteed to be connected to the AP Server at this point, so functions that require a connection should not be used here.

### `CFGLUA:PostCfgLoad()`

This is the second config script function run. Unlike `OnFullConnect()`, it is guaranteed to run on the same tick as when the map is reset and the entities saved into your config have been created. It doesn't wait for a connection to be established, so this is intended to be used for code that needs to run as soon as possible. Use `APADV.SendMapLocation()` inside hooks within this function.

### `CFGLUA:OnFullConnect()`

This function runs after the config has been loaded and the gamemode has connected to Archipelago. If the gamemode is already connected to Archipelago, it will run on the same tick as `PostCfgLoad()`, otherwise it will be delayed until a connection is established. Use `APADV.GetMapLocationStatus()` within this function.

### `CFGLUA:CfgUnload()`

This function runs whenever your config is being unloaded, to either change map or config, or reload the current config. It's a good place to clean up any hooks and variables you registered for your config.

> [!NOTE]
> This function also runs when the player connects to a different slot, so don't try to interact with the AP Slot in here, as you may be interacting with the new slot.

### `ItemFuncs` and `MapItemFuncs`

These are tables of functions that are run for each set item and map item on load or when their quantity changes, where `iList` is an integer-indexed table (array) of the relevant received items.

> [!NOTE]
> These functions can run when the received quantity of an item is 0, so you can use the length of `iList` to stop execution if nothing should happen.

```lua
MapItemFuncs = {
  ['<map item name>'] = function(iList)
    if #iList == 0 then return end
    print(#iList, 'of the map item has been received, run your code here')
  end
}
```

## Functions

apAdventure provides some functions that make interacting with locations easier:

### `APADV.SendMapLocation( lctn )`

Sends a map location, where `lctn` is the name of the location. Do not add the group/map name prefixes, as this function will automatically build the full name for you, thus your code will still work if the way location names are structured changes in the future.

### `APADV.GetMapLocationStatus( lctn )`

Gets whether a map location has been collected, where `lctn` is the name of the location (uses the same naming convention as `APADV.SendMapLocation()`). Returns `true`/`false` if the location exists in the current run and `nil` if it doesn't. If you register any hooks for your scripted locations, discard those that aren't needed using this as the conditional.
