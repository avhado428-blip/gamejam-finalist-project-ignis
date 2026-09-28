shader_type canvas_item;
// Brief shift flash. `strength` (0..1) is driven from code.

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float scanlines = 220.0;

void fragment() {
	float a = strength;
	// faint scanline texture so the flash reads as "signal", not pure white
	float line = 0.9 + 0.1 * sin(FRAGCOORD.y * scanlines);
	COLOR = vec4(flash_color.rgb, flash_color.a * a * line);
}
