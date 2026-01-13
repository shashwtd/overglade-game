extends CharacterBody3D

@export var speed := 6.0
@export var jump_velocity := 4.5

@onready var brute: Node3D = $Brute
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# INPUT (WASD)
	var input_vec: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	)

	# CAMERA-RELATIVE MOVEMENT
	var cam_basis: Basis = camera.global_transform.basis
	var forward: Vector3 = -cam_basis.z
	var right: Vector3 = cam_basis.x

	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	var direction: Vector3 = right * input_vec.x + forward * input_vec.y

	if direction.length() > 0.0:
		direction = direction.normalized()

		# Move
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

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
