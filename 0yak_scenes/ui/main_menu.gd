extends Control

@onready var start_button: Button = $"Vertical Center Container/Start Button"
@onready var exit_button: Button = $"Vertical Center Container/Exit Button"

@export var menu_camera: Camera3D
@export var fade_duration := 0.5

func _ready() -> void:
	# Start invisible, fade in
	modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, fade_duration)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	# Disable buttons so player can't spam
	start_button.disabled = true
	exit_button.disabled = true
	
	# Fade out UI
	var fade_tween := create_tween()
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await fade_tween.finished
	
	# Unpause for camera transition
	get_tree().paused = false
	
	# Start camera transition
	if menu_camera and menu_camera.has_method("transition_to_player"):
		menu_camera.transition_to_player()
		await get_tree().create_timer(menu_camera.transition_duration).timeout
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Enable player input
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("enable_input"):
		player.enable_input()
	
	queue_free()

func _on_exit_pressed() -> void:
	# Fade out before quit (optional)
	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await fade_tween.finished
	
	get_tree().quit()
