extends CharacterBody3D

# Complete Character Controller
# Features: BlendSpace2D movement, Turn transitions, Jump, Crouch

@export var speed: float = 4.0
@export var crouch_speed: float = 3.0
@export var jump_velocity: float = 6

@onready var brute: Node3D = $Brute
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var anim_tree: AnimationTree = $Brute/AnimationTree
@onready var anim_player: AnimationPlayer = $Brute/AnimationPlayer
@onready var state_machine: AnimationNodeStateMachinePlayback = null

# State tracking
var is_crouching: bool = false
var is_jumping: bool = false
var was_moving_left: bool = false
var was_moving_right: bool = false
var current_blend: Vector2 = Vector2.ZERO

# Turn animation tracking
var is_turning: bool = false
var turn_timer: float = 0.0
var turn_duration: float = 0.3  # How long turn animation plays before walk kicks in

func _ready():
	print("=== Character Controller with Turns/Jump/Crouch ===")
	
	# Setup animations to loop
	if anim_player:
		for anim_name in anim_player.get_animation_list():
			var animation: Animation = anim_player.get_animation(anim_name)
			var name_lower: String = anim_name.to_lower()
			# Loop walk, idle, crouch idle animations
			if "walk" in name_lower or "idle" in name_lower:
				animation.loop_mode = Animation.LOOP_LINEAR
		print("✓ Animations set to loop")
	
	# Activate AnimationTree and get state machine
	if anim_tree:
		anim_tree.active = true
		state_machine = anim_tree.get("parameters/playback")
		print("✓ AnimationTree activated")
	
	# Fix root motion
	fix_root_motion()
	
	print("✓ Ready!")
	print("")
	print("Controls:")
	print("  WASD - Move")
	print("  Space - Jump")
	print("  Ctrl/C - Crouch (toggle)")

func fix_root_motion():
	"""Disable root position tracks to prevent sliding"""
	if not anim_player:
		return
	
	var fixed_count: int = 0
	for anim_name in anim_player.get_animation_list():
		var name_lower: String = anim_name.to_lower()
		if "walk" in name_lower or "turn" in name_lower or "jump" in name_lower:
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
	
	# Landing detection
	if is_jumping and is_on_floor():
		is_jumping = false
		print("Landed!")

	# Get input
	var input_right: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var input_forward: float = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var blend_position: Vector2 = Vector2(input_right, input_forward)
	
	# Crouch toggle (Ctrl or C key)
	if Input.is_action_just_pressed("crouch"):
		toggle_crouch()
	
	# Jump (only if not crouching and on floor)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		do_jump()

	# Camera-relative movement
	var cam_basis: Basis = camera.global_transform.basis
	var cam_forward: Vector3 = -cam_basis.z
	var cam_right: Vector3 = cam_basis.x
	cam_forward.y = 0
	cam_right.y = 0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var move_dir: Vector3 = cam_right * input_right + cam_forward * input_forward
	
	# Apply movement (slower when crouching)
	var current_speed: float = crouch_speed if is_crouching else speed
	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * current_speed
		velocity.z = move_dir.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	# Update animations based on state
	update_animations(blend_position)
	
	# Store for next frame
	was_moving_left = input_right < -0.5
	was_moving_right = input_right > 0.5
	current_blend = blend_position

	move_and_slide()

func toggle_crouch() -> void:
	"""Toggle crouch state"""
	is_crouching = not is_crouching
	
	if state_machine:
		if is_crouching:
			state_machine.travel("CrouchIdle")
			print("→ Crouching")
		else:
			state_machine.travel("StandUp")
			print("→ Standing up")

func do_jump() -> void:
	"""Execute jump"""
	is_jumping = true
	velocity.y = jump_velocity
	
	if state_machine:
		state_machine.travel("Jump")
		print("→ Jumping!")

func update_animations(blend_position: Vector2) -> void:
	"""Update animation state based on current state"""
	
	# Skip if in special state
	if is_jumping or is_turning:
		return
	
	if is_crouching:
		# Crouching - use crouch idle (could add crouch walk later)
		if blend_position.length() > 0.1:
			# Moving while crouched - could blend crouch walk here
			pass
		# Stay in crouch idle
		return
	
	# Normal movement - update BlendSpace2D
	anim_tree.set("parameters/BlendSpace2D/blend_position", blend_position)
