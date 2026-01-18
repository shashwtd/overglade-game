@tool
extends Node3D

@export_tool_button("Create Lighting Setup") var create_action = create_lighting

func create_lighting() -> void:
	# Create WorldEnvironment
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	
	var env := Environment.new()
	
	# Sky
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.4, 0.6, 0.9)
	sky_mat.sky_horizon_color = Color(0.7, 0.8, 0.9)
	sky_mat.ground_bottom_color = Color(0.3, 0.25, 0.2)
	sky_mat.ground_horizon_color = Color(0.5, 0.5, 0.5)
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	
	# Ambient light from sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.4
	
	# Tonemap
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	
	world_env.environment = env
	add_child(world_env)
	world_env.owner = get_tree().edited_scene_root
	
	# Create DirectionalLight3D
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.95, 0.9)  # Warm
	sun.shadow_enabled = true
	sun.shadow_blur = 1.0
	add_child(sun)
	sun.owner = get_tree().edited_scene_root
	
	print("Lighting setup created!")
