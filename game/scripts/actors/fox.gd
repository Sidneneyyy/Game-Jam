extends Node2D
## Winter's only hunter. It pads around the dark park leaving prints in the snow
## (you can see those from afar); the fox itself only shows inside your little
## circle of sight. If it spots you it gives chase: get up a tree or into a burrow.

const WALK := 30.0
const RUN := 70.0
var state := "wander"  # wander, chase, sniff, retreat
var st_t := 0.0
var target := Vector2.ZERO
var facing := 1.0
var anim: AnimatedSprite2D
var _last_print := Vector2.ZERO
var _print_side := 1.0


func _ready() -> void:
	add_to_group("fox")
	add_to_group("threat")
	anim = AnimatedSprite2D.new()
	anim.sprite_frames = Art.frames("sprites/fox")
	anim.position = Vector2(-3, -8)
	anim.play("walk")
	add_child(anim)
	_last_print = global_position
	target = Run.park.random_spot()


func _process(delta: float) -> void:
	if not Run.playing():
		return
	st_t += delta
	var sq = Run.squirrel
	var sees: bool = sq != null and not sq.hidden() and sq.global_position.distance_to(global_position) < Run.park.vision_radius() + 6.0
	match state:
		"wander":
			if _go(target, WALK, delta, "walk"):
				_to("sniff")
			if sees:
				Snd.play("yip")
				_to("chase")
		"sniff":
			anim.play("sniff")
			if st_t > 1.8:
				target = Run.park.random_spot()
				_to("wander")
			if sees:
				Snd.play("yip")
				_to("chase")
		"chase":
			if sq == null or sq.hidden() or st_t > 6.5:
				_to("sniff")
			else:
				_go(sq.global_position, RUN * (1.0 + 0.06 * (Clock.year - 1)), delta, "run")
				if global_position.distance_to(sq.global_position) < 9.0:
					anim.play("pounce")
					if sq.take_hit(18.0, global_position, true, 18.0):
						target = Run.park.far_spot(sq.global_position)
						_to("retreat")
		"retreat":
			if _go(target, RUN * 0.8, delta, "run") or st_t > 3.0:
				target = Run.park.random_spot()
				_to("wander")


func _to(s: String) -> void:
	state = s
	st_t = 0.0


func _go(p: Vector2, sp: float, delta: float, a: String) -> bool:
	var d := p - global_position
	if d.length() < 2.0:
		return true
	var step := d.normalized() * minf(sp * delta, d.length())
	global_position = Run.park.clamp_in(global_position + step)
	if absf(step.x) > 0.02:
		facing = signf(step.x)
	anim.flip_h = facing < 0.0
	anim.position.x = -3.0 * facing
	anim.play(a)
	# paw prints every few pixels, alternating sides
	if global_position.distance_to(_last_print) > 7.0:
		var ang := snappedf(step.angle() + PI / 2.0, PI / 4.0)
		var side := Vector2(-step.y, step.x).normalized() * 1.5 * _print_side
		Run.park.fox_prints.add(global_position + side, ang)
		_print_side = -_print_side
		_last_print = global_position
	return false
