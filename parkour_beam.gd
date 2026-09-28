class_name ParkourBeam
extends Node3D
## The staff's answer, once the room has let the player have one.
##
## A strike, not a throwing: lightning does not cross a room, it is simply *there*,
## between the head of the staff and whatever was in the way, for a third of a second,
## and then gone. Nothing in it is new art — the bolt is a chain of little boxes, which
## is the only shape that reads from every angle, and the hit is the flat game's sparks.
##
## It asks the room itself what it struck: the nearest creature the strike passes
## through, or the first solid thing behind it. So a shot at a creature standing in the
## other world goes through the floor that is not there instead of stopping on it.

## How far a strike can reach, and how long it is shown for.
const RANGE := 34.0
const LIFE := 0.30
## How close the strike has to pass to a creature to have hit it.
const HIT_RADIUS := 0.75
## How many segments the bolt is cut into, how far they pull sideways, and how often it
## is redrawn while it lives — which is what makes it crackle instead of sitting still.
const SEGS := 26
const KINK := 0.5
const CRACKLE := 0.04

const ART_SPARK := "res://assets/effects/sparks.png"
const SPARK_FRAMES := 8

## The bolt's colour: cold, because it comes out of the sky the true world keeps. Neither
## of these is white on purpose — this room is pale stone in one world and blood in the
## other, and a blue bolt keeps its shape against both.
const CORE := Color(0.72, 0.88, 1.00)
const EDGE := Color(0.20, 0.45, 0.95)
const FLASH := 5.0

## How wide the two nested bolts are drawn: a cold glow around a bright shaft.
const GLOW_W := 0.13
const CORE_W := 0.05

var _from: Vector3 = Vector3.ZERO
var _to: Vector3 = Vector3.FORWARD
var _life: float = 0.0
var _next: float = 0.0
## One entry per layer of the bolt: [its segment nodes, how wide it is drawn].
var _layers: Array = []
var _light: OmniLight3D


## Handed where the staff is and where the player was looking. Called after the node is
## in the tree, so the strike can ask the room what is in the way.
func setup(from: Vector3, to: Vector3) -> void:
	_from = from
	_to = to
	# the segments are placed in world coordinates, so this node has to stay at the
	# origin: standing it on the muzzle would draw every strike a second time, in the
	# wrong place, and the bolt would land behind the wall it hit
	global_position = Vector3.ZERO
	_build()
	_strike()


func _build() -> void:
	_layer(CORE, CORE_W, 6.0, false)
	_layer(EDGE, GLOW_W, 3.0, true)
	_light = OmniLight3D.new()
	_light.light_color = CORE
	_light.light_energy = FLASH
	_light.omni_range = 16.0
	_light.shadow_enabled = false
	add_child(_light)


## One layer of the bolt: a shared box, and one copy of it per segment, all of which get
## placed and stretched along the bolt every time it is redrawn.
##
## A box rather than a flat ribbon because lightning is a thing in a room, not a decal
## on the view: the player can walk around a strike and it stays a bolt. That also means
## the glow has to be the *outer* layer and the shaft the inner one, with the glow drawn
## additively, or the shaft would be swallowed by the shape around it.
func _layer(col: Color, width: float, energy: float, additive: bool) -> void:
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if additive:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.albedo_color = Color(col.r, col.g, col.b, 0.5)
	var nodes: Array = []
	for i in SEGS:
		var mi := MeshInstance3D.new()
		mi.mesh = box
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		nodes.append(mi)
	_layers.append([nodes, width, additive])


## Draw the bolt, and keep redrawing it: the kinks are new every time, which is what
## reads as a crackle rather than a bar of light.
func _draw_bolt() -> void:
	var span: Vector3 = _to - _from
	if span.length_squared() < 0.0001:
		return
	var dir: Vector3 = span.normalized()
	# the kinks happen in one plane, and it belongs to the bolt rather than to the view,
	# so the same strike looks the same from anywhere the player watches it from
	var across: Vector3 = dir.cross(Vector3.UP)
	if across.length_squared() < 0.0001:
		across = dir.cross(Vector3.RIGHT)
	across = across.normalized()

	var joints: Array[Vector3] = []
	for i in SEGS + 1:
		var t := float(i) / float(SEGS)
		var p: Vector3 = _from + span * t
		if i > 0 and i < SEGS:
			# pulled sideways, most in the middle and not at all at either end, so the
			# bolt stays stuck to the staff and to the thing it struck
			p += across * randf_range(-1.0, 1.0) * KINK * sin(t * PI)
		joints.append(p)

	for entry in _layers:
		var nodes: Array = entry[0]
		var w: float = entry[1]
		var additive: bool = entry[2]
		for k in nodes.size():
			var mi: MeshInstance3D = nodes[k]
			var a: Vector3 = joints[k]
			var b: Vector3 = joints[k + 1]
			var run: Vector3 = b - a
			var run_len: float = run.length()
			if run_len < 0.0001:
				mi.visible = false
				continue
			mi.visible = true
			var along: Vector3 = run / run_len
			var side: Vector3 = along.cross(across)
			if side.length_squared() < 0.0001:
				side = along.cross(Vector3.RIGHT)
			side = side.normalized()
			var upward: Vector3 = along.cross(side).normalized()
			# thin where it leaves the staff, widest where it lands, so the end near the
			# eye is a whip of light rather than a slab across the corner
			var half: float = w * (0.3 + 0.7 * (float(k) + 1.0) / float(SEGS))
			if additive:
				half *= 1.0
			# each segment is stretched past its own ends so the chain has no gaps at
			# the kinks, where consecutive boxes would otherwise pull apart
			mi.transform = Transform3D(
					Basis(side * half * 2.0, upward * half * 2.0, along * (run_len + half * 2.0)),
					(a + b) * 0.5)


