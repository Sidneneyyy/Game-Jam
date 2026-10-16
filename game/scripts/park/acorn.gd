extends Node2D
## An acorn on the ground. Falls out of a crown in fall (drop + bounce),
## scatters when you're hit, and is picked up by running over it.

var height := 0.0
var vz := 0.0
var landed := false
var sprite: Sprite2D
var shadow: Sprite2D


func drop_from(h: float) -> void:
	height = h
	vz = 0.0


func _ready() -> void:
	add_to_group("acorn")
	z_as_relative = false
	z_index = -3
	shadow = Sprite2D.new()
	shadow.texture = Art.tex("park/shadow_small")
	shadow.position = Vector2(0, 1)
	add_child(shadow)
	sprite = Sprite2D.new()
	sprite.texture = Art.tex("park/acorn")
	sprite.offset = Vector2(0, -4)
	add_child(sprite)
	landed = height <= 0.0
	_place()


func _place() -> void:
	sprite.position.y = -round(height)
	z_index = 22 if height > 6.0 else -3   # falling acorns show over the crown


func _process(delta: float) -> void:
	if landed:
		return
	vz -= 260.0 * delta
	height += vz * delta
	if height <= 0.0:
		height = 0.0
		if vz < -50.0:
			vz = -vz * 0.35  # little bounce
		else:
			landed = true
	_place()


func can_pick() -> bool:
	return landed or height < 3.0
