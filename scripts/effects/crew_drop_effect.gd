extends Sprite2D
## 船员掉落特效：从生成位置垂直重力加速下落，超出屏幕后自动销毁。

const TEXTURE := preload("res://assets/art/Character Art Assets/Protagonist Assets/npc2.png")

@export var gravity: float = 600.0          # 像素/秒²
@export var fall_distance: float = 1200.0   # 世界坐标下落距离阈值（>默认窗口高度 648）

var _velocity: float = 0.0
var _start_y: float = 0.0
var _initialized: bool = false


func _ready() -> void:
	texture = TEXTURE
	scale = Vector2(0.12, 0.12)
	z_index = 50
	top_level = true          # 不跟随父节点（船）移动


func _physics_process(delta: float) -> void:
	# 第一帧只记录起始 y：此时父节点已设置好 global_position，避免读到错误初始值
	if not _initialized:
		_start_y = global_position.y
		_initialized = true
		return
	_velocity += gravity * delta
	global_position.y += _velocity * delta
	if global_position.y - _start_y >= fall_distance:
		queue_free()
