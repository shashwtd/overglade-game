extends CharacterBody3D

# Character Controller - FIXED for your setup
# BlendSpace2D path: parameters/BlendSpace2D/blend_position

@export var speed: float = 6.0
@export var jump_velocity: float = 4.5

@onready var brute: Node3D = $Brute
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var anim_tree: AnimationTree = $Brute/AnimationTree
@onready var anim_player: AnimationPlayer = $Brute/AnimationPlayer

func _ready():
	print("=== Character Controller Starting ===")
	
	# Make animations loop
	if anim_player:
		for anim_name in anim_player.get_animation_list():
			var animation: Animation = anim_player.get_animation(anim_name)
			var name_lower: String = anim_name.to_lower()
			if "walk" in name_lower or "idle" in name_lower:
				animation.loop_mode = Animation.LOOP_LINEAR
		print("✓ Animations set to loop")
	
	# Activate AnimationTree
	if anim_tree:
		anim_tree.active = true
		print("✓ AnimationTree activated")
	
	# Fix root motion
	fix_root_motion()
	
	print("✓ Ready!")

func fix_root_motion():
	"""Disable root position tracks to prevent sliding"""
	if not anim_player:
		return
	
	var fixed_count: int = 0
	for anim_name in anim_player.get_animation_list():
		var name_lower: String = anim_name.to_lower()
		if "walk" in name_lower or "turn" in name_lower:
			var animation: Animation = anim_player.get_animation(anim_name)
			for track_idx in range(animation.get_track_count()):
				var track_path: NodePath = animation.track_get_path(track_idx)
				var path_str: String = str(track_path)
				if ":position" in path_str:
					var node_name: String = track_path.get_name(0)
					if node_name in ["Armature", ".", "Skeleton3D", "Brute", "RootNode", "GeneralSkeleton"]:
						animation.track_set_enabled(track_idx, false)
						fixed_count += 1
	
	if fixed_count > 0:
		print("✓ Disabled ", fixed_count, " root motion tracks")

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get input
	var input_right: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var input_forward: float = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	
	# Blend position for BlendSpace2D
	var blend_position: Vector2 = Vector2(input_right, input_forward)

	# Camera-relative movement
	var cam_basis: Basis = camera.global_transform.basis
	var cam_forward: Vector3 = -cam_basis.z
	var cam_right: Vector3 = cam_basis.x
	cam_forward.y = 0
	cam_right.y = 0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var move_dir: Vector3 = cam_right * input_right + cam_forward * input_forward
	
	# Apply movement
	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	# UPDATE BLENDSPACE2D - Using YOUR correct parameter path!
	anim_tree.set("parameters/BlendSpace2D/blend_position", blend_position)

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
