shader_type canvas_item;
// Restrained reality-shift glitch: horizontal block displacement + chromatic
// aberration. `amount` is driven from code (0 = invisible, 1 = full).

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float block_rows = 40.0;
uniform float displace : hint_range(0.0, 0.1) = 0.018;
uniform float chroma : hint_range(0.0, 0.05) = 0.0045;

void fragment() {
	if (amount <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		vec2 uv = SCREEN_UV;
		float row = floor(uv.y * block_rows);
		float n = fract(sin(row * 12.9898 + floor(TIME * 24.0) * 0.37) * 43758.5453);
		float shift = (n - 0.5) * displace * amount;
		vec2 u = uv + vec2(shift, 0.0);
		float sp = chroma * amount;
		vec3 c;
		c.r = texture(screen_tex, u + vec2(sp, 0.0)).r;
		c.g = texture(screen_tex, u).g;
		c.b = texture(screen_tex, u - vec2(sp, 0.0)).b;
		// sparse bright tear lines
		float tear = step(0.985, n);
		c += tear * amount * vec3(0.85, 0.95, 1.0) * 0.5;
		COLOR = vec4(c, 1.0);
	}
}
