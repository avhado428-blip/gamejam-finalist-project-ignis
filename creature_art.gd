class_name CreatureArt
extends RefCounted
## Draws the White Worlds watcher, one frame at a time, in code.
##
## It is one solid thing standing on the floor: a long skull that is more mouth
## than face, two wide eyes with slit pupils, a black seam packed with teeth
## splitting the face in two, a starved column of a body with a second mouth
## where the stomach should be, arms hanging well clear of it so the gap between
## limb and body reads, and two long legs planted flat. The last row of the art
## is the floor it stands on.
##
## Nothing here fades, dissolves or blinks out between frames, and nothing is
## random. A figure that draws itself differently on every frame reads as
## something coming apart, and this one never comes apart.
##
## The drawing lives in its own class so a tool can build the frames headless
## and look at them without a scene tree.

const FRAME_W := 32
const FRAME_H := 112
## The head starts here; rows 0..7 above it belong to the horns.
const BODY_TOP := 8
## The surface its feet stand on. The node's origin is this row.
const FLOOR_ROW := 108
## Everything above this row drifts with the frame; below it the body never
## moves, so the sway reads as something held very still on purpose.
const SWAY_ROW := 40

const DARK := Color(0.055, 0.035, 0.098, 1.0)
const INK := Color(0.016, 0.010, 0.035, 1.0)
const PALE := Color(0.949, 0.937, 0.902, 1.0)
const BLOOD := Color(0.831, 0.078, 0.431, 1.0)


static func make(lean: int, eyes_on: bool, head_drift: int = 0, mouth_open: bool = false) -> ImageTexture:
	return CreatureArt.new().build(lean, eyes_on, head_drift, mouth_open)


func build(lean: int, eyes_on: bool, head_drift: int, mouth_open: bool) -> ImageTexture:
	var im := Image.create(FRAME_W, FRAME_H, false, Image.FORMAT_RGBA8)
	im.fill(Color(0.0, 0.0, 0.0, 0.0))
	var face := lean + head_drift
	_horns(im, lean)
	_skull(im, lean)
	_face(im, face, eyes_on, mouth_open)
	_body(im, lean)
	_arms(im, lean)
	_legs(im, lean)
	_eyes_where_they_do_not_belong(im, lean, eyes_on)
	_drool(im, face)
	return ImageTexture.create_from_image(im)


## Two wire-thin horns rooted in the skull, curving apart as they rise.
func _horns(im: Image, lean: int) -> void:
	for i in range(BODY_TOP):
		var out := int(float(BODY_TOP - 1 - i) / 3.0)
		_rect(im, lean, 14 - out, i, 1, 1, DARK)
		_rect(im, lean, 17 + out, i, 1, 1, DARK)


## A long, narrow skull tapering to a point, with no neck under it: the head sits
## straight on the shoulders like something that was never assembled properly.
func _skull(im: Image, lean: int) -> void:
	var y := BODY_TOP
	_rect(im, lean, 13, y, 6, 1, DARK)
	_rect(im, lean, 12, y + 1, 8, 1, DARK)
	_rect(im, lean, 11, y + 2, 10, 4, DARK)
	_rect(im, lean, 10, y + 6, 12, 9, DARK)
	_rect(im, lean, 11, y + 15, 10, 1, DARK)
	_rect(im, lean, 12, y + 16, 8, 3, DARK)
	_rect(im, lean, 13, y + 19, 6, 2, DARK)
	_rect(im, lean, 14, y + 21, 4, 1, DARK)


## Two big eyes with slit pupils that never move, over a mouth that is a hole
## down the face instead of a grin across it: black, no wider than the eyes,
## with fangs crossing it. Lining that hole in bone turned it into a ladder, so
## it is left as a hole — the black in this figure is far darker than the dark
## it is drawn in. On the blink frame the eyes do not close; they are simply not
## there.
func _face(im: Image, face: int, eyes_on: bool, mouth_open: bool) -> void:
	# big, blank, and pointing slightly away from each other: nothing is behind
	# them and they are not looking at the same thing
	for i in range(2):
		var ex := 11 if i == 0 else 17
		_rect(im, face, ex, BODY_TOP + 6, 4, 5, PALE if eyes_on else INK)
	if eyes_on:
		_rect(im, face, 12, BODY_TOP + 7, 1, 3, INK)
		_rect(im, face, 19, BODY_TOP + 7, 1, 3, INK)
	# the mouth: a black seam, wider on the frame where it opens
	var mtop := BODY_TOP + 12
	var half := 3 if mouth_open else 2
	for i in range(8):
		_rect(im, face, 16 - half, mtop + i, half * 2, 1, INK)
	# two long fangs, one off each lip, so the mouth reads as a mouth and not as
	# a line of stitches
	for i in range(2):
		_rect(im, face, 15 + i, mtop + 1 + i * 4, 1, 3, PALE)


