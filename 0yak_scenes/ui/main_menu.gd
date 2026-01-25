extends Control

@onready var start_button: Button = $"VerticalCenterContainer/StartButton"
@onready var exit_button: Button = $"VerticalCenterContainer/ExitButton"

func _ready() -> void:
	# Show mouse cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Pause the game while in menu
	get_tree().paused = true
	
	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()  # Remove menu

func _on_exit_pressed() -> void:
	get_tree().quit()
