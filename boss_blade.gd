class_name BossBlade
extends Node3D
## One blade off the fan behind her.
##
## It is aimed once, where the player was standing when it left her, and it does not track
## after that. A projectile that follows you is not a threat, it is a tax: this one is a
## line the player can see coming and step out of, which is the only kind of attack worth
## putting in a fight.

const ART := "res://assets/generated/boss_blade.png"
const ART_GLOW := "res://assets/generated/fx_glow_hot.png"

const HEIGHT := 1.65
const WIDTH := 0.42
const LIFE := 5.5
const TOUCH := 1.05
const Y_TRACK := 1.0
const SPIN := 2.6

const EDGE := Color(1.0, 0.22, 0.16)

var _dir: Vector3 = Vector3.FORWARD
var _speed: float = 11.5
var _life: float = 0.0
var _player: Node3D
var _spin: float = 0.0
var _mat: StandardMaterial3D
var _blade: MeshInstance3D
var _gleam: MeshInstance3D


## Where it starts, where it was told to go, who it is for, and how fast. Called after the
## node is in the tree, as everything else in this room is.
func setup(from: Vector3, to: Vector3, player: Node3D, speed: float) -> void:
	global_position = from
	_player = player
	_speed = speed
	var lead: Vector3 = to + Vector3(0.0, Y_TRACK, 0.0)
	_dir = (lead - from)
	if _dir.length_squared() < 0.0001:
		_dir = Vector3.FORWARD
	_dir = _dir.normalized()
	_spin = randf() * PI


func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(1.0, 1.0, 1.0)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_mat.alpha_scissor_threshold = 0.42
	_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_mat.emission_enabled = true
	_mat.emission = EDGE
	_mat.emission_energy_multiplier = 0.85
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mat.disable_receive_shadows = true
	var tex := load(ART) as Texture2D
	if tex == null:
		tex = PlaceholderTexture2D.new()
	_mat.albedo_texture = tex
	_mat.emission_texture = tex

	_blade = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(WIDTH, HEIGHT)
	_blade.mesh = quad
	_blade.material_override = _mat
	_blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_blade)

	# the gleam it leaves behind it, so a thin blade in a dark room is a thing the eye
	# catches even when the blade itself is edge-on
	_gleam = MeshInstance3D.new()
	var mote := QuadMesh.new()
	mote.size = Vector2(1.0, 1.0)
	_gleam.mesh = mote
	var m := StandardMaterial3D.new()
	var glow := load(ART_GLOW) as Texture2D
	if glow != null:
		m.albedo_texture = glow
	m.albedo_color = EDGE
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = EDGE
	m.emission_energy_multiplier = 1.1
	m.disable_receive_shadows = true
	_gleam.material_override = m
	_gleam.scale = Vector3.ONE * 0.9
	_gleam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_gleam)


func _process(delta: float) -> void:
	if GameState.is_paused:
		return
	_life += delta
	if _life >= LIFE:
		queue_free()
		return
	global_position += _dir * _speed * delta
	# a slow turn while it flies, and a size that breathes: a billboard has no rotation of
	# its own to give, so the movement is what sells it
	_spin += delta * SPIN
	var swell: float = 1.0 + 0.06 * sin(_spin)
	if _blade != null:
		_blade.scale = Vector3(1.0, swell, 1.0)
	if _player == null or not is_instance_valid(_player):
		return
	var at: Vector3 = _player.global_position + Vector3(0.0, 0.9, 0.0)
	if global_position.distance_to(at) <= TOUCH:
		_player.call("hit", global_position)
		AudioManager.play_sfx("sting", -14.0, 1.4)
		queue_free()