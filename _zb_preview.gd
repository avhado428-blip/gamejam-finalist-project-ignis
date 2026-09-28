extends Node3D
## TEMPORARY verification harness — delete after the boss has been looked at.
##
## The projection preview the boss was built against cannot show what a tiling texture, an
## OmniLight and a glow pass actually do, so this stands her up in a real frame with the hall's
## own palette and films her from wherever PREVIEW_AT is pointed.

const PREVIEW_AT := Vector3(4.4, 3.05, 3.9)
const PREVIEW_LOOK := Vector3(0.0, 2.60, 0.0)


func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.016, 0.005, 0.005)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.52, 0.16, 0.13)
	e.ambient_light_energy = 0.34
	e.glow_enabled = true
	e.glow_intensity = 0.5
	e.glow_bloom = 0.15
	e.glow_hdr_threshold = 0.8
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	e.fog_enabled = true
	e.fog_density = 0.010
	e.fog_light_color = Color(0.085, 0.017, 0.014)
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.20
	sun.rotation_degrees = Vector3(-38.0, 26.0, 0.0)
	add_child(sun)

	var cam := Camera3D.new()
	cam.fov = 44.0
	cam.position = PREVIEW_AT
	add_child(cam)
	cam.look_at(PREVIEW_LOOK, Vector3.UP)
	cam.current = true

	var boss := TempleBoss.new()
	add_child(boss)
	boss.setup({"x": 0.0, "top": 0.0, "z": 0.0})
	boss.wake()