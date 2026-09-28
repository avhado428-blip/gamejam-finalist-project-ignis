class_name Glitch
extends CanvasLayer
## The picture is not well, and it gets worse.
##
## Sits between the world and the HUD (layer 8) and redraws every frame slightly
## wrong: torn rows, separated colour, a bright band rolling down the screen like
## a bad sync. `intensity` (0..1) is set by the area from how deep into the run
## the player is, so the first area is almost clean and the last one is barely
## holding itself together.
##
## On top of that it tears on its own, at random, more often the worse it gets —
## and it always tears when reality does, because shifting between two worlds is
## not something the picture survives cleanly.

const SHADER := preload("res://effects/glitch.gdshader")

## 0 = the picture is fine. 1 = the picture is nearly gone.
@export var intensity: float = 0.0
## How often it tears on its own, at intensity 0 and at intensity 1.
@export var calm_gap: Vector2 = Vector2(9.0, 18.0)
@export var dread_gap: Vector2 = Vector2(1.6, 4.5)

var _rect: ColorRect
var _mat: ShaderMaterial
var _burst: float = 0.0
var _gap: float = 0.0
var _roll: float = -1.0
var _roll_speed: float = 0.0


func _ready() -> void:
	layer = 8
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_rect = ColorRect.new()
	_rect.material = _mat
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gap = randf_range(2.0, 6.0)
	EventManager.reality_shift_finished.connect(_on_shift)
	_push()


func _process(delta: float) -> void:
	if GameState.is_paused:
		return
	_burst = maxf(0.0, _burst - delta * 3.2)
	_gap -= delta
	if _gap <= 0.0:
		_gap = randf_range(lerpf(calm_gap.x, dread_gap.x, intensity), lerpf(calm_gap.y, dread_gap.y, intensity))
		_burst = randf_range(0.35, 0.9)
		if randf() < 0.25 + intensity * 0.4:
			_roll = -0.05
			_roll_speed = randf_range(0.8, 1.7)
	if _roll >= 0.0:
		_roll += _roll_speed * delta
		if _roll > 1.12:
			_roll = -1.0
	_push()


func _push() -> void:
	_mat.set_shader_parameter("strength", intensity)
	_mat.set_shader_parameter("burst", _burst)
	_mat.set_shader_parameter("roll", _roll)


## Shifting between the two worlds costs the picture something.
func _on_shift(_reality: int) -> void:
	_burst = maxf(_burst, 0.55 + intensity * 0.35)


## Tear now, on cue — for a story beat the picture cannot take.
func burst(amount: float = 0.8) -> void:
	_burst = maxf(_burst, amount)
