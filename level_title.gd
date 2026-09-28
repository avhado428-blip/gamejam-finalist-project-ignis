class_name LevelTitle
extends CanvasLayer
## The name of the place, once, low enough to sit under the eye — and then gone.
##
## Nothing here is a HUD element. It arrives on its own, drifts a few pixels while
## it is up, and is gone in under three seconds, so the name stays a thing you
## half-remember rather than a thing the game told you. The name is all of it:
## there is no description under the rule.

const SCREEN_W := 640.0
const BLOCK_Y := 30.0
const DRIFT := 6.0

const COL_TITLE := Color(0.949, 0.925, 0.859, 1.0)
const COL_DIM := Color(0.706, 0.616, 0.847, 1.0)
const COL_RULE := Color(0.949, 0.129, 0.541, 0.55)
const COL_OUTLINE := Color(0.043, 0.020, 0.078, 0.95)

var numeral: String = ""
var title: String = ""

var _block: Control
var _rule: ColorRect
var _numeral: Label
var _name: Label


func _ready() -> void:
	layer = 6
	_build()
	_reveal()


func _build() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_block = Control.new()
	_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_block.position = Vector2(0.0, BLOCK_Y)
	_block.size = Vector2(SCREEN_W, 360.0)
	root.add_child(_block)

	# the numeral and the name, and nothing else: no description under the rule
	_numeral = _mk_label(numeral, 10, COL_DIM, 0.0)
	_name = _mk_label(title.to_upper(), 22, COL_TITLE, 13.0)

	_rule = ColorRect.new()
	_rule.color = COL_RULE
	_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rule.size = Vector2(0.0, 1.0)
	_rule.position = Vector2(SCREEN_W * 0.5, 39.0)
	_block.add_child(_rule)


func _mk_label(text: String, size: int, col: Color, y: float) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", COL_OUTLINE)
	l.add_theme_constant_override("outline_size", 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(SCREEN_W, float(size) + 8.0)
	l.position = Vector2(0.0, y)
	_block.add_child(l)
	return l


func _reveal() -> void:
	for c: CanvasItem in [_numeral, _name, _rule]:
		c.modulate.a = 0.0
	AudioManager.play_sfx("whisper", -9.0, 0.92)

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(_numeral, "modulate:a", 1.0, 0.7)
	t.parallel().tween_property(_name, "modulate:a", 1.0, 1.2)
	t.parallel().tween_property(_rule, "size:x", 168.0, 1.1)
	t.parallel().tween_property(_rule, "position:x", SCREEN_W * 0.5 - 84.0, 1.1)
	t.parallel().tween_property(_block, "position:y", BLOCK_Y - DRIFT, 3.6)
	t.chain().tween_interval(2.6)
	t.chain().tween_property(_block, "modulate:a", 0.0, 1.7)
	t.chain().tween_callback(queue_free)
