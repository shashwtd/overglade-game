shader_type spatial;

uniform vec4 water_color : source_color = vec4(0.1, 0.4, 0.6, 0.95);
uniform float wave_speed = 0.4;
uniform float wave_height = 0.04;
uniform float wave_scale = 0.05;

void vertex() {
	float wave = sin(VERTEX.x * wave_scale + TIME * wave_speed) 
	           + cos(VERTEX.z * wave_scale + TIME * wave_speed * 0.8);
	VERTEX.y += wave * wave_height;
}

void fragment() {
	ALBEDO = water_color.rgb;
	ALPHA = water_color.a;
	METALLIC = 0.3;
	ROUGHNESS = 0.1;
}