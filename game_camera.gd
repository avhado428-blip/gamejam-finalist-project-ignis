class_name GameCamera
extends Camera2D
## Smooth follow camera with decay-based shake, driven by
## EventManager.request_camera_shake.

var _shake_amount: float = 0.0
var _shake_time: float = 0.0
var _shake_duration: float = 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 9.0
	EventManager.request_camera_shake.connect(_on_shake_requested)


func _on_shake_requested(amount: float, duration: float) -> void:
	if amount >= _shake_amount:
		_shake_amount = amount
		_shake_duration = maxf(duration, 0.01)
		_shake_time = _shake_duration


func _process(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		var k: float = _shake_amount * (_shake_time / _shake_duration)
		offset = Vector2(randf_range(-k, k), randf_range(-k, k))
	else:
		offset = offset.lerp(Vector2.ZERO, clampf(delta * 12.0, 0.0, 1.0))
		if offset.length_squared() < 0.01:
			offset = Vector2.ZERO
			_shake_amount = 0.0