func _process(delta: float) -> void:
	_life += delta
	if _life >= LIFE:
		queue_free()
		return
	if _life >= _next:
		_next = _life + CRACKLE
		_draw_bolt()


# ── what it strikes ────────────────────────────────────────────────────────

## Where the shot stopped and what it found there, worked out in the single frame it
## was fired in: lightning does not travel, so the hit is resolved before it is ever
## drawn.
func _strike() -> void:
	var dir: Vector3 = _to - _from
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
		_to = _from + dir
	dir = dir.normalized()
	var reach: float = minf(RANGE, _from.distance_to(_to) + 1.5)
	var end: Vector3 = _from + dir * reach

	var wall := _solid_hit(_from, end)
	if not wall.is_empty():
		end = wall["position"]
	var prey := _creature_on_the_way(_from, end)
	if prey != null:
		# where it was actually hit, which for a thing built out of an arm is not its
		# origin: the flash belongs at the point the strike came to rest, not on the floor
		end = prey.global_position + Vector3(0.0, 0.75, 0.0)
		if prey.has_method("aim_point"):
			end = prey.call("aim_point")
		prey.call("hit")
		_spark_at(end)
		if _light != null:
			_light.global_position = end
	elif _light != null:
		# nothing to strike: the flash goes dim, so a bolt into empty air does not
		# light the whole hall up
		_light.global_position = end
		_light.light_energy = FLASH * 0.35
	_to = end
	_draw_bolt()


## Creatures are not physics bodies, so the bolt asks the creatures themselves which of
## them the strike passed through, and takes the nearest one.
func _creature_on_the_way(a: Vector3, b: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("enemy3d"):
		var other := node as Node3D
		if other == null or not other.visible:
			continue
		var middle: Vector3 = other.global_position + Vector3(0.0, 0.75, 0.0)
		var wide: float = HIT_RADIUS
		# a target is hit where it says it is, and is as wide as it says it is. The thing
		# in the ceiling is an arm and a palm with its origin on the floor, so it answers
		# for both: a wall is not hit by a ray that passes near a point.
		if other.has_method("aim_point"):
			middle = other.call("aim_point")
		if other.has_method("hit_radius"):
			wide = float(other.call("hit_radius"))
		var d: float = _distance_to_segment(middle, a, b)
		if d <= wide and d < best_d:
			best = other
			best_d = d
	return best


func _distance_to_segment(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab: Vector3 = b - a
	var len_sq: float = ab.length_squared()
	if len_sq < 0.0001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Everything solid in the room is on physics layer 1. The floor a creature is standing
## in belongs to the *other* world, so it is not on layer 1 at all and a strike passes
## straight through it.
func _solid_hit(a: Vector3, b: Vector3) -> Dictionary:
	var space := get_world_3d().direct_space_state
	if space == null:
		return {}
	var query := PhysicsRayQueryParameters3D.create(a, b, 1)
	query.collide_with_areas = false
	return space.intersect_ray(query)


# ── the room's effects, which are the flat game's ──────────────────────────

## One of the flat game's effect strips, played once and freed. The bolt, the
## creatures and the hand all call this one copy of it, so there is a single way in
## the room to put a flat-game effect into a place that has a third dimension.
##
## It goes under whatever host is passed rather than under the thing that caused it,
## because that thing is usually about to stop existing.
static func effect(host: Node, path: String, frames: int, pos: Vector3, size: float,
		col: Color, step: float = 0.045) -> void:
	if host == null or frames <= 1:
		return
	var sprite := Sprite3D.new()
	sprite.texture = load(path) as Texture2D
	sprite.hframes = frames
	sprite.pixel_size = size
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.modulate = col
	host.add_child(sprite)
	sprite.global_position = pos

	var t := sprite.create_tween()
	for i in range(1, frames):
		t.tween_callback(func() -> void: sprite.frame = i)
		t.tween_interval(step)
	t.tween_callback(sprite.queue_free)


## The bolt's own spark, where it stopped being a bolt.
func _spark_at(pos: Vector3) -> void:
	effect(get_parent(), ART_SPARK, SPARK_FRAMES, pos, 0.12, Color(1.0, 0.62, 0.68))