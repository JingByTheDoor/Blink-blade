# Blink Blade

A room-based third-person action combo game built in Godot 4.5.

## Game Concept

Maintain a high-speed melee combo by blinking (teleport repositioning) between enemies. Blink does not deal damage—it's purely a positioning and tempo tool. Combat mastery is about choosing targets, staying in range, and never getting hit, because **any damage fully resets your combo**.

## Controls

| Action | Key/Button |
|--------|------------|
| Move | WASD |
| Camera | Mouse |
| Jump | Space |
| Light Attack | Left Mouse Button |
| Blink | Right Mouse Button |
| Dash | Left Shift |
| Pause | Escape |

## Project Structure

```
Blink-blade/
├── scenes/          # All game scenes (.tscn files)
│   ├── main/        # Main menu and game manager
│   ├── player/      # Player character and systems
│   ├── enemies/     # Enemy types
│   ├── rooms/       # Combat rooms (10 total)
│   ├── ui/          # HUD, menus, upgrade screen
│   └── effects/     # Visual effects
├── scripts/         # Standalone scripts
│   ├── autoload/    # Global singletons
│   ├── resources/   # Custom resource definitions
│   └── utils/       # Utility classes
├── resources/       # Resource instances
└── assets/          # Models, textures, audio
```

## Getting Started

1. Open the project in Godot 4.5
2. Run the main scene (`scenes/main/main_menu.tscn`)
3. Press "Start Run" to begin

## MVP Features

- [x] 3-hit light combo system
- [x] Blink repositioning with target selection
- [x] Dash for emergency movement
- [x] Combo counter with decay and damage reset
- [x] 2 enemy types (Grunt and Heavy)
- [x] 10 combat rooms with escalating difficulty
- [x] Upgrade system (every 3 rooms)
- [x] Scoring and results screen

## Replacing Placeholder Assets

See `ASSET_INTEGRATION_GUIDE.md` for detailed instructions on replacing placeholder assets with custom models, animations, and sounds.