shader_type spatial;
render_mode cull_disabled;

uniform vec3 color : source_color = vec3(0.0, 0.396, 0.0);
uniform vec3 color2 : source_color = vec3(0.0, 0.765, 0.404);
uniform sampler2D noise;
uniform float noiseScale = 20.0;
uniform float wind_strength = 0.08;
uniform float wind_speed = 2.0;

varying vec3 worldPos;

void vertex() {
	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Wind - only affects top of grass
	float height_factor = VERTEX.y;
	
	float wind = sin(worldPos.x * 0.5 + TIME * wind_speed) 
	           + sin(worldPos.z * 0.3 + TIME * wind_speed * 0.8);
	
	VERTEX.x += wind * wind_strength * height_factor;
	VERTEX.z += wind * wind_strength * height_factor * 0.3;
}

void fragment() {
	vec3 noiseLevel = texture(noise, worldPos.xz / noiseScale).rgb;
	ALBEDO = mix(color, color2, 1.0 - UV.y) * mix(color, color2, noiseLevel.r);
	
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}