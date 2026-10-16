extends Node2D
## A rival squirrel (darker coat). Slips into the park and picks a spot to spy
## from: up a tree (peeking out of the crown), tucked behind a trunk, or sitting
## far off in the open. If it sees you bury, it remembers that stash and comes
## back for ALL of it once you wander off. Run at it while well fed
## (hunger >= 60%) and it bolts; if you're weak it stands up and fights you off.

const SPEED := 66.0
const SIGHT := 140.0
const SCARE := 22.0

var state := "enter"   # enter, watch, sneak, dig, leave, flee, lunge
var perch := "far"     # tree, behind, far
var perch_tree: Node = null
var target := Vector2.ZERO
var watch_t := 0.0
var st_t := 0.0
var memory: Array = []
var loot := 0
var fight_cd := 0.0
var facing := 1.0
var anim: AnimatedSprite2D
var warn: Label
var _chat_t := 0.0


func _ready() -> void:
	add_to_group("rival")
	add_to_group("threat")
	anim = AnimatedSprite2D.new()
	anim.sprite_frames = Art.frames("sprites/rival")
	anim.position = Vector2(-1, -10)
	anim.play("run")
	add_child(anim)
	warn = Art.label("!", Color("f6c83a"), 9)
	warn.position = Vector2(-2, -32)
	warn.visible = false
	add_child(warn)
	_choose_perch()


func _choose_perch() -> void:
	var park = Run.park
	var sq = Run.squirrel
	var trees: Array = park.trees_list().filter(func(t): return t.climbable() and not t.has_hive \
		and (sq == null or sq.tree != t) and not park.rival_at_tree(t))
	var r := randf()
	if r < 0.4 and not trees.is_empty():
		perch = "tree"
		perch_tree = trees[randi() % trees.size()]
		var side := -1.0 if randf() < 0.5 else 1.0
		target = perch_tree.global_position + Vector2(side * 16.0, -30.0)
	elif r < 0.75 and not trees.is_empty():
		perch = "behind"
		perch_tree = trees[randi() % trees.size()]
		target = perch_tree.global_position + Vector2(randf_range(-3, 3), -5)
	else:
		perch = "far"
		target = park.far_spot(sq.global_position if sq else Vector2(192, 108))


func forget(stash: Node) -> void:
	memory.erase(stash)


func saw_bury(stash: Node) -> bool:
	if state != "watch" or global_position.distance_to(stash.global_position) > SIGHT:
		return false
	if not memory.has(stash):
		memory.append(stash)
		stash.witnesses.append(self)
	warn.visible = true
	warn.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(warn, "modulate:a", 0.0, 0.4)
	Snd.play("chatter", 0.1, -8.0)
	return true


func _process(delta: float) -> void:
	if not Run.playing():
		return
	st_t += delta
	fight_cd = maxf(0.0, fight_cd - delta)
	var sq = Run.squirrel
	memory = memory.filter(func(s): return is_instance_valid(s))
	match state:
		"enter":
			if perch == "tree" and is_instance_valid(perch_tree):
				# run to the trunk, then scamper up into the crown
				if _move_to(perch_tree.global_position + Vector2(0, 2), SPEED, delta):
					anim.play("climb")
					Snd.play("climb", 0.1, -8.0)
					var tw := create_tween()
					tw.tween_property(self, "global_position", target, 0.4)
					_enter_state("climbing")
			elif _move_to(target, SPEED, delta):
				_enter_state("watch")
		"climbing":
			if st_t > 0.42:
				_enter_state("watch")
		"watch":
			watch_t += delta
			_sit_pose(sq)
			if not memory.is_empty():
				var s: Node = memory[0]
				var away: float = sq.global_position.distance_to(s.global_position) if sq else 999.0
				if away > 70.0 or watch_t > 14.0:
					target = s.global_position
					_enter_state("sneak")
			elif watch_t > 45.0:
				_leave()
		"sneak":
			if not memory.is_empty() and is_instance_valid(memory[0]):
				target = memory[0].global_position
				if _move_to(target, SPEED * 0.9, delta):
					_enter_state("dig")
			else:
				_enter_state("watch")
		"dig":
			anim.play("dig")
			if memory.is_empty() or not is_instance_valid(memory[0]):
				_enter_state("watch")
			elif st_t > 1.4:
				var s: Node = memory[0]
				loot = s.acorns
				Run.stats.stolen += loot
				Run.popup.emit("-%d STOLEN" % loot, s.global_position + Vector2(0, -14), Color("f05a4a"))
				Snd.play("steal")
				Run.park.dirt(s.global_position, false)
				s.forget_all()
				s.queue_free()
				memory.clear()
				_leave()
		"leave", "flee":
			if _move_to(target, SPEED * (1.6 if state == "flee" else 1.15), delta):
				queue_free()
				return
		"lunge":
			if st_t > 0.5:
				if perch == "tree":
					perch = "behind"  # it hopped down to fight; it keeps watching from the trunk
					target = perch_tree.global_position + Vector2(0, -5)
					global_position = target
				_enter_state("watch")
	_confront(sq)
	_layering()


