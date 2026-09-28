class_name ParkourEnemy
extends Node3D
## Something that was not standing here a moment ago.
##
## The room's creatures are the flat game's own sheets — in both versions of them — so Q
## is not a screen effect in here either: switch worlds and what is hunting you changes
## shape with the room, and a creature that belongs to the other world is not standing in
## this one at all. Three hits from the bolt puts one down, visibly, with its own death
## frames and its own sparks.
##
## They do not patrol a line any more. This is a room they were put in *with* the player,
## so they walk at whoever is holding the staff — and none of them was here the whole
## time. They come up through the floor, slowly, with the stone still on them, which is the
## room's way of saying it had them all along. One that is put down comes back somewhere
## else later, from underneath, the same way.

const ART := "res://assets/enemies/reality_enemy/%s_%s.png"
const FRAMES := {"idle": 4, "move": 6, "death": 6}
const FPS := {"idle": 6.0, "move": 9.0, "death": 10.0}
## The sheets are 32x40 frames; this puts a creature at one and a half metres.
const PIXEL := 0.0375
const EYE_HEIGHT := 0.75
const TOUCH_RADIUS := 0.8
const DEATH_TIME := 0.62
const RESPAWN := 6.0
## How far away the player has to be before one of these dares come back.
const KEEP_AWAY := 7.0

const DEATH_FX := "res://assets/effects/enemy_death_effect.png"
const DEATH_FX_FRAMES := 6
const DUST := "res://assets/effects/landing_dust.png"
const DUST_FRAMES := 8

## Coming up out of the floor: how deep it starts and how long it takes to get out. The
## row's own `delay` staggers the eight of them, which is what makes this a room that had
## them all along rather than a spawn.
const RISE_DEPTH := 1.6
const RISE_TIME := 1.15
## How close it will walk before it stops, and how far away it can be and still bother.
const STANDOFF := 1.5
const HUNT_RANGE := 46.0
## How far it is allowed from the middle of the room before the wall stops it.
const R_WALL := 28.0

enum State { RISING, ALIVE, DYING, GONE }

var _sprite: Sprite3D
var _touch: Area3D
var _state: int = State.RISING
var _anim: String = "move"
var _suffix: String = "perceived"
var _frame: float = 0.0
var _timer: float = 0.0
var _wait: float = 0.0
var _bob: float = 0.0
var _home: Vector3 = Vector3.ZERO
var _speed: float = 1.6
var _only: String = ""


## One row of the room's creature table.
func setup(cfg: Dictionary) -> void:
	add_to_group("enemy3d")
	# the row is the position: there is no authoring of creatures in the scene at all, so
	# where it comes up is a number in the table like everything else about it
	position = Vector3(float(cfg.get("x", 0.0)), float(cfg.get("y", 0.0)), float(cfg.get("z", 0.0)))
	_home = position
	_speed = float(cfg.get("speed", 1.6))
	_only = str(cfg.get("only", ""))
	_wait = float(cfg.get("delay", 0.0))
	_frame = 0.0
	_timer = 0.0

	_sprite = Sprite3D.new()
	_sprite.pixel_size = PIXEL
	_sprite.position = Vector3(0.0, EYE_HEIGHT, 0.0)
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.shaded = false
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

	_touch = Area3D.new()
	_touch.collision_layer = 0
	_touch.collision_mask = 1
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = TOUCH_RADIUS
	shape.shape = ball
	shape.position = Vector3(0.0, EYE_HEIGHT, 0.0)
	_touch.add_child(shape)
	add_child(_touch)

	_play(_anim)
	# it is not standing here yet: it is buried, and the room's own floor is what hides it
	# until it starts to come up. Nothing in this game fades in.
	position = _home - Vector3(0.0, RISE_DEPTH, 0.0)
	_state = State.RISING
	react(RealityManager.current_reality)


func _process(delta: float) -> void:
	if GameState.is_paused:
		return
	match _state:
		State.RISING:
			_rise(delta)
		State.ALIVE:
			_hunt(delta)
			_advance(delta)
		State.DYING:
			_timer += delta
			_advance(delta)
			if _timer >= DEATH_TIME:
				_state = State.GONE
				_timer = 0.0
				visible = false
				_touch.monitoring = false
		State.GONE:
			_timer += delta
			if _timer >= RESPAWN:
				_rise_again()


func _physics_process(_delta: float) -> void:
	if _state != State.ALIVE or not visible or GameState.is_paused:
		return
	for node in _touch.get_overlapping_bodies():
		var body := node as ParkourPlayer
		if body != null:
			body.hit(global_position)


# ── coming up out of the floor ─────────────────────────────────────────────

