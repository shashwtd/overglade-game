extends Camera3D

@export var transition_duration := 1.5
@export var idle_rotation_speed := 0.05

var is_transitioning := false
var player_camera: Camera3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	current = true
	
	var player := get_tree().get_first_node_in_group("player")
	
	if player:
		player_camera = player.get_node("CameraPivot/SpringArm3D/Camera3D")

func _process(delta: float) -> void:
	if is_transitioning:
		return
	
	rotate_y(idle_rotation_speed * delta)

func transition_to_player() -> void:
	if not player_camera:
		push_error("No player camera found!")
		return
	
	is_transitioning = true
	
	var start_pos := global_position
	var start_rot := global_rotation
	var start_fov := fov
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_method(
		func(t: float):
			global_position = start_pos.lerp(player_camera.global_position, t)
			global_rotation = Vector3(
				lerp_angle(start_rot.x, player_camera.global_rotation.x, t),
				lerp_angle(start_rot.y, player_camera.global_rotation.y, t),
				lerp_angle(start_rot.z, player_camera.global_rotation.z, t)
			)
			fov = lerpf(start_fov, player_camera.fov, t)
			, 0.0, 1.0, transition_duration
		)
	
	tween.tween_callback(func():
		player_camera.current = true
		queue_free()
	)
