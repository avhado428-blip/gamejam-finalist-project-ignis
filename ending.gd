extends Node2D
## The ending — and the only scene in this game that talks.
##
## One room, cut down the middle by a seam that should not be there. On the left
## the world as it is; on the right the world as it was told. Two of you stand
## either side of it wearing the same face, and they walk — step for step, at the
## same instant, the way a reflection moves.
##
## What stands up in the tear is neither of them. It is one long black body,
## standing up straight — a black body, in the shape of a person, held at the wrong
## length and taller than the room can hold — and it is the part of the
## picture that was watching you play the whole time. It talks. It tells you what
## you were — a panel, a detail, a rendering, never the subject — and then it
## takes hold of the seam it has been standing on all along and cuts its own head
## off with it, and the blood goes everywhere, and the room stops pretending
## there is anything behind it.
##
## The last voice is not in the room at all.

const W := 640.0
const H := 360.0
const SEAM_X := 320.0
const FLOOR_Y := 296.0

## Who is speaking. The colour of the line is the only attribution there is, so
## the voices are separated by how much blood is left in them and nothing else:
## the palest is the world as it was told, the reddest is the thing in the tear.
const COL_PALE := Color(0.965, 0.706, 0.722, 1.0)
const COL_TRUE := Color(0.937, 0.435, 0.475, 1.0)
const COL_ROOM := Color(0.784, 0.235, 0.267, 1.0)
const COL_IT := Color(0.925, 0.129, 0.161, 1.0)
const COL_VOID := Color(0.996, 0.545, 0.565, 1.0)
## The seam, which was never a seam. It is a cut, and it never stops bleeding.
const COL_GLOW := Color(0.941, 0.129, 0.145, 1.0)

## And what it is made of, which is the same thing you are.
const COL_BLACK := Color(0.043, 0.020, 0.078, 1.0)

## The colours above are what the room is made of. What is written on it is a
## different matter, and nothing in this room is written in white any more. Every
## line is blood: the speaker still shows through, but only as brightness — the
## voice that used to be palest is the lightest red, the room is the deepest, and
## the thing in the tear stays the reddest thing in the game. The black outline
## holding each letter together is the only black left in the writing.
##
## Every one of them is lifted well clear of the wall it is written on, and the
## deepest of them is lifted furthest: this is the only scene in the game with
## anything to read, and a line of dark red on a dark red room is not a voice, it
## is a texture. The order still reads — palest to reddest — it is just all of it
## further from the floor now.
const TXT_PALE := Color(0.980, 0.502, 0.541, 1.0)
const TXT_TRUE := Color(0.929, 0.341, 0.380, 1.0)
const TXT_ROOM := Color(0.855, 0.251, 0.290, 1.0)
const TXT_IT := Color(1.000, 0.235, 0.243, 1.0)
const TXT_VOID := Color(0.949, 0.361, 0.400, 1.0)
## Any line handed a colour that is not one of the voices still arrives in blood.
const TXT_ANY := Color(0.949, 0.341, 0.380, 1.0)

const WALL_TRUE := "res://assets/tilesets/tileset_true.png"
const WALL_PALE := "res://assets/tilesets/tileset_perceived.png"
const PLAYER_PALE := "res://assets/player/player_idle_perceived.png"
const PLAYER_TRUE := "res://assets/player/player_idle_true.png"
## And what is standing in the middle of the room once those two are gone. It is
## not a sprite of the world any more: it is one image, and the only thing in this
## game that was never drawn for the room it stands in, face and all.
const FIGURE := "res://assets/generated/its_body_joined.png"

const EERIE_TEXT := preload("res://ui/eerie_text.gd")
const BLOOD := preload("res://effects/blood.gd")
## What is left of it keeps losing its own edge.
const WARP := preload("res://effects/warp.gdshader")

## The two pawns' own art: one 32x48 frame of the idle sheet.
const FRAME_W := 32.0
const FRAME_H := 48.0

