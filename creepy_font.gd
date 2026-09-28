extends Node
## The room's handwriting.
##
## Every glyph in this game is drawn here, by hand, into one 1-bit atlas and
## handed to Godot as a bitmap font — then installed as the fallback font, so
## every piece of text in the game (HUD, signs, cards, menus) wears it.
##
## It is deliberately damaged. Strokes are rubbed through, thorns grow off the
## ends of letters where a stroke should have stopped, and the letters sit
## unevenly on their baseline, the way writing does when the person writing it
## is not comfortable. It is a small, worn, 5x7 hand.

const FIXED_SIZE := 8
## The cell the glyph is drawn into, including one spare column and row for the
## thorns that grow out of the strokes.
const CELL_W := 6
const CELL_H := 8
## The glyph body proper: 5 wide, 7 tall, sitting on the baseline at row 7.
const BODY_W := 5
const BODY_H := 7
const COLS := 16

const INK := Color(1, 1, 1, 1)

## Every character the game can write, as 7 rows of 5. "1" is ink.
const GLYPHS := {
	" ": "...../...../...../...../...../...../.....",
	"A": ".111./1...1/1...1/11111/1...1/1...1/1...1",
	"B": "1111./1...1/1...1/1111./1...1/1...1/1111.",
	"C": ".111./1...1/1..../1..../1..../1...1/.111.",
	"D": "1111./1...1/1...1/1...1/1...1/1...1/1111.",
	"E": "11111/1..../1..../1111./1..../1..../11111",
	"F": "11111/1..../1..../1111./1..../1..../1....",
	"G": ".111./1...1/1..../1.111/1...1/1...1/.111.",
	"H": "1...1/1...1/1...1/11111/1...1/1...1/1...1",
	"I": "11111/..1../..1../..1../..1../..1../11111",
	"J": "..111/...1./...1./...1./...1./1..1./.11..",
	"K": "1...1/1..1./1.1../11.../1.1../1..1./1...1",
	"L": "1..../1..../1..../1..../1..../1..../11111",
	"M": "1...1/11.11/1.1.1/1...1/1...1/1...1/1...1",
	"N": "1...1/11..1/1.1.1/1..11/1...1/1...1/1...1",
	"O": ".111./1...1/1...1/1...1/1...1/1...1/.111.",
	"P": "1111./1...1/1...1/1111./1..../1..../1....",
	"Q": ".111./1...1/1...1/1...1/1.1.1/1..1./.11.1",
	"R": "1111./1...1/1...1/1111./1.1../1..1./1...1",
	"S": ".1111/1..../1..../.111./....1/....1/1111.",
	"T": "11111/..1../..1../..1../..1../..1../..1..",
	"U": "1...1/1...1/1...1/1...1/1...1/1...1/.111.",
	"V": "1...1/1...1/1...1/1...1/1...1/.1.1./..1..",
	"W": "1...1/1...1/1...1/1...1/1.1.1/11.11/1...1",
	"X": "1...1/1...1/.1.1./..1../.1.1./1...1/1...1",
	"Y": "1...1/1...1/.1.1./..1../..1../..1../..1..",
	"Z": "11111/....1/...1./..1../.1.../1..../11111",
	"0": ".111./1...1/1..11/1.1.1/11..1/1...1/.111.",
	"1": "..1../.11../..1../..1../..1../..1../.111.",
	"2": ".111./1...1/....1/...1./..1../.1.../11111",
	"3": "11111/...1./..1../...1./....1/1...1/.111.",
	"4": "...1./..11./.1.1./1..1./11111/...1./...1.",
	"5": "11111/1..../1111./....1/....1/1...1/.111.",
	"6": "..11./.1.../1..../1111./1...1/1...1/.111.",
	"7": "11111/....1/...1./..1../.1.../.1.../.1...",
	"8": ".111./1...1/1...1/.111./1...1/1...1/.111.",
	"9": ".111./1...1/1...1/.1111/....1/...1./.11..",
	".": "...../...../...../...../...../..11./..11.",
	",": "...../...../...../...../...../..11./.1...",
	":": "...../..11./..11./...../..11./..11./.....",
	";": "...../..11./..11./...../..11./.1.../.....",
	"!": "..1../..1../..1../..1../..1../...../..1..",
	"?": ".111./1...1/....1/...1./..1../...../..1..",
	"'": "..1../..1../...../...../...../...../.....",
	"\"": ".1.1./.1.1./...../...../...../...../.....",
	"-": "...../...../...../.111./...../...../.....",
	"_": "...../...../...../...../...../...../11111",
	"/": "....1/....1/...1./..1../.1.../1..../1....",
	"\\": "1..../1..../.1.../..1../...1./....1/....1",
	"(": "...1./..1../.1.../.1.../.1.../..1../...1.",
	")": ".1.../..1../...1./...1./...1./..1../.1...",
	"[": ".111./.1.../.1.../.1.../.1.../.1.../.111.",
	"]": ".111./...1./...1./...1./...1./...1./.111.",
	"<": "...1./..1../.1.../1..../.1.../..1../...1.",
	">": ".1.../..1../...1./....1/...1./..1../.1...",
	"+": "...../..1../..1../11111/..1../..1../.....",
	"=": "...../...../11111/...../11111/...../.....",
	"*": "...../1.1.1/.111./11111/.111./1.1.1/.....",
	"%": "11..1/11..1/...1./..1../.1.../1..11/1..11",
	"#": ".1.1./.1.1./11111/.1.1./11111/.1.1./.1.1.",
	"@": ".111./1...1/1.111/1.1.1/1.111/1..../.111.",
	"&": ".11../1..1./1.1../.1.../1.1.1/1..1./.11.1",
	"$": "..1../.1111/1.1../.111./..1.1/1111./..1..",
	"~": "...../...../.1..1/1.1.1/1..1./...../.....",
	"^": "..1../.1.1./1...1/...../...../...../.....",
	"|": "..1../..1../..1../..1../..1../..1../..1..",
}


