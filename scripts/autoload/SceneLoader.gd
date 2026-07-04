extends Node


func _ready() -> void:
	EventBus.scene_transition_requested.connect(change_scene)


func change_scene(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Failed to change scene to %s: %s" % [scene_path, error])
