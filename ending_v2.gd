extends Node2D
## The ending — and the only scene in this game that talks.
##
## One room, cut down the middle by a seam that should not be there. On the left
## the world as it is; on the right the world as it was told. Two of you stand
## either side of it wearing the same face, and they walk — step for step, at the
## same instant, the way a reflection moves.
##
## What is left standing in the tear is neither of them. It is bigger than the
## room can hold, it has one eye of each world, and it is the part of the picture
## that was watching you play the whole time. It talks. It tells you what you
## were — a panel, a detail, a rendering, never the subject — and then it shows
## you what it is made of, which is the same thing you are, and the room stops
## pretending there is anything behind it.
##
## The last voice is not in the room at all.

const W := 640.0
const H := 360.0
const SEAM_X := 320.0
const FLOOR_Y := 296.0

## Who is speaking. The colour of the line is the only attribution there is.
const COL_PALE := Color(0.95, 0.97, 1.0, 1.0)
const COL_TRUE := Color(0.62, 0.90, 1.0, 1.0)
const COL_ROOM := Color(0.68, 0.71, 0.78, 1.0)
const COL_IT := Color(0.99, 0.87, 0.70, 1.0)
const COL_VOID := Color(0.86, 0.88, 0.93, 1.0)
const COL_GLOW := Color(0.66, 0.93, 1.0, 1.0)
const COL_EYE_PALE := Color(0.94, 0.97, 1.0, 1.0)
const COL_EYE_TRUE := Color(0.55, 0.94, 1.0, 1.0)

const WALL_TRUE := "res://assets/tilesets/tileset_true.png"
const WALL_PALE := "res://assets/tilesets/tileset_perceived.png"
const PLAYER_PALE := "res://assets/player/player_idle_perceived.png"
const PLAYER_TRUE := "res://assets/player/player_idle_true.png"

const EERIE_TEXT := preload("res://ui/eerie_text.gd")

## The player's own art: one 32x48 frame of the idle sheet, and where the eyes
## sit inside it — measured off the pixels rather than guessed at.
const FRAME_W := 32.0
const FRAME_H := 48.0
const EYE_LEFT_X := 13.0
const EYE_RIGHT_X := 19.0
const EYE_TOP_Y := 13.0
const EYE_BOTTOM_Y := 17.0

## Two of them standing apart, and the one they turn into.
const PAWN_SCALE := 2.2
const PAWN_GAP := 60.0
const MERGED_SCALE := 4.6

## What is said once there is nothing left to look at.
const VOID_LINES: Array[String] = [
	"NONE OF THIS WAS REAL.",
	"NOT THE ROOM. NOT THE SEAM. NOT EITHER OF YOU.",
	"YOU WERE PART OF A BIGGER PICTURE.",
	"A DETAIL IN IT. NEVER THE SUBJECT.",
	"YOU ARE MEANINGLESS.",
	"HAPPINESS WAS A LIGHT I HELD IN FRONT OF YOU.",
	"SO WERE YOU.",
	"AND SO IS THE ONE READING THIS.",
]

var _layer: CanvasLayer
var _glitch: Glitch
var _backdrop: ColorRect
var _walls: Array[TextureRect] = []
var _swap_left: TextureRect
var _swap_right: TextureRect
var _seam: ColorRect
var _glow: ColorRect
var _tear: ColorRect
var _true_pawn: Sprite2D
var _pale_pawn: Sprite2D
var _merged: Sprite2D
var _split_l: Sprite2D
var _split_r: Sprite2D
var _head: Sprite2D
var _eyes: Array[ColorRect] = []
var _void_eyes: Array[ColorRect] = []
var _dlg: EerieText
var _void_text: EerieText
var _black: ColorRect
var _flash: ColorRect
var _skippable: bool = false


func _ready() -> void:
	GameState.current_level = "ending"
	GameState.set_objective("")
	EventManager.hint_changed.emit("")
	AudioManager.play_music("music_broken")
	AudioManager.set_music_distortion(0.18)
	_build()
	_run()
	await get_tree().create_timer(2.6).timeout
	_skippable = true