## A starved column of a body with a second mouth where the stomach should be.
## The shoulders are the only part of it the arms touch.
func _body(im: Image, lean: int) -> void:
	var y := BODY_TOP
	_rect(im, lean, 12, y + 22, 8, 1, DARK)
	_rect(im, lean, 11, y + 23, 10, 1, DARK)
	for i in range(26):
		var half := 4 if i < 12 else 3
		_rect(im, lean, 16 - half, y + 24 + i, half * 2, 1, DARK)
	# the second mouth: a small hole with fangs in it, not a row of stitches
	for i in range(6):
		_rect(im, lean, 14, y + 30 + i, 4, 1, INK)
	_rect(im, lean, 15, y + 31, 1, 3, PALE)
	_rect(im, lean, 16, y + 34, 1, 2, PALE)


## Arms far too long, hanging well clear of the body, ending in three thin claws
## that reach past its knees. The gap between arm and body is what makes the
## silhouette read: a figure drawn as one slab is not a creature, it is a
## wardrobe.
func _arms(im: Image, lean: int) -> void:
	for side in [-1, 1]:
		var shoulder := 11 if side < 0 else 20
		for i in range(30):
			var reach := 1.0 + float(i) / 29.0 * 5.0
			var ax := int(round(float(shoulder) + float(side) * reach))
			_rect(im, lean, ax, BODY_TOP + 24 + i, 2, 1, DARK)
		# the hand is a wrist with one long claw off it, not a rake: fingers this
		# thin just become comb teeth at this size
		var hx := int(round(float(shoulder) + float(side) * 6.0))
		_rect(im, lean, hx - 1, BODY_TOP + 54, 3, 3, DARK)
		_rect(im, lean, hx - 1, BODY_TOP + 57, 2, 4, DARK)
		_rect(im, lean, hx - side, BODY_TOP + 57, 1, 3, DARK)
		_rect(im, lean, hx - 1, BODY_TOP + 61, 1, 5, DARK)


## Two long legs — thick at the thigh, thin at the shin — with long feet planted
## flat. The art ends on the floor row: there is nothing left of it that drips
## away.
func _legs(im: Image, lean: int) -> void:
	_rect(im, lean, 12, BODY_TOP + 50, 8, 2, DARK)
	for i in range(18):
		_rect(im, lean, 11, BODY_TOP + 52 + i, 4, 1, DARK)
		_rect(im, lean, 17, BODY_TOP + 52 + i, 4, 1, DARK)
	for i in range(26):
		_rect(im, lean, 12, BODY_TOP + 70 + i, 3, 1, DARK)
		_rect(im, lean, 17, BODY_TOP + 70 + i, 3, 1, DARK)
	_rect(im, lean, 11, BODY_TOP + 70, 5, 2, DARK)
	_rect(im, lean, 16, BODY_TOP + 70, 5, 2, DARK)
	_rect(im, lean, 9, BODY_TOP + 96, 7, 5, DARK)
	_rect(im, lean, 17, BODY_TOP + 96, 7, 5, DARK)


## Eyes where eyes have no business being: on the arms and on the legs. Each one
## sits on the limb it belongs to — nothing here floats.
func _eyes_where_they_do_not_belong(im: Image, lean: int, eyes_on: bool) -> void:
	var spots := [
		Vector2i(9, 40), Vector2i(23, 44), Vector2i(6, 58), Vector2i(25, 60),
		Vector2i(13, 70), Vector2i(18, 90),
	]
	for s in spots:
		_small_eye(im, lean, s.x, s.y, eyes_on)


## One of the eyes it is covered in: a bead of pale with a pupil, or the hole it
## leaves behind on the frame where every light on it goes out at once.
func _small_eye(im: Image, lean: int, x: int, y: int, lit: bool) -> void:
	if not lit:
		_rect(im, lean, x, y, 2, 2, INK)
		return
	_rect(im, lean, x, y, 2, 2, PALE)
	_px(im, lean, x + y % 2, y, INK)


## It is drooling. That, and nothing else, is what it lets go of.
func _drool(im: Image, face: int) -> void:
	_rect(im, face, 16, BODY_TOP + 19, 1, 6, BLOOD)


func _rect(im: Image, lean: int, x: int, y: int, w: int, h: int, col: Color) -> void:
	var sx := x + (lean if y < SWAY_ROW else 0)
	for j in range(y, y + h):
		if j < 0 or j >= FRAME_H:
			continue
		for i in range(sx, sx + w):
			if i >= 0 and i < FRAME_W:
				im.set_pixel(i, j, col)


func _px(im: Image, lean: int, x: int, y: int, col: Color) -> void:
	var sx := x + (lean if y < SWAY_ROW else 0)
	if sx >= 0 and sx < FRAME_W and y >= 0 and y < FRAME_H:
		im.set_pixel(sx, y, col)
