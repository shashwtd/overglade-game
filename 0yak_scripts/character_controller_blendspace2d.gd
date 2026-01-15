extends CharacterBody3D

@export var move_speed := 5.0
@export var crouch_speed := 2.5
@export var jump_velocity := 4.5
@export var acceleration := 10.0
@export var blend_speed := 8.0
@export var crouch_blend_speed := 6.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var anim_tree: AnimationTree = $Brute/AnimationTree

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var blend_position := Vector2.ZERO
var crouch_blend := 0.0
var is_crouching := false

func _ready() -> void:
	anim_tree.active = true

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Jump (only when grounded and not crouching)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity
		anim_tree.set("parameters/JumpOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	# Crouch toggle
	if Input.is_action_just_pressed("crouch"):
		is_crouching = not is_crouching
	
	# Get input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Movement relative to camera
	var cam_basis := camera_pivot.global_transform.basis
	var direction := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0
	
	# Current speed based on crouch state
	var current_speed := crouch_speed if is_crouching else move_speed
	
	# Apply movement
	if direction:
		velocity.x = lerp(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, acceleration * delta)
	
	move_and_slide()
	
	# Locomotion blend
	var target_blend := Vector2(input_dir.x, -input_dir.y)
	blend_position = blend_position.lerp(target_blend, blend_speed * delta)
	anim_tree.set("parameters/Locomotion/blend_position", blend_position)
	
	# Crouch blend (smooth transition)
	var target_crouch := 1.0 if is_crouching else 0.0
	crouch_blend = lerpf(crouch_blend, target_crouch, crouch_blend_speed * delta)
	anim_tree.set("parameters/CrouchBlend/blend_amount", crouch_blend)
