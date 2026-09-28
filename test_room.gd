extends Node2D
## Test room — proves movement, jumping and Q-shifting against the real art.
##
## Truthful level logic:
##   - PERCEIVED has a solid bridge over the gap (an illusion you can walk on).
##   - TRUE has a real pit there, a lethal spike strip, but no wall.
##   - The wall only exists in PERCEIVED's counterpart... i.e. it exists in TRUE
##     only, so shifting is the way past it.

@onready var sky_perceived: TextureRect = $Background/SkyPerceived
@onready var sky_true: TextureRect = $Background/SkyTrue
@onready var checkpoint_sprite: Sprite2D = $Checkpoint/Sprite
@onready var lever_sprite: Sprite2D = $Lever/Sprite


func _ready() -> void:
	GameState.current_level = "test_room"
	GameState.set_objective("Reach the far end.    [Q] shifts reality")

	RealityManager.set_reality(RealityManager.Reality.TRUE, true)
	RealityManager.reality_changed.connect(_on_reality_changed)
	_on_reality_changed(RealityManager.current_reality)

	$Checkpoint.body_entered.connect(_on_checkpoint_entered)
	$TrueWorld/SpikeHazard.body_entered.connect(_on_spike_touched)
	$KillZone.body_entered.connect(_on_fell_out)
	$Lever.activated.connect(_on_lever_activated)

	AudioManager.play_sfx("ui", -10.0)


func _on_reality_changed(new_reality: int) -> void:
	sky_perceived.visible = new_reality == RealityManager.Reality.PERCEIVED
	sky_true.visible = new_reality == RealityManager.Reality.TRUE


func _on_checkpoint_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	var pos: Vector2 = $Checkpoint.global_position + Vector2(0, -2)
	if not CheckpointManager.has_checkpoint or CheckpointManager.active_checkpoint.distance_to(pos) > 4.0:
		CheckpointManager.set_checkpoint(pos)
	checkpoint_sprite.frame = 3


func _on_spike_touched(body: Node2D) -> void:
	if body is Player:
		body.hurt(Vector2(-70.0, -150.0))


func _on_fell_out(body: Node2D) -> void:
	if body is Player:
		body.die()


func _on_lever_activated() -> void:
	lever_sprite.frame = 1
	GameState.set_objective("Lever pulled. The machine is awake.")
	EventManager.request_flash.emit(Color(0.31, 0.85, 0.88, 0.5), 0.25)
