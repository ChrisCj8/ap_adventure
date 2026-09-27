# Setup Guide for apAdventure

## Requirements

- Familiarity with Archipelago - This is not a great first introduction for people who are new to AP. I would recommend playing a few other games in AP first to get a feel for how they work.
  - Knowing how to edit YAMLs manually is a hard requirement. This implementation features some non-standard YAML settings which the Web UI and Options Creator cannot handle.
- [Garry's Mod](https://store.steampowered.com/app/4000/Garrys_Mod/)
- *Optional*: [Half-Life 2](https://store.steampowered.com/app/220/HalfLife_2/) (the default configs are mainly made for this game's maps, you'll want it for your test run)
- [GWSockets](https://github.com/FredyH/GWSockets/releases) - More information on which version to grab can be found in the **[Installation (for Players)](#installation-for-players)** section.
- [GMAP](https://github.com/ChrisCj8/gm_ap/releases)
- [apAdventure](https://github.com/ChrisCj8/ap_adventure/releases) itself
- Other games or [workshop content](https://steamcommunity.com/workshop/browse?appid=4000) may be required depending on what configs were chosen for your run. apAdventure has a requirements system that you can use to check what you need in-game, and can create a addon preset for you to download/activate the required workshop items automatically.

## Installation (for Players)

1. Install [GWSockets](https://github.com/FredyH/GWSockets/releases)
    1. Grab the right version of GWSockets depending on your operating system and what version of GMod you're playing.

        Whether or not you need the 32 or 64-bit version of GWSockets doesn't depend on your OS, but on whether you're playing on the 64-bit branch of GMod. If you don't know what that means, just get both; GMod will automatically load the correct version.

        GMAP was mainly coded on GWSockets 1.3.0. 1.4.x should work but hasn't been tested much. Linux is completely untested.
    2. Navigate to your GMod install folder (right-click the game in your Steam Library, then click `Manage > Browse local files`).
    3. Put the `.dll` file(s) into `GarrysMod/garrysmod/lua/bin/`. The final path should be something like `GarrysMod/garrysmod/lua/bin/gmsv_gwsockets_<flavor>.dll`. (Yes, these `.dll` files do start with `gmsv`, even if you're not installing this on a server.)
2. Install [apAdventure](https://github.com/ChrisCj8/ap_adventure/releases) and [GMAP](https://github.com/ChrisCj8/gm_ap/releases)
    1. Get apAdventure and GMAP from their releases pages. The apAdventure release should contain a link to the GMAP release it depends on.
    2. Put both in your GMod addons folder. When everything is installed the final filesystem structure should look something like this:
        ```
        steamapps/common/GarrysMod/garrysmod/addons/
            apadventure/
                gamemodes/
                lua/
                ...
            gmap/
                lua/
                materials/
                resource/
        ```
    3. Install the apAdventure apworld like any other apworld.
    4. *Optional:* After starting the Archipelago Launcher with the apAdventure apworld installed, `gmod_apadv/gmodpath.txt` should have been created in your Archipelago install directory. Put the path to your GMod install folder into this file (the path should end with `../steamapps/common/GarrysMod/`). This lets Archipelago load map configs and item sets you create in GMod directly from your data folder (you won't have to copy them to your Archipelago folder every time you want to test them).

### Recommendations

I recommend disabling all unneeded GMod addons while playing apAdventure. While it is designed to be playable alongside as many addons as possible, you will be changing between maps quite often, and loading times can get very long if you have too many addons enabled.

## Hosting: Loading Custom Map Configs and Item Sets

While apAdventure will automatically load custom map configs and item sets from the GMod data folder if the player completed step 4 of the installation instructions, the host will not be able access these if they're not the one playing apAdventure. In this case, the logic data can be loaded from a subfolder in the Archipelago directory.

Whenever a map config is saved or item set is processed, GMod will write its logic data to the `GarrysMod/garrysmod/data/apadventure/logic/` folder. This data needs to be copied to `gmod_apadv/logic/` in the host's Archipelago installation folder.

Logic data from different players can be "merged" together, as long as all map groups and item sets using the same name are identical between all players.

> [!NOTE]
> Logic data in these folders can override logic data included in the apworld.
>
> If the host has a GMod path set in their `gmodpath.txt` file and is also loading logic data from`gmod_apadv/logic/`, the generator will prioritize loading the GMod folder files over the Archipelago folder.

## Playing

1. Once the Archipelago server is hosting, start Garry's Mod and select the **apAdventure** gamemode by clicking the button in the bottom right (which should say 'Sandbox' by default, but may say something else if you've been playing a different gamemode). This does not work while in-game, it must be done on the main menu.
2. Click **Start New Game**.
3. If you know what your starting map is (`ap_orange` with the default YAML settings), select it. Otherwise, select any map. (Leave 'Connection Preset' blank unless you've saved one previously.)
4. Once you're in-game, open the Context Menu (hold `C` or whatever you've bound it to) and click the Archipelago icon on the left side of the screen labelled **Connection**.
5. Enter your connection info into the window that just opened.
6. *Optional:* Save your connection info as a preset by entering a name for it at the bottom then clicking **Save Preset**. You can select presets in the **Connection** window and in GMod's map select (by typing the preset name).
7. Click **Connect**. You will be sent to the appropriate map automatically.
    - When reconnecting to an in-progress run, you can go straight to maps you have transitioned to. You can use this to "fast travel" between already-visited maps.
8. Once connected, click the **Check Requirements** button to open the requirements menu. This menu lets you check if all requirements needed for your run are installed. Further instructions on how to use this menu are found in-game.
9. *Optional*: In singleplayer, GMod's Lua environment is paused when the game is paused, causing you to temporarily lose connection to the AP server. Open the console and type `sv_pause_sp 0` to stop that. This also stops other players from being spammed with connection messages.

## Making Your Own Configs

apAdventure adds new Tool Gun modes and an editor to the Sandbox gamemode which can be used to create Map Configs. The new tools are located in the **apAdventure** tool category and the editor can be found by opening the Context Menu (normally opened by holding `C`) and clicking the Archipelago icon on the left side of the screen. More documentation for these tools is included in-game.

Configs can also have additional functionality added to them through config scripts. These scripts are automatically loaded from `**/lua/apadventure/cfglua/<config_group_name>/<map_name>.lua`. If you're a developer who wants to attempt to use this feature, you can try referencing existing scripts. Refer to **[Config Scripts](./cfglua_en.md)** for more information.

If you're a mapper who wants to make a custom map for apAdventure, the gamemode includes custom entities which you can place in your map to interact with Archipelago without coding knowledge. An `.fgd` for these custom entities is included in the releases.

## Custom Items

apAdventure allows custom items to be defined through Lua, but this feature is currently undocumented. If you want to try making custom items anyways, you can reference the existing item sets in `lua/apadventure/itemsets/`. Once you have created an item set in Lua, you can process it into logic data for the generator to read through the `apadventure_editor_processitemdefs "<set name>"` command in-game. This command will not work on the menu screen, it needs to be used in the Sandbox gamemode.

## Commands

Chat messages are prepended with players' in-game usernames, preventing them from using Archipelago chat commands. Prefix a chat message with `/ap` to bypass this; it will allow you to use Archipelago chat commands (e.g., `/ap !hint <group_name> - <map_name> - <item name>`). (This may require the player to be in the (super) admin usergroup depending on what `apadv_apsay_perms` is set to.)

All of the below are console commands.

### Any mode

- `apadventure_save_manager` - Opens a window that lets you manage local save data from apAdventure, which is created every time you connect to a new slot in a multiworld. You should clear these out occasionally. This window can also be accessed through the apAdventure editor window in Sandbox.
- `apadventure_dump_ammotypes` - Prints out the names of all ammotypes that currently exist in the game. This mainly exists to help people figure out the names of addon-added ammo types for the `ammo_merge` YAML option.

### Sandbox only

- `apadventure_patch_changelevel 0/1` - Controls whether or not apAdventure should replace `trigger_changelevel` brush entities with its own custom version, which disables its normal functionality and makes it visible to you, stopping you from accidentally triggering level transitions and making you more aware of where they are. Defaults to 0.
- `apadventure_patch_loadsaved 0/1` - Controls whether or not apAdventure should replace `player_loadsaved` point entities with its own custom version, which disables its normal functionality. These entities normally exist to reload the game whenever the player reaches a certain fail state, which may be triggered accidentally while editing configs, causing you to lose progress. Defaults to 0.
- `apadventure_editor_allow_static_overwrite 0/1` - Allows players to save maps into map groups that also exist in `data_static/` (the configs included with the apworld). Mainly exists to prevent people from accidentally overwriting stuff that they shouldn't. You can turn this on if you know what you're doing. Defaults to 0.
- `apadventure_editor_processitemdefs "<set name>"` - Converts an item set defined in Lua into a JSON format so the generator can use it. You won't need this if you're not making your own item sets.

### apAdventure only

- `apadv_apsay "<any text>"` - Functions like the `/ap` chat command, but works through the console instead.
- `apadv_apsay_perms 0/1/2` - Determines what usergroup the player needs to be in to use the `/ap` and `apadv_apsay` commands. Defaults to 1.
    - 0 - Everyone
    - 1 - (Super) Admins and Listen Host only
    - 2 - Super Admins and Listen Host only
- `adadv_slot_connect` - If connection info has already been sent to the GMod Server, re-connects to the Archipelago Server. Does nothing otherwise. Super Admins and Listen Host only.
- `adadv_slot_disconnect` - Disconnects the GMod Server from the Archipelago Server if it's connected. Does nothing otherwise. Super Admins and Listen Host only.
- `apadventure_mapiconmat_resolution` - What the resolution for map icon materials displayed on exits should be, as a power of two (8 = 256, 9 = 512, etc.). Map icons are rarely bigger than 512x512, so there's not much of a benefit to setting this higher than 9. Won't update until you load another map. Clientside.