## And the thing they turn into, measured off its own pixels rather than guessed
## at: 256x256 of texture, every row of which is the thing itself. It is the same
## shape you walked the whole game around in, wrung out until it stops being one.
## It is one drawing and it is drawn as one thing: the head runs down through a
## tapering neck into the shoulders without a break, so there is no join in it for
## anything to show. The face is part of it too, measured off its own pixels: two
## red eyes at rows 17-21, a wide red grin at rows 25-32, and that red is the only
## colour anywhere in the figure.
## The head comes off at row 37. The neck is rows 33-38 and the shoulders begin at
## row 39, so the cut is inside the neck — clear of the shoulders and clear of the
## face, which is entirely above it.
const FIG_W := 256.0
const FIG_H := 256.0
const HEAD_ROWS := 37.0

## Two of them standing apart, and the thing they turn into.
const PAWN_SCALE := 2.2
const PAWN_GAP := 60.0
## 256 rows of figure at this scale stands 250px tall, which is what the room
## was built to hold.
const MERGED_SCALE := 0.977
## It was not born. It was assembled out of whatever was left over — but it was
## assembled out of one drawing and left as one piece: head and body are cut from
## the same art at the same scale, and all that separates them is where the cut is
## going to be made. Scaling either half against the other would put a join on it
## that nothing in the drawing ever had. Both carry MERGED_SCALE — the head's
## pivot as well as the body's node — so the two agree to the pixel.
const HEAD_WARP := Vector2(1.0, 1.0)
const BODY_NARROW := 1.0

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
var _blade: ColorRect
var _true_pawn: Sprite2D
var _pale_pawn: Sprite2D
var _merged: Sprite2D
var _head_pivot: Node2D
var _head: Sprite2D
var _body: Sprite2D

var _void_eyes: Array[ColorRect] = []
var _blood: Blood
var _dlg: EerieText
var _void_text: EerieText
var _black: ColorRect
var _flash: ColorRect
var _skippable: bool = false

## The two of them, and where they were standing before this started.
var _pawns: Array[Sprite2D] = []
var _pawn_home: Array[Vector2] = []
var _pawn_tint: Array[Color] = []
## 0 = standing still. 1 = being taken apart where it stands.
var _vibrate: float = 0.0
## How far into the middle of the room they have been dragged.
var _suck: float = 0.0
## The room is strobing, because the picture has lost the argument with itself.
var _flicker: bool = false
var _flicker_clock: float = 0.0
## The thing is standing, and it cannot hold its own proportions.
var _pulse: bool = false
var _t: float = 0.0


func _ready() -> void:
	GameState.current_level = "ending"
	GameState.set_objective("")
	EventManager.hint_changed.emit("")
	AudioManager.play_music("music_broken")
	AudioManager.set_music_distortion(0.18)
	# This room is the end of the game — unless the run came in through the fourth
	# wall, in which case it is being borrowed as the beat before the parkour room:
	# the two of them are pulled together, the flash takes the player, and nothing is
	# left standing in the middle of it. The flag is consumed here, so the real
	# ending still plays afterwards, when the parkour has been finished.
	set_meta("parkour", bool(Engine.get_meta("parkour_mode", false)))
	Engine.set_meta("parkour_mode", false)
	_build()
	if bool(get_meta("parkour", false)):
		_run_parkour()
	else:
		_run()
	await get_tree().create_timer(2.6).timeout
	_skippable = true
	_show_skip_prompt()


## Nothing was ever explained; the player is allowed to leave anyway. In parkour
## mode there is no ending to leave, so the same key skips forward into the room.
func _unhandled_input(event: InputEvent) -> void:
	if not _skippable:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if bool(get_meta("parkour", false)):
			_out_to_the_room()
		else:
			GameState.start_credits()


## The beat this room is being borrowed for: the two of them are taken into the
## middle of the room, and the flash that ends it is a door rather than a reveal.
## Everything the ending does after that — the thing in the tear, its face, what it
## does with its head — is left for the real ending, because this is the door and
## not the room behind it.
func _run_parkour() -> void:
	_open()
	await _wait(1.4)
	await _convulse(1.6)
	await _glitch_merge()
	await _out_to_the_room()


