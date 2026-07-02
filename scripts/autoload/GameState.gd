extends Node

signal score_changed(score: int)
signal pause_changed(is_paused: bool)

var score: int = 0
var is_paused: bool = false


func reset() -> void:
	score = 0
	set_paused(false)
	score_changed.emit(score)


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func set_paused(value: bool) -> void:
	if is_paused == value:
		return

	is_paused = value
	get_tree().paused = is_paused
	pause_changed.emit(is_paused)