## Standing up through the room's floor. It is slow, and the first thing that happens is
## the stone letting go rather than the creature: the dust is the flat game's own landing
## dust, which is the only thing in this game that weight has ever been drawn with.
func _rise(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_break_ground()
		return
	_timer += delta
	var t: float = clampf(_timer / RISE_TIME, 0.0, 1.0)
	position = _home - Vector3(0.0, RISE_DEPTH * (1.0 - ease(t, 1.7)), 0.0)
	_advance(delta)
	if t >= 1.0:
		_state = State.ALIVE
		_timer = 0.0
		_bob = 0.0
		react(RealityManager.current_reality)


func _break_ground() -> void:
	ParkourBeam.effect(get_parent(), DUST, DUST_FRAMES,
		_home + Vector3(0.0, 0.3, 0.0), 0.45, Color(1.0, 0.86, 0.86), 0.05)


## Walking at whoever is holding the staff. It stays in the room, and it stops before it is
## standing on top of them: the threat in here is that it is always coming, not that it has
## already arrived.
func _hunt(delta: float) -> void:
	_bob += delta
	var want := _home
	var player := get_tree().get_first_node_in_group("player3d") as Node3D
	if player != null and _speed > 0.0:
		var to: Vector3 = player.global_position - position
		to.y = 0.0
		var dist: float = to.length()
		if dist > STANDOFF and dist < HUNT_RANGE:
			want = position + to.normalized() * _speed * delta
		if absf(to.x) > 0.15:
			_sprite.flip_h = to.x < 0.0
	var flat := Vector2(want.x, want.z)
	if flat.length() > R_WALL:
		flat = flat.normalized() * R_WALL
	position.x = flat.x
	position.z = flat.y
	position.y = _home.y + sin(_bob * 1.5) * 0.14


# ── being put down, and coming back ────────────────────────────────────────

## Called by the bolt. Its own death frames, from the world it was standing in.
func hit() -> void:
	if _state != State.ALIVE and _state != State.RISING:
		return
	_state = State.DYING
	_timer = 0.0
	_touch.monitoring = false
	_play("death")
	# a creature standing in the other world is put down quietly: nobody is watching that
	# one, and a spark in an empty part of the room would be a lie the player can see
	if not visible:
		return
	AudioManager.play_sfx("death", -6.0, 1.5)
	ParkourBeam.effect(get_parent(), DEATH_FX, DEATH_FX_FRAMES,
		global_position + Vector3(0.0, EYE_HEIGHT, 0.0), 0.28,
		Color(1.0, 0.62, 0.68), 0.06)
	var room := get_tree().get_first_node_in_group("parkour_fx") as Parkour3D
	if room != null:
		room.pulse_glitch(0.3)


func _away_from_player(p: Vector3) -> bool:
	var player := get_tree().get_first_node_in_group("player3d") as Node3D
	return player == null or player.global_position.distance_to(p) > KEEP_AWAY


## Somewhere else, from underneath, the way it arrived the first time.
func _rise_again() -> void:
	var spot := _home
	for _i in 10:
		var a: float = randf() * TAU
		var r: float = randf_range(8.0, R_WALL - 2.0)
		var candidate := Vector3(cos(a) * r, _home.y, -sin(a) * r)
		if _away_from_player(candidate):
			spot = candidate
			break
	_home = spot
	position = _home - Vector3(0.0, RISE_DEPTH, 0.0)
	_state = State.RISING
	_timer = 0.0
	_wait = 0.0
	_anim = "move"
	_bob = 0.0
	react(RealityManager.current_reality)
	_break_ground()


func _play(anim: String) -> void:
	_anim = anim
	_frame = 0.0
	_sprite.hframes = int(FRAMES[anim])
	_sprite.frame = 0
	_sprite.texture = load(ART % [anim, _suffix]) as Texture2D


func _advance(delta: float) -> void:
	var count: int = int(FRAMES[_anim])
	if count <= 1:
		return
	_frame += delta * float(FPS[_anim])
	# the death plays once and stops on its last frame rather than looping
	if _anim == "death":
		_sprite.frame = mini(int(_frame), count - 1)
	else:
		_sprite.frame = int(_frame) % count


## Which version of itself is standing here, and whether it is standing here at all.
func react(reality: int) -> void:
	_suffix = "true" if reality == RealityManager.Reality.TRUE else "perceived"
	var here: bool = _only == "" or (_only == "true") == (reality == RealityManager.Reality.TRUE)
	if _sprite != null:
		_play(_anim)
	visible = here and _state != State.GONE
	_touch.monitoring = here and _state == State.ALIVE