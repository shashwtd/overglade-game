extends CharacterBody3D

@export var speed := 6.0
@export var jump_velocity := 4.5

@onready var brute: Node3D = $Brute
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

@onready var anim_tree: AnimationTree = $Brute/AnimationTree
var anim_state: AnimationNodeStateMachinePlayback


func _ready():
	anim_tree.active = true
	await get_tree().process_frame
	anim_state = anim_tree.get("parameters/StateMachine/playback")



func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# INPUT (WASD)
	var input_vec := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	)

	# CAMERA-RELATIVE BASIS
	var cam_basis := camera.global_transform.basis
	var forward := -cam_basis.z
	var right := cam_basis.x

	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	# MOVEMENT DIRECTION
	var direction := right * input_vec.x + forward * input_vec.y

	if direction.length() > 0.01:
		direction = direction.normalized()

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		# Rotate brute to face movement
		brute.rotation.y = lerp_angle(
			brute.rotation.y,
			atan2(direction.x, direction.z),
			10.0 * delta
		)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	# ANIMATION UPDATE (USES REAL MOVEMENT)
	update_animation(Vector2(direction.x, direction.z))

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()


func update_animation(move_vec: Vector2) -> void:
	if anim_state == null:
		return


	if move_vec.length() < 0.01:
		anim_state.travel("idle")
		return

	if abs(move_vec.y) > abs(move_vec.x):
		if move_vec.y > 0:
			anim_state.travel("walk_forward")
		else:
			anim_state.travel("walk_back")
	else:
		if move_vec.x < 0:
			anim_state.travel("walk_left")
		else:
			anim_state.travel("walk_right")
