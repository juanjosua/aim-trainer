# Background and decisions

## Why this project

I wanted a lifelong hobby project, inspired by Linus Torvalds building Linux as a hobby and still working on it. I have a CS background and program.

What makes a project last for decades:
- You use it yourself, so you keep finding what's missing.
- It starts tiny.
- It has no ceiling; there's always a harder layer.
- It doesn't need other people to start.

Ideas considered:
- **JARVIS-style AI assistant.** Training my own model from scratch is the weak part: compute and data heavy, and outdated within a year. If I ever do it, build the shell (tools, memory, automation) around a swappable model instead.
- **Own language, hobby OS, game engine, emulator/database/editor.** All valid lifelong options.
- **Chosen: Valorant aim trainer that replays scenarios from my own recordings.** I'd use it myself, and it has real depth (game physics, then computer vision).

## The concept

Record myself playing (e.g. a 1v3 I lost), then recreate that same situation to train it. I don't need visuals, only the physics, so it mimics the real game for aim.

Aim Lab and Kovaak's already exist. The edge here is replaying *my own* real situations.

## Key decisions

- **Engine: Godot 4.3 + GDScript.** Free, open source, good 3D, easy scripting; likely still around in 20 years.
- **Build in layers, each one playable on its own.** Turning video into a scenario is the hardest part (2D footage to 3D enemy positions over time needs computer vision), so it comes last. Starting there would stall for months with nothing playable.
  1. Sim with Valorant-like physics (done: basic version).
  2. Scenario file: a timeline of enemy positions, speeds and peek times. Written by hand first, then by clicking enemy positions frame by frame in my footage.
  3. Auto-extraction: a vision model (e.g. YOLO) trained on Valorant frames fills the scenario file. Valorant's red enemy outlines help detection.
  4. Stats over time, difficulty scaling, sharing scenarios.
- **No game hooking.** The app only reads recorded video, never the Valorant process, so it stays clear of Vanguard.

## Valorant numbers

| Value | Used | Verified? |
|---|---|---|
| Yaw per mouse count | 0.07° × sens (same as CS) | Widely known; check by comparing a 360 turn in-game |
| Horizontal FOV | 103° | Known fixed value |
| Run speed (rifle) | 6.75 m/s | Unverified |
| Health + full shields | 150 | Known |
| Vandal damage | 160 head, 40 body, 34 legs | Unverified (no distance falloff modelled) |
| Vandal fire rate | 9.75 rounds/s | Widely known |
| Vandal first-shot error | 0.25° | Unverified |
| Vandal spray | +0.15° error per shot (max 1.5°), climbs 0 to 3.2° over 8 shots, resets after 0.35 s | Made up; tune by feel |
| Player acceleration | 40 m/s² (full speed or full stop in ~0.17 s) | Made up; tune by feel |
| Moving error | up to +5° at run speed; none below 1.4 m/s | Made up; tune by feel |
| Eye / head height | 1.6 m | Guess |
| Hitboxes | stickman: head sphere r 0.15 m, torso capsule r 0.15 m, arm capsules r 0.05 m (body damage), leg capsules r 0.08 m | Guess; slimmer than a real agent |

Riot doesn't publish all weapon and movement numbers, so expect to tune by feel against the real game. That tuning never ends, and that's fine.

## Honest limits

- Many lost 1v3s come from positioning, utility or decisions, not aim. This trains crosshair placement and peek fights, not everything.
- On Windows, turn off "Enhance pointer precision" or mouse counts won't match the game.
