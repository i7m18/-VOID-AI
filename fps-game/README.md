# VOID FRONTLINE — FPS Prototype

A Godot 4 starter for an Android-oriented first-person military shooter. This is a playable prototype built from primitive 3D geometry; it is not a finished photorealistic game.

## Run
1. Install Godot 4.3 or newer.
2. Import `project.godot`.
3. Press F6/F5 to run `scenes/main.tscn`.

## Prototype features
- First-person camera and mouse look (desktop prototype controls)
- Move, jump, hitscan rifle, ammo and reload
- Enemies chase the player and deal contact damage
- Health/ammo/mission HUD
- Mission completion when enemies are cleared

## Controls
WASD move, mouse look, left mouse fire, R reload, Space jump, Esc release mouse.

## Android
This is a source project, not an APK yet. To export Android, install Godot export templates and Android build prerequisites, then configure an Android export preset. Mobile touch controls and device performance testing are still required before calling it Android-ready.

## Planned next
Touch joystick/buttons, proper animated weapon models, navigation-based enemy AI, vehicle controller, authored levels, sound, optimized assets, save/checkpoint system.
