# THE LAST ORDER — Prototype 0.1

## Objective

First **technical smoke test**, not a complete game: two stylized factions made from temporary Roblox R15 rigs, a greybox map, autonomous NPCs moving toward a contested central objective, server-side raycast shooting, first-person/tactical camera switch.

## Design constraints (agreed)

- Humans vs robots, stylized and readable; no drivable vehicles.
- Final PvP: 1v1 / 2v2 / 3v3, up to 10 personal NPCs per commander; PvE later.
- Slower-paced tactical gunplay; cover and positioning matter.
- Commander sends orders by radio while alive; after death, surviving squad follows its last order with no new commands.
- Commander presence near the squad will give a small buff (planned).
- Players capture faster than NPCs.
- Central objective B rewards control with 30s helicopter (humans) or drone support (machines) later.
- Maps: forest, town and warehouse.
- Cosmetic personalization, leaderboard, lobby, increasing death timer (plus experimental paid respawn with competitive fairness review).

## Included in this commit

1. Pure Lua/Rojo project structure.
2. Test arena generated automatically, no imported models or scripts.
3. R15 humanoid NPCs from blank HumanoidDescription (NOT final assets).
4. 5 NPCs per faction, basic AI choosing nearby opponent and moving to center.
5. Basic line-of-sight combat, server-side raycast damage, client-only tracers.
6. Player auto-assigned to faction, spawn near corresponding base.
7. Keyboard/mouse test: WASD, LMB, V for tactical/first-person camera.
8. Capture point B shows debug state; capture does NOT yet trigger aviation or win conditions.

## Mandatory Studio smoke test

- [ ] Open a new Baseplate place in Roblox Studio and sync/build Rojo project.
- [ ] Press Play; arena and 10 R15 NPCs appear without runtime errors.
- [ ] Humans/robots advance toward center and shoot when they have line of sight.
- [ ] Check NPCs don't get stuck indefinitely and no critical pathfinding warnings.
- [ ] Press V; camera switches to FPS and back.
- [ ] LMB shoots; hits damage enemies but not allies.
- [ ] Walk to B; player capture progresses faster than single NPC.
- [ ] Use **Test > Start** with two players and verify team assignment.
- [ ] Check MicroProfiler/performance for 10, then 20, then 40 NPC.
- [ ] Test death and respawn to ensure no stale camera mode.
- [ ] Check rendering/movement and controls on real mobile device later.

## Important known limitations

- The NPC rigs are placeholders; no rifle models, loaded animation packs, voice, death ragdolls, or robot-specific visuals.
- NPCs can route around basic obstacles but have **no tactical cover selection, cover shooting, suppressive fire, formations or squad ownership/orders** yet.
- Dead NPCs are not respawned, so battles end after casualties. No match loop yet.
- Capture point is currently just a debug progress display; it can reach a team-held state but offers no bonus yet.
- Bot steering and sight accuracy need balancing; aiming and tracers are provisional.
- PC test client only; mobile/Xbox mapping and polished HUD are future work.
- All code is untested in Roblox Studio until a place is created; do not publish directly as a finished game.

## Next milestones

- 0.2: approved soldier/robot modular assets, rig/animation and safety audit, role-based accuracy.
- 0.3: ownable 10-NPC squads, Follow / Move / Attack / Defend / Capture, radio command UI.
- 0.4: actual B reward (30s support), base capture, player death/radio lock, first 2v2 match.
- 0.5: PvE commander, forest/city/warehouse variations, optimization toward 40–60 NPC.
- Later: cosmetics, honest monetization controls, lobby, leaderboards, production UI.

## Asset security rules

No arbitrary Toolbox model scripts. Audit all descendants (Script / LocalScript / ModuleScript), remove third-party executable content by default, and check rigs/animation ownership/licensing before import.
