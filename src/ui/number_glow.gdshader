shader_type canvas_item;
// The light behind the Number (D087): a soft glow fading into the black, with
// fine film grain in it, and the range's haze when it's shown (D088). One quad over the arena, so it costs next to nothing;
// the arena drives its colour and strength, breathing and flaring.

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
// How much the grain jitters the light, as a share of it.
uniform float grain = 0.3;

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
	// Grain per screen pixel, reseeded 24 times a second like film, and only
	// where there is light, so the black stays black.
	float n = hash(floor(FRAGCOORD.xy) + floor(TIME * 24.0) * 17.0) - 0.5;
	light = max(0.0, light * (1.0 + grain * 2.0 * n));
	COLOR = vec4(tint.rgb, light);
}