## Out of the plane of the picture and into the room behind it, through the white
## the merge left behind. Guarded, because skipping and finishing both come through
## here and only one of them should ever arrive.
func _out_to_the_room() -> void:
	if bool(get_meta("out", false)):
		return
	set_meta("out", true)
	_skippable = false
	_glitch.burst(1.0)
	AudioManager.play_sfx("sting", -4.0, 0.5)
	var out := create_tween()
	out.tween_property(_flash, "color:a", 1.0, 0.4)
	await out.finished
	get_tree().change_scene_to_file("res://scenes/parkour_3d.tscn")


## Once the ending can be left, it says so. A player who has seen enough should
## never have to sit through a cutscene to find out whether they are allowed to
## stand up, and a jam judge is the most impatient player there is.
func _show_skip_prompt() -> void:
	var skip: Label = UiStyle.at("SPACE TO SKIP", 10, 12.0, 342.0, W - 24.0,
		TXT_VOID, HORIZONTAL_ALIGNMENT_RIGHT)
	skip.modulate.a = 0.0
	_layer.add_child(skip)
	var t := create_tween()
	t.tween_property(skip, "modulate:a", 0.6, 1.4)


# ── the picture is not holding together ────────────────────────────────────

## Everything that is wrong at this point is wrong per frame, so it is done here
## rather than in a tween: the two of them juddering where they stand, the room
## strobing on and off, and the thing in the middle of it unable to hold a shape.
func _process(delta: float) -> void:
	if _true_pawn == null:
		return
	_t += delta

	if _vibrate > 0.0:
		for i in _pawns.size():
			var who: Sprite2D = _pawns[i]
			var home: Vector2 = _pawn_home[i]
			if _suck > 0.0:
				home = home.lerp(Vector2(SEAM_X, home.y), _suck)
			who.position = home + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 3.6 * _vibrate
			who.rotation = randf_range(-0.075, 0.075) * _vibrate
			# it judders where it stands and stays exactly as bright as it was: a
			# sprite that strobes between its own colour and the dark, and drops
			# out every eighth frame, reads as a broken sprite rather than as
			# something being taken apart
			who.visible = true
			who.modulate = _pawn_tint[i]

	if _pulse:
		# it pinches and lets go, slowly, like something breathing that has no
		# business breathing
		var p := sin(_t * 1.6)
		# it leans and lifts on its neck rather than swelling off it: at the body's
		# own scale, a breath big enough to see would open a line at the join
		_head_pivot.scale = Vector2(HEAD_WARP.x + 0.02 * p, HEAD_WARP.y - 0.018 * p) * MERGED_SCALE
		_head_pivot.rotation = 0.035 * sin(_t * 0.9)
		_body.scale = Vector2(MERGED_SCALE * BODY_NARROW * (1.0 + 0.045 * p), MERGED_SCALE)

	if _flicker:
		_flicker_clock -= delta
		if _flicker_clock <= 0.0:
			_flicker_clock = randf_range(0.03, 0.11)
			for wall: TextureRect in _walls:
				wall.modulate.a = [1.0, 1.0, 0.30, 0.0][randi() % 4]
			# and for a frame or two each half is wearing the other one, which
			# is the only honest thing the room has said all game
			_swap_left.modulate.a = randf_range(0.0, 0.80)
			_swap_right.modulate.a = randf_range(0.0, 0.80)
			if randf() < 0.40:
				_glitch.burst(randf_range(0.45, 1.0))


# ── the room ───────────────────────────────────────────────────────────────

