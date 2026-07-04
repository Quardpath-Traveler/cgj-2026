class_name DebugValuePanel
extends Control

@onready var _labels: VBoxContainer = $VBoxContainer

var _label_map: Dictionary = {}

func _ready() -> void:
  var names := [
    "angular_velocity",
    "rotation_degrees",
    "nose_angle",
    "input",
    "applied_torque",
    "airborne",
    "position_locked",
  ]
  for name in names:
    var label := Label.new()
    label.name = name
    _label_map[name] = label
    _labels.add_child(label)

func update(boat: Boat, input: float, applied_torque: float, position_locked: bool) -> void:
  _label_map["angular_velocity"].text = "Angular Velocity: %.2f rad/s" % boat.angular_velocity
  _label_map["rotation_degrees"].text = "Rotation: %.1f°" % rad_to_deg(boat.global_rotation)
  _label_map["nose_angle"].text = "Nose Angle: %.1f°" % rad_to_deg(boat.global_transform.x.angle())
  _label_map["input"].text = "Input: %.2f" % input
  _label_map["applied_torque"].text = "Applied Torque: %.0f" % applied_torque
  _label_map["airborne"].text = "Airborne: %s" % boat.is_airborne()
  _label_map["position_locked"].text = "Position Locked: %s" % position_locked
