class_name Checkpoint
extends Area2D
## A pylon that remembers where safety is. It does exactly what it looks like
## it does — the honest half of this game's vocabulary.

var _sprite: Sprite2D
var _done: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, 44)
	shape.shape = rect
	add_child(shape)

	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/props/checkpoint.png")
	_sprite.hframes = 4
	_sprite.frame = 3
	_sprite.centered = false
	# the base of the pylon ends a pixel inside the floor, so it reads as
	# standing in the ground instead of hovering above it
	_sprite.position = Vector2(-16, -23)
	add_child(_sprite)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player) or _done:
		return
	_done = true
	CheckpointManager.set_checkpoint(global_position + Vector2(0, -2))
