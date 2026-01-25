shader_type spatial;
render_mode cull_disabled;

// Your original values preserved
uniform vec4 water_color : source_color = vec4(0.1, 0.4, 0.6, 0.95);
uniform float wave_speed = 0.4;
uniform float wave_height = 0.04;
uniform float wave_scale = 0.05;

// New: Extra detail
uniform vec4 foam_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform float foam_amount = 0.15;
uniform float ripple_strength = 0.02;

void vertex() {
	// Multiple wave layers for more natural motion
	float wave1 = sin(VERTEX.x * wave_scale + TIME * wave_speed);
	float wave2 = cos(VERTEX.z * wave_scale * 0.8 + TIME * wave_speed * 0.9);
	float wave3 = sin((VERTEX.x + VERTEX.z) * wave_scale * 0.5 + TIME * wave_speed * 1.1) * 0.5;

	float wave = wave1 + wave2 + wave3;
	VERTEX.y += wave * 0.3 *  wave_height;
}

void fragment() {
	// Fresnel effect - edges look different than center
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 3.0);

	// Fake ripples using UV distortion
	float ripple = sin(UV.x * 40.0 + TIME * 2.0) * cos(UV.y * 40.0 + TIME * 1.5);

	// Mix base color with lighter edge color
	vec3 deep_color = water_color.rgb * 0.7;
	vec3 surface_color = water_color.rgb * 1.3;
	vec3 final_color = mix(deep_color, surface_color, fresnel);

	// Add foam on wave peaks (fake it with noise pattern)
	float foam = smoothstep(0.3, 0.7, sin(UV.x * 20.0 + TIME) * cos(UV.y * 20.0 - TIME * 0.5));
	final_color = mix(final_color, foam_color.rgb, foam * foam_amount * fresnel);

	// Perturb normal for ripple reflections
	vec3 ripple_normal = NORMAL;
	ripple_normal.x += ripple * ripple_strength;
	ripple_normal.z += ripple * ripple_strength * 0.5;
	ripple_normal = normalize(ripple_normal);

	ALBEDO = final_color;
	ALPHA = water_color.a;
	METALLIC = 0.4;
	ROUGHNESS = 0.05;
	SPECULAR = 0.8;
	NORMAL = ripple_normal;
}