class_name Fx
extends RefCounted
## Tiny throwaway-effect helper: spawns a one-shot AnimatedSprite2D built from
## a horizontal sheet, plays it, frees itself. Used for dust, sparks, bursts.

static func burst(parent: Node, sheet: String, frames: int, fw: int, fh: int, pos: Vector2, fps: float = 14.0, scale_mul: float = 1.0, modulate: Color = Color.WHITE) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var tex: Texture2D = load(sheet) as Texture2D
	if tex == null:
		return
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("fx")
	sf.set_animation_speed("fx", fps)
	sf.set_animation_loop("fx", false)
	for i in range(frames):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, fh)
		sf.add_frame("fx", at)
	var s := AnimatedSprite2D.new()
	s.sprite_frames = sf
	s.scale = Vector2(scale_mul, scale_mul)
	s.modulate = modulate
	s.z_index = 50
	parent.add_child(s)
	s.global_position = pos
	s.play("fx")
	s.animation_finished.connect(s.queue_free)
