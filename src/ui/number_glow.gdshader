shader_type canvas_item;
// The light behind the Number (D087): a soft glow fading into the black,
// with smoke swirling close about the Number and faint motes caught in it, like a lamp
// in a hazy room, and the range's haze when it's shown (D088). One quad over
// the arena, so it costs one pass; the arena drives its colour and strength,
// breathing and flaring.

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
// Smoke: wisps held close about the Number, within about this radius, this
// size, and this bright against the light; and a lighter haze through the
// wider light, thinning and thickening it by this much.
uniform float smoke_radius_px = 58.0;
uniform float smoke_scale_px = 34.0;
uniform float smoke_gain = 1.3;
uniform float haze_depth = 0.25;
// Motes: one may sit in each cell this many points across, this share of
// cells hold one, and this is how bright a lit one is.
uniform float mote_cell_px = 22.0;
uniform float mote_share = 0.22;
uniform float mote_strength = 0.5;
// A trace of per-pixel grain, so the light's gradient never bands.
uniform float dither = 0.04;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float billows(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		v += a * value_noise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 px = UV * rect_px;
	float d = length(px - centre_px) / radius_px;
	float light = strength * exp(-d * d * 2.2);
	float edge = length(px - centre_px) - range_px;
	float spread = edge < 0.0 ? 16.0 : 3.0;
	light += range_strength * exp(-(edge * edge) / (spread * spread));

	float t = TIME;
	vec2 rel = px - centre_px;
	float r = length(rel);
	// The smoke swirls about the Number. Its turn is a slow drift plus three
	// sways whose periods (about half a minute, one and two minutes) never line
	// up, so it speeds, slows and eases back without ever repeating a cycle; it
	// never stops or turns back. The inside is wound further than the outside,
	// by an amount that breathes within bounds, so the curl never tightens into
	// rings however long the run.
	float turn = 0.22 * t + 0.9 * sin(t * 0.113) + 0.6 * sin(t * 0.047 + 1.3) + 0.35 * sin(t * 0.231 + 2.1);
	float wind = 1.1 + 0.4 * sin(t * 0.089) + 0.25 * sin(t * 0.037 + 0.7);
	float twist = turn + wind * (1.0 - smoothstep(0.0, smoke_radius_px * 1.8, r));
	vec2 q = mat2(vec2(cos(twist), sin(twist)), vec2(-sin(twist), cos(twist))) * rel / smoke_scale_px;
	float wisps = billows(q + vec2(0.0, t * 0.03) + 0.4 * vec2(sin(t * 0.07), cos(t * 0.053)));
	float held_close = exp(-(r * r) / (smoke_radius_px * smoke_radius_px));
	light += strength * smoke_gain * held_close * smoothstep(0.35, 0.85, wisps);
	// A lighter haze through the wider light, drifting up slowly.
	float haze = billows(rel / (smoke_scale_px * 2.2) + vec2(3.1, t * 0.05));
	light *= mix(1.0 - haze_depth, 1.0 + haze_depth, smoothstep(0.2, 0.8, haze));

	// Motes drifting up, each cell's row swaying its own way, twinkling slowly,
	// and seen only where the light reaches them.
	vec2 mp = px / mote_cell_px + vec2(0.0, t * 0.12);
	mp.x += 0.15 * sin(t * 0.3 + floor(mp.y) * 1.7);
	vec2 cell = floor(mp);
	float held = hash(cell + 3.7);
	vec2 at = vec2(hash(cell + 1.3), hash(cell + 7.9)) * 0.8 + 0.1;
	float gap = length((fract(mp) - at) * mote_cell_px);
	float twinkle = 0.5 + 0.5 * sin(t * (0.6 + held * 1.5) + held * 40.0);
	float lit = exp(-d * d * 1.2);
	light += step(held, mote_share) * exp(-gap * gap / 1.5) * twinkle * mote_strength * lit * step(0.001, strength);

	light = max(0.0, light * (1.0 + dither * 2.0 * (hash(floor(FRAGCOORD.xy) + floor(t * 12.0)) - 0.5)));
	COLOR = vec4(tint.rgb, light);
}
