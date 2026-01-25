shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Visual controls
uniform float desaturation : hint_range(0.0, 1.0) = 0.8;
uniform float blur_strength : hint_range(0.0, 8.0) = 1.5;
uniform float darkness : hint_range(0.0, 1.0) = 0.55;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float vignette_smoothness : hint_range(0.0, 1.0) = 0.4;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 pixel = SCREEN_PIXEL_SIZE * blur_strength * progress;

	// ---- BLUR (9-tap, cheap but good) ----
	vec4 blur =
		texture(screen_texture, uv) * 0.2 +
		texture(screen_texture, uv + vec2( pixel.x, 0.0)) * 0.1 +
		texture(screen_texture, uv - vec2( pixel.x, 0.0)) * 0.1 +
		texture(screen_texture, uv + vec2(0.0,  pixel.y)) * 0.1 +
		texture(screen_texture, uv - vec2(0.0,  pixel.y)) * 0.1 +
		texture(screen_texture, uv + pixel) * 0.1 +
		texture(screen_texture, uv - pixel) * 0.1 +
		texture(screen_texture, uv + vec2( pixel.x, -pixel.y)) * 0.05 +
		texture(screen_texture, uv + vec2(-pixel.x,  pixel.y)) * 0.05;

	vec3 color = blur.rgb;

	// ---- DESATURATION ----
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(gray), desaturation * progress);

	// ---- VIGNETTE ----
	vec2 center = vec2(0.5);
	float dist = distance(uv, center);
	float vignette = smoothstep(
		0.75 - vignette_smoothness,
		0.75,
		dist * (1.0 + vignette_intensity * progress)
	);

	// ---- DARKEN FOR UI CONTRAST ----
	color *= 1.0 - (darkness * progress);
	color *= 1.0 - vignette * progress * 0.8;

	COLOR = vec4(color, 1.0);
}
