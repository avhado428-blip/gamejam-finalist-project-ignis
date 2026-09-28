class_name ParkourBridge
extends StaticBody3D
## A floor that is only a floor once.
##
## The flat game's collapsing stone given a body: it rocks the moment it has weight
## on it, goes, drops away into the dark under the room, and then comes back up out
## of that same dark a little later — so the room is never short of a way across,
## and nothing in it quietly disappears. It is faintly red, because in this game red
## has only ever meant one thing.
##
## It joins the "no_safe" group: somewhere the player can stand is not somewhere they
## can be put back on, or a respawn would drop them onto a bridge that had already
## fallen (see ParkourPlayer._note_safe_ground).

const FUSE := 0.75
const AWAY := 2.6
const FALL_TIME := 1.7
const RISE_TIME := 0.7
const FALL_ACCEL := 22.0
## How far below its place the bridge waits, and the longest it spends falling.
const DEEP := 34.0

enum State { WAITING, GOING, GONE, COMING_BACK }

var _state: int = State.WAITING
var _timer: float = 0.0
var _fall_speed: float = 0.0
var _rock: float = 0.0
var _home: Vector3 = Vector3.ZERO
var _mat: StandardMaterial3D


## Called by the room right after the node is added, because the course is a table
## and this is one row of it.
func setup(w: float, h: float, d: float, col: Color) -> void:
	add_to_group("no_safe")
	_home = position

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = col.darkened(0.18)
	_mat.roughness = 0.85
	_mat.emission_enabled = true
	_mat.emission = Color(0.44, 0.06, 0.09)
	_mat.emission_energy_multiplier = 0.45

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(w, h, d)
	mesh.mesh = box
	mesh.material_override = _mat
	add_child(mesh)

	var shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = Vector3(w, h, d)
	shape.shape = cube
	add_child(shape)

	# the weight that starts the fuse: a sensor sitting in the top of the slab, so
	# it is standing *on* the bridge that matters, not brushing its side
	var foot := Area3D.new()
	foot.collision_layer = 0
	foot.collision_mask = 1
	var foot_shape := CollisionShape3D.new()
	var foot_box := BoxShape3D.new()
	foot_box.size = Vector3(w * 0.85, 1.0, d * 0.85)
	foot_shape.shape = foot_box
	foot_shape.position = Vector3(0.0, h * 0.5 + 0.3, 0.0)
	foot.add_child(foot_shape)
	add_child(foot)
	foot.body_entered.connect(_on_foot_entered)


func _on_foot_entered(body: Node3D) -> void:
	if _state != State.WAITING or not (body is ParkourPlayer):
		return
	_state = State.GOING
	_timer = 0.0
	AudioManager.play_sfx("creak", -7.0, 1.15)


func _process(delta: float) -> void:
	# a floor must not go out from under a player the game has stopped
	if GameState.is_paused:
		return
	match _state:
		State.GOING:
			_timer += delta
			_rock += delta * 26.0
			rotation.z = sin(_rock) * 0.022
			_mat.emission_energy_multiplier = 0.45 + 0.75 * absf(sin(_rock))
			if _timer >= FUSE:
				_go()
		State.GONE:
			_timer += delta
			if _timer <= FALL_TIME:
				_fall_speed += FALL_ACCEL * delta
				position.y -= _fall_speed * delta
			if _timer >= AWAY:
				_state = State.COMING_BACK
				_timer = 0.0
		State.COMING_BACK:
			_timer += delta
			var t: float = clampf(_timer / RISE_TIME, 0.0, 1.0)
			position.y = lerpf(_home.y - DEEP, _home.y, ease(t, 0.35))
			if t >= 1.0:
				_state = State.WAITING
				rotation.z = 0.0
				collision_layer = 1
				_pulse(0.22)
				AudioManager.play_sfx("land", -4.0, 0.7)


## Off: the floor goes out from under whatever is on it and the slab drops away.
func _go() -> void:
	_state = State.GONE
	_timer = 0.0
	_fall_speed = 0.0
	rotation.z = 0.0
	collision_layer = 0
	_mat.emission_energy_multiplier = 0.45
	_pulse(0.55)
	AudioManager.play_sfx("stone", -5.0, 1.35)


## The body it wears belongs to whichever world the player is standing in.
func react(col: Color) -> void:
	if _mat != null:
		_mat.albedo_color = col.darkened(0.18)


## The room keeps one tear between all of it (see Parkour3D.pulse_glitch), rather
## than a screen shader per prop.
func _pulse(amount: float) -> void:
	var room := get_tree().get_first_node_in_group("parkour_fx") as Parkour3D
	if room != null:
		room.pulse_glitch(amount)
