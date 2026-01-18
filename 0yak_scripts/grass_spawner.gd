@tool
extends MultiMeshInstance3D

@export var grass_mesh: Mesh
@export var grass_count := 50000
@export var radius := 80.0

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() and event is InputEventKey:
		if event.pressed and event.keycode == KEY_G:
			spawn_grass()

func spawn_grass() -> void:
	print("Spawning grass...")
	
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = grass_mesh
	mm.instance_count = grass_count
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var space_state := get_world_3d().direct_space_state
	var placed := 0
	
	for i in grass_count:
		var angle := randf() * TAU
		var dist := sqrt(randf()) * radius
		
		var ray_start := Vector3(cos(angle) * dist, 100.0, sin(angle) * dist)
		var ray_end := ray_start + Vector3.DOWN * 200.0
		
		var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		var result := space_state.intersect_ray(query)
		
		if result:
			var xform := Transform3D()
			xform.origin = result.position
			xform = xform.rotated(Vector3.UP, randf() * TAU)
			xform = xform.scaled(Vector3.ONE * randf_range(0.6, 1.2))
			mm.set_instance_transform(placed, xform)
			placed += 1
	
	mm.instance_count = placed
	multimesh = mm
	print("Done! Placed: ", placed)
