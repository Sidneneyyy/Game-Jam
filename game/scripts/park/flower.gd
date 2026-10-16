extends Node2D
## A spring flower. Bees like them; bees on flowers close to a tree for long enough
## build a hive in that tree. Eat the flowers near your trees to keep bees away.

const KINDS := ["daisy", "tulip", "bell"]
var kind := "daisy"
var eaten := false
var anim: AnimatedSprite2D


func _ready() -> void:
	add_to_group("flower")
	kind = KINDS[randi() % KINDS.size()]
	anim = AnimatedSprite2D.new()
	anim.sprite_frames = Art.frames("park/flower_" + kind)
	anim.offset = Vector2(0, -6)
	anim.play("idle")
	anim.frame = randi() % 2
	add_child(anim)
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.4).set_delay(randf() * 1.5).set_trans(Tween.TRANS_BACK)


func eat() -> void:
	eaten = true
	remove_from_group("flower")
	anim.stop()
	anim.sprite_frames = null
	var s := Sprite2D.new()
	s.texture = Art.tex("park/flower_eaten")
	s.offset = Vector2(0, -6)
	add_child(s)


func wilt() -> void:
	remove_from_group("flower")
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.2, 0.1), 0.6)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)
