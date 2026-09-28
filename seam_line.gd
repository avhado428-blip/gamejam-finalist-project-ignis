class_name SeamLine
extends Control
## The tear, standing open in a level — the same cut that runs down the middle of
## the last room, already there, already bleeding, before anything has broken.
##
## It is a line. It has never had a collision and it never will: what it does is
## fail to hold still. The picture at either side of it is fine; the picture *on*
## it is not, and every so often the line itself drops out for a frame and comes
## back brighter than it was, the way a bad signal does.
##
## Drawn, not loaded: a halo, the line, and a pool where it meets the floor.

## Where the cut is, in world pixels. Set here rather than in the scene so a
## Control's anchors cannot move it somewhere else.
@export var at_x: float = 0.0
@export var seam_width: float = 2.0
## How far down it goes. It should reach the floor: the pool is drawn across the
## floor line, so the cut has somewhere to be bleeding from.
@export var seam_height: float = 224.0
@export var col: Color = Color(0.941, 0.129, 0.145, 1.0)

var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 3
	position = Vector2(at_x, 0.0)
	size = Vector2(seam_width, seam_height)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w: float = seam_width
	var h: float = seam_height

	# the halo: a cut in a picture bleeds outwards, faintly, the whole way down
	draw_rect(Rect2(-w * 3.0, 0.0, w * 7.0, h), Color(col.r, col.g, col.b, 0.06))
	draw_rect(Rect2(-w * 1.4, 0.0, w * 3.8, h), Color(col.r, col.g, col.b, 0.15))

	# and it does not hold a constant brightness. sometimes it goes out
	var steady: float = 0.86 + 0.14 * sin(_t * 1.9)
	if randf() < 0.02:
		steady = 0.16
	draw_rect(Rect2(0.0, 0.0, w, h), Color(minf(col.r * 1.35, 1.0), col.g * 1.2, col.b * 1.2, steady))

	# where it reaches the floor it pools, because a cut that stays open does
	draw_rect(Rect2(-w * 3.5, h - 8.0, w * 8.0, 18.0), Color(col.r, col.g * 0.22, col.b * 0.28, 0.34 * steady))
	draw_rect(Rect2(-w * 1.5, h - 3.0, w * 4.0, 6.0), Color(col.r, col.g * 0.35, col.b * 0.4, 0.5 * steady))
