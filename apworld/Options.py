from dataclasses import dataclass
from Options import Toggle, PerGameCommonOptions, Choice, OptionSet, Visibility

class Skill(Choice):
    """What the \"skill\" ConVar will be set to. 
    
    This is mainly used for Half-Life 2s difficulty settings, which affect how much 
    ammo the player gets from pickups, among other things.

    Outside of HL2, lua coders and map makers are also able to check what this value is set to 
    and have their code/maps behave differently depending on it, but this isn't very common.
    """
    display_name = "Skill"
    option_easy = 1
    option_normal = 2
    option_hard = 3
    alias_medium = 2
    default = 2

class ConfigGroups(OptionSet):
    """Config Groups to use for generation."""
    default = {"test"}

class ItemSets(OptionSet):
    """Item Sets to use for generation."""
    default = {"funny"}

class BunnyHop(Choice):
    """GMods Sandbox gamemode (which this gamemode is derived off) normally clamps 
    the players movement speed when they jump off the ground to prevent Bunnyhopping. 
    This behavior may be disabled entirely or removed after the player receives an item."""
    display_name = "BunnyHop"
    option_never = 1
    option_item = 2
    option_always = 3
    default = 1

class BunnyHopLogic(Toggle):
    """Should the player be expected to BunnyHop to reach certain areas?
    Ignored if BunnyHop is set to \"never\"."""
    display_name = "BunnyHop Logic"


class GeneratePUML(Toggle):
    """Generates a PlantUML Diagram showing all of the worlds Regions and Locations, 
    which may be helpful for debugging."""
    display_name = "Generate PUML"

class WriteDebug(Toggle):
    """Saves some debug info."""
    visibility = Visibility.none
    display_name = "Debug Log"

@dataclass
class GMADVGameOptions(PerGameCommonOptions):
    skill: Skill
    bhop: BunnyHop
    bhop_logic: BunnyHopLogic
    config_groups: ConfigGroups
    item_sets: ItemSets
    generate_puml: GeneratePUML
    write_debug: WriteDebug