class_name TitleParallaxLayer
extends TextureRect
## One flat picture of the title screen, hung at its own distance.
##
## A parallax is a lie about depth told with flat pictures: nothing in the title is
## actually further away than anything else, every layer is a sheet laid over the one
## behind it. What sells it is that the far sheet barely moves and the near one moves a
## lot, so the eye reads the *difference* as distance. The mouse work lives on the title
## root (see title_screen.gd); a layer only knows two things about itself — how far it is
## allowed to travel, and how much bigger than the frame it has been cut, so that
## travelling can never drag an edge into view.
##
## Both of those are exported, so every layer is tuned in the inspector rather than in
## code, and the pictures themselves are just a path: swap the art and the motion is
## identical, which is the whole point of keeping the two apart.
##
## Layers never take the mouse. A full-frame Control with the default filter swallows the
## mouse motion the title lives on before the button under the cursor ever sees it.

## How far this layer travels, in viewport pixels, when the mouse is at the very edge of
## the screen — its own distance made into a number. The sky gets a few pixels, the thing
## standing in front of the player gets twenty-odd.
@export var strength: Vector2 = Vector2(6.0, 4.0)
## How much bigger than the frame a full-bleed layer is drawn. 1.15 leaves 7.5% of margin on
## every side, and that margin is the entire budget the strength above is allowed to spend:
## the offset is clamped to it, so a plate can never slide far enough to show the beyond.
## A placed layer ignores this and is only ever allowed to wander by its own strength.
@export var overscan: float = 1.15
## A full-bleed layer is a plate cut larger than the frame, and the controller sizes it to
## fit. A placed layer is an object standing *in* the picture — a figure, a foreground
## silhouette — and keeps the rect it was given in the scene, which is the only way to say
## where in the frame it stands and how tall it is.
@export var full_bleed: bool = true
## Life. A parallax that only answers the mouse is a photograph nailed to a stick: it moves
## when it is pushed and is dead the rest of the time. Every layer also breathes on its own
## — a slow drift at its own speed and its own phase, so the sky and the thing standing in
## front of the player are never quite agreeing about where they are. Measured in the same
## pixels as strength, and it spends the same margin.
@export var idle_strength: Vector2 = Vector2.ZERO
## Breaths a second. A tenth of one is a drift the eye only notices by looking twice, which
## is the only kind of drift worth having on a screen somebody is reading.
@export var idle_speed: float = 0.10
## Where in the breath this layer starts, so the layers do not inhale together.
@export var idle_phase: float = 0.0
## The picture this layer wears. A path rather than a texture so that a picture the editor
## has not imported yet still loads (see _wear).
@export_file("*.png") var art: String = ""
## What the layer paints itself if there is no art yet, so the effect can be built and felt
## before a single drawing exists. Give each placeholder layer its own colour.
@export var placeholder: Color = Color(0.118, 0.063, 0.192, 1.0)

## Where the layer sits with the mouse in the middle of the screen, and how far from there
## it is allowed to go. Both are derived, never accumulated, so the layer cannot drift.
var _rest: Vector2 = Vector2.ZERO
var _limit: Vector2 = Vector2.ZERO
var _fitted: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# smooth paintings, not pixel art: the project's default filter is nearest, which is
	# right for the levels and wrong for everything in here
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Without this a TextureRect refuses to be smaller than its own picture. Every plate
	# would quietly un-size itself and hang at full resolution off the top-left corner — the
	# rect is the authority here, and the picture merely fills it.
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# The rect is left exactly as the scene authored it. Re-applying a layout preset here
	# would look harmless and is not: the default resize mode snaps the control to its
	# minimum size, which for a TextureRect that has been told to ignore its picture is zero
	# — every layer would be silently resized to nothing.
	_wear()
	if not _fitted:
		fit(get_viewport().get_visible_rect().size)


## Put the picture on. If it has not been imported — which is the editor's business and not
## this screen's — the pixels are read straight out of the file instead, and if there is no
## file at all the layer becomes its placeholder colour. A missing picture is a colour, and
## never a hole for the sky to show through.
func _wear() -> void:
	var tex: Texture2D = null
	if art != "":
		# load() refuses an unimported picture out loud, and this screen's quiet is worth
		# more than the shortcut: go to the cache only when there is a cache to go to. It is
		# also correct in an exported build, where the raw picture no longer exists.
		if ResourceLoader.exists(art):
			tex = load(art) as Texture2D
		if tex == null:
			var img: Image = Image.load_from_file(art)
			if img != null:
				img.generate_mipmaps()
				tex = ImageTexture.create_from_image(img)
	if tex != null:
		texture = tex
		return
	var block := ColorRect.new()
	block.name = "Placeholder"
	block.color = placeholder
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(block)
	block.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Cut this layer to the frame it is filling, or — for a placed layer — simply remember where
## it was put. Called by the title root once the frame is known, and safe to call again if
## the window ever changes size.
func fit(frame: Vector2) -> void:
	_fitted = true
	if frame.x <= 0.0 or frame.y <= 0.0:
		return
	if not full_bleed:
		_rest = position
		_limit = strength
		return
	var full: Vector2 = frame * overscan
	size = full
	_rest = (frame - full) * 0.5
	_limit = frame * (overscan - 1.0) * 0.5
	position = _rest


## Where the layer sits for a mouse offset of -1..1 on each axis, at a moment in its own slow
## breath. The offset is already smoothed by the caller; all that happens here is the scale by
## this layer's own distance, the adding of the drift, and the clamp into the margin the
## overscan bought — so the picture stays edge to edge however hard the player throws the
## mouse at a corner and however far the breath has carried it.
func travel(normalized: Vector2, t: float = 0.0) -> void:
	var sway: Vector2 = Vector2.ZERO
	if idle_strength != Vector2.ZERO:
		# two sines at a ratio that never quite repeats, rather than one: a layer sliding
		# back and forth on a single axis is a layer on rails, and the eye spots rails
		var a: float = (t + idle_phase) * TAU * idle_speed
		sway = Vector2(sin(a), sin(a * 0.73 + 1.3)) * idle_strength
	position = _rest + ((normalized * strength) + sway).clamp(-_limit, _limit)