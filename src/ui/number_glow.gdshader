shader_type canvas_item;
// The light behind the Number (D087): a soft glow fading into the black, with
// fine, gently drifting grain in it, and the range's haze when it's shown
// (D088). One quad over the arena, so it costs next to nothing; the arena
// drives its colour and strength, breathing and flaring.

uniform vec2 centre_px;
uniform vec2 rect_px = vec2(390.0, 500.0);
uniform float radius_px = 110.0;
uniform vec4 tint : source_color = vec4(1.0);
// Nothing until the arena lights it.
uniform float strength = 0.0;
// The range, when the player shows it (D088): a haze that thickens toward its
// edge from inside and stops soon after, rather than a line.
uniform float range_px = 125.0;
uniform float range_strength = 0.0;
// How much the grain jitters the light, as a share of it, and how many times
// a second it drifts to a new pattern.
uniform float grain = 0.12;
uniform float grain_rate = 6.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 px = UV * rect_px;
	float d = length(px - centre_px) / radius_px;
	float light = strength * exp(-d * d * 2.2);
	float edge = length(px - centre_px) - range_px;
	float spread = edge < 0.0 ? 16.0 : 3.0;
	light += range_strength * exp(-(edge * edge) / (spread * spread));
	// Grain per screen pixel, only where there is light, so the black stays
	// black. It eases from one pattern into the next rather than cutting, so it
	// drifts like haze instead of flickering like static.
	float t = TIME * grain_rate;
	float n = mix(hash(floor(FRAGCOORD.xy) + floor(t) * 17.0), hash(floor(FRAGCOORD.xy) + (floor(t) + 1.0) * 17.0),
		smoothstep(0.0, 1.0, fract(t))) - 0.5;
	light = max(0.0, light * (1.0 + grain * 2.0 * n));
	COLOR = vec4(tint.rgb, light);
}
