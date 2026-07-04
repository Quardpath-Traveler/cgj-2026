extends CanvasLayer


@export_enum("res://scenes/game/Game.tscn","res://debug/FinishAreaRegression.tscn") var level_scene: String = "res://scenes/game/Game.tscn"


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_start_game()
	elif event is InputEventMouseButton and event.pressed:
		_start_game()


func _start_game() -> void:
	get_viewport().set_input_as_handled()
	GameState.current_level_scene = level_scene
	EventBus.scene_transition_requested.emit(level_scene)
