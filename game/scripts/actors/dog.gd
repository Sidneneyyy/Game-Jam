extends Node2D
## The park dog (summer + fall). Bursts in through a gate and chases you. Get up
## a tree without bees (or into a burrow): it barks at the trunk for a bit, gets
## bored and trots off out of the park until its next visit.

const SPEED := 86.0
var state := "arrive"  # arrive (barking at the gate), chase, bark, caught, leave
var st_t := 0.0
var facing := 1.0
var anim: AnimatedSprite2D
var target := Vector2.ZERO
var _bark_t := 0.0
var _bark_spot := Vector2.INF
signal done


func _ready() -> void:
	add_to_group("dog")
	add_to_group("threat")
	anim = AnimatedSprite2D.new()
	anim.sprite_frames = Art.frames("sprites/dog")
	anim.position = Vector2(0, -10)
	anim.play("run")
	add_child(anim)
	Snd.play("bark")


func _process(delta: float) -> void:
	if not Run.playing():
		anim.pause()
		return
	if not anim.is_playing():
		anim.play()
	st_t += delta
	var sq = Run.squirrel
	match state:
		"arrive":
			anim.play("bark")
			facing = 1.0 if global_position.x < 192.0 else -1.0
			anim.flip_h = facing < 0.0
			_bark_t -= delta
			if _bark_t <= 0.0:
				_bark_t = 0.5
				Snd.play("bark2", 0.1, -2.0)
			if st_t > 1.3:
				_set_state("chase")
		"chase":
			if sq == null:
				_leave()
			elif sq.hidden():
				# treed you: go bark at the trunk (pick the side once, on the way in)
				var base: Vector2 = sq.tree.global_position if sq.tree else sq.global_position
				if _bark_spot == Vector2.INF:
					var side := signf(global_position.x - base.x) if absf(global_position.x - base.x) > 1.0 else -1.0
					_bark_spot = base + Vector2(side * 13.0, 6)
				if _run_to(_bark_spot, SPEED, delta) or st_t > 8.0:
					_set_state("bark")
			else:
				_bark_spot = Vector2.INF
				_run_to(sq.global_position, SPEED * (1.0 + 0.06 * (Clock.year - 1)), delta)
				if global_position.distance_to(sq.global_position) < 10.0:
					if sq.take_hit(18.0, global_position, true):
						_set_state("caught")
				elif st_t > 14.0:
					_leave()
		"bark":
			anim.play("bark")
			if sq and sq.tree:
				facing = signf(sq.tree.global_position.x - global_position.x) if absf(sq.tree.global_position.x - global_position.x) > 1 else facing
			anim.flip_h = facing < 0.0
			_bark_t -= delta
			if _bark_t <= 0.0:
				_bark_t = 0.7
				Snd.play("bark2", 0.1, -3.0)
			if st_t > 3.2:
				_leave()
			elif sq and not sq.hidden() and st_t > 0.5:
				_set_state("chase")  # you came down too early!
		"caught":
			anim.play("idle")  # happy tail wag over the dropped acorns
			if st_t > 0.9:
				_leave()
		"leave":
			if _run_to(target, SPEED * 0.8, delta):
				done.emit()
				queue_free()


func _leave() -> void:
	target = Run.park.gate_point(global_position)
	_set_state("leave")


func _set_state(s: String) -> void:
	state = s
	st_t = 0.0


func _run_to(p: Vector2, sp: float, delta: float) -> bool:
	var d := p - global_position
	if d.length() < 2.0:
		anim.play("idle")
		return true
	var step := d.normalized() * minf(sp * delta, d.length())
	global_position += step
	if absf(step.x) > 0.05:
		facing = signf(step.x)
	anim.flip_h = facing < 0.0
	anim.play("run")
	return false
