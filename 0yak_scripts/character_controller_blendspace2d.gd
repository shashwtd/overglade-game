extends CharacterBody3D

@export_group("Movement")
@export var walk_speed := 2.2
@export var run_speed := 5.5
@export var crouch_speed := 1.5
@export var jump_velocity := 3.5
@export var acceleration := 10.0

@export_group("Mouse")
@export var mouse_sensitivity := 0.003
@export var camera_pitch_min := -89.0
@export var camera_pitch_max := 89.0

@export_group("Animation")
@export var blend_speed := 8.0
@export var crouch_blend_speed := 6.0
@export var sprint_blend_speed := 8.0
@export var jump_anim_delay := 0.5

@onready var camera_pivot: Node3D = $CameraPivot
@onready var brute: Node3D = $Brute
@onready var anim_tree: AnimationTree = $Brute/AnimationTree
@onready var crosshair: Control = get_tree().get_first_node_in_group("crosshair")

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var blend_position := Vector2.ZERO
var crouch_blend := 0.0
var sprint_blend := 0.0
var is_crouching := false
var is_sprinting := false
var jump_pending := false
var is_attacking := false

func _ready() -> void:
	anim_tree.active = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x,
			deg_to_rad(camera_pitch_min),
			deg_to_rad(camera_pitch_max)
		)
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Get input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Sprint check
	is_sprinting = Input.is_action_pressed("sprint") and input_dir.y < 0 and not is_crouching and not is_attacking
	
	# Check if attack finished
	if is_attacking:
		var attack_active: bool = anim_tree.get("parameters/AttackOneShot/active")
		if not attack_active:
			is_attacking = false
	
	# Attack input
	if Input.is_action_just_pressed("attack") and not is_attacking and is_on_floor():
		start_attack()
	
	# Jump input
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching and not jump_pending and not is_attacking:
		jump_pending = true
		anim_tree.set("parameters/JumpOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		get_tree().create_timer(jump_anim_delay).timeout.connect(_apply_jump)
	
	# Crouch toggle
	if Input.is_action_just_pressed("crouch") and not is_attacking:
		is_crouching = not is_crouching
	
	# Movement direction
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Current speed
	var current_speed := walk_speed
	if is_attacking:
		current_speed = walk_speed * 0.2
	elif is_crouching:
		current_speed = crouch_speed
	elif is_sprinting:
		current_speed = run_speed
	
	# Apply movement
	if direction:
		velocity.x = lerp(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, acceleration * delta)
	
	move_and_slide()
	
	# Animation blends
	var target_blend := Vector2(input_dir.x, -input_dir.y)
	blend_position = blend_position.lerp(target_blend, blend_speed * delta)
	anim_tree.set("parameters/Locomotion/blend_position", blend_position)
	
	var target_sprint := 1.0 if is_sprinting else 0.0
	sprint_blend = lerpf(sprint_blend, target_sprint, sprint_blend_speed * delta)
	anim_tree.set("parameters/WalkRunBlend/blend_amount", sprint_blend)
	
	var target_crouch := 1.0 if is_crouching else 0.0
	crouch_blend = lerpf(crouch_blend, target_crouch, crouch_blend_speed * delta)
	anim_tree.set("parameters/CrouchBlend/blend_amount", crouch_blend)
	
	update_crosshair()

func start_attack() -> void:
	is_attacking = true
	anim_tree.set("parameters/AttackOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _apply_jump() -> void:
	jump_pending = false
	if is_on_floor():
		velocity.y = jump_velocity

func update_crosshair() -> void:
	if not crosshair:
		return
	
	if is_sprinting:
		crosshair.set_sprinting()
	elif is_crouching:
		crosshair.set_aiming()
	else:
		crosshair.set_normal()
