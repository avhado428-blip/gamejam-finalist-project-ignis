extends RefCounted
## FALSE//REAL — placeholder art generator, v2.
##
## Reworked for the zoomed-out 640x360 presentation and a colder, creepier read:
##   - 1px outline on every character so silhouettes read from a distance
##   - PERCEIVED face is a black hollow with pin-prick eyes; TRUE keeps a simple face
##   - perceived world: cold grout, hairline cracks, smeared blankness
##   - true world: rust, grime, flickering cyan
##   - 640x360 parallax backdrops with faint distant figures and fog
##   - a 3x5 pixel face for whispered wall marks
##
## Every file lands at its exact specified size and frame count.
## Regenerate with: load("res://tools/generate_placeholder_art.gd").new().run()

const C_PW := Color8(242, 236, 244)      # perceived paper
const C_PA := Color8(206, 186, 224)      # perceived lavender accent
const C_PG := Color8(178, 152, 206)      # perceived torn seam
const C_PC := Color8(118, 90, 158)       # perceived purple ink
const C_TD := Color8(22, 14, 38)         # true near-black violet
const C_TG := Color8(9, 5, 16)           # true void
const C_TR := Color8(198, 24, 108)       # true magenta
const C_TA := Color8(72, 220, 234)       # true cyan
const C_PT := Color8(74, 58, 112)        # indigo cloak
const C_PTS := Color8(46, 34, 76)
const C_PTO := Color8(14, 10, 22)
const C_PP := Color8(240, 233, 216)      # bone mask
const C_PPS := Color8(206, 196, 178)
const C_PPO := Color8(20, 16, 30)
const C_INT := Color8(250, 216, 46)      # interactable gold
const C_HAZ := Color8(200, 44, 96)       # hazard magenta-red
const C_MISS := Color8(255, 0, 255)
const C_STEEL := Color8(78, 58, 118)
const C_STEEL_HI := Color8(146, 124, 190)
const C_VOID := Color8(6, 8, 12)

const BG_W := 640
const BG_H := 360

## Minimal 3x5 uppercase face, '#' = lit pixel.
const FONT5 := {
	" ": ["...", "...", "...", "...", "..."],
	"A": [".#.", "#.#", "###", "#.#", "#.#"],
	"B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": [".##", "#..", "#..", "#..", ".##"],
	"D": ["##.", "#.#", "#.#", "#.#", "##."],
	"E": ["###", "#..", "##.", "#..", "###"],
	"F": ["###", "#..", "##.", "#..", "#.."],
	"G": [".##", "#..", "#.#", "#.#", ".##"],
	"H": ["#.#", "#.#", "###", "#.#", "#.#"],
	"I": ["###", ".#.", ".#.", ".#.", "###"],
	"J": ["..#", "..#", "..#", "#.#", ".#."],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"],
	"L": ["#..", "#..", "#..", "#..", "###"],
	"M": ["#.#", "###", "###", "#.#", "#.#"],
	"N": ["#.#", "###", "###", "###", "#.#"],
	"O": [".#.", "#.#", "#.#", "#.#", ".#."],
	"P": ["##.", "#.#", "##.", "#..", "#.."],
	"Q": [".#.", "#.#", "#.#", "##.", ".##"],
	"R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"S": [".##", "#..", ".#.", "..#", "##."],
	"T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#.#", "#.#", "#.#", "#.#", ".#."],
	"V": ["#.#", "#.#", "#.#", ".#.", ".#."],
	"W": ["#.#", "#.#", "###", "###", "#.#"],
	"X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
	"Z": ["###", "..#", ".#.", "#..", "###"],
	"'": [".#.", ".#.", "...", "...", "..."],
	"!": [".#.", ".#.", ".#.", "...", ".#."],
	"?": ["##.", "..#", ".#.", "...", ".#."],
	".": ["...", "...", "...", "...", ".#."],
	"/": ["..#", "..#", ".#.", "#..", "#.."],
	"-": ["...", "...", "###", "...", "..."],
	":": ["...", ".#.", "...", ".#.", "..."],
}

var rng := RandomNumberGenerator.new()


func run() -> void:
	rng.seed = 20240607
	_gen_player()
	_gen_patrol()
	_gen_reality_enemy()
	_gen_tilesets()
	_gen_props()
	_gen_backgrounds()
	_gen_effects()
	_gen_ui()
	_gen_story()
	# runs last: redraws the props, barriers and tilesets the creepy pass owns
	_gen_creepy_pass()
	print("PLACEHOLDER ART v2 :: generation complete.")


# ────────────────────── CREEPY PASS ──────────────────────
## A darker second pass over the things you navigate by: the drop you must not
## fall into, the barrier that stops you, and the furniture you read a room with.

func _gen_creepy_pass() -> void:
	_gen_void_shaft()
	_gen_wall_block()
	_gen_props_hard()
	_gen_tileset_true_dark()


## Two drops you can actually see, one per world, so a pit reads as a hole and not
## an absence of tiles. The true world's falls into black with the sunset bleeding
## down its walls; the pale world's falls into a bottomless white nothing.
func _gen_void_shaft() -> void:
	_gen_void_art("void_shaft_true.png", true)
	_gen_void_art("void_shaft_perceived.png", false)
	# the single-variant file is superseded
	DirAccess.remove_absolute("res://assets/props/void_shaft.png")


func _gen_void_art(file_name: String, dark: bool) -> void:
	var w := 64
	var h := 256
	var im := _img(w, h)
	var lip: Color = Color8(96, 112, 132) if dark else Color8(64, 66, 82)
	var face: Color = Color8(28, 34, 44) if dark else Color8(26, 28, 36)
	var abyss: Color = Color8(2, 2, 3) if dark else Color8(4, 4, 6)
	var deep: Color = Color8(0, 0, 1) if dark else Color8(0, 0, 0)
	var glow: Color = C_TA if dark else Color8(120, 124, 150)
	for y in range(h):
		var col: Color
		if y < 2:
			# the floor's own top edge, so its line carries straight across the gap
			col = lip
		elif y < 6:
			# a quick ambient occlusion just inside the opening — no hard bar
			col = lip.lerp(face, float(y - 2) / 4.0)
		elif y < 20:
			col = face.lerp(face.darkened(0.45), float(y - 6) / 14.0)
		else:
			var d := float(y - 20) / float(h - 21)
			col = face.lerp(abyss, minf(d * 6.0, 1.0)).lerp(deep, d * d)
		_rect(im, 0, y, w, 1, col)
	# faint ledges far down, so the drop reads as depth and not as a flat band
	for k in range(9):
		var ly := 34 + k * 26
		_rect(im, 5, ly, w - 10, 1, Color(0.55, 0.56, 0.62, 0.06 if dark else 0.05))
		_rect(im, 5, ly + 1, w - 10, 1, Color(0, 0, 0, 0.20 if dark else 0.05))
	# side falloff, so the shaft reads as a hole with edges
	for x in range(w):
		var edge := absf(float(x) / float(w - 1) - 0.5) * 2.0
		var k := edge * edge * (0.82 if dark else 0.60)
		for y in range(h):
			var cur := im.get_pixel(x, y)
			im.set_pixel(x, y, Color(cur.r * (1.0 - k), cur.g * (1.0 - k), cur.b * (1.0 - k), 1.0))
	# inner wall highlight just inside the rim on both sides, so the lip has thickness
	for y in range(2, 26):
		var a := (0.22 if dark else 0.30) * (1.0 - float(y - 2) / 24.0)
		_px(im, 2, y, Color(lip.r, lip.g, lip.b, a))
		_px(im, w - 3, y, Color(lip.r, lip.g, lip.b, a * 0.7))
	var r := RandomNumberGenerator.new()
	r.seed = 90210
	# light spilling down the walls, well below the opening
	for i in range(4):
		var sx := 7 + i * 16
		for k in range(46):
			var a: float = (0.12 if dark else 0.16) * (1.0 - float(k) / 46.0)
			_px(im, sx, 22 + k, Color(glow.r, glow.g, glow.b, a))
	# motes falling away into it
	for i in range(7):
		var mx := r.randi_range(8, w - 9)
		var my := r.randi_range(26, 90)
		var length := r.randi_range(30, 120)
		for k in range(length):
			var a := 0.22 * (1.0 - float(k) / float(length))
			_px(im, mx, my + k, Color(0.82, 0.84, 0.90, a) if dark else Color(1, 1, 1, a * 0.8))
			if r.randf() < 0.35:
				_px(im, mx + (1 if r.randf() < 0.5 else -1), my + k, Color(0.70, 0.72, 0.80, a * 0.6))
	if dark:
		# something further down than you can see
		_blob(im, 22, 76, 4, 3, Color(0.72, 0.74, 0.80, 0.14))
		_blob(im, 44, 104, 3, 2, Color(0.72, 0.74, 0.80, 0.10))
		_px(im, 18, 190, _fade(C_TA, 0.40))
		_px(im, 19, 191, _fade(C_TA, 0.22))
		_px(im, 46, 210, _fade(C_TA, 0.30))
		_px(im, 30, 228, _fade(C_TA, 0.24))
		_px(im, 31, 229, _fade(C_TA, 0.14))
	else:
		# faint pale wisps drifting in the black — and a shape that might be a face if you look too long
		_blob(im, 24, 96, 6, 4, Color(0.50, 0.51, 0.60, 0.14))
		_blob(im, 42, 140, 5, 3, Color(0.52, 0.53, 0.62, 0.11))
		_blob(im, 32, 186, 7, 5, Color(0.54, 0.55, 0.64, 0.09))
		_blob(im, 20, 220, 5, 3, Color(0.56, 0.57, 0.66, 0.07))
	_save(im, "res://assets/props/" + file_name)


## The barrier that stops you: plated, riveted, striped, unmistakably solid.
## Designed so any 32x64 window of it still reads as wall.
func _gen_wall_block() -> void:
	var w := 64
	var h := 96
	var im := _img(w, h)
	for px in range(4):
		var x := px * 16
		_rect(im, x, 0, 16, h, Color8(28, 34, 43))
		_rect(im, x + 2, 0, 13, h, Color8(40, 48, 60))
		_rect(im, x + 2, 0, 2, h, Color8(18, 22, 28))
		_rect(im, x + 14, 0, 1, h, Color8(62, 74, 90))
	for py in range(6):
		var y := py * 16
		_rect(im, 0, y, w, 2, Color8(66, 78, 94))
		_rect(im, 0, y + 2, w, 1, Color8(14, 18, 24))
		_px(im, 8, y + 5, Color8(80, 94, 112))
		_px(im, 24, y + 5, Color8(80, 94, 112))
		_px(im, 40, y + 5, Color8(80, 94, 112))
		_px(im, 56, y + 5, Color8(80, 94, 112))
	# warning stripes: it is a barrier and it wants you to know
	_rect(im, 0, 0, w, 4, Color8(142, 60, 34))
	_rect(im, 0, 1, w, 2, Color8(198, 92, 46))
	_rect(im, 0, h - 4, w, 4, Color8(142, 60, 34))
	_rect(im, 0, h - 3, w, 2, Color8(198, 92, 46))
	# a dead status pip
	_rect(im, 29, 45, 6, 6, Color8(16, 20, 26))
	_rect(im, 30, 46, 4, 4, Color8(30, 44, 50))
	_px(im, 31, 47, _fade(C_TA, 0.5))
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for i in range(30):
		_px(im, r.randi_range(0, w - 1), r.randi_range(0, h - 1), Color8(10, 13, 17))
	for i in range(8):
		_rect(im, r.randi_range(2, w - 4), r.randi_range(6, h - 22), 2, r.randi_range(5, 16), _fade(C_TR, 0.55))
	_save(im, "res://assets/props/wall_block.png")


