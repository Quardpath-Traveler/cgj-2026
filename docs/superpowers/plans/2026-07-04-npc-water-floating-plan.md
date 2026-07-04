# NPC Water Floating and Drifting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make NPCs float on animated water surfaces and drift slowly along the water flow direction using a kinematic, animation-driven approach.

**Architecture:** Each NPC instance is an independent scene with a `FloatingNPC` script that detects the `WaterSurface` it overlaps, queries that surface for animated height and flow direction, and updates its own position every physics frame. `WaterSurface` only adds a height-query helper; existing boat physics remains untouched.

**Tech Stack:** Godot 4.7, GDScript, Jolt Physics 2D.

## Global Constraints

- Engine: Godot 4.7, Jolt Physics, Forward Plus renderer.
- All `main` pushes go through a Pull Request; never push directly to `main`.
- Code owns `.gd`, `.cs`, `.tscn` node structure, and `project.godot`.
- Smoke-test the project in Godot before marking a PR ready.
- Save and close Godot before committing.
- Stage `.gd.uid` files together with their `.gd` scripts.
- Pull with rebase before pushing: `git pull --rebase origin main`.

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `scripts/level_parts/water_surface.gd` | Modify | Add public `get_surface_height_at_global_position()` helper that samples the animated surface at a given world X and returns the world Y height. |
| `scripts/characters/floating_npc.gd` | Create | New script attached to `NPC.tscn`. Detects overlapping `WaterSurface`, aligns NPC to animated surface height, drifts along flow direction, flips sprite. |
| `scenes/characters/NPC.tscn` | Modify | Attach `FloatingNPC`, add `WaterDetector` Area2D with CollisionShape2D, wire exported node references. |
| `debug/DebugLevel.tscn` | Modify (test only) | Temporarily place an NPC instance in water for smoke testing; revert before final commit or keep as part of level design if desired. |

---

### Task 1: Add WaterSurface height query helper

**Files:**
- Modify: `scripts/level_parts/water_surface.gd:183`

**Interfaces:**
- Produces: `func get_surface_height_at_global_position(global_position: Vector2) -> float`

- [ ] **Step 1: Open `scripts/level_parts/water_surface.gd`**

- [ ] **Step 2: Insert the helper after `get_boat_target_rotation()`**

```gdscript
## Returns the animated water surface world Y coordinate at the given world X position.
func get_surface_height_at_global_position(global_position: Vector2) -> float:
    var local_position := to_local(global_position)
    return to_global(Vector2(local_position.x, _sample_surface_y(local_position.x))).y
```

Insert it around line 183, after `get_boat_target_rotation()` and before `get_mass_force_scale()`.

- [ ] **Step 3: Verify in Godot editor**

1. Open the project in Godot.
2. Open `scenes/level_parts/WaterSurface.tscn`.
3. Select the `WaterSurface` node.
4. In the Remote/Editor debugger, run any scene containing a water surface.
5. From another script or the debugger, call `get_surface_height_at_global_position(Vector2(0, 0))` on the water instance.
6. Expected: returns a `float` close to `surface_y` plus wave offset.

- [ ] **Step 4: Commit**

```bash
git add scripts/level_parts/water_surface.gd
git commit -m "feat(water): add surface height query for NPC floating

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Create FloatingNPC script

**Files:**
- Create: `scripts/characters/floating_npc.gd`
- Create: `scripts/characters/floating_npc.gd.uid` (Godot generates this automatically when saving the script in the editor)

**Interfaces:**
- Consumes: `WaterSurface.get_surface_height_at_global_position(global_position: Vector2) -> float`, `WaterSurface.get_water_flow_direction() -> Vector2`, `WaterSurface.current_flow_speed: float`
- Produces: `class_name FloatingNPC` with exported `drift_speed_multiplier`, `vertical_offset`, `detection_area`, `sprite`

- [ ] **Step 1: Create directory if missing**

```bash
mkdir -p /Volumes/takusan/projects/cgj-2026/.worktrees/design/main-level/scripts/characters
```

- [ ] **Step 2: Write `scripts/characters/floating_npc.gd`**

```gdscript
class_name FloatingNPC
extends Node2D

