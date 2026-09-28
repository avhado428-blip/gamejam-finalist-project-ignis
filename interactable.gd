class_name Interactable
extends Area2D
## Anything the player can press E on.
##
## Shows a truthful prompt while the player stands inside it, and when used it
## announces its own id on the EventManager bus — the matching Mechanism reacts.
## It never references a level, and it never lies.

signal activated

@export var prompt: String = "[E] interact"
@export var activates_id: StringName = &""
@export var one_shot: bool = false
@export var on_use_hint: String = ""
@export var hitbox_size: Vector2 = Vector2(36, 44)

var _inside: bool = false
var _used: bool = false


func _ready() -> void:
	# The group is how the rest of the game asks "is the player about to press E on
	# something?" without having to guess: the player's dash shares that key, and it asks
	# the group rather than counting modifiers.
	add_to_group("interactable")
	collision_layer = 0
	collision_mask = 2
	if not _has_shape():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = hitbox_size
		shape.shape = rect
		add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	EventManager.interaction_used.connect(_on_interaction_used)


func _has_shape() -> bool:
	for c in get_children():
		if c is CollisionShape2D:
			return true
	return false


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_inside = true
		EventManager.prompt_changed.emit(prompt)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_inside = false
		EventManager.prompt_changed.emit("")


func _on_interaction_used(_source: Node) -> void:
	if not _inside or (_used and one_shot):
		return
	_used = true
	activated.emit()
	if activates_id != &"":
		EventManager.mechanism_activated.emit(activates_id)
	if on_use_hint != "":
		EventManager.hint_changed.emit(on_use_hint)
