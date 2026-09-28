class_name TitleEmbers
extends Control
## The air over the title painting, doing something.
##
## A still painting of a burning city is a photograph of one, and the difference is not the
## fire — it is the ash. A few dozen specks of it, rising, wandering sideways a little,
## brightening and going out, forever, and the eye reads the whole painting as moving
## because it has one thing in it that plainly is. None of it is drawn by hand and none of
## it is a picture: every ember is a number with a sine on it, and the numbers are all
## different.
##
## They are lit additively, so they add light to the painting rather than laying paint over
## it — a spark that covers the sky is a grey dot. Each one is two circles, a wide soft one
## and a small bright one, because one flat circle reads as a dead pixel and a glow reads
## as a spark.
##
## The layer never takes the mouse. The title's whole menu and its whole parallax live on
## mouse motion, and a full-frame Control with the default filter eats both.

## How many are in the air at once. Enough to be a haze, few enough that the eye can pick
## one out and follow it up the frame.
@export var count: int = 76
## How fast they climb, in frame units a second, low to high. The slow ones read as near:
## a spark that crawls is a spark in front of everything else.
@export var rise: Vector2 = Vector2(7.0, 30.0)
## How far off their line one wanders, and how many times a second it wanders there.
@export var drift: Vector2 = Vector2(9.0, 22.0)
@export var wander: Vector2 = Vector2(0.16, 0.70)
## Seconds one lives, low to high. Long lives are the thin haze at the top of the frame.
@export var life: Vector2 = Vector2(4.0, 11.0)
## The size of the bright centre of one, in frame units.
@export var grain: Vector2 = Vector2(0.7, 2.4)
## Deep ember-red through to a pale gold: where each one sits between them.
@export var cold: Color = Color(0.94, 0.20, 0.14)
@export var hot: Color = Color(1.40, 0.72, 0.34)

var _x: PackedFloat32Array = PackedFloat32Array()
var _y: PackedFloat32Array = PackedFloat32Array()
var _v: PackedFloat32Array = PackedFloat32Array()
var _g: PackedFloat32Array = PackedFloat32Array()
var _w: PackedFloat32Array = PackedFloat32Array()
var _f: PackedFloat32Array = PackedFloat32Array()
var _p: PackedFloat32Array = PackedFloat32Array()
var _l: PackedFloat32Array = PackedFloat32Array()
var _t: PackedFloat32Array = PackedFloat32Array()
var _h: PackedFloat32Array = PackedFloat32Array()
var _frame: Vector2 = Vector2.ZERO
## Fixed seed: the haze is part of the painting too, and a screen whose ash is different
## every time it is opened is a screen that was never the same screen twice.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	_rng.seed = 0x19F15
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame = size
	# packed arrays arrive empty and there is no "push" onto one that has no room, so every
	# column is cut to size first. Eight parallel columns rather than an array of objects:
	# this is read and written sixty times a second and nothing here is a reference.
	_x.resize(count)
	_y.resize(count)
	_v.resize(count)
	_g.resize(count)
	_w.resize(count)
	_f.resize(count)
	_p.resize(count)
	_l.resize(count)
	_t.resize(count)
	_h.resize(count)
	for i in count:
		_born(i, true)


## One ember, either invented mid-flight — so the first frame is already a haze instead of a
## row of sparks all leaving the floor together — or sent up from below it.
func _born(i: int, anywhere: bool) -> void:
	var f: Vector2 = _frame if _frame.x > 0.0 else Vector2(640.0, 360.0)
	_x[i] = _rng.randf() * f.x
	_y[i] = _rng.randf() * f.y if anywhere else f.y + _rng.randf_range(4.0, 40.0)
	_v[i] = _rng.randf_range(rise.x, rise.y)
	_g[i] = _rng.randf_range(grain.x, grain.y)
	_w[i] = _rng.randf_range(drift.x, drift.y)
	_f[i] = _rng.randf_range(wander.x, wander.y)
	_p[i] = _rng.randf() * TAU
	_l[i] = _rng.randf_range(life.x, life.y)
	_t[i] = _rng.randf() * _l[i] if anywhere else 0.0
	_h[i] = _rng.randf()


func _process(delta: float) -> void:
	if size != _frame and size.x > 0.0 and size.y > 0.0:
		_frame = size
	for i in count:
		_t[i] += delta
		if _t[i] >= _l[i] or _y[i] < -8.0:
			_born(i, false)
		else:
			_y[i] -= _v[i] * delta
	queue_redraw()


func _draw() -> void:
	for i in count:
		var u: float = _t[i] / maxf(_l[i], 0.001)
		# in quickly, out slowly: ash that appeared at full brightness and vanished at full
		# brightness is a blinking light, and a blinking light is not a spark
		var a: float = minf(1.0, u / 0.10) * minf(1.0, (1.0 - u) / 0.34)
		if a <= 0.01:
			continue
		var px: float = _x[i] + sin(_t[i] * TAU * _f[i] + _p[i]) * _w[i]
		var py: float = _y[i] + sin(_t[i] * TAU * _f[i] * 0.61 + _p[i] * 1.7) * _w[i] * 0.35
		var c: Color = cold.lerp(hot, _h[i])
		var at: Vector2 = Vector2(px, py)
		draw_circle(at, _g[i] * 3.0, Color(c.r, c.g, c.b, a * 0.07))
		draw_circle(at, _g[i] * 1.7, Color(c.r, c.g, c.b, a * 0.16))
		draw_circle(at, _g[i], Color(c.r * 1.25, c.g * 1.15, c.b * 1.05, a * 0.85))
