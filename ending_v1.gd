extends Node2D
## The ending.
##
## One room, cut down the middle by a seam that should not be there. On the left
## the world as it is: dark, and the thing that lives in it. On the right the
## world as it is told: white, and the thing that lives in that. Same floor, same
## room — two halves that were never meant to touch.
##
## They see each other across it, and they walk. The seam does not survive that,
## and what is left standing in the tear is neither of them. It is you, or it is
## close enough that you cannot tell — which is the whole point the run was
## making while you were busy jumping over things.

const W := 640.0
const H := 360.0
const SEAM_X := 320.0
const FLOOR_Y := 296.0

const COL_GLOW := Color(0.66, 0.93, 1.0, 1.0)
const COL_TEXT := Color(0.90, 0.92, 0.96, 1.0)
const COL_OUTLINE := Color(0.02, 0.025, 0.04, 0.95)
## The two eyes this game has always used for its two worlds.
const COL_EYE_PALE := Color(0.94, 0.97, 1.0, 1.0)
const COL_EYE_TRUE := Color(0.55, 0.94, 1.0, 1.0)

const FINAL_LINE := "ONE OF THESE WAS ALWAYS YOU."

const WALL_TRUE := "res://assets/tilesets/tileset_true.png"
const WALL_PALE := "res://assets/tilesets/tileset_perceived.png"
const PLAYER_PALE := "res://assets/player/player_idle_perceived.png"
const PLAYER_TRUE := "res://assets/player/player_idle_true.png"

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

var _layer: CanvasLayer
var _glitch: Glitch
var _seam: ColorRect
var _glow: ColorRect
var _true_pawn: Sprite2D
var _pale_pawn: Sprite2D
var _merged: Sprite2D
var _swap_left: TextureRect
var _swap_right: TextureRect
var _eyes: Array[ColorRect] = []
var _line: Label
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
	await get_tree().create_timer(1.8).timeout
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

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.014, 0.016, 0.024, 1.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(backdrop)

	# the same room, twice: walls above the floor line, floor below it
	_layer.add_child(_wall(WALL_TRUE, Rect2(0.0, 0.0, SEAM_X, FLOOR_Y), Color(0.78, 0.81, 0.90)))
	_layer.add_child(_wall(WALL_PALE, Rect2(SEAM_X, 0.0, W - SEAM_X, FLOOR_Y), Color(0.97, 0.975, 1.0)))
	_layer.add_child(_wall(WALL_TRUE, Rect2(0.0, FLOOR_Y, SEAM_X, H - FLOOR_Y), Color(1.10, 1.16, 1.30)))
	_layer.add_child(_wall(WALL_PALE, Rect2(SEAM_X, FLOOR_Y, W - SEAM_X, H - FLOOR_Y), Color(0.86, 0.87, 0.90)))

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
	_layer.add_child(_swap_left)
	_swap_right = _wall(WALL_TRUE, Rect2(SEAM_X, 0.0, W - SEAM_X, H), Color(1.05, 1.10, 1.22))
	_swap_right.modulate.a = 0.0
	_layer.add_child(_swap_right)

	# the same person, standing on both sides of it: what the true world looks
	# like from the inside, and what the perceived world was told to look like
	_true_pawn = _pawn(_player_frame(PLAYER_TRUE), SEAM_X - PAWN_GAP, 0.0, PAWN_SCALE)
	_true_pawn.modulate = Color(1.45, 1.52, 1.70, 0.0)
	_pale_pawn = _pawn(_player_frame(PLAYER_PALE), SEAM_X + PAWN_GAP, 0.0, PAWN_SCALE)
	_pale_pawn.modulate = Color(0.99, 0.99, 1.02, 0.0)

	# and what is standing there when the seam gives way: still you, at a size
	# the room cannot hold, with one of each world's eyes looking out of it
	_merged = _pawn(_player_frame(PLAYER_PALE), SEAM_X, 0.0, MERGED_SCALE)
	_merged.modulate = Color(0.90, 0.94, 1.05, 0.0)
	_merged.visible = false
	var eye_y: float = _merged.position.y + (EYE_TOP_Y - FRAME_H * 0.5) * MERGED_SCALE
	var eye_h: float = (EYE_BOTTOM_Y - EYE_TOP_Y) * MERGED_SCALE
	_eyes.append(_eye(EYE_LEFT_X, eye_y, eye_h, COL_EYE_PALE))
	_eyes.append(_eye(EYE_RIGHT_X, eye_y, eye_h, COL_EYE_TRUE))

	_line = Label.new()
	_line.text = FINAL_LINE
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.position = Vector2(0.0, 312.0)
	_line.size = Vector2(W, 16.0)
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.add_theme_color_override("font_color", COL_TEXT)
	_line.add_theme_color_override("font_outline_color", COL_OUTLINE)
	_line.add_theme_constant_override("outline_size", 3)
	_line.modulate.a = 0.0
	_layer.add_child(_line)

	# the picture is about to be asked to do something it cannot do
	_glitch = Glitch.new()
	_glitch.intensity = 0.18
	_glitch.calm_gap = Vector2(5.0, 11.0)
	add_child(_glitch)

	_flash = ColorRect.new()
	_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_flash)

	_black = ColorRect.new()
	_black.color = Color(0.0, 0.0, 0.0, 1.0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_black)


