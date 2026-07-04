class_name ResultScreen
extends CanvasLayer

@onready var score_label: Label = %ScoreLabel
@onready var stats_label: Label = %StatsLabel
@onready var retry_button: Button = %RetryButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(_on_retry_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)


func show_results(score: int, stats: Dictionary = {}) -> void:
	score_label.text = "Score: %d" % score
	stats_label.text = str(stats)
	visible = true


func _on_retry_button_pressed() -> void:
	EventBus.level_restart_requested.emit()


func _on_main_menu_button_pressed() -> void:
	EventBus.scene_transition_requested.emit("res://scenes/main/Main.tscn")
