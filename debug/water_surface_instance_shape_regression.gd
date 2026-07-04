extends SceneTree

const WATER_SURFACE_SCENE := preload("res://scenes/level_parts/WaterSurface.tscn")


func _init() -> void:
	var first_water := WATER_SURFACE_SCENE.instantiate() as WaterSurface
	var second_water := WATER_SURFACE_SCENE.instantiate() as WaterSurface
	var exit_code := 0

	first_water.water_width = 1000.0
	second_water.water_width = 560.0
	first_water._sync_collision_shape()
	second_water._sync_collision_shape()

	var first_shape := _get_rectangle_shape(first_water)
	var second_shape := _get_rectangle_shape(second_water)
	if first_shape == null or second_shape == null:
		push_error("WaterSurface regression: missing rectangle collision shape.")
		exit_code = 1
	elif not is_equal_approx(first_shape.size.x, first_water.water_width):
		push_error(
			"WaterSurface regression: first instance collision width is %s, expected %s."
			% [first_shape.size.x, first_water.water_width]
		)
		exit_code = 1
	elif not is_equal_approx(second_shape.size.x, second_water.water_width):
		push_error(
			"WaterSurface regression: second instance collision width is %s, expected %s."
			% [second_shape.size.x, second_water.water_width]
		)
		exit_code = 1

	first_water.free()
	second_water.free()
	if exit_code == 0:
		print("WaterSurface instance shape regression passed.")
	quit(exit_code)


func _get_rectangle_shape(water_surface: WaterSurface) -> RectangleShape2D:
	var collision_shape := water_surface.get_node("CollisionShape2D") as CollisionShape2D
	return collision_shape.shape as RectangleShape2D
