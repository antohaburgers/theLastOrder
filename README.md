# THE LAST ORDER

A Roblox tactical squad shooter prototype. **Humans vs Machines**, deliberate combat, personal AI squads, and objective control.

> **Prototype 0.1:** temporary R15 characters and an auto-generated arena. No purchased/free Toolbox models, no untrusted scripts, and no published Roblox place required to edit the code.

## GitHub Actions build and Roblox publishing

Commits to `main` now trigger an automated Rojo build with a downloadable
`TheLastOrder.rbxlx` artifact. Roblox API publishing is prepared but
**not configured or performed** until THE LAST ORDER has its own Roblox
Universe/Place IDs and repository-scoped API key. Follow
[`docs/FIRST_PUBLISH.md`](docs/FIRST_PUBLISH.md). Auto-publishing stays OFF
unless deliberately enabled after initial testing.

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

## Projectile combat (2026-10-23)

Shots are now server-simulated projectiles instead of instant hitscan rays. Default
speed is **108 studs/s** (180 baseline × **0.60**), adjustable in
`src/shared/Config.lua`. Both player and NPC weapons share swept collision,
so movement/cover can avoid a hit before the bullet arrives. Clients draw
team-colored glowing bullets, short trails, muzzle flashes and impact sparks;
only the server applies damage. Refer to
`docs/PROJECTILE_COMBAT_0_2.md` for Studio validation.

**Status:** committed to the repository; Roblox Studio multiplayer/device
smoke tests and live place publishing have **not** been performed here.

## Design direction

Core game: 1v1 / 2v2 / 3v3 and PvE (future), up to ten personally owned units per player, tactical pace, central objective B, temporary air support (helicopter vs drones), three maps (forest/city/warehouse), stylized factions, cosmetic monetization. No drivable vehicles.

The prototype is intentionally small and independent from `nivaRoblox`.
