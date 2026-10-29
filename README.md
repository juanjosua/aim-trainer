# Aim Trainer

A Valorant-feel aim trainer. The goal: feed in a recorded Valorant video, pick a moment (e.g. a lost 1v3), and replay that exact situation in the trainer until you win it.

The app never touches the Valorant process (Vanguard anti-cheat); its only input is recorded video.

## Run

1. Install [Godot 4.3+](https://godotengine.org/download) (standard build).
2. Open Godot, then **Import** and pick this folder's `project.godot`.
3. Press **F5**.

Set `sensitivity` on the `Main` node (Inspector) to your Valorant sensitivity. Turn off Windows "Enhance pointer precision" so mouse counts match the game.

Controls: mouse to aim, hold left click to spray, Esc to free the mouse.

## Test

```
godot --headless --quit-after 300 -s tests/test_main.gd
```

Prints `ALL PASSED` (exit code 0) or the failing checks (exit code 1).

## What matches Valorant now

- Sensitivity: 0.07° per mouse count × your sens, so cm/360 is the same as in-game
- 103° horizontal FOV
- Run speed 6.75 m/s, 150 HP, Vandal damage (head one-tap, 4 body shots, legs 34)
- Vandal fire rate 9.75/s, first-shot error, spray error and recoil climb (rough numbers)

## Progress

**Layer 1, the sim: in progress**

- [x] Room, camera and mouse look with Valorant sensitivity and 103° FOV
- [x] Strafing bot (ADAD with random stops), shaped as a capsule stickman with head, body and leg hitboxes
- [x] Vandal damage, fire rate, full-auto, first-shot error, spray error and recoil climb
- [x] Back wall and bullet marks, so the spray pattern is visible
- [x] Stats HUD and a headless self-test
- [x] Runs on Windows with Godot 4.3

## Next steps

Each step stays playable on its own.

**Finish layer 1 (sim feels like Valorant)**

1. Tune Vandal spread and recoil against the real game by feel (the numbers are rough now).
2. Player movement (WASD) with Valorant run speed, moving inaccuracy and counter-strafing.
3. Recoil that decays gradually after you stop firing, instead of resetting at once.
4. Bot acceleration and deceleration, so its strafes feel like a real player.
5. More weapons (Phantom, Sheriff), with a key to switch.

**Layer 2: scenario files (replay a situation by hand)**

1. Define a scenario file (e.g. JSON): a simple room layout (cover boxes, not real maps), your start position, and per enemy a timeline of positions, speeds and peek times.
2. A loader that spawns enemies and moves them along their timelines; enemies shoot back after a reaction time, so you can lose.
3. Write the first scenario by hand from one of your clips (a 1v3), and play it on repeat.
4. A simple tool that plays your video frame by frame so you click each enemy's position, and writes the scenario file.

**Layer 3: auto-extraction (video in, scenario out)**

1. Collect and label Valorant frames (enemy red outlines help), then train a detector such as YOLO.
2. Estimate each enemy's 3D position from the 2D detection, using your crosshair, FOV and known agent height.
3. Track enemies across frames and write the timeline into a scenario file automatically.
4. Let the user fix wrong positions in the layer-2 click tool.

**Layer 4: training over time**

1. Save results per scenario (time to kill, accuracy, wins) and show progress.
2. Difficulty scaling (faster peeks, quicker enemy reactions).
3. Share scenario files with others.
