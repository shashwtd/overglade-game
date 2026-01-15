extends CharacterBody3D

@export var move_speed := 5.0
@export var jump_velocity := 4.5
@export var acceleration := 10.0
@export var blend_speed := 8.0  # How fast animations blend

@onready var camera_pivot: Node3D = $CameraPivot
@onready var anim_tree: AnimationTree = $Brute/AnimationTree

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var blend_position := Vector2.ZERO  # Current blend position

func _ready() -> void:
	anim_tree.active = true

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Get input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Movement relative to camera
	var cam_basis := camera_pivot.global_transform.basis
	var direction := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0
	
	# Apply movement
	if direction:
		velocity.x = lerp(velocity.x, direction.x * move_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * move_speed, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, acceleration * delta)
	
	move_and_slide()
	
	# Smoothly blend toward target position
	var target_blend := Vector2(input_dir.x, -input_dir.y)
	blend_position = blend_position.lerp(target_blend, blend_speed * delta)
	anim_tree.set("parameters/Locomotion/blend_position", blend_position)
