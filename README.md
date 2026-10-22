# THE LAST ORDER

A Roblox tactical squad shooter prototype. **Humans vs Machines**, deliberate combat, personal AI squads, and objective control.

> **Prototype 0.1:** temporary R15 characters and an auto-generated arena. No purchased/free Toolbox models, no untrusted scripts, and no published Roblox place required to edit the code.

## Run in Roblox Studio

1. Create a new **Baseplate** experience in Roblox Studio (you can do this later).
2. Install [Rojo](https://rojo.space/) and the Rojo Studio plugin, then clone this repository.
3. From the repository directory run `rojo serve`, connect through the plugin in Studio, and press **Play**.
4. Alternatively run `rojo build -o TheLastOrder.rbxlx`, open the generated place in Studio, and press **Play**. Save/publish it to your experience when ready.

A simple arena, blue HUMAN bots, red MACHINE bots, and a central capture zone spawn automatically. As a player, use **WASD**, **left mouse** to fire, and **V** to toggle between tactical and first-person camera modes. This first iteration targets PC/Studio testing; mobile/controller controls come later.

**Current limitations:** bots can move toward the center, chase, and fire; tactical cover selection, squad ownership/orders, weapon models, real animation sets, respawn purchases, air support, full rounds, three maps and PvE matchmaking are NOT implemented yet. The capture status is visual/debug-only. Prototype code has not yet been executed in a Roblox place.

## Project layout

- `default.project.json` — Rojo mapping
- `src/shared/Config.lua` — all prototype tuning
- `src/server/Arena.lua` — test map created from Roblox parts
- `src/server/Main.server.lua` — authoritative server combat, bots and capture debug
- `src/client/Combat.client.lua` — tactical/FPS camera, test input and combat effects
- `docs/PROTOTYPE_0_1.md` — roadmap, testing checklist and known constraints

## Design direction

Core game: 1v1 / 2v2 / 3v3 and PvE (future), up to ten personally owned units per player, tactical pace, central objective B, temporary air support (helicopter vs drones), three maps (forest/city/warehouse), stylized factions, cosmetic monetization. No drivable vehicles.

The prototype is intentionally small and independent from `nivaRoblox`.
