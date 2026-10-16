extends Node
## Mood of each season: colour tint, weather, passing spring showers, and the
## dark of winter (you only see a small circle around you, plus the park lamps).

const TINT := [Color(1, 1, 1), Color(1.04, 1.0, 0.9), Color(1.0, 0.92, 0.84), Color(0.9, 0.95, 1.05)]
const RAIN_TINT := Color(0.8, 0.86, 0.95)

var raining := false
var modulate_node: CanvasModulate
var weather_layer: CanvasLayer
var dark_layer: CanvasLayer
var dark_rect: ColorRect
var dark_mat: ShaderMaterial
var parts := {}
var rain: CPUParticles2D
var _season := 0
var _dark := 0.0
var _shower_cd := 20.0
var _shower_t := 0.0
var _rain_snd_t := 0.0
var _amb_t := 4.0
const AMBIENCE := [["amb_bird1", "amb_bird2"], ["amb_bird2", "amb_cricket", "amb_bird1"], ["amb_leaves", "amb_bird1", "amb_leaves"], ["amb_wind", "amb_owl", "amb_wind"]]


func _ready() -> void:
	modulate_node = CanvasModulate.new()
	add_child(modulate_node)
	dark_layer = CanvasLayer.new()
	dark_layer.layer = 2
	add_child(dark_layer)
	dark_rect = ColorRect.new()
	dark_rect.size = Vector2(384, 216)
	dark_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark_mat = ShaderMaterial.new()
	dark_mat.shader = preload("res://scripts/park/dark.gdshader")
	dark_rect.material = dark_mat
	dark_layer.add_child(dark_rect)
	weather_layer = CanvasLayer.new()
	weather_layer.layer = 4
	add_child(weather_layer)
	var dot := Art.dot_texture(1, 1, Color.WHITE)
	rain = _emitter(Art.dot_texture(1, 4, Color.WHITE), 160, 0.7, Vector2(30, 300), Color(0.75, 0.85, 1.0, 0.65))
	parts[Clock.SPRING] = _emitter(dot, 14, 6.0, Vector2(4, 10), Color(1, 0.85, 0.92, 0.9))  # petals
	parts[Clock.SUMMER] = _emitter(dot, 22, 5.0, Vector2(3, -6), Color(1, 0.96, 0.6, 0.85))  # pollen motes
	var leaf := _emitter(Art.dot_texture(2, 1, Color.WHITE), 34, 7.0, Vector2(-14, 30), Color(0.93, 0.5, 0.16))
	var g := Gradient.new()
	g.set_color(0, Color(0.95, 0.55, 0.15))
	g.set_color(1, Color(0.75, 0.25, 0.1))
	leaf.color_initial_ramp = g
	parts[Clock.AUTUMN] = leaf
	parts[Clock.WINTER] = _emitter(Art.dot_texture(2, 2, Color.WHITE), 150, 6.0, Vector2(-18, 40), Color(1, 1, 1, 0.95))
	set_season(Clock.season)


func _emitter(t: Texture2D, n: int, life: float, vel: Vector2, c: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = t
	p.amount = n
	p.lifetime = life
	p.preprocess = life
	p.position = Vector2(192, -6)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(230, 4)
	p.direction = vel.normalized()
	p.spread = 12.0
	p.initial_velocity_min = vel.length() * 0.7
	p.initial_velocity_max = vel.length()
	p.gravity = Vector2.ZERO
	p.color = c
	p.emitting = false
	weather_layer.add_child(p)
	return p


func set_season(s: int) -> void:
	_season = s
	for k in parts:
		parts[k].emitting = (k == s)
	if s != Clock.SPRING:
		_stop_rain()
	_shower_cd = randf_range(12.0, 30.0)


func _stop_rain() -> void:
	raining = false
	rain.emitting = false


func _process(delta: float) -> void:
	# passing spring showers: they come and go
	if _season == Clock.SPRING and Run.playing():
		if raining:
			_shower_t -= delta
			_rain_snd_t -= delta
			if _rain_snd_t <= 0.0:
				_rain_snd_t = 3.6
				Snd.play("rain", 0.02, -10.0)
			if _shower_t <= 0.0:
				_stop_rain()
				_shower_cd = randf_range(25.0, 40.0)
		else:
			_shower_cd -= delta
			if _shower_cd <= 0.0:
				raining = true
				rain.emitting = true
				_shower_t = randf_range(10.0, 15.0)
	# a little life in the background: birds, crickets, rustling leaves, wind and owls
	if Run.playing() or Run.state == Run.TITLE:
		_amb_t -= delta
		if _amb_t <= 0.0:
			_amb_t = randf_range(5.0, 11.0)
			var pool: Array = AMBIENCE[_season]
			if not (raining and _season == Clock.SPRING):
				Snd.play(pool[randi() % pool.size()], 0.12, -10.0)
	var tint: Color = TINT[_season]
	if raining:
		tint = tint * RAIN_TINT
	modulate_node.color = modulate_node.color.lerp(tint, clampf(delta * 1.5, 0.0, 1.0))
	# winter dark: only a small circle of sight, plus lamp light
	var want := 1.0 if (_season == Clock.WINTER and Run.state != Run.TITLE) else 0.0
	_dark = move_toward(_dark, want, delta * 0.5)
	dark_rect.visible = _dark > 0.01
	if dark_rect.visible and Run.park:
		var sq = Run.squirrel
		var c: Vector2 = (sq.global_position + Vector2(0, -6)) if sq else Vector2(192, 108)
		dark_mat.set_shader_parameter("center", c + Run.park.position)
		dark_mat.set_shader_parameter("radius", Run.park.vision_radius())
		dark_mat.set_shader_parameter("strength", _dark * 0.94)
		var lamps: Array = []
		for l in Run.park.LAMPS:
			lamps.append(l + Vector2(0, -28) + Run.park.position)
		dark_mat.set_shader_parameter("lamps", PackedVector2Array(lamps))