func _build() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 0
	add_child(_layer)

	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.043, 0.020, 0.078, 1.0)
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
	_seam.color = Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, 0.0)
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
	_pawns = [_true_pawn, _pale_pawn]

	# and what stands up when the seam gives way: one black shape, too big for
	# the room, and a face drawn into it rather than put on it
	_merged = _pawn(load(FIGURE), SEAM_X, MERGED_SCALE)
	_merged.modulate = Color(COL_BLACK.r, COL_BLACK.g, COL_BLACK.b, 0.0)
	_merged.visible = false
	_merged.scale = Vector2(MERGED_SCALE * BODY_NARROW, MERGED_SCALE)

	# its head, on a pivot of its own so that the face travels with it when it is
	# no longer attached to anything. Nothing is done to its size: it is drawn on
	# the body's own neck at the body's own scale, so it sits on it as drawn
	_head_pivot = Node2D.new()
	_head_pivot.position = _slice_at(Rect2(0.0, 0.0, FIG_W, HEAD_ROWS))
	_head_pivot.scale = HEAD_WARP * MERGED_SCALE
	_layer.add_child(_head_pivot)
	_head = _piece(Rect2(0.0, 0.0, FIG_W, HEAD_ROWS), _head_pivot)

	# and the rest of it, pivoted at its feet so that it can topple
	_body = _piece(Rect2(0.0, HEAD_ROWS, FIG_W, FIG_H - HEAD_ROWS), _layer)
	_body.offset = Vector2(0.0, -(FIG_H - HEAD_ROWS) * 0.5)
	_body.position = _slice_at(_body_region()) + Vector2(0.0, (FIG_H - HEAD_ROWS) * 0.5 * MERGED_SCALE)
	_body.scale = Vector2(MERGED_SCALE * BODY_NARROW, MERGED_SCALE)

	# and neither piece can hold an edge while it is standing there. Both are cut
	# from the one drawing and both wear the same shader at the same strength, so
	# the join between them moves with them rather than against them: what tears is
	# the outline of a single thing, and the only part of it that keeps its own
	# colour is the face.
	_warp(_body, 0.0)
	_warp(_head, 1.0)

	# what it cuts itself with: the seam, in its hand
	_blade = ColorRect.new()
	_blade.color = Color(0.960, 0.937, 0.902, 1.0)
	_blade.size = Vector2(300.0, 3.0)
	_blade.pivot_offset = Vector2(150.0, 1.5)
	_blade.rotation = -0.20
	_blade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blade.visible = false
	_layer.add_child(_blade)

	# the picture is about to be asked to do something it cannot do
	_glitch = Glitch.new()
	_glitch.intensity = 0.18
	_glitch.calm_gap = Vector2(5.0, 11.0)
	add_child(_glitch)

	# everything it is made of, drawn over the room and over itself
	_blood = BLOOD.new()
	_blood.floor_y = FLOOR_Y
	_layer.add_child(_blood)

	_black = ColorRect.new()
	_black.color = Color(0.0, 0.0, 0.0, 1.0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_black)

	# something is in the dark with you, and it is not blinking
	_void_eyes.append(_void_eye(256.0, 90.0, 30.0, 12.0, Color(0.855, 0.706, 1.0)))
	_void_eyes.append(_void_eye(354.0, 90.0, 30.0, 12.0, Color(0.855, 0.706, 1.0)))

	_dlg = EERIE_TEXT.new()
	# 18 was too big for the lines it has to carry. The longest one it ever says —
	# "I AM THE PART OF THE PICTURE THAT WATCHED YOU PLAY." — measures 702 px at 18 in
	# this hand, and the frame is 640: the first and last words were being cut off at
	# both ends of the screen, and the black caption behind them ran edge to edge and
	# read as a letterbox rather than as a caption. 15 puts the widest line at 585,
	# which leaves the plate a margin of its own on each side and still reads at this
	# size — and the plate never exceeds the label's rect whatever it is set to.
	_dlg.position = Vector2(24.0, 306.0)
	_dlg.size = Vector2(W - 48.0, 26.0)
	_dlg.add_theme_font_size_override("font_size", 15)
	# the plate: this dialogue is set in the colour the wall behind it is
	_dlg.caption = true
	_dlg.caption_pad = Vector2(12.0, 5.0)
	_layer.add_child(_dlg)

	# The void gets the same treatment one size up from its own overflow: its longest
	# line is 46 characters, which is 704 px at the 20 it was built with.
	_void_text = EERIE_TEXT.new()
	_void_text.position = Vector2(24.0, 142.0)
	_void_text.size = Vector2(W - 48.0, 32.0)
	_void_text.add_theme_font_size_override("font_size", 16)
	_void_text.tremble = 0.55
	_void_text.slip_gap = Vector2(1.6, 4.5)
	_void_text.caption = true
	_void_text.caption_pad = Vector2(16.0, 6.0)
	_layer.add_child(_void_text)

	_flash = ColorRect.new()
	# The room does not flash white when the head comes off. It flashes red.
	_flash.color = Color(0.949, 0.106, 0.129, 0.0)
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


