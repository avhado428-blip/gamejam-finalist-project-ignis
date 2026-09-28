class_name GlowEye
extends RefCounted
## A glowing eye, drawn from maths when it is asked for.
##
## The ending needs the only *alive* thing on screen, and a pair of rectangles
## with a halo behind them does not read as alive — it reads as two rectangles.
## This builds a proper eye instead: a lens whose lids are arcs, a bright iris
## ring, a vertical slit pupil (nothing in this game with a round pupil is
## looking at you), a wet catch of light off-centre, and a halo that falls off in
## the shape of the eye rather than as a box.
##
## The texture comes out in greys on purpose. The pupil is baked near-black and
## the rest is a brightness ramp, so whatever the caller modulates it to, the
## pupil stays a hole and the light takes the tint.
##
## Static, so callers never have to hold an instance of this.

## `size` is the texture's pixel size; `tilt` slants the lids, in radians.
static func make(size: Vector2i = Vector2i(96, 64), tilt: float = -0.20) -> ImageTexture:
	var w: int = size.x
	var h: int = size.y
	var im := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	var a: float = float(w) * 0.5
	var b: float = float(h) * 0.5
	# Two lid arcs: circles of radius r whose centres sit k above and below the
	# middle, meeting exactly at the corners of a lens a wide and b tall.
	var r: float = (a * a + b * b) / (2.0 * b)
	var k: float = r - b
	var ct: float = cos(tilt)
	var st: float = sin(tilt)
	for y in h:
		for x in w:
			var px: float = float(x) + 0.5 - a
			var py: float = float(y) + 0.5 - b
			# rotate the sample into the eye's own frame so the lids slant
			var qx: float = px * ct + py * st
			var qy: float = -px * st + py * ct
			var inside: bool = Vector2(qx, qy - k).length() <= r and Vector2(qx, qy + k).length() <= r
			var norm: float = sqrt((qx / a) * (qx / a) + (qy / b) * (qy / b))
			if inside:
				var body: float = 0.34 * (1.0 - minf(1.0, norm) * minf(1.0, norm))
				var ring: float = exp(-pow((norm - 0.70) / 0.20, 2.0))
				var core: float = exp(-pow(norm / 0.34, 2.0))
				var ink: float = clampf(body + 0.95 * ring + 0.75 * core, 0.0, 1.0)
				# a vertical slit pupil, tapering to a point at either end
				var taper: float = sqrt(maxf(0.0, 1.0 - minf(1.0, absf(qy) / b) * minf(1.0, absf(qy) / b)))
				if absf(qx) <= a * 0.15 * taper:
					ink = 0.03
				# and the catch of light that makes it wet, off to one side
				var d: float = Vector2(qx + a * 0.34, qy + b * 0.36).length()
				ink = clampf(ink + 0.85 * exp(-pow(d / (b * 0.24), 2.0)), 0.0, 1.0)
				im.set_pixel(x, y, Color(ink, ink, ink, 1.0))
			else:
				# outside the lens, the same falloff keeps the halo eye-shaped
				var g: float = exp(-maxf(0.0, norm - 1.0) * 3.4) * 0.5
				if g > 0.004:
					im.set_pixel(x, y, Color(g, g, g, minf(1.0, g * 1.5)))
	return ImageTexture.create_from_image(im)
