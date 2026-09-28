extends CanvasLayer
## Pause menu — resume, restart the area, volume, fullscreen, quit to title.
##
## Runs while the tree is paused, so it is PROCESS_MODE_ALWAYS and everything it
## builds inherits that. The volume slider writes straight through to Settings,
## which pushes it at the audio server and remembers it for next time.

var _resume: Button
var _fullscreen: Button
var _volume: HSlider
var _volume_label: Label


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.load_from_disk()
	_build()
	visible = false
	GameState.paused_changed.connect(_on_paused_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameState.toggle_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		Settings.toggle_fullscreen()
		_refresh()


func _on_paused_changed(paused: bool) -> void:
	visible = paused
	if paused:
		_refresh()
		_resume.grab_focus()


func _build() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.035, 0.80)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := UiStyle.panel(320, 138)
	panel.position = Vector2(160, 86)
	root.add_child(panel)

	var title := UiStyle.at("PAUSED", 12, 160, 98, 320, Color(0.80, 0.83, 0.90),
		HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(title)

	_resume = UiStyle.button("RESUME", 132.0, 20.0)
	_resume.position = Vector2(176, 122)
	_resume.pressed.connect(_on_resume)
	root.add_child(_resume)

	_fullscreen = UiStyle.button("FULLSCREEN", 132.0, 20.0)
	_fullscreen.position = Vector2(332, 122)
	_fullscreen.pressed.connect(_on_fullscreen)
	root.add_child(_fullscreen)

	var restart := UiStyle.button("RESTART AREA", 132.0, 20.0)
	restart.position = Vector2(176, 146)
	restart.pressed.connect(_on_restart)
	root.add_child(restart)

	_volume_label = UiStyle.at("", 10, 332, 150, 132, UiStyle.TEXT_DIM)
	root.add_child(_volume_label)

	_volume = HSlider.new()
	_volume.position = Vector2(332, 164)
	_volume.size = Vector2(132, 14)
	_volume.min_value = 0.0
	_volume.max_value = 1.0
	_volume.step = 0.05
	_volume.value = Settings.volume
	_volume.mouse_filter = Control.MOUSE_FILTER_STOP
	_volume.add_theme_stylebox_override("slider", UiStyle.box(Color(0.05, 0.06, 0.085, 1.0), UiStyle.LINE))
	_volume.add_theme_stylebox_override("grabber_area",
		UiStyle.box(Color(0.949, 0.129, 0.541, 0.55), Color(0, 0, 0, 0)))
	_volume.add_theme_stylebox_override("grabber_area_highlight",
		UiStyle.box(Color(1.0, 0.36, 0.60, 0.80), Color(0, 0, 0, 0)))
	_volume.add_theme_icon_override("grabber", _chip(Color(0.98, 0.75, 0.84)))
	_volume.add_theme_icon_override("grabber_highlight", _chip(Color(1.0, 1.0, 1.0)))
	_volume.value_changed.connect(_on_volume)
	root.add_child(_volume)
	_refresh_volume_label(Settings.volume)

	var quit := UiStyle.button("QUIT TO TITLE", 132.0, 20.0)
	quit.position = Vector2(254, 178)
	quit.pressed.connect(_on_quit)
	root.add_child(quit)

	_resume.grab_focus()


## The slider's grabber has to be a texture, so make a tiny flat one rather than
## shipping an icon for it.
func _chip(col: Color) -> ImageTexture:
	var im := Image.create_empty(9, 9, false, Image.FORMAT_RGBA8)
	im.fill(col)
	return ImageTexture.create_from_image(im)


func _on_volume(value: float) -> void:
	Settings.set_volume(value)
	_refresh_volume_label(value)


func _refresh_volume_label(value: float) -> void:
	var pct: int = int(round(value * 100.0))
	_volume_label.text = "VOLUME  %d%%" % pct


## Called whenever the menu opens, so the controls show the state the game is
## actually in rather than the state they were built in.
func _refresh() -> void:
	_volume.set_value_no_signal(0.0 if Settings.muted else Settings.volume)
	_refresh_volume_label(Settings.volume)
	_fullscreen.text = "FULLSCREEN  ON" if Settings.fullscreen else "FULLSCREEN  OFF"


func _on_resume() -> void:
	AudioManager.play_sfx("ui", -4.0)
	GameState.set_paused(false)


func _on_fullscreen() -> void:
	AudioManager.play_sfx("ui", -4.0)
	Settings.toggle_fullscreen()


func _on_restart() -> void:
	AudioManager.play_sfx("ui", -4.0)
	GameState.set_paused(false)
	CheckpointManager.reset()
	get_tree().reload_current_scene()


func _on_quit() -> void:
	AudioManager.play_sfx("ui", -4.0)
	GameState.set_paused(false)
	get_tree().change_scene_to_file("res://ui/title_screen.tscn")
