shader_type canvas_item;

// The picture is not well.
//
// Every frame this samples what has already been drawn underneath it and puts it
// back slightly wrong: rows tear sideways in bands, the colour channels come
// apart, a bright band rolls down the screen like a bad sync, scanlines crawl,
// and a little noise sits on top of everything. `strength` is how far gone the
// room is (0..1, set per area), `burst` is a momentary tear, and `roll` is the
// position of the sync band (-1 = none).

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float burst : hint_range(0.0, 1.0) = 0.0;
uniform float roll = -1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME;

	// ── rows tear sideways, in bands ──────────────────────────────
	// kept small on purpose: this is a picture that is unwell, not one that has
	// been destroyed — the room underneath has to stay readable
	float band = floor(uv.y * 96.0);
	float tear = hash(vec2(band, floor(t * 9.0))) - 0.5;
	uv.x += tear * (strength * 0.004 + burst * 0.008);

	// ── the colour channels come apart ────────────────────────────
	float split = strength * 0.0016 + burst * 0.006;
	vec4 c;
	c.r = texture(screen_tex, uv + vec2(split, 0.0)).r;
	c.g = texture(screen_tex, uv).g;
	c.b = texture(screen_tex, uv - vec2(split, 0.0)).b;
	c.a = 1.0;

	// ── a bright band rolls down, smearing what it passes ─────────
	if (roll >= 0.0) {
		float d = abs(uv.y - roll);
		float m = smoothstep(0.07, 0.0, d);
		vec4 smear = texture(screen_tex, uv + vec2(0.02 * m, 0.0));
		c.rgb = mix(c.rgb, smear.rgb * 1.35, m * 0.75);
	}

	// ── scanlines, and a crawling darkness ────────────────────────
	float scan = 0.94 + 0.06 * sin(uv.y * 400.0 + t * 7.0);
	c.rgb *= mix(1.0, scan, strength * 0.5 + burst * 0.4);

	// ── noise ─────────────────────────────────────────────────────
	float n = hash(uv * vec2(320.0, 180.0) + floor(t * 24.0));
	c.rgb += (n - 0.5) * (0.03 * strength + 0.07 * burst);

	// ── dropout: single dead cells, black or blown out ────────────
	float cell = hash(floor(uv * vec2(160.0, 90.0)) + floor(t * 12.0));
	float dead = step(0.9994 - strength * 0.0006 - burst * 0.01, cell);
	c.rgb = mix(c.rgb, vec3(step(0.5, cell) * 1.5), dead * (strength * 0.35 + burst * 0.5));

	// ── the edges of the room are darker than the middle ──────────
	c.rgb *= 1.0 - distance(uv, vec2(0.5)) * (0.16 + strength * 0.24);

	COLOR = c;
}