func _gen_props_hard() -> void:
	var d := "res://assets/props/"

	# lever — a fat base, a bright handle, a live indicator
	var lv := _img(64, 32)
	for i in range(2):
		var ox := i * 32
		_rect(lv, ox + 9, 23, 14, 8, Color8(46, 32, 74))
		_rect(lv, ox + 10, 24, 12, 1, Color8(96, 72, 150))
		_hollow(lv, ox + 9, 23, 14, 8, C_INT)
		if i == 0:
			_rect(lv, ox + 13, 8, 3, 16, Color8(108, 82, 168))
			_rect(lv, ox + 13, 8, 1, 16, Color8(156, 124, 208))
			_circle(lv, ox + 14, 7, 3, Color8(250, 216, 46))
			_circle(lv, ox + 14, 7, 1, Color8(255, 246, 200))
		else:
			_rect(lv, ox + 19, 12, 3, 12, Color8(108, 82, 168))
			_rect(lv, ox + 19, 12, 1, 12, Color8(156, 124, 208))
			_circle(lv, ox + 20, 11, 3, Color8(250, 216, 46))
			_circle(lv, ox + 20, 11, 1, Color8(255, 252, 224))
		_rect(lv, ox + 11, 26, 3, 3, C_TA if i == 1 else Color8(22, 14, 38))
		_rect(lv, ox + 18, 26, 3, 3, Color8(22, 14, 38))
	_save(lv, d + "lever.png")

	# checkpoint — pylon, mast, vanes, and a light that ramps to a flare
	var ck := _img(128, 48)
	for i in range(4):
		var ox := i * 32
		_rect(ck, ox + 10, 38, 12, 9, Color8(46, 32, 74))
		_rect(ck, ox + 11, 39, 10, 1, Color8(96, 72, 150))
		_hollow(ck, ox + 10, 38, 12, 9, C_INT)
		_rect(ck, ox + 15, 16, 3, 23, Color8(76, 54, 124))
		_rect(ck, ox + 15, 16, 1, 23, Color8(146, 124, 190))
		_rect(ck, ox + 10, 20, 4, 2, Color8(58, 40, 96))
		_rect(ck, ox + 19, 24, 4, 2, Color8(58, 40, 96))
		var ring: Color = C_TA if i >= 2 else _fade(C_TA, 0.28 * float(i))
		_circle(ck, ox + 16, 12, 5 if i < 3 else 6, _fade(ring, 0.32 + 0.16 * float(i)))
		_circle(ck, ox + 16, 12, 3, ring)
		_circle(ck, ox + 16, 12, 1, Color8(245, 255, 255) if i >= 2 else ring)
		for k in range(i * 7):
			_px(ck, ox + 16, 36 - k, _fade(C_TA, 0.9))
			if i == 3 and k % 3 == 0:
				_px(ck, ox + 17, 36 - k, _fade(C_TA, 0.5))
		if i == 3:
			_circle(ck, ox + 16, 12, 9, _fade(C_TA, 0.16))
	_save(ck, d + "checkpoint.png")

	# the door that is not a door
	var dd := _img(64, 96)
	_rect(dd, 2, 2, 60, 92, Color8(238, 238, 244))
	_hollow(dd, 2, 2, 60, 92, Color8(174, 176, 196))
	_rect(dd, 9, 9, 46, 28, Color8(224, 224, 233))
	_hollow(dd, 9, 9, 46, 28, Color8(188, 190, 208))
	_rect(dd, 9, 46, 46, 18, Color8(228, 228, 237))
	_hollow(dd, 9, 46, 46, 18, Color8(188, 190, 208))
	_circle(dd, 32, 33, 13, Color8(146, 148, 170))
	_circle(dd, 32, 33, 10, Color8(92, 94, 116))
	_circle(dd, 32, 33, 7, Color8(232, 232, 242))
	_rect(dd, 30, 29, 5, 9, Color8(26, 30, 40))
	_circle(dd, 32, 29, 3, Color8(26, 30, 40))
	var r := RandomNumberGenerator.new()
	r.seed = 777
	for i in range(16):
		_rect(dd, r.randi_range(6, 54), r.randi_range(50, 88), r.randi_range(4, 16), 1, Color8(184, 186, 204))
	# someone dragged a hand down it, once
	for k in range(5):
		_rect(dd, 17 + k * 6, 74 - k, 2, 9 + k * 2, Color8(196, 198, 214))
	_save(dd, d + "false_door_perceived.png")

	# the opening that was always there
	var hp := _img(64, 96)
	_rect(hp, 0, 0, 64, 96, Color8(10, 13, 18))
	_hollow(hp, 0, 0, 64, 96, Color8(42, 50, 63))
	_hollow(hp, 4, 4, 56, 88, Color8(28, 34, 44))
	for y in range(10, 90):
		var t := float(y - 10) / 80.0
		_rect(hp, 8, y, 48, 1, Color8(12, 15, 20).lerp(Color8(2, 3, 4), t))
	_rect(hp, 8, 8, 48, 1, Color8(122, 130, 148))
	_rect(hp, 8, 9, 48, 1, Color8(70, 78, 94))
	_rect(hp, 14, 20, 1, 60, Color8(22, 27, 36))
	_rect(hp, 49, 20, 1, 60, Color8(22, 27, 36))
	_blob(hp, 32, 62, 3, 2, Color(0.62, 0.64, 0.72, 0.10))
	_save(hp, d + "hidden_passage_true.png")


## Darker, wetter, dirtier true-world stone.
func _gen_tileset_true_dark() -> void:
	var t := _img(256, 256)
	for tx in range(16):
		for ty in range(16):
			_tile_true_dark(t, tx * 16, ty * 16, tx, ty)
	_save(t, "res://assets/tilesets/tileset_true.png")


func _tile_true_dark(im: Image, x: int, y: int, tx: int, ty: int) -> void:
	# dark plate lit from above, printed with fluorescent ink
	for i in range(16):
		var t := float(i) / 15.0
		_rect(im, x, y + i, 16, 1, Color8(28, 16, 48).lerp(C_TG, t * 0.45))
	# panel bevel: magenta top lip, deep bottom shadow, lit left edge
	_rect(im, x, y, 16, 1, Color8(198, 24, 108))
	_rect(im, x, y + 1, 16, 1, Color8(74, 32, 128))
	_rect(im, x, y, 1, 16, Color8(108, 56, 168))
	_rect(im, x + 15, y, 1, 16, Color8(9, 5, 16))
	_rect(im, x, y + 15, 16, 1, Color8(6, 3, 11))
	_rect(im, x, y + 14, 16, 1, Color8(16, 9, 28))
	# corner rivets — the plate is bolted down
	_px(im, x + 2, y + 2, Color8(146, 124, 190))
	_px(im, x + 3, y + 3, Color8(46, 26, 80))
	_px(im, x + 13, y + 2, Color8(96, 70, 150))
	_px(im, x + 2, y + 13, Color8(70, 46, 120))
	_px(im, x + 13, y + 13, Color8(52, 32, 92))
	# grime, bleeding ink and cracks, deterministic per tile
	var h := (tx * 5 + ty * 11) % 9
	var r := RandomNumberGenerator.new()
	r.seed = 90 + tx * 17 + ty
	if h < 5:
		for i in range(3 + h):
			var gx := x + r.randi_range(2, 13)
			var gy := y + r.randi_range(4, 14)
			_px(im, gx, gy, Color8(9, 5, 16))
			_px(im, gx, gy + 1, Color8(16, 9, 28))
	if h == 5:
		_rect(im, x + 5, y + 3, 2, 11, _fade(C_TR, 0.70))
		_rect(im, x + 6, y + 12, 1, 3, _fade(C_TR, 0.40))
	elif h == 7:
		_rect(im, x + 9, y + 4, 2, 8, _fade(C_TR, 0.55))
	if h == 2:
		# a hairline crack, like something was dragged along the wall
		var cx := x + r.randi_range(3, 12)
		var cy := y + 3
		for k in range(10):
			_px(im, cx, cy, Color8(11, 6, 20))
			cx += r.randi_range(-1, 1)
			cy += 1
	# strip lighting, with a soft glow so it reads as emissive
	if ty == 0:
		_rect(im, x + 1, y + 1, 14, 1, C_INT)
		_rect(im, x + 1, y + 2, 14, 1, _fade(C_INT, 0.35))
		_rect(im, x + 1, y + 3, 14, 1, _fade(C_INT, 0.12))
	elif (tx + ty) % 5 == 0:
		_rect(im, x + 2, y + 5, 4, 4, _fade(C_TA, 0.10))
		_rect(im, x + 3, y + 6, 2, 2, _fade(C_TA, 0.85))
		_rect(im, x + 11, y + 10, 1, 1, _fade(C_TA, 0.60))
	# occasional structural rib, so the wall has architecture
	if tx == 3 and ty == 2:
		_rect(im, x + 7, y, 2, 16, Color8(52, 32, 92))
		_rect(im, x + 7, y, 1, 16, Color8(146, 124, 190))
	if tx == 8 and ty == 5:
		_rect(im, x, y + 8, 16, 2, Color8(52, 32, 92))
		_rect(im, x, y + 7, 16, 1, Color8(146, 124, 190))


# ────────────────────────────── helpers ──────────────────────────────

