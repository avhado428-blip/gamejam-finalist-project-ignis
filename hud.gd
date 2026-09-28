extends CanvasLayer
## Honest HUD — and deliberately quiet.
##
## Everything here is TRUE, and nothing here is centre-stage: text sits small and
## dim, and the middle of the screen is left to the room.
##
## It says three things, and no more:
##   - whatever the room has just said — "the lock snaps back: dark, pale, dark".
##     Every puzzle in the game was already saying these things into an empty
##     room; without them the sequence lock is not a puzzle, it is a wall. This is
##     the only line here that is not a number or a position, and it is the only
##     one the player has to actually read.
##   - how many hits you have left, as three small lamps in the top-right.
##   - which of the two worlds you are standing in, bottom-right.
##
## The areas still set an objective for themselves and it is still broadcast on
## GameState for anything that wants it; the HUD deliberately does not draw it.
## A line of narration along the bottom of the screen is one more thing standing
## between the player and the room they are supposed to be reading.
##
## The lamps are polled rather than signalled: the hit count is the one number in
## the game that changes without telling anybody.

const COL_TEXT := Color(0.933, 0.910, 0.847, 0.72)
const COL_DIM := Color(0.706, 0.616, 0.847, 0.46)
const COL_OUTLINE := Color(0.043, 0.020, 0.078, 0.85)
const COL_HINT := Color(0.976, 0.855, 0.192, 0.94)
const COL_LAMP := Color(0.949, 0.129, 0.541, 0.95)
const COL_LAMP_OUT := Color(0.949, 0.129, 0.541, 0.16)

## How long the room's last remark stays up before it lets go of you.
const HINT_HOLD := 4.5

var _indicator_tex: Texture2D
var _reality_icon: TextureRect
var _reality_label: Label
var _prompt: Control
var _prompt_label: Label
var _shift_hint: Label
var _checkpoint_label: Label
var _hint: Label
var _lamps: Array[ColorRect] = []
var _last_hits: int = -1
var _hint_tween: Tween


func _ready() -> void:
	layer = 10
	_build()

	RealityManager.reality_changed.connect(_refresh_reality)
	EventManager.prompt_changed.connect(_set_prompt)
	EventManager.checkpoint_activated.connect(_on_checkpoint_activated)
	EventManager.hint_changed.connect(_say_hint)

	_refresh_reality(RealityManager.current_reality)
	_set_prompt("")
	_paint_lamps(0)


func _build() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# whatever the room has just said to you: brief, centred, and gone again.
	# It sits below the floor line (the ground surface is at viewport y 220), so
	# it is painted over the floor rather than over the player or the gap they
	# are trying to cross — with the levels no longer signposted, this line is
	# the only helping text left in the game, and it has to be readable and out
	# of the way at the same time.
	_hint = _mk_label("", 12, COL_HINT)
	_hint.position = Vector2(40, 262)
	_hint.size = Vector2(560, 16)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.modulate = Color(1, 1, 1, 0.0)
	root.add_child(_hint)

	# prompt — bottom-centre, and only while it is actually true
	_prompt = Control.new()
	_prompt.position = Vector2(272, 312)
	_prompt.size = Vector2(96, 16)
	_prompt.visible = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_prompt)

	var pt := TextureRect.new()
	pt.texture = load("res://assets/ui/interaction_prompt.png")
	pt.size = Vector2(96, 16)
	pt.modulate = Color(1, 1, 1, 0.5)
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_child(pt)

	_prompt_label = _mk_label("", 11, COL_TEXT)
	_prompt_label.position = Vector2(16, 0)
	_prompt_label.size = Vector2(80, 16)
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt_label.clip_text = true
	_prompt.add_child(_prompt_label)

	# the key that moves you between the two worlds — the one thing a player
	# must never have to guess at, so it stays at the bottom of the screen
	_shift_hint = _mk_label("PRESS Q TO SWITCH WORLDS", 10, COL_DIM)
	_shift_hint.position = Vector2(170, 336)
	_shift_hint.size = Vector2(300, 14)
	_shift_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shift_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(_shift_hint)

	# checkpoint notice — true, brief, and then gone again
	_checkpoint_label = _mk_label("", 12, COL_TEXT)
	_checkpoint_label.position = Vector2(170, 246)
	_checkpoint_label.size = Vector2(300, 16)
	_checkpoint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_checkpoint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_checkpoint_label.modulate = Color(1, 1, 1, 0.0)
	root.add_child(_checkpoint_label)

	# hits left — three lamps, top-right. Nothing announces a hit, so they are
	# polled every frame; they are the only warning the player gets.
	for i in Player.MAX_HITS:
		var lamp := ColorRect.new()
		lamp.size = Vector2(7, 7)
		lamp.position = Vector2(596.0 + float(i) * 12.0, 9.0)
		lamp.color = COL_LAMP_OUT
		lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(lamp)
		_lamps.append(lamp)

	# reality indicator — bottom-right, the smallest thing on screen.
	# TextureRect has no region in Godot 4, so slice the 2-state sheet with an
	# AtlasTexture (state 0 = white PERCEIVED eye, 1 = cyan TRUE eye).
	_indicator_tex = load("res://assets/ui/reality_indicator.png")
	_reality_icon = TextureRect.new()
	_reality_icon.texture = _atlas(_indicator_tex, Rect2(0, 0, 32, 16))
	_reality_icon.stretch_mode = TextureRect.STRETCH_KEEP
	_reality_icon.position = Vector2(594, 334)
	_reality_icon.size = Vector2(32, 16)
	_reality_icon.modulate = Color(1, 1, 1, 0.7)
	_reality_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_reality_icon)

	_reality_label = _mk_label("PERCEIVED", 11, COL_DIM)
	_reality_label.position = Vector2(486, 334)
	_reality_label.size = Vector2(104, 16)
	_reality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_reality_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(_reality_label)


