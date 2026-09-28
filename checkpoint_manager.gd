extends Node
## CheckpointManager — remembers every safe place the player has actually reached,
## and hands them back to the nearest one. FINAL NAME.

signal checkpoint_reached(position: Vector2)
signal player_respawned(player: Node)

var active_checkpoint: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false

var _player: Node = null
var _checkpoints: Array[Vector2] = []


func register_player(player: Node) -> void:
	_player = player


## A place the player is already standing, recorded silently (no sound, no banner).
func set_spawn(pos: Vector2) -> void:
	active_checkpoint = pos
	has_checkpoint = true
	if not _checkpoints.has(pos):
		_checkpoints.append(pos)


## A checkpoint the player has just touched.
func set_checkpoint(pos: Vector2) -> void:
	set_spawn(pos)
	checkpoint_reached.emit(pos)
	EventManager.checkpoint_activated.emit(pos)
	AudioManager.play_sfx("checkpoint")


## Send the player back to the closest checkpoint they have actually reached —
## not simply the last one, so falling backwards still returns them sensibly.
func respawn() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var target := _nearest_to(_player.global_position)
	active_checkpoint = target
	_player.global_position = target
	_player.velocity = Vector2.ZERO
	if _player.has_method("on_respawn"):
		_player.on_respawn()
	EventManager.player_respawned.emit(_player)
	player_respawned.emit(_player)


func _nearest_to(from: Vector2) -> Vector2:
	if _checkpoints.is_empty():
		return active_checkpoint
	var best: Vector2 = _checkpoints[0]
	var best_distance: float = from.distance_squared_to(best)
	for point in _checkpoints:
		var d: float = from.distance_squared_to(point)
		if d < best_distance:
			best_distance = d
			best = point
	return best


func reset() -> void:
	has_checkpoint = false
	active_checkpoint = Vector2.ZERO
	_checkpoints.clear()
	_player = null
