extends CharacterBody3D

@export var speed := 6.0
@export var jump_velocity := 4.5

@onready var brute: Node3D = $Brute
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var anim_tree: AnimationTree = $Brute/AnimationTree
@onready var anim_player: AnimationPlayer = $Brute/AnimationPlayer

func _ready():
	anim_tree.active = true
	
	# Disable root motion on all animations to prevent sliding
	if anim_player:
		for anim_name in anim_player.get_animation_list():
			var animation = anim_player.get_animation(anim_name)
			
			# Set walk/run/idle animations to loop
			if "walk" in anim_name.to_lower() or "run" in anim_name.to_lower() or "idle" in anim_name.to_lower():
				animation.loop_mode = Animation.LOOP_LINEAR
				print("Set ", anim_name, " to loop")
			
			# Disable position tracks that cause sliding
			for track_idx in range(animation.get_track_count()):
				var track_path = animation.track_get_path(track_idx)
				var path_string = str(track_path).to_lower()
				
				# Check if this is a position track on the root/armature
				if "position" in path_string:
					var node_name = track_path.get_name(0)
					# Disable root-level position tracks
					if node_name in ["Armature", ".", "Skeleton3D", "Brute", "RootNode"]:
						print("Disabling position track in ", anim_name, ": ", track_path)
						animation.track_set_enabled(track_idx, false)
	
	print("✓ BlendSpace2D movement system ready")
	print("✓ Root motion disabled - movement is now velocity-based only")

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# INPUT - camera-relative
	var input_strafe := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var input_forward := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	
	var input_vec := Vector2(input_strafe, input_forward)

	# CAMERA-RELATIVE MOVEMENT
	var cam_basis := camera.global_transform.basis
	var cam_forward := -cam_basis.z
	var cam_right := cam_basis.x
	cam_forward.y = 0
	cam_right.y = 0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	# Calculate world-space movement direction
	var move_dir := cam_right * input_strafe + cam_forward * input_forward
	
	# Apply movement (this is the ONLY thing that moves the character)
	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	# UPDATE BLENDSPACE2D
	# The blend position controls which animations blend together
	# X-axis: -1 (left) to +1 (right)
	# Y-axis: -1 (back) to +1 (forward)
	# Center (0,0): idle
	anim_tree.set("parameters/movement_blend/blend_position", input_vec)

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
