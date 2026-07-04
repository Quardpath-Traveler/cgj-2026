class_name DeathZone
extends Area2D


@export var respawn_marker: Marker2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("boats"):
		return
	if not body.has_method("respawn_at"):
		return
	if respawn_marker == null:
		push_warning("DeathZone '%s' has no respawn_marker assigned" % name)
		return

	body.respawn_at(respawn_marker.global_position)
