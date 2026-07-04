class_name DebugRotationIndicator
extends Node2D

@export var max_arrow_length: float = 80.0
@export var max_velocity_for_length: float = 8.0
@export var idle_color: Color = Color(1.0, 1.0, 1.0)
@export var left_color: Color = Color(0.3, 0.6, 1.0)
@export var right_color: Color = Color(1.0, 0.6, 0.2)

var _boat: Boat = null
var _input: float = 0.0

func update(boat: Boat, input: float) -> void:
	_boat = boat
	_input = input
	queue_redraw()

func _draw() -> void:
	if _boat == null or not is_instance_valid(_boat):
		return

	var nose_direction := _boat.global_transform.x
	var length := clampf(absf(_boat.angular_velocity) / max_velocity_for_length, 0.0, 1.0) * max_arrow_length
	var color := idle_color
	if not is_zero_approx(_input):
		color = left_color if _input < 0.0 else right_color

	var start := Vector2.ZERO
	var end := nose_direction * length
	draw_line(start, end, color, 3.0)
	_draw_arrow_head(end, nose_direction, color)

func _draw_arrow_head(tip: Vector2, direction: Vector2, color: Color) -> void:
	var head_size := 10.0
	var back := -direction * head_size
	var side := direction.rotated(PI * 0.5) * head_size * 0.5
	draw_line(tip, tip + back + side, color, 2.0)
	draw_line(tip, tip + back - side, color, 2.0)
