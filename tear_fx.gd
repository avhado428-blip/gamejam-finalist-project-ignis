extends Node2D

## The last room does not hold together, and it comes apart faster the closer you
## get to the cut. This stacks a second glitch pass on the one the room already
## runs and drives it off how far along the level you are, so the two of them
## never settle into a rhythm you can read.

const RAMP_START := 0.35
const RAMP_END := 1.0
## What the ramp measures against when the room has no camera bounds of its own.
const FALLBACK_WIDTH := 1280.0

var _glitch: Glitch
var _player: Node2D
var _level_width: float = FALLBACK_WIDTH


func _ready() -> void:
	_player = get_parent().get_node_or_null("Player") as Node2D
	_glitch = Glitch.new()
	_glitch.intensity = RAMP_START
	add_child(_glitch)
	var bounds: Variant = get_parent().get("camera_bounds")
	if bounds is Rect2:
		# the camera centre stops 320 short of the room's far edge
		_level_width = maxf((bounds as Rect2).size.x - 320.0, 1.0)


func _process(delta: float) -> void:
	if _player == null or _glitch == null:
		return
	var deep: float = clampf(_player.global_position.x / _level_width, 0.0, 1.0)
	var want: float = lerpf(RAMP_START, RAMP_END, deep)
	_glitch.intensity = lerpf(_glitch.intensity, want, minf(delta * 1.6, 1.0))
	# and every so often it tears for no reason at all
	if randf() < delta * (0.7 + deep * 1.5):
		_glitch.intensity = clampf(want + randf_range(0.1, 0.3), 0.0, 1.0)
