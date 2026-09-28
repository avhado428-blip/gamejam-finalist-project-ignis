class_name ParkourHall
extends Node3D
## The room the game stops lying in, stood up as the place the cut leads to.
##
## A circular temple, seen from inside: one wall running all the way round with no break
## in it, a ceiling of churning cloud over the wall's broken rim with one carved medallion
## hung under the middle of it, beams springing out of that wall with lanterns slung under
## them, banners hanging in the dark between them, and exactly one building standing on the
## floor. It is one gate, and it is not repeated anywhere — a wall that goes round in a ring
## cannot have four of anything on it, which is the whole reason it is a ring.
##
## It is flat, and it is in depth. Every layer sits at its own radius: the wall furthest
## out, then the piers on it, then the lanterns and the banners hung along it, then the
## beams and the lanterns slung under them, then the gate. Walking the room slides the near
## lanterns past fast and the wall barely at all. The room is a parallax.
##
## It is lit rather than painted. Every stone picture in here is a photograph of stone:
## desaturated, close to monochrome, with its own detail but almost none of its own colour.
## The colour is what the room is lit *by* — red lanterns, a shut door in the gate with a
## red seam of light under it, three cold shafts coming down through it, and a red light
## hanging over the middle of the floor —
## which is the only way one hall can be a blood temple in one world and a pale one in the
## other without owning two sets of pictures.
##
## Every stone surface carries its own picture again as its emission, so the wall glows in
## the colour of the world it is standing in. The world is what colours it: the true world
## soaks the hall in blood, which is what it is and what it opens in, and the false one
## washes it pale and cold. One set of pictures, two temples, and Q is the difference.

# ── the pictures everything in here is cut from ────────────────────────────

const FLOOR := "res://assets/generated/temple_floor_v2.png"
const WALL := "res://assets/generated/temple_wall_v2.png"
const SKY := "res://assets/generated/temple_ceiling_v2.png"
const MEDALLION := "res://assets/generated/temple_medallion.png"
const COLUMN := "res://assets/generated/temple_column.png"
const LANTERN := "res://assets/generated/temple_lamp_v2.png"
const BANNER := "res://assets/generated/temple_banner.png"
const RUBBLE := "res://assets/generated/temple_rubble.png"
const ROCK := "res://assets/generated/temple_rock_v2.png"
const GATE := "res://assets/generated/temple_gate_shut.png"
const MIST := "res://assets/generated/temple_mist.png"
const GLOW := "res://assets/generated/fx_glow_hot.png"

# ── how big the hall is ────────────────────────────────────────────────────

## One round room. The wall stands thirty metres out from the middle of the floor and
## twenty-four up, and the cloud closes over the top of it: there is no way out of here
## that is not through the gate.
const R_WALL := 30.0
const WALL_H := 24.0
const DOME_H := 26.0
const SEGMENTS := 64

## How often a picture repeats. Big numbers: stone should not look like wallpaper, and
## the wall gets the largest of them both because it is the biggest surface in here and
## because it is the one the player's eye is on for the longest.
const TILE_STONE := 9.0
const TILE_FLOOR := 8.0
const TILE_SKY := 26.0
const TILE_MEDALLION := 26.0

# ── what is built in it ────────────────────────────────────────────────────

## Beams springing out of the wall, the piers they land on, and the lanterns slung under
## them. The beams and the piers stand on the same eight spokes on purpose: a beam that
## lands on the top of a pier is a room that was put together rather than decorated.
const BEAMS := 8
const BEAM_Y := 19.5
const BEAM_IN := 20.0
const BEAM_THICK := 0.66
const PIER_R := 28.2
const PIER_H := 16.4
## A lantern hung under every beam, and a second tier hung straight off the wall, higher
## up and further out, so the ones the player walks under are not all at one height.
const LANTERN_H := 3.2
const LANTERN_R := 19.4
const LANTERN_Y := 13.4
const WALL_LANTERNS := 8
const WALL_LANTERN_R := 26.4
const WALL_LANTERN_Y := 10.2
## Banners hanging in the dark between them, at a radius nothing else stands at, because
## the picture this room is taken from has cloth hanging over a hall and no hall is a
## temple without something hanging in it.
const BANNERS := 6
const BANNER_H := 9.4
const BANNER_R := 24.6
const BANNER_Y := 11.0
## Broken slabs lying over the rim of the wall: the top of this room is not a clean
## circle, and the pieces that came off it are still up there.
const SLABS := 11
const SLAB_Y := 22.2

