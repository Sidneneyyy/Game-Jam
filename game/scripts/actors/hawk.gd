extends Node2D
## The hawk is never seen circling: just a screech, a shadow swelling on the spot
## where you stood, then a blur that drops out of the sky and rips back up.
## Be up a tree, in a burrow or under a leafy crown, or just don't be there.

const MARK := 1.1
const DIVE := 0.28
const RISE := 0.45
signal done

var phase := "mark"
var t := 0.0
var spot := Vector2.ZERO
var anim: AnimatedSprite2D
var _hit_checked := false


func _ready() -> void:
	add_to_group("hawk")
	add_to_group("threat")
	z_as_relative = false
	z_index = 40
	spot = Run.squirrel.global_position if Run.squirrel else Vector2(192, 108)
	anim = AnimatedSprite2D.new()
	anim.sprite_frames = Art.frames("sprites/hawk")
	anim.visible = false
	add_child(anim)
	Snd.play("hawk")


func _process(delta: float) -> void:
	if not Run.playing():
		return
	t += delta
	match phase:
		"mark":
			if t >= MARK:
				phase = "dive"
				t = 0.0
				anim.visible = true
				anim.play("dive")
				Snd.play("whoosh")
		"dive":
			var k := clampf(t / DIVE, 0.0, 1.0)
			anim.position = spot + Vector2(-50, -110).lerp(Vector2(0, -8), k)
			anim.scale = Vector2.ONE * lerpf(1.7, 1.0, k)
			anim.modulate.a = lerpf(0.35, 0.95, k)
			if t >= DIVE:
				phase = "strike"
				t = 0.0
				anim.play("strike")
				_strike()
		"strike":
			if t >= 0.12:
				phase = "rise"
				t = 0.0
				anim.play("rise")
		"rise":
			var k := clampf(t / RISE, 0.0, 1.0)
			anim.position = spot + Vector2(0, -8).lerp(Vector2(70, -150), k * k)
			anim.scale = Vector2.ONE * lerpf(1.0, 1.6, k)
			anim.modulate.a = 1.0 - k
			if t >= RISE:
				done.emit()
				queue_free()
	queue_redraw()


func _strike() -> void:
	var sq = Run.squirrel
	Run.park.shake(2.0)
	if sq and sq.global_position.distance_to(spot) < 15.0 and not sq.covered():
		sq.take_hit(16.0, spot + Vector2(0, -6), true)
		Snd.play("hit")
	else:
		Run.popup.emit("MISSED", spot + Vector2(0, -16), Color("fbf6ec"))


func _draw() -> void:
	if phase == "mark" or phase == "dive":
		# the growing shadow on the ground
		var k := clampf(t / MARK, 0.0, 1.0) if phase == "mark" else 1.0
		var r := lerpf(4.0, 14.0, k)
		var a := lerpf(0.15, 0.45, k)
		_ellipse(spot, r, r * 0.55, Color(0.08, 0.05, 0.04, a))
		if Settings.high_contrast or k > 0.6:
			_ring(spot, r + 2.0, (r + 2.0) * 0.55, Color(0.95, 0.3, 0.25, 0.8 if Settings.high_contrast else 0.4))


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(20):
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)


func _ring(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(21):
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, col, 1.0)
