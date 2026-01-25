extends Control

@export var crosshair_color := Color.WHITE
@export var line_thickness := 2.0
@export var size_scale := 1.0

enum CrosshairStyle { DOT, CROSS }
enum CrosshairState { NORMAL, AIMING, SPRINTING, HIDDEN }

@export var style := CrosshairStyle.DOT
var current_state := CrosshairState.NORMAL

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if current_state == CrosshairState.HIDDEN:
		return
	
	var center := get_viewport_rect().size / 2.0
	var s := size_scale
	
	match style:
		CrosshairStyle.DOT:
			draw_circle(center, 2.5 * s, crosshair_color)
		
		CrosshairStyle.CROSS:
			# Only scale cross based on state
			match current_state:
				CrosshairState.AIMING:
					s *= 0.6
				CrosshairState.SPRINTING:
					s *= 1.4
			
			var len := 10.0 * s
			var gap := 4.0 * s
			draw_line(center + Vector2(0, -gap - len), center + Vector2(0, -gap), crosshair_color, line_thickness)
			draw_line(center + Vector2(0, gap), center + Vector2(0, gap + len), crosshair_color, line_thickness)
			draw_line(center + Vector2(-gap - len, 0), center + Vector2(-gap, 0), crosshair_color, line_thickness)
			draw_line(center + Vector2(gap, 0), center + Vector2(gap + len, 0), crosshair_color, line_thickness)

func set_normal() -> void:
	current_state = CrosshairState.NORMAL

func set_aiming() -> void:
	current_state = CrosshairState.AIMING

func set_sprinting() -> void:
	current_state = CrosshairState.SPRINTING

func hide_crosshair() -> void:
	current_state = CrosshairState.HIDDEN

func show_crosshair() -> void:
	current_state = CrosshairState.NORMAL