## The one gate. It stands on the floor with its arch at the height of a person's chest.
const GATE_Z := -25.0
const GATE_H := 19.0
const GATE_BASE := -0.35
const ARCH_Y := 5.2
## The doorway. The one door in the room is *shut* for the whole of the fight: it is a door,
## and a door that is already open is not a thing to win. What is behind it is what the room
## is lit by while it is shut — a dim red seam under a sealed door — and when the thing on
## the other side is put down, the seam becomes the brightest thing in the hall.
const PORTAL_H := 9.6
## Over-bright on purpose: the doorway is the one thing in here allowed to blow out, and
## the room's glow pass turns the top of that range into the bloom around it.
const PORTAL_RGB := Color(2.05, 0.62, 0.26)
const ARCH_DIM := 0.42
const ARCH_HOT := 14.0
## How fast the door gives: a door does not slide open, it takes a second and a half for
## something that size to stop being a door.
const PORTAL_RATE := 0.5

## What is lying around on the floor: bone and skull along the wall, wet boulders standing
## in the slabs, mist lying on it, and one broken timber frame off to the left of the way in.
const ROCKS := 11
const BONES := 17
const MISTS := 9
const SCAFFOLD_AT := Vector3(-20.5, 0.0, 7.0)

## The things in here that move on their own: the ceiling, the lanterns, the banners, the
## mist, and the ash coming up off the floor.
const CLOUD := Vector2(0.0032, 0.0013)
const SWAY := 0.5
const SWAY_ARC := 2.2
const BANNER_SWAY := 0.14
const MIST_DRIFT := 0.10
## How far away a prop is dropped. The room is sixty metres across; this is well past it.
const CULL := 160.0

## What each world does to the pictures. The wall is a dark photograph of near-black
## masonry and the floor is a bright one of pale wet slabs, so they cannot share a tint:
## one number over both of them turns either the wall into mud or the floor into paper.
##
## Above 1 on both, because the pictures are deliberately dark and the room is lit by its
## own surfaces as much as by its lights.
const TINT := {
	0: {
		# the wall is the biggest surface in the room and it is the one most easily ruined:
		# turn it up and the hall becomes a flat red box with masonry printed on it. It is
		# kept dim and only just glowing, so that what the player reads is not *a red wall*
		# but pools of red light standing on a dark one
		"stone": Color(1.58, 0.42, 0.34),
		"floor": Color(0.80, 0.22, 0.18),
		"sky": Color(1.02, 0.16, 0.13),
		"glow": Color(0.58, 0.05, 0.04),
		"energy": 0.92,
		"prop": Color(1.00, 1.00, 1.00),
		"mist": Color(0.52, 0.15, 0.13, 0.34),
		"lamp": Color(1.00, 0.30, 0.14),
		"shaft": Color(0.52, 0.68, 1.00),
		# the three shafts are the only cold light in the hall and they are the easiest thing
		# in it to overdo. A bright cone meeting a wet mirror floor is not a column of light,
		# it is a puddle that has been painted white: they are kept weak enough that what
		# lands on the stone reads as haze lying on it rather than as a second floor
		"shaft_energy": 2.0,
	},
	1: {
		"stone": Color(2.60, 2.55, 2.50),
		"floor": Color(0.86, 0.87, 0.92),
		"sky": Color(1.45, 1.50, 1.66),
		"glow": Color(0.14, 0.14, 0.18),
		"energy": 0.20,
		"prop": Color(0.60, 0.64, 0.72),
		"mist": Color(0.72, 0.74, 0.80, 0.26),
		"lamp": Color(0.72, 0.80, 1.00),
		"shaft": Color(0.72, 0.82, 1.00),
		"shaft_energy": 1.35,
	},
}

var _stone: Array[StandardMaterial3D] = []
var _floors: Array[StandardMaterial3D] = []
var _glow: Array[StandardMaterial3D] = []
var _props: Array[Sprite3D] = []
var _mist: Array[Sprite3D] = []
var _mist_home: Array[Vector3] = []
var _wrap: Array[Node3D] = []
var _wrap_home: Array[Vector3] = []
## The materials the room's *modelled* props are made of, and the colour each was cut at, so
## the world switch can tint them the same way it tints the sprites.
var _prop_mats: Array[StandardMaterial3D] = []
var _prop_base: Array[Color] = []
## One flattened texture per picture, so a cutout is only composited once however many props
## stand in the room wearing it.
var _flat_cache: Dictionary = {}
var _lanterns: Array[Node3D] = []
var _lights: Array[OmniLight3D] = []
var _shafts: Array[SpotLight3D] = []
var _ceil: ShaderMaterial
var _ceil_uv := Vector2.ZERO
var _gate: Sprite3D
var _arch: OmniLight3D
var _arch_energy := 1.0
## The light standing in the shut doorway, and how far it has opened: 0 is a sealed door in
## a dark wall and 1 is the way out.
var _portal: Sprite3D
var _portal_t := 0.0
var _portal_open := false
var _t := 0.0


