# Asset Integration Guide

This guide explains how to replace placeholder assets with your custom 3D models, animations, textures, and audio.

## Player Character

### Current Placeholder
The player is currently a capsule mesh with basic collision.

### Replacing with Custom Model

1. **Export your model** from Blender/Maya as `.glb` or `.gltf` format
2. **Place the file** in `assets/models/player/`
3. **Open** `scenes/player/player.tscn`
4. **Replace the MeshInstance3D**:
   - Delete the current `PlayerMesh` node
   - Drag your `.glb` file into the scene
   - Rename it to `PlayerMesh`
   - Ensure it's a child of the root `Player` node

### Animation Requirements

Your player model should include these animations:

| Animation Name | Description | Loop |
|----------------|-------------|------|
| `idle` | Standing idle | Yes |
| `run` | Running forward | Yes |
| `jump` | Jump up | No |
| `fall` | Falling down | Yes |
| `attack_1` | First combo hit | No |
| `attack_2` | Second combo hit | No |
| `attack_3` | Third combo finisher | No |
| `dash` | Dash movement | No |
| `hit` | Taking damage | No |
| `death` | Death animation | No |

## Enemies

### Grunt
- Place model in `assets/models/enemies/grunt/`
- Required animations: `idle`, `walk`, `attack`, `hit`, `death`, `stagger`

### Heavy
- Place model in `assets/models/enemies/heavy/`
- Required animations: `idle`, `walk`, `attack_windup`, `attack`, `hit`, `death`

## Audio

Place audio files in `assets/audio/sfx/`:
- `attack_1.wav`, `attack_2.wav`, `attack_3.wav`
- `blink.wav`, `dash.wav`
- `hit_player.wav`, `hit_enemy.wav`, `enemy_death.wav`
- `combo_milestone.wav`, `combo_break.wav`
- `upgrade_select.wav`, `door_open.wav`

Music in `assets/audio/music/`:
- `menu.ogg`, `combat.ogg`, `results.ogg`