shader_type canvas_item;
// Winter dark: a small circle of sight around the squirrel and pools of lamp
// light; the edge is dithered in 2px steps so it stays pixel-art.

uniform vec2 center = vec2(192.0, 108.0);
uniform float radius = 60.0;
uniform float strength = 0.94;
uniform vec2 lamps[3];
uniform vec4 tint : source_color = vec4(0.05, 0.07, 0.14, 1.0);

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec2 p = floor(UV * vec2(384.0, 216.0));
	float d = length(p - center);
	float v = smoothstep(radius * 0.55, radius, d);
	for (int i = 0; i < 3; i++) {
		float l = length((p - lamps[i]) * vec2(1.0, 1.4));
		v = min(v, 0.35 + 0.65 * smoothstep(10.0, 30.0, l));
	}
	ivec2 q = ivec2(mod(floor(p / 2.0), 4.0));
	float b = (BAYER[q.y * 4 + q.x] + 0.5) / 16.0;
	float a = (v > b) ? 1.0 : 0.0;
	// keep a faint view of the world even in the dark
	COLOR = vec4(tint.rgb, mix(v * 0.55, 1.0, a * 0.95) * strength);
}