func _ready() -> void:
	ThemeDB.fallback_font = build()


## The ending's voice: the same hand, but worse — glyphs rubbed through, thorns
## on the strokes, and a baseline that will not hold still. Damaged enough to be
## unsettling, not so damaged that the words cannot be read.
func build_eerie() -> FontFile:
	return build(12, 9, 1.3, 0.85)


## The whole alphabet, as one font. Public so it can also be applied by hand.
##
## `damage` and `thorn` are how far the hand has come apart: the chance in a
## hundred that any single ink pixel has been rubbed away, and the chance in a
## hundred that a stroke grows a thorn it should not have. `wobble` lifts and
## drops whole glyphs off the baseline and `shaky` crowds or spreads the
## letters, so a word is never written the same way twice.
func build(damage: int = 7, thorn: int = 5, wobble: float = 0.0, shaky: float = 0.0) -> FontFile:
	var font := FontFile.new()
	font.font_name = "the room"
	font.font_weight = 400
	font.fixed_size = FIXED_SIZE
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_ENABLED
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.hinting = TextServer.HINTING_NONE
	font.allow_system_fallback = false

	var chars: Array = GLYPHS.keys()
	chars.sort()
	var rows: int = int(ceil(float(chars.size()) / float(COLS)))
	var atlas := Image.create_empty(COLS * CELL_W, rows * CELL_H, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))

	var size_key := Vector2i(FIXED_SIZE, 0)
	for i in chars.size():
		var ch: String = chars[i]
		var code: int = ch.unicode_at(0)
		var cell := Vector2i((i % COLS) * CELL_W, floori(float(i) / float(COLS)) * CELL_H)
		var grid := _grid(GLYPHS[ch])
		_draw(atlas, cell, grid, code, damage, thorn)

		var box := _ink_bounds(grid)
		var ink_w: float = float(box.size.x)
		var ink_h: float = float(box.size.y)
		var uv := Rect2(Vector2(cell + Vector2i(box.position)), Vector2(ink_w, ink_h))
		var advance := 3.0 if ink_w <= 0.0 else ink_w + 1.0
		# a worse hand also refuses to sit level, and refuses to keep its
		# spacing even — but the same letter always fails the same way, so the
		# alphabet stays still instead of boiling
		var lift := Vector2.ZERO
		if wobble > 0.0:
			lift = Vector2(0.0, roundf(_unit(code, 11) * wobble))
		if shaky > 0.0 and ink_w > 0.0:
			advance = maxf(1.0, advance + roundf(_unit(code, 23) * shaky))
		for c: int in _codes(ch, code):
			font.set_glyph_texture_idx(0, size_key, c, 0)
			font.set_glyph_uv_rect(0, size_key, c, uv)
			font.set_glyph_size(0, size_key, c, Vector2(ink_w, ink_h))
			font.set_glyph_offset(0, size_key, c, Vector2(box.position.x, box.position.y - BODY_H) + lift)
			font.set_glyph_advance(0, FIXED_SIZE, c, Vector2(advance, 0.0))

	font.set_texture_image(0, size_key, 0, atlas)
	font.set_cache_ascent(0, FIXED_SIZE, float(BODY_H))
	font.set_cache_descent(0, FIXED_SIZE, 1.0)
	return font


