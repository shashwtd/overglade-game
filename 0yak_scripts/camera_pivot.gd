extends Node3D

@export var mouse_sensitivity := 0.003
@export var pitch_min := -89.0
@export var pitch_max := 89.0

@onready var character: CharacterBody3D = get_parent()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Horizontal rotation on the character
		character.rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Vertical rotation on the camera pivot
		rotate_x(-event.relative.y * mouse_sensitivity)
		rotation.x = clamp(rotation.x, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
