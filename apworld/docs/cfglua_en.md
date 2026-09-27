# Config Scripts

Config Scripts can be used to add additional functionality to your configs using Lua.

## Organization

Whenever a config is loaded, the gamemode checks for a `.lua` file at `**/lua/apadventure/cfglua/<config_group_name>/<map_name>.lua` and runs it if it can find it.

> [!NOTE]
> In Gmod, all addon folders, workshop addons and mounted games are combined into a single file system when the game loads. You should **NOT** put your config scripts into the base `lua/` folder (`GarrysMod/garrysmod/lua/`) or apAdventure's `lua/` folder (`GarrysMod/garrysmod/addons/ap_adventure/lua/`), as this causes problems when GMod or apAdventure updates. Instead, create a new addon folder for your config scripts (e.g., `GarrysMod/garrysmod/addons/<addon_name>/lua/apadventure/cfglua/<config_group_name>/<map_name>.lua`).

## Execution

While you could theoretically run any code you want when your script is loaded into the config file, you most likely don't want all your code to execute immediately, because if your config is loaded after a map transition, GMAP may not have re-established the connection to the Archipelago Server yet. Instead, your config can return a table containing the functions that will be run at different times during or after loading your config.

The below code snippets are functionally identical.

```lua
--This code reads closer to how entity definitions work
local CFGLUA = {}

function CFGLUA:OnFullConnect()
  print('Run your code here')
end

return CFGLUA
```

```lua
--This code saves space
return {
  OnFullConnect = function(self)
    print('Run your code here')
  end
}
```

## Testing your Scripts

The gamemode loads your config script every time the config is loaded or reloaded, so you don't have to restart the map to test changes you've made to your script. The `apadv_loadcfg` console command can be used to reload your config instantly. You can also pass the name of a specific config group to load that group's config for the current map, but keep in mind that configs that aren't part of your current run won't have locations on them and may not behave correctly in other ways.

> [!NOTE]
> If you're reading this before the release of version 0.4.0, the `apadv_loadcfg` command is called `apadventure_loadcfg`, and it uses the wrong path to check if a config exists for the current map, so it will only work if you don't pass in any arguments.

## Available Events

### `CFGLUA:PreDupe( dupedata )`

This is the first function to run. It occurs after your config has been loaded, its rules (convars, player movement speed, etc.) have been applied, and all entities that were marked with the Deletion Marker Tool are deleted (but before saved entities are placed).

A table is passed into `dupedata` containing an `Entities` and `Constraints` field, which are later passed to [`duplicator.Paste()`](https://wiki.facepunch.com/gmod/duplicator.Paste) to load in the entities that were saved using the Save Marker Tool.

This function should return `dupedata`, unless you want to prevent these entities from being created or want to return a different table containing different duplication data. If nothing is returned, the config loader will skip the duplication step.

> [!NOTE]
> You are not guaranteed to be connected to the AP Server at this point, so functions that require a connection should not be used here.

### `CFGLUA:PostCfgLoad()`

This is the second to last function run. Unlike `OnFullConnect()`, it is guaranteed to run on the same tick as when the map is reset and the entities saved into your config have been created. It doesn't wait for a connection to be established, so this is intended to be used for code that needs to run as soon as possible.

### `CFGLUA:OnFullConnect()`

This function runs after the config has been loaded and the gamemode has connected to Archipelago. If the gamemode is already connected to Archipelago, it will run on the same tick as `PostCfgLoad()`, otherwise it will be delayed until a connection is established.

### `CFGLUA:CfgUnload()`

This function runs whenever your config is being unloaded, to either change map or config, or reload your config. It's a good place to clean up any hooks you registered for your config.

> [!NOTE]
> This function also runs when the player connects to a different slot, so don't try to interact with the AP Slot in here, as you may be interacting with the new slot.

### UNDOCUMENTED: `ItemFuncs` and `MapItemFuncs` tables

## Functions

apAdventure offers some functions that make interacting with locations easier:

### `APADV.SendMapLocation( lctn )`

Sends a map location, where `lctn` is the name of the location. Do not add the group/map name prefixes, as this function will automatically build the full name for you, thus your code will still work if the way location names are structured changes in the future.

### `APADV.GetMapLocationStatus( lctn )`

Gets whether a map location has been collected, where `lctn` is the name of the location (uses the same naming convention as `APADV.SendMapLocation()`). Returns `true`/`false` if the location exists in the current run and `nil` if it doesn't. If you register any hooks for your scripted locations, discard those that aren't needed using this as the conditional.
