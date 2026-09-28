extends Control
## The rules, on one page, between the opening and the first area.
##
## There is only one copy of a rule in this project, and this is it. The title's
## INSTRUCTIONS button opens this same page — not an overlay built into the title — so the
## controls are written once and can never drift apart from themselves.
##
## It sits on the same sky as the opening, dimmed almost to nothing, so a player walking
## title → opening → here → gameplay is never once shown a different room.

const FIRST_AREA := 0
const TITLE := "res://ui/title_screen.tscn"
const SKY := "res://assets/generated/title_sky.png"

var _begin: Button


func _ready() -> void:
	GameState.set_paused(false)
	GameState.current_level = "instructions"
	# no-op if the opening's track is still playing; this page is not a new place
	AudioManager.play_music("music_calm")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


const SIGIL := "res://assets/generated/ui_sigil.png"
const DIVIDER := "res://assets/generated/ui_divider.png"

var _keycaps: Dictionary = {}
var _rows: Array = []
var _font_cache: Dictionary = {}
var _hand: Font


func _build() -> void:
	var back := TextureRect.new()
	back.texture = _sky()
	back.position = Vector2(-24, -14)
	# expand mode before the size, necessarily: a Control clamps its size up to the minimum in
	# force when the size is assigned, and lowering that minimum afterwards never hands the size
	# back — the painting would stay drawn 1:1, hanging off the frame instead of covering it.
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	back.size = Vector2(688, 388)
	back.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	back.modulate = Color(0.40, 0.38, 0.48)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)

	var ink := ColorRect.new()
	ink.color = Color(0.043, 0.020, 0.078, 0.90)
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ink)
	ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# What makes this a room with a wall in it rather than a wall: two big sigils, half off the
	# corners, turning the whole time the page is open. Over the dark and under everything else,
	# and taking no input at all.
	_sigil(Vector2(-96, -86), 320.0, -0.20, 0.20)
	_sigil(Vector2(438, 190), 300.0, 0.34, 0.15)

	# And then the page itself: one soft plate carrying everything that has to be read. This is
	# the only thing on the page that is not type, a line or a button, and it is here because
	# the rest of the page is written on a *photograph* — a sky with spires in it — and a sky
	# with spires in it is a fine thing to look at and a terrible thing to read small grey text
	# on. It stops short of the frame on all four sides so the room is still visible around it,
	# and it is dark enough to hold the words without becoming a second background.
	var sheet := Panel.new()
	sheet.name = "Sheet"
	sheet.position = Vector2(78.0, 14.0)
	sheet.size = Vector2(484.0, 340.0)
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_theme_stylebox_override("panel", UiStyle.box(
		Color(0.035, 0.016, 0.062, 0.74), Color(0.706, 0.616, 0.847, 0.20)))
	add_child(sheet)

	var mid := HORIZONTAL_ALIGNMENT_CENTER
	var left := HORIZONTAL_ALIGNMENT_LEFT

	# ── the masthead ─────────────────────────────────────────────────────────────
	add_child(_eyebrow("HOW TO BE HERE"))
	_title("CONTROLS")
	_diamond(Vector2(320.0, 108.0), 20.0)
	add_child(UiStyle.at("the room is not the same twice", 12, 96, 116, 448,
		Color(0.72, 0.68, 0.82), mid))
	add_child(_rule(96, 138, 448))

	# ── the table ────────────────────────────────────────────────────────────────
	# Two columns, read down and then across: keys on the left of each, what they do against the
	# column's own right edge. Nothing is drawn to hold them in place — the alignment is the
	# structure, and the hairline under each header is the only rule on the page.
	_table(96.0, 208.0, 170.0, [
		["MOVE", [["A  /  D", "walk"], ["SPACE", "jump"]]],
		["ELSEWHERE", [["R", "restart"], ["ESC", "pause"]]],
	])
	_table(336.0, 208.0, 170.0, [
		["THE TWO WORLDS", [["Q", "shift reality"], ["E", "dash"]]],
	])
	add_child(UiStyle.at("the room is rebuilt around you when you", 10, 320, 236, 234,
		Color(0.70, 0.68, 0.79), left))
	add_child(UiStyle.at("shift, and everything in the way when you dash.", 10, 320, 252, 234,
		Color(0.70, 0.68, 0.79), left))

	# The only thing drawn between the two columns: a hairline down the page's own centre,
	# so the halves read as two halves instead of one left-aligned list and a stray one.
	add_child(_rule(319, 170, 1.0, 112.0))

	# ── the footnote, and the way out ────────────────────────────────────────────
	add_child(_rule(96, 290, 448))
	# two lines, because at this size the sentence is 520 pixels long and the page is 448
	# wide: set on one line it ran off both edges of its own sheet and the player was told
	# the middle of it
	add_child(UiStyle.at("One of the two worlds is lying.", 10, 96, 296, 448,
		Color(0.80, 0.83, 0.90), mid))
	add_child(UiStyle.at("Three hits and the world takes you back to the last post.", 10, 96, 310, 448,
		Color(0.80, 0.83, 0.90), mid))

	# The button sits below everything rather than inside a box: this page is a page first and a
	# menu second, and a button hanging off the edge of the screen is the one thing on it that
	# nobody could read.
	_begin = UiStyle.button("BEGIN", 144.0)
	_begin.position = Vector2(248, 322)
	_begin.pressed.connect(_on_begin)
	add_child(_begin)

	add_child(UiStyle.at("ESC   back to the title", 10, 96, 328, 200, UiStyle.TEXT_DIM, left))
	_begin.grab_focus()
	_intro()


# ── the pieces the page is made of ───────────────────────────────────────────


## The page's own typeface: a clean letterspaced sans. A page of instructions is not written in
## the game's damaged hand — the headers, the keys and the title are the system's, and only what
## the keys *do* is written in the hand the rooms are written in. (System fonts are the one
## thing here that is not shipped with the game; the family list falls back through whatever the
## machine actually has, and off Windows it lands on the theme's default and still reads.)
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


## The game's own hand, built once. `build()` draws an alphabet from scratch, so building it per
## label would cost more than the whole page does.
##
## Damaged as little as this hand can be while still being it. The three actions down the right
## of the table are the only words on the page set in it, they are the smallest type on the page,
## and they are the words somebody has come here to read — so they get the hand with its thorns
## and none of its wobble. A letter that has been lifted off the baseline is charming at 22
## pixels, in the middle of a speech, and it is a letter at 11.
func _creepy() -> Font:
	if _hand == null:
		var tool: Node = preload("res://ui/creepy_font.gd").new()
		_hand = tool.call("build", 1, 1, 0.0, 0.0) as Font
		tool.free()
	return _hand


func _eyebrow(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", _display(600, 8))
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color(0.949, 0.129, 0.541, 0.92))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(448.0, 16.0)
	l.position = Vector2(96.0, 22.0)
	return l


## The word the page is about, drawn twice. There is no blur in a Control, so the halo is an
## outline: sixteen pixels of low-alpha pink around the same glyphs, which at this size reads as
## light spilling off the letters instead of as a border drawn round them. It breathes.
func _title(text: String) -> void:
	var glow := Label.new()
	glow.text = text
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.add_theme_font_override("font", _display(700, 3))
	glow.add_theme_font_size_override("font_size", 42)
	glow.add_theme_color_override("font_color", Color(0.949, 0.129, 0.541, 0.30))
	glow.add_theme_color_override("font_outline_color", Color(0.949, 0.129, 0.541, 0.32))
	glow.add_theme_constant_override("outline_size", 16)
	glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glow.size = Vector2(448.0, 60.0)
	glow.position = Vector2(96.0, 36.0)
	add_child(glow)

	var front := Label.new()
	front.text = text
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.add_theme_font_override("font", _display(700, 3))
	front.add_theme_font_size_override("font_size", 42)
	front.add_theme_color_override("font_color", Color(1.0, 0.90, 0.95))
	front.add_theme_color_override("font_outline_color", Color(0.043, 0.020, 0.078, 0.92))
	front.add_theme_constant_override("outline_size", 4)
	front.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	front.size = Vector2(448.0, 60.0)
	front.position = Vector2(96.0, 36.0)
	add_child(front)

	var breath := create_tween().set_loops()
	breath.tween_property(glow, "modulate:a", 0.55, 1.7).set_trans(Tween.TRANS_SINE)
	breath.tween_property(glow, "modulate:a", 1.0, 1.7).set_trans(Tween.TRANS_SINE)


func _diamond(pos: Vector2, span: float) -> void:
	var d := TextureRect.new()
	d.texture = UiStyle.load_art(DIVIDER)
	d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	d.size = Vector2(span, span)
	d.position = pos - Vector2(span, span) * 0.5
	d.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	d.modulate = Color(0.949, 0.129, 0.541, 0.85)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(d)


func _sigil(pos: Vector2, span: float, angle: float, alpha: float) -> void:
	var s := TextureRect.new()
	s.texture = UiStyle.load_art(SIGIL)
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.stretch_mode = TextureRect.STRETCH_SCALE
	s.size = Vector2(span, span)
	s.position = pos
	s.pivot_offset = Vector2(span, span) * 0.5
	s.rotation = angle
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.modulate = Color(0.949, 0.129, 0.541, alpha)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(s)
	# Slow enough that nobody ever catches it turning — only that it has turned. The wall is
	# never quite a still image, and that is the whole of the animation budget spent on it.
	var t := create_tween().set_loops()
	t.tween_property(s, "rotation", angle + 0.14, 9.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "rotation", angle - 0.14, 9.0).set_trans(Tween.TRANS_SINE)


## One column of the table. A section is a pink letterspaced header, a hairline, then rows of
## keycap-then-action. Returns where the column ended, so a caller can hang something under it.
##
## Every gap on the page is one of the four numbers here, so the air between a header and its
## rows, between two rows, and between two sections is set in one place and cannot drift.
const ROW_H := 18.0
const ROW_GAP := 18.0
const HEAD_GAP := 12.0
const AFTER_RULE := 5.0
const SECTION_GAP := 7.0


func _table(x: float, w: float, y: float, sections: Array) -> float:
	var cursor: float = y
	for section in sections:
		var header: String = section[0]
		var rows: Array = section[1]
		if header != "":
			var h := UiStyle.at(header, 10, x, cursor, w, Color(0.949, 0.129, 0.541))
			h.add_theme_font_override("font", _display(700, 4))
			add_child(h)
			_slide(h)
			cursor += HEAD_GAP
			add_child(_rule(x, cursor, w))
			cursor += AFTER_RULE
		for row in rows:
			_row(x, w, cursor, row[0], row[1])
			cursor += ROW_GAP
		cursor += SECTION_GAP
	return cursor


## One row of the table: a keycap on the left of the column and what it does right-aligned
## against the column's far edge. Both live inside one Control that is the row, so the two can
## never drift apart — the cap, its label and the action are all placed against the same origin
## and the same height, and the whole row slides into place as one thing.
func _row(x: float, w: float, y: float, key: String, action: String) -> void:
	var row := Control.new()
	row.position = Vector2(x, y)
	row.size = Vector2(w, ROW_H)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_slide(row)

	var cap := Panel.new()
	# wide enough for the pair of keys that share one cap ("A  /  D"): a cap whose label
	# touches both of its own edges looks like a mistake, not like a key
	cap.size = Vector2(46.0, ROW_H)
	cap.position = Vector2.ZERO
	cap.pivot_offset = cap.size * 0.5
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_theme_stylebox_override("panel", UiStyle.box(Color(0.118, 0.063, 0.192, 0.85),
		Color(0.706, 0.616, 0.847, 0.55)))
	row.add_child(cap)

	var kl := Label.new()
	kl.text = key
	kl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kl.add_theme_font_override("font", _display(600, 1))
	kl.add_theme_font_size_override("font_size", 10)
	kl.add_theme_color_override("font_color", UiStyle.TEXT_ACCENT)
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kl.size = cap.size
	cap.add_child(kl)

	# what this cap answers to, so that pressing a key on the page lights up its own cap
	for code in _codes_for(key):
		if not _keycaps.has(code):
			_keycaps[code] = []
		(_keycaps[code] as Array).append(cap)

	var al := Label.new()
	al.text = action
	al.mouse_filter = Control.MOUSE_FILTER_IGNORE
	al.add_theme_font_override("font", _creepy())
	al.add_theme_font_size_override("font_size", 11)
	al.add_theme_color_override("font_color", Color(0.90, 0.91, 0.96))
	al.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	al.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	al.size = row.size
	row.add_child(al)


## Which keys a cap answers to. Only the caps that name a key get any; the one that names a pair
## lights both of its keys, which is the honest thing for it to do.
func _codes_for(key: String) -> Array:
	match key:
		"A  /  D":
			return [KEY_A, KEY_D]
		"SPACE":
			return [KEY_SPACE]
		"Q":
			return [KEY_Q]
		"E":
			return [KEY_E]
		"R":
			return [KEY_R]
		"ESC":
			return [KEY_ESCAPE]
	return []


## Rows arrive rather than simply being there. Collected here and fired at the end of the build,
## one after another down the page, so the table assembles itself once on the way in.
func _slide(node: Control) -> void:
	var home: Vector2 = node.position
	node.modulate.a = 0.0
	node.position = home + Vector2(0.0, 9.0)
	_rows.append({"node": node, "home": home})


func _intro() -> void:
	for i in _rows.size():
		var entry: Dictionary = _rows[i]
		var node: Control = entry["node"]
		var home: Vector2 = entry["home"]
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(node, "modulate:a", 1.0, 0.35).set_delay(0.04 * float(i))
		t.tween_property(node, "position", home, 0.35) \
			.set_delay(0.04 * float(i)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## The page answers the keys it is describing. Press A on it and the A cap lights up — which is
## the whole difference between a page about controls and a page that has any.
func _input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	for code in [k.keycode, k.physical_keycode]:
		if _keycaps.has(code):
			for cap in _keycaps[code]:
				_flash(cap)
			return


func _flash(cap: Control) -> void:
	if not is_instance_valid(cap):
		return
	cap.modulate = Color(1.0, 0.72, 0.84)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(cap, "modulate", Color.WHITE, 0.45)
	t.tween_property(cap, "scale", Vector2(1.16, 1.16), 0.06)
	t.chain().tween_property(cap, "scale", Vector2.ONE, 0.24)


## One hairline. Sections get one above their first row and the page gets one before its
## footnote; being the only lines on the page is why nothing here needs to be in a box.
func _rule(x: float, y: float, w: float, h: float = 1.0) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.949, 0.129, 0.541, 0.24)
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _sky() -> Texture2D:
	var tex: Texture2D = load(SKY) as Texture2D
	if tex != null:
		return tex
	var img: Image = Image.load_from_file(SKY)
	if img != null:
		img.generate_mipmaps()
		return ImageTexture.create_from_image(img)
	return GradientTexture2D.new()


func _on_begin() -> void:
	AudioManager.play_sfx("ui", -4.0)
	GameState.start_area(FIRST_AREA)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		AudioManager.play_sfx("ui", -4.0)
		get_tree().change_scene_to_file(TITLE)