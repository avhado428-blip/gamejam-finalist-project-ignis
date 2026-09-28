extends Control
## Title screen — flat paintings on a mouse parallax, then the menu: play, the controls,
## the two settings, the credits, and the way out.
## Main scene of the project.
##
## The depth is a trick, and it is deliberately a thin one: there are no 3D nodes here and
## nothing is actually further away than anything else. The painting of the city and the one
## small figure standing in front of it are laid over one another and slid by different
## amounts as the mouse moves, and the eye — which has no way of knowing how far apart they
## really are — reads the difference as distance. Each picture's distance is a number on the
## picture itself, set in the inspector and nowhere else (see title_layer.gd); this script
## only owns the mouse, the smoothing, and the one decision that a painting gets to move
## while a button does not.
##
## The picture is *alive* as well as deep. Every plate breathes on a slow sine of its own,
## the storm's eye opens and closes, the name takes its own light up and down, and ash rises
## through all of it (title_embers.gd) — because a painting of a burning city that does not
## move is a photograph of one, and the whole screen is a promise about what is behind the
## menu button.
##
## The wordmark is its own small layer, because in this screen it is painted into the scene
## rather than laid over it. The panel is gone: the buttons carry their own plates and are
## nailed to the frame, because a menu that slides out from under the cursor is a menu that
## is being unkind to the player.
##
## Also the first place anything stored is applied: the saved volume and window mode are
## read here, before a single sound has played, so the game never opens at the wrong volume
## even for a frame.

## The game no longer begins at area 0 directly: PLAY opens the cutscene, which hands over
## to the instruction page, which is the one place that begins area 0. None of the three
## needs to know anything about the others beyond its own next path.
const CUTSCENE := "res://ui/cutscene.tscn"
const INSTRUCTIONS := "res://ui/instructions.tscn"
const CREDITS := "res://ui/credits.tscn"

## The four-pointed ornament the menu is hung on, the same one the instructions page is
## decorated with.
const ORN := "res://assets/generated/ui_divider.png"

## The breath each painting takes when nobody is touching the mouse, by node name:
## [how far it drifts in frame units, breaths a second, where in the breath it starts].
##
## It is handed to the layers here rather than authored on them because the breath belongs to
## the *picture* and not to the plate it happens to be painted on: the same file of sky on a
## different screen is allowed to breathe at a different rate, and a number that lives beside
## the design that chose it is a number that gets tuned.
##
## The far plate takes a wide slow one and the figure a shorter quicker one, so the two are
## never quite agreeing about where they are — which is the entire trick, and it is the same
## trick the mouse is already playing.
const IDLE := {
	"Scene": [Vector2(6.0, 3.5), 0.07, 0.0],
	"Hero": [Vector2(5.0, 3.0), 0.11, 1.4],
}

## Where the menu column hangs, in frame units: the plate's own size, the gap between the
## plates, and the top of the first one. Everything else about the stack is derived from
## these five numbers, so the whole menu moves by changing them.
const MENU_X := 26.0
const MENU_W := 176.0
const MENU_H := 32.0
const MENU_STEP := 38.0
const MENU_TOP := 146.0

## How fast the paintings catch the mouse. 5 is a soft follow — each layer covers roughly a
## twelfth of the distance to the mouse every frame, which reads as weight. Very large values
## read as a bug instead: the layers glued to the cursor with no movement of their own.
@export_range(1.0, 20.0, 0.5) var smoothing: float = 5.0
## The parallax and the breathing on one switch, for anyone who wants to see the screen
## standing still. The ash keeps going: it is weather, and weather does not stop because
## somebody turned the camera off.
@export var parallax_enabled: bool = true
## The text layer's own small distance. Zero pins the logo dead still, which is the honest
## way to decide whether that drift is worth having.
@export var text_strength: Vector2 = Vector2(5.0, 3.5)

var _start: Button
var _settings: SettingsPanel
var _text_layer: Control
var _logo: TextureRect
var _vortex: TextureRect
var _embers: TitleEmbers
var _layers: Array[TitleParallaxLayer] = []
## Seconds this screen has been up, which is the clock every breath in it is read off.
var _t: float = 0.0
## The frame in viewport units (640x360 in this project) and not in window pixels. Every
## number in this file — the strengths, the offsets, the clamp — is in those units, which is
## why the effect is exactly the same size whatever the window happens to be doing.
var _frame: Vector2 = Vector2.ZERO
var _norm: Vector2 = Vector2.ZERO
var _text_rest: Vector2 = Vector2.ZERO