## A character is registered for itself, and — since the room only has one
## voice — its other case wears the same glyph.
func _codes(ch: String, code: int) -> Array:
	var out: Array = [code]
	if ch >= "a" and ch <= "z":
		out.append(code - 32)
	elif ch >= "A" and ch <= "Z":
		out.append(code + 32)
	return out


func _grid(rows: String) -> PackedStringArray:
	return rows.split("/")


# ─────────────────────────── the damage ───────────────────────────

func _draw(im: Image, cell: Vector2i, grid: PackedStringArray, code: int, damage: int, thorn: int) -> void:
	for y in CELL_H:
		for x in CELL_W:
			if y < BODY_H and x < BODY_W and grid[y][x] == "1":
				# worn — pixels of every glyph have been rubbed away
				if _h(code, x, y) < damage:
					continue
				im.set_pixel(cell.x + x, cell.y + y, INK)
			elif _touches(grid, x, y) and _h(code, x + 31, y + 77) < thorn:
				# thorn — the stroke does not stop where it should
				im.set_pixel(cell.x + x, cell.y + y, INK)


## -1..1, and always the same for the same glyph — so a hand that will not hold
## still still holds still the same way every frame.
func _unit(code: int, salt: int) -> float:
	return float(_h(code, salt, salt * 7)) / 99.0 * 2.0 - 1.0


func _touches(grid: PackedStringArray, x: int, y: int) -> bool:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if nx < 0 or ny < 0 or nx >= BODY_W or ny >= BODY_H:
			continue
		if grid[ny][nx] == "1":
			return true
	return false


func _ink_bounds(grid: PackedStringArray) -> Rect2i:
	var box := Rect2i()
	for y in CELL_H:
		for x in CELL_W:
			var on: bool = y < BODY_H and x < BODY_W and grid[y][x] == "1"
			var thorn: bool = not on and _touches(grid, x, y)
			if on or thorn:
				if box.size == Vector2i.ZERO:
					box = Rect2i(Vector2i(x, y), Vector2i(1, 1))
				else:
					var end: Vector2i = box.end
					box = Rect2i(Vector2i(mini(box.position.x, x), mini(box.position.y, y)),
						Vector2i(maxi(end.x, x + 1), maxi(end.y, y + 1)) - Vector2i(mini(box.position.x, x), mini(box.position.y, y)))
	return box


## A small integer hash — the same glyph is always damaged the same way, so the
## alphabet is stable frame to frame.
func _h(a: int, b: int, c: int) -> int:
	return abs((a * 73856093) ^ (b * 19349663) ^ (c * 83492791)) % 100
