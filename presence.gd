class_name Presence
extends CanvasLayer
## Something in the room has been aware of you for longer than you have been
## here — but it never says a word. It only breathes, and moves.
##
## It used to talk. It does not any more: a room that explains itself is not
## frightening, and a room that keeps saying so is only embarrassing. What is
## left is the body language of a thing you cannot see — distant drips, stone
## settling somewhere above, and every so often the whole room going dark for
## half a beat as though something crossed in front of it.
##
## It gets worse the deeper the run goes: `dread` (0..1, set by the area) scales
## how often the room moves, and how hard.

## 0 = the room is still. 1 = the room is not still at all.
@export var dread: float = 0.0

var _breath: float = 0.0
var _dark: float = 0.0


func _ready() -> void:
	layer = 7
	_breath = randf_range(3.0, 7.0)
	_dark = randf_range(12.0, 30.0)
	EventManager.reality_shift_finished.connect(_on_shift_finished)


func _process(delta: float) -> void:
	if GameState.is_paused:
		return
	var quicken: float = 1.0 + dread * 1.6
	_breath -= delta * quicken
	if _breath <= 0.0:
		_breath = randf_range(6.0, 15.0)
		_exhale()
	_dark -= delta * quicken
	if _dark <= 0.0:
		_dark = randf_range(34.0, 76.0)
		_pass_in_front()


# ─────────────────────────── what it does ───────────────────────────

## Something far away, dripping, or settling, or breathing.
func _exhale() -> void:
	var pick: String = ["drip", "creak", "stone", "breath"][randi_range(0, 3)]
	AudioManager.play_sfx(pick, randf_range(-19.0, -12.0), randf_range(0.85, 1.20))


## The room dims for half a beat, as though something crossed in front of it.
func _pass_in_front() -> void:
	EventManager.request_camera_shake.emit(0.9 + dread * 1.4, 0.28)
	EventManager.request_flash.emit(Color(0.015, 0.018, 0.028, 0.72), 0.30)
	AudioManager.play_sfx("stone", -11.0, randf_range(0.68, 0.88))


## Shifting reality is not free, and the room notices.
func _on_shift_finished(_reality: int) -> void:
	if randf() < 0.22 + dread * 0.4:
		EventManager.request_camera_shake.emit(1.2, 0.2)
