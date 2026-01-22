extends Node3D

@export_group("Time Settings")
@export var day_length_minutes := 10.0
@export var start_hour := 8.0

@export_group("Sun & Moon")
@export var sun: DirectionalLight3D
@export var moon_mesh: MeshInstance3D

@export_group("Environment")
@export var world_env: WorldEnvironment

# Sky colors
var dawn_sky_top := Color(0.2, 0.3, 0.5)
var dawn_sky_horizon := Color(0.95, 0.5, 0.3)
var day_sky_top := Color(0.3, 0.5, 0.9)
var day_sky_horizon := Color(0.6, 0.8, 1.0)
var dusk_sky_top := Color(0.2, 0.2, 0.4)
var dusk_sky_horizon := Color(0.95, 0.4, 0.2)
var night_sky_top := Color(0.01, 0.01, 0.02)
var night_sky_horizon := Color(0.03, 0.03, 0.06)

# Sun colors
var dawn_sun := Color(0.95, 0.5, 0.3)
var day_sun := Color(1.0, 0.95, 0.9)
var dusk_sun := Color(0.95, 0.4, 0.2)

# Intensity
var dawn_intensity := 0.6
var day_intensity := 1.0
var dusk_intensity := 0.5

var current_hour := 0.0
var current_period := ""
var sky: ProceduralSkyMaterial

# Orbit settings
var orbit_radius := 500.0

signal hour_changed(hour: int)
signal period_changed(period: String)

func _ready() -> void:
	current_hour = start_hour
	setup_procedural_sky()
	setup_moon_mesh()
	update_environment()

func setup_procedural_sky() -> void:
	if not world_env or not world_env.environment:
		return
	
	sky = ProceduralSkyMaterial.new()
	sky.use_debanding = true
	
	var sky_resource := Sky.new()
	sky_resource.sky_material = sky
	
	world_env.environment.background_mode = Environment.BG_SKY
	world_env.environment.sky = sky_resource

func setup_moon_mesh() -> void:
	if not moon_mesh:
		return
	
	moon_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var mat := moon_mesh.get_surface_override_material(0)
	if mat and mat is StandardMaterial3D:
		mat.emission_enabled = true
		mat.emission = Color(0.7, 0.7, 0.8)
		mat.emission_energy_multiplier = 0.5

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
	update_celestial_bodies()
	update_colors()
	update_ambient()

func update_celestial_bodies() -> void:
	# Both sun and moon travel the same circular path
	# 0° = horizon east, 90° = overhead, 180° = horizon west
	
	# Sun: 6AM rises, 12PM peak, 6PM sets
	var sun_angle := ((current_hour - 6.0) / 24.0) * 360.0
	var sun_rad := deg_to_rad(sun_angle)
	
	# Moon: 12 hours offset from sun
	var moon_angle := sun_angle + 180.0
	var moon_rad := deg_to_rad(moon_angle)
	
	var is_day := current_hour >= 6.0 and current_hour < 18.0
	
	# Update sun
	if sun:
		sun.visible = is_day
		if is_day:
			sun.rotation_degrees.x = -sun_angle
	
	# Update moon mesh position on same orbit
	if moon_mesh:
		moon_mesh.visible = not is_day
		if not is_day:
			moon_mesh.position = Vector3(
				0,
				sin(moon_rad) * orbit_radius,
				-cos(moon_rad) * orbit_radius
			)
			moon_mesh.look_at(Vector3.ZERO)
			moon_mesh.scale = Vector3(1.8, 1.8, 1.8)

func update_colors() -> void:
	if not sky:
		return
	
	var sky_top: Color
	var sky_horizon: Color
	var sun_color: Color
	var sun_intensity: float
	
	if current_hour >= 5.0 and current_hour < 8.0:
		var t := (current_hour - 5.0) / 3.0
		sky_top = dawn_sky_top.lerp(day_sky_top, t)
		sky_horizon = dawn_sky_horizon.lerp(day_sky_horizon, t)
		sun_color = dawn_sun.lerp(day_sun, t)
		sun_intensity = lerpf(dawn_intensity, day_intensity, t)
		
	elif current_hour >= 8.0 and current_hour < 17.0:
		sky_top = day_sky_top
		sky_horizon = day_sky_horizon
		sun_color = day_sun
		sun_intensity = day_intensity
		
	elif current_hour >= 17.0 and current_hour < 20.0:
		var t := (current_hour - 17.0) / 3.0
		sky_top = day_sky_top.lerp(dusk_sky_top, t)
		sky_horizon = day_sky_horizon.lerp(dusk_sky_horizon, t)
		sun_color = day_sun.lerp(dusk_sun, t)
		sun_intensity = lerpf(day_intensity, dusk_intensity, t)
		
	else:
		if current_hour >= 20.0 and current_hour < 21.0:
			var t := (current_hour - 20.0)
			sky_top = dusk_sky_top.lerp(night_sky_top, t)
			sky_horizon = dusk_sky_horizon.lerp(night_sky_horizon, t)
		elif current_hour >= 4.0 and current_hour < 5.0:
			var t := (current_hour - 4.0)
			sky_top = night_sky_top.lerp(dawn_sky_top, t)
			sky_horizon = night_sky_horizon.lerp(dawn_sky_horizon, t)
		else:
			sky_top = night_sky_top
			sky_horizon = night_sky_horizon
		
		sun_color = Color.WHITE
		sun_intensity = 0.0
	
	sky.sky_top_color = sky_top
	sky.sky_horizon_color = sky_horizon
	sky.ground_horizon_color = sky_horizon
	sky.ground_bottom_color = sky_top.darkened(0.3)
	
	if sun and sun.visible:
		sun.light_color = sun_color
		sun.light_energy = sun_intensity

func update_ambient() -> void:
	if not world_env or not world_env.environment:
		return
	
	var env := world_env.environment
	var ambient_color: Color
	var ambient_energy: float
	
	if current_hour >= 8.0 and current_hour < 17.0:
		# Day - lower ambient, sun does the work
		ambient_color = Color(0.6, 0.6, 0.6)
		ambient_energy = 0.4
	elif current_hour >= 5.0 and current_hour < 8.0:
		# Dawn
		var t := (current_hour - 5.0) / 3.0
		ambient_color = Color(0.4, 0.4, 0.5).lerp(Color(0.6, 0.6, 0.6), t)
		ambient_energy = lerpf(0.7, 0.4, t)
	elif current_hour >= 17.0 and current_hour < 20.0:
		# Dusk
		var t := (current_hour - 17.0) / 3.0
		ambient_color = Color(0.6, 0.6, 0.6).lerp(Color(0.3, 0.3, 0.5), t)
		ambient_energy = lerpf(0.4, 0.8, t)
	else:
		# Night - ambient does all the lighting
		ambient_color = Color(0.3, 0.3, 0.5)
		ambient_energy = 0.8
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_color
	env.ambient_light_energy = ambient_energy

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
