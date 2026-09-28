class_name SettingsPanel
extends Control
## The title screen's SETTINGS: the two things a player should never have to set twice,
## asked for from the main menu rather than only from inside a paused run.
##
## The pause menu already carries a volume slider and a fullscreen switch, and this is
## deliberately that same pair with the same behaviour — it writes through to Settings,
## which pushes the value at the audio server and remembers it. What is different is
## where it lives: a player who cannot hear the game should be able to fix that before
## starting it, not after.
##
## Built in code and shown over the title, so the title screen keeps its own layout and
## this one can be opened and closed without the menu behind it moving a pixel.

signal closed

var _volume: HSlider
var _volume_label: Label
var _mute: Button
var _fullscreen: Button
var _back: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	visible = false


func open() -> void:
	Settings.load_from_disk()
	_refresh()
	visible = true
	_back.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		AudioManager.play_sfx("ui", -4.0)
		close()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.012, 0.008, 0.024, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := UiStyle.panel(360.0, 192.0)
	panel.position = Vector2(140.0, 84.0)
	add_child(panel)

	var title := UiStyle.at("SETTINGS", 13, 140.0, 96.0, 360.0,
		Color(0.87, 0.83, 0.90), HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", UiStyle.display(700, 5))
	add_child(title)

	var hl := ColorRect.new()
	hl.color = Color(0.949, 0.129, 0.541, 0.35)
	hl.position = Vector2(140.0, 118.0)
	hl.size = Vector2(360.0, 1.0)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hl)

	var vol_head := UiStyle.at("VOLUME", 9, 162.0, 130.0, 140.0, UiStyle.TEXT_DIM)
	vol_head.add_theme_font_override("font", UiStyle.display(700, 4))
	add_child(vol_head)

	_volume_label = UiStyle.at("", 9, 380.0, 130.0, 120.0, UiStyle.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_RIGHT)
	add_child(_volume_label)

	_volume = HSlider.new()
	_volume.position = Vector2(162.0, 148.0)
	_volume.size = Vector2(338.0, 14.0)
	_volume.min_value = 0.0
	_volume.max_value = 1.0
	_volume.step = 0.05
	_volume.value = Settings.volume
	_volume.add_theme_stylebox_override("slider",
		UiStyle.box(Color(0.05, 0.06, 0.085, 1.0), UiStyle.LINE))
	_volume.add_theme_stylebox_override("grabber_area",
		UiStyle.box(Color(0.949, 0.129, 0.541, 0.55), Color(0, 0, 0, 0)))
	_volume.add_theme_stylebox_override("grabber_area_highlight",
		UiStyle.box(Color(1.0, 0.36, 0.60, 0.80), Color(0, 0, 0, 0)))
	_volume.add_theme_icon_override("grabber", _chip(Color(0.98, 0.75, 0.84)))
	_volume.add_theme_icon_override("grabber_highlight", _chip(Color(1.0, 1.0, 1.0)))
	_volume.value_changed.connect(_on_volume)
	add_child(_volume)

	_mute = UiStyle.button("MUTE", 150.0, 22.0)
	_mute.position = Vector2(162.0, 178.0)
	_mute.pressed.connect(_on_mute)
	add_child(_mute)

	_fullscreen = UiStyle.button("FULLSCREEN", 188.0, 22.0)
	_fullscreen.position = Vector2(312.0, 178.0)
	_fullscreen.pressed.connect(_on_fullscreen)
	add_child(_fullscreen)

	_back = UiStyle.button("BACK", 150.0, 24.0)
	_back.position = Vector2(245.0, 226.0)
	_back.pressed.connect(_on_back)
	add_child(_back)

	add_child(UiStyle.at("ESC   back to the menu", 9, 162.0, 254.0, 220.0,
		UiStyle.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT))


	## The slider's grabber has to be a texture, so make a tiny flat one rather than
## shipping an icon for it.
func _chip(col: Color) -> ImageTexture:
	var im := Image.create_empty(9, 9, false, Image.FORMAT_RGBA8)
	im.fill(col)
	return ImageTexture.create_from_image(im)


func _on_volume(value: float) -> void:
	Settings.set_volume(value)
	_refresh()


func _on_mute() -> void:
	AudioManager.play_sfx("ui", -4.0)
	Settings.toggle_mute()
	_refresh()


func _on_fullscreen() -> void:
	AudioManager.play_sfx("ui", -4.0)
	Settings.toggle_fullscreen()
	_refresh()


func _on_back() -> void:
	AudioManager.play_sfx("ui", -4.0)
	close()


## Redrawn every time it opens and after every change, so the controls show the state the
## game is actually in rather than the state they were built in.
func _refresh() -> void:
	_volume.set_value_no_signal(0.0 if Settings.muted else Settings.volume)
	_volume_label.text = "%d%%" % int(round(Settings.volume * 100.0))
	_mute.text = "MUTED" if Settings.muted else "MUTE"
	_fullscreen.text = "FULLSCREEN  ON" if Settings.fullscreen else "FULLSCREEN  OFF"