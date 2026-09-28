class_name Blood
extends Node2D
## Blood, on the floor, for as long as it makes sense for it to be there.
##
## Every splat in this game is drawn at runtime: one irregular blob of white
## pixels with droplets thrown off it, tinted by the caller. So there are no
## blood assets to ship, and the same shape reads as fresh or dried depending on
## what colour it is handed. Drops are thrown out of a wound and fall under their
## own weight; where they land they stay, flattened, until the scene goes — or
## until `life` runs out and takes them quietly with it.
##
## Used by every room that has something in it worth opening up.

const COL_FRESH := Color(0.62, 0.045, 0.06, 1.0)
const COL_DRY := Color(0.30, 0.02, 0.035, 1.0)

## How hard it pulls. Blood is heavier than it looks.
@export var gravity: float = 520.0
## Where drops stop falling — normally the floor line of the room they are in.
@export var floor_y: float = 296.0
## How long a splat stays before it starts to go. 0 means it does not.
##
## A fight's mess should be gone before the fight is a memory: a floor still painted
## red ten minutes later makes a room look saved rather than fought. Set it and the
## decals clean themselves up. The ending leaves it at 0 on purpose — its blood is
## the whole point of the last scene, and it stays there until the scene does.
@export var life: float = 0.0
## How long the fade itself takes. Long enough that nobody ever catches it happening.
@export var fade: float = 1.6

var _shapes: Array[ImageTexture] = []
var _drops: Array[Sprite2D] = []
var _vels: Array[Vector2] = []
var _spin: Array[float] = []
## The splats that have stopped moving and are now only counting down.
var _aged: Array[Sprite2D] = []
var _aged_t: Array[float] = []
var _aged_a: Array[float] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for i in 5:
		_shapes.append(_make_shape(4711 + i * 977, 32))
	set_process(false)


func _process(delta: float) -> void:
	var i: int = _drops.size() - 1
	while i >= 0:
		var s: Sprite2D = _drops[i]
		var v: Vector2 = _vels[i]
		v.y += gravity * delta
		s.position += v * delta
		s.rotation += _spin[i] * delta
		if s.position.y >= floor_y:
			# it hits the floor and it stays there, spread out
			s.position.y = floor_y
			s.rotation = 0.0
			s.scale = Vector2(absf(s.scale.x) * 1.2, absf(s.scale.y) * 0.4)
			s.modulate = COL_DRY
			_vels.remove_at(i)
			_spin.remove_at(i)
			_drops.remove_at(i)
			_age(s)
		i -= 1

	# The ones that have already landed, counting down. Nothing here runs at all while
	# life is 0 — the arrays stay empty and the node goes back to sleep with the drops.
	var j: int = _aged.size() - 1
	while j >= 0:
		_aged_t[j] += delta
		var u: float = (_aged_t[j] - life) / maxf(fade, 0.01)
		if u <= 0.0:
			j -= 1
			continue
		var d: Sprite2D = _aged[j]
		if u >= 1.0:
			_aged.remove_at(j)
			_aged_t.remove_at(j)
			_aged_a.remove_at(j)
			d.queue_free()
			j -= 1
			continue
		var c: Color = d.modulate
		c.a = _aged_a[j] * (1.0 - u)
		d.modulate = c
		j -= 1

	if _drops.is_empty() and _aged.is_empty():
		set_process(false)


## Starts the clock on a splat that has stopped moving. Does nothing at all if this
## node was left at life = 0, which is how a caller says *this one stays*.
func _age(s: Sprite2D) -> void:
	if life <= 0.0:
		return
	_aged.append(s)
	_aged_t.append(0.0)
	_aged_a.append(s.modulate.a)
	set_process(true)


## Throws `count` drops out of `from`, roughly along `dir`, and lets them go.
func spray(from: Vector2, dir: Vector2, count: int, spread: float = 0.9,
		speed: Vector2 = Vector2(120.0, 300.0), size: Vector2 = Vector2(0.45, 1.30)) -> void:
	for i in count:
		var away: Vector2 = dir.normalized().rotated(_rng.randf_range(-spread, spread))
		var s := _new_shape(size, COL_FRESH)
		s.position = from + Vector2(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-4.0, 4.0))
		_drops.append(s)
		_vels.append(away * _rng.randf_range(speed.x, speed.y))
		_spin.append(_rng.randf_range(-11.0, 11.0))
	set_process(true)


## Stamps splats straight onto whatever is behind it. No motion at all — it is
## already dry by the time you look.
func stamp(rect: Rect2, count: int, size: Vector2 = Vector2(1.1, 3.2)) -> void:
	for i in count:
		var s := _new_shape(size, COL_FRESH if _rng.randf() < 0.55 else COL_DRY)
		s.position = Vector2(_rng.randf_range(rect.position.x, rect.end.x),
			_rng.randf_range(rect.position.y, rect.end.y))
		s.rotation = _rng.randf_range(-PI, PI)
		s.modulate.a = _rng.randf_range(0.50, 0.95)
		s.scale.y *= _rng.randf_range(0.55, 1.0)
		_age(s)


func _new_shape(size: Vector2, col: Color) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _shapes[_rng.randi() % _shapes.size()]
	var k: float = _rng.randf_range(size.x, size.y)
	s.scale = Vector2(k * _rng.randf_range(0.85, 1.2), k * _rng.randf_range(0.85, 1.2))
	s.modulate = col
	add_child(s)
	return s


## One irregular blob with droplets thrown off it. White, so the caller tints it.
func _make_shape(seed_value: int, size: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var im := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	var c := Vector2(float(size), float(size)) * 0.5
	var base: float = float(size) * 0.18
	var lobes := 9
	var radii: PackedFloat32Array = PackedFloat32Array()
	for i in lobes:
		radii.append(base * rng.randf_range(0.45, 1.30))
	# the blob itself: a circle whose radius wanders round the rim
	for y in size:
		for x in size:
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			var d: float = p.distance_to(c)
			if d > base * 1.4:
				continue
			var f: float = ((p - c).angle() + PI) / TAU * float(lobes)
			var i0: int = int(floor(f)) % lobes
			var i1: int = (i0 + 1) % lobes
			var r: float = lerpf(radii[i0], radii[i1], f - floor(f))
			if d <= r:
				im.set_pixel(x, y, Color(1, 1, 1, 1))
	# and what it threw off on the way out
	for i in rng.randi_range(7, 13):
		var ang: float = rng.randf_range(0.0, TAU)
		var dp: Vector2 = c + Vector2(cos(ang), sin(ang)) * base * rng.randf_range(1.1, 2.1)
		var dr: float = rng.randf_range(0.7, 2.4)
		for y in range(maxi(0, int(dp.y - dr)), mini(size, int(dp.y + dr) + 2)):
			for x in range(maxi(0, int(dp.x - dr)), mini(size, int(dp.x + dr) + 2)):
				if Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(dp) <= dr:
					im.set_pixel(x, y, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(im)
