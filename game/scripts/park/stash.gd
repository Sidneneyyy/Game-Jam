extends Node2D
## A buried stash: one spot can hold several acorns. If it's forgotten until next
## spring it can sprout (one tree, however many acorns). A rival who saw it buried
## can come back and take every acorn in one go. In winter it hides under the
## snow; get close and sparkles give it away.

var acorns := 1
var witnesses: Array = []
var sprite: Sprite2D
var sparkle: AnimatedSprite2D
var _sniff_t := 0.0


func _ready() -> void:
	add_to_group("stash")
	z_as_relative = false
	z_index = -5
	sprite = Sprite2D.new()
	sprite.offset = Vector2(0, -2)
	add_child(sprite)
	sparkle = AnimatedSprite2D.new()
	sparkle.sprite_frames = Art.frames("park/sparkle")
	sparkle.play("idle")
	sparkle.position = Vector2(0, -7)
	sparkle.visible = false
	sparkle.z_as_relative = false
	sparkle.z_index = 5
	add_child(sparkle)
	apply_season(Clock.season)


func apply_season(_s := 0) -> void:
	var n: String = Clock.NAMES[Clock.season]
	sprite.texture = Art.tex(("park/stash2_" if acorns >= 3 else "park/stash_") + n)
	sprite.modulate.a = 0.55 if Clock.season == Clock.WINTER and not Settings.assist else 1.0


func add(n := 1) -> void:
	acorns += n
	apply_season()
	var tw := create_tween()
	sprite.scale = Vector2(1.3, 0.7)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.2)


func take(n: int) -> int:
	var k := mini(n, acorns)
	acorns -= k
	if acorns <= 0:
		forget_all()
		queue_free()
	else:
		apply_season()
	return k


func forget_all() -> void:
	for r in witnesses:
		if is_instance_valid(r):
			r.forget(self)
	witnesses.clear()


func _process(delta: float) -> void:
	# winter: sniff out stashes under the snow
	if Clock.season == Clock.WINTER and Run.squirrel:
		var near: bool = Run.squirrel.global_position.distance_to(global_position) < (46.0 if Settings.assist else 34.0)
		sparkle.visible = near
		if near:
			_sniff_t -= delta
			if _sniff_t <= 0.0:
				_sniff_t = 1.4
				Snd.play("sparkle", 0.1, -12.0)
	else:
		sparkle.visible = false
