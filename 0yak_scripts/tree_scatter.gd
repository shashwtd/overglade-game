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
	var max_attempts := tree_count * 3  # Avoid infinite loop
	
	while placed < tree_count and attempts < max_attempts:
		attempts += 1
		
		# Random position in radius
		var random_pos := global_position + Vector3(
			randf_range(-scatter_radius, scatter_radius),
			raycast_height,
			randf_range(-scatter_radius, scatter_radius)
		)
		
		# Raycast down to find terrain
		var query := PhysicsRayQueryParameters3D.create(
			random_pos,
			random_pos + Vector3.DOWN * raycast_depth
		)
		var result := space_state.intersect_ray(query)
		
		if result:
			var tree := tree_scene.instantiate()
			add_child(tree)
			tree.owner = get_tree().edited_scene_root
			
			# Place on surface
			tree.global_position = result.position
			
			# Align to surface normal (optional, makes trees tilt with terrain)
			# tree.global_transform = align_to_normal(tree.global_transform, result.normal)
			
			# Random Y rotation
			tree.rotation.y = randf() * TAU
			
			# Random scale
			var scale_factor := randf_range(min_scale, max_scale)
			tree.scale = Vector3.ONE * scale_factor
			
			placed += 1
	
	print("Placed ", placed, " trees")

func clear_trees() -> void:
	for child in get_children():
		child.queue_free()
	print("Cleared all trees")

# Optional: Align tree to surface normal
func align_to_normal(xform: Transform3D, normal: Vector3) -> Transform3D:
	var up := normal
	var forward := Vector3.FORWARD
	if abs(up.dot(forward)) > 0.99:
		forward = Vector3.RIGHT
	var right := up.cross(forward).normalized()
	forward = right.cross(up).normalized()
	
	xform.basis = Basis(right, up, forward)
	return xform