## The slice of the figure's frame that is its body rather than its head.
func _body_region() -> Rect2:
	return Rect2(0.0, HEAD_ROWS, FIG_W, FIG_H - HEAD_ROWS)


## Where a slice of the figure sits, given the region it takes out of the frame.
## The head and the body are cut from the same whole, so laying them back down
## puts it together again exactly.
func _slice_at(region: Rect2) -> Vector2:
	return Vector2(SEAM_X, _merged.position.y
		+ (region.position.y + region.size.y * 0.5 - FIG_H * 0.5) * MERGED_SCALE)


## One slice of the figure, parented wherever the caller wants it. It arrives
## black and hidden, because the thing in the tear is a hole with a face in it;
## the shader and the fade onto it are put on later, when there is room to show it.
## It is cut out of the frame with an AtlasTexture rather than a sprite region, so
## the coordinates it is drawn with are the drawing's own all the way down into the
## shader — which is what lets two pieces of it be two pieces of one thing.
func _piece(region: Rect2, parent: Node) -> Sprite2D:
	var at := AtlasTexture.new()
	at.atlas = load(FIGURE)
	at.region = region
	var s := Sprite2D.new()
	s.texture = at
	s.scale = Vector2(MERGED_SCALE, MERGED_SCALE)
	s.modulate = COL_BLACK
	s.visible = false
	parent.add_child(s)
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



## An eye in the dark: the same lens the thing in the tear wears, scaled up and
## flattened into a wide slit, tinted cold instead of red. Nothing in this scene
## has a body behind it any more, which is the point.
func _void_eye(x: float, y: float, w: float, h: float, col: Color) -> ColorRect:
	var eye := ColorRect.new()
	eye.color = Color(0, 0, 0, 0)
	eye.size = Vector2(w, h)
	eye.position = Vector2(x, y)
	eye.pivot_offset = Vector2(w, h) * 0.5
	eye.modulate = Color(col.r, col.g, col.b, 0.0)
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lens := TextureRect.new()
	# built round and squashed into the slit by the size below, which keeps the
	# pupil vertical however wide the eye ends up
	lens.texture = GlowEye.make(Vector2i(96, 96), 0.10)
	lens.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	lens.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lens.stretch_mode = TextureRect.STRETCH_SCALE
	lens.size = Vector2(w, h)
	lens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eye.add_child(lens)

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

	# neither of them can hold still any more, and then neither of them can hold
	# anything at all
	await _convulse(2.4)
	await _glitch_merge()
	await _say(COL_IT, "I AM NOT EITHER OF THEM.", 0.7, 26.0)
	await _swap()
	await _say(COL_IT, "I AM THE PART OF THE PICTURE THAT WATCHED YOU PLAY.", 0.7, 26.0)
	await _open_eyes()
	await _say(COL_IT, "YOU WERE ONE PANEL OF SOMETHING ENORMOUS.", 0.7, 26.0)
	await _say(COL_IT, "LET ME SHOW YOU WHAT I AM MADE OF.", 0.7, 26.0)

	# the only thing it has left to do
	await _cut_its_head_off()
	await _nothing_left()

	# and then the dark, which was here first
	await _void()
	GameState.start_credits()


## Picks the red a voice writes in. The voices are still told apart, but by how
## much light is left in the blood rather than by how close to white it is: the
## palest speaker in the room is the lightest red, and nothing here is pale.
func _ink(base: Color) -> Color:
	if base == COL_PALE:
		return TXT_PALE
	if base == COL_TRUE:
		return TXT_TRUE
	if base == COL_ROOM:
		return TXT_ROOM
	if base == COL_IT:
		return TXT_IT
	if base == COL_VOID:
		return TXT_VOID
	return TXT_ANY


## One line, in the colour of whoever is speaking. Returns once it has been said
## and cleared, so the beats can be written in order.
func _say(col: Color, line: String, tremble: float, speed: float) -> void:
	_dlg.add_theme_color_override("font_color", _ink(col))
	# Nothing in this room holds still, however calmly it is talking.
	_dlg.tremble = maxf(tremble, 0.45)
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


