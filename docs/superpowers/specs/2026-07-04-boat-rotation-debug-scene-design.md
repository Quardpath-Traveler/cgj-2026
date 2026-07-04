# Boat AD Rotation Debug Scene Design

## Purpose

Create an isolated, interactive debug scene for tuning the boat's AD-driven airborne rotation speed without interference from water, slopes, anchors, or level geometry.

## Context

- Boat script: `scripts/player/boat.gd`
- Relevant logic: `_physics_process()` lines 54-59 apply `airborne_rotation_torque` based on `Input.get_axis("move_left", "move_right")` while the boat is airborne and not anchored.
- Existing debug pattern: `debug/` directory already contains regression scenes (e.g. `AnchorSwingRegression`) that instantiate production scenes programmatically and print metrics.
- Project conventions: debug tooling should stay under `debug/` and avoid modifying production scripts or scenes.

## Requirements

1. **Interactive**: user holds A/D to rotate the boat in real time.
2. **Isolated environment**: pure airborne, no water/slope/anchor interactions.
3. **Full debug overlay**:
   - Real-time value panel.
   - Rotation direction/speed indicator.
   - Historical angular-velocity graph.
4. **Runtime parameter tuning**: adjust `airborne_rotation_torque` while the scene runs.
5. **No production-code pollution**: all new files live under `debug/`.

## Design

### Scene structure

`debug/BoatRotationDebug.tscn`

```
BoatRotationDebug (Node2D)
├── Camera2D
├── BoatContainer (Node2D)          # spawn position (0, 0)
└── CanvasLayer
    ├── DebugValuePanel
    ├── DebugGraph
    └── DebugRotationIndicator
```

The boat is instantiated at runtime from `res://scenes/player/Boat.tscn` so that changes to the boat scene do not couple back to the debug scene.

### Environment behavior

- Default state: position locked. Every physics frame the boat's `linear_velocity.y` is zeroed and its position is reset to `(0, 0)`, so tuning focuses purely on rotation.
- Optional free-fall: press `L` to toggle position locking and observe rotation under gravity.

### Debug components

#### DebugValuePanel (top-left, Label list)

Displays:

| Field | Source |
|---|---|
| Angular Velocity | `boat.angular_velocity` (rad/s) |
| Rotation | `boat.global_rotation_degrees` |
| Nose Angle | `boat.global_transform.x.angle()` |
| Input | `Input.get_axis("move_left", "move_right")` |
| Applied Torque | computed value sent to `apply_torque()` |
| Airborne | `boat.is_airborne()` |
| Position Locked | debug-scene state |

#### DebugGraph (bottom-left)

- Plots the last 180 frames of `angular_velocity`.
- Zero line drawn as a dashed reference.
- Positive values green, negative values red.
- Current `Rotation` shown as small text beside the graph.

#### DebugRotationIndicator (over the boat)

- Draws a forward-pointing arrow from the boat center.
- Arrow length scales with `abs(angular_velocity)` up to a capped maximum.
- Color: white when no input, blue for left rotation (A), orange for right rotation (D).

### Parameter tuning

Inspector exports on `BoatRotationDebug`:

- `rotation_torque_step: float = 5000.0`
- `position_locked: bool = true`
- `graph_sample_count: int = 180`

Runtime shortcuts:

| Key | Action |
|---|---|
| A / D | Rotate boat |
| PageUp / PageDown | Increase/decrease `boat.airborne_rotation_torque` by `rotation_torque_step` |
| L | Toggle position lock |
| R | Reset boat position, rotation, and velocities |
| Esc / Q | Quit scene |

## Files to create

```
debug/
├── BoatRotationDebug.tscn
├── boat_rotation_debug.gd
└── ui/
    ├── DebugValuePanel.tscn
    ├── DebugValuePanel.gd
    ├── DebugGraph.tscn
    ├── DebugGraph.gd
    ├── DebugRotationIndicator.tscn
    └── DebugRotationIndicator.gd
```

## Success criteria

- Scene opens and runs independently of the main game.
- Holding A/D produces visible rotation and real-time updates in all debug overlays.
- PageUp/PageDown changes torque and the new value is reflected immediately in the applied torque display.
- R resets the boat cleanly.
- No files outside `debug/` are modified.

## Future extensions (out of scope)

- Automated regression assertions (e.g. "reach 90° in N frames").
- Side-by-side comparison of two torque values.
- Recording and exporting rotation-response curves.