func _ready() -> void:
	# The project folder is named "flux" and Godot puts the project name in the
	# window's title bar, so every build used to introduce itself by the wrong
	# name. The window title is set here, which is a change to the window rather
	# than to the game, so it is skipped inside the editor, where it would be
	# changing the editor instead.
	if not OS.has_feature("editor"):
		DisplayServer.window_set_title("IGNIS")
		# hotspot sits on the arrow's tip, measured from the artwork itself
		Input.set_custom_mouse_cursor(load("res://assets/ui/cursor.png"),
			Input.CURSOR_ARROW, Vector2(3, 1))
	Settings.load_from_disk()
	Settings.apply()
	GameState.set_paused(false)
	AudioManager.play_music("music_calm")
	AudioManager.set_music_distortion(0.0)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_collect_layers()


func _build() -> void:
	# The room behind everything, for the sake of a painting that is ever missing. The
	# parallax layers arrived with the scene, so they are already in front of this; it only
	# has to be their backdrop and is moved to the very back to be sure of it.
	var bg := ColorRect.new()
	bg.color = Color(0.043, 0.020, 0.078, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The air. It is added second, so the layers are already behind it and it is already in
	# front of them and behind the name — and, being a full-frame Control, it is told here
	# to leave the mouse alone, because the menu and the whole parallax live on motion that
	# a layer with the default filter would eat before either of them ever saw it.
	_embers = TitleEmbers.new()
	_embers.name = "Embers"
	add_child(_embers)

	# The storm's eye, opening and closing. It lives *inside* the painting rather than over
	# it — it is a child of the backdrop layer, so it is carried by every drift that painting
	# makes and can never come adrift from the swirl it was drawn into.
	_vortex = get_node_or_null("Layers/Scene/Vortex") as TextureRect
	if _vortex != null:
		_vortex.pivot_offset = _vortex.size * 0.5

	# The name, over the top of everything, drifting with the near end of the picture.
	#
	# The rect is the art's whole 640x160 canvas rather than its ink: the letters occupy only a
	# 238x160 band in the middle of that file. Sizing the rect to where the ink *looks* like it
	# is (and hoping the margins are trimmed) is exactly how the credits got a wordmark laid
	# straight through them, so this says what the file actually contains — 1.25x, shifted left
	# by the ink's own centre so the *letters* land on the centreline.
	#
	# Expand mode first, size after: a Control clamps its size up to the minimum in force when
	# the size is assigned and never shrinks it back, so the order is load-bearing.
	_text_layer = Control.new()
	_text_layer.name = "TextLayer"
	_text_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text_layer)

	var logo := TextureRect.new()
	logo.texture = UiStyle.load_art("res://assets/generated/ignis_wordmark.png")
	logo.position = Vector2(-96, 0)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_SCALE
	logo.size = Vector2(800, 200)
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# scaled from its own middle, so the glow can make it *breathe* instead of growing off
	# towards the bottom-right corner
	logo.pivot_offset = logo.size * 0.5
	_text_layer.add_child(logo)
	_logo = logo

	# The menu is a bare stack in the lower left, with nothing behind it: the buttons carry
	# their own plates (MenuPlate) and a plate is enough — a panel on top of a painting is a
	# panel covering a painting. It is also the one corner of this picture with nothing in it
	# worth seeing: the figure stands dead centre, the tower rises behind her, the banners
	# hang above this block, and the wet stone under it is empty.
	#
	# The stack is threaded onto one hairline with an ornament at each end, so the five of
	# them read as one hung thing rather than five that happen to be near each other. The
	# line goes in first — everything added after it draws over it — and the plates are
	# deliberately a little see-through, so it shows through the gaps between them.
	_spine(MENU_X + MENU_W * 0.5, MENU_TOP - 12.0, MENU_TOP + MENU_STEP * 4.0 + MENU_H + 12.0)

	_start = _menu("PLAY", 0, _on_start)
	_menu("INSTRUCTIONS", 1, _on_instructions)
	_menu("SETTINGS", 2, _on_settings)
	_menu("CREDITS", 3, _on_credits)
	_menu("QUIT", 4, _on_quit)

	add_child(UiStyle.at("F11   fullscreen", 9, 420, 342, 194, UiStyle.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_RIGHT))

	_start.grab_focus()


## One rung of the menu: a plate, a label, and a handler. Returns it, so the first one can
## be the one the screen starts on.
func _menu(text: String, index: int, handler: Callable) -> Button:
	var b := UiStyle.menu_button(text, MENU_W, MENU_H)
	b.position = Vector2(MENU_X, MENU_TOP + MENU_STEP * float(index))
	b.pressed.connect(handler)
	add_child(b)
	return b


## The hairline the stack is hung on and the ornament at each end of it.
func _spine(x: float, top: float, bottom: float) -> void:
	var line := ColorRect.new()
	line.color = Color(0.949, 0.129, 0.541, 0.26)
	line.position = Vector2(roundf(x) - 0.5, top)
	line.size = Vector2(1.0, bottom - top)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)
	_ornament(Vector2(x, top), 14.0, 0.80)
	_ornament(Vector2(x, bottom), 16.0, 1.0)


