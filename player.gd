class_name Player
extends CharacterBody2D
## IGNIS player.
## Identical silhouette/size/animations in both realities — only the tinted
## sheet changes. Everything else (physics, states, feel) is reality-agnostic.

const SPEED := 92.0
const ACCEL := 900.0
const AIR_ACCEL := 620.0
const DECEL := 1400.0
const GRAVITY := 900.0
const MAX_FALL := 320.0
const JUMP_VELOCITY := -270.0
const JUMP_CUT_MULT := 0.42
const COYOTE_TIME := 0.10
const JUMP_BUFFER_TIME := 0.12

const FRAME_W := 32
const FRAME_H := 48

## anim -> {frames, speed(fps), loop}
const ANIMS := {
	"idle": {"frames": 4, "speed": 6.0, "loop": true},
	"run": {"frames": 6, "speed": 12.0, "loop": true},
	"jump": {"frames": 2, "speed": 8.0, "loop": false},
	"fall": {"frames": 2, "speed": 5.0, "loop": true},
	"land": {"frames": 3, "speed": 14.0, "loop": false},
	"shift": {"frames": 6, "speed": 16.0, "loop": false},
	"interact": {"frames": 4, "speed": 10.0, "loop": false},
	"hurt": {"frames": 3, "speed": 12.0, "loop": false},
	"death": {"frames": 6, "speed": 8.0, "loop": false},
}

## How many hits the player can take before being dragged back to the nearest
## checkpoint. The creatures of the true world are not a nuisance you can simply
## stand inside.
const MAX_HITS := 3

@onready var sprite: AnimatedSprite2D = $Sprite

var facing: int = 1
var invulnerable: bool = false
## Hits taken since the last checkpoint, respawn or safe place.
var hits: int = 0

var _coyote: float = 0.0
var _buffer: float = 0.0
var _one_shot: String = ""
var _dead: bool = false
var _invuln_time: float = 0.0
var _was_on_floor: bool = false
var _frames: Dictionary = {}


func _ready() -> void:
	add_to_group("player")
	_frames[RealityManager.Reality.PERCEIVED] = _build_frames(true)
	_frames[RealityManager.Reality.TRUE] = _build_frames(false)
	sprite.sprite_frames = _frames[RealityManager.current_reality]
	sprite.play("idle")

	RealityManager.reality_changed.connect(_on_reality_changed)
	sprite.animation_finished.connect(_on_anim_finished)
	EventManager.checkpoint_activated.connect(_on_checkpoint_activated)
	CheckpointManager.register_player(self)
	# the area start is always a safe place to come back to
	CheckpointManager.set_spawn(global_position)

	EventManager.player_spawned.emit(self)


func _build_frames(perceived: bool) -> SpriteFrames:
	var suffix: String = "perceived" if perceived else "true"
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim in ANIMS.keys():
		var info: Dictionary = ANIMS[anim]
		var tex: Texture2D = load("res://assets/player/player_%s_%s.png" % [anim, suffix])
		sf.add_animation(anim)
		sf.set_animation_speed(anim, info["speed"])
		sf.set_animation_loop(anim, info["loop"])
		for i in range(int(info["frames"])):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
			sf.add_frame(anim, at)
	return sf


# ─────────────────────────── life cycle ───────────────────────────

## Nothing in any level is below this, so falling past it means the player left
## the level. Hand them straight back to the nearest checkpoint.
const FALL_LIMIT := 620.0


func _physics_process(delta: float) -> void:
	if GameState.is_paused:
		return

	if not _dead and global_position.y > FALL_LIMIT:
		die()
		return

	_invuln_time = maxf(0.0, _invuln_time - delta)
	invulnerable = _invuln_time > 0.0
	sprite.modulate = Color(1, 1, 1, 0.55) if (invulnerable and int(_invuln_time * 20.0) % 2 == 0) else Color.WHITE

	if _dead:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)
		move_and_slide()
		return

	_dash_rest = maxf(0.0, _dash_rest - delta)
	_handle_input()
	if _dash_time > 0.0:
		# for the length of it, the dash replaces movement entirely
		_tick_dash(delta)
	else:
		_apply_gravity(delta)
		_apply_horizontal(delta)
		_apply_jump(delta)
	move_and_slide()
	_detect_landing()
	_update_anim()
	sprite.flip_h = facing < 0


