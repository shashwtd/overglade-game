extends Label

func _ready() -> void:
	# Position top right
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -150
	offset_right = -10
	offset_top = 10
	offset_bottom = 40
	
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _process(_delta: float) -> void:
	text = "FPS: " + str(Engine.get_frames_per_second())
