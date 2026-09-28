class_name IllusionFloor
extends Node2D
## A floor that is not there.
##
## It is drawn with the same ground tile the level itself uses, in each world's
## own colours, so in both realities it looks exactly like the floor you have
## been walking on all level. It is solid in neither of them. Step onto it in
## the world that is supposed to be honest and find out what you were looking at.
##
## It is not a cheat: every few seconds the image loses its grip on itself for a
## moment, and the floor you were about to trust is briefly not there at all.

const TILE := 16.0
const TILESET_TRUE := "res://assets/tilesets/tileset_true.png"
const TILESET_PALE := "res://assets/tilesets/tileset_perceived.png"

## How many 16px tiles wide the lie is.
@export var cells: int = 4
## Seconds between the moments where it forgets to be a floor.
@export var flicker_gap: float = 2.4
@export var flicker_time: float = 0.12

var _slabs: Array[TextureRect] = []
var _clock: float = 0.0
var _next_flicker: float = 0.0


func _ready() -> void:
	var w: float = float(cells) * TILE
	_slabs.append(_slab(TILESET_TRUE, w))
	_slabs.append(_slab(TILESET_PALE, w))

	RealityManager.reality_changed.connect(_on_reality_changed)
	_apply(RealityManager.current_reality)
	_next_flicker = flicker_gap * 0.55


func _slab(tex_path: String, w: float) -> TextureRect:
	var tile := AtlasTexture.new()
	tile.atlas = load(tex_path)
	tile.region = Rect2(0.0, 0.0, TILE, TILE)
	var quad := TextureRect.new()
	quad.texture = tile
	quad.stretch_mode = TextureRect.STRETCH_TILE
	quad.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quad.position = Vector2.ZERO
	quad.size = Vector2(w, TILE)
	add_child(quad)
	return quad


func _on_reality_changed(new_reality: int) -> void:
	_apply(new_reality)


func _apply(reality: int) -> void:
	# both versions of the lie exist; neither of them is holding you up
	_slabs[0].visible = reality == RealityManager.Reality.TRUE
	_slabs[1].visible = reality != RealityManager.Reality.TRUE


func _process(delta: float) -> void:
	_clock += delta
	if _clock >= _next_flicker:
		_next_flicker = _clock + flicker_gap
		_flicker()


func _flicker() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.15, 0.04)
	t.tween_interval(flicker_time)
	t.tween_property(self, "modulate:a", 1.0, 0.12)
