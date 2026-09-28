class_name ParkourBackdrop
extends Node3D
## The flat game's sky, and the dark under it, stood up around the room.
##
## Both worlds have always been the same two pictures: a torn-paper collage above,
## with a skyline about two thirds down it, and the void — a shaft that darkens all
## the way to black — hanging below the floor line. Here those pictures are the four
## walls of the room, placed so the collage's own skyline lands exactly on the height
## the course floats at. Above that line you are somewhere. Below it there is nothing.
##
## Neither picture is squashed into the wrong shape: the sky keeps its own 16:9, and
## the shaft is tiled sideways while its one gradient spans the whole drop, the way
## a single shaft does in the side-on game.

## Which picture belongs to which world. Keys are RealityManager.Reality values.
const SKY := {
	0: "res://assets/backgrounds/perceived/sky_white.png",
	1: "res://assets/backgrounds/true/sky_normal.png",
}
const VOID := {
	0: "res://assets/props/void_shaft_perceived.png",
	1: "res://assets/props/void_shaft_true.png",
}

## Where the skyline sits in both collages, measured down from the top of the picture.
const HORIZON := 0.655
## How tall the sky quad is. Big enough that the picture still fills the view when
## seen from the far wall, and the width follows the picture's own proportions.
const SKY_H := 168.0
## How far the void hangs below the floor line, and how wide the shaft texture is.
const VOID_H := 40.0
const SHAFT_TEX_W := 64.0

## How far the walls stand from the middle of the run.
const HALF := 96.0
const NEAR := 74.0
const FAR := -168.0
## How far inside each wall the void hangs: closer than the sky, so the dark covers
## the bottom of the picture instead of the picture showing through it.
const INSET := 22.0
const FLOOR_Y := -44.0

var _sky_mat: StandardMaterial3D
var _void_mat: StandardMaterial3D


func _ready() -> void:
	_build()
	react(RealityManager.current_reality)
	RealityManager.reality_changed.connect(react)


func _build() -> void:
	var sky_w: float = SKY_H * 1280.0 / 720.0
	# the skyline, not the middle of the picture, is what has to land on y 0
	var sky_y: float = SKY_H * HORIZON - SKY_H * 0.5
	var void_y: float = -VOID_H * 0.5

	_sky_mat = _art_material()
	_void_mat = _art_material()
	# sideways: one shaft every 64 pixels of picture. downwards: the whole gradient,
	# once, over the whole drop
	_void_mat.uv1_scale = Vector3(sky_w / SHAFT_TEX_W, 1.0, 1.0)

	_wall(sky_w, Vector3(0.0, sky_y, FAR), 0.0, Vector3(0.0, void_y, FAR + INSET), 0.0)
	_wall(sky_w, Vector3(0.0, sky_y, NEAR), 180.0, Vector3(0.0, void_y, NEAR - INSET), 180.0)
	_wall(sky_w, Vector3(-HALF, sky_y, 0.0), 90.0, Vector3(-HALF + INSET, void_y, 0.0), 90.0)
	_wall(sky_w, Vector3(HALF, sky_y, 0.0), -90.0, Vector3(HALF - INSET, void_y, 0.0), -90.0)

	# and a bottom, under the fog and well below the height the player is put back
	# from, so there is no seam to see if they look straight down while falling
	var floor_mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(600.0, 600.0)
	floor_mesh.mesh = quad
	floor_mesh.position = Vector3(0.0, FLOOR_Y, -40.0)
	floor_mesh.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var black := _art_material()
	black.albedo_color = Color(0.0, 0.0, 0.0)
	floor_mesh.material_override = black
	floor_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(floor_mesh)


## One wall: the world's sky, and the void hanging inside it.
func _wall(w: float, sky_pos: Vector3, sky_deg: float, void_pos: Vector3, void_deg: float) -> void:
	var sky := MeshInstance3D.new()
	var sky_quad := QuadMesh.new()
	sky_quad.size = Vector2(w, SKY_H)
	sky.mesh = sky_quad
	sky.position = sky_pos
	sky.rotation_degrees = Vector3(0.0, sky_deg, 0.0)
	sky.material_override = _sky_mat
	sky.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sky)

	var dark := MeshInstance3D.new()
	var dark_quad := QuadMesh.new()
	dark_quad.size = Vector2(w, VOID_H)
	dark.mesh = dark_quad
	dark.position = void_pos
	dark.rotation_degrees = Vector3(0.0, void_deg, 0.0)
	dark.material_override = _void_mat
	dark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dark)


## Backdrop art is not lit, not fogged and does not cast: it is a picture the room is
## standing inside, and the room's own lighting has to leave it alone.
func _art_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_receive_shadows = true
	m.disable_fog = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func react(reality: int) -> void:
	if _sky_mat == null:
		return
	var key: int = 1 if reality == RealityManager.Reality.TRUE else 0
	_sky_mat.albedo_texture = load(SKY[key]) as Texture2D
	_void_mat.albedo_texture = load(VOID[key]) as Texture2D