func _ready() -> void:
	_build()
	react(RealityManager.current_reality)
	RealityManager.reality_changed.connect(react)


func _process(delta: float) -> void:
	if GameState.is_paused:
		return
	_t += delta
	if _ceil != null:
		_ceil_uv.x = fmod(_ceil_uv.x + CLOUD.x * delta, 1.0)
		_ceil_uv.y = fmod(_ceil_uv.y + CLOUD.y * delta, 1.0)
		_ceil.set_shader_parameter("scroll", _ceil_uv)
	for i in _lanterns.size():
		var pivot: Node3D = _lanterns[i]
		pivot.rotation_degrees.z = sin(_t * SWAY + float(i) * 1.7) * SWAY_ARC
	for i in _mist.size():
		var s: Sprite3D = _mist[i]
		var home: Vector3 = _mist_home[i]
		s.position.x = home.x + sin(_t * MIST_DRIFT + float(i)) * 1.6
		s.position.z = home.z + cos(_t * MIST_DRIFT * 0.8 + float(i) * 1.3) * 1.6
	for i in _wrap.size():
		var b: Node3D = _wrap[i]
		var bh: Vector3 = _wrap_home[i]
		b.position = bh + Vector3(sin(_t * 0.6 + float(i) * 1.9) * BANNER_SWAY,
			sin(_t * 0.8 + float(i) * 1.3) * 0.09, 0.0)
	if _portal != null:
		var want: float = 1.0 if _portal_open else 0.0
		if not is_equal_approx(_portal_t, want):
			_portal_t = move_toward(_portal_t, want, delta * PORTAL_RATE)
			_portal.modulate = Color(PORTAL_RGB.r, PORTAL_RGB.g, PORTAL_RGB.b, _portal_t * 0.9)
			_portal.scale = Vector3.ONE * lerpf(0.55, 1.0, ease(_portal_t, 0.45))
	if _arch != null:
		_arch_energy = lerpf(ARCH_DIM, ARCH_HOT, _portal_t)
		_arch.light_energy = _arch_energy * (0.88 + 0.12 * sin(_t * 1.7))


# ── building it ────────────────────────────────────────────────────────────

func _build() -> void:
	_build_floor()
	_build_wall()
	_build_ceiling()
	_build_medallion()
	_build_rim()
	_build_frame()
	_build_gate()
	_build_light()
	_build_ash()
	_scatter()


## The floor: one disc of wet, cracked slabs, and the one surface in here that answers a
## light with a reflection. There is no standing water laid on top of it: the mirror is the
## floor itself, and the whole room lands in it — the wall, the gate, the lanterns and the
## one door out. Roughness is what makes the reflection hard, and a hard reflection on dark
## stone is most of what makes a floor read as wet rather than as rock.
func _build_floor() -> void:
	var mat := _stone_mat(FLOOR, Vector2(R_WALL * 2.0 / TILE_FLOOR, R_WALL * 2.0 / TILE_FLOOR),
		0.15, 0.32)
	mat.emission_enabled = false
	_floors.append(mat)
	var mi := _cyl(R_WALL, 2.0, -1.0, mat, true)
	mi.name = "Floor"


## The wall, in one piece and all the way round. A cylinder rather than four walls: this
## is the one shape the room cannot repeat anything on.
func _build_wall() -> void:
	var mat := _stone_mat(WALL, Vector2(TAU * R_WALL / TILE_STONE, WALL_H / TILE_STONE), 0.86, 0.0)
	mat.emission_enabled = true
	var mi := _cyl(R_WALL, WALL_H, WALL_H * 0.5, mat, false)
	mi.name = "Wall"
	_glow.append(mat)


