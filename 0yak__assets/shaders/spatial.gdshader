shader_type spatial;

uniform sampler2D albedo_texture;
uniform float height_scale = 4.0;
uniform float noise_scale = 0.05;
uniform float uv_scale = 10;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) +
		   (c - a) * u.y * (1.0 - u.x) +
		   (d - b) * u.x * u.y;
}

void vertex() {
	float n = noise(VERTEX.xz * noise_scale);
	VERTEX.y += n * height_scale;
}

void fragment() {
	vec2 tiled_uv = UV * uv_scale;
	ALBEDO = texture(albedo_texture, tiled_uv).rgb;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;

}
