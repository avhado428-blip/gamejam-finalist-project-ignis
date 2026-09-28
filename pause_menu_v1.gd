extends CanvasLayer
## Pause menu — resume / restart / quit. Runs while the tree is paused.

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	GameState.paused_changed.connect(_on_paused_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameState.toggle_pause()
		get_viewport().set_input_as_handled()


func _on_paused_changed(paused: bool) -> void:
	visible = paused


func _build() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.035, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := TextureRect.new()
	panel.texture = load("res://assets/ui/menu_panel.png")
	panel.position = Vector2(240, 88)
	panel.size = Vector2(160, 96)
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var title := _mk_label("PAUSED", 12)
	title.position = Vector2(240, 96)
	title.size = Vector2(160, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var resume := _mk_button("RESUME")
	resume.position = Vector2(264, 112)
	resume.pressed.connect(_on_resume)
	root.add_child(resume)

	var restart := _mk_button("RESTART")
	restart.position = Vector2(264, 136)
	restart.pressed.connect(_on_restart)
	root.add_child(restart)

	var quit := _mk_button("QUIT")
	quit.position = Vector2(264, 160)
	quit.pressed.connect(_on_quit)
	root.add_child(quit)

	resume.grab_focus()


func _mk_label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(0.78, 0.80, 0.88))
	return l


func _mk_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.size = Vector2(112, 20)
	b.add_theme_font_size_override("font_size", 11)
	return b


func _on_resume() -> void:
	AudioManager.play_sfx("ui", -4.0)
	GameState.set_paused(false)


func _on_restart() -> void:
	AudioManager.play_sfx("ui", -4.0)
	GameState.set_paused(false)
	CheckpointManager.reset()
	get_tree().reload_current_scene()


func _on_quit() -> void:
	AudioManager.play_sfx("ui", -4.0)
	GameState.set_paused(false)
	get_tree().change_scene_to_file("res://ui/title_screen.tscn")
