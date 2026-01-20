extends CharacterBody3D

@export var max_health := 100.0
@export var wobble_strength := 0.3
@export var wobble_speed := 20.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var health_bar: Sprite3D = $HealthBar

var health: float
var original_material: StandardMaterial3D
var wobble_time := 0.0
var is_wobbling := false

func _ready() -> void:
	health = max_health
	setup_material()
	update_health_bar()

func _process(delta: float) -> void:
	if is_wobbling:
		wobble_time += delta * wobble_speed
		mesh.rotation.x = sin(wobble_time) * wobble_strength
		mesh.rotation.z = cos(wobble_time * 0.7) * wobble_strength * 0.5
		
		if wobble_time > 1.5:
			is_wobbling = false
			wobble_time = 0.0
			mesh.rotation.x = 0
			mesh.rotation.z = 0

func setup_material() -> void:
	original_material = StandardMaterial3D.new()
	original_material.albedo_color = Color(0.5, 0.1, 0.1)
	mesh.set_surface_override_material(0, original_material)

func get_health_color() -> Color:
	var health_percent := health / max_health
	
	if health_percent > 0.6:
		return Color(0.1, 0.8, 0.1)
	elif health_percent > 0.3:
		return Color(1.0, 0.6, 0.0)
	else:
		return Color(0.9, 0.1, 0.1)

func update_health_bar() -> void:
	var health_percent := health / max_health
	var bar_width := 64
	var fill_width := int(bar_width * health_percent)
	
	var image := Image.create(bar_width, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.2, 0.2, 0.9))
	
	var health_color := get_health_color()
	for x in fill_width:
		for y in 8:
			image.set_pixel(x, y, health_color)
	
	health_bar.texture = ImageTexture.create_from_image(image)

func take_damage(amount: float) -> void:
	health -= amount
	
	update_health_bar()
	start_wobble()
	
	await get_tree().create_timer(0.05).timeout
	flash_hit()
	
	if health <= 0:
		die()

func start_wobble() -> void:
	is_wobbling = true
	wobble_time = 0.0

func flash_hit() -> void:
	original_material.albedo_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	original_material.albedo_color = Color(0.5, 0.1, 0.1)

func die() -> void:
	queue_free()
