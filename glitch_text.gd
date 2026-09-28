extends Node2D
## What is written on the wall of the tear.
##
## There are no signs in this room. What is left of the writing is a few words
## hanging in the air in the room's own damaged hand, and the hand cannot hold a
## line: letters drop out, whole words slip into rubbish for a moment, and the
## whole thing twitches out of place. None of it helps. That is the point of it —
## "help" is not a hint, it is something that was written here and could not
## finish.
##
## `reality` decides which world the words exist in. The words that exist in only
## one world are the reason there are two: at one point the wall says nothing at
## all until you shift, and then it does.

@export_multiline var text: String = "HELP"
@export var font_size: int = 12
@export var tint: Color = Color(0.878, 0.196, 0.216, 0.96)
## -1 = both worlds, 0 = only while the world is perceived, 1 = only while it is true.
@export var reality: int = -1
## Seconds between the word slipping into rubbish.
@export var slip_gap: Vector2 = Vector2(1.3, 3.6)
## Pixels of twitch. 0 = it holds perfectly still, which nothing here does.
@export var jitter: float = 1.5

const GARBAGE := "#@&$*+=<>/\\|_~^%?!;:"
## Wide and short: every word here is one line, centred on the node. Tall enough for the
## letter size, because a box that clips its own word is not a wall that lost the word
const BOX := Vector2(240.0, 26.0)

var _label: Label
var _home: Vector2
var _rng := RandomNumberGenerator.new()
var _gap: float = 0.0
var _slip: float = 0.0


func _ready() -> void:
	z_index = 2
	_rng.randomize()
	_home = position

	_label = Label.new()
	_label.text = text
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Built straight from the script rather than through the CreepyFont autoload:
	# a damaged hand this early in load order must not depend on an autoload
	# having been created first.
	var hand: Node = preload("res://ui/creepy_font.gd").new()
	_label.add_theme_font_override("font", hand.call("build_eerie") as FontFile)
	hand.free()
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", tint)
	_label.add_theme_color_override("font_outline_color", Color(0.015, 0.015, 0.02, 0.95))
	_label.add_theme_constant_override("outline_size", 2)
	_label.size = BOX
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = -BOX * 0.5
	add_child(_label)

	_gap = _rng.randf_range(slip_gap.x, slip_gap.y)


func _process(delta: float) -> void:
	# Polled rather than bound to RealityManager.reality_changed: whichever world
	# is current is all this needs to know, and polling cannot fall out of sync
	# with a shift that happened while the level was paused.
	if reality >= 0:
		visible = reality == RealityManager.current_reality
		if not visible:
			return

	_gap -= delta
	if _gap <= 0.0:
		_gap = _rng.randf_range(slip_gap.x, slip_gap.y)
		_slip = _rng.randf_range(0.07, 0.20)
	if _slip > 0.0:
		_slip -= delta
		_label.text = _rubbish()
	else:
		_label.text = text

	# and even when it is readable it will not sit still
	position = _home + Vector2(_rng.randf_range(-jitter, jitter), _rng.randf_range(-jitter, jitter) * 0.6)


## The word, mostly lost. Enough survives that you can tell it was a word.
func _rubbish() -> String:
	var out := ""
	for i in text.length():
		var c: String = text[i]
		if c == " " or _rng.randf() < 0.22:
			out += c
		else:
			out += GARBAGE[_rng.randi() % GARBAGE.length()]
	return out
