# Advanced Options for apAdventure

apAdventure features some YAML options that are structured differently from what players might be used to in other apworlds.

## Cherrypicking and Blacklisting

Maps and items in apAdventure are normally grouped together for organization, but the cherrypicking and blacklisting options may be used in cases where you only want to add certain maps or items from a group to your run.

All of these options are structured similarly, so you can reference the defaults for the `config_blacklist` option as an example. Maps or items in the blacklist options that aren't included in previous options will not cause any errors.

Here are a few more examples:

- This would only give players the Gravity Gun and Bugbait from Half-Life 2, excluding other HL2 weapons. This could be useful when playing with a custom weapon set, so maps that require these items are still beatable.
  ```yaml
  item_cherrypick:
    hl2weps:
      - Gravity Gun
      - Bugbait
  ```
- This would remove the Crowbar from the item pool and replace it with the Stunstick from Half-Life 2: Deathmatch.
  ```yaml
  item_cherrypick:
    hl2dmweps:
      - Stunstick
  item_blacklist:
    hl2weps:
      - Crowbar
  ```
