# Aim Trainer

A Valorant-feel aim trainer. The long-term goal is to replay real situations from your own recordings (e.g. a lost 1v3) so you can train that exact fight.

## Run

1. Install [Godot 4.3+](https://godotengine.org/download) (standard build).
2. Open Godot, then **Import** and pick this folder's `project.godot`.
3. Press **F5**.

Set `sensitivity` on the `Main` node (Inspector) to your Valorant sensitivity. Turn off Windows "Enhance pointer precision" so mouse counts match the game.

Controls: mouse to aim, left click to shoot, Esc to free the mouse.

## Test

```
godot --headless --quit-after 300 -s tests/test_main.gd
```

Prints `ALL PASSED` (exit code 0) or the failing checks (exit code 1).

## What matches Valorant now

- Sensitivity: 0.07° per mouse count × your sens, so cm/360 is the same as in-game
- 103° horizontal FOV
- Run speed 6.75 m/s, 150 HP, Vandal damage (head one-tap, 4 body shots)

## Roadmap

1. **Sim** (now): one strafing bot. Next: spread, recoil, fire rate, movement accel, more weapons.
2. **Scenario files**: a timeline of enemy positions and peeks, written by hand or clicked out of your footage.
3. **Auto-extraction**: a vision model reads your recording and fills the scenario file.
4. Stats over time, difficulty scaling, sharing scenarios.