func _handle_input() -> void:
	if Input.is_action_just_pressed("reality_shift") and not RealityManager.is_transitioning:
		_play_once("shift")
		RealityManager.request_shift()
	if Input.is_action_just_pressed("interact"):
		# E is two things. Something offering itself to E wins; with nothing to press, E is
		# the dash. Which of the two it is is never ambiguous — it is read off the world,
		# not off a modifier key.
		if _interactable_in_reach():
			_play_once("interact")
			AudioManager.play_sfx("interact", -4.0)
			EventManager.interaction_used.emit(self)
		else:
			_start_dash()
	if Input.is_action_just_pressed("restart"):
		CheckpointManager.respawn()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		_coyote = maxf(0.0, _coyote - delta)
	else:
		_coyote = COYOTE_TIME


func _apply_horizontal(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if absf(dir) > 0.01:
		var accel: float = ACCEL if is_on_floor() else AIR_ACCEL
		velocity.x = move_toward(velocity.x, dir * SPEED, accel * delta)
		if _one_shot == "" or _one_shot == "run":
			facing = 1 if dir > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)


func _apply_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER_TIME
	_buffer = maxf(0.0, _buffer - delta)

	if _buffer > 0.0 and _coyote > 0.0 and _one_shot != "shift":
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
		_play_once("jump")
		AudioManager.play_sfx("jump", -3.0)
		Fx.burst(get_parent(), "res://assets/effects/jump_dust.png", 8, 8, 8, global_position + Vector2(0, 20), 20.0)

	# variable jump height: releasing early clips upward velocity once
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULT


func _detect_landing() -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and _one_shot != "shift":
		_play_once("land")
		AudioManager.play_sfx("land", -6.0)
		Fx.burst(get_parent(), "res://assets/effects/landing_dust.png", 8, 8, 8, global_position + Vector2(0, 22), 16.0)
	_was_on_floor = on_floor


func _update_anim() -> void:
	if _one_shot != "":
		return
	var next := "idle"
	if not is_on_floor():
		next = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 5.0:
		next = "run"
	if sprite.animation != next:
		sprite.play(next)


func _play_once(anim_name: String) -> void:
	_one_shot = anim_name
	sprite.play(anim_name)


func _on_anim_finished() -> void:
	if _one_shot != "hurt" and _one_shot != "death":
		_one_shot = ""


func _on_reality_changed(new_reality: int) -> void:
	var current := sprite.animation
	sprite.sprite_frames = _frames[new_reality]
	sprite.play(current)


# ─────────────────────────── damage / death ───────────────────────────

func hurt(push: Vector2 = Vector2.ZERO) -> void:
	# a dash goes through: that is the whole point of it, and the one moment in the game the
	# player is allowed to be inside something that wants them
	if _dead or invulnerable or _dash_time > 0.0:
		return
	hits += 1
	if hits >= MAX_HITS:
		# the last one of them: the world takes the player back
		velocity = push
		die()
		return
	_invuln_time = 1.0
	invulnerable = true
	_play_once("hurt")
	velocity = push
	AudioManager.play_sfx("hurt", -2.0)
	Fx.burst(get_parent(), "res://assets/effects/hurt_particles.png", 2, 16, 16, global_position, 12.0)


func die() -> void:
	if _dead:
		return
	_dead = true
	_end_dash()
	_one_shot = "death"
	sprite.play("death")
	AudioManager.play_sfx("death", -2.0)
	GameState.deaths += 1
	EventManager.player_died.emit(self)
	await get_tree().create_timer(0.9).timeout
	_dead = false
	_one_shot = ""
	if CheckpointManager.has_checkpoint:
		CheckpointManager.respawn()
	else:
		sprite.play("idle")


func on_respawn() -> void:
	_dead = false
	_one_shot = ""
	velocity = Vector2.ZERO
	_invuln_time = 0.6
	hits = 0
	_end_dash()
	sprite.play("idle")


## A checkpoint is a safe place, and safety clears the count.
func _on_checkpoint_activated(_pos: Vector2) -> void:
	hits = 0