## Nothing was ever explained; the player is allowed to leave anyway.
func _unhandled_input(event: InputEvent) -> void:
	if not _skippable:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		GameState.start_credits()


# ── the room ───────────────────────────────────────────────────────────────

func _build() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 0
	add_child(_layer)

	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.014, 0.016, 0.024, 1.0)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_backdrop)

	# the same room, twice: walls above the floor line, floor below it
	_wall(WALL_TRUE, Rect2(0.0, 0.0, SEAM_X, FLOOR_Y), Color(0.78, 0.81, 0.90))
	_wall(WALL_PALE, Rect2(SEAM_X, 0.0, W - SEAM_X, FLOOR_Y), Color(0.97, 0.975, 1.0))
	_wall(WALL_TRUE, Rect2(0.0, FLOOR_Y, SEAM_X, H - FLOOR_Y), Color(1.10, 1.16, 1.30))
	_wall(WALL_PALE, Rect2(SEAM_X, FLOOR_Y, W - SEAM_X, H - FLOOR_Y), Color(0.86, 0.87, 0.90))

	# the seam itself: a hard white line with a soft cold halo
	_glow = ColorRect.new()
	_glow.color = Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, 0.0)
	_glow.position = Vector2(SEAM_X - 5.0, 0.0)
	_glow.size = Vector2(10.0, H)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_glow)

	_seam = ColorRect.new()
	_seam.color = Color(0.88, 0.97, 1.0, 0.0)
	_seam.position = Vector2(SEAM_X - 1.0, 0.0)
	_seam.size = Vector2(2.0, H)
	_seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_seam)

	# each half of the room wearing the other half's skin — held back until the
	# one moment where the lie is worth showing
	_swap_left = _wall(WALL_PALE, Rect2(0.0, 0.0, SEAM_X, H), Color(0.97, 0.975, 1.0))
	_swap_left.modulate.a = 0.0
	_swap_right = _wall(WALL_TRUE, Rect2(SEAM_X, 0.0, W - SEAM_X, H), Color(1.05, 1.10, 1.22))
	_swap_right.modulate.a = 0.0

	# the same person, standing on both sides of it: what the true world looks
	# like from the inside, and what the perceived world was told to look like
	_true_pawn = _pawn(_player_frame(PLAYER_TRUE), SEAM_X - PAWN_GAP, PAWN_SCALE)
	_true_pawn.modulate = Color(1.45, 1.52, 1.70, 0.0)
	_pale_pawn = _pawn(_player_frame(PLAYER_PALE), SEAM_X + PAWN_GAP, PAWN_SCALE)
	_pale_pawn.modulate = Color(0.99, 0.99, 1.02, 0.0)

	# and what is standing there when the seam gives way: still you, at a size
	# the room cannot hold, with one of each world's eyes looking out of it
	_merged = _pawn(_player_frame(PLAYER_PALE), SEAM_X, MERGED_SCALE)
	_merged.modulate = Color(0.90, 0.94, 1.05, 0.0)
	_merged.visible = false
	var eye_y: float = _merged.position.y + (EYE_TOP_Y - FRAME_H * 0.5) * MERGED_SCALE
	var eye_h: float = (EYE_BOTTOM_Y - EYE_TOP_Y) * MERGED_SCALE
	_eyes.append(_eye(EYE_LEFT_X, eye_y, eye_h, COL_EYE_PALE))
	_eyes.append(_eye(EYE_RIGHT_X, eye_y, eye_h, COL_EYE_TRUE))

	# the three pieces it comes apart into, laid exactly over it and hidden: the
	# seam that runs through the room runs through it as well
	var cy: float = _merged.position.y
	var half: float = 8.0 * MERGED_SCALE
	_split_l = _piece(Rect2(0.0, 0.0, 16.0, FRAME_H), SEAM_X - half, cy)
	_split_r = _piece(Rect2(16.0, 0.0, 16.0, FRAME_H), SEAM_X + half, cy)
	_head = _piece(Rect2(0.0, 0.0, FRAME_W, 18.0), SEAM_X, cy - 15.0 * MERGED_SCALE)

	_tear = ColorRect.new()
	_tear.color = Color(0.88, 0.97, 1.0, 0.0)
	_tear.position = Vector2(SEAM_X - 1.5, cy - FRAME_H * 0.5 * MERGED_SCALE)
	_tear.size = Vector2(3.0, 0.0)
	_tear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tear.visible = false
	_layer.add_child(_tear)

	# the picture is about to be asked to do something it cannot do
	_glitch = Glitch.new()
	_glitch.intensity = 0.18
	_glitch.calm_gap = Vector2(5.0, 11.0)
	add_child(_glitch)

	_black = ColorRect.new()
	_black.color = Color(0.0, 0.0, 0.0, 1.0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_black)

	# something is in the dark with you, and it is not blinking
	_void_eyes.append(_void_eye(256.0, 90.0, 30.0, 12.0, Color(0.78, 0.86, 0.98)))
	_void_eyes.append(_void_eye(354.0, 90.0, 30.0, 12.0, Color(0.78, 0.86, 0.98)))

	_dlg = EERIE_TEXT.new()
	_dlg.position = Vector2(0.0, 310.0)
	_dlg.size = Vector2(W, 20.0)
	_dlg.add_theme_font_size_override("font_size", 12)
	_layer.add_child(_dlg)

	_void_text = EERIE_TEXT.new()
	_void_text.position = Vector2(0.0, 146.0)
	_void_text.size = Vector2(W, 24.0)
	_void_text.add_theme_font_size_override("font_size", 14)
	_void_text.tremble = 0.55
	_void_text.slip_gap = Vector2(1.4, 4.0)
	_layer.add_child(_void_text)

	_flash = ColorRect.new()
	_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_flash)


