class_name AmbiguousShiftZone
extends Area2D
## Inside this zone, Q still performs a *real* shift — the world genuinely changes
## and the HUD genuinely reports it. Only the feedback is withheld: a whisper of a
## flash, no glitch, no shake. The player has to read the environment (solidity,
## enemy behaviour, the haze, sound) to know which world they are standing in.
##
## Deterministic and scripted — never random.

@export var muffled: bool = true
@export var hitbox_size: Vector2 = Vector2(200.0, 120.0)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	if not _has_shape():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = hitbox_size
		shape.shape = rect
		add_child(shape)
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)


func _has_shape() -> bool:
	for c in get_children():
		if c is CollisionShape2D:
			return true
	return false


func _on_entered(body: Node2D) -> void:
	if body is Player:
		EventManager.shift_style_requested.emit(muffled)


func _on_exited(body: Node2D) -> void:
	if body is Player:
		EventManager.shift_style_requested.emit(false)
