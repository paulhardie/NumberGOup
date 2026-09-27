shader_type canvas_item;
// The light behind the Number, as the owner's main-screen design draws it
// (D096): a wide halo that breathes, slowly growing and brightening, and a
// small soft bloom at its heart, both in a warm white. One quad, one pass; the
// arena (or Home) drives where it sits, its breath, strength and tint.

uniform vec2 centre_px;
// The light's rectangle in its own points, so UV maps to them.
uniform vec2 rect_px = vec2(390.0, 500.0);
// The design's warm white; a flare tints it (a ÷ turns it violet).
uniform vec4 tint : source_color = vec4(1.0, 0.957, 0.902, 1.0);
// 1 is the design's light; a flare adds to it. Nothing until it's lit.
uniform float strength = 0.0;
// Where the breath is, 0 at its faintest and smallest, 1 at its fullest.
uniform float breath = 0.0;
// The halo reaches this far at rest, and grows by `breath_grow` at its fullest.
uniform float halo_px = 190.0;
uniform float breath_grow = 0.05;
// The bloom's soft width: the design's 150 px cone under an 18 px blur.
uniform float bloom_px = 35.0;
// A trace of per-pixel grain, so the gradient never bands on a phone.
uniform float dither = 0.012;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 px = UV * rect_px;
	float r = length(px - centre_px);
	// The halo: the design's radial gradient, 13% at the centre, 5% a third of
	// the way out and nothing just past two thirds, over its circle's corner
	// distance (√2 × its radius), scaled and brightened by the breath.
	float corner = halo_px * sqrt(2.0) * (1.0 + breath_grow * breath);
	float t = r / corner;
	float halo = t < 0.34 ? mix(0.13, 0.05, t / 0.34) : mix(0.05, 0.0, clamp((t - 0.34) / 0.34, 0.0, 1.0));
	halo *= mix(0.82, 1.0, breath);
	// The bloom: 34% at the heart of a cone softened by the blur, which comes
	// to about a quarter at the centre, falling away like a bell.
	float bloom = 0.25 * exp(-(r * r) / (2.0 * bloom_px * bloom_px));
	float light = 1.0 - (1.0 - clamp(halo * strength, 0.0, 1.0)) * (1.0 - clamp(bloom * strength, 0.0, 1.0));
	light += (hash(floor(FRAGCOORD.xy)) - 0.5) * dither * step(0.002, light);
	COLOR = vec4(tint.rgb, clamp(light, 0.0, 1.0));
}
