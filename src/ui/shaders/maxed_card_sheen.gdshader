shader_type canvas_item;
render_mode unshaded;

// Static brushed gold: a soft diagonal highlight, kept behind the text.
// Pixel-space rounding follows both the small active slots and taller tiles.
uniform vec2 card_size = vec2(100.0);

void fragment() {
	vec2 extent = max(card_size, vec2(1.0));
	vec2 q = abs((UV - vec2(0.5)) * extent) - extent * 0.5 + vec2(6.0);
	float distance_to_edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - 6.0;
	float mask = 1.0 - smoothstep(-0.7, 0.7, distance_to_edge);
	float diagonal = UV.x * 0.7 + UV.y * 0.3;
	float highlight = exp(-pow((diagonal - 0.38) / 0.16, 2.0));
	vec3 gold = mix(vec3(0.56, 0.35, 0.10), vec3(1.0, 0.86, 0.50), highlight);
	COLOR = vec4(gold, (0.08 + highlight * 0.17) * mask);
}