func _confront(sq: Node) -> void:
	if sq == null or state in ["leave", "flee", "enter", "climbing"] or (sq.hidden() and sq.tree != perch_tree):
		return
	var close: bool
	if perch == "tree" and state == "watch":
		close = sq.tree == perch_tree or sq.global_position.distance_to(perch_tree.global_position) < 16.0
	else:
		close = sq.global_position.distance_to(global_position) < SCARE
	if not close:
		return
	if Run.hunger >= Run.RIVAL_LINE:
		_flee()
	elif fight_cd <= 0.0 and state != "lunge":
		fight_cd = 2.2
		_enter_state("lunge")
		anim.play("fight")
		Snd.play("chatter", 0.05, -2.0)
		if perch == "tree":
			global_position = perch_tree.global_position + Vector2(0, 6)
		sq.shove(global_position, 6.0)
		Run.popup.emit("TOO WEAK", sq.global_position + Vector2(0, -32), Color("f2a088"))


func _flee() -> void:
	Run.stats.chased += 1
	Snd.play("flee")
	Run.popup.emit("SCRAM!", global_position + Vector2(0, -26), Color("fbf6ec"))
	if loot > 0:
		Run.park.scatter_acorns(global_position, loot)
		loot = 0
	for s in memory:
		if is_instance_valid(s):
			s.witnesses.erase(self)
	memory.clear()
	if perch == "tree" and state == "watch":
		global_position = perch_tree.global_position + Vector2(0, 4)
	target = Run.park.exit_point(global_position)
	_enter_state("flee")


func _leave() -> void:
	target = Run.park.exit_point(global_position)
	_enter_state("leave")


func _enter_state(s: String) -> void:
	state = s
	st_t = 0.0


func _move_to(p: Vector2, sp: float, delta: float) -> bool:
	var d := p - global_position
	if d.length() < 2.0:
		return true
	var step := d.normalized() * minf(sp * delta, d.length())
	global_position += step
	if absf(step.x) > 0.01:
		facing = signf(step.x)
	anim.flip_h = facing < 0.0
	anim.play("run")
	return false


func _sit_pose(sq: Node) -> void:
	anim.play("sit")
	if sq:
		facing = signf(sq.global_position.x - global_position.x) if absf(sq.global_position.x - global_position.x) > 2 else facing
	anim.flip_h = facing < 0.0
	_chat_t -= get_process_delta_time()
	if _chat_t <= 0.0:
		_chat_t = randf_range(5.0, 9.0)
		Snd.play("chatter", 0.15, -16.0)


func _layering() -> void:
	# peeking out of a crown: drawn over the leaves; otherwise normal y-sorting
	if perch == "tree" and state == "watch":
		z_as_relative = false
		z_index = 21
		anim.modulate = Color(0.85, 0.85, 0.85)
	else:
		z_as_relative = true
		z_index = 0
		anim.modulate = Color.WHITE
