extends CanvasLayer
## RealityFX — everything the shift does to the picture, in one place:
##   Haze  : white-haze overlay, shown while PERCEIVED
##   Dread : always-on vignette + grain + slow breathing (the mood layer)
##   Glitch: chromatic tear, ramped up/down around the swap
##   Flash : brief pop at the moment reality flips
##
## When the shift is muffled (AmbiguousShiftZone) the swap still happens — only
## this feedback is withheld: no glitch, no shake, a whisper of a flash.

var _haze: ColorRect
var _dread: ColorRect
var _glitch: ColorRect
var _flash: ColorRect


func _ready() -> void:
	layer = 5
	_haze = _make_rect("res://shaders/white_haze.gdshader", {})
	_dread = _make_rect("res://shaders/dread.gdshader", {})
	_glitch = _make_rect("res://shaders/glitch_chromatic.gdshader", {"amount": 0.0})
	_flash = _make_rect("res://shaders/transition_flash.gdshader", {"strength": 0.0})
	_set_glitch(0.0)
	_set_flash(0.0)

	_haze.visible = RealityManager.is_perceived()
	_apply_dread(RealityManager.current_reality)
	RealityManager.reality_changed.connect(_on_reality_changed)
	EventManager.reality_shift_started.connect(_on_shift_started)
	EventManager.request_flash.connect(_on_flash_requested)


func _make_rect(shader_path: String, params: Dictionary) -> ColorRect:
	var r := ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.color = Color(1, 1, 1, 1)
	var m := ShaderMaterial.new()
	m.shader = load(shader_path)
	for k in params.keys():
		m.set_shader_parameter(k, params[k])
	r.material = m
	add_child(r)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return r


func _on_reality_changed(new_reality: int) -> void:
	_haze.visible = new_reality == RealityManager.Reality.PERCEIVED
	_apply_dread(new_reality)


func _apply_dread(new_reality: int) -> void:
	var perceived := new_reality == RealityManager.Reality.PERCEIVED
	var m: ShaderMaterial = _dread.material
	m.set_shader_parameter("vignette", 1.30 if perceived else 1.05)
	m.set_shader_parameter("grain", 0.09 if perceived else 0.075)
	m.set_shader_parameter("desat", 0.22 if perceived else 0.14)
	m.set_shader_parameter("breathe", 0.13 if perceived else 0.08)
	m.set_shader_parameter("lift", 0.015 if perceived else 0.0)
	m.set_shader_parameter("cold", Color(0.86, 0.88, 0.96) if perceived else Color(0.76, 0.80, 0.92))


func _on_shift_started(_from: int, _to: int) -> void:
	var d := RealityManager.SHIFT_DURATION
	if RealityManager.shift_muffled:
		var faint := create_tween()
		faint.tween_method(_set_flash, 0.18, 0.0, 0.40)
		_spawn_shift_particles(true)
		return
	var up := create_tween()
	up.tween_method(_set_glitch, 0.0, 1.0, d * 0.45).set_trans(Tween.TRANS_QUAD)
	var down := create_tween()
	down.tween_interval(d * 0.45)
	down.tween_method(_set_glitch, 1.0, 0.0, d * 0.55).set_trans(Tween.TRANS_QUAD)
	var fl := create_tween()
	fl.tween_method(_set_flash, 0.85, 0.0, 0.16)
	_spawn_shift_particles(false)


func _spawn_shift_particles(faint: bool) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	if faint:
		Fx.burst(player.get_parent(), "res://assets/effects/shift_particles.png", 8, 8, 8, player.global_position, 10.0, 0.9)
		return
	Fx.burst(player.get_parent(), "res://assets/effects/shift_particles.png", 8, 8, 8, player.global_position, 18.0, 1.6)
	Fx.burst(player.get_parent(), "res://assets/effects/glitch_fragments.png", 8, 8, 8, player.global_position + Vector2(0, -10), 14.0, 2.0)


func _set_glitch(v: float) -> void:
	_glitch.material.set_shader_parameter("amount", v)
	_glitch.visible = v > 0.001


func _set_flash(v: float) -> void:
	_flash.material.set_shader_parameter("strength", v)
	_flash.visible = v > 0.001


func _on_flash_requested(color: Color, duration: float) -> void:
	_flash.material.set_shader_parameter("flash_color", color)
	var t := create_tween()
	t.tween_method(_set_flash, 1.0, 0.0, maxf(duration, 0.05))
