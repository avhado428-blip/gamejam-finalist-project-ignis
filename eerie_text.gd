class_name EerieText
extends Label
## One line of the room's handwriting, arriving a letter at a time.
##
## The font it wears is the damaged one — CreepyFont.build_eerie() — so it is
## rubbed through, thorned, and never quite level. On top of that the letters
## that have only just arrived are still the wrong ones for a frame or two: the
## line is not so much being written as remembered badly. Every second or two the
## whole line slips at once, every letter drags a blood shadow behind it, and
## `tremble` keeps the whole thing shaking whether or not it is being typed.
##
## Used by the ending, which is the only scene in the game that talks.

## Emitted when the last letter has arrived. play() returns on this.
signal typed

## What a letter falls back on when the line slips. Every one of these exists in
## the bitmap font — anything else would simply draw nothing at all.
const GARBAGE := "#@&$*+=<>/\\|_~^%?!;:"

## How fast it writes. The ending runs fast; it has a lot to say.
@export var chars_per_second: float = 44.0
## How often a letter that has only just arrived is still the wrong one. High
## enough that the line is never quite settled on what it is saying.
@export var slip_chance: float = 0.30
## How many letters at the end of the line are still settling.
@export var slip_tail: int = 2
## Pixels of shake. 0 = the line holds perfectly still, which is the one thing
## nothing in this scene is allowed to do.
@export var tremble: float = 0.5
## How long between the whole line slipping at once. Short: whatever is holding
## the pen keeps losing its place.
@export var slip_gap: Vector2 = Vector2(1.8, 5.0)
## Puts a solid black plate behind the line, the way a caption sits on one.
##
## Turn it on for any line that has to be read over something it is not allowed to
## cover up. This is the whole reason it exists: the words in this game are written
## in the same red the walls are, and a red word on a red wall is not a hard-to-read
## word, it is a word that is not there.
@export var caption: bool = false
## How much air the plate leaves around the letters.
@export var caption_pad: Vector2 = Vector2(12.0, 5.0)
## How black it is. High enough to hold the letters apart from the wall and no
## higher: a plate that is *fully* black reads as a UI panel, which is the one thing
## this scene is not allowed to look like.
@export var caption_ink: Color = Color(0.015, 0.008, 0.035, 0.80)

var _plate: ColorRect = null
var _plate_for: String = ""
var _full: String = ""
var _revealed: int = 0
var _typing: bool = false
var _arrived: bool = false
var _acc: float = 0.0
var _gap: float = 0.0
var _whole: bool = false
var _base: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	# The hand is built straight from the script instead of through the CreepyFont
	# autoload: a script with a class_name is compiled before the autoloads exist,
	# so an autoload name in here would not resolve at all.
	var hand: Node = preload("res://ui/creepy_font.gd").new()
	var font: FontFile = hand.call("build_eerie") as FontFile
	hand.free()
	add_theme_font_override("font", font)
	# Nothing in this room is written in white any more: the hand is dipped in the
	# same blood the room is made of, and only the outline is black — hard enough
	# to hold a shaking letter together against a wall this red.
	add_theme_color_override("font_color", Color(0.878, 0.196, 0.216, 0.96))
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	add_theme_constant_override("outline_size", 5)
	# Whatever is writing this has been writing it in something that runs: every
	# letter carries a blood shadow down and to the right, under the outline.
	add_theme_color_override("font_shadow_color", Color(0.549, 0.016, 0.035, 0.85))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)
	add_theme_constant_override("shadow_outline_size", 0)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_TOP
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	text = ""
	set_process(false)


## Writes `line` out, and returns once every letter of it has arrived. The line
## then stays on screen, still slipping, until wipe() is called.
func play(line: String) -> void:
	_full = line
	_revealed = 0
	_acc = 0.0
	_gap = _rng.randf_range(slip_gap.x, slip_gap.y)
	_whole = false
	_base = position
	modulate.a = 1.0
	text = ""
	_typing = true
	set_process(true)
	if _full.is_empty():
		_typing = false
		typed.emit()
		return
	await typed


## Fades the line out and empties it, leaving the label ready for the next one.
func wipe(duration: float = 0.22) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, duration)
	await t.finished
	text = ""
	_full = ""
	_typing = false
	_whole = false
	position = _base
	set_process(false)


func _process(delta: float) -> void:
	if _typing:
		_acc += delta * chars_per_second
		while _acc >= 1.0 and _revealed < _full.length():
			_acc -= 1.0
			_revealed += 1
		if _revealed >= _full.length():
			_revealed = _full.length()
			_typing = false
			_arrived = true
	_gap -= delta
	if _gap <= 0.0:
		_gap = _rng.randf_range(slip_gap.x, slip_gap.y)
		_whole = true
	else:
		_whole = false
	_draw_line()
	if tremble > 0.0:
		position = _base + Vector2(_rng.randf_range(-tremble, tremble), _rng.randf_range(-tremble, tremble))
	# once, on the frame the last letter lands — not every frame after it
	if _arrived:
		_arrived = false
		typed.emit()


func _draw_line() -> void:
	if _full.is_empty():
		text = ""
		return
	_fit_plate()
	if _whole:
		var slipped := ""
		for i in _full.length():
			slipped += " " if _full[i] == " " else GARBAGE[_rng.randi() % GARBAGE.length()]
		text = slipped
		return
	if not _typing:
		text = _full
		return
	var out := ""
	var tail: int = _revealed - slip_tail
	for i in _revealed:
		var c: String = _full[i]
		if i >= tail and c != " " and _rng.randf() < slip_chance:
			out += GARBAGE[_rng.randi() % GARBAGE.length()]
		else:
			out += c
	text = out


## Sizes the plate to the *whole* line rather than to the part of it that has arrived,
## so the box does not crawl outward a letter at a time while somebody is reading it.
## Recomputed only when the line changes — the label slips garbage into its own text
## every other second, and a plate that followed *that* would breathe.
func _fit_plate() -> void:
	if not caption or _full == _plate_for:
		return
	_plate_for = _full
	if _plate == null:
		_plate = ColorRect.new()
		_plate.color = caption_ink
		_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# One layer *under* the label's own drawing rather than over it. A child item
		# sorts by its own effective z, and a relative -1 puts this one behind the hand:
		# without it the plate is a black bar with no words on it, which is worse than
		# no plate at all.
		_plate.z_as_relative = true
		_plate.z_index = -1
		add_child(_plate)
	var f: Font = get_theme_font("font")
	var fs: int = get_theme_font_size("font_size")
	var w: float = 0.0
	if f != null:
		w = f.get_string_size(_full, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	# never wider than the label it belongs to: a plate that ran off the edge of the
	# screen would be a plate telling the player where the line *used* to be
	w = minf(size.x, w + caption_pad.x * 2.0)
	var h: float = float(fs) + caption_pad.y * 2.0
	_plate.size = Vector2(w, h)
	_plate.position = Vector2((size.x - w) * 0.5, (size.y - h) * 0.5)
