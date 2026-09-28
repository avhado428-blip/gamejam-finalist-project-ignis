class_name BossFly
extends Node3D
## What comes off her when she screams.
##
## One fly is nothing: a dark moted picture, six frames of wings, a wobble and an
## appetite. Six of them arriving at once out of a summoning is the point — the player is
## holding a staff that fires three times a second and this is what it is for.
##
## They are in the same group as everything else in the room that can be struck, so the
## staff's lightning kills them with no special case anywhere, and they ask the player for
## one of their three hits by hand because they are not physics bodies.

const ART := "res://assets/generated/boss_fly_loop.png"
const FRAMES := 6
const FPS := 17.0
const ART_GLOW := "res://assets/generated/fx_glow_hot.png"

## Shoulder height is where a fly goes for: it is the part of a person that is not on the
## floor, and it means they are always a little above the player's own sights.
const GO_FOR := 1.15
const SPEED := 2.75
const SPEED_JITTER := 0.6
const WOBBLE := 1.35
const WOBBLE_SPEED := 3.1
const TOUCH := 0.95
const LIFE := 24.0
const SIZE := 0.62
const DIE_TIME := 0.28

## Acid green: the flies are the one thing on the floor that is not hers, and against a hall
## of red stone and a boss who is made of it, green is the only colour that reads as *not
## this room*. The whole fly is tinted with it, not just the glow, so it is a green thing
## coming for the player and not a black speck with a green light on it.
const EYE := Color(0.55, 1.0, 0.26)
const BODY_TINT := Color(0.62, 1.0, 0.55)

var _player: Node3D
var _phase: float = 0.0
var _life: float = 0.0
var _dying: bool = false
var _dead_t: float = 0.0
var _speed: float = SPEED
var _wobble_at: Vector3 = Vector3.ZERO
var _mat: StandardMaterial3D
var _body: MeshInstance3D
var _eye: MeshInstance3D


func setup(at: Vector3, player: Node3D) -> void:
	global_position = at
	_player = player
	# the wobble is anchored where it was born, so it drifts *around* that point rather
	# than accumulating a spiral, which is what a fly that keeps adding noise to its own
	# position does
	_wobble_at = at
	_speed = SPEED + randf_range(-SPEED_JITTER, SPEED_JITTER)
	_phase = randf() * TAU


func _ready() -> void:
	add_to_group("enemy3d")
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = BODY_TINT
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_mat.alpha_scissor_threshold = 0.42
	_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_mat.emission_enabled = true
	_mat.emission = EYE
	_mat.emission_energy_multiplier = 0.95
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mat.disable_receive_shadows = true
	var tex := load(ART) as Texture2D
	if tex == null:
		tex = PlaceholderTexture2D.new()
	_mat.albedo_texture = tex
	_mat.emission_texture = tex
	_mat.uv1_scale = Vector3(1.0 / float(FRAMES), 1.0, 1.0)

	_body = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(SIZE, SIZE)
	_body.mesh = quad
	_body.material_override = _mat
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_body)

	_eye = MeshInstance3D.new()
	var mote := QuadMesh.new()
	mote.size = Vector2(1.0, 1.0)
	_eye.mesh = mote
	var m := StandardMaterial3D.new()
	var glow := load(ART_GLOW) as Texture2D
	if glow != null:
		m.albedo_texture = glow
	m.albedo_color = EYE
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = EYE
	m.emission_energy_multiplier = 1.4
	m.disable_receive_shadows = true
	_eye.material_override = m
	_eye.scale = Vector3.ONE * 0.34
	_eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_eye)


func _process(delta: float) -> void:
	if GameState.is_paused:
		return
	_life += delta
	if _dying:
		_dead_t += delta
		var t: float = clampf(_dead_t / DIE_TIME, 0.0, 1.0)
		scale = Vector3.ONE * (1.0 - t)
		global_position.y -= delta * 1.6
		if t >= 1.0:
			queue_free()
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player3d")
	if _player == null or _life >= LIFE:
		_fall()
		return

	# the wings, off the same UV transform the material already owns
	_phase += delta
	if _mat != null:
		var frame: int = int(_phase * FPS) % FRAMES
		_mat.uv1_offset.x = float(frame) / float(FRAMES)

	# where it wants to be: a little above the player's shoulders. The *anchor* is what
	# travels — it walks straight at the player at the fly's own speed — and the body is
	# drawn a little off that anchor by its own wobble. A fly that added its wobble to its
	# own position instead would spend the whole summon drifting and never arrive
	var want: Vector3 = _player.global_position + Vector3(0.0, GO_FOR, 0.0)
	_wobble_at = _wobble_at.move_toward(want, _speed * delta)
	var wob: Vector3 = Vector3(
		sin(_phase * WOBBLE_SPEED) * WOBBLE,
		sin(_phase * WOBBLE_SPEED * 0.73 + 1.1) * WOBBLE * 0.6,
		cos(_phase * WOBBLE_SPEED * 0.87) * WOBBLE)
	global_position = _wobble_at + wob
	global_position.y = maxf(global_position.y, 0.35)
	if _eye != null:
		_eye.position.y = SIZE * 0.18

	if _wobble_at.distance_to(want) <= TOUCH:
		_player.call("hit", global_position)
		_fall()


## It has done its one thing, or it has run out of time.
func _fall() -> void:
	if _dying:
		return
	_dying = true
	_dead_t = 0.0
	AudioManager.play_sfx("fly_die", -9.0, randf_range(0.85, 1.25))


## The staff's lightning reaches them like anything else in the room: nothing special is
## asked of the weapon here, the fly just answers the question every creature answers.
func hit() -> void:
	_fall()


func aim_point() -> Vector3:
	return global_position


func hit_radius() -> float:
	return 0.5