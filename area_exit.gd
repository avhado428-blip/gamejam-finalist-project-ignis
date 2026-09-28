class_name AreaExit
extends Area2D
## Walking into this ends the current area and starts the next one in
## GameState.AREA_SEQUENCE. It does not know which area it is in.

var _triggered: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _triggered or not (body is Player):
		return
	_triggered = true
	AudioManager.play_sfx("checkpoint", -4.0)
	EventManager.hint_changed.emit("")
	EventManager.request_flash.emit(Color(0.94, 0.94, 0.96, 1.0), 0.85)
	await get_tree().create_timer(0.5).timeout
	GameState.advance_area()
