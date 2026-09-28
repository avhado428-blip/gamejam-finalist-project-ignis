class_name Ambience
extends Node2D
## Ambient dread. Lives in every level. Nothing here is interactive — it exists
## so the room never feels still:
##   - dust drifting across the view, always
##   - slow fog wisps
##   - and, rarely, a pair of eyes in the dark that blinks once and is gone

var _dust: CPUParticles2D
var _fog: CPUParticles2D
var _cam: Camera2D
var _eye_timer: float = 8.0

@export var dust_amount: int = 46
@export var fog_amount: int = 6
@export var eye_min_gap: float = 11.0
@export var eye_max_gap: float = 26.0


func _ready() -> void:
	z_index = -3
	_dust = _particles("res://assets/effects/dust_motes.png", Rect2(0, 0, 8, 8), dust_amount, 9.0, Vector2(0.0, -7.0), 3.0, 10.0, 0.5, 1.5, Color(1, 1, 1, 0.5))
	_dust.name = "Dust"
	add_child(_dust)
	_fog = _particles("res://assets/effects/fog_wisps.png", Rect2(0, 0, 64, 64), fog_amount, 18.0, Vector2(3.0, 0.0), -7.0, 7.0, 1.3, 2.8, Color(1, 1, 1, 0.14))
	_fog.name = "Fog"
	add_child(_fog)
	RealityManager.reality_changed.connect(_on_reality_changed)
	_on_reality_changed(RealityManager.current_reality)


func _particles(path: String, region: Rect2, amount: int, life: float, grav: Vector2, vmin: float, vmax: float, smin: float, smax: float, col: Color) -> CPUParticles2D:
	var at := AtlasTexture.new()
	at.atlas = load(path)
	at.region = region
	var p := CPUParticles2D.new()
	p.texture = at
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.local_coords = true
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700.0, 410.0)
	p.gravity = grav
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	p.color = col
	p.z_index = z_index
	return p


func _on_reality_changed(new_reality: int) -> void:
	var perceived := new_reality == RealityManager.Reality.PERCEIVED
	# In the pale world the motes have to be darker to be seen at all.
	_dust.color = Color(0.52, 0.53, 0.60, 0.42) if perceived else Color(0.92, 0.94, 1.0, 0.5)
	_fog.color = Color(0.80, 0.81, 0.87, 0.20) if perceived else Color(1, 1, 1, 0.13)


## How deep into the run this room is, 0..1. The deeper it goes, the more of the
## room is moving: more dust, more fog, and the eyes in the dark come more often.
## Called by the area after the particles exist, because a child's _ready runs
## before its parent's.
func apply_dread(depth: float) -> void:
	var d: float = clampf(depth, 0.0, 1.0)
	if _dust != null:
		_dust.amount = int(round(float(dust_amount) * (1.0 + d * 1.4)))
		_dust.initial_velocity_max = 10.0 + d * 6.0
	if _fog != null:
		_fog.amount = int(round(float(fog_amount) * (1.0 + d * 0.8)))
	eye_min_gap = lerpf(11.0, 4.0, d)
	eye_max_gap = lerpf(26.0, 9.0, d)


func _process(delta: float) -> void:
	if _cam == null:
		_cam = get_viewport().get_camera_2d()
	if _cam:
		global_position = _cam.get_screen_center_position()
	_eye_timer -= delta
	if _eye_timer <= 0.0:
		_eye_timer = randf_range(eye_min_gap, eye_max_gap)
		_reveal_eyes()


func _reveal_eyes() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("blink")
	sf.set_animation_speed("blink", 5.0)
	sf.set_animation_loop("blink", false)
	var tex: Texture2D = load("res://assets/effects/eyes_blink.png")
	for i in range(4):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * 16, 0, 16, 16)
		sf.add_frame("blink", at)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.modulate = Color(1, 1, 1, 0.0)
	spr.z_index = -4
	add_child(spr)
	spr.position = Vector2(randf_range(-320.0, 320.0), randf_range(-160.0, -50.0))
	spr.play("blink")
	var t := create_tween()
	t.tween_property(spr, "modulate:a", 0.9, 0.8)
	t.tween_interval(0.7)
	t.tween_property(spr, "modulate:a", 0.0, 0.5)
	t.tween_callback(spr.queue_free)