## Bounced off something below (stomping an enemy). Reads as a jump.
func bounce(velocity_y: float = -190.0) -> void:
	velocity.y = velocity_y
	_play_once("jump")


# ─────────────────────────── the dash ───────────────────────────
#
# E, when there is nothing to press, is the dash: a short hard shove in the direction the
# player faces that ignores gravity for the length of it. It is the one move in the game
# that goes *through* things instead of around them, which is exactly what the monsters of
# the two worlds are for — they are not fast enough to outrun and not patient enough to walk
# around, and this is the answer to them.
#
# Everything the dash is lives in this block: its numbers, its state, and the three
# functions it needs. It can be read, retuned or lifted out in one piece.

## How fast, how long, and how long until it can be done again. Short and hard: long enough
## to carry the player through something, short enough that it is never a way to travel.
const DASH_SPEED := 330.0
const DASH_TIME := 0.16
const DASH_REST := 0.42
## The box the dash cuts in front of the player. Only the horizontal number matters here:
## the vertical extent is the pair of numbers down beside _sweep, measured from the player's
## feet, because that is the end of the body an enemy's own origin is also measured from.
const DASH_REACH := Vector2(30.0, 26.0)
const DASH_DUST := "res://assets/effects/jump_dust.png"

## And what the dash *is*, when you look at it: the player puts a blade through whatever is in
## front of them. The weapon is drawn for the length of the dash and not one frame longer —
## there is no sword in the idle animation and there never was, which is the whole point: the
## weapon is the move, not equipment.
const BLADE_ART := "res://assets/generated/player_blade.png"
const SLASH_ART := "res://assets/generated/fx_slash_arc.png"
const BLADE_SCALE := 0.55
const ARC_SCALE := 0.42
## How often the trail drops a frozen copy of the player behind them. A trail is the cheapest
## honest way to say "that happened fast" without animating anything.
const TRAIL_STEP := 0.035

## Time left in the current dash, time left before the next one is allowed, and whatever
## this dash has already taken — so one dash is one hit per thing, never a flood.
var _dash_time: float = 0.0
var _dash_rest: float = 0.0
var _dash_taken: Array = []
var _blade: Sprite2D
var _trail: float = 0.0


## Anything offering itself to E right now. The dash is on the same key, so this is what
## decides between them, and it reads the world rather than a modifier: if something is
## holding the player, E presses it; if nothing is, E moves them. The reach is the
## interactable's own — it reports whether it holds the player, not the other way round — so
## the prompt on screen and the key that appears to match it can never disagree.
func _interactable_in_reach() -> bool:
	for node in get_tree().get_nodes_in_group("interactable"):
		var area := node as Area2D
		if area != null and area.overlaps_body(self):
			return true
	return false


func _start_dash() -> void:
	if _dash_time > 0.0 or _dash_rest > 0.0 or _dead:
		return
	_dash_time = DASH_TIME
	_dash_rest = DASH_TIME + DASH_REST
	_dash_taken.clear()
	_trail = 0.0
	# squashed along the direction of travel, so the move reads as leaning into it
	sprite.scale = Vector2(1.30, 0.74)
	AudioManager.play_sfx("slash", -4.0)
	AudioManager.play_sfx("shift_dull", -11.0)
	Fx.burst(get_parent(), DASH_DUST, 5, 6, 6, global_position + Vector2(-facing * 8.0, 18.0), 18.0)
	_swing()


## The blade comes out and sweeps down through the space in front of the player, and a crescent
## of the cut is left hanging in the air behind it. Both are children of the player, so the
## swing travels with the body, and neither has to be cleaned up by hand: the swing is a tween
## on the blade's own rotation and the crescent frees itself when it has faded.
func _swing() -> void:
	if _blade == null:
		_blade = Sprite2D.new()
		_blade.texture = UiStyle.load_art(BLADE_ART)
		# the picture is a whole sword lying flat with the hilt at its left end. The offset
		# moves the *hilt* onto the node's origin, so the swing turns about the hand instead of
		# about the middle of the blade.
		_blade.offset = Vector2(46.0, 0.0)
		_blade.z_index = 4
		_blade.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(_blade)
	# mirrored for a leftward dash by a negative x scale rather than by flip_h: a flip takes
	# the offset's direction with it and moves the hilt off the hand
	_blade.scale = Vector2(BLADE_SCALE * float(facing), BLADE_SCALE)
	_blade.rotation = -1.15 * float(facing)
	_blade.visible = true

	var arc := Sprite2D.new()
	arc.texture = UiStyle.load_art(SLASH_ART)
	arc.position = Vector2(13.0 * float(facing), -2.0)
	arc.scale = Vector2(ARC_SCALE * float(facing), ARC_SCALE)
	arc.z_index = 5
	arc.modulate = Color(1.0, 0.72, 0.80, 0.95)
	arc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(arc)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_blade, "rotation", 0.85 * float(facing), DASH_TIME) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_property(arc, "scale",
		Vector2(ARC_SCALE * 1.4 * float(facing), ARC_SCALE * 1.4), DASH_TIME * 1.4)
	t.tween_property(arc, "modulate:a", 0.0, DASH_TIME * 1.4)
	t.chain().tween_callback(arc.queue_free)


func _tick_dash(delta: float) -> void:
	_dash_time -= delta
	velocity.x = facing * DASH_SPEED
	# a dash is a straight line, not an arc: it holds its height for the whole of it, which
	# is what makes it something the player can use to cross a gap a jump cannot
	velocity.y = 0.0
	_sweep()
	_trail -= delta
	if _trail <= 0.0:
		_trail = TRAIL_STEP
		_afterimage()
	if _dash_time <= 0.0:
		_dash_time = 0.0
		velocity.x *= 0.45
		sprite.scale = Vector2.ONE
		if _blade != null:
			_blade.visible = false
		Fx.burst(get_parent(), "res://assets/effects/landing_dust.png", 4, 6, 6,
			global_position + Vector2(0.0, 18.0), 12.0)


## One frozen copy of the frame the player is on right now, hot and fading. Parented to the
## level rather than to the player on purpose: a trail that follows the thing it is trailing
## is not a trail, it is a tail.
func _afterimage() -> void:
	var frames: SpriteFrames = sprite.sprite_frames
	if frames == null or not frames.has_animation(sprite.animation):
		return
	var tex: Texture2D = frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.flip_h = sprite.flip_h
	ghost.z_index = -1
	ghost.modulate = Color(1.0, 0.45, 0.65, 0.55)
	get_parent().add_child(ghost)
	ghost.global_position = global_position
	var t := create_tween()
	t.tween_property(ghost, "modulate:a", 0.0, 0.22)
	t.tween_callback(ghost.queue_free)


func _end_dash() -> void:
	_dash_time = 0.0
	_dash_rest = 0.0
	sprite.scale = Vector2.ONE
	if _blade != null:
		_blade.visible = false


## The dash sweeps a box around the player's **feet** — 22px below the origin, the collider
## being 44 tall and centred on it. The feet are the measurement that lines two bodies up:
## an enemy's origin is at *its* feet, so on one floor the two agree exactly, and an enemy
## standing a step below or a ledge above still lands inside the window.
const DASH_FEET := 22.0
const DASH_UP := 34.0
const DASH_DOWN := 16.0


## Everything the dash is standing inside, right now. Duck-typed on purpose: anything in the
## enemies group that knows how to be dashed is taken, and anything that does not — one of
## the old watchers further back in the game, say — is simply left where it stands.
##
## Nor does it take anything that is not *here*. Both worlds keep their monsters standing in
## the same corridor at the same time, one of them invisible, so the sweep asks each of them
## the ordinary question — is this node visible — and leaves the waiting ones alone. A dash
## that kills the thing in the other world would be a dash that kills nothing you can see.
func _sweep() -> void:
	var feet: Vector2 = global_position + Vector2(0.0, DASH_FEET)
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or _dash_taken.has(node):
			continue
		var enemy := node as Node2D
		if enemy == null:
			continue
		if enemy is CanvasItem and not (enemy as CanvasItem).visible:
			continue
		var d: Vector2 = enemy.global_position - feet
		if absf(d.x) > DASH_REACH.x or d.y > DASH_DOWN or d.y < -DASH_UP:
			continue
		_dash_taken.append(enemy)
		if enemy.has_method("dash_hit"):
			enemy.call("dash_hit", facing)
		elif enemy.has_method("kill"):
			enemy.call("kill")