## And on the last step the room flinches: everything the true one is lit by goes up
## a stop. The pale one does not change at all — it used to drop most of the way out
## of sight here for a tenth of a second, which read as a broken sprite rather than
## as the thing walking towards you never having stood on anything.
func _slip() -> void:
	var slip := create_tween()
	slip.set_trans(Tween.TRANS_SINE)
	slip.tween_property(_true_pawn, "modulate", Color(1.85, 1.95, 2.20, 1.0), 0.5)
	AudioManager.play_sfx("sting", -14.0, 0.55)
	_glitch.burst(0.5)
	await slip.finished
	await _wait(1.56)


## What is left of it cannot hold an edge, and this is how that looks: it wears a
## shader that will not let a row of it sit still, and it comes apart the same way
## every time. Painted by the shader, so the sheet's own colours come off it first
## — all except the face, which `keep_art` hands back to the head alone. The head
## and the body are two pieces of one drawing, drawn at one scale and wearing this
## one shader at one strength, so what comes apart is a single thing's outline.
func _warp(piece: Sprite2D, keep_art: float) -> void:
	var m := ShaderMaterial.new()
	m.shader = WARP
	m.set_shader_parameter("strength", 0.75)
	m.set_shader_parameter("churn", 1.0)
	m.set_shader_parameter("speed", 1.4)
	m.set_shader_parameter("chroma", 0.6)
	m.set_shader_parameter("band_soft", 0.16)
	m.set_shader_parameter("glow", 0.55)
	m.set_shader_parameter("tint", COL_BLACK)
	m.set_shader_parameter("keep_art", keep_art)
	piece.material = m
	piece.modulate = Color(1.0, 1.0, 1.0, 1.0)


## Both of them stop being able to stand still. This is not a walk any more: it
## is two objects being asked to hold a shape they are losing, and losing it
## faster and faster, while the room they are losing it in starts to strobe.
func _convulse(seconds: float) -> void:
	_pawn_home = [_true_pawn.position, _pale_pawn.position]
	_pawn_tint = [_true_pawn.modulate, _pale_pawn.modulate]
	_flicker = true
	_glitch.intensity = 1.0
	AudioManager.play_sfx("sting", -11.0, 0.55)
	AudioManager.set_music_distortion(0.9)
	var ramp := create_tween()
	ramp.tween_property(self, "_vibrate", 1.0, 1.0)
	await _wait(seconds)


## And then they are taken. They judder across the floor into the middle of the
## room a few pixels at a time, still wearing exactly the colour they had, and by
## the time they arrive neither of them is holding a shape the room can read — and
## what is
## standing there in the flash afterwards is not either of them.
func _glitch_merge() -> void:
	AudioManager.play_sfx("heartbeat", -3.0, 0.45)
	var suck := create_tween()
	suck.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	suck.tween_property(self, "_suck", 1.0, 1.25)
	while _suck < 0.995:
		_glitch.burst(randf_range(0.5, 1.0))
		_shake(_suck * 1.7, 0.09)
		await _wait(randf_range(0.04, 0.14))

	# the flash, and what is standing in the middle of it when it clears
	_glitch.burst(1.0)
	AudioManager.play_sfx("sting", -3.0, 0.42)
	AudioManager.set_music_distortion(1.0)
	_shake(2.2, 0.5)
	_vibrate = 0.0
	var broke := create_tween()
	broke.tween_property(_flash, "color:a", 0.94, 0.05)
	broke.parallel().tween_property(_true_pawn, "modulate:a", 0.0, 0.24)
	broke.parallel().tween_property(_pale_pawn, "modulate:a", 0.0, 0.24)
	broke.parallel().tween_property(_seam, "color:a", 0.0, 0.30)
	broke.parallel().tween_property(_glow, "color:a", 0.62, 0.30)
	await broke.finished
	_true_pawn.visible = false
	_pale_pawn.visible = false
	_pawns.clear()
	# it does not arrive so much as stop being avoidable — except in parkour mode,
	# where the flash is the door out and there is nothing standing in the middle of
	# it but the light
	if not bool(get_meta("parkour", false)):
		_head.visible = true
		_body.visible = true
		_pulse = true
	var out := create_tween()
	out.set_trans(Tween.TRANS_SINE)
	out.tween_property(_flash, "color:a", 0.0, 1.1)
	out.parallel().tween_property(_glow, "color:a", 0.10, 1.4)
	await out.finished
	_glitch.intensity = 0.35
	_flicker = false
	_restore_walls()


