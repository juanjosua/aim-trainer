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
- `main.tscn`: a single `Main` node; `main.gd` builds the whole scene in code (light, floor, camera, bot, HUD).
- `main.gd`: mouse look (`counts_to_degrees`), hitscan `shoot()`, stats, HUD.
- `bot.gd`: strafing bot with `head` and `body` StaticBody3D parts tagged with `set_meta("part", ...)`; `hit(is_head)` returns true on a kill.
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
- Never read from or hook into the Valorant process (Vanguard anti-cheat). Input to this app is recorded video only.

## Status

Layer 1 is done: one room, one ADAD-strafing bot, Valorant sens/FOV/damage, stats. Only tested headless in the cloud; the feel and raw mouse input on my Windows PC are **not yet verified**.

Next:
1. Play it on Windows and compare a 360 turn with Valorant.
2. Spread (moving and first-shot inaccuracy), recoil, fire rate, starting with the Vandal.
3. Bot acceleration/deceleration (counter-strafe feel).
4. Then layer 2: scenario files.
