class_name Hazard
extends Area2D
## A hazard. It does exactly what it looks like — but what it looks like depends
## on the reality, so levels keep it inside a reality gate. The pale PERCEIVED
## spikes are decoration with no Hazard on them at all; the red TRUE spikes are.

@export var lethal: bool = false
@export var knockback: Vector2 = Vector2(-80.0, -150.0)
@export var hitbox_size: Vector2 = Vector2(48.0, 12.0)
## How far ABOVE the node's origin the sprite's contact line sits. The spike art
## is drawn mirrored (scale.y = -1) with offset (0, 8), and Godot bakes the
## offset into the sprite's local rect *before* the flip — so the teeth stand
## 8 px over the origin and the node belongs 8 px BELOW the floor it stands on.
@export var ground_offset: float = 8.0
## The teeth are up there, not at the origin, so the hitbox goes up with them.
@export var hitbox_offset: Vector2 = Vector2(0.0, -12.0)
## Off for a hazard that is meant to be off the ground.
@export var ground_snap: bool = true
## How far down to look for a floor.
@export var ground_reach: float = 240.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	if not _has_shape():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = hitbox_size
		shape.shape = rect
		shape.position = hitbox_offset
		add_child(shape)
	body_entered.connect(_on_body_entered)
	if ground_snap:
		_snap_to_floor.call_deferred()


## Stand on the floor, or do not exist.
##
## Spikes are placed in a scene by their column and a rough height; this finds
## the real floor under them on the first physics frame and stands them on it, so
## they can never float. A spike whose column turns out to be a pit takes itself
## out instead of hanging over the hole.
func _snap_to_floor() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var node := get_parent() as Node2D
	if node == null:
		return
	var space := node.get_world_2d().direct_space_state
	# cast from just above the spike's own contact line, so the first thing under
	# it is the floor and not some platform or gate body that happens to be there
	var from: Vector2 = node.global_position + Vector2(0.0, -(ground_offset + 8.0))
	var to: Vector2 = node.global_position + Vector2(0.0, ground_reach)
	# layer 1 is the world: every floor tile in this game lives there
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		push_warning("Hazard '%s' has no floor beneath it — hidden." % node.name)
		node.visible = false
		monitoring = false
		return
	var surface: float = (hit["position"] as Vector2).y
	node.global_position.y = surface + ground_offset


func _has_shape() -> bool:
	for c in get_children():
		if c is CollisionShape2D:
			return true
	return false


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	if lethal:
		body.die()
	else:
		body.hurt(knockback)
