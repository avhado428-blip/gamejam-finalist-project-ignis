class_name MenuPlate
extends StyleBox
## The home menu's plate: drawn here rather than imported, so every state of it is one
## shape with different colours and a menu can never be missing its own button art.
##
## It is a hexagon with a point at each end — an elongated lozenge, which is the shape
## every plate in this game has been implying — filled with the same flat dark the rest
## of the furniture uses, edged in a single hairline, and carrying one small four-pointed
## ornament inside each point. The ornament is the ui_divider the instructions page draws,
## cut down to four points and set flat, so the menu and the page are decorated out of the
## same vocabulary.
##
## A StyleBox rather than a Control because a Button already knows how to draw one, once
## per state, under its own label: the focus plate comes out a glow and nothing else, so
## the lettering is never painted over.

## The plate before the mouse finds it.
const FILL := Color(0.055, 0.024, 0.098, 0.92)
const EDGE := Color(0.62, 0.58, 0.70, 0.50)
const MARK := Color(0.949, 0.129, 0.541, 0.62)

## And after: the red the whole game is written in, as a fill rather than a border.
const FILL_HOT := Color(0.212, 0.031, 0.055, 0.96)
const EDGE_HOT := Color(0.949, 0.129, 0.541, 0.95)
const MARK_HOT := Color(1.0, 0.44, 0.46, 1.0)

## One faint inner line, a step inside the edge, so the plate reads as a plate.
const INNER := Color(1.0, 1.0, 1.0, 0.05)

var fill: Color = FILL
var edge: Color = EDGE
var mark: Color = MARK
var inner: Color = INNER
var glow: Color = Color(0, 0, 0, 0)


func _init() -> void:
	content_margin_left = 22.0
	content_margin_right = 22.0
	content_margin_top = 4.0
	content_margin_bottom = 4.0


static func idle() -> MenuPlate:
	return MenuPlate.new()


static func hot() -> MenuPlate:
	var p := MenuPlate.new()
	p.fill = FILL_HOT
	p.edge = EDGE_HOT
	p.mark = MARK_HOT
	p.glow = Color(0.949, 0.129, 0.541, 0.16)
	return p


static func pressed() -> MenuPlate:
	var p := MenuPlate.new()
	p.fill = Color(0.106, 0.012, 0.031, 0.98)
	p.edge = EDGE_HOT
	p.mark = MARK_HOT
	p.glow = Color(1.0, 0.30, 0.30, 0.10)
	return p


## Drawn on top of the normal plate, so it is a glow and an outline and nothing else: a
## fill in here would paint out the button's own label.
static func focus() -> MenuPlate:
	var p := MenuPlate.new()
	p.fill = Color(0, 0, 0, 0)
	p.edge = Color(0.949, 0.129, 0.541, 0.55)
	p.mark = Color(0, 0, 0, 0)
	p.inner = Color(0, 0, 0, 0)
	p.glow = Color(0.949, 0.129, 0.541, 0.14)
	return p


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var w: float = rect.size.x
	var h: float = rect.size.y
	if w <= 4.0 or h <= 4.0:
		return
	# How far each end comes to a point. Tied to the height so the point is always the
	# same angle, and capped so a long thin plate cannot run its points into each other.
	var e: float = clampf(h * 0.58, 3.0, w * 0.5)
	var pos: Vector2 = rect.position

	if glow.a > 0.0:
		_poly(to_canvas_item, _hex(pos, w, h, e, -3.0), glow)
	_poly(to_canvas_item, _hex(pos, w, h, e, 0.0), fill)
	if inner.a > 0.0:
		_poly(to_canvas_item, _hex(pos, w, h, e, -2.0), inner)
	if mark.a > 0.0:
		var r: float = clampf(h * 0.15, 1.5, 6.0)
		_poly(to_canvas_item, _diamond(pos + Vector2(e * 0.62, h * 0.5), r), mark)
		_poly(to_canvas_item, _diamond(pos + Vector2(w - e * 0.62, h * 0.5), r), mark)
	_stroke(to_canvas_item, _hex(pos, w, h, e, 0.0), edge, 1.0)


## The plate's own outline. `inset` grows the shape when negative and shrinks it when
## positive, which is how the inner hairline and the glow are the same hexagon and not
## two shapes that agree by hand.
func _hex(pos: Vector2, w: float, h: float, e: float, inset: float) -> PackedVector2Array:
	var l: float = pos.x + inset
	var t: float = pos.y + inset
	var r: float = pos.x + w - inset
	var b: float = pos.y + h - inset
	var ee: float = maxf(2.0, e - inset)
	return PackedVector2Array([
		Vector2(l, (t + b) * 0.5),
		Vector2(l + ee, t),
		Vector2(r - ee, t),
		Vector2(r, (t + b) * 0.5),
		Vector2(r - ee, b),
		Vector2(l + ee, b),
	])


func _diamond(center: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -r),
		center + Vector2(r, 0.0),
		center + Vector2(0.0, r),
		center + Vector2(-r, 0.0),
	])


func _poly(to_canvas_item: RID, points: PackedVector2Array, col: Color) -> void:
	var cols := PackedColorArray()
	cols.resize(points.size())
	cols.fill(col)
	RenderingServer.canvas_item_add_polygon(to_canvas_item, points, cols)


## One closed hairline. Antialiased, because the point of a plate is the one place a hard
## pixel edge is visible.
func _stroke(to_canvas_item: RID, points: PackedVector2Array, col: Color, width: float) -> void:
	if col.a <= 0.0 or points.size() < 3:
		return
	var closed := points.duplicate()
	closed.append(points[0])
	var cols := PackedColorArray()
	cols.resize(closed.size())
	cols.fill(col)
	RenderingServer.canvas_item_add_polyline(to_canvas_item, closed, cols, width, true)