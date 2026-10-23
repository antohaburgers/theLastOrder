# THE LAST ORDER — Projectile Combat 0.2

Implemented: 2026-10-23

## Design

Previously `fireRay` applied raycast damage immediately and only drew a
0.09-second tracer. There was no projectile velocity, so 60% of the old
speed was undefined. The starting reference speed is now 180 studs/second,
scaled by 0.60 for a real **108 studs/second** travelling projectile.

- All player/NPC firing uses `launchProjectile` on the server.
- `RunService.Heartbeat` advances each projectile and performs a swept
  raycast along that frame's entire segment; no teleport-through-cover.
- Damage applies at the impact frame, not when the trigger is pulled.
- The caster's character is excluded from collision; teammates/cover can
  intercept the shot. Only enemy humanoids receive damage.
- Range stays at 125 studs; previous weapon damage and cadence are unchanged.
- Clients receive `spawn`, `impact` and `expire` visual events. Render
  position is derived from synchronized server time, not an instantaneous ray.
- Client-only glowing projectiles, colored trails, muzzle flashes and hit
  sparks; no third-party scripts or weapon sound assets.
- Old shots expire at max range; clients have a timeout for lost VFX events.
- Shared speed tuning: `ProjectileBaseSpeed`, `ProjectileSpeedScale`,
  `ProjectileSpeed` in `Config.lua`.

## Manual Studio validation (not executed in this environment)

- [ ] Solo: fire from near and far; verify actual delay before enemy loses HP.
- [ ] Strafe across enemy fire at 30–65 studs: some shots should miss.
- [ ] Step behind cover after a bot fires: shot hits cover, not the player.
- [ ] Fire behind a moving enemy: no retroactive damage at original aim point.
- [ ] Shoot friendly NPC / concrete: no friendly damage, but projectile stops.
- [ ] Shoot enemy: correct original damage and red/orange impact spark.
- [ ] Shoot past all obstacles: visible projectile disappears by 125 studs.
- [ ] Check client tracers and server hits in a 2-player Studio test.
- [ ] Watch performance with 10, 20, 40 NPC; watch excessive VFX parts.
- [ ] Test when server FPS drops; bullets must not pass through targets.
- [ ] Validate rendering on low-end mobile and Xbox later.

If combat feels too easy/hard: adjust `Config.ProjectileSpeedScale`, not
only the client animation. Example scales: 0.50 = 90, 0.70 = 126 studs/s.
The player/AI aim currently does not lead moving targets (by design).
