extends Node2D
## High contrast mode: every threat gets a bold ring (and the rings differ by
## shape as well as colour, so nothing relies on colour alone).
## Dog / fox: solid red circle. Rivals: dashed orange circle. Bees: yellow diamond.

func _ready() -> void:
	z_as_relative = false
	z_index = 45


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not Settings.high_contrast or not Run.playing():
		return
	for n in get_tree().get_nodes_in_group("threat"):
		if not is_instance_valid(n) or not n.visible or n.is_in_group("hawk"):
			continue
		var p: Vector2 = n.global_position + Vector2(0, -6)
		if n.is_in_group("bees"):
			var r := 11.0
			draw_polyline(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0), p + Vector2(0, -r)]), Color("ffe14a"), 1.0)
		elif n.is_in_group("rival"):
			for i in range(12):
				if i % 2 == 0:
					draw_arc(p, 12.0, TAU * i / 12.0, TAU * (i + 1) / 12.0, 3, Color("ff9a3a"), 1.0)
		else:
			draw_arc(p, 15.0, 0, TAU, 24, Color("ff3a3a"), 2.0)