## One tile of a tileset, repeated over a rectangle: a wall, or a floor.
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
	return quad


## Stands one of them on the floor. `floor_row` is the row of its own art that
## belongs on the ground line (-1 = whatever its lowest drawn pixel is), so a
## figure whose drips hang below its feet still gets its feet on the floor.
func _pawn(tex: Texture2D, x: float, base_offset: float, pawn_scale: float, floor_row: float = -1.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(pawn_scale, pawn_scale)
	s.offset = Vector2(0.0, base_offset)
	var h := float(tex.get_height())
	var row: float = floor_row if floor_row >= 0.0 else _content_bottom(tex)
	s.position = Vector2(x, FLOOR_Y - base_offset * pawn_scale - (row + 0.5 - h * 0.5) * pawn_scale)
	s.modulate.a = 0.0
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


# ── what happens ───────────────────────────────────────────────────────────

func _run() -> void:
	# the dark lets go, and both of them are standing there
	var open := create_tween()
	open.set_trans(Tween.TRANS_SINE)
	open.tween_property(_black, "color:a", 0.0, 1.8)
	open.parallel().tween_property(_seam, "color:a", 0.75, 2.4)
	open.parallel().tween_property(_glow, "color:a", 0.16, 3.0)
	open.parallel().tween_property(_true_pawn, "modulate:a", 1.0, 2.2)
	open.parallel().tween_property(_pale_pawn, "modulate:a", 1.0, 2.4)
	await open.finished
	await _wait(2.6)
	AudioManager.play_sfx("heartbeat", -8.0, 0.9)

	# they cross to each other — step for step, at exactly the same moment, the
	# way a reflection moves. nobody watching would call them two people.
	for i in 3:
		var step := create_tween()
		step.set_trans(Tween.TRANS_SINE)
		step.tween_property(_true_pawn, "position:x", _true_pawn.position.x + 8.0, 0.26)
		step.parallel().tween_property(_pale_pawn, "position:x", _pale_pawn.position.x - 8.0, 0.26)
		AudioManager.play_sfx("stone", -16.0, 1.4)
		await step.finished
		await _wait(0.32)

	# and on the last step the pale one loses hold of itself for a moment: the
	# thing walking towards you was never standing on anything
	var slip := create_tween()
	slip.set_trans(Tween.TRANS_SINE)
	slip.tween_property(_pale_pawn, "modulate:a", 0.12, 0.08)
	slip.parallel().tween_property(_true_pawn, "modulate", Color(1.85, 1.95, 2.20, 1.0), 0.5)
	AudioManager.play_sfx("sting", -14.0, 0.55)
	_glitch.burst(0.5)
	await slip.finished
	await _wait(0.44)
	var back := create_tween()
	back.tween_property(_pale_pawn, "modulate:a", 1.0, 0.16)
	await back.finished
	await _wait(1.1)

	# the seam gives way
	_glitch.intensity = 1.0
	_glitch.burst(1.0)
	AudioManager.play_sfx("sting", -3.0, 0.42)
	AudioManager.set_music_distortion(0.85)
	var broke := create_tween()
	broke.tween_property(_flash, "color:a", 0.92, 0.06)
	broke.parallel().tween_property(_true_pawn, "modulate:a", 0.0, 0.30)
	broke.parallel().tween_property(_pale_pawn, "modulate:a", 0.0, 0.30)
	broke.parallel().tween_property(_seam, "color:a", 0.0, 0.30)
	broke.parallel().tween_property(_glow, "color:a", 0.62, 0.30)
	await broke.finished

	# something is standing in it now, and it is wearing you — and it is far
	# too big for the room, because it is what the room was always about
	_merged.visible = true
	var out := create_tween()
	out.set_trans(Tween.TRANS_SINE)
	out.tween_property(_flash, "color:a", 0.0, 1.1)
	out.parallel().tween_property(_glow, "color:a", 0.10, 1.4)
	out.parallel().tween_property(_merged, "modulate:a", 1.0, 1.6)
	await out.finished
	_glitch.intensity = 0.35

	# and then each half of the room wears the other half's skin for a moment.
	# the two worlds were the same room painted twice, and you were told
	# otherwise for six levels.
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

	# it opens its eyes — one of each
	var look := create_tween()
	look.set_trans(Tween.TRANS_SINE)
	for eye: ColorRect in _eyes:
		look.parallel().tween_property(eye, "modulate:a", 1.0, 1.2)
	AudioManager.play_sfx("heartbeat", -6.0, 0.7)
	await look.finished
	await _wait(1.8)

	# and says the only thing it has been saying the whole time
	var said := create_tween()
	said.set_trans(Tween.TRANS_SINE)
	said.tween_property(_line, "modulate:a", 1.0, 1.4)
	AudioManager.play_sfx("whisper", -8.0, 0.8)
	await said.finished
	await _wait(3.4)

	var close := create_tween()
	close.set_trans(Tween.TRANS_SINE)
	close.tween_property(_line, "modulate:a", 0.0, 1.2)
	close.parallel().tween_property(_merged, "modulate:a", 0.0, 2.4)
	close.parallel().tween_property(_black, "color:a", 1.0, 2.6)
	close.parallel().tween_property(_glitch, "intensity", 0.0, 2.6)
	await close.finished
	await _wait(1.2)
	GameState.start_credits()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
