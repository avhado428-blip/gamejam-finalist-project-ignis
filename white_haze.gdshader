shader_type canvas_item;
// PERCEIVED WORLD overlay: pale, eerie, white-hazed, uncanny stillness.
// Full-screen pass that desaturates + washes everything toward pale white
// and adds a very slow, barely-moving fog drift.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;
uniform float wash : hint_range(0.0, 1.0) = 0.30;
uniform float desaturate : hint_range(0.0, 1.0) = 0.45;
uniform float fog : hint_range(0.0, 1.0) = 0.30;
uniform vec3 tint = vec3(0.945, 0.945, 0.958);
uniform float drift_speed = 0.10;
uniform float wobble : hint_range(0.0, 0.01) = 0.0012;
uniform float second_image : hint_range(0.0, 1.0) = 0.10;

void fragment() {
	vec2 uv = SCREEN_UV;
	// slow positional wobble — "something is off about this room"
	vec2 offs = vec2(
		sin(uv.y * 18.0 + TIME * drift_speed) * wobble,
		cos(uv.x * 14.0 + TIME * drift_speed * 0.8) * wobble
	);
	vec3 c = texture(screen_tex, uv + offs).rgb;
	// a faint second image, always looking slightly elsewhere than the first
	vec2 g_off = offs + vec2(second_image * (0.004 + 0.002 * sin(TIME * 0.21)), second_image * 0.003);
	vec3 ghost = texture(screen_tex, uv + g_off).rgb;
	c = mix(c, ghost, second_image * 0.6);
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(lum), desaturate);
	// a cold cast that scales with luminance, so darks stay dark and only the
	// light parts go sickly pale — contrast survives, which is what reads as eerie
	c = mix(c, tint * (0.55 + 0.45 * lum), wash);
	float band = sin(uv.y * 22.0 + TIME * drift_speed * 1.6) * 0.5 + 0.5;
	c += fog * band * 0.03;
	c += fog * 0.02 * (1.0 - uv.y);
	COLOR = vec4(c, 1.0);
}
