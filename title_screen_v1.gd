extends Control
## Title screen — Start / Instructions / Quit. Main scene of the project.

## Areas are sequenced by GameState.AREA_SEQUENCE; START simply begins at 0.
const FIRST_AREA := 0

var _instructions: Control


func _ready() -> void:
	GameState.set_paused(false)
	AudioManager.play_music("music_calm")
	AudioManager.set_music_distortion(0.0)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.030, 0.036, 0.050, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var logo := TextureRect.new()
	logo.texture = load("res://assets/ui/false_real_logo.png")
	logo.position = Vector2(224, 66)
	logo.size = Vector2(192, 32)
	logo.stretch_mode = TextureRect.STRETCH_SCALE
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

	var panel := TextureRect.new()
	panel.texture = load("res://assets/ui/menu_panel.png")
	panel.position = Vector2(240, 140)
	panel.size = Vector2(160, 96)
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var tag := _mk_label("the room is not the same twice", 12)
	tag.position = Vector2(180, 110)
	tag.size = Vector2(280, 16)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(tag)

	var start := _mk_button("START")
	start.position = Vector2(264, 150)
	start.pressed.connect(_on_start)
	add_child(start)

	var help := _mk_button("INSTRUCTIONS")
	help.position = Vector2(264, 178)
	help.pressed.connect(_on_instructions)
	add_child(help)

	var quit := _mk_button("QUIT")
	quit.position = Vector2(264, 206)
	quit.pressed.connect(_on_quit)
	add_child(quit)

	var hint := _mk_label("A/D move    SPACE jump    Q reality shift    E interact    R restart    ESC pause", 11)
	hint.position = Vector2(20, 336)
	hint.size = Vector2(600, 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)

	_build_instructions()
	start.grab_focus()


func _build_instructions() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.025, 0.035, 0.93)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_instructions = overlay

	var box := Panel.new()
	box.position = Vector2(96, 46)
	box.size = Vector2(448, 262)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.095, 0.96)
	sb.border_color = Color(0.79, 0.79, 0.85, 0.55)
	sb.set_border_width_all(1)
	box.add_theme_stylebox_override("panel", sb)
	overlay.add_child(box)

	overlay.add_child(_line("HOW TO BE HERE", 14, 110, 60, 420, HORIZONTAL_ALIGNMENT_CENTER, Color(0.88, 0.90, 0.96)))
	overlay.add_child(_line("PERCEIVED — pale, hazed, still.        TRUE — dim, real, grounded.", 11, 110, 88, 420, HORIZONTAL_ALIGNMENT_CENTER, Color(0.76, 0.79, 0.86)))
	overlay.add_child(_line("A / D   move          SPACE   jump          Q   shift reality", 12, 110, 118, 420, HORIZONTAL_ALIGNMENT_CENTER, Color(0.84, 0.86, 0.92)))
	overlay.add_child(_line("E   interact          R   restart          ESC   pause", 12, 110, 142, 420, HORIZONTAL_ALIGNMENT_CENTER, Color(0.84, 0.86, 0.92)))
	overlay.add_child(_line("Q really does change the world. The HUD always tells you the truth.", 11, 110, 182, 420, HORIZONTAL_ALIGNMENT_CENTER, Color(0.76, 0.79, 0.86)))
	overlay.add_child(_line("Some things exist in only one of the two worlds — and the environment", 11, 110, 206, 420, HORIZONTAL_ALIGNMENT_CENTER, Color(0.76, 0.79, 0.86)))
	overlay.add_child(_line("is the only thing here that lies. Read solidity, enemies, haze, sound.", 11, 110, 226, 420, HORIZONTAL_ALIGNMENT_CENTER, Color(0.76, 0.79, 0.86)))
	overlay.add_child(_line("Stomp a crawler from above. Twice, for the big ones.", 11, 110, 252, 420, HORIZONTAL_ALIGNMENT_CENTER, Color(0.68, 0.71, 0.79)))

	var back := _mk_button("BACK")
	back.position = Vector2(264, 274)
	back.pressed.connect(_close_instructions)
	overlay.add_child(back)

	_instructions.visible = false


func _line(text: String, font_size: int, x: float, y: float, w: float, align: HorizontalAlignment, col: Color) -> Label:
	var l := _mk_label(text, font_size)
	l.position = Vector2(x, y)
	l.size = Vector2(w, font_size + 6)
	l.horizontal_alignment = align
	l.add_theme_color_override("font_color", col)
	return l


func _mk_label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(0.70, 0.73, 0.82))
	return l


func _mk_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.size = Vector2(112, 22)
	b.add_theme_font_size_override("font_size", 11)
	return b


func _on_instructions() -> void:
	AudioManager.play_sfx("ui", -4.0)
	_instructions.visible = true


func _close_instructions() -> void:
	AudioManager.play_sfx("ui", -4.0)
	_instructions.visible = false


func _on_start() -> void:
	AudioManager.play_sfx("ui", -4.0)
	GameState.start_area(FIRST_AREA)


func _on_quit() -> void:
	AudioManager.play_sfx("ui", -4.0)
	get_tree().quit()
