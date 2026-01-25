extends Control

@onready var start_button: Button = $"VBoxContainer/StartButton"
@onready var exit_button: Button = $"VBoxContainer/ExitButton"

@export var fade_duration := 0.5

var menu_camera: Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	menu_camera = get_tree().get_first_node_in_group("menu_camera")
	
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	# Hide mouse immediately
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	start_button.visible = false
	exit_button.visible = false
	
	get_tree().paused = false
	
	# Start fade and camera transition at the same time
	var fade_tween := create_tween()
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	
	if menu_camera and menu_camera.has_method("transition_to_player"):
		menu_camera.transition_to_player()
	
	# Wait for camera transition (longer of the two)
	var wait_time :float = menu_camera.transition_duration if menu_camera else fade_duration
	await get_tree().create_timer(wait_time).timeout
	
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("enable_input"):
		player.enable_input()
	
	queue_free()

func _on_exit_pressed() -> void:
	get_tree().quit()