## Multiplier applied to the water's current_flow_speed to determine drift speed.
@export var drift_speed_multiplier: float = 0.6
## Local offset applied to the surface height so the sprite base sits on the water.
@export var vertical_offset: float = 0.0
## Area2D used to detect overlapping WaterSurface instances.
@export var detection_area: Area2D
## Sprite to flip based on drift direction.
@export var sprite: Sprite2D

var _current_water: WaterSurface = null

func _ready() -> void:
    if detection_area == null:
        push_error("FloatingNPC: detection_area is not assigned on %s" % name)
    if sprite == null:
        push_error("FloatingNPC: sprite is not assigned on %s" % name)


func _physics_process(_delta: float) -> void:
    _update_current_water()
    if _current_water == null:
        return

    _align_to_surface()
    _drift_with_current(_delta)
    _update_facing()


func _update_current_water() -> void:
    if detection_area == null:
        _current_water = null
        return

    for area in detection_area.get_overlapping_areas():
        if area is WaterSurface:
            _current_water = area
            return

    _current_water = null


func _align_to_surface() -> void:
    var surface_height := _current_water.get_surface_height_at_global_position(global_position)
    global_position.y = surface_height + vertical_offset


func _drift_with_current(delta: float) -> void:
    var flow_direction := _current_water.get_water_flow_direction()
    var drift_speed := _current_water.current_flow_speed * drift_speed_multiplier
    global_position += flow_direction * drift_speed * delta


func _update_facing() -> void:
    var flow_direction := _current_water.get_water_flow_direction()
    if flow_direction.x < 0.0:
        sprite.flip_h = true
    elif flow_direction.x > 0.0:
        sprite.flip_h = false
```

- [ ] **Step 3: Save in Godot editor to generate `.uid`**

1. Open Godot.
2. Use `File > New Script` or create the file externally and drag it into the FileSystem dock.
3. Save the script in the editor. Godot will create `scripts/characters/floating_npc.gd.uid` automatically.

- [ ] **Step 4: Verify script parses**

In Godot, open `scripts/characters/floating_npc.gd`. There should be no parse errors in the script editor.

- [ ] **Step 5: Commit**

```bash
git add scripts/characters/floating_npc.gd scripts/characters/floating_npc.gd.uid
git commit -m "feat(npc): add FloatingNPC script for water surface drifting

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Update NPC scene

**Files:**
- Modify: `scenes/characters/NPC.tscn`

**Interfaces:**
- Consumes: `scripts/characters/floating_npc.gd`

- [ ] **Step 1: Open `scenes/characters/NPC.tscn` in Godot**

- [ ] **Step 2: Add an Area2D child named `WaterDetector`**

1. Right-click the root `NPC` node.
2. `Add Child Node` > `Area2D`.
3. Rename it to `WaterDetector`.

- [ ] **Step 3: Add a CollisionShape2D under `WaterDetector`**

1. Right-click `WaterDetector` > `Add Child Node` > `CollisionShape2D`.
2. In the Inspector, assign a `RectangleShape2D`.
3. Set the shape size to roughly match the NPC sprite's lower body, e.g. `Vector2(32, 16)`.
4. Position the shape so its top edge is near the sprite's base. The sprite's pivot is at its center, offset by `position = Vector2(0, -33)`, so place the collision shape around `Vector2(0, -8)` to sit at the sprite's feet.

- [ ] **Step 4: Configure collision layers and masks**

1. Select `WaterDetector`.
2. Set `Collision > Layer` to `0` (no layers; NPC detector does not need to be detected by others).
3. Set `Collision > Mask` to the same layer that `WaterSurface` uses for its `Collision > Layer`. By default this is often layer 1, but check the `WaterSurface.tscn` CollisionShape2D's layer to be sure.

- [ ] **Step 5: Attach `FloatingNPC` to the root `NPC` node**

1. Select the root `NPC` node.
2. In the Inspector, attach script `scripts/characters/floating_npc.gd`.
3. Assign the exported fields:
   - `Detection Area`: drag `WaterDetector` into the slot.
   - `Sprite`: drag the existing `Sprite2D` into the slot.
   - `Drift Speed Multiplier`: `0.6`
   - `Vertical Offset`: adjust so the sprite base sits on the water. Start with `0.0` and tweak after observing.

- [ ] **Step 6: Save the scene**

Press `Ctrl+S` / `Cmd+S`.

- [ ] **Step 7: Verify `.tscn` content**

Close Godot and inspect `scenes/characters/NPC.tscn`. It should contain:

- `[ext_resource type="Script" path="res://scripts/characters/floating_npc.gd" id="..."]`
- A `WaterDetector` node of type `Area2D`.
- A `CollisionShape2D` child under `WaterDetector`.
- The root node referencing the `FloatingNPC` script and exported node paths.

- [ ] **Step 8: Commit**

```bash
git add scenes/characters/NPC.tscn
git commit -m "feat(npc): attach FloatingNPC and water detector to NPC scene

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Smoke test in DebugLevel

**Files:**
- Modify (temporary): `debug/DebugLevel.tscn`

**Interfaces:**
- Consumes: `scenes/characters/NPC.tscn`, existing `scenes/level_parts/WaterSurface.tscn`

- [ ] **Step 1: Open `debug/DebugLevel.tscn` in Godot**

- [ ] **Step 2: Add an NPC instance**

1. Drag `scenes/characters/NPC.tscn` into the level.
2. Place it somewhere inside an existing `WaterSurface` area.
3. Save the scene.

- [ ] **Step 3: Run the scene**

Press `F6` (Play Current Scene) or click the Play button with `DebugLevel.tscn` active.

- [ ] **Step 4: Verify behavior**

Watch the NPC and confirm:

1. It bobs up and down with the animated waves.
2. It drifts slowly along the water flow direction.
3. If the water surface is rotated, it drifts along the rotated flow direction.
4. It stops moving when it leaves the water area.
5. The sprite flips horizontally when the drift direction changes.

- [ ] **Step 5: Adjust `vertical_offset` if needed**

If the NPC's feet are above or below the water line, select the NPC instance and tweak `Vertical Offset` in the Inspector until the sprite base sits on the surface.

- [ ] **Step 6: Decide whether to keep the NPC placement**

- If `DebugLevel.tscn` is meant to be a playable debug level, keep the NPC placement and commit.
- If the placement was only for testing, remove the NPC instance and revert the scene before committing.

- [ ] **Step 7: Commit**

If keeping the NPC placement:

```bash
git add debug/DebugLevel.tscn
git commit -m "test(debug): place NPC in DebugLevel for smoke testing

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

If reverting:

```bash
git checkout -- debug/DebugLevel.tscn
```

---

## Self-Review

### Spec coverage

| Spec Requirement | Task |
|---|---|
| Kinematic driving (no physics) | Task 2 (`FloatingNPC` extends `Node2D`) |
| Surface alignment to animated wave | Task 1 (helper) + Task 2 (`_align_to_surface`) |
| Drift along water flow direction | Task 2 (`_drift_with_current`) |
| Single drift speed multiplier | Task 2 (`drift_speed_multiplier`) |
| Independent scene auto-detects water | Task 2 (`_update_current_water`) + Task 3 (`WaterDetector`) |
| Stop on exit | Task 2 (`if _current_water == null: return`) |
| No interaction in this task | Out of scope; no collision layers for gameplay interactions |
| Visual facing | Task 2 (`_update_facing`) |

### Placeholder scan

No `TBD`, `TODO`, vague instructions, or undefined references found.

### Type consistency

- `get_surface_height_at_global_position(global_position: Vector2) -> float` is defined in Task 1 and consumed in Task 2 as `_current_water.get_surface_height_at_global_position(global_position)`.
- `get_water_flow_direction() -> Vector2` and `current_flow_speed: float` are existing `WaterSurface` members used in Task 2.
- Exported node types (`Area2D`, `Sprite2D`) match the scene structure defined in Task 3.

### Gap check

- No automated unit test harness exists for GDScript in this project. Verification relies on in-editor smoke tests, which is consistent with other recent plans in `docs/superpowers/plans/`.
- Collision/rescue/damage interactions are explicitly out of scope per the spec.
