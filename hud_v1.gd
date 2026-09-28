extends CanvasLayer
## Honest HUD — and deliberately quiet.
##
## Everything here is TRUE, and nothing here is centre-stage: text sits small
## and dim in the corners, the objective fades once you have read it, and the
## middle of the screen is left to the room.

const COL_TEXT := Color(0.84, 0.86, 0.92, 0.52)
const COL_DIM := Color(0.74, 0.76, 0.84, 0.40)
const COL_OUTLINE := Color(0.03, 0.04, 0.06, 0.85)

var _indicator_tex: Texture2D
var _reality_icon: TextureRect
var _reality_label: Label
var _prompt: Control
var _prompt_label: Label
var _shift_hint: Label
var _checkpoint_label: Label


func _ready() -> void:
	layer = 10
	_build()

	RealityManager.reality_changed.connect(_refresh_reality)
	EventManager.prompt_changed.connect(_set_prompt)
	EventManager.checkpoint_activated.connect(_on_checkpoint_activated)

	_refresh_reality(RealityManager.current_reality)
	_set_prompt("")


func _build() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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
	_checkpoint_label.position = Vector2(170, 290)
	_checkpoint_label.size = Vector2(300, 16)
	_checkpoint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_checkpoint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_checkpoint_label.modulate = Color(1, 1, 1, 0.0)
	root.add_child(_checkpoint_label)

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


## Reaching a checkpoint is the one good thing that happens in these rooms, and
## the player should be told that it happened.
func _on_checkpoint_activated(_pos: Vector2) -> void:
	_checkpoint_label.text = "CHECKPOINT"
	_checkpoint_label.modulate = Color(1, 1, 1, 0.0)
	var t := create_tween()
	t.tween_property(_checkpoint_label, "modulate:a", 0.9, 0.35)
	t.tween_interval(1.6)
	t.tween_property(_checkpoint_label, "modulate:a", 0.0, 0.8)
