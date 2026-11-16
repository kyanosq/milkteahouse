shader_type canvas_item;
render_mode unshaded;
varying vec4 tint;

void vertex() { tint = COLOR; }

// Painted props share the live scene's soft color bands; alpha and UI text stay intact.
void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	vec2 texel = TEXTURE_PIXEL_SIZE * 2.0;
	vec4 soft = (texture(TEXTURE, UV + vec2(texel.x, 0.0))
		+ texture(TEXTURE, UV - vec2(texel.x, 0.0))
		+ texture(TEXTURE, UV + vec2(0.0, texel.y))
		+ texture(TEXTURE, UV - vec2(0.0, texel.y))) * 0.25;
	vec3 paint = mix(ink.rgb, soft.rgb, 0.45 * step(0.98, soft.a));
	float value = max(max(paint.r, paint.g), paint.b);
	float band = floor(value * 7.0) / 7.0;
	float tone = mix(value, band, 0.38);
	paint *= (0.12 + tone * 0.84) / max(value, 0.001);
	paint = mix(paint, vec3(dot(paint, vec3(0.2126, 0.7152, 0.0722))), 0.05);
	paint *= vec3(0.985, 1.01, 1.045);
	COLOR = tint * vec4(paint, ink.a);
}
