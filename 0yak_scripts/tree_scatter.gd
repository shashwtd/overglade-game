@tool
extends Node3D

@export var tree_scene: PackedScene
@export var tree_count := 100
@export var scatter_radius := 50.0
@export var min_scale := 0.8
@export var max_scale := 1.2
@export var raycast_height := 100.0
@export var raycast_depth := 200.0

@export_tool_button("Generate Trees") var generate_action = generate_trees
@export_tool_button("Clear Trees") var clear_action = clear_trees

func generate_trees() -> void:
	if not tree_scene:
		push_warning("Set tree_scene first!")
		return
	
	var space_state := get_world_3d().direct_space_state
	var placed := 0
	var attempts := 0
	var max_attempts := tree_count * 3
	
	while placed < tree_count and attempts < max_attempts:
		attempts += 1
		
		# --- CIRCULAR DISTRIBUTION ---
		var angle := randf() * TAU
		var radius := sqrt(randf()) * scatter_radius
		
		var offset := Vector3(
			cos(angle) * radius,
			raycast_height,
			sin(angle) * radius
		)
		
		var random_pos := global_position + offset
		
		# Raycast down to terrain
		var query := PhysicsRayQueryParameters3D.create(
			random_pos,
			random_pos + Vector3.DOWN * raycast_depth
		)
		
		var result := space_state.intersect_ray(query)
		
		if result:
			var tree := tree_scene.instantiate()
			add_child(tree)
			tree.owner = get_tree().edited_scene_root
			
			tree.global_position = result.position
			
			# Random Y rotation
			tree.rotation.y = randf() * TAU
			
			# Random uniform scale
			var scale_factor := randf_range(min_scale, max_scale)
			tree.scale = Vector3.ONE * scale_factor
			
			placed += 1
	
	print("Placed ", placed, " trees")

func clear_trees() -> void:
	for child in get_children():
		child.queue_free()
	print("Cleared all trees")
