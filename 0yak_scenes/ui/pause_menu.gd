extends Control

@onready var shader_overlay: ColorRect = $ShaderOverlay
@onready var vbox: VBoxContainer = $VBoxContainer
@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

@export var transition_duration := 0.3

var shader_material: ShaderMaterial
var is_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# Setup shader
	shader_material = shader_overlay.material as ShaderMaterial
	shader_material.set_shader_parameter("progress", 0.0)
	
	# Hide menu elements initially
	vbox.modulate.a = 0.0
	
	# Connect buttons
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Don't allow pause if main menu exists
		var main_menu := get_tree().get_first_node_in_group("main_menu")
		if main_menu:
			return
		
		# Don't allow pause if player input not enabled
		var player := get_tree().get_first_node_in_group("player")
		if player and not player.input_enabled:
			return
		
		if is_paused:
			resume_game()
		else:
			pause_game()
		get_viewport().set_input_as_handled()


func pause_game() -> void:
	is_paused = true
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Animate shader and menu
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	
	tween.tween_method(set_shader_progress, 0.0, 1.0, transition_duration)
	tween.tween_property(vbox, "modulate:a", 1.0, transition_duration)

func resume_game() -> void:
	is_paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Animate out
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	
	tween.tween_method(set_shader_progress, 1.0, 0.0, transition_duration)
	tween.tween_property(vbox, "modulate:a", 0.0, transition_duration)
	
	tween.chain().tween_callback(func():
		visible = false
		get_tree().paused = false
	)

func set_shader_progress(value: float) -> void:
	shader_material.set_shader_parameter("progress", value)

func _on_resume_pressed() -> void:
	resume_game()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
