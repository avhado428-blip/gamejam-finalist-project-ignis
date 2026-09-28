class_name Mechanism
extends Node2D
## A machine core. It activates when EventManager reports that its own id was
## triggered, and announces the new state back on the bus.
##
## It knows nothing about any level — only its id — so any Interactable anywhere
## can drive it, and any gate can react to it.

@export var id: StringName = &"core"
@export var start_frame: int = 0

var active: bool = false

var _sprite: Sprite2D
var _pulse: Tween


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/props/mechanism_core.png")
	_sprite.hframes = 3
	_sprite.frame = start_frame
	_sprite.centered = false
	_sprite.position = Vector2(-16, -16)
	add_child(_sprite)
	EventManager.mechanism_activated.connect(_on_activated)


func _on_activated(mechanism_id: StringName) -> void:
	if mechanism_id != id or active:
		return
	activate()


func activate() -> void:
	if active:
		return
	active = true
	AudioManager.play_sfx("switch", -2.0)
	EventManager.request_flash.emit(Color(0.31, 0.85, 0.88, 0.30), 0.35)
	EventManager.mechanism_state_changed.emit(id, true)
	var spin := create_tween()
	spin.tween_method(_set_frame, float(start_frame), 2.0, 0.5)
	spin.tween_callback(_start_pulse)


func _set_frame(value: float) -> void:
	_sprite.frame = int(round(value))


func _start_pulse() -> void:
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_pulse = create_tween().set_loops()
	_pulse.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, 0.7), 0.9)
	_pulse.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.9)