func _mk_label(text: String, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", COL_OUTLINE)
	l.add_theme_constant_override("outline_size", 3)
	return l


func _atlas(tex: Texture2D, region: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = region
	return a


func _refresh_reality(new_reality: int) -> void:
	var perceived := new_reality == RealityManager.Reality.PERCEIVED
	_reality_icon.texture = _atlas(_indicator_tex, Rect2(0 if perceived else 32, 0, 32, 16))
	_reality_label.text = RealityManager.reality_name(new_reality)
	# the eye is the only thing in the HUD that ever moves on its own
	_reality_label.modulate = Color(1, 1, 1, 1)
	var t := create_tween()
	t.tween_property(_reality_label, "modulate:a", 0.72, 0.8)


func _set_prompt(text: String) -> void:
	_prompt_label.text = text
	_prompt.visible = text != ""
## A line the room says once. Held long enough to read and then gone, because
## most of these arrive while something is trying to kill you.
func _say_hint(text: String) -> void:
	if _hint_tween != null and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint.text = text
	_hint_tween = create_tween()
	if text == "":
		_hint_tween.tween_property(_hint, "modulate:a", 0.0, 0.2)
		return
	_hint.modulate = Color(1, 1, 1, 0.0)
	_hint_tween.tween_property(_hint, "modulate:a", 1.0, 0.25)
	_hint_tween.tween_interval(HINT_HOLD)
	_hint_tween.tween_property(_hint, "modulate:a", 0.0, 0.9)


## Reaching a checkpoint is the one good thing that happens in these rooms, and
## the player should be told that it happened.
func _on_checkpoint_activated(_pos: Vector2) -> void:
	_checkpoint_label.text = "CHECKPOINT"
	_checkpoint_label.modulate = Color(1, 1, 1, 0.0)
	var t := create_tween()
	t.tween_property(_checkpoint_label, "modulate:a", 0.9, 0.35)
	t.tween_interval(1.6)
	t.tween_property(_checkpoint_label, "modulate:a", 0.0, 0.8)


func _process(_delta: float) -> void:
	var pl: Player = get_tree().get_first_node_in_group("player") as Player
	var hits: int = pl.hits if pl != null else 0
	if hits == _last_hits:
		return
	var took: bool = _last_hits >= 0 and hits > _last_hits
	_last_hits = hits
	_paint_lamps(hits)
	if took:
		_pulse_lamps()


func _paint_lamps(hits: int) -> void:
	var left: int = maxi(0, Player.MAX_HITS - hits)
	for i in _lamps.size():
		_lamps[i].color = COL_LAMP if i < left else COL_LAMP_OUT


## A hit otherwise only shows as a flicker on the player, which is easy to miss
## when you are busy falling into something.
func _pulse_lamps() -> void:
	for lamp: ColorRect in _lamps:
		lamp.pivot_offset = lamp.size * 0.5
		lamp.scale = Vector2(1.7, 1.7)
		var t := create_tween()
		t.tween_property(lamp, "scale", Vector2.ONE, 0.35)