func _img(w: int, h: int) -> Image:
	var im := Image.create(w, h, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	return im


func _save(im: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := im.save_png(path)
	if err != OK:
		push_error("FAILED to save %s (%d)" % [path, err])


func _px(im: Image, x: int, y: int, c: Color) -> void:
	var w := im.get_width()
	var h := im.get_height()
	if x < 0 or y < 0 or x >= w or y >= h or c.a <= 0.0:
		return
	if c.a >= 1.0:
		im.set_pixel(x, y, c)
		return
	var d := im.get_pixel(x, y)
	var a := c.a + d.a * (1.0 - c.a)
	if a <= 0.0:
		im.set_pixel(x, y, Color(0, 0, 0, 0))
		return
	var rgb := (Color(c.r, c.g, c.b) * c.a + Color(d.r, d.g, d.b) * d.a * (1.0 - c.a)) / a
	im.set_pixel(x, y, Color(rgb.r, rgb.g, rgb.b, a))


func _rect(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for i in range(x, x + w):
		for j in range(y, y + h):
			_px(im, i, j, c)


func _hollow(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	_rect(im, x, y, w, 1, c)
	_rect(im, x, y + h - 1, w, 1, c)
	_rect(im, x, y, 1, h, c)
	_rect(im, x + w - 1, y, 1, h, c)


func _circle(im: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for i in range(-r, r + 1):
		for j in range(-r, r + 1):
			if i * i + j * j <= r * r:
				_px(im, cx + i, cy + j, c)


func _blob(im: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for i in range(-rx, rx + 1):
		for j in range(-ry, ry + 1):
			if float(i * i) / float(rx * rx + 1) + float(j * j) / float(ry * ry + 1) <= 1.0:
				_px(im, cx + i, cy + j, c)


func _fade(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * clampf(a, 0.0, 1.0))


func _clear_px(im: Image, x: int, y: int) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, Color(0, 0, 0, 0))


## Ring of `col` deposited just outside every opaque pixel inside the cell.
func _rim(im: Image, ox: int, w: int, h: int, c: Color, a: float = 0.5) -> void:
	var targets: Array = []
	for x in range(w):
		for y in range(h):
			if im.get_pixel(ox + x, y).a > 0.5:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var dd: Vector2i = d
					var nx: int = x + dd.x
					var ny: int = y + dd.y
					if nx >= 0 and nx < w and ny >= 0 and ny < h:
						if im.get_pixel(ox + nx, ny).a < 0.5:
							targets.append(Vector2i(ox + nx, ny))
	for t in targets:
		if im.get_pixel(t.x, t.y).a < 0.5:
			im.set_pixel(t.x, t.y, Color(c.r, c.g, c.b, a))


func _stamp_text(im: Image, x: int, y: int, text: String, col: Color, scratchy: bool = false) -> void:
	var cx := x
	for i in range(text.length()):
		var ch := text.substr(i, 1).to_upper()
		var glyph: Array = FONT5.get(ch, FONT5[" "])
		for row in range(5):
			var line: String = glyph[row]
			for ci in range(3):
				if line[ci] == "#":
					if scratchy and randf() < 0.25:
						continue
					_px(im, cx + ci, y + row, col)
		cx += 4


func _stamp_text_big(im: Image, x: int, y: int, text: String, col: Color, scale: int) -> int:
	var cx := x
	for i in range(text.length()):
		var ch := text.substr(i, 1).to_upper()
		var glyph: Array = FONT5.get(ch, FONT5[" "])
		for row in range(5):
			var line: String = glyph[row]
			for ci in range(3):
				if line[ci] == "#":
					_rect(im, cx + ci * scale, y + row * scale, scale, scale, col)
		cx += 4 * scale
	return cx


# ────────────────────────────── PLAYER ──────────────────────────────

func _gen_player() -> void:
	var idle := [{"bob": 0}, {"bob": -1}, {"bob": 0}, {"bob": 0}]

	var run: Array = []
	for i in range(6):
		var t := float(i) / 6.0 * TAU
		run.append({
			"leg_l_dx": int(round(sin(t) * 3.0)),
			"leg_r_dx": int(round(-sin(t) * 3.0)),
			"arm_l_dy": int(round(-sin(t) * 2.0)),
			"arm_r_dy": int(round(sin(t) * 2.0)),
			"leg_l_dh": -2 if sin(t) > 0.3 else 0,
			"leg_r_dh": -2 if sin(t) < -0.3 else 0,
			"bob": -1 if (i == 1 or i == 4) else 0,
		})

	var jump := [{"crouch": 3}, {"stretch": 3}]
	var fall := [{"crouch": 4, "leg_l_dh": -4, "leg_r_dh": -4}, {"arms_out": true, "leg_l_dx": -2, "leg_r_dx": 2}]
	var land := [{"crouch": 5}, {"crouch": 2}, {"crouch": 0}]
	var shift := [{}, {}, {"ghost": true, "ghost_dx": -2}, {"ghost": true, "ghost_dx": 2}, {"alpha": 0.16}, {"ghost": true, "ghost_dx": -1}]
	var interact := [{"arm_reach": 1}, {"arm_reach": 3}, {"arm_reach": 4}, {"arm_reach": 1}]
	var hurt := [{"lean": -2}, {"flash": true}, {"lean": 2}]
	var death := [{"lean": 3}, {"lean": 5}, {"crouch": 6}, {"crouch": 12}, {"crouch": 14, "alpha": 0.6}, {"crouch": 16, "alpha": 0.25}]

	var anims := {
		"idle": idle, "run": run, "jump": jump, "fall": fall, "land": land,
		"shift": shift, "interact": interact, "hurt": hurt, "death": death,
	}
	for name in anims.keys():
		for per in [true, false]:
			_player_sheet(name, per, anims[name])


func _player_sheet(name: String, per: bool, poses: Array) -> void:
	var n := poses.size()
	var im := _img(32 * n, 48)
	for i in range(n):
		_draw_player(im, i * 32, per, poses[i])
	_save(im, "res://assets/player/player_%s_%s.png" % [name, "perceived" if per else "true"])


## Every colour the figure is made of. The silhouette — bone egg mask, black
## lenses, crown, indigo cloak — is identical in both worlds; only the scheme
## changes.
##
## The two branches are written out in full rather than derived from each other.
## The pale world is not the dark one with its lights turned off: it is paper and
## plum and rose and brass, the same materials as the tiles, the bridges and the
## spikes standing in it. The figure has to look like it was cut out of the room
## it is walking through, not like a photograph of the other room's figure.
func _player_palette(per: bool) -> Dictionary:
	var cloak := Color(0.188, 0.125, 0.337)
	var spire := Color(0.941, 0.078, 0.471)
	if per:
		# ── the pale world: paper, plum, rose, brass ──
		var plum := Color(0.451, 0.208, 0.310)
		var rose := Color(0.831, 0.294, 0.392)
		return {
			"mask": Color(0.949, 0.929, 0.953),
			"mask_dark": Color(0.855, 0.808, 0.898),
			"mask_lit": Color(0.988, 0.976, 0.960),
			"void": Color(0.129, 0.086, 0.196),
			"cloak": plum,
			"cloak_dark": plum.darkened(0.34),
			"trim": Color(0.902, 0.373, 0.451),
			"spire": rose,
			"spire_dark": rose.darkened(0.36),
			"gold": Color(0.855, 0.757, 0.545),
			"collar": Color(0.773, 0.749, 0.800),
			"leg": Color(0.208, 0.133, 0.227),
			"blade": Color(0.404, 0.376, 0.494),
		}
	# ── the dark world: near-black, magenta, and one cold highlight ──
	return {
		"mask": Color(0.902, 0.878, 0.855),
		"mask_dark": Color(0.663, 0.624, 0.659),
		"mask_lit": Color(0.988, 0.976, 0.945),
		"void": Color(0.047, 0.039, 0.086),
		"cloak": cloak,
		"cloak_dark": cloak.darkened(0.34),
		"trim": Color(0.941, 0.118, 0.510),
		"spire": spire,
		"spire_dark": spire.darkened(0.36),
		"gold": Color(0.941, 0.804, 0.431),
		"collar": Color(0.749, 0.714, 0.776),
		"leg": Color(0.063, 0.047, 0.102),
		"blade": Color(0.902, 0.929, 0.937),
	}


func _draw_player(im: Image, ox: int, per: bool, p: Dictionary) -> void:
	var alpha := float(p.get("alpha", 1.0))
	var flash := bool(p.get("flash", false))
	var pal := _player_palette(per)
	if flash:
		for key: String in pal.keys():
			pal[key] = Color.WHITE
	elif alpha < 1.0:
		for key: String in pal.keys():
			var c: Color = pal[key]
			pal[key] = Color(c.r, c.g, c.b, c.a * alpha)
	_draw_player_body(im, ox, pal, p)

	# outline + rim only while the figure is actually readable
	if alpha > 0.5 and not flash:
		_rim(im, ox, 32, 48, Color(0.043, 0.020, 0.078, 1.0), 1.0)
		# the pale copy gets no light rim any more: it is a negative now, so its
		# mask is the dark thing in the frame and a white halo around it would only
		# fight the black rim it already has

	# glitch double-image drawn last so it is not outlined
	if p.get("ghost", false):
		var ghost := pal.duplicate()
		for key: String in ghost.keys():
			var gc: Color = ghost[key]
			ghost[key] = Color(gc.r, gc.g, gc.b, gc.a * 0.32)
		_draw_player_body(im, ox + int(p.get("ghost_dx", 0)), ghost, p)


## One black almond lens, 3 px wide and 5 px tall, centred on (ex, ey).
func _draw_lens(im: Image, ex: int, ey: int, c: Color) -> void:
	_px(im, ex, ey - 2, c)
	_rect(im, ex - 1, ey - 1, 3, 3, c)
	_px(im, ex, ey + 2, c)


func _draw_player_body(im: Image, ox: int, pal: Dictionary, p: Dictionary) -> void:
	var lean := int(p.get("lean", 0))
	var bob := int(p.get("bob", 0))
	var crouch := int(p.get("crouch", 0))
	var stretch := int(p.get("stretch", 0))
	var cx := 16 + lean
	var feet_y := 47 + bob
	var leg_h: int = max(3, 13 - crouch + stretch)
	var torso_h: int = max(3, 13 - crouch + stretch)
	var leg_top: int = feet_y - leg_h
	var torso_top: int = leg_top - torso_h
	var head_top: int = torso_top - 13
	var mask: Color = pal["mask"]
	var mask_dark: Color = pal["mask_dark"]
	var void_c: Color = pal["void"]
	var cloak: Color = pal["cloak"]
	var cloak_dark: Color = pal["cloak_dark"]
	var trim: Color = pal["trim"]
	var spire: Color = pal["spire"]
	var spire_dark: Color = pal["spire_dark"]
	var leg_c: Color = pal["leg"]
	var arm_c: Color = pal["cloak_dark"]

	# legs first: the cloak hangs over the top of them. A shortened leg lifts its
	# FOOT and keeps its top where the hip is; shortening it at the top instead
	# leaves a hole under the cloak and the figure comes apart in mid-air, which
	# is exactly when the player is looking at it.
	var ll_dx := int(p.get("leg_l_dx", 0))
	var rl_dx := int(p.get("leg_r_dx", 0))
	var ll: int = max(2, leg_h + int(p.get("leg_l_dh", 0)))
	var rl: int = max(2, leg_h + int(p.get("leg_r_dh", 0)))
	_rect(im, ox + cx - 4 + ll_dx, leg_top, 3, ll, leg_c)
	_rect(im, ox + cx + 1 + rl_dx, leg_top, 3, rl, leg_c)
	_rect(im, ox + cx - 5 + ll_dx, leg_top + ll - 2, 4, 2, leg_c)
	_rect(im, ox + cx + rl_dx, leg_top + rl - 2, 4, 2, leg_c)

	# the cloak: a long tattered cape from the shoulders to a ragged hem, so the
	# figure reads as one dark shape over whatever the world is doing behind it
	var hem: int = mini(feet_y - 2, leg_top + 3)
	var cape_y: int = torso_top + 1
	if cape_y < hem:
		_rect(im, ox + cx - 4, cape_y, 8, hem - cape_y, cloak)
		_rect(im, ox + cx - 4, cape_y, 2, hem - cape_y, cloak_dark)
		var fl: int = maxi(cape_y, hem - 3)
		_rect(im, ox + cx - 5, fl, 1, hem - fl, cloak)
		_rect(im, ox + cx + 4, fl, 1, hem - fl, cloak_dark)
	_rect(im, ox + cx - 4, torso_top, 8, 1, pal["collar"])
	# torn tips, each with a thread of hot pink at the point
	var tips := [-4, -3, -1, 1, 2, 4]
	for i in range(tips.size()):
		var tx: int = cx + int(tips[i])
		var tl: int = 2 + (i % 2)
		_rect(im, ox + tx, hem, 1, tl, cloak)
		_px(im, ox + tx, hem + tl, trim)

	# arms — the shoulder stays attached and the arm gets shorter, so it never
	# floats away from the body
	if p.get("arms_out", false):
		_rect(im, ox + cx - 8, torso_top + 2, 4, 3, arm_c)
		_rect(im, ox + cx + 4, torso_top + 2, 4, 3, arm_c)
	elif p.has("arm_reach"):
		var r := int(p["arm_reach"])
		_rect(im, ox + cx - 7, torso_top + 1, 3, maxi(2, torso_h - 3), arm_c)
		_rect(im, ox + cx + 4, torso_top + 3, 3 + r, 3, arm_c)
		# the knife only comes out when the hand is reaching with it
		_rect(im, ox + cx + 7 + r, torso_top + 4, 4, 1, pal["blade"])
		_px(im, ox + cx + 11 + r, torso_top + 4, pal["blade"])
	else:
		var al: int = maxi(2, torso_h - 3 + int(p.get("arm_l_dy", 0)))
		var ar: int = maxi(2, torso_h - 3 + int(p.get("arm_r_dy", 0)))
		_rect(im, ox + cx - 7, torso_top + 1, 3, al, arm_c)
		_rect(im, ox + cx + 4, torso_top + 1, 3, ar, arm_c)

	# the mask: a bone egg, 13 rows, widest across the middle. Its eye lenses land
	# on rows head_top+5 .. head_top+9 — art rows 13..17 — which is exactly the
	# band the ending scene slices out for its two red eyes. This arithmetic is
	# load-bearing: change it and the ending's eyes drift off the mask.
	_rect(im, ox + cx - 3, head_top, 6, 1, mask)
	_rect(im, ox + cx - 4, head_top + 1, 8, 1, mask)
	_rect(im, ox + cx - 5, head_top + 2, 10, 10, mask)
	_rect(im, ox + cx - 4, head_top + 12, 8, 1, mask)
	_rect(im, ox + cx - 5, head_top + 2, 2, 10, mask_dark)
	_rect(im, ox + cx - 4, head_top + 1, 8, 1, pal["mask_lit"])
	_px(im, ox + cx + 4, head_top + 2, pal["mask_lit"])
	_draw_lens(im, ox + cx - 3, head_top + 7, void_c)
	_draw_lens(im, ox + cx + 3, head_top + 7, void_c)
	# the mask's own small wounds: a gold fleck on the brow, a pink chip below
	_rect(im, ox + cx - 1, head_top + 3, 2, 1, pal["gold"])
	_px(im, ox + cx + 3, head_top + 11, trim)
	_px(im, ox + cx + 4, head_top + 12, trim)

	# the crown, as tall as the frame allows: in mid-air the head is already near
	# the top edge, so the crown compresses rather than being clipped away
	var spire_h: int = mini(7, maxi(0, head_top))
	var tab := [7, 5, 4, 3, 2, 1, 1]
	for k in range(spire_h):
		var w: int = int(tab[int(k * 6.0 / float(maxi(1, spire_h - 1)))])
		var sy: int = head_top - spire_h + k
		var half: int = (w - 1) >> 1
		_rect(im, ox + cx - half, sy, w, 1, spire)
		if w >= 3:
			_px(im, ox + cx + half, sy, spire_dark)


# ────────────────────────────── PATROL ENEMY ──────────────────────────────

func _gen_patrol() -> void:
	_patrol_sheet("idle", 4, [{"dy": 0}, {"dy": -1}, {"dy": 0}, {"dy": 1}])
	_patrol_sheet("move", 6, [
		{"legs": [0, 1, 0, 1], "dy": 0}, {"legs": [1, 0, 1, 0], "dy": -1},
		{"legs": [0, 1, 0, 1], "dy": 0}, {"legs": [1, 0, 1, 0], "dy": 0},
		{"legs": [0, 1, 0, 1], "dy": -1}, {"legs": [1, 0, 1, 0], "dy": 0},
	])
	_patrol_sheet("attack", 5, [
		{"rear": 0.2}, {"rear": 0.6}, {"rear": 0.8}, {"rear": 0.4, "dx": 4}, {"rear": 0.0, "dx": 7},
	])
	_patrol_sheet("hurt", 2, [{"flash": true}, {}])
	_patrol_sheet("death", 6, [
		{"squash": 1.0}, {"squash": 0.7}, {"squash": 0.4, "spark": 3},
		{"squash": 0.2, "spark": 5}, {"spark": 6}, {"spark": 6, "alpha": 0.3},
	])


func _patrol_sheet(name: String, n: int, poses: Array) -> void:
	var im := _img(32 * n, 32)
	for i in range(n):
		_draw_patrol(im, i * 32, poses[i])
	_save(im, "res://assets/enemies/patrol/patrol_%s.png" % name)


func _draw_patrol(im: Image, ox: int, p: Dictionary) -> void:
	var body := C_TD
	var shade := C_TG
	var eye := C_HAZ
	var alpha := float(p.get("alpha", 1.0))
	if p.get("flash", false):
		body = Color.WHITE
		shade = Color.WHITE
		eye = Color.WHITE
	if p.has("spark"):
		var sc := int(p["spark"])
		for i in range(sc):
			var sx := ox + 6 + (i * 5 + 3) % 22
			var sy := 4 + (i * 7) % 12
			_px(im, sx, sy, _fade(C_INT, alpha))
			_px(im, sx + 1, sy, _fade(C_HAZ, alpha))
	body = _fade(body, alpha)
	shade = _fade(shade, alpha)
	eye = _fade(eye, alpha)
	var dx := int(p.get("dx", 0))
	var squash := float(p.get("squash", 1.0))
	var shrink := 0.35 + 0.65 * squash
	var bw := int(round(20 * shrink))
	var bh: int = max(2, int(round(9.0 * shrink)))
	var bx := ox + 6 + dx + int(round((20 - bw) * 0.5))
	var by := 18 + int(p.get("dy", 0)) + int(round((9 - bh) * 0.5))
	_rect(im, bx, by, bw, bh, body)
	_rect(im, bx, by + bh - 2, bw, 2, shade)
	_clear_px(im, bx, by)
	_clear_px(im, bx + bw - 1, by)
	var rear := float(p.get("rear", 0.0))
	var hx := bx + bw - 8
	var hy := by - 3 - int(round(rear * 6.0))
	_rect(im, hx, hy, 9, 6, body)
	_rect(im, hx, hy + 4, 9, 2, shade)
	_px(im, hx + 5, hy + 3, eye)
	_px(im, hx + 6, hy + 3, eye)
	_px(im, hx + 5, hy + 2, _fade(Color.WHITE, alpha * 0.6))
	var legs: Array = p.get("legs", [0, 0, 0, 0])
	if squash > 0.5:
		for k in range(4):
			_rect(im, bx + 3 + k * 4, by + bh - 1, 2, 3 + int(legs[k]), shade)
	if alpha > 0.5:
		_rim(im, ox, 32, 32, _fade(Color8(8, 11, 16), alpha), 1.0)


# ────────────────────────────── REALITY ENEMY ──────────────────────────────

func _gen_reality_enemy() -> void:
	var idle := [{"bob": 0}, {"bob": -1}, {"bob": 0}, {"bob": 1}]
	var move: Array = []
	for i in range(6):
		var t := float(i) / 6.0 * TAU
		move.append({"arm": int(round(sin(t) * 3.0)), "leg": int(round(-sin(t) * 2.0)), "bob": -1 if i % 3 == 0 else 0})
	var attack := [{"lean": 1}, {"lean": 2, "arm_out": true}, {"lean": 3, "arm_out": true}, {"lean": 4, "arm_out": true}, {"lean": 2}]
	var hurt := [{"flash": true}, {}]
	var death := [{"lean": 2}, {"crouch": 4}, {"crouch": 9}, {"crouch": 14, "alpha": 0.6}, {"crouch": 18, "alpha": 0.3}, {"alpha": 0.0}]
	var anims := {"idle": idle, "move": move, "attack": attack, "hurt": hurt, "death": death}
	for name in anims.keys():
		for per in [true, false]:
			_reality_sheet(name, per, anims[name])


func _reality_sheet(name: String, per: bool, poses: Array) -> void:
	var n := poses.size()
	var im := _img(32 * n, 40)
	for i in range(n):
		_draw_reality_enemy(im, i * 32, per, poses[i])
	_save(im, "res://assets/enemies/reality_enemy/%s_%s.png" % [name, "perceived" if per else "true"])


func _draw_reality_enemy(im: Image, ox: int, per: bool, p: Dictionary) -> void:
	var alpha := float(p.get("alpha", 1.0))
	var flash := bool(p.get("flash", false))
	if per:
		var body: Color = C_PP
		var shade: Color = C_PPS
		var face: Color = C_VOID
		var eye: Color = Color8(240, 240, 252)
		if flash:
			body = Color.WHITE
			shade = Color.WHITE
			face = Color.WHITE
			eye = Color.WHITE
		body = _fade(body, alpha)
		shade = _fade(shade, alpha)
		face = _fade(face, alpha)
		var lean := int(p.get("lean", 0))
		var bob := int(p.get("bob", 0))
		var crouch := int(p.get("crouch", 0))
		var cx := 16 + lean
		var feet := 38 + bob
		var leg_h: int = max(2, 12 - crouch)
		var torso_h: int = max(2, 12 - crouch)
		var leg_top := feet - leg_h
		var torso_top := leg_top - torso_h
		var head_top := torso_top - 9
		_circle(im, ox + cx, head_top + 4, 4, body)
		_rect(im, ox + cx - 2, head_top + 3, 4, 3, face)
		_px(im, ox + cx - 1, head_top + 4, eye)
		_px(im, ox + cx + 2, head_top + 4, eye)
		_rect(im, ox + cx - 2, torso_top, 4, torso_h, body)
		_rect(im, ox + cx - 2, torso_top, 1, torso_h, shade)
		_rect(im, ox + cx - 3, leg_top, 2, leg_h, body)
		_rect(im, ox + cx + 1, leg_top, 2, leg_h, body)
		var arm := int(p.get("arm", 0))
		if p.get("arm_out", false):
			_rect(im, ox + cx + 2, torso_top + 2, 8 - lean, 2, body)
			_rect(im, ox + cx - 9, torso_top + 2, 7, 2, body)
		else:
			_rect(im, ox + cx - 5 + arm, torso_top + 1, 2, 16, body)
			_rect(im, ox + cx + 3 - arm, torso_top + 1, 2, 16, body)
		if alpha > 0.5:
			_rim(im, ox, 32, 40, _fade(C_PPO, 1.0), 1.0)
			_rim(im, ox, 32, 40, Color(1, 1, 1, 0.3), 1.0)
	else:
		var body: Color = C_TD
		var eye := C_TA
		if flash:
			body = Color.WHITE
			eye = Color.WHITE
		body = _fade(body, alpha)
		eye = _fade(eye, alpha)
		var crouch := int(p.get("crouch", 0))
		var lean := int(p.get("lean", 0))
		var bw: int = max(4, 14 - crouch / 2)
		var bh: int = max(3, 8 - crouch / 3)
		var bx := ox + 9 + lean
		var by := 34 - bh - crouch / 2
		_circle(im, bx + bw / 2, by + bh / 2, maxi(2, bh / 2 + 1), body)
		_rect(im, bx, by + 1, bw, bh, body)
		for k in range(3):
			_rect(im, bx + 2 + k * 4, by + bh, 1, 4, body)
			_rect(im, bx + 3 + k * 4, by + bh, 1, 4, body)
		_px(im, bx + bw - 2, by + 2, eye)
		_px(im, bx + bw - 1, by + 2, eye)
		_px(im, bx + bw - 2, by + 3, eye)
		if alpha > 0.5:
			_rim(im, ox, 32, 40, _fade(C_VOID, 1.0), 1.0)


# ────────────────────────────── TILESETS ──────────────────────────────

func _gen_tilesets() -> void:
	var p := _img(256, 256)
	for tx in range(16):
		for ty in range(16):
			_tile_pale_white(p, tx * 16, ty * 16, tx, ty)
	_tile_mirror(p, 12 * 16, 3 * 16)
	_tile_fragment(p, 5 * 16, 7 * 16)
	_tile_fragment(p, 9 * 16, 11 * 16)
	_tile_stain(p, 2 * 16, 9 * 16)
	_save(p, "res://assets/tilesets/tileset_perceived.png")

	var t := _img(256, 256)
	for tx in range(16):
		for ty in range(16):
			_tile_true(t, tx * 16, ty * 16, tx, ty)
	_save(t, "res://assets/tilesets/tileset_true.png")


## The pale world, taken all the way to white: no grey grout, no cold shadow —
## only white plates and the faintest of seams, so a white room stays white and
## its geometry reads from light rather than from dark lines.
## Regenerate with load("res://tools/generate_placeholder_art.gd").new()._gen_pale_tileset_white()
func _gen_pale_tileset_white() -> void:
	var im := _img(256, 256)
	for tx in range(16):
		for ty in range(16):
			_tile_pale_white(im, tx * 16, ty * 16, tx, ty)
	# the same handful of wrongness tiles the full pass stamps in, kept in step, so
	# regenerating the pale world on its own cannot quietly drop them
	_tile_mirror(im, 12 * 16, 3 * 16)
	_tile_fragment(im, 5 * 16, 7 * 16)
	_tile_fragment(im, 9 * 16, 11 * 16)
	_tile_stain(im, 2 * 16, 9 * 16)
	_save(im, "res://assets/tilesets/tileset_perceived.png")


## One pale plate: a single paper tone, a lit top edge, the faintest of seams —
## and nothing else on it.
##
## A collage pass once gave every tile a torn deckle edge, a halftone dot grid, a
## line of newsprint and a gradient, which at 2x turned every wall into a loud
## patchwork grid: the tiling started reading as breakage and the room stopped
## being a room and became a texture. A wall is a surface, not a picture. It gets
## one tone and then it gets out of the way of the figure standing in front of it.
##
## The seams are still here at roughly a five-level difference, because a wall
## should read as plates rather than as one flat sheet — but that is all the
## contrast a pale room needs. Its geometry comes from light, never from dark lines.
func _tile_pale_white(im: Image, x: int, y: int, tx: int, ty: int) -> void:
	var base := Color(0.949, 0.929, 0.953)
	var foot := Color(0.922, 0.894, 0.945)
	for i in range(16):
		var t := float(i) / 15.0
		_rect(im, x, y + i, 16, 1, base.lerp(foot, t * 0.5))
	# the faintest of seams, so a wall still reads as stacked plates
	_rect(im, x, y + 15, 16, 1, _fade(Color(0.855, 0.808, 0.898), 0.26))
	_rect(im, x + 15, y, 1, 16, _fade(Color(0.855, 0.808, 0.898), 0.18))
	# a lit top edge, so a horizontal run of these still reads as a ledge
	_rect(im, x, y, 16, 1, Color(1.0, 0.996, 1.0))
	_rect(im, x, y + 1, 16, 1, Color(1, 1, 1, 0.22))


func _tile_perceived(im: Image, x: int, y: int, tx: int, ty: int) -> void:
	# base plate, lit softly from above so the wall reads with real depth
	for i in range(16):
		var t := float(i) / 15.0
		_rect(im, x, y + i, 16, 1, C_PW.lerp(C_PA, t * 0.30))
	# a recessed grout channel around every plate — this is what makes it read as tiling
	_rect(im, x, y + 15, 16, 1, _fade(C_PC, 0.95))
	_rect(im, x, y + 14, 16, 1, _fade(C_PG, 0.55))
	_rect(im, x + 15, y, 1, 16, _fade(C_PC, 0.70))
	_rect(im, x + 14, y, 1, 16, _fade(C_PG, 0.40))
	_rect(im, x, y, 1, 16, _fade(C_PG, 0.50))
	# bevel highlight catching the light along the top and left
	_rect(im, x + 1, y, 14, 1, Color(1, 1, 1, 0.95))
	_rect(im, x + 1, y + 1, 14, 1, Color(1, 1, 1, 0.30))
	_rect(im, x + 1, y + 1, 1, 13, Color(1, 1, 1, 0.45))
	# deterministic wrongness per tile
	var h := (tx * 7 + ty * 13) % 13
	if h == 3 or h == 8:
		_crack(im, x, y, tx, ty, _fade(C_PC, 0.90))
	elif h == 6:
		_crack(im, x, y, tx, ty, _fade(C_PC, 0.45))
	elif h == 9:
		# a chipped corner
		_rect(im, x + 11, y + 11, 4, 4, _fade(C_PC, 0.30))
		_px(im, x + 14, y + 14, _fade(C_PC, 0.55))
	elif h == 11:
		# a faint smear that reads as a hand that was never there
		_rect(im, x + 3, y + 6, 10, 1, _fade(C_PG, 0.45))
		_rect(im, x + 5, y + 8, 7, 1, _fade(C_PG, 0.30))
	# a rare vertical panel seam breaks the grid so the wall is not a flat checkerboard
	if tx % 8 == 4:
		_rect(im, x + 7, y + 2, 1, 13, _fade(C_PG, 0.45))
		_rect(im, x + 8, y + 2, 1, 13, Color(1, 1, 1, 0.30))


func _crack(im: Image, x: int, y: int, tx: int, ty: int, col: Color) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 500 + tx * 31 + ty
	var cx := x + r.randi_range(3, 12)
	var cy := y + r.randi_range(2, 6)
	for i in range(9):
		_px(im, cx, cy, col)
		cx += r.randi_range(-1, 1)
		cy += 1


func _tile_mirror(im: Image, x: int, y: int) -> void:
	_rect(im, x, y, 16, 16, C_PW)
	_rect(im, x + 2, y + 6, 6, 2, _fade(C_PG, 0.9))
	_rect(im, x + 2, y + 9, 10, 2, _fade(C_PG, 0.7))
	_rect(im, x + 11, y + 4, 3, 3, _fade(C_PC, 0.8))
	_rect(im, x + 3, y + 3, 3, 3, _fade(C_PC, 0.5))


func _tile_fragment(im: Image, x: int, y: int) -> void:
	_rect(im, x, y, 16, 16, C_PW)
	_rect(im, x + 4, y + 4, 6, 5, C_PW)
	_hollow(im, x + 4, y + 4, 6, 5, _fade(C_PC, 0.9))
	_rect(im, x + 11, y + 10, 3, 3, Color(1, 1, 1, 0.85))


func _tile_stain(im: Image, x: int, y: int) -> void:
	_rect(im, x, y, 16, 16, C_PW)
	_blob(im, x + 7, y + 9, 5, 4, _fade(C_PG, 0.35))
	_blob(im, x + 7, y + 9, 3, 2, _fade(C_PC, 0.35))
	# a smear that reads as a hand that was never there
	_rect(im, x + 5, y + 4, 2, 3, _fade(C_PC, 0.55))
	_rect(im, x + 8, y + 3, 2, 4, _fade(C_PC, 0.55))
	_rect(im, x + 11, y + 4, 2, 3, _fade(C_PC, 0.55))


func _tile_true(im: Image, x: int, y: int, tx: int, ty: int) -> void:
	# The same room, printed on black with fluorescent ink.
	_rect(im, x, y, 16, 16, C_TD)
	_rect(im, x, y, 16, 2, Color8(74, 32, 128))
	_rect(im, x, y, 16, 1, _fade(C_TR, 0.85))
	_rect(im, x, y + 2, 16, 1, C_TG)
	_px(im, x + 2, y + 1, Color8(46, 20, 84))
	_px(im, x + 13, y + 1, Color8(46, 20, 84))
	# ink and grime
	var h := (tx * 5 + ty * 11) % 9
	if h < 4:
		var r := RandomNumberGenerator.new()
		r.seed = 90 + tx * 17 + ty
		for i in range(2 + h):
			_px(im, x + r.randi_range(2, 13), y + r.randi_range(4, 14), C_TG)
			_px(im, x + r.randi_range(2, 13), y + r.randi_range(4, 14), Color8(62, 22, 112))
	if h == 5:
		# magenta bleeding down the plate
		_rect(im, x + 5, y + 3, 2, 9, _fade(C_TR, 0.8))
		_rect(im, x + 6, y + 12, 1, 3, _fade(C_TR, 0.55))
	elif h == 7:
		_rect(im, x + 9, y + 4, 2, 6, _fade(C_TR, 0.6))
	# strip lights
	if ty == 0:
		_rect(im, x + 1, y + 1, 14, 1, C_INT)
	elif (tx + ty) % 5 == 0:
		_rect(im, x + 3, y + 6, 2, 2, _fade(C_TA, 0.9))
		_rect(im, x + 11, y + 10, 1, 1, _fade(C_TA, 0.65))
	if tx == 3 and ty == 2:
		_rect(im, x + 7, y, 2, 16, Color8(46, 20, 84))
		_rect(im, x + 7, y, 1, 16, _fade(C_TR, 0.7))
	if tx == 8 and ty == 5:
		_rect(im, x, y + 8, 16, 2, Color8(46, 20, 84))
		_rect(im, x, y + 7, 16, 1, _fade(C_TA, 0.55))


# ────────────────────────────── PROPS ──────────────────────────────

func _gen_props() -> void:
	var d := "res://assets/props/"

	# The reference bridge: the same heavy slab the platforms are cut from. The
	# whole 128px sheet is one bridge and not a tile, so the ends are capped in
	# teal — the thing you are about to trust your weight to should have an edge
	# you can actually see. The old bridge was a 66%-alpha white strip, which on a
	# paper floor was simply not there.
	var bslab := Color(0.451, 0.208, 0.310)
	var bslate := bslab.darkened(0.38)
	var bcap := Color(0.227, 0.412, 0.478)
	var btop := Color(0.902, 0.867, 0.800)
	var bp := _img(128, 16)
	_rect(bp, 0, 4, 128, 10, bslab)
	_rect(bp, 0, 11, 128, 3, bslate)
	_rect(bp, 0, 4, 128, 2, btop)
	_rect(bp, 0, 6, 128, 1, _fade(btop, 0.40))
	# plank seams, so a long bridge still reads as built rather than extruded
	for i in range(1, 8):
		_rect(bp, i * 16, 5, 1, 9, _fade(bslate, 0.45))
	_rect(bp, 0, 4, 3, 10, bcap)
	_rect(bp, 125, 4, 3, 10, bcap)
	_rect(bp, 3, 5, 122, 1, Color(1, 1, 1, 0.18))
	_hollow(bp, 0, 4, 128, 10, _fade(bslate, 0.85))
	_save(bp, d + "bridge_perceived.png")

	var br := _img(64, 16)
	var stumps := [6, 9, 4, 7]
	for i in range(4):
		var ox := i * 16
		var h: int = stumps[i]
		_rect(br, ox + 5, 16 - h, 5, h, C_TD)
		_rect(br, ox + 2, 15, 3, 1, C_TD)
		_px(br, ox + 10, 16 - h, C_STEEL)
		_rect(br, ox + 4, 12, 7, 1, C_TG)
		_rect(br, ox + 6, 16 - h, 1, 2, _fade(C_TR, 0.7))
	_save(br, d + "bridge_true_remnants.png")

	var cr := _img(32, 32)
	_rect(cr, 2, 2, 28, 28, C_PW)
	_hollow(cr, 2, 2, 28, 28, C_INT)
	_rect(cr, 4, 4, 24, 1, _fade(C_PG, 0.8))
	_hollow(cr, 8, 8, 16, 16, _fade(C_PG, 0.7))
	_rect(cr, 14, 14, 4, 6, _fade(C_PC, 0.5))
	_save(cr, d + "false_crate_perceived.png")

	var fs := _img(64, 16)
	for i in range(4):
		var ox := i * 16
		var press: int = [0, 2, 4, 0][i]
		_rect(fs, ox + 1, 8 + press, 14, 6, C_STEEL)
		_rect(fs, ox + 1, 8 + press, 14, 1, C_STEEL_HI)
		_hollow(fs, ox + 1, 8 + press, 14, 6, C_INT)
		if press > 0:
			_rect(fs, ox + 5, 10 + press, 6, 1, C_TA)
	_save(fs, d + "floor_switch_true.png")

	var dd := _img(64, 96)
	_rect(dd, 2, 2, 60, 92, C_PW)
	_hollow(dd, 2, 2, 60, 92, C_PG)
	_rect(dd, 6, 6, 52, 1, Color(1, 1, 1, 0.85))
	_circle(dd, 32, 46, 9, C_PC)
	_circle(dd, 32, 46, 6, C_PW)
	_rect(dd, 30, 46, 4, 8, C_PC)
	_rect(dd, 10, 70, 20, 1, _fade(C_PC, 0.4))
	_save(dd, d + "false_door_perceived.png")

	var hp := _img(64, 96)
	_rect(hp, 0, 0, 64, 96, C_TD)
	_rect(hp, 6, 8, 52, 88, C_TG)
	_rect(hp, 0, 0, 6, 96, C_STEEL)
	_rect(hp, 58, 0, 6, 96, C_STEEL)
	_rect(hp, 6, 8, 4, 4, C_TA)
	_circle(hp, 32, 52, 14, Color(4, 6, 9, 1.0))
	_save(hp, d + "hidden_passage_true.png")

	var sg := _img(128, 24)
	for i in range(4):
		var ox := i * 32
		_rect(sg, ox + 15, 12, 2, 12, C_STEEL)
		_rect(sg, ox + 4, 2, 24, 12, C_PW if i != 1 else C_TD)
		_hollow(sg, ox + 4, 2, 24, 12, C_INT if i != 1 else C_PA)
		var marks := (i == 2)
		for k in range(3):
			var mx := ox + 8 + k * 6
			if marks:
				mx = ox + 24 - k * 6
			_rect(sg, mx, 6, 3, 1, _fade(C_PC, 0.9))
			_rect(sg, mx, 9, 4, 1, _fade(C_PC, 0.6))
		if i == 3:
			_rect(sg, ox + 4, 2, 24, 12, C_PW)
			_hollow(sg, ox + 4, 2, 24, 12, C_INT)
			_stamp_text(sg, ox + 8, 4, "NO", _fade(C_PC, 0.8))
	_save(sg, d + "signs_atlas.png")

	# whispered wall marks — faint, scratchy, easy to miss
	var wm := _img(128, 16)
	var words := ["NOT REAL", "YOU ARE", "LOOK UP", "HELP"]
	for i in range(4):
		var ox := i * 32
		var w: String = words[i]
		_stamp_text(wm, ox + (32 - w.length() * 4) / 2, 6, w, _fade(C_PC, 0.9), true)
	_save(wm, d + "wall_marks.png")

	var sp := _img(64, 16)
	for i in range(4):
		var ox := i * 16
		_rect(sp, ox + 2, 4, 12, 9, C_STEEL)
		_hollow(sp, ox + 2, 4, 12, 9, C_INT)
		_rect(sp, ox + 5, 6 + i, 6, 2, C_TA if i == 3 else C_STEEL_HI)
	_save(sp, d + "switch_panel.png")

	var lv := _img(64, 32)
	for i in range(2):
		var ox := i * 32
		_rect(lv, ox + 12, 24, 8, 6, C_STEEL)
		_hollow(lv, ox + 12, 24, 8, 6, C_INT)
		if i == 0:
			_rect(lv, ox + 15, 8, 3, 17, C_STEEL_HI)
			_circle(lv, ox + 16, 8, 2, C_INT)
		else:
			_rect(lv, ox + 20, 12, 3, 13, C_STEEL_HI)
			_circle(lv, ox + 21, 12, 2, C_INT)
	_save(lv, d + "lever.png")

	var ck := _img(128, 48)
	for i in range(4):
		var ox := i * 32
		_rect(ck, ox + 12, 38, 8, 8, C_STEEL)
		_hollow(ck, ox + 12, 38, 8, 8, C_INT)
		_rect(ck, ox + 15, 14, 2, 26, C_STEEL_HI)
		for k in range(i + 1):
			_px(ck, ox + 16, 30 - k, C_TA)
		_circle(ck, ox + 16, 12, 3, C_TA if i >= 2 else _fade(C_TA, 0.35))
		_circle(ck, ox + 16, 12, 1, Color(1, 1, 1, 0.9))
	_save(ck, d + "checkpoint.png")

	for per in [true, false]:
		# The reference platform: a heavy slab with a lit stone top and capped
		# ends, so a platform reads as furniture and not just as a ledge.
		var slab: Color = Color(0.451, 0.208, 0.310) if per else Color(0.541, 0.106, 0.478)
		var slate: Color = slab.darkened(0.38)
		var cap: Color = Color(0.227, 0.412, 0.478) if per else C_TA
		var top: Color = Color(0.902, 0.867, 0.800) if per else C_INT
		var pl := _img(48, 16)
		_rect(pl, 0, 4, 48, 10, slab)
		_rect(pl, 0, 11, 48, 3, slate)
		_rect(pl, 0, 4, 48, 2, top)
		_rect(pl, 0, 6, 48, 1, _fade(top, 0.40))
		_rect(pl, 0, 4, 3, 10, cap)
		_rect(pl, 45, 4, 3, 10, cap)
		_rect(pl, 2, 5, 44, 1, Color(1, 1, 1, 0.18))
		_hollow(pl, 0, 4, 48, 10, _fade(slate, 0.85))
		_save(pl, d + ("platform_perceived.png" if per else "platform_true.png"))
		var mp := _img(48, 16)
		_rect(mp, 0, 4, 48, 10, slab)
		_rect(mp, 0, 11, 48, 3, slate)
		_rect(mp, 0, 4, 48, 2, top)
		_rect(mp, 0, 4, 3, 10, cap)
		_rect(mp, 45, 4, 3, 10, cap)
		_hollow(mp, 0, 4, 48, 10, _fade(slate, 0.85))
		# a lit centre block, so a moving platform is identifiable at a glance
		_rect(mp, 20, 7, 8, 6, slate)
		_rect(mp, 20, 7, 8, 1, cap)
		_save(mp, d + ("moving_platform_perceived.png" if per else "moving_platform_true.png"))

	for per in [true, false]:
		var hz := _img(128, 16)
		var col: Color = Color(0.784, 0.267, 0.376) if per else Color(0.980, 0.157, 0.588)
		for i in range(8):
			var ox := i * 16
			for k in range(4):
				var sxx := ox + 2 + k * 4
				for row in range(8):
					_rect(hz, sxx + row / 2, 8 + row, 4 - row / 2, 1, col)
			_px(hz, ox + 3, 10, Color(1, 1, 1, 0.8) if per else Color(1, 1, 1, 0.45))
		_save(hz, d + ("hazards_perceived.png" if per else "hazards_true.png"))

	var mc := _img(96, 32)
	for i in range(3):
		var ox := i * 32
		_rect(mc, ox + 4, 10, 24, 18, C_STEEL)
		_hollow(mc, ox + 4, 10, 24, 18, C_STEEL_HI)
		_rect(mc, ox + 12, 6, 8, 6, C_STEEL)
		var glow := 3 + i
		_circle(mc, ox + 16, 19, glow, _fade(C_TA, 0.45 + 0.2 * i))
		_circle(mc, ox + 16, 19, 2, C_TA)
	_save(mc, d + "mechanism_core.png")

	var dl := _img(48, 16)
	for i in range(3):
		var ox := i * 16
		_rect(dl, ox + 2, 4, 12, 10, C_STEEL)
		_hollow(dl, ox + 2, 4, 12, 10, C_INT)
		if i == 0:
			_circle(dl, ox + 8, 8, 3, C_HAZ)
		elif i == 1:
			_circle(dl, ox + 8, 8, 3, C_INT)
		else:
			_rect(dl, ox + 6, 4, 4, 6, C_TA)
	_save(dl, d + "door_lock.png")


# ────────────────────────────── BACKGROUNDS ──────────────────────────────

func _gen_backgrounds() -> void:
	var per := "res://assets/backgrounds/perceived/"
	var tro := "res://assets/backgrounds/true/"

	# sky_white.png is no longer generated here: both sky plates are authored
	# collage art (assets/generated/sky_paper_collage.png and sky_neon_collage.png)
	# and are copied into place. This writes a flat fallback instead of stamping
	# over them.
	var sk := _img(BG_W, BG_H)
	_gradient(sk, Color8(242, 236, 244), Color8(206, 186, 224))
	_edges(sk, Color8(178, 152, 206), 0.35)
	_save(sk, "res://assets/generated/sky_flat_pale.png")

	var hz := _img(BG_W, BG_H)
	for i in range(9):
		var cx := 20 + i * 74
		_fog_blob(hz, cx, 250 + (i % 3) * 22, 90, 34, Color(0.72, 0.72, 0.79, 0.20))
	_fog_blob(hz, 120, 300, 160, 40, Color(0.68, 0.68, 0.76, 0.16))
	_fog_blob(hz, 480, 296, 150, 36, Color(0.68, 0.68, 0.76, 0.16))
	_save(hz, per + "haze_far.png")

	var af := _img(BG_W, BG_H)
	_band(af, 300, Color(0.86, 0.86, 0.90, 0.45), 60, 150, 12, 1)
	_save(af, per + "architecture_far.png")

	var am := _img(BG_W, BG_H)
	_band(am, 336, Color(0.870, 0.870, 0.906, 0.92), 70, 180, 10, 2)
	_windows(am, 336, 70, 180, 10, 2, _fade(C_PC, 0.30))
	_save(am, per + "architecture_mid.png")

	var fg := _img(BG_W, BG_H)
	_figures(fg, 330, Color(0.36, 0.37, 0.44, 0.30), 4, 11)
	_save(fg, per + "figures_far.png")

	var fs := _img(BG_W, BG_H)
	_spindles(fs, 360, Color8(52, 55, 66), 14, 13)
	_save(fs, per + "foreground_silhouettes.png")

	# a sunset that has gone wrong: near-black overhead, a sick orange band at the
	# horizon, and darkness closing in again underneath
	var sn := _img(BG_W, BG_H)
	for y in range(BG_H):
		var t := float(y) / float(BG_H - 1)
		var col := Color8(10, 4, 20)
		if t < 0.34:
			col = Color8(12, 8, 14).lerp(Color8(48, 22, 26), t / 0.34)
		elif t < 0.52:
			col = Color8(48, 22, 26).lerp(Color8(142, 58, 30), (t - 0.34) / 0.18)
		elif t < 0.63:
			col = Color8(142, 58, 30).lerp(Color8(216, 108, 44), (t - 0.52) / 0.11)
		elif t < 0.72:
			col = Color8(216, 108, 44).lerp(Color8(122, 48, 26), (t - 0.63) / 0.09)
		else:
			col = Color8(122, 48, 26).lerp(Color8(18, 10, 12), (t - 0.72) / 0.28)
		_rect(sn, 0, y, BG_W, 1, col)
	# sky_normal.png is authored collage art too — never stamp over it
	_save(sn, "res://assets/generated/sky_flat_true.png")

	var ind := _img(BG_W, BG_H)
	_band(ind, 320, Color8(28, 35, 46), 60, 140, 13, 4)
	_cyan_lights(ind, 320, 60, 140, 13, 4)
	_smoke(ind, 320, 60, 140, 13, 4)
	_save(ind, tro + "industrial_far.png")

	var atm := _img(BG_W, BG_H)
	_band(atm, 352, C_TD, 70, 190, 11, 5)
	_cyan_lights(atm, 352, 70, 190, 11, 5)
	_windows(atm, 352, 70, 190, 11, 5, _fade(C_TA, 0.22))
	_save(atm, tro + "architecture_mid.png")

	var fm := _img(BG_W, BG_H)
	_spindles(fm, 360, Color8(20, 25, 33), 16, 6)
	for i in range(9):
		_px(fm, 24 + i * 70, 300 - (i % 3) * 12, C_TA)
	_save(fm, tro + "foreground_machinery.png")

	var fs2 := _img(BG_W, BG_H)
	_spindles(fs2, 360, Color8(9, 12, 17), 18, 7)
	_save(fs2, tro + "foreground_silhouettes.png")


func _gradient(im: Image, top: Color, bottom: Color) -> void:
	var h := im.get_height()
	for y in range(h):
		var t := float(y) / float(h - 1)
		_rect(im, 0, y, im.get_width(), 1, top.lerp(bottom, t))


func _edges(im: Image, col: Color, a: float) -> void:
	var w := im.get_width()
	var h := im.get_height()
	for y in range(h):
		var t := absf(float(y) / float(h - 1) - 0.5) * 2.0
		var f := a * t * t
		_rect(im, 0, y, 26, 1, _fade(col, f))
		_rect(im, w - 26, y, 26, 1, _fade(col, f))


func _glow(im: Image, base_y: int, col: Color, radius: int) -> void:
	for y in range(base_y - radius, base_y + 40):
		var t := clampf(1.0 - absf(float(y - base_y)) / float(radius), 0.0, 1.0)
		_rect(im, 0, y, im.get_width(), 1, _fade(col, t * t))


func _fog_blob(im: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	for i in range(-rx, rx + 1):
		for j in range(-ry, ry + 1):
			var d := float(i * i) / float(rx * rx + 1) + float(j * j) / float(ry * ry + 1)
			if d <= 1.0:
				_px(im, cx + i, cy + j, _fade(col, (1.0 - d) * 0.9))


func _band(im: Image, base_y: int, col: Color, min_h: int, max_h: int, count: int, seed_off: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 700 + seed_off
	var x := 8
	for i in range(count):
		var w := r.randi_range(24, 56)
		var h := r.randi_range(min_h, max_h)
		_rect(im, x, base_y - h, w, h, col)
		_rect(im, x, base_y - h, w, 1, _fade(col, 0.55))
		x += w + r.randi_range(10, 30)
		if x > im.get_width() - 24:
			break


func _windows(im: Image, base_y: int, min_h: int, max_h: int, count: int, seed_off: int, col: Color) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1300 + seed_off
	var x := 16
	for i in range(count):
		var w := r.randi_range(24, 56)
		var h := r.randi_range(min_h, max_h)
		for k in range(3):
			var wx := x + 5 + k * 8
			var wy := base_y - h + 8 + r.randi_range(0, maxi(1, h - 20))
			_rect(im, wx, wy, 4, 6, col)
		x += w + r.randi_range(10, 30)
		if x > im.get_width() - 24:
			break


func _cyan_lights(im: Image, base_y: int, min_h: int, max_h: int, count: int, seed_off: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 900 + seed_off
	var x := 14
	for i in range(count):
		var w := r.randi_range(24, 56)
		var h := r.randi_range(min_h, max_h)
		for k in range(3):
			_px(im, x + 4 + k * 6, base_y - h + 6 + r.randi_range(0, maxi(1, h - 10)), C_TA)
		x += w + r.randi_range(10, 30)
		if x > im.get_width() - 24:
			break


func _smoke(im: Image, base_y: int, min_h: int, max_h: int, count: int, seed_off: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1700 + seed_off
	var x := 20
	for i in range(count):
		var w := r.randi_range(24, 56)
		var h := r.randi_range(min_h, max_h)
		if i % 2 == 0:
			var sx := x + w / 2
			for k in range(14):
				_blob(im, sx + r.randi_range(-3, 3), base_y - h - 6 - k * 4, 5 + k / 3, 3, Color(0.16, 0.19, 0.24, 0.28))
		x += w + r.randi_range(10, 30)
		if x > im.get_width() - 24:
			break


func _figures(im: Image, base_y: int, col: Color, count: int, seed_off: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 2100 + seed_off
	var x := 40
	for i in range(count):
		var fh := r.randi_range(26, 40)
		var cx := x
		_rect(im, cx - 3, base_y - fh, 7, fh - 12, col)
		_blob(im, cx, base_y - fh - 2, 4, 4, col)
		_rect(im, cx - 4, base_y - 12, 3, 12, col)
		_rect(im, cx + 2, base_y - 12, 3, 12, col)
		x += r.randi_range(90, 170)
		if x > im.get_width() - 30:
			break


func _spindles(im: Image, base_y: int, col: Color, count: int, seed_off: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 2500 + seed_off
	var x := 4
	for i in range(count):
		var w := r.randi_range(6, 16)
		var h := r.randi_range(30, 90)
		_rect(im, x, base_y - h, w, h, col)
		if r.randf() < 0.4:
			_rect(im, x + w, base_y - h - 6, 2, 8, col)
		x += w + r.randi_range(24, 60)
		if x > im.get_width() - 12:
			break


# ────────────────────────────── EFFECTS ──────────────────────────────

func _gen_effects() -> void:
	var d := "res://assets/effects/"

	_puff_sheet(d + "shift_particles.png", Color(1, 1, 1), Color(0.31, 0.85, 0.88))
	_puff_sheet(d + "glitch_fragments.png", Color(1, 1, 1), Color(0.31, 0.85, 0.88))
	_puff_sheet(d + "jump_dust.png", Color8(150, 152, 168), Color8(196, 196, 208))
	_puff_sheet(d + "landing_dust.png", Color8(140, 142, 160), Color8(196, 196, 208))
	_puff_sheet(d + "sparks.png", C_INT, Color(1, 1, 1))

	_burst_sheet(d + "hit_effect.png", 4, 16, 16, Color(1, 1, 1), C_HAZ)
	_burst_sheet(d + "checkpoint_effect.png", 4, 16, 16, C_TA, Color(1, 1, 1))
	_burst_sheet(d + "enemy_death_effect.png", 6, 16, 16, C_TA, Color(1, 1, 1))
	_burst_sheet(d + "hurt_particles.png", 2, 16, 16, Color(1, 1, 1), C_HAZ)

	# ambient floating dust — 8 cells of tiny specks
	var dm := _img(64, 8)
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for i in range(8):
		var ox := i * 8
		for k in range(3):
			var px := ox + r.randi_range(0, 7)
			var py := r.randi_range(0, 7)
			_px(dm, px, py, Color(0.87, 0.87, 0.93, 0.5))
			if r.randf() < 0.4:
				_px(dm, px + 1, py, Color(0.75, 0.75, 0.82, 0.35))
	_save(dm, d + "dust_motes.png")

	# a pair of eyes in the dark that blink once — 4 frames of 16x16
	var ey := _img(64, 16)
	for f in range(4):
		var ox := f * 16
		var open_h: int = [2, 1, 0, 2][f]
		for side in [-4, 4]:
			var cxx: int = ox + 8 + side
			if open_h > 0:
				_blob(ey, cxx, 8, 3, open_h, Color(0.92, 0.92, 0.97, 0.85))
				_px(ey, cxx, 8, Color(0.31, 0.35, 0.44, 0.95))
			else:
				_rect(ey, cxx - 2, 8, 5, 1, Color(0.72, 0.72, 0.80, 0.7))
	_save(ey, d + "eyes_blink.png")

	var fw := _img(256, 64)
	for i in range(4):
		var ox := i * 64
		var rad := 14 + i * 5
		_fog_blob(fw, ox + 32, 32, rad, rad / 2, Color(1, 1, 1, 0.30))
	_save(fw, d + "fog_wisps.png")

	var eb := _img(16, 16)
	_rect(eb, 7, 0, 2, 16, _fade(C_TA, 0.9))
	_rect(eb, 6, 0, 4, 16, _fade(C_TA, 0.3))
	_px(eb, 7, 0, Color.WHITE)
	_px(eb, 8, 0, Color.WHITE)
	_save(eb, d + "energy_beam.png")


func _puff_sheet(path: String, colA: Color, colB: Color) -> void:
	var im := _img(64, 8)
	for i in range(8):
		var ox := i * 8
		var spread := 1 + i
		for k in range(4):
			var px := ox + 4 + (k - 2) * spread / 2
			var py := 4 + ((k % 2) * 2 - 1)
			_px(im, px, py, _fade(colA if k % 2 == 0 else colB, 0.9))
			_px(im, px, py + 1, _fade(colA if k % 2 == 1 else colB, 0.5))
	_save(im, path)


func _burst_sheet(path: String, n: int, cw: int, ch: int, colA: Color, colB: Color) -> void:
	var im := _img(cw * n, ch)
	for i in range(n):
		var ox := i * cw
		var r := 2 + i * 2
		_circle(im, ox + cw / 2, ch / 2, mini(r, cw / 2 - 1), _fade(colA, clampf(1.0 - i * 0.18, 0.0, 1.0)))
		if i >= 2:
			_circle(im, ox + cw / 2, ch / 2, maxi(1, r - 3), _fade(colB, 0.7))
	_save(im, path)


# ────────────────────────────── UI ──────────────────────────────

func _gen_ui() -> void:
	var d := "res://assets/ui/"

	# the wordmark itself, in the 3x5 face at 3x so it stays crisp
	var lg := _img(192, 32)
	var x0 := 30
	var y0 := 9
	var x1 := _stamp_text_big(lg, x0, y0, "FALSE", C_PW, 3)
	x1 = _stamp_text_big(lg, x1, y0, "//", C_TA, 3)
	x1 = _stamp_text_big(lg, x1, y0, "REAL", C_PW, 3)
	# a faint underline anchor
	_rect(lg, x0, 27, x1 - x0 - 12, 1, _fade(C_INT, 0.45))
	_save(lg, d + "false_real_logo.png")

	# 2 states: white PERCEIVED eye, cyan TRUE eye — outlined so it reads on pale
	var ri := _img(64, 16)
	_eye(ri, 16, 8, C_PW)
	_eye(ri, 48, 8, C_TA)
	_save(ri, d + "reality_indicator.png")

	var ob := _img(192, 16)
	_rect(ob, 0, 0, 192, 16, Color(0.06, 0.07, 0.1, 0.55))
	_hollow(ob, 0, 0, 192, 16, _fade(C_INT, 0.5))
	_save(ob, d + "objective_bar.png")

	var ip := _img(96, 16)
	_rect(ip, 0, 0, 96, 16, Color(0.06, 0.07, 0.1, 0.6))
	_hollow(ip, 0, 0, 96, 16, _fade(C_PA, 0.55))
	_rect(ip, 4, 3, 10, 10, _fade(C_INT, 0.8))
	_hollow(ip, 4, 3, 10, 10, C_TD)
	_save(ip, d + "interaction_prompt.png")

	var ki := _img(80, 16)
	for i in range(5):
		var ox := i * 16
		_rect(ki, ox + 3, 3, 10, 10, Color(0.1, 0.12, 0.16, 0.9))
		_hollow(ki, ox + 3, 3, 10, 10, _fade(C_PA, 0.85))
		if i < 4:
			_rect(ki, ox + 6, 7, 4, 2, C_PW)
		else:
			_rect(ki, ox + 5, 7, 3, 2, C_PW)
			_rect(ki, ox + 9, 7, 3, 2, C_PW)
	_save(ki, d + "key_icons.png")

	var cb := _img(192, 24)
	_rect(cb, 0, 0, 192, 24, Color(0.06, 0.07, 0.1, 0.6))
	_hollow(cb, 0, 0, 192, 24, _fade(C_TA, 0.6))
	_circle(cb, 12, 12, 4, C_TA)
	_save(cb, d + "checkpoint_banner.png")

	var mp := _img(160, 96)
	_rect(mp, 0, 0, 160, 96, Color(0.05, 0.06, 0.08, 0.94))
	_hollow(mp, 0, 0, 160, 96, _fade(C_PA, 0.7))
	_hollow(mp, 3, 3, 154, 90, _fade(C_INT, 0.45))
	_save(mp, d + "menu_panel.png")

	var mb := _img(288, 16)
	for i in range(3):
		var ox := i * 96
		var border: Color = C_PA if i == 0 else (C_INT if i == 1 else C_TA)
		var fill := Color(0.09, 0.1, 0.13, 0.9) if i != 1 else Color(0.14, 0.16, 0.2, 0.95)
		_rect(mb, ox, 0, 96, 16, fill)
		_hollow(mb, ox, 0, 96, 16, border)
	_save(mb, d + "menu_buttons.png")

	var cu := _img(32, 16)
	_arrow(cu, 2, 1, Color.WHITE)
	_arrow(cu, 18, 1, C_TA)
	_save(cu, d + "cursor.png")

	var cr := _img(256, 32)
	_rect(cr, 0, 0, 256, 32, Color(0.05, 0.06, 0.08, 0.9))
	_hollow(cr, 0, 0, 256, 32, _fade(C_PA, 0.7))
	_save(cr, d + "credits_panel.png")


func _eye(im: Image, cx: int, cy: int, col: Color) -> void:
	for x in range(-8, 9):
		var h := int(round(3.0 * (1.0 - absf(float(x)) / 9.0)))
		for y in range(-h, h + 1):
			_px(im, cx + x, cy + y, _fade(Color8(10, 12, 18), 0.75))
	_circle(im, cx, cy, 3, col)
	_circle(im, cx, cy, 1, Color8(12, 16, 22))


func _arrow(im: Image, x: int, y: int, col: Color) -> void:
	for row in range(11):
		_rect(im, x + 1, y + row, 1 + (10 - row) / 2, 1, col)
	_rect(im, x + 1, y, 1, 11, _fade(col, 0.6))


# ────────────────────────────── STORY ──────────────────────────────

func _gen_story() -> void:
	var d := "res://assets/story/"

	var aw := _img(BG_W, BG_H)
	aw.fill(C_PW)
	_blob(aw, 320, 300, 120, 30, _fade(C_PG, 0.35))
	_rect(aw, 306, 176, 20, 60, C_TD)
	_circle(aw, 316, 170, 7, C_TD)
	_save(aw, d + "awakening.png")

	var wr := _img(BG_W, BG_H)
	wr.fill(C_TD)
	for i in range(22):
		_rect(wr, 10 + i * 28, 120 + (i % 4) * 24, 16, 120 - (i % 4) * 24, C_STEEL)
	for i in range(34):
		_px(wr, 12 + i * 18, 130 + (i % 5) * 20, C_TA)
	_save(wr, d + "world_reveal.png")

	var pe := _img(64, 96)
	var tmp := _img(32, 48)
	_draw_player(tmp, 0, true, {"bob": 0, "alpha": 0.6})
	pe.blit_rect(tmp, Rect2i(0, 0, 32, 48), Vector2i(16, 24))
	_save(pe, d + "protagonist_echo.png")

	var ev := _img(BG_W, BG_H)
	ev.fill(Color8(5, 6, 9))
	_circle(ev, 320, 180, 3, Color(1, 1, 1, 0.9))
	_circle(ev, 320, 180, 1, Color.WHITE)
	_save(ev, d + "ending_void.png")

	var eg := _img(BG_W * 4, BG_H)
	for f in range(4):
		var ox := f * BG_W
		for y in range(BG_H):
			for x in range(BG_W):
				var col := Color8(9, 11, 16)
				var shift := int(round(sin(float(y) * 0.4 + f) * (f * 4.0)))
				if (x + shift) % maxi(4, 56 - f * 12) == 0:
					col = C_TA
				elif (x + y + f * 9) % maxi(3, 21 - f * 4) == 0:
					col = C_PW
				_px(eg, ox + x, y, col)
	_save(eg, d + "ending_glitch.png")

	var cb := _img(BG_W, BG_H)
	_gradient(cb, Color8(14, 17, 25), Color8(30, 35, 47))
	_spindles(cb, BG_H, Color8(9, 12, 18), 18, 3)
	for i in range(8):
		_px(cb, 40 + i * 78, 120 + (i % 2) * 20, C_TA)
	_save(cb, d + "credits_background.png")
