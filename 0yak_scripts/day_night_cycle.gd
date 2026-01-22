extends Node3D

@export_group("Time Settings")
@export var day_length_minutes := 10.0
@export var start_hour := 8.0

@export_group("Sun")
@export var sun: DirectionalLight3D

@export_group("Environment")
@export var world_env: WorldEnvironment

# Sky colors
var dawn_sky_top := Color(0.2, 0.3, 0.5)
var dawn_sky_horizon := Color(0.95, 0.5, 0.3)
var day_sky_top := Color(0.3, 0.5, 0.9)
var day_sky_horizon := Color(0.6, 0.8, 1.0)
var dusk_sky_top := Color(0.2, 0.2, 0.4)
var dusk_sky_horizon := Color(0.95, 0.4, 0.2)
var night_sky_top := Color(0.02, 0.02, 0.05)
var night_sky_horizon := Color(0.05, 0.05, 0.1)

# Sun colors
var dawn_sun := Color(0.95, 0.5, 0.3)
var day_sun := Color(1.0, 0.95, 0.9)
var dusk_sun := Color(0.95, 0.4, 0.2)
var night_sun := Color(0.1, 0.1, 0.2)

# Intensity
var dawn_intensity := 0.6
var day_intensity := 1.0
var dusk_intensity := 0.5
var night_intensity := 0.02

var current_hour := 0.0
var current_period := ""
var sky: ProceduralSkyMaterial

signal hour_changed(hour: int)
signal period_changed(period: String)

func _ready() -> void:
	current_hour = start_hour
	setup_procedural_sky()
	update_environment()

func setup_procedural_sky() -> void:
	if not world_env or not world_env.environment:
		return
	
	sky = ProceduralSkyMaterial.new()
	
	var sky_resource := Sky.new()
	sky_resource.sky_material = sky
	
	world_env.environment.background_mode = Environment.BG_SKY
	world_env.environment.sky = sky_resource
	world_env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY

func _process(delta: float) -> void:
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
	update_colors()

func update_sun_rotation() -> void:
	if not sun:
		return
	
	var sun_angle := ((current_hour - 6.0) / 24.0) * 360.0
	sun.rotation_degrees.x = -sun_angle

func update_colors() -> void:
	if not sun or not sky:
		return
	
	var sky_top: Color
	var sky_horizon: Color
	var sun_color: Color
	var intensity: float
	
	if current_hour >= 5.0 and current_hour < 8.0:
		# Dawn
		var t := (current_hour - 5.0) / 3.0
		sky_top = dawn_sky_top.lerp(day_sky_top, t)
		sky_horizon = dawn_sky_horizon.lerp(day_sky_horizon, t)
		sun_color = dawn_sun.lerp(day_sun, t)
		intensity = lerpf(dawn_intensity, day_intensity, t)
		
	elif current_hour >= 8.0 and current_hour < 17.0:
		# Day
		sky_top = day_sky_top
		sky_horizon = day_sky_horizon
		sun_color = day_sun
		intensity = day_intensity
		
	elif current_hour >= 17.0 and current_hour < 20.0:
		# Dusk
		var t := (current_hour - 17.0) / 3.0
		sky_top = day_sky_top.lerp(dusk_sky_top, t)
		sky_horizon = day_sky_horizon.lerp(dusk_sky_horizon, t)
		sun_color = day_sun.lerp(dusk_sun, t)
		intensity = lerpf(day_intensity, dusk_intensity, t)
		
	else:
		# Night
		if current_hour >= 20.0 and current_hour < 22.0:
			var t := (current_hour - 20.0) / 2.0
			sky_top = dusk_sky_top.lerp(night_sky_top, t)
			sky_horizon = dusk_sky_horizon.lerp(night_sky_horizon, t)
			sun_color = dusk_sun.lerp(night_sun, t)
			intensity = lerpf(dusk_intensity, night_intensity, t)
		elif current_hour >= 3.0 and current_hour < 5.0:
			var t := (current_hour - 3.0) / 2.0
			sky_top = night_sky_top.lerp(dawn_sky_top, t)
			sky_horizon = night_sky_horizon.lerp(dawn_sky_horizon, t)
			sun_color = night_sun.lerp(dawn_sun, t)
			intensity = lerpf(night_intensity, dawn_intensity, t)
		else:
			sky_top = night_sky_top
			sky_horizon = night_sky_horizon
			sun_color = night_sun
			intensity = night_intensity
	
	# Apply to sky
	sky.sky_top_color = sky_top
	sky.sky_horizon_color = sky_horizon
	sky.ground_horizon_color = sky_horizon
	sky.ground_bottom_color = sky_top.darkened(0.3)
	
	# Apply to sun
	sun.light_color = sun_color
	sun.light_energy = intensity

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
