class_name TutorialZone
extends Area2D
## Shows one quiet, truthful hint line while the player is standing inside it.
## Nothing here is deceptive — the environment does the lying, not the HUD.

@export var message: String = ""
@export var clear_on_exit: bool = true


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		EventManager.hint_changed.emit(message)


func _on_body_exited(body: Node2D) -> void:
	if body is Player and clear_on_exit:
		EventManager.hint_changed.emit("")