## And the cloud over it: a dome rather than a lid, because the ceiling of this room
## curves away towards the wall on every side and the picture of it is what the player
## spends the whole fight under. It is drawn through a small shader rather than a material
## because it has to *move*: a churning ceiling is a ceiling for about four seconds and a
## photograph of one forever after.
func _build_ceiling() -> void:
	var mi := MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = R_WALL
	dome.height = DOME_H
	dome.is_hemisphere = true
	dome.radial_segments = SEGMENTS
	dome.rings = 20
	mi.mesh = dome
	mi.position = Vector3(0.0, WALL_H, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ceil = ShaderMaterial.new()
	_ceil.shader = load("res://scenes/temple_cloud.gdshader") as Shader
	_ceil.set_shader_parameter("albedo_tex", load(SKY))
	_ceil.set_shader_parameter("tiles", Vector2(6.0, 2.0))
	_ceil.set_shader_parameter("scroll", Vector2.ZERO)
	_ceil.set_shader_parameter("tint", TINT[1]["sky"])
	mi.material_override = _ceil
	add_child(mi)


## The one carved disc hung under the middle of the cloud. It is a real disc of stone and
## not a picture of one, so it takes the same tint and the same emission as the wall and
## lands in the floor's reflection like everything else up there.
func _build_medallion() -> void:
	var mat := _stone_mat(MEDALLION, Vector2(1.0, 1.0) * (R_WALL / TILE_MEDALLION), 0.78, 0.10)
	mat.emission_enabled = true
	var mi := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 11.5
	disc.bottom_radius = 11.5
	disc.height = 0.34
	disc.radial_segments = SEGMENTS
	disc.rings = 1
	# the disc hangs under the cloud and is looked *up* at, so the face that exists is the
	# one pointing down at the floor
	disc.cap_top = false
	disc.cap_bottom = true
	mi.mesh = disc
	mi.material_override = mat
	mi.position = Vector3(0.0, WALL_H + 3.2, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_glow.append(mat)


## What came off the rim. Flat, dark, at angles, and over the ceiling's own edge, so the
## top of the room is broken rather than drawn as a circle.
func _build_rim() -> void:
	var dark := _dark(Color(0.05, 0.045, 0.055), 0.8)
	for i in SLABS:
		var a: float = TAU * float(i) / float(SLABS) + 0.35
		var slab := _box(Vector3(2.4 + float(i % 3) * 1.6, 0.9, 5.0 + float(i % 2) * 2.0),
			_dir(a) * (R_WALL - 2.6) + Vector3(0.0, SLAB_Y, 0.0), dark)
		slab.rotation.y = a
		slab.rotation.z = -0.10 + 0.05 * float(i % 4)


## The piers and the beams: eight of each, on the same spokes. This is the skeleton the
## room is hung off, and it is what the lanterns hang from.
func _build_frame() -> void:
	var wood := _dark(Color(0.055, 0.05, 0.062), 0.72)
	for i in BEAMS:
		var a: float = TAU * float(i) / float(BEAMS) + PI / float(BEAMS)
		var dir := _dir(a)
		# the pier the beam lands on, standing on the wall — a pillar in the round now,
		# not a card that turns to face the player
		_column(dir * PIER_R + Vector3(0.0, PIER_H * 0.5, 0.0))
		# the beam itself, lying along the spoke
		var beam := _box(Vector3(R_WALL - BEAM_IN, BEAM_THICK, BEAM_THICK),
			dir * ((R_WALL + BEAM_IN) * 0.5) + Vector3(0.0, BEAM_Y, 0.0), wood)
		beam.rotation.y = a
		# the rope, and the lantern hanging off the end of the beam
		var _rope := _box(Vector3(0.09, BEAM_Y - LANTERN_Y, 0.09),
			dir * LANTERN_R + Vector3(0.0, (BEAM_Y + LANTERN_Y) * 0.5, 0.0), wood)
		var pivot := Node3D.new()
		pivot.position = dir * LANTERN_R + Vector3(0.0, LANTERN_Y, 0.0)
		add_child(pivot)
		_hang_lantern(pivot, i, i % 2 == 0)
	# and the higher tier, hung straight off the wall
	for i in WALL_LANTERNS:
		var a: float = TAU * float(i) / float(WALL_LANTERNS)
		var dir := _dir(a)
		var _rope := _box(Vector3(0.09, 5.4, 0.09),
			dir * WALL_LANTERN_R + Vector3(0.0, WALL_LANTERN_Y + 2.7, 0.0), wood)
		var pivot := Node3D.new()
		pivot.position = dir * WALL_LANTERN_R + Vector3(0.0, WALL_LANTERN_Y, 0.0)
		add_child(pivot)
		_hang_lantern(pivot, i + 40, i % 3 == 0)
	# and the cloth, hanging in the gaps between them
	for i in BANNERS:
		var a: float = TAU * float(i) / float(BANNERS) + 0.55
		var dir := _dir(a)
		var cloth := _cloth(dir * BANNER_R + Vector3(0.0, BANNER_Y, 0.0), BANNER_H)
		cloth.name = "Banner%d" % i
		_wrap.append(cloth)
		_wrap_home.append(cloth.position)


## One lantern, on the end of its rope. It is a picture rather than a model — a lantern
## that always turns to face the player never turns into a paper edge — and the light is
## in only some of them, because sixteen omni lights in a closed room is a light show on a
## laptop and these are their own picture anyway.
func _hang_lantern(pivot: Node3D, index: int, lit: bool) -> void:
	var lamp := _prop(LANTERN, LANTERN_H, Vector3(0.0, -LANTERN_H * 0.5, 0.0), true, pivot)
	lamp.name = "Lantern%d" % index
	_lanterns.append(pivot)
	if lit:
		_lamp(pivot.global_position if pivot.is_inside_tree() else pivot.position, 1.6, 16.0)


## The one gate. Facing the middle of the room, standing on the floor of it, with the
## arch lit from inside: this is the only building in here and the whole room is aimed at
## it. There is a body behind the facade so that walking round the side of it shows a
## building rather than a picture.
func _build_gate() -> void:
	var wood := _dark(Color(0.06, 0.055, 0.07), 0.86)
	var mass := _box(Vector3(13.0, GATE_H * 0.74, 4.0),
		Vector3(0.0, GATE_H * 0.37, GATE_Z - 2.3), wood)
	mass.name = "GateMass"

	_gate = Sprite3D.new()
	# this doorway is the thing the whole hall is aimed at, so its picture is loaded the
	# forgiving way: through the import cache when there is one, straight out of the file when
	# the editor has not caught up yet, and as a flat colour rather than a hole when there is
	# no picture at all. It is not allowed to come up as a white rectangle.
	var tex: Texture2D = null
	# the import cache first: an exported build has no loose PNG for Image.load_from_file to
	# read, and a doorway missing from the shipped game is a worse bug than a line in the log.
	# The file is only fallen back to while the editor has not caught up with it yet
	if ResourceLoader.exists(GATE):
		tex = load(GATE) as Texture2D
	if tex == null:
		var img: Image = Image.load_from_file(GATE)
		if img != null:
			img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
	if tex == null:
		tex = PlaceholderTexture2D.new()
	_gate.texture = tex
	_gate.pixel_size = GATE_H / float(tex.get_height())
	# not billboarded, and facing +Z: this is a building, and a building that turned to
	# look at the player would be the one thing in the room that is not a place
	_gate.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_gate.shaded = false
	_gate.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_gate.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_gate.position = Vector3(0.0, GATE_BASE + GATE_H * 0.5, GATE_Z)
	_gate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_gate.visibility_range_end = CULL
	add_child(_gate)
	_props.append(_gate)

	# the light in the doorway, which is the only warm thing in here and the only reason
	# the floor in front of the gate is not black — and which, because the door is shut, is
	# a dim red seam under it rather than a fire
	_arch = _lamp(Vector3(0.0, ARCH_Y, GATE_Z + 1.4), ARCH_DIM, 34.0)
	_arch.name = "Arch"
	_arch_energy = ARCH_DIM

	# and what is inside the doorway, which is nothing at all yet. One glow standing in the
	# arch, off, hidden only by its own alpha: the door lighting up from the inside is the
	# whole of the ending, so it is built here and left dark until there is a reason for it
	var gl: Texture2D = load(GLOW)
	_portal = Sprite3D.new()
	_portal.name = "Portal"
	_portal.texture = gl
	_portal.pixel_size = PORTAL_H / float(gl.get_width())
	# facing +Z like the building it is set into, and not lit by the room: it *is* the light
	_portal.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_portal.shaded = false
	_portal.transparent = true
	_portal.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_portal.position = Vector3(0.0, ARCH_Y - 0.35, GATE_Z + 0.5)
	_portal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_portal.visibility_range_end = CULL
	_portal.modulate = Color(PORTAL_RGB.r, PORTAL_RGB.g, PORTAL_RGB.b, 0.0)
	add_child(_portal)


## The one thing in this room that ever changes: the thing behind the door has been put
## down, so the door lights from the inside and the floor in front of it turns warm. Nothing
## is rebuilt and nothing is swapped — the door is the reward and the door is the way out.
func open_portal() -> void:
	if _portal_open:
		return
	_portal_open = true
	# Stone moving somewhere it has not moved in a long time, and light arriving behind it.
	# It is the loudest thing in the room that is not her, which is the point: the player is
	# meant to look back at the door rather than be told about it.
	AudioManager.play_sfx("gate_open", -3.0, 1.0)


## What the room is lit *by*. The stone in here is nearly colourless on purpose, so the
## colour of the temple is entirely this: three cold shafts falling through the upper air,
## and one dull red light hanging over the middle of the floor so that the wall the player
## is walking towards is never a black hole.
func _build_light() -> void:
	var shafts := [
		[Vector3(-15.0, 21.0, -13.0), Vector3(-2.0, 0.0, 3.0)],
		[Vector3(17.0, 20.0, -15.0), Vector3(3.0, 0.0, -3.0)],
		[Vector3(-19.0, 19.0, 15.0), Vector3(0.0, 0.0, 1.0)],
	]
	for entry in shafts:
		var l := SpotLight3D.new()
		l.light_color = TINT[1]["shaft"]
		l.light_energy = float(TINT[1]["shaft_energy"])
		l.spot_range = 48.0
		# wide and soft on purpose: a narrow bright cone is a spotlight, and what this room
		# wants is three cold holes in the ceiling of it, not three white circles on the floor
		l.spot_angle = 31.0
		l.spot_angle_attenuation = 1.15
		l.shadow_enabled = false
		add_child(l)
		l.position = entry[0]
		l.look_at(entry[1], Vector3.UP)
		_shafts.append(l)

	var fill := OmniLight3D.new()
	fill.name = "Fill"
	fill.light_color = Color(1.0, 0.32, 0.22)
	fill.light_energy = 0.9
	fill.omni_range = 46.0
	fill.shadow_enabled = false
	fill.position = Vector3(0.0, 7.0, 0.0)
	add_child(fill)
	_lights.append(fill)


## Ash coming up off the floor and hanging in the air: the cheapest possible way to make a
## still room read as a room something is happening in.
func _build_ash() -> void:
	var p := CPUParticles3D.new()
	p.name = "Ash"
	p.amount = 80
	p.lifetime = 9.0
	p.local_coords = true
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(R_WALL * 0.85, 3.0, R_WALL * 0.85)
	p.direction = Vector3(0.0, 1.0, 0.0)
	p.spread = 25.0
	p.gravity = Vector3(0.0, 0.11, 0.0)
	p.initial_velocity_min = 0.06
	p.initial_velocity_max = 0.34
	p.scale_amount_min = 0.03
	p.scale_amount_max = 0.09
	p.color = Color(1.5, 0.42, 0.30)
	p.position = Vector3(0.0, 2.0, 0.0)
	var mote := QuadMesh.new()
	mote.size = Vector2(1.0, 1.0)
	mote.material = _mote_mat()
	p.mesh = mote
	add_child(p)


func _mote_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var tex := load(GLOW) as Texture2D
	if tex != null:
		m.albedo_texture = tex
	m.albedo_color = Color(1.0, 0.30, 0.20)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = Color(1.4, 0.36, 0.24)
	m.emission_energy_multiplier = 1.1
	m.disable_receive_shadows = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Bone and skull along the wall, wet rock standing in the slabs, mist lying on the floor,
## and one broken timber frame off to the left of the way in.
func _scatter() -> void:
	for i in ROCKS:
		var a: float = TAU * float(i) / float(ROCKS) + 0.9
		var r: float = randf_range(12.0, R_WALL - 3.0)
		var h: float = randf_range(1.5, 3.1)
		_rock(Vector3(cos(a) * r, h * 0.30, -sin(a) * r), h)

	for i in BONES:
		var a: float = TAU * float(i) / float(BONES) + 0.4
		var r: float = randf_range(19.0, R_WALL - 1.0)
		var h: float = randf_range(0.8, 1.7)
		_rubble(Vector3(cos(a) * r, h * 0.28, -sin(a) * r), h)

	for i in MISTS:
		var a: float = TAU * float(i) / float(MISTS) + 0.9
		var r: float = randf_range(17.0, 26.0)
		var home := Vector3(cos(a) * r, 0.7, -sin(a) * r)
		if i >= MISTS - 2:
			home = Vector3(float(i - MISTS + 2) * 12.0 - 6.0, 0.7, GATE_Z + 4.0)
		var s := _prop(MIST, randf_range(6.0, 10.0), home, true)
		s.transparent = true
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		_mist.append(s)
		_mist_home.append(home)

	_scaffold()


## The one structure that is not stone: a timber frame standing off to the left of the way
## in, half of it still up. It is what the reference picture has where a second building
## would go, which is the reason it is a frame and not an arch.
func _scaffold() -> void:
	var at := SCAFFOLD_AT
	var wood_mat := _dark(Color(0.05, 0.045, 0.055), 0.78)
	# four posts
	_box(Vector3(0.55, 7.4, 0.55), at + Vector3(-4.5, 3.7, -1.7), wood_mat)
	_box(Vector3(0.55, 7.4, 0.55), at + Vector3(4.5, 3.7, -1.7), wood_mat)
	_box(Vector3(0.55, 5.6, 0.55), at + Vector3(-4.5, 2.8, 1.7), wood_mat)
	_box(Vector3(0.55, 7.4, 0.55), at + Vector3(4.5, 3.7, 1.7), wood_mat)
	# two rails across the top, and one along each side
	_box(Vector3(9.6, 0.5, 0.5), at + Vector3(0.0, 7.2, -1.7), wood_mat)
	_box(Vector3(9.6, 0.5, 0.5), at + Vector3(0.0, 5.4, 1.7), wood_mat)
	_box(Vector3(0.5, 0.5, 3.9), at + Vector3(-4.5, 7.2, 0.0), wood_mat)
	_box(Vector3(0.5, 0.5, 3.9), at + Vector3(4.5, 7.2, 0.0), wood_mat)
	# and one beam lying across the top of it, off the square, so it is not a tidy box
	var lean := _box(Vector3(8.4, 0.42, 0.42), at + Vector3(1.0, 8.1, -0.4), wood_mat)
	lean.rotation.y = 0.35


# ── the shapes it is built out of ──────────────────────────────────────────

func _dir(a: float) -> Vector3:
	return Vector3(cos(a), 0.0, -sin(a))


func _cyl(radius: float, height: float, y: float, mat: Material, caps: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = SEGMENTS
	m.rings = 1
	m.cap_top = caps
	m.cap_bottom = caps
	mi.mesh = m
	mi.material_override = mat
	mi.position = Vector3(0.0, y, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


## A stone surface: the picture, tiled, lit and able to catch a reflection. It is not
## given an emission unless it asks for one, so the floor stays dark under the lanterns
## while the wall glows.
func _stone_mat(path: String, rep: Vector2, rough: float, metal: float) -> StandardMaterial3D:
	var tex := load(path) as Texture2D
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = Vector3(rep.x, rep.y, 1.0)
	m.roughness = rough
	m.metallic = metal
	# a wall has two sides and the room is on the inside of it
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if tex != null:
		m.emission_texture = tex
	_stone.append(m)
	return m


## A picture that is not stone and not sky: dark, unlit by the world, and left alone by
## `react`. The broken slabs and the timber in here are silhouettes in either world, and
## a silhouette is the one thing in a room that can never stop being visible.
func _dark(col: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## A texture read off disk with its transparency laid over a background first. These props
## are photographs of stone cut out on nothing, and a cutout wrapped round a real object is a
## real object full of holes: flattening the nothing to the colour of the stone the thing
## stands on is what lets the picture be *on* a mesh instead of being the mesh.
func _flat_tex(path: String, bg: Color) -> Texture2D:
	if _flat_cache.has(path):
		return _flat_cache[path] as Texture2D
	# read it as the imported resource rather than off disk, so this keeps working in an
	# exported build and not only in the editor
	var src := load(path) as Texture2D
	var base: Image = src.get_image() if src != null else null
	if base == null:
		_flat_cache[path] = src
		return src
	var img := base.duplicate() as Image
	var w: int = img.get_width()
	var h: int = img.get_height()
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var a: float = c.a
			if a < 0.999:
				img.set_pixel(x, y, Color(
					c.r * a + bg.r * (1.0 - a),
					c.g * a + bg.g * (1.0 - a),
					c.b * a + bg.b * (1.0 - a), 1.0))
	img.generate_mipmaps()
	var made := ImageTexture.create_from_image(img)
	_flat_cache[path] = made
	return made


## A material for a prop that is real geometry: the stone's own picture, flattened onto the
## stone's own colour so it can be wrapped onto a mesh.
func _prop_mat(path: String, bg: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _flat_tex(path, bg)
	m.roughness = rough
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_prop_mats.append(m)
	_prop_base.append(Color.WHITE)
	return m


## A piece of the room that has a body. Every modelled prop is placed through here, so there
## is nothing in the hall that is only a picture.
func _mesh(mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


## A pier: a real column, standing on the wall, with a base and a capital so it reads as a
## pillar and not as a pipe. The carving is wrapped round it, so it is a column from every
## side instead of a picture that swivels to face the player.
func _column(pos: Vector3) -> void:
	var mat := _prop_mat(COLUMN, Color(0.06, 0.055, 0.06), 0.88)
	mat.uv1_scale = Vector3(2.0, 1.0, 1.0)
	var shaft := CylinderMesh.new()
	shaft.top_radius = 1.02
	shaft.bottom_radius = 1.02
	shaft.height = PIER_H
	shaft.radial_segments = 16
	_mesh(shaft, mat, pos)
	var cap := BoxMesh.new()
	cap.size = Vector3(2.6, 0.7, 2.6)
	_mesh(cap, mat, pos + Vector3(0.0, PIER_H * 0.5, 0.0))
	var base := BoxMesh.new()
	base.size = Vector3(2.9, 0.8, 2.9)
	_mesh(base, mat, pos - Vector3(0.0, PIER_H * 0.5, 0.0))


## A boulder: a small cluster of rounded masses, so it is a rock in the round. The wet stone
## picture is wrapped onto the masses, and the nothing around it is laid over the colour of
## the floor it sits on.
func _rock(pos: Vector3, h: float) -> void:
	var mat := _prop_mat(ROCK, Color(0.08, 0.07, 0.07), 0.95)
	for i in 3:
		var r: float = maxf(0.32, h * (0.42 - 0.09 * float(i)))
		var s := SphereMesh.new()
		s.radius = r
		s.height = r * 2.0
		s.radial_segments = 8
		s.rings = 5
		var off := Vector3(randf_range(-0.5, 0.5) * h, r * 0.7 + float(i) * h * 0.12,
			randf_range(-0.5, 0.5) * h)
		var mi := _mesh(s, mat, pos + off)
		mi.rotation_degrees = Vector3(randf_range(0.0, 360.0), randf_range(0.0, 360.0), randf_range(0.0, 360.0))
		mi.scale = Vector3(randf_range(0.8, 1.3), randf_range(0.6, 0.9), randf_range(0.8, 1.3))


## Rubble: the bone and broken stone the room is strewn with, as low masses lying on the
## floor rather than a card laid flat on it.
func _rubble(pos: Vector3, h: float) -> void:
	var mat := _prop_mat(RUBBLE, Color(0.10, 0.09, 0.09), 0.95)
	for i in 4:
		var r: float = maxf(0.24, h * (0.40 - 0.06 * float(i)))
		var s := SphereMesh.new()
		s.radius = r
		s.height = r * 2.0
		s.radial_segments = 7
		s.rings = 4
		var off := Vector3(randf_range(-0.9, 0.9) * h, r * 0.45, randf_range(-0.9, 0.9) * h)
		var mi := _mesh(s, mat, pos + off)
		mi.scale = Vector3(randf_range(1.1, 1.7), randf_range(0.45, 0.65), randf_range(1.1, 1.7))


## A banner: real cloth on a real frame. A thin slab carrying the banner picture, so it hangs
## in the hall instead of turning to face the player.
func _cloth(pos: Vector3, h: float) -> MeshInstance3D:
	var m := StandardMaterial3D.new()
	var tex := load(BANNER) as Texture2D
	if tex != null:
		m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.45
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = Color(0.20, 0.02, 0.02)
	m.emission_energy_multiplier = 0.5
	_prop_mats.append(m)
	_prop_base.append(Color.WHITE)
	var w: float = h * 0.42
	var box := BoxMesh.new()
	box.size = Vector3(w, h, 0.12)
	return _mesh(box, m, pos)


func _prop(art: String, height: float, pos: Vector3, billboard := true, parent: Node3D = null) -> Sprite3D:
	var s := Sprite3D.new()
	var tex := load(art) as Texture2D
	# a picture that is not there still has to *be* a picture, or one unimported file
	# takes the whole room down with it
	if tex == null:
		tex = PlaceholderTexture2D.new()
	s.texture = tex
	s.pixel_size = height / float(tex.get_height())
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	s.position = pos
	s.visibility_range_end = CULL
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent == null:
		add_child(s)
	else:
		parent.add_child(s)
	_props.append(s)
	return s


## A light in the room. It carries no shadow: this hall is a lantern-lit cave and every
## shadow-casting light in it is another full pass over the room.
func _lamp(pos: Vector3, energy: float, reach: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = TINT[1]["lamp"]
	l.light_energy = energy
	l.omni_range = reach
	l.shadow_enabled = false
	l.position = pos
	add_child(l)
	_lights.append(l)
	return l


# ── the world switch ───────────────────────────────────────────────────────

## The world is the paint. Nothing in here is an overlay and nothing in here is hidden by
## a switch: the same hall is standing in both worlds and only its colour changes, which
## is what makes the true one the real one and the pale one the picture of it.
func react(reality: int) -> void:
	# 0 is the true world and 1 is the picture of it. Getting this the wrong way round is
	# not a subtle mistake: it paints the blood hall pale and calls it the truth
	var key: int = 0 if reality == RealityManager.Reality.TRUE else 1
	var t: Dictionary = TINT[key]
	for m in _stone:
		m.albedo_color = t["stone"]
	for m in _floors:
		m.albedo_color = t["floor"]
	for m in _glow:
		m.emission_enabled = true
		m.emission = t["glow"]
		m.emission_energy_multiplier = float(t["energy"])
	if _ceil != null:
		_ceil.set_shader_parameter("tint", t["sky"])
	for s in _props:
		s.modulate = t["prop"]
	for i in _prop_mats.size():
		_prop_mats[i].albedo_color = _prop_base[i] * t["prop"]
	for s in _mist:
		s.modulate = t["mist"]
	for l in _lights:
		l.light_color = t["lamp"]
	for l in _shafts:
		l.light_color = t["shaft"]
		l.light_energy = float(t["shaft_energy"])