## The room stops being a room. It was a picture the whole time, and it is being
## pulled: every panel of it comes off in strips, each one going its own way, at
## its own speed, and none of them agreeing on which way is out.
func _shatter(seconds: float) -> void:
	_flicker = false
	_restore_walls()
	_shake(2.4, seconds)
	AudioManager.play_sfx("sting", -4.0, 0.5)
	AudioManager.play_sfx("stone", -6.0, 0.7)
	_glitch.intensity = 1.0
	_glitch.burst(1.0)
	for wall: TextureRect in _walls:
		var src := wall.texture as AtlasTexture
		var upright := wall.size.y > wall.size.x
		var along: float = wall.size.y if upright else wall.size.x
		var thick := 7.0
		var count: int = maxi(1, int(along / thick))
		for k in count:
			var slice := AtlasTexture.new()
			slice.atlas = src.atlas
			slice.region = Rect2(0.0, 0.0, thick, 16.0) if upright else Rect2(0.0, 0.0, 16.0, thick)
			var shard := TextureRect.new()
			shard.texture = slice
			shard.stretch_mode = TextureRect.STRETCH_TILE
			shard.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shard.modulate = wall.modulate
			if upright:
				shard.position = wall.position + Vector2(float(k) * thick, 0.0)
				shard.size = Vector2(thick, wall.size.y)
			else:
				shard.position = wall.position + Vector2(0.0, float(k) * thick)
				shard.size = Vector2(wall.size.x, thick)
			shard.pivot_offset = shard.size * 0.5
			_layer.add_child(shard)
			# the room is behind everything happening in it, blood included
			_layer.move_child(shard, _blood.get_index())
			var away := Vector2(randf_range(-1.0, 1.0), randf_range(-1.3, 0.25)).normalized()
			var flight := randf_range(80.0, 430.0)
			var fly := create_tween()
			fly.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			fly.tween_property(shard, "position", shard.position + away * flight, seconds)
			fly.parallel().tween_property(shard, "rotation", randf_range(-1.5, 1.5), seconds)
			fly.parallel().tween_property(shard, "modulate:a", 0.0, seconds * 0.85)
		wall.visible = false


## Back to how the room was, for whenever the strobe lets go of it again.
func _restore_walls() -> void:
	for wall: TextureRect in _walls:
		wall.modulate.a = 1.0
	_swap_left.modulate.a = 0.0
	_swap_right.modulate.a = 0.0


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


## It is already looking at you: the face is part of the drawing, so there are no
## lights to fade up and nothing to blink. What is left of this beat is the room
## noticing — one held breath while the thing stands there doing it, for as long as
## the beat used to take.
func _open_eyes() -> void:
	AudioManager.play_sfx("heartbeat", -6.0, 0.7)
	await _wait(4.45)



