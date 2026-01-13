extends MeshInstance3D

@export var height: float = 4.0
@export var noise_scale: float = 0.05

func _ready():
	if mesh == null:
		return

	var mdt := MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)

	var noise := FastNoiseLite.new()
	noise.frequency = noise_scale

	for i in range(mdt.get_vertex_count()):
		var v: Vector3 = mdt.get_vertex(i)
		v.y += noise.get_noise_2d(v.x, v.z) * height
		mdt.set_vertex(i, v)

	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)

	mdt.clear()
