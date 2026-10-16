extends Node2D
## A little swarm of bees. In spring it drifts from flower to flower; sitting on
## flowers close to a tree slowly builds a hive in that tree. Once it has a hive
## it lives there (dormant in winter). Get too close and they sting.

const N := 5
const SPEED := 24.0
var state := "fly"     # fly, sit, hive, leave
var flower: Node = null
var home: Node = null  # hive tree
var target := Vector2.ZERO
var sit_t := 0.0
var sting_cd := 0.0
var bees: Array[AnimatedSprite2D] = []
var _jit := 0.0
var _buzz_t := 0.0


func _ready() -> void:
	add_to_group("bees")
	add_to_group("threat")
	z_as_relative = false
	z_index = 22
	for i in range(N):
		var b := AnimatedSprite2D.new()
		b.sprite_frames = Art.frames("sprites/bee")
		b.play("fly")
		b.frame = i % 2
		add_child(b)
		bees.append(b)
	_pick_flower()


func _pick_flower() -> void:
	var fl: Array = get_tree().get_nodes_in_group("flower").filter(func(f): return f != flower)
	if fl.is_empty():
		flower = null
		target = Run.park.random_spot()
		return
	flower = fl[randi() % fl.size()]
	target = flower.global_position + Vector2(0, -8)


func settle(tree: Node) -> void:
	home = tree
	state = "hive"


func _process(delta: float) -> void:
	if not Run.playing():
		return
	_jit -= delta
	if _jit <= 0.0:
		_jit = 0.12  # choppy little hops, not smooth orbits
		for i in range(bees.size()):
			var a := randf() * TAU
			var r := randf_range(2.0, 7.0)
			bees[i].position = Vector2(cos(a) * r, sin(a) * r * 0.7)
			bees[i].flip_h = randf() < 0.5
	sting_cd = maxf(0.0, sting_cd - delta)
	match state:
		"fly":
			if _fly_to(target, delta):
				state = "sit"
				sit_t = randf_range(6.0, 11.0)
		"sit":
			sit_t -= delta
			if flower == null or not is_instance_valid(flower) or flower.eaten:
				_pick_flower()
				state = "fly"
			else:
				Run.park.bees_on_flower(self, flower, delta)
				if sit_t <= 0.0 and state == "sit":
					_pick_flower()
					state = "fly"
		"hive":
			var dormant := Clock.season == Clock.WINTER
			visible = not dormant
			target = home.global_position + Vector2(9, -16)
			_fly_to(target, delta)
			if dormant:
				return
		"leave":
			if _fly_to(target, delta):
				queue_free()
				return
	_sting_check()
	_buzz(delta)


func leave() -> void:
	if state == "hive":
		return
	state = "leave"
	target = Run.park.exit_point(global_position)


func _fly_to(p: Vector2, delta: float) -> bool:
	var d := p - global_position
	if d.length() < 1.5:
		return true
	global_position += d.normalized() * minf(SPEED * delta, d.length())
	return false


func _sting_check() -> void:
	var sq = Run.squirrel
	if sq == null or sting_cd > 0.0 or not visible:
		return
	var reach := 12.0 if state != "hive" else 16.0
	var p: Vector2 = global_position + Vector2(0, 8 if state == "sit" else 14)
	if sq.global_position.distance_to(p) < reach and not sq.hidden():
		sting_cd = 1.6
		sq.sting(global_position)
		Run.popup.emit("OUCH!", sq.global_position + Vector2(0, -24), Color("f6c83a"))


func _buzz(delta: float) -> void:
	var sq = Run.squirrel
	if sq == null:
		return
	_buzz_t -= delta
	var d: float = sq.global_position.distance_to(global_position)
	if _buzz_t <= 0.0 and d < 70.0:
		_buzz_t = 1.2
		Snd.play("buzz", 0.1, lerpf(-6.0, -22.0, d / 70.0))
