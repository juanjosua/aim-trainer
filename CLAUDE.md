# CLAUDE.md

Valorant-feel aim trainer in Godot 4.3 (GDScript). The goal: replay real fights from my own recordings (e.g. a lost 1v3) and train that exact situation. Aim and physics only; visuals stay simple shapes.

This is a lifelong hobby project, so keep each step small and playable. Background and the reasoning behind decisions: `docs/decisions.md`. Roadmap: `README.md`.

## Working style

- Smallest change that fully works. No abstractions, options or "for later" code nobody asked for.
- Known limits get a code comment: `# shortcut: <the limit>, <when to upgrade>`.
- New non-trivial logic gets a check in `tests/test_main.gd`.
- Comment only the why the code can't show.
- End replies with what was skipped or unchecked and any risk.

## Layout

- `project.godot`: main scene is `main.tscn`; vsync is off to cut input latency.
- `main.tscn`: a single `Main` node; `main.gd` builds the whole scene in code (light, floor, back wall, camera, bot, HUD).
- `main.gd`: mouse look (`counts_to_degrees`), full-auto Vandal (`_process` + `trigger`), hitscan `shoot()` with spread and recoil (`spray` counts shots in the current spray), bullet marks, stats, HUD.
- `bot.gd`: strafing capsule stickman; each limb is a StaticBody3D tagged `set_meta("part", "head"|"body"|"legs")`, hitbox = visible mesh; `hit(part)` returns true on a kill.
- `tests/test_main.gd`: SceneTree self-test.

## Commands

```
godot --headless --import                                  # first time, builds .godot/
godot --headless --quit-after 300 -s tests/test_main.gd    # prints ALL PASSED, exit 0/1
```

Always pass `--quit-after`: a script error makes the test hang forever otherwise.

## Conventions and gotchas

- 1 Godot unit = 1 metre. Camera at eye height 1.6 m, which is also the bot's head-centre height, so straight ahead = head-level crosshair.
- Mouse: use `event.screen_relative` (unscaled counts), not `relative`.
- Camera uses `keep_aspect = KEEP_WIDTH` so `fov` is horizontal (Valorant's 103°).
- In tests, `await process_frame` after `root.add_child(...)` before touching the node (its `_ready` hasn't run yet), and `await physics_frame` twice after moving a body before raycasting.
- Headless test prints `Parameter "m" is null` (dummy renderer, at shutdown, from primitive meshes) after `ALL PASSED`; harmless, exit code is still 0.
- In tests set `main.spray = 0` before a shot: tests fire instantly, which otherwise counts as one long spray.
- Recoil offsets the bullet ray, not the camera, like Valorant.
- Never read from or hook into the Valorant process (Vanguard anti-cheat). Input to this app is recorded video only.

## Status

Layer 1: one room, one ADAD-strafing stickman bot, Valorant sens/FOV/damage, stats. Runs on my Windows PC (Godot 4.3 via winget). Vandal fire rate, first-shot error, spray error and a recoil climb are in, with made-up numbers.

Next:
1. Tune the Vandal recoil/spread numbers against the real game by feel.
2. Player movement (WASD) with moving inaccuracy; recoil that decays instead of resetting.
3. Bot acceleration/deceleration (counter-strafe feel).
4. Then layer 2: scenario files.
