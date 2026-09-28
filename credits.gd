extends Control
## Where the game stops talking about itself.
##
## There is exactly one way into this screen and it is `GameState.start_credits()`. Every win
## walks through it: the ending's own finish, the ending after the void, and the parkour room,
## which reaches the ending through `advance_area()`. So the credits are hung off that one call,
## and no win state has to know that credits exist.
##
## It scrolls. Slow, linear, one pass, on the same dimmed sky the title and the opening are on —
## the last look at the room rather than a new one. The game's own hand writes the names and the
## game's own glitch convulses once in the middle of it, because both of those already exist and
## a credits sequence is not a reason to build a second anything.

const TITLE := "res://ui/title_screen.tscn"
const SKY := "res://assets/generated/title_sky.png"

## Pixels a second. It is meant to be read at, not watched. At 27 the roll was twenty-five
## seconds long, which is longer than anybody reads credits for and longer than the reel is:
## measured against the reel's own height this is a shade over eighteen, which is still slow
## enough to read a name off without leaning in.
const SPEED := 36.0
## Where the reel comes to rest, measured against the frame rather than the reel: the last line
## stops here, in the middle of the screen, instead of running off the top of it.
const REST_Y := 236.0

const COL_HEAD := Color(0.949, 0.129, 0.541, 0.92)
const COL_NAME := Color(0.933, 0.925, 0.965)
## The colour the fourth wall writes in. The last section is the only thing here in it, which is
## what makes it read as the game speaking rather than as one more credit.
const COL_LAST := Color(0.941, 0.129, 0.145)
const COL_MARK := Color(0.78, 0.76, 0.86)
const COL_DIM := Color(0.56, 0.60, 0.70)

## What the run was called, in order. `header` empty means the headerless section: the one that
## is not a credit at all, given the extra room, the size and the colour of the game's own voice.
const CREDITS := [
	{"header": "GAME DESIGN & PROGRAMMING", "names": ["Omkar Avhad", "Reuben Alwyn"]},
	{"header": "ART", "names": ["Omkar Avhad", "Reuben Alwyn"]},
	{"header": "MUSIC & SOUND", "names": ["Reuben Alwyn"]},
	{"header": "MADE WITH", "names": ["Godot Engine", "Built with Ziva"]},
	{"header": "", "names": ["it was never real.", "but you were."]},
]
## The line at the very bottom, on its own, under the last word.
const MARK := "BYTE ME — © 2026"

var _reel: Control
var _pen: float = 0.0
var _special_end: float = 0.0
var _tween: Tween
var _glitch: Glitch
var _mark: Label
var _summary: Label
var _prompt: Label
var _done: bool = false
var _font_cache: Dictionary = {}
var _hand: Font


func _ready() -> void:
	GameState.set_paused(false)
	GameState.current_level = "credits"
	AudioManager.play_music("music_calm")
	AudioManager.set_music_distortion(0.0)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.043, 0.020, 0.078, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The sky the title and the opening are on, dimmed nearly into the dark. Expand mode before
	# size: a Control clamps its size up to the minimum in force when the size is assigned, and
	# lowering that minimum afterwards never gives the size back — the painting would stay drawn
	# 1:1 and hang off the side of the frame instead of covering it.
	var sky := TextureRect.new()
	sky.texture = UiStyle.load_art(SKY)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sky.size = Vector2(688, 388)
	sky.position = Vector2(-24, -14)
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sky.modulate = Color(0.34, 0.32, 0.42)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)

	var ink := ColorRect.new()
	ink.color = Color(0.043, 0.020, 0.078, 0.86)
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ink)
	ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The game's own glitch, at a whisper, for one convulsion in the middle of the scroll and
	# nothing else at all.
	_glitch = Glitch.new()
	_glitch.intensity = 0.10
	add_child(_glitch)

	_reel = Control.new()
	_reel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reel.position = Vector2(0.0, 360.0)
	add_child(_reel)

	_pen = 84.0
	for entry in CREDITS:
		var header: String = entry["header"]
		if header != "":
			_roll_line(header, 12, COL_HEAD, _display(700, 5))
			_pen += 8.0
			for who in entry["names"]:
				_roll_line(who, 15, COL_NAME, _creepy())
			_pen += 26.0
		else:
			# the headerless one. No header, more room around it, bigger, and the only thing on
			# the reel in the colour the fourth wall writes in
			_pen += 14.0
			for who in entry["names"]:
				_roll_line(who, 22, COL_LAST, _creepy())
				_pen += 6.0
			_special_end = _pen
	_reel.size = Vector2(640.0, _pen)

	# The mark and the two small lines under it are not on the reel. The reel arrives and stops
	# with the last word sitting in the middle of the frame, and these appear below it: a line
	# that scrolls off the top has been read, but a line the sequence is *for* should still be
	# there when the reader looks up at it.
	_mark = _line(MARK, 13, COL_MARK, _display(600, 6))
	_mark.position = Vector2(0.0, 272.0)
	_mark.visible = false
	add_child(_mark)

	_summary = _line(_run_summary(), 10, COL_DIM, _creepy())
	_summary.position = Vector2(0.0, 296.0)
	_summary.visible = false
	add_child(_summary)

	_prompt = _line("PRESS ANY KEY", 10, COL_DIM, _display(600, 4))
	_prompt.position = Vector2(0.0, 328.0)
	_prompt.visible = false
	add_child(_prompt)

	_roll()


## Down the screen, slowly, once. The reel stops with the last line of it in the middle of the
## frame rather than running off the top: what the whole sequence is for is that line.
func _roll() -> void:
	var end_y: float = REST_Y - _special_end
	var seconds: float = (360.0 - end_y) / SPEED
	_tween = create_tween()
	_tween.tween_property(_reel, "position:y", end_y, seconds).set_trans(Tween.TRANS_LINEAR)
	_convulse(seconds * 0.6)
	await _tween.finished
	_finish()


## One convulsion, on the way, where the lines stop being names and start being addressed to
## whoever is holding the keyboard.
func _convulse(after: float) -> void:
	await get_tree().create_timer(after).timeout
	if _done:
		return
	_glitch.burst(0.6)


func _finish() -> void:
	if _done:
		return
	_done = true
	AudioManager.play_sfx("chime", -10.0)
	_mark.visible = true
	_summary.visible = true
	_prompt.visible = true
	var pulse := create_tween().set_loops()
	pulse.tween_property(_prompt, "modulate:a", 0.30, 1.3)
	pulse.tween_property(_prompt, "modulate:a", 1.0, 1.3)


func _roll_line(text: String, font_size: int, col: Color, font: Font) -> void:
	var l := _line(text, font_size, col, font)
	l.position = Vector2(0.0, _pen)
	_reel.add_child(l)
	_pen += float(font_size) + 8.0


func _line(text: String, font_size: int, col: Color, font: Font) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(640.0, float(font_size) + 8.0)
	return l


## The names are written in the game's damaged hand and the headers are not: the hand is the
## voice the rooms are written in, so it is the one that says who did this.
func _creepy() -> Font:
	if _hand == null:
		var tool: Node = preload("res://ui/creepy_font.gd").new()
		_hand = tool.call("build", 1, 1, 0.4, 0.3) as Font
		tool.free()
	return _hand


## A clean letterspaced sans for the headers and the mark. Not shipped with the game — it is a
## system font, asked for by family name, and it falls back through whatever the machine has.
func _display(weight: int = 600, spacing: int = 0) -> FontVariation:
	var key := "%d:%d" % [weight, spacing]
	if _font_cache.has(key):
		return _font_cache[key]
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray(["Segoe UI", "Inter", "Arial", "sans-serif"])
	sys.font_weight = weight
	var fv := FontVariation.new()
	fv.base_font = sys
	if spacing != 0:
		fv.set_spacing(TextServer.SPACING_GLYPH, spacing)
	_font_cache[key] = fv
	return fv


## What the run cost. GameState has been counting deaths and run time all along; the credits
## were the one place that could have said so and never did.
func _run_summary() -> String:
	# Opened from the title there is no run to report on, and a line saying the player
	# finished in no time without dying would be the sequence lying about itself.
	if GameState.run_time < 1.0 and GameState.deaths == 0:
		return ""
	var total: int = int(GameState.run_time)
	var time_text: String = "%d:%02d" % [floori(float(total) / 60.0), total % 60]
	var deaths: int = GameState.deaths
	if deaths == 0:
		return "You reached the end in %s without dying once." % time_text
	if deaths == 1:
		return "You reached the end in %s, dying once." % time_text
	return "You reached the end in %s, dying %d times." % [time_text, deaths]


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	var click := event as InputEventMouseButton
	var pressed: bool = (key != null and key.pressed and not key.echo) \
		or (click != null and click.pressed)
	if not pressed:
		return
	AudioManager.play_sfx("ui", -4.0)
	if _done:
		get_tree().change_scene_to_file(TITLE)
		return
	# The first press does not throw the credits away, it hastens them: the reel snaps to its
	# ending and the sequence finishes in front of the player rather than without them. The
	# press after that is the one that leaves.
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_reel.position.y = REST_Y - _special_end
	_finish()
