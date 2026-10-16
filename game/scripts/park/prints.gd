extends Node2D
## Footprints in the snow (fox or squirrel). They fade out over time.

var tex: Texture2D
var life := 22.0
var marks: Array = []  # [pos, angle, age]


func add(pos: Vector2, angle: float) -> void:
	marks.append([pos, angle, 0.0])
	if marks.size() > 220:
		marks.pop_front()


func clear() -> void:
	marks.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if marks.is_empty():
		return
	for m in marks:
		m[2] += delta
	while not marks.is_empty() and marks[0][2] > life:
		marks.pop_front()
	queue_redraw()


func _draw() -> void:
	for m in marks:
		var a := clampf(1.0 - m[2] / life, 0.0, 1.0)
		draw_set_transform(m[0], m[1], Vector2.ONE)
		draw_texture(tex, -tex.get_size() / 2.0, Color(1, 1, 1, a * 0.85))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