func _ornament(at: Vector2, span: float, alpha: float) -> void:
	var o := TextureRect.new()
	o.texture = UiStyle.load_art(ORN)
	o.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	o.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	o.size = Vector2(span, span)
	o.position = at - Vector2(span, span) * 0.5
	o.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	o.modulate = Color(0.949, 0.129, 0.541, alpha)
	o.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(o)


## Find the layers the scene brought and cut each of them to the frame. The rest position is
## derived here once and never added to again — which is the whole reason a night of mouse
## waggling cannot walk the sky off the screen.
func _collect_layers() -> void:
	var holder := get_node_or_null("Layers")
	if holder == null:
		return
	_frame = get_viewport().get_visible_rect().size
	for child in holder.get_children():
		var layer := child as TitleParallaxLayer
		if layer == null:
			continue
		layer.fit(_frame)
		var idle: Array = IDLE.get(String(layer.name), [])
		if idle.size() == 3:
			layer.idle_strength = idle[0]
			layer.idle_speed = idle[1]
			layer.idle_phase = idle[2]
		_layers.append(layer)
	if _text_layer != null:
		_text_rest = _text_layer.position


## The mouse as -1..1 on each axis, measured from the middle of the frame. Desktop only: a
## machine with no pointer at all — a phone, a console pad — never leaves the middle, and
## every layer stays exactly where it was hung.
func _mouse_axis() -> Vector2:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_MOUSE):
		return Vector2.ZERO
	var half: Vector2 = _frame * 0.5
	if half.x <= 0.0 or half.y <= 0.0:
		return Vector2.ZERO
	return ((get_viewport().get_mouse_position() - half) / half).clamp(
		Vector2(-1.0, -1.0), Vector2(1.0, 1.0))


func _process(delta: float) -> void:
	var frame_now: Vector2 = get_viewport().get_visible_rect().size
	if frame_now != _frame and frame_now.x > 0.0 and frame_now.y > 0.0:
		_frame = frame_now
		for layer in _layers:
			layer.fit(_frame)
	if not parallax_enabled:
		return
	_t += delta
	# One smoothed value for the whole screen rather than one per layer. Every layer scales
	# the same number by its own distance, and scaling a smoothed value is the same thing as
	# smoothing a scaled one — so this stays one accumulator instead of four.
	var weight: float = clampf(delta * smoothing, 0.0, 1.0)
	_norm = _norm.lerp(_mouse_axis(), weight)
	for layer in _layers:
		layer.travel(_norm, _t)
	if _text_layer != null:
		_text_layer.position = _text_rest + _norm * text_strength
	_animate()


## The life that is not the parallax.
##
## All three of these are deliberately small and one of them is deliberately slow. A title
## screen is a page with a menu on it, and a page that twitches is a page nobody finishes
## reading: the eye is drawn to movement, and every drop of it spent here is a drop not
## spent on the buttons. So the storm's eye takes eleven seconds to open and close, the name
## never leaves a tenth of its own light, and the ash is the only thing allowed to be quick.
func _animate() -> void:
	if _vortex != null:
		var beat: float = 0.5 + 0.5 * sin(_t * 0.85)
		_vortex.modulate.a = 0.14 + 0.30 * beat
		_vortex.scale = Vector2.ONE * (0.92 + 0.16 * beat)
	if _logo != null:
		# two beats, one slow and one eight times faster, because one sine on a glow is a
		# pulse and two that never line up are a *fire*
		var glow: float = 0.88 + 0.10 * sin(_t * 1.35) + 0.035 * sin(_t * 8.7)
		_logo.modulate = Color(1.0, 1.0, 1.0, clampf(glow, 0.0, 1.0))
		_logo.scale = Vector2.ONE * (1.0 + 0.008 * sin(_t * 1.05))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		Settings.toggle_fullscreen()


func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _on_start() -> void:
	AudioManager.play_sfx("ui", -4.0)
	_go(CUTSCENE)


func _on_instructions() -> void:
	AudioManager.play_sfx("ui", -4.0)
	_go(INSTRUCTIONS)


func _on_settings() -> void:
	AudioManager.play_sfx("ui", -4.0)
	if _settings == null:
		_settings = SettingsPanel.new()
		add_child(_settings)
		_settings.closed.connect(_on_settings_closed)
	_settings.open()


func _on_settings_closed() -> void:
	if _start != null:
		_start.grab_focus()


func _on_credits() -> void:
	AudioManager.play_sfx("ui", -4.0)
	_go(CREDITS)


func _on_quit() -> void:
	AudioManager.play_sfx("ui", -4.0)
	get_tree().quit()