## One tile of a tileset, repeated over a rectangle: a wall, or a floor. Every
## wall is kept, because the room is going to have to come apart too.
func _wall(tex_path: String, rect: Rect2, col: Color) -> TextureRect:
	var tile := AtlasTexture.new()
	tile.atlas = load(tex_path)
	tile.region = Rect2(0.0, 0.0, 16.0, 16.0)
	var quad := TextureRect.new()
	quad.texture = tile
	quad.stretch_mode = TextureRect.STRETCH_TILE
	quad.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	quad.modulate = col
	quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quad.position = rect.position
	quad.size = rect.size
	_layer.add_child(quad)
	_walls.append(quad)
	return quad


## Stands one of them on the floor, with its lowest drawn pixel on the ground
## line so a figure whose art hangs low still has its feet in the right place.
func _pawn(tex: Texture2D, x: float, pawn_scale: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(pawn_scale, pawn_scale)
	var h := float(tex.get_height())
	var row: float = _content_bottom(tex)
	s.position = Vector2(x, FLOOR_Y - (row + 0.5 - h * 0.5) * pawn_scale)
	s.modulate.a = 0.0
	_layer.add_child(s)
	return s


## One slice of the merged one, cut along the seam that runs through it. It is
## laid exactly where that part of the whole figure sits, so it can be revealed
## without anything appearing to move until it does.
func _piece(region: Rect2, cx: float, cy: float) -> Sprite2D:
	var at := AtlasTexture.new()
	at.atlas = load(PLAYER_PALE)
	at.region = region
	var s := Sprite2D.new()
	s.texture = at
	s.scale = Vector2(MERGED_SCALE, MERGED_SCALE)
	s.position = Vector2(cx, cy)
	s.modulate = Color(0.90, 0.94, 1.05, 1.0)
	s.visible = false
	_layer.add_child(s)
	return s


## The last row of a texture that has anything drawn on it.
func _content_bottom(tex: Texture2D) -> float:
	var im: Image = tex.get_image()
	if im == null:
		return float(tex.get_height()) - 1.0
	for y in range(im.get_height() - 1, -1, -1):
		for x in im.get_width():
			if im.get_pixel(x, y).a > 0.05:
				return float(y)
	return float(tex.get_height()) - 1.0


## One frame of the player's own idle sheet — the same art you were walking
## around in, so the figure in the tear is recognisably the one you were.
func _player_frame(path: String) -> Texture2D:
	var at := AtlasTexture.new()
	at.atlas = load(path)
	at.region = Rect2(0.0, 0.0, FRAME_W, FRAME_H)
	return at


## One of the merged one's eyes, laid over the eye the art already has, with a
## dim halo riding on the same fade. `art_x` is a pixel column in the 32x48 frame.
func _eye(art_x: float, y: float, h: float, col: Color) -> ColorRect:
	var eye := ColorRect.new()
	eye.color = col
	eye.size = Vector2(3.0 * MERGED_SCALE, h)
	eye.position = Vector2(SEAM_X + (art_x - FRAME_W * 0.5) * MERGED_SCALE, y)
	eye.modulate.a = 0.0
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var halo := ColorRect.new()
	halo.color = Color(col.r * 0.34, col.g * 0.34, col.b * 0.34, 1.0)
	halo.size = eye.size + Vector2(6.0, 6.0)
	halo.position = Vector2(-3.0, -3.0)
	halo.show_behind_parent = true
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eye.add_child(halo)

	_layer.add_child(eye)
	return eye


## An eye in the dark: a slit with a pupil in it, and two rings of glow behind
## that, so it reads as something looking at you rather than as a rectangle.
## Nothing in this scene has a body behind it any more, which is the point.
func _void_eye(x: float, y: float, w: float, h: float, col: Color) -> ColorRect:
	var eye := ColorRect.new()
	eye.color = col
	eye.size = Vector2(w, h)
	eye.position = Vector2(x, y)
	eye.modulate.a = 0.0
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var outer := ColorRect.new()
	outer.color = Color(col.r * 0.10, col.g * 0.10, col.b * 0.10, 1.0)
	outer.size = Vector2(w + 24.0, h + 24.0)
	outer.position = Vector2(-12.0, -12.0)
	outer.show_behind_parent = true
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eye.add_child(outer)

	var inner := ColorRect.new()
	inner.color = Color(col.r * 0.24, col.g * 0.24, col.b * 0.24, 1.0)
	inner.size = Vector2(w + 10.0, h + 10.0)
	inner.position = Vector2(-5.0, -5.0)
	inner.show_behind_parent = true
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eye.add_child(inner)

	# the pupil, which is the only part that makes the slit a thing that sees
	var pupil := ColorRect.new()
	pupil.color = Color(0.015, 0.015, 0.02, 1.0)
	pupil.size = Vector2(w * 0.30, h)
	pupil.position = Vector2(w * 0.35, 0.0)
	pupil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eye.add_child(pupil)

	_layer.add_child(eye)
	return eye


# ── what happens ───────────────────────────────────────────────────────────

func _run() -> void:
	# the dark lets go, and both of them are standing there — and they start
	# talking to each other before the room is even finished arriving
	_open()
	await _say(COL_PALE, "YOU CAME ALL THIS WAY.", 0.0, 46.0)
	await _say(COL_TRUE, "IT WAS ONLY TWO ROOMS. YOU PAINTED THE SECOND ONE.", 0.0, 46.0)
	await _say(COL_PALE, "I PAINTED IT THE WAY YOU WANTED IT TO LOOK.", 0.0, 46.0)

	# they cross to each other, while the room watches and says so
	_walk()
	await _say(COL_ROOM, "SAME FLOOR. SAME FEET. SAME FACE.", 0.3, 40.0)
	await _slip()
	await _say(COL_ROOM, "ONE OF THESE WAS ALWAYS YOU.", 0.3, 40.0)

	# the seam gives way, and what stands up in it has a voice of its own
	await _break_seam()
	await _say(COL_IT, "I AM NOT EITHER OF THEM.", 0.7, 26.0)
	await _swap()
	await _say(COL_IT, "I AM THE PART OF THE PICTURE THAT WATCHED YOU PLAY.", 0.7, 26.0)
	await _open_eyes()
	await _say(COL_IT, "YOU WERE ONE PANEL OF SOMETHING ENORMOUS.", 0.7, 26.0)
	await _say(COL_IT, "LET ME SHOW YOU WHAT I AM MADE OF.", 0.7, 26.0)

	# the only thing it has left to do
	await _unmake_itself()
	await _nothing_left()

	# and then the dark, which was here first
	await _void()
	GameState.start_credits()


## One line, in the colour of whoever is speaking. Returns once it has been said
## and cleared, so the beats can be written in order.
func _say(col: Color, line: String, tremble: float, speed: float) -> void:
	_dlg.add_theme_color_override("font_color", col)
	_dlg.tremble = tremble
	_dlg.chars_per_second = speed
	_dlg.modulate.a = 1.0
	AudioManager.play_sfx("whisper", -20.0, randf_range(0.62, 1.05))
	await _dlg.play(line)
	await _wait(0.5)
	await _dlg.wipe()


func _open() -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(_black, "color:a", 0.0, 2.2)
	t.parallel().tween_property(_seam, "color:a", 0.70, 2.6)
	t.parallel().tween_property(_glow, "color:a", 0.14, 3.2)
	t.parallel().tween_property(_true_pawn, "modulate:a", 1.0, 2.4)
	t.parallel().tween_property(_pale_pawn, "modulate:a", 1.0, 2.6)


func _walk() -> void:
	for i in 3:
		var step := create_tween()
		step.set_trans(Tween.TRANS_SINE)
		step.tween_property(_true_pawn, "position:x", _true_pawn.position.x + 8.0, 0.26)
		step.parallel().tween_property(_pale_pawn, "position:x", _pale_pawn.position.x - 8.0, 0.26)
		AudioManager.play_sfx("stone", -16.0, 1.4)
		await step.finished
		await _wait(0.34)


## And on the last step the pale one loses hold of itself for a moment: the thing
## walking towards you was never standing on anything.
func _slip() -> void:
	var slip := create_tween()
	slip.set_trans(Tween.TRANS_SINE)
	slip.tween_property(_pale_pawn, "modulate:a", 0.12, 0.08)
	slip.parallel().tween_property(_true_pawn, "modulate", Color(1.85, 1.95, 2.20, 1.0), 0.5)
	AudioManager.play_sfx("sting", -14.0, 0.55)
	_glitch.burst(0.5)
	await slip.finished
	await _wait(0.5)
	var back := create_tween()
	back.tween_property(_pale_pawn, "modulate:a", 1.0, 0.16)
	await back.finished
	await _wait(0.9)


func _break_seam() -> void:
	_glitch.intensity = 1.0
	_glitch.burst(1.0)
	AudioManager.play_sfx("sting", -3.0, 0.42)
	AudioManager.set_music_distortion(0.85)
	_shake(1.0, 0.5)
	var broke := create_tween()
	broke.tween_property(_flash, "color:a", 0.92, 0.06)
	broke.parallel().tween_property(_true_pawn, "modulate:a", 0.0, 0.30)
	broke.parallel().tween_property(_pale_pawn, "modulate:a", 0.0, 0.30)
	broke.parallel().tween_property(_seam, "color:a", 0.0, 0.30)
	broke.parallel().tween_property(_glow, "color:a", 0.62, 0.30)
	await broke.finished

	_merged.visible = true
	var out := create_tween()
	out.set_trans(Tween.TRANS_SINE)
	out.tween_property(_flash, "color:a", 0.0, 1.1)
	out.parallel().tween_property(_glow, "color:a", 0.10, 1.4)
	out.parallel().tween_property(_merged, "modulate:a", 1.0, 1.6)
	await out.finished
	_glitch.intensity = 0.35


## Each half of the room wears the other half's skin for a moment. The two worlds
## were the same room painted twice, and you were told otherwise for six levels.
func _swap() -> void:
	_glitch.burst(0.7)
	var swap := create_tween()
	swap.tween_property(_swap_left, "modulate:a", 0.80, 0.10)
	swap.parallel().tween_property(_swap_right, "modulate:a", 0.80, 0.10)
	await swap.finished
	await _wait(0.18)
	var swap_back := create_tween()
	swap_back.set_trans(Tween.TRANS_SINE)
	swap_back.tween_property(_swap_left, "modulate:a", 0.0, 0.95)
	swap_back.parallel().tween_property(_swap_right, "modulate:a", 0.0, 0.95)
	AudioManager.play_sfx("whisper", -7.0, 0.7)
	await swap_back.finished


## It opens its eyes — one of each — and neither of them is yours.
func _open_eyes() -> void:
	var look := create_tween()
	look.set_trans(Tween.TRANS_SINE)
	for eye: ColorRect in _eyes:
		look.parallel().tween_property(eye, "modulate:a", 1.0, 1.2)
	AudioManager.play_sfx("heartbeat", -6.0, 0.7)
	await look.finished
	await _wait(1.4)


## The only thing it has left to do. It looks at itself, opens the seam that was
## always running through it, and comes apart along it — left half one way, right
## half the other, head up into the dark, with nothing at all in between.
func _unmake_itself() -> void:
	AudioManager.play_sfx("heartbeat", -5.0, 0.55)
	var look := create_tween()
	look.set_trans(Tween.TRANS_SINE)
	look.tween_property(_merged, "rotation", -0.045, 0.8)
	look.parallel().tween_property(_merged, "scale", Vector2(MERGED_SCALE * 1.06, MERGED_SCALE * 1.06), 0.8)
	await look.finished
	await _wait(0.7)

	# the eyes come up, and they do not come down again
	var flare := create_tween()
	for eye: ColorRect in _eyes:
		flare.parallel().tween_property(eye, "modulate", Color(3.4, 3.4, 3.4, 1.0), 0.55)
	AudioManager.play_sfx("sting", -10.0, 0.9)
	await flare.finished
	await _wait(0.5)

	# it opens along the seam, from the top of it to the floor
	_tear.visible = true
	AudioManager.play_sfx("creak", -6.0, 0.5)
	var split := create_tween()
	split.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	split.tween_property(_tear, "size:y", FRAME_H * MERGED_SCALE, 0.75)
	split.parallel().tween_property(_tear, "color:a", 1.0, 0.75)
	_shake(0.6, 0.75)
	await split.finished

	var dead := create_tween()
	for eye: ColorRect in _eyes:
		dead.parallel().tween_property(eye, "modulate:a", 0.0, 0.16)
	await dead.finished

	# and it comes apart
	_merged.visible = false
	for piece: Sprite2D in [_split_l, _split_r, _head]:
		piece.visible = true
	_glitch.intensity = 1.0
	_glitch.burst(1.0)
	AudioManager.set_music_distortion(1.0)
	AudioManager.play_sfx("sting", 0.0, 0.30)
	_shake(1.6, 2.0)
	# the light is a spike and not a wash: what comes apart has to be visible
	var spike := create_tween()
	spike.tween_property(_flash, "color:a", 0.85, 0.08)
	spike.tween_property(_flash, "color:a", 0.12, 0.6)
	var apart := create_tween()
	apart.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	apart.tween_property(_split_l, "position", _split_l.position + Vector2(-190.0, 90.0), 1.8)
	apart.parallel().tween_property(_split_l, "rotation", -0.7, 1.8)
	apart.parallel().tween_property(_split_r, "position", _split_r.position + Vector2(190.0, 90.0), 1.8)
	apart.parallel().tween_property(_split_r, "rotation", 0.7, 1.8)
	apart.parallel().tween_property(_head, "position", _head.position + Vector2(0.0, -230.0), 1.8)
	apart.parallel().tween_property(_head, "rotation", 1.9, 1.8)
	apart.parallel().tween_property(_glow, "color:a", 1.0, 1.8)
	await apart.finished

	var gone := create_tween()
	gone.tween_property(_flash, "color:a", 0.0, 0.5)
	for piece: Sprite2D in [_split_l, _split_r, _head]:
		gone.parallel().tween_property(piece, "modulate:a", 0.0, 1.1)
	await gone.finished
	AudioManager.play_sfx("sting", -6.0, 0.5)
	await _wait(0.6)


## And the room lets go of the picture. There was never anything behind it.
func _nothing_left() -> void:
	AudioManager.play_sfx("whisper", -8.0, 0.5)
	var tear := create_tween()
	tear.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	for wall: TextureRect in _walls:
		var dir: float = -1.0 if wall.position.x < SEAM_X else 1.0
		tear.parallel().tween_property(wall, "position:x", wall.position.x + dir * 260.0, 1.5)
	tear.parallel().tween_property(_seam, "color:a", 0.0, 0.4)
	tear.parallel().tween_property(_glow, "color:a", 1.0, 1.5)
	_shake(1.2, 1.5)
	await tear.finished

	# cut
	_glitch.intensity = 0.16
	_glitch.calm_gap = Vector2(3.5, 8.0)
	AudioManager.stop_music()
	var cut := create_tween()
	cut.tween_property(_black, "color:a", 1.0, 0.10)
	await cut.finished
	_layer.offset = Vector2.ZERO
	await _wait(1.6)


## Nothing left to look at, and it still has things to say.
func _void() -> void:
	_dlg.visible = false
	_void_eyes_in()
	AudioManager.play_sfx("breath", -12.0, 0.6)
	await _wait(1.2)

	var last: int = VOID_LINES.size() - 1
	for i in VOID_LINES.size():
		await _void_say(VOID_LINES[i], 3.2 if i == last else 1.1)
		if i == 3:
			AudioManager.play_sfx("heartbeat", -9.0, 0.5)
		elif i == 5:
			AudioManager.play_sfx("sting", -16.0, 0.4)

	await _wait(1.6)
	var close := create_tween()
	close.set_trans(Tween.TRANS_SINE)
	for eye: ColorRect in _void_eyes:
		close.parallel().tween_property(eye, "modulate:a", 0.0, 2.4)
	close.parallel().tween_property(_glitch, "intensity", 0.0, 2.4)
	AudioManager.play_sfx("whisper", -14.0, 0.4)
	await close.finished
	await _wait(1.0)


func _void_say(line: String, hold: float) -> void:
	_void_text.add_theme_color_override("font_color", COL_VOID)
	_void_text.chars_per_second = 34.0
	_void_text.modulate.a = 1.0
	AudioManager.play_sfx("whisper", -22.0, randf_range(0.5, 0.9))
	await _void_text.play(line)
	await _wait(hold)
	await _void_text.wipe(0.3)


## Something in the dark, fading up and drifting apart. It never blinks.
func _void_eyes_in() -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	for eye: ColorRect in _void_eyes:
		eye.modulate.a = 0.0
		t.parallel().tween_property(eye, "modulate:a", 0.22, 6.0)
	t.parallel().tween_property(_void_eyes[0], "position:x", _void_eyes[0].position.x - 16.0, 16.0)
	t.parallel().tween_property(_void_eyes[1], "position:x", _void_eyes[1].position.x + 16.0, 16.0)


## The room is not steady any more. Shakes the whole layer, which is everything
## that is left of the picture.
func _shake(amount: float, duration: float) -> void:
	var t := create_tween()
	var steps: int = maxi(1, int(duration / 0.045))
	for i in steps:
		t.tween_property(_layer, "offset", Vector2(randf_range(-amount, amount) * 5.0, randf_range(-amount, amount) * 5.0), 0.045)
	t.tween_property(_layer, "offset", Vector2.ZERO, 0.14)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
