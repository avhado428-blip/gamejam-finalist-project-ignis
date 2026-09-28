shader_type canvas_item;
// Global dread pass — the mood layer, always on.
// Vignette + film grain + a slow breathing pulse + a cold cast. Strength is
// driven from code per reality (heavier while PERCEIVED).

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;
uniform float vignette : hint_range(0.0, 3.0) = 1.05;
uniform float grain : hint_range(0.0, 0.3) = 0.07;
uniform float breathe : hint_range(0.0, 0.5) = 0.08;
uniform float desat : hint_range(0.0, 1.0) = 0.18;
uniform float lift : hint_range(0.0, 0.3) = 0.0;
uniform vec3 cold = vec3(0.80, 0.83, 0.92);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_tex, uv).rgb;

	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(lum) * cold, desat);
	col += lift;

	// vignette that exhales
	vec2 c = uv - 0.5;
	float d = length(c * vec2(1.12, 1.0));
	float pulse = 1.0 + breathe * sin(TIME * 0.62);
	float v = 1.0 - vignette * d * d * pulse;
	col *= clamp(v, 0.0, 1.0);

	// film grain
	float g = (hash(floor(uv * vec2(640.0, 360.0)) + vec2(floor(TIME * 12.0))) - 0.5) * grain;
	col += g;

	// the light is failing: rare, brief dips that the eye half-catches
	if (hash(vec2(floor(TIME * 3.0), 7.0)) > 0.93) {
		col *= 0.78 + 0.22 * hash(vec2(floor(TIME * 45.0), 3.0));
	}

	COLOR = vec4(col, 1.0);
}
