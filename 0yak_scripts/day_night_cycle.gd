extends Node3D

@export_group("Time Settings")
@export var day_length_minutes := 10.0  # Real minutes per in-game day
@export var start_hour := 8.0  # Start at 8 AM

@export_group("Sun")
@export var sun: DirectionalLight3D

@export_group("Sky Colors")
@export var dawn_color := Color(0.95, 0.5, 0.3)
@export var day_color := Color(1.0, 0.95, 0.9)
@export var dusk_color := Color(0.95, 0.4, 0.3)
@export var night_color := Color(0.1, 0.1, 0.2)

@export_group("Ambient Light")
@export var dawn_ambient := Color(0.4, 0.3, 0.3)
@export var day_ambient := Color(0.5, 0.5, 0.5)
@export var dusk_ambient := Color(0.3, 0.2, 0.2)
@export var night_ambient := Color(0.05, 0.05, 0.1)

@export_group("Sun Intensity")
@export var dawn_intensity := 0.6
@export var day_intensity := 1.0
@export var dusk_intensity := 0.5
@export var night_intensity := 0.05

# 0-24 hour format
var current_hour := 0.0

signal hour_changed(hour: int)
signal period_changed(period: String)

var current_period := ""

func _ready() -> void:
	current_hour = start_hour
	update_environment()

func _process(delta: float) -> void:
	# Hours per real second
	var hours_per_second := 24.0 / (day_length_minutes * 60.0)
	
	var previous_hour := int(current_hour)
	current_hour += hours_per_second * delta
	
	if current_hour >= 24.0:
		current_hour -= 24.0
	
	if int(current_hour) != previous_hour:
		hour_changed.emit(int(current_hour))
	
	update_environment()
	check_period_change()

func update_environment() -> void:
	update_sun_rotation()
	update_sun_color()
	update_ambient()

func update_sun_rotation() -> void:
	if not sun:
		return
	
	# Sun rises at 6, overhead at 12, sets at 18
	# Map hour to rotation: 6AM = 0°, 12PM = 90°, 6PM = 180°, 12AM = 270°
	var sun_angle := ((current_hour - 6.0) / 24.0) * 360.0
	sun.rotation_degrees.x = -sun_angle

func update_sun_color() -> void:
	if not sun:
		return
	
	var color: Color
	var intensity: float
	
	if current_hour >= 5.0 and current_hour < 8.0:
		# Dawn (5-8)
		var t := (current_hour - 5.0) / 3.0
		color = dawn_color.lerp(day_color, t)
		intensity = lerpf(dawn_intensity, day_intensity, t)
	elif current_hour >= 8.0 and current_hour < 17.0:
		# Day (8-17)
		color = day_color
		intensity = day_intensity
	elif current_hour >= 17.0 and current_hour < 20.0:
		# Dusk (17-20)
		var t := (current_hour - 17.0) / 3.0
		color = day_color.lerp(dusk_color, t)
		intensity = lerpf(day_intensity, dusk_intensity, t)
	elif current_hour >= 20.0 or current_hour < 5.0:
		# Night (20-5)
		if current_hour >= 20.0:
			var t := (current_hour - 20.0) / 2.0
			color = dusk_color.lerp(night_color, t)
			intensity = lerpf(dusk_intensity, night_intensity, t)
		else:
			color = night_color
			intensity = night_intensity
	else:
		color = day_color
		intensity = day_intensity
	
	sun.light_color = color
	sun.light_energy = intensity

func update_ambient() -> void:
	var env := get_viewport().world_3d.environment
	if not env:
		return
	
	var ambient: Color
	
	if current_hour >= 5.0 and current_hour < 8.0:
		var t := (current_hour - 5.0) / 3.0
		ambient = dawn_ambient.lerp(day_ambient, t)
	elif current_hour >= 8.0 and current_hour < 17.0:
		ambient = day_ambient
	elif current_hour >= 17.0 and current_hour < 20.0:
		var t := (current_hour - 17.0) / 3.0
		ambient = day_ambient.lerp(dusk_ambient, t)
	elif current_hour >= 20.0 or current_hour < 5.0:
		if current_hour >= 20.0:
			var t := (current_hour - 20.0) / 2.0
			ambient = dusk_ambient.lerp(night_ambient, t)
		else:
			ambient = night_ambient
	else:
		ambient = day_ambient
	
	env.ambient_light_color = ambient

func check_period_change() -> void:
	var new_period := get_current_period()
	if new_period != current_period:
		current_period = new_period
		period_changed.emit(current_period)

func get_current_period() -> String:
	if current_hour >= 5.0 and current_hour < 8.0:
		return "dawn"
	elif current_hour >= 8.0 and current_hour < 17.0:
		return "day"
	elif current_hour >= 17.0 and current_hour < 20.0:
		return "dusk"
	else:
		return "night"

func get_time_string() -> String:
	var hours := int(current_hour)
	var minutes := int((current_hour - hours) * 60)
	return "%02d:%02d" % [hours, minutes]
