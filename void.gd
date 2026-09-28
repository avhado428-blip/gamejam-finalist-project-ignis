extends Control
## What is left when the room behind the picture is finished with.
##
## The parkour room's own exit fades the hall out and hands over to this, and this is the
## beat between the last thing the player did and the credits: nothing to walk on, nothing
## to fight, and the game's own voice saying the short version of what it has been saying
## the whole way through. Then the credits roll.
##
## It is deliberately tiny. The picture is gone — a black field, one faint ornament, one
## line at a time — so that the reel arriving afterwards reads as the only thing left to
## look at. Any key skips the whole beat: a player who has heard enough should never have
## to sit through it to reach the names.

const CREDITS := "res://ui/credits.tscn"
const ORN := "res://assets/generated/ui_divider.png"

## What is said into the dark, one line at a time, and how long each is left standing.
const LINES: PackedStringArray = [
	"NONE OF THIS WAS REAL.",
	"YOU WERE A DETAIL IN A BIGGER PICTURE.",
	"AND SO IS THE ONE READING THIS.",
]
const HOLD := 1.9
const FADE_IN := 0.85
const FADE_OUT := 0.6

## The line the whole game has been talking in, and the colour it has been bleeding in.
const COL_WORD := Color(0.898, 0.239, 0.259)
## The ornament is a watermark under the words and never more than that: it is the only
## thing in the frame, so it has to be faint enough that the line over it is still the
## thing being read.
const COL_MARK := Color(0.949, 0.129, 0.541, 0.16)

var _label: Label
var _orn: TextureRect
var _fade: ColorRect
var _glitch: Glitch
var _skippable: bool = false
var _done: bool = false


func _ready() -> void:
	GameState.current_level = "void"
	GameState.set_objective("")
	EventManager.hint_changed.emit("")
	GameState.set_paused(false)
	# the room the player has just left is still the music; this only takes its edge off
	AudioManager.set_music_distortion(0.08)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	await get_tree().create_timer(0.5).timeout
	_skippable = true
	_run()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.012, 0.006, 0.016, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The tear, at a whisper and almost never: the room is not doing anything any more, so
	# nothing here should be moving except the words.
	_glitch = Glitch.new()
	_glitch.intensity = 0.06
	_glitch.calm_gap = Vector2(3.5, 7.0)
	add_child(_glitch)

	# One ornament hanging in the dark behind the words, breathing. It is the same four
	# points the menu and the instructions page are decorated with, so the last room in the
	# game is furnished by the same hand as the first one.
	_orn = TextureRect.new()
	_orn.texture = UiStyle.load_art(ORN)
	_orn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_orn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_orn.size = Vector2(130.0, 130.0)
	_orn.position = Vector2(255.0, 106.0)
	_orn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_orn.modulate = COL_MARK
	_orn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_orn)
	var breath := create_tween().set_loops()
	breath.tween_property(_orn, "modulate:a", 0.06, 3.1).set_trans(Tween.TRANS_SINE)
	breath.tween_property(_orn, "modulate:a", 0.16, 3.1).set_trans(Tween.TRANS_SINE)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_override("font", _hand())
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", COL_WORD)
	_label.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.01, 0.95))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector2(60.0, 140.0)
	_label.size = Vector2(520.0, 80.0)
	_label.modulate.a = 0.0
	add_child(_label)

	add_child(UiStyle.at("SPACE TO SKIP", 9, 60.0, 336.0, 520.0, COL_MARK,
		HORIZONTAL_ALIGNMENT_CENTER))

	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## The game's own damaged hand: this is the voice the rooms are written in, so it is the one
## that has the last word.
func _hand() -> Font:
	var tool: Node = preload("res://ui/creepy_font.gd").new()
	var f: Font = tool.call("build_eerie") as Font
	tool.free()
	return f


func _run() -> void:
	for line in LINES:
		if _done:
			return
		await _say(line)
	if _done:
		return
	await get_tree().create_timer(0.8).timeout
	_to_credits()


func _say(text: String) -> void:
	_label.text = text
	_glitch.burst(0.45)
	var t := create_tween()
	t.tween_property(_label, "modulate:a", 1.0, FADE_IN)
	t.tween_interval(HOLD)
	t.tween_property(_label, "modulate:a", 0.0, 0.45)
	await t.finished


## Any key or click at all. The first one takes the player straight to the names rather
## than throwing anything away: the beat is short, but it is not compulsory.
func _unhandled_input(event: InputEvent) -> void:
	if not _skippable or _done:
		return
	var key := event as InputEventKey
	var click := event as InputEventMouseButton
	var pressed: bool = (key != null and key.pressed and not key.echo) \
		or (click != null and click.pressed)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	_to_credits()


func _to_credits() -> void:
	if _done:
		return
	_done = true
	_skippable = false
	AudioManager.play_sfx("ui", -4.0)
	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, FADE_OUT)
	await out.finished
	GameState.start_credits()