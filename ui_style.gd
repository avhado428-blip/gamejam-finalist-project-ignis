class_name UiStyle
extends RefCounted
## One look for every menu in the game.
##
## Before this, the title screen, the pause menu and the credits all used Godot's
## stock Button theme: rounded grey pills with a blue focus ring, sitting on top
## of hand-drawn pixel-art panels. It read as a prototype. Everything here is
## built from the same flat dark fill and single hairline border the rest of the
## game's furniture uses, so the menus belong to the same room as the levels.
##
## Static, so no caller has to hold an instance.

const INK := Color(0.043, 0.020, 0.078, 0.96)
const FACE := Color(0.118, 0.063, 0.192, 0.97)
const FACE_HOVER := Color(0.243, 0.094, 0.357, 0.99)
const LINE := Color(0.706, 0.616, 0.847, 0.48)
const LINE_HOT := Color(0.949, 0.129, 0.541, 0.98)
const TEXT := Color(0.933, 0.910, 0.847)
const TEXT_DIM := Color(0.678, 0.635, 0.729)
const TEXT_HOT := Color(1.0, 0.976, 0.929)
const TEXT_ACCENT := Color(0.976, 0.855, 0.192)

## Built once and kept: a font is expensive to assemble and every menu here wants the
## same two or three of them.
static var _fonts: Dictionary = {}


## A clean letterspaced sans, for headers, menus and anything that is furniture rather
## than voice. It is a system font asked for by family name, so it falls back through
## whatever the machine actually has.
static func display(weight: int = 600, spacing: int = 0) -> Font:
	var key := "%d:%d" % [weight, spacing]
	if _fonts.has(key):
		return _fonts[key]
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray(["Segoe UI", "Inter", "Arial", "sans-serif"])
	sys.font_weight = weight
	var fv := FontVariation.new()
	fv.base_font = sys
	if spacing != 0:
		fv.set_spacing(TextServer.SPACING_GLYPH, spacing)
	_fonts[key] = fv
	return fv


## A menu button that looks like part of the game rather than part of the engine.
## The focus box is deliberately hollow: Godot draws it over the top of the
## button, so a filled one would hide the label.
static func button(text: String, w: float = 112.0, h: float = 22.0) -> Button:
	var b := Button.new()
	b.text = text
	b.size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", TEXT_HOT)
	b.add_theme_color_override("font_focus_color", TEXT_HOT)
	b.add_theme_color_override("font_pressed_color", TEXT_ACCENT)
	b.add_theme_stylebox_override("normal", box(FACE, LINE))
	b.add_theme_stylebox_override("hover", box(FACE_HOVER, LINE_HOT))
	b.add_theme_stylebox_override("pressed", box(INK, LINE_HOT))
	b.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), LINE_HOT))
	return b


## A flat panel: the same fill as a button, used for the box behind a menu.
static func panel(w: float, h: float) -> Panel:
	var p := Panel.new()
	p.size = Vector2(w, h)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", box(INK, LINE))
	return p


static func box(fill: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	return sb


## The title screen's buttons: bigger than a menu button, still the same family. The title
## is the one screen in the game with a picture behind it, so its buttons sit on a dark,
## semi-see-through plate instead of the solid panels the other menus wear — the art keeps
## showing through where it is dark — and each carries a heavier edge down its left side, so
## the stack of them reads as one column with a spine.
static func title_button(text: String, w: float = 176.0, h: float = 26.0) -> Button:
	var b := Button.new()
	b.text = text
	b.size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Color(0.867, 0.851, 0.902))
	b.add_theme_color_override("font_hover_color", TEXT_HOT)
	b.add_theme_color_override("font_focus_color", TEXT_HOT)
	b.add_theme_color_override("font_pressed_color", TEXT_ACCENT)
	b.add_theme_stylebox_override("normal", plate(FACE_GLASS, LINE, 3))
	b.add_theme_stylebox_override("hover", plate(FACE_GLASS_HOT, LINE_HOT, 5))
	b.add_theme_stylebox_override("pressed", plate(INK, LINE_HOT, 5))
	b.add_theme_stylebox_override("focus", plate(Color(0.949, 0.129, 0.541, 0.12), LINE_HOT, 5))
	return b


## The home menu's buttons: the same family as everything else here, but drawn as a
## pointed lozenge rather than a rectangle (see MenuPlate) and set larger and wider,
## because the title screen is the one place the player is looking at the menu and not
## at the room behind it.
static func menu_button(text: String, w: float = 176.0, h: float = 32.0) -> Button:
	var b := Button.new()
	b.text = text
	b.size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", display(600, 3))
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", Color(0.80, 0.78, 0.85))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.87, 0.87))
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.91, 0.91))
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.72, 0.72))
	b.add_theme_stylebox_override("normal", MenuPlate.idle())
	b.add_theme_stylebox_override("hover", MenuPlate.hot())
	b.add_theme_stylebox_override("pressed", MenuPlate.pressed())
	b.add_theme_stylebox_override("focus", MenuPlate.focus())
	return b


## A title plate. `edge` is how thick the left border is: a StyleBoxFlat has one border
## colour for all four sides, so the spine is the left side being drawn wider, not a
## different colour. Growing it from 3 to 5 is how a button says the mouse has found it.
static func plate(fill: Color, border: Color, edge: int = 3) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.border_width_left = edge
	sb.content_margin_left = 12.0
	sb.content_margin_right = 10.0
	return sb


## The one way UI art is loaded in this project. The import cache first, then the file's own
## pixels if the editor has not got round to importing it — a menu must never depend on how
## recently someone pressed Import, and a missing texture must never be a crash.
static func load_art(path: String) -> Texture2D:
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null:
		var img: Image = Image.load_from_file(path)
		if img != null:
			tex = ImageTexture.create_from_image(img)
	return tex


## The colour a title plate is filled with before the mouse finds it, and after.
const FACE_GLASS := Color(0.055, 0.024, 0.098, 0.82)
const FACE_GLASS_HOT := Color(0.180, 0.071, 0.267, 0.94)


static func label(text: String, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	return l


## A label at a fixed place, for the times a caller wants one positioned inline.
static func at(text: String, font_size: int, x: float, y: float, w: float, col: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text, font_size, col)
	l.position = Vector2(x, y)
	l.size = Vector2(w, font_size + 6)
	l.horizontal_alignment = align
	return l
