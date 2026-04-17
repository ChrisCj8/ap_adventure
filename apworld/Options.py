from dataclasses import dataclass
from Options import Toggle, PerGameCommonOptions, Choice, OptionSet, Visibility, StartInventoryPool, OptionDict, OptionList, FreeText
from schema import Schema, Or

class McGuffinCount(FreeText):
    """Currently, the main goal of apAdventure is to collect all McGuffin items.
    This setting controls how many of these items will exist in the item pool.

    If this is set to a higher number than the amount of free space in
    the item pool the generator will only place as many as it can fit.
    """
    display_name = "McGuffin Count"
    default = 5

class Skill(Choice):
    """Sets the internal "skill" variable, which is mainly used for difficulty settings
    in the Half-Life games.

    In Half-Life: Source, enemies will gain more health and deal more damage at higher skill settings.

    In Half-Life 2, enemies will deal more damage at higher difficulties and ammo gain from pickups is reduced.

    Players will also deal less damage against enemies from both games at higher difficulties.
    (This may not be intended behavior for HL1 enemies, but this is how GMod handles it.)

    Outside of Half-Life, lua coders and map makers are also able to check what this value is set to 
    and have their code/maps behave differently depending on it, but this is not very common.
    """
    display_name = "Skill"
    option_easy = 1
    option_normal = 2
    option_hard = 3
    alias_medium = 2
    default = 2

class ConfigGroups(OptionSet):
    """Config Groups to use for generation.
    
    Map Configs are used by apAdventure to tell the generator what the maps the player wants to play on contain
    and where the gamemode should place exits, locations and whatever else the config creator wants to include
    in their Config.

    Configs are organized into groups so maps related to each other (such as maps from the same chapter in HL2)
    can be grouped together and share certain settings.
    """
    display_name = "Config Groups"
    default = {"orange_hub","canals_walk","ravenholm","coast_walk","nova_prospekt"}

singlepickschema = Schema(Or({
        str: Or(list, str)
    },{}))

class ConfigCherryPick(OptionDict):
    """This option allows you to cherrypick single maps from a Config Group.
    
    Check the options guide for more information on how this option works."""
    display_name = "Config Cherrypicking"
    default = {}
    schema = singlepickschema

class ConfigBlacklist(OptionDict):
    """This option allows you to pick maps from a Config Group that should not be added to your run.
    
    The defaults for this setting contain some maps that don't play very well in this mode, but still
    had configs made for them for the sake of covering all maps.
    
    Blacklisting maps that have not actually been added through the previous options
    should not cause problems.
    
    Check the options guide for more information on how this option works."""
    display_name = "Config Blacklist"
    default = {
        "ravenholm": ["d1_town_02a","d1_town_04"],
        "nova_prospekt": ["d2_prison_06"]
    }
    schema = singlepickschema

class StartGroup(FreeText):
    """What group your starting map should be picked from. Normally, your starting map is picked at random 
    from all maps that have starting points set, but this option lets you set a filter for a certain group.
    
    An empty string (the default setting) disables the filter.
    
    This option mainly exists for cases where the same map exists in multiple groups,
    you probably won't have to set this."""

    default = ""

class StartMap(FreeText):
    """The name of your starting map. Functions similarly to the start_group setting,
    but filters after the map name instead.

    Looks for the file name of the map. (ap_orange, gm_construct, etc., without extensions)
    
    Currently, apAdventure only includes a single starting map, so you won't have to set
    this option unless you have made your own configs with starting points."""

    default = ""

class StartRegion(FreeText):
    """If your selected starting map has start points placed in multiple regions,
    you can use this setting to chose what region you want to start in.
    
    The starting map included with apAdventure does not have multiple starting regions,
    so you can ignore this option unless you have made your own configs with
    multiple starting regions."""

    default = ""

class ItemSets(OptionSet):
    """Item Sets to use for generation.
    
    Similarly to Map Configs, Items related to each other are grouped together in Item Sets.
    
    The Generator will automatically check which of the items chosen are relevant to progression
    and remove items that are not logically required if there is not enough space for them.
    This process is not perfect though, the generator just checks if the item can fullfill
    any logic rule, but it doesn't check if there is another item that could also satisfy
    that rule, so if multiple items exist that can pass the same conditions the generator will
    keep all of then, even if the run could be beaten with only one of them."""
    display_name = "Item Sets"
    default = {"hl2weps","generic_filler","funny"}

class ItemCherryPick(OptionDict):
    """This option allows you to cherrypick single items from an Item Set.
    
    Check the options guide for more information on how this option works."""
    display_name = "Item Cherrypicking"
    default = {}
    schema = singlepickschema

class ItemBlacklist(OptionDict):
    """This option allows you to blacklist single items from an Item Set.
    
    Check the options guide for more information on how this option works."""
    display_name = "Item Blacklist"
    default = {}
    schema = singlepickschema

class AmmoMerge(OptionList):
    """This option allows ammo types to be merged together.

    Whenever the player gains or loses ammo for a merged type,
    all merged types will also be set to the same amount, and
    whenever ammunition of a merged type is available logically,
    the generator will also consider all merged types to be available.

    This feature mainly exists for Half-Life: Source, which uses
    separate ammo types from HL2. Note that not all HL2 ammo types
    have a HL:S counterpart.

    A list of all of GMods default ammo types can be found here:
    https://wiki.facepunch.com/gmod/Default_Ammo_Types
    
    Alternatively, apAdventure also provides a console command
    called "apadventure_dump_ammotypes" that will dump the names
    of all currently existing ammo types, which can be used to figure
    out the names of ammo types that have been added by addons."""
    display_name = "Ammo Merge"
    default = [
        ["Pistol","9mmRound"],
        ["Buckshot","BuckshotHL1"],
        ["357","357Round"],
        ["Grenade","GrenadeHL1"],
        ["SMG1_Grenade","MP5_Grenade"],
        ["RPG_Round","RPG_Rocket"],
    ]

class BunnyHop(Choice):
    """GMods Sandbox gamemode (which this gamemode derives from internally) normally clamps 
    the players movement speed when they jump off the ground to prevent Bunnyhopping. 

    Choosing "never" maintains this behavior, "item" removes it after
    receiving an item and "always" will disable it from the start.
    
    The latter two options also provide an autohop."""
    display_name = "Bunnyhop"
    option_never = 1
    option_item = 2
    option_always = 3
    default = 1

class BunnyHopLogic(Toggle):
    """Should the player be expected to Bunnyhop to reach certain areas?
    Ignored if bhop is set to "never"."""
    display_name = "Bunnyhop Logic"


class GeneratePUML(Toggle):
    """Generates a PlantUML Diagram showing all of the worlds regions and locations, 
    which may be helpful for debugging configs you've made."""
    display_name = "Generate PUML"

#class WriteDebug(Toggle):
#    """Saves some debug info."""
#    visibility = Visibility.none
#    display_name = "Debug Log"

@dataclass
class APADVGameOptions(PerGameCommonOptions):
    mcguffin_count: McGuffinCount
    skill: Skill
    bhop: BunnyHop
    bhop_logic: BunnyHopLogic
    config_groups: ConfigGroups
    config_cherrypick: ConfigCherryPick
    config_blacklist: ConfigBlacklist
    start_group: StartGroup
    start_map: StartMap
    start_region: StartRegion
    item_sets: ItemSets
    item_cherrypick: ItemCherryPick
    item_blacklist: ItemBlacklist
    ammo_merge: AmmoMerge
    generate_puml: GeneratePUML
    #write_debug: WriteDebug
    start_inventory_from_pool: StartInventoryPool