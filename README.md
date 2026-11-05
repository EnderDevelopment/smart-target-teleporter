# Teleport to Best Enemy (NPC)

A Roblox script pack that continuously teleports a player to the best (highest priority) alive enemy NPC. When that enemy dies, it automatically switches to the next-best alive enemy, and so on. Includes a draggable on/off GUI button for player control.

## Install

1. Place `src/Teleporter.lua` in `ServerScriptService`.
2. Place `src/TeleportButton.client.lua` in `StarterPlayerScripts` (or `StarterGui`).
3. Tag every enemy NPC with the `Enemy` CollectionService tag (in the model's Attributes, add the tag **Enemy**).

## Use

1. Adjust the priority list and settings at the top of `src/Teleporter.lua`:
   - `EnemyPriority` — ordered list of enemy names. The first is the "best".
   - `EnemyTag` — the CollectionService tag used to mark enemies. Set to `""` to match purely by `Humanoid.Name` instead.
   - `TeleportInterval` — seconds between teleport attempts (default `1`).
   - `ToggleEventName` — the name of the RemoteEvent used for on/off control.
2. Make sure each enemy NPC has a `Humanoid` with a name matching one in `EnemyPriority`.
3. When the game runs, players see a draggable button to toggle teleporting on/off.

The server automatically creates a `RemoteEvent` named `TeleportToggle` inside `ReplicatedStorage > Remotes` (folder created if missing). No manual RemoteEvent setup needed.

---

More Roblox script projects by EnderDevelopment: https://github.com/EnderDevelopment

Project page: https://dash.enderdevelopment.com/community/50e3e827-de2f-402e-8422-889a33901be2?utm_source=github&utm_medium=readme&utm_campaign=auto_publish&utm_content=50e3e827-de2f-402e-8422-889a33901be2
