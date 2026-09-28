extends Control
## The opening — what the game says about itself before it hands over the controls.
##
## It is the title's own sky, darkened and drifting slowly behind five lines of the room's
## handwriting, because the first thing that should move in this game is the world and not a
## menu. No new art is invented here: the whole point is that the picture the player has
## just been looking at is the picture they are about to be put inside.
##
## Lines advance themselves and obey a keypress: a player who has understood can leave, and
## a player who is reading is never rushed. Any one of the five may be skipped; the fifth
## ends the scene and opens the rules.

const SKY := "res://assets/generated/title_sky.png"
const NEXT := "res://ui/instructions.tscn"

## Each beat: the line, how long it holds once it has faded up, and the sound it arrives
## with. The sounds are the room's existing ones — nothing here is special-cased.
const BEATS := [
	{"line": "YOU WERE TOLD YOU WERE ASLEEP.", "hold": 2.3, "sfx": "whisper"},
	{"line": "NOBODY EVER SAID BY WHOM.", "hold": 2.3, "sfx": ""},
	{"line": "THE ROOM AROUND YOU IS REAL. IT HAS NEVER ONCE PRETENDED TO BE.", "hold": 3.0, "sfx": "stone"},
	{"line": "THE ONE THAT LOOKS REAL IS THE PICTURE. THE PICTURE IS THE LIE.", "hold": 3.0, "sfx": "static_burst"},
	{"line": "PRESS Q. WATCH IT COME OFF.", "hold": 2.8, "sfx": "shift"},
]
const FADE_IN := 0.9
const FADE_OUT := 0.6
## How much bigger than the frame the painting is drawn, so that it covers the frame whatever
## the frame's aspect rather than sitting inside it. It is not a travel budget any more: this
## backdrop is parked, centred, for the whole of the scene, because a room that slides sideways
## while it is being talked over reads as a mistake rather than as weather.
const DRIFT := Vector2(76, 43)

var _backdrop: TextureRect
var _line: Label
var _tween: Tween
var _beat: int = 0


func _ready() -> void:
	GameState.set_paused(false)
	# the title's track is already playing and play_music ignores a repeat, so the music
	# runs straight through the title, the opening and the rules without a seam
	AudioManager.play_music("music_calm")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_show()


func _build() -> void:
	_backdrop = TextureRect.new()
	_backdrop.texture = _sky()
	# Fitted to the frame and centred on it. The painting is exactly twice the size of the
	# frame, so leaving the default expand mode drew it at 1:1 and showed only its top-left
	# quarter — a crop of the picture rather than the picture, sitting off to one side of the
	# middle. The rect is the authority: expand mode first, size second, because a Control
	# clamps its size up to the minimum in force when the size is assigned and never hands it
	# back once the minimum drops.
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.size = Vector2(640.0, 360.0) + DRIFT
	_backdrop.position = -DRIFT * 0.5
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_backdrop.modulate = Color(0.62, 0.58, 0.72)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)

	var shade := ColorRect.new()
	shade.color = Color(0.043, 0.020, 0.078, 0.52)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The room's hand, but barely damaged. The ending and the temple captions wear the
	# wrecked version (build_eerie); narration the player has to actually read does not —
	# worn-through glyphs are atmosphere until they are the only thing on screen and the
	# player is trying to read them.
	var hand: FontFile = preload("res://ui/creepy_font.gd").new().build(3, 2)
	_line = Label.new()
	_line.position = Vector2(40, 132)
	_line.size = Vector2(560, 96)
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.add_theme_font_override("font", hand)
	_line.add_theme_font_size_override("font_size", 22)
	_line.add_theme_color_override("font_color", Color(0.949, 0.941, 0.976))
	_line.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.04, 0.96))
	_line.add_theme_constant_override("outline_size", 5)
	_line.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.04, 0.85))
	_line.add_theme_constant_override("shadow_offset_x", 1)
	_line.add_theme_constant_override("shadow_offset_y", 1)
	_line.modulate.a = 0.0
	add_child(_line)

	var hint := UiStyle.at("ANY KEY", 12, 40, 326, 560, UiStyle.TEXT_DIM,
		HORIZONTAL_ALIGNMENT_CENTER)
	add_child(hint)
	var pulse := create_tween().set_loops()
	pulse.tween_property(hint, "modulate:a", 0.30, 1.4)
	pulse.tween_property(hint, "modulate:a", 1.0, 1.4)

	# The sky does not move here any more. It used to drift a few pixels either way on a loop,
	# which on a painting drawn at its own full size read as the whole room sliding sideways
	# out of the frame for no reason. What moves in this scene is the words, and only the words.


## The sky, loaded the same forgiving way the temple gate is: straight out of the file if the
## editor has not imported it yet, and a flat colour if it is not there at all.
func _sky() -> Texture2D:
	var tex: Texture2D = load(SKY) as Texture2D
	if tex != null:
		return tex
	var img: Image = Image.load_from_file(SKY)
	if img != null:
		img.generate_mipmaps()
		return ImageTexture.create_from_image(img)
	var block := GradientTexture2D.new()
	block.width = 8
	block.height = 8
	return block


## Put the current beat on screen and let it run itself out. Killing the previous tween first
## is what makes a skip clean: there is never a half-faded line left behind to fade out of.
func _show() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if _beat >= BEATS.size():
		_go_next()
		return
	var beat: Dictionary = BEATS[_beat]
	_line.text = str(beat["line"])
	var sfx: String = str(beat["sfx"])
	if sfx != "":
		AudioManager.play_sfx(sfx, -7.0)
	_line.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_line, "modulate:a", 1.0, FADE_IN)
	_tween.tween_interval(float(beat["hold"]))
	_tween.tween_property(_line, "modulate:a", 0.0, FADE_OUT)
	_tween.tween_callback(_advance)


func _advance() -> void:
	_beat += 1
	_show()


func _go_next() -> void:
	get_tree().change_scene_to_file(NEXT)


## _input rather than _unhandled_input: a full-frame Control is the shape of scene that
## would happily swallow the click that was meant to skip it, and this scene has nothing
## else that wants the mouse.
func _input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	AudioManager.play_sfx("ui", -9.0)
	_advance()