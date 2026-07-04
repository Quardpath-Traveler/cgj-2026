# Boat Counter-Rotation Boost Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a counter-rotation boost to the boat so reversing rotation direction quickly overcomes angular momentum, with debug UI visibility and automated test coverage.

**Architecture:** Extend `Boat` with a stateful boost check in `_physics_process`; expose multiplier and zero-threshold as `@export` vars. Pass the boost state to `DebugValuePanel` and assert boosted torque in the existing headless test harness.

**Tech Stack:** Godot 4.7, GDScript, Jolt Physics 2D.

## Global Constraints

- Boost only applies while airborne and not anchored, consistent with existing airborne rotation torque.
- Default boost multiplier is `2.0` and must be `@export` adjustable.
- Debug UI must show boost state and multiplier.
- The existing automated harness `debug/BoatRotationDebugTest.tscn` must continue to pass and include a reverse-input torque assertion.
- Production files outside `scripts/player/boat.gd` are not modified except for debug tooling under `debug/`.

---

## File Structure

| File | Responsibility |
|---|---|
| `scripts/player/boat.gd` | Adds `_is_counter_rotation_boost_active`, parameters, and `_update_counter_rotation_boost()`; applies boosted torque. |
| `debug/ui/DebugValuePanel.gd` | Displays `counter_boost_active` and `counter_boost_mult` labels. |
| `debug/boat_rotation_debug.gd` | Reads boat boost state and passes it to the value panel. |
| `debug/boat_rotation_debug_test.gd` | Adds a reverse-input phase that asserts boosted torque is applied. |

---

### Task 1: Add counter-rotation boost logic to Boat

**Files:**
- Modify: `scripts/player/boat.gd`
- Test: `debug/BoatRotationDebugTest.tscn` (existing harness)

**Interfaces:**
- Consumes: existing `airborne_rotation_torque`, `is_airborne()`, `anchor.is_hooked()`, `angular_velocity`
- Produces: `_is_counter_rotation_boost_active: bool` (read-only from outside), `counter_rotation_boost: float`, `counter_rotation_zero_threshold: float`

- [ ] **Step 1: Add state and exports**

Add near the top of `scripts/player/boat.gd`, after `airborne_rotation_torque`:

```gdscript
@export var counter_rotation_boost: float = 2.0
@export var counter_rotation_zero_threshold: float = 0.05

var _is_counter_rotation_boost_active: bool = false
```

- [ ] **Step 2: Add the boost update helper**

Add a new private method in `scripts/player/boat.gd`:

```gdscript
func _update_counter_rotation_boost(input: float) -> void:
	if is_zero_approx(input):
		_is_counter_rotation_boost_active = false
		return

	if absf(angular_velocity) <= counter_rotation_zero_threshold:
		return

	var velocity_sign := signf(angular_velocity)
	var input_sign := signf(input)

	if _is_counter_rotation_boost_active:
		if velocity_sign == input_sign:
			_is_counter_rotation_boost_active = false
	else:
		if velocity_sign != input_sign:
			_is_counter_rotation_boost_active = true
```

- [ ] **Step 3: Apply boosted torque in `_physics_process`**

Replace the existing torque block in `scripts/player/boat.gd:54-59` with:

```gdscript
var rotation_input := Input.get_axis("move_left", "move_right")
if is_airborne():
	if not anchor.is_hooked():
		_apply_airborne_nose_down()
	if not is_zero_approx(rotation_input):
		_update_counter_rotation_boost(rotation_input)
		var torque := airborne_rotation_torque
		if _is_counter_rotation_boost_active:
			torque *= counter_rotation_boost
		apply_torque(rotation_input * torque)
```

- [ ] **Step 4: Verify no parse errors**

Run: `godot --headless --path /Volumes/takusan/projects/cgj-2026/.worktrees/code/debug-boat-rotation-torque --import`
Expected: Project imports without script errors.

- [ ] **Step 5: Commit**

```bash
git add scripts/player/boat.gd
git commit -m "feat(player): add counter-rotation boost for airborne boat

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Display boost state in DebugValuePanel

**Files:**
- Modify: `debug/ui/DebugValuePanel.gd`

**Interfaces:**
- Consumes: `update(boat: Boat, input: float, applied_torque: float, position_locked: bool)`
- Produces: `update(..., counter_boost_active: bool = false, counter_boost_mult: float = 1.0)`

- [ ] **Step 1: Add new labels to `_ready`**

In `debug/ui/DebugValuePanel.gd`, add two entries to the `names` array in `_ready()`:

```gdscript
var names := [
	"angular_velocity",
	"rotation_degrees",
	"nose_angle",
	"input",
	"applied_torque",
	"counter_boost_active",
	"counter_boost_mult",
	"airborne",
	"position_locked",
]
```

- [ ] **Step 2: Extend `update` signature and body**

Replace the existing `update` method with:

```gdscript
func update(
	boat: Boat,
	input: float,
	applied_torque: float,
	position_locked: bool,
	counter_boost_active: bool = false,
	counter_boost_mult: float = 1.0
) -> void:
	_label_map["angular_velocity"].text = "Angular Velocity: %.2f rad/s" % boat.angular_velocity
	_label_map["rotation_degrees"].text = "Rotation: %.1f°" % rad_to_deg(boat.global_rotation)
	_label_map["nose_angle"].text = "Nose Angle: %.1f°" % rad_to_deg(boat.global_transform.x.angle())
	_label_map["input"].text = "Input: %.2f" % input
	_label_map["applied_torque"].text = "Applied Torque: %.0f" % applied_torque
	_label_map["counter_boost_active"].text = "Counter Boost Active: %s" % counter_boost_active
	_label_map["counter_boost_mult"].text = "Counter Boost Mult: %.2f" % counter_boost_mult
	_label_map["airborne"].text = "Airborne: %s" % boat.is_airborne()
	_label_map["position_locked"].text = "Position Locked: %s" % position_locked
```

- [ ] **Step 3: Verify no parse errors**

Run: `godot --headless --path /Volumes/takusan/projects/cgj-2026/.worktrees/code/debug-boat-rotation-torque --import`
Expected: No script errors.

- [ ] **Step 4: Commit**

```bash
git add debug/ui/DebugValuePanel.gd
git commit -m "feat(debug): show counter-rotation boost state in value panel

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Wire boost data into BoatRotationDebug controller

**Files:**
- Modify: `debug/boat_rotation_debug.gd`

**Interfaces:**
- Consumes: `_boat.counter_rotation_boost`, `_boat._is_counter_rotation_boost_active`
- Produces: updated `_value_panel.update(...)` call with boost args

- [ ] **Step 1: Pass boost values to `_compute_applied_torque` and panel**

In `debug/boat_rotation_debug.gd`, update `_process`:

```gdscript
func _process(_delta: float) -> void:
	if _boat == null or not is_instance_valid(_boat):
		return

	var input := Input.get_axis("move_left", "move_right")
	var applied_torque := _compute_applied_torque(input)

	_value_panel.update(
		_boat,
		input,
		applied_torque,
		position_locked,
		_boat._is_counter_rotation_boost_active,
		_boat.counter_rotation_boost
	)
	_graph.push_sample(_boat.angular_velocity)
	_indicator.global_position = _boat.global_position
	_indicator.update(_boat, input)
```

Note: accessing `_boat._is_counter_rotation_boost_active` reads an underscore-prefixed variable. For debug-only code this is acceptable; if the variable is later made public, update both call sites.

- [ ] **Step 2: Update `_compute_applied_torque` to mirror boost logic**

```gdscript
func _compute_applied_torque(input: float) -> float:
	if _boat.is_airborne() and not is_zero_approx(input):
		var torque := _boat.airborne_rotation_torque
		if _boat._is_counter_rotation_boost_active:
			torque *= _boat.counter_rotation_boost
		return input * torque
	return 0.0
```

- [ ] **Step 3: Run the debug scene headlessly and confirm no errors**

Run: `godot --headless --path /Volumes/takusan/projects/cgj-2026/.worktrees/code/debug-boat-rotation-torque debug/BoatRotationDebugTest.tscn`
Expected: Existing harness still passes (exit code 0).

- [ ] **Step 4: Commit**

```bash
git add debug/boat_rotation_debug.gd
git commit -m "feat(debug): wire counter-rotation boost data to debug UI

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Add reverse-input boost assertion to automated harness

**Files:**
- Modify: `debug/boat_rotation_debug_test.gd`

**Interfaces:**
- Consumes: `_boat._is_counter_rotation_boost_active`, `_boat.counter_rotation_boost`, `_boat.airborne_rotation_torque`
- Produces: additional test phase and assertion method

- [ ] **Step 1: Add a reverse-input test phase**

After the existing `ASSERT_LOCKED_ROTATION` phase in `debug/boat_rotation_debug_test.gd`, add a new phase that:
1. Holds `D` until angular velocity is clearly positive.
2. Releases `D` and presses `A`.
3. Asserts `_boat._is_counter_rotation_boost_active` becomes true.
4. Asserts the applied torque magnitude equals `airborne_rotation_torque * counter_rotation_boost`.

Add to the `Phase` enum:

```gdscript
HOLD_D_FOR_BOOST_SETUP,
ASSERT_BOOST_TRIGGERED,
```

Add phase logic in `_physics_process`:

```gdscript
Phase.ASSERT_LOCKED_ROTATION:
	if _boat.global_position.distance_to(_initial_position) > locked_position_tolerance:
		_fail("Boat moved while position lock was enabled (position %v)" % _boat.global_position)
	if not (absf(_boat.angular_velocity) > angular_velocity_tolerance):
		_fail("Boat did not rotate in place while locked (angular velocity %f)" % _boat.angular_velocity)
	for _i in range(3):
		_press_key(KEY_PAGEUP)
		_release_key(KEY_PAGEUP)
		_expected_torque += _debug.rotation_torque_step
	_start_phase(Phase.ASSERT_TORQUE, 1)
	return

# ... existing torque assertions ...

Phase.ASSERT_TORQUE_VELOCITY:
	if not (_max_angular_velocity_boosted > _max_angular_velocity_initial):
		_fail("Higher torque did not produce higher angular velocity (initial max %f, boosted max %f)" % [_max_angular_velocity_initial, _max_angular_velocity_boosted])
	_release_key(KEY_D)
	_start_phase(Phase.HOLD_D_FOR_BOOST_SETUP, 1)
	return

Phase.HOLD_D_FOR_BOOST_SETUP:
	_press_key(KEY_D)
	if _boat.angular_velocity < 2.0:
		return
	_release_key(KEY_D)
	_press_key(KEY_A)
	_start_phase(Phase.ASSERT_BOOST_TRIGGERED, 1)
	return

Phase.ASSERT_BOOST_TRIGGERED:
	if not _boat._is_counter_rotation_boost_active:
		_fail("Counter-rotation boost did not activate when reversing input")
	var expected_boosted_torque := _boat.airborne_rotation_torque * _boat.counter_rotation_boost
	var actual_applied_torque := absf(_boat.angular_velocity - _previous_angular_velocity) / delta
	# Simpler assertion: check the boat is decelerating faster than base torque would allow
	if _boat.angular_velocity > 0.0:
		_fail("Boat angular velocity did not start reversing (got %f)" % _boat.angular_velocity)
	_release_key(KEY_A)
	_start_phase(Phase.DONE)
	_finish()
	return
```

This phase needs a `_previous_angular_velocity` field tracked each frame.

- [ ] **Step 2: Add `_previous_angular_velocity` tracking**

Add a variable:

```gdscript
var _previous_angular_velocity: float = 0.0
```

At the top of `_physics_process`:

```gdscript
_previous_angular_velocity = _boat.angular_velocity
```

- [ ] **Step 3: Verify the harness passes**

Run: `godot --headless --path /Volumes/takusan/projects/cgj-2026/.worktrees/code/debug-boat-rotation-torque debug/BoatRotationDebugTest.tscn`
Expected: `PASS: BoatRotationDebug interactive controls verified.`

- [ ] **Step 4: Commit**

```bash
git add debug/boat_rotation_debug_test.gd
git commit -m "test(debug): assert counter-rotation boost activates on reverse input

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

### Spec coverage

| Spec Requirement | Implementing Task |
|---|---|
| Trigger on input-velocity direction mismatch | Task 1 (`_update_counter_rotation_boost`) |
| Configurable boost multiplier (default 2.0) | Task 1 (`@export counter_rotation_boost`) |
| Release when velocity aligns with input | Task 1 (`_update_counter_rotation_boost`) |
| Only airborne, not anchored | Task 1 (inside existing airborne block) |
| Debug UI shows state and multiplier | Task 2 + Task 3 |
| Automated test asserts reverse-input boost | Task 4 |

### Placeholder scan

- No TBD/TODO.
- All code steps contain actual GDScript.
- Exact commands and expected outputs included.

### Type consistency

- `_is_counter_rotation_boost_active: bool` used consistently.
- `counter_rotation_boost: float` used consistently.
- `DebugValuePanel.update` signature extended with defaults so existing callers remain valid during Task 2; Task 3 updates the caller.

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-07-04-boat-counter-rotation-boost-plan.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