## The only thing it has left to do. It takes the seam it has been standing on
## all along, puts it through its own throat, and lets go — and the room is
## wearing what is left of it by the time it is done.
func _cut_its_head_off() -> void:
	# it stops holding still, and so does everything standing behind it
	_pulse = false
	_flicker = true
	AudioManager.play_sfx("heartbeat", -4.0, 0.5)
	var look := create_tween()
	look.set_trans(Tween.TRANS_SINE)
	look.tween_property(_head_pivot, "scale", HEAD_WARP * MERGED_SCALE * 1.12, 0.9)
	await look.finished
	await _wait(0.7)

	# the blade goes through, and it does not slow down on the way
	_glitch.intensity = 1.0
	_glitch.burst(1.0)
	AudioManager.set_music_distortion(1.0)
	AudioManager.play_sfx("slash", -1.0, 1.0)
	var neck_y: float = _head_pivot.position.y + HEAD_ROWS * 0.5 * MERGED_SCALE * HEAD_WARP.y
	_blade.position = Vector2(SEAM_X - 260.0, neck_y - 34.0)
	_blade.visible = true
	var slash := create_tween()
	slash.tween_property(_blade, "position", Vector2(SEAM_X + 130.0, neck_y + 20.0), 0.13)
	slash.parallel().tween_property(_flash, "color:a", 0.90, 0.05)
	_shake(1.6, 0.45)
	await slash.finished
	_blade.visible = false

	# and everything in it lets go at once. it is on the walls behind before the
	# head has finished falling.
	AudioManager.play_sfx("wet", -2.0, 1.0)
	AudioManager.play_sfx("sting", -4.0, 0.40)
	_merged.visible = false
	_head.visible = true
	_body.visible = true
	var neck := Vector2(SEAM_X, neck_y)
	_blood.spray(neck, Vector2(0.0, -1.0), 30, 0.55, Vector2(150.0, 330.0))
	_blood.spray(neck + Vector2(-8.0, 0.0), Vector2(-0.9, -0.85), 14)
	_blood.spray(neck + Vector2(8.0, 0.0), Vector2(0.9, -0.85), 14)
	_blood.stamp(Rect2(SEAM_X - 210.0, neck_y - 170.0, 420.0, 200.0), 9, Vector2(1.0, 3.0))
	_blood.stamp(Rect2(0.0, 0.0, W, FLOOR_Y), 8)
	_blood.stamp(Rect2(0.0, FLOOR_Y - 5.0, W, 18.0), 6)

	var head_to := Vector2(SEAM_X + 86.0, FLOOR_Y - HEAD_ROWS * 0.5 * MERGED_SCALE * HEAD_WARP.y)
	var fall := create_tween()
	fall.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(_head_pivot, "position", head_to, 1.0)
	fall.parallel().tween_property(_head_pivot, "rotation", 2.6, 1.0)
	fall.parallel().tween_property(_flash, "color:a", 0.0, 0.6)
	await fall.finished

	# it lands, rolls once, and stops with its eyes still on
	AudioManager.play_sfx("thud", -5.0, 1.15)
	AudioManager.play_sfx("wet", -7.0, 0.9)
	_shake(0.7, 0.35)
	var roll := create_tween()
	roll.tween_property(_head_pivot, "position:x", head_to.x + 28.0, 0.5)
	roll.parallel().tween_property(_head_pivot, "rotation", 3.7, 0.5)
	await roll.finished
	_blood.stamp(Rect2(head_to.x - 30.0, FLOOR_Y - 9.0, 140.0, 14.0), 5, Vector2(1.2, 2.6))

	# and the body stands there with nothing on its shoulders, which is worse
	# than if it had gone over straight away
	await _wait(0.85)
	AudioManager.play_sfx("thud", -3.0, 0.80)
	_blood.stamp(Rect2(SEAM_X - 40.0, FLOOR_Y - 13.0, 80.0, 15.0), 5, Vector2(1.4, 2.8))
	var down := create_tween()
	down.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	down.tween_property(_body, "rotation", -1.2, 0.9)
	down.parallel().tween_property(_body, "position", Vector2(SEAM_X - 40.0, FLOOR_Y - 1.0), 0.9)
	_shake(1.1, 0.9)
	await down.finished
	AudioManager.play_sfx("stone", -6.0, 0.80)
	_blood.spray(Vector2(SEAM_X - 40.0, FLOOR_Y - 30.0), Vector2(-0.5, -0.4), 10, 1.2, Vector2(60.0, 170.0))
	await _wait(1.2)


## And the room lets go of the picture. There was never anything behind it — and
## it does not slide away politely: it comes off in strips, in the frame, in
## front of you, and there is nothing behind that either.
func _nothing_left() -> void:
	AudioManager.play_sfx("whisper", -8.0, 0.5)
	_shatter(1.5)
	var tear := create_tween()
	tear.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tear.tween_property(_seam, "color:a", 0.0, 0.4)
	tear.parallel().tween_property(_glow, "color:a", 1.0, 1.5)
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
	_void_text.add_theme_color_override("font_color", _ink(COL_VOID))
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
