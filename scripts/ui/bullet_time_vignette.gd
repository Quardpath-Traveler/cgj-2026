extends CanvasLayer

# 子弹时间圆形暗角（中心不受影响，四周渐变淡黑）
# 只有一个全屏 ColorRect 挂 shader，用 _process 调 intensity

@export var max_intensity: float = 0.55
@export var fade_in_duration: float = 0.4
@export var fade_out_duration: float = 0.15
@export var activation_threshold: float = 0.9

@onready var _vignette_rect: ColorRect = $VignetteRoot/VignetteRect

var _current_intensity: float = 0.0


func _ready() -> void:
	layer = 5  # 在世界之上、HUD 之下
	# 启动时强度为 0，shader 输出 alpha=0，不可见
	_vignette_rect.material.set_shader_parameter("intensity", 0.0)


func _process(delta: float) -> void:
	var target := 0.0
	if Engine.time_scale < activation_threshold:
		target = max_intensity

	# 渐入渐出
	var duration := fade_in_duration if target > _current_intensity else fade_out_duration
	_current_intensity = move_toward(_current_intensity, target, delta / maxf(duration, 0.001))

	if _vignette_rect.material is ShaderMaterial:
		_vignette_rect.material.set_shader_parameter("intensity", _current_intensity)
