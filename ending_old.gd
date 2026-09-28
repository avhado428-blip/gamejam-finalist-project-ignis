extends Node2D
## The ending. Nothing is explained — the echo, the void, one line, then black.

const LINE := "YOU WERE NEVER THE ONE WHO WAS TRAPPED."

var _black: ColorRect
var _void: TextureRect
var _echo: TextureRect
var _line: Label


func _ready() -> void:
	AudioManager.play_music("music_broken")
	AudioManager.set_music_distortion(0.45)
	GameState.current_level = "ending"
	GameState.set_objective("")
	EventManager.hint_changed.emit("")
	_build()
	_run()


func _build() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	layer.add_child(_full(load("res://assets/story/awakening.png"), Color(1, 1, 1, 1)))

	_void = _full(load("res://assets/story/ending_void.png"), Color(1, 1, 1, 0))
	layer.add_child(_void)

	_echo = TextureRect.new()
	_echo.texture = load("res://assets/story/protagonist_echo.png")
	_echo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_echo.stretch_mode = TextureRect.STRETCH_KEEP
	_echo.size = Vector2(64, 96)
	_echo.position = Vector2(288, 128)
	_echo.modulate = Color(1, 1, 1, 0)
	_echo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_echo)

	_line = Label.new()
	_line.text = LINE
	_line.position = Vector2(60, 258)
	_line.size = Vector2(520, 20)
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.add_theme_font_size_override("font_size", 14)
	_line.add_theme_color_override("font_color", Color(0.88, 0.90, 0.95))
	_line.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.04, 0.9))
	_line.add_theme_constant_override("outline_size", 4)
	_line.modulate = Color(1, 1, 1, 0)
	layer.add_child(_line)

	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 1)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_black)
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _full(tex: Texture2D, col: Color) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = tex
	rect.modulate = col
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect


func _run() -> void:
	await _prop(_black, "color:a", 0.0, 2.2)
	await _wait(0.6)
	await _prop(_echo, "modulate:a", 0.72, 2.0)
	await _wait(1.4)
	await _prop(_line, "modulate:a", 1.0, 2.0)
	await _wait(4.2)
	var v := create_tween()
	v.tween_property(_echo, "modulate:a", 0.0, 1.6)
	v.parallel().tween_property(_void, "modulate:a", 1.0, 2.4)
	v.parallel().tween_property(_line, "modulate:a", 0.35, 2.4)
	await v.finished
	await _wait(2.0)
	var b := create_tween()
	b.tween_property(_line, "modulate:a", 0.0, 1.4)
	b.parallel().tween_property(_black, "color:a", 1.0, 2.2)
	await b.finished
	await _wait(1.4)
	GameState.start_credits()


func _prop(obj: Object, path: String, to: float, time: float) -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(obj, path, to, time)
	await t.finished


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
