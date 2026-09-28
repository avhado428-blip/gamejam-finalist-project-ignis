class_name ParkourFinish
extends Area3D
## The end of the course, which is the end of the game.
##
## The door the room has been holding shut since the player walked in is open, and
## walking through it is the last thing the game asks for. What it hands over to is
## the void — the black beat, and then the credits (see `ui/void.gd`) — rather than
## `GameState.advance_area()`: the parkour room *is* the end of this run, and there is
## nothing behind its door that the run has not already been through.
##
## Before it fires, the picture goes first: being pushed back out of somewhere is
## not something it survives cleanly, so the tear comes up at full strength, the
## room flattens out, and the hands are taken away from the camera — the exact
## reverse of the way in.

const VOID := "res://ui/void.tscn"

## How long the push back out takes, and the field of view it opens to.
const PUSH_OUT := 0.85
const PULL_BACK := 118.0
## Left over after the hands are gone, before the next scene is asked for.
const AFTER := 0.45

var _triggered: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _triggered or not (body is ParkourPlayer):
		return
	_triggered = true
	_leave(body as ParkourPlayer)


func _leave(player: ParkourPlayer) -> void:
	# control goes, and so does the mouse
	player.freeze()
	EventManager.hint_changed.emit("")

	# the same tear this room has been making all game, on cue and at full weight
	var burst := Glitch.new()
	burst.intensity = 1.0
	burst.calm_gap = Vector2(0.15, 0.4)
	add_child(burst)
	burst.burst(1.0)
	AudioManager.play_sfx("sting", -3.0, 0.5)
	AudioManager.play_sfx("heartbeat", -4.0, 0.35)

	var out := create_tween()
	out.set_trans(Tween.TRANS_SINE)
	out.tween_property(player.camera, "fov", PULL_BACK, PUSH_OUT)
	if player.hands != null:
		# down and away from the eye: the body stops being yours on the way out
		out.parallel().tween_property(player.hands, "position",
			ParkourPlayer.HAND_HOME + Vector3(0.12, -0.55, -0.90), PUSH_OUT)
	var black := get_parent().get_node_or_null("Fade/Rect") as ColorRect
	if black != null:
		out.parallel().tween_property(black, "modulate:a", 1.0, PUSH_OUT * 1.15)
	await out.finished

	burst.intensity = 0.0
	burst.burst(0.0)
	await get_tree().create_timer(AFTER).timeout
	get_tree().change_scene_to_file(VOID)
