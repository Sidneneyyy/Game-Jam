extends Node2D
## The park: one fixed screen. Holds the ground, props, trees, stashes, acorns,
## flowers and every creature, runs the season changes (sprouting, growing,
## snow), and directs the threats: the dog and the hawk never come at the same
## time or back to back, rivals drift in, bees settle, the fox prowls in winter.

const OakScript := preload("res://scripts/park/oak.gd")
const StashScript := preload("res://scripts/park/stash.gd")
const AcornScript := preload("res://scripts/park/acorn.gd")
const FlowerScript := preload("res://scripts/park/flower.gd")
const BushScript := preload("res://scripts/park/bush.gd")
const PrintsScript := preload("res://scripts/park/prints.gd")
const SquirrelScript := preload("res://scripts/actors/squirrel.gd")
const RivalScript := preload("res://scripts/actors/rival.gd")
const DogScript := preload("res://scripts/actors/dog.gd")
const HawkScript := preload("res://scripts/actors/hawk.gd")
const FoxScript := preload("res://scripts/actors/fox.gd")
const BeesScript := preload("res://scripts/actors/bees.gd")

const SCREEN := Vector2(384, 216)
const BOUNDS := Rect2(14, 26, 356, 180)       # where the squirrel can run
const GATES := [Vector2(-24, 116), Vector2(408, 112)]  # the path leaves the park here
const OAKS := [Vector2(46, 62), Vector2(338, 60), Vector2(150, 100), Vector2(244, 130),
	Vector2(96, 190), Vector2(300, 192), Vector2(196, 64)]
const START_SPROUTS := [Vector2(120, 140), Vector2(270, 80)]
const START_STASHES := [[Vector2(178, 150), 2], [Vector2(62, 140), 1]]
const BENCHES := [Vector2(110, 40), Vector2(282, 200)]
const LAMPS := [Vector2(40, 92), Vector2(344, 136), Vector2(192, 98)]
const BINS := [Vector2(232, 36), Vector2(156, 198)]
const ROCKS := [Vector2(24, 140), Vector2(330, 152), Vector2(204, 146)]
const BUSHES := [Vector2(28, 188), Vector2(362, 194), Vector2(214, 104), Vector2(300, 34)]
const MAX_TREES := 34
const FOREST := 28          # this many trees = the park has become a forest (true ending)
const MAX_GROUND_ACORNS := 12

var ground_a: Sprite2D
var ground_b: Sprite2D
var ents: Node2D
var props: Array = []      # seasonal sprites: [Sprite2D, base name]
var squirrel: Node = null
var squirrel_prints: Node2D
var fox_prints: Node2D
var fox_layer: CanvasLayer
var atmos: Node = null
var snow_acorns: Array = []

var threat: Node = null
var threat_cd := 14.0
var last_threat := ""
var rival_cd := 20.0
var bee_cd := 0.0
var fox_cd := -1.0
var _shake := 0.0
var _full_cd := 0.0
var _ground_tw: Tween


func _ready() -> void:
	Run.park = self
	ground_a = _ground_sprite()
	ground_b = _ground_sprite()
	squirrel_prints = PrintsScript.new()
	squirrel_prints.tex = Art.tex("park/print_squirrel")
	squirrel_prints.life = 10.0
	squirrel_prints.z_as_relative = false
	squirrel_prints.z_index = -6
	add_child(squirrel_prints)
	ents = Node2D.new()
	ents.y_sort_enabled = true
	add_child(ents)
	# fox prints sit above the winter darkness so you can see trails from afar
	fox_layer = CanvasLayer.new()
	fox_layer.layer = 3
	add_child(fox_layer)
	fox_prints = PrintsScript.new()
	fox_prints.tex = Art.tex("park/print_fox")
	fox_prints.life = 24.0
	fox_layer.add_child(fox_prints)
	_build_props()
	var alerts := preload("res://scripts/park/alerts.gd").new()
	add_child(alerts)
	Clock.season_changed.connect(_on_season)
	Clock.season_warning.connect(_on_warning)


func _ground_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.z_as_relative = false
	s.z_index = -10
	add_child(s)
	return s


# ------------------------------------------------------------------ setup
func new_game() -> void:
	for n in ents.get_children():
		if not n.has_meta("prop"):
			n.queue_free()
	for g in ["stash", "acorn", "hawk", "bees"]:
		for n in get_tree().get_nodes_in_group(g):
			n.queue_free()
	squirrel_prints.clear()
	fox_prints.clear()
	snow_acorns.clear()
	threat = null
	threat_cd = randf_range(12.0, 16.0)
	rival_cd = 22.0
	bee_cd = 0.0
	fox_cd = -1.0
	for i in range(OAKS.size()):
		add_tree("oak", OAKS[i], i % 2)
	for p in START_SPROUTS:
		add_tree("sprout", p)
	for s in START_STASHES:
		var st: Node = StashScript.new()
		st.acorns = s[1]
		st.position = s[0]
		add_child(st)
	for p in [Vector2(70, 100), Vector2(232, 160), Vector2(330, 96)]:
		_spawn_acorn(p, 0.0)
	squirrel = SquirrelScript.new()
	squirrel.position = Vector2(192, 150)
	ents.add_child(squirrel)
	_set_ground(Clock.season, 0.0)
	_apply_all(Clock.season)
	_spring_start()


func title_scene() -> void:
	## A calm park behind the title screen (no squirrel input).
	new_game()
	squirrel.visible = false
	squirrel.process_mode = Node.PROCESS_MODE_DISABLED


func show_season(s: int) -> void:
	## Title screen: flip the park through the seasons.
	_set_ground(s, 1.0)
	_apply_all(s)


func _build_props() -> void:
	for p in BENCHES:
		_prop("bench", p)
	for p in LAMPS:
		_prop("lamp", p)
	for p in BINS:
		_prop("bin", p)
	for i in range(ROCKS.size()):
		_prop("rock%d" % (i % 2), ROCKS[i])
	for p in BUSHES:
		var b: Sprite2D = BushScript.new()
		b.position = p
		b.set_meta("prop", true)
		ents.add_child(b)
	# the fence, with gaps where the path leaves the park
	for x in range(8, 376, 16):
		_prop("fence_h", Vector2(x + 8, 22))
		_prop("fence_h", Vector2(x + 8, 215))
	for y in range(28, 210, 16):
		if y > 96 and y < 132:
			continue
		_prop("fence_v", Vector2(5, y + 8))
		_prop("fence_v", Vector2(379, y + 8))


func _prop(base: String, p: Vector2) -> void:
	var s := Sprite2D.new()
	s.position = p
	s.set_meta("prop", true)
	ents.add_child(s)
	props.append([s, base])
	s.texture = Art.tex("park/%s_%s" % [base, Clock.NAMES[Clock.season]])
	s.offset = Vector2(0, -s.texture.get_height() / 2.0)


func add_tree(stage: String, p: Vector2, v := -1) -> Node:
	var t: Node2D = OakScript.new()
	t.setup(stage, v if v >= 0 else randi() % 2)
	t.position = p
	ents.add_child(t)
	return t


# ------------------------------------------------------------------ queries
func trees_list() -> Array:
	return get_tree().get_nodes_in_group("tree").filter(func(t): return not t.is_queued_for_deletion())


func tree_count() -> int:
	return trees_list().size()


func tree_near(p: Vector2, r: float) -> Node:
	var best: Node = null
	var bd := r
	for t in trees_list():
		var d: float = t.global_position.distance_to(p)
		if d < bd and t.stage != "sprout":
			bd = d
			best = t
	return best


func under_canopy(p: Vector2) -> bool:
	for t in trees_list():
		if t.under_canopy(p):
			return true
	return false


func stash_near(p: Vector2, r: float) -> Node:
	var best: Node = null
	var bd := r
	for s in get_tree().get_nodes_in_group("stash"):
		if s.is_queued_for_deletion():
			continue
		var d: float = s.global_position.distance_to(p)
		if d < bd:
			bd = d
			best = s
	return best


func flower_near(p: Vector2, r: float) -> Node:
	for f in get_tree().get_nodes_in_group("flower"):
		if f.global_position.distance_to(p + Vector2(0, -2)) < r:
			return f
	return null


func bush_near(p: Vector2, r: float) -> Node:
	for b in get_tree().get_nodes_in_group("bush"):
		if b.berries > 0 and b.global_position.distance_to(p) < r:
			return b
	return null


func rival_at_tree(t: Node) -> bool:
	for r in get_tree().get_nodes_in_group("rival"):
		if r.perch_tree == t:
			return true
	return false


func clamp_in(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, BOUNDS.position.x, BOUNDS.end.x), clampf(p.y, BOUNDS.position.y, BOUNDS.end.y))


func random_spot() -> Vector2:
	return Vector2(randf_range(BOUNDS.position.x + 10, BOUNDS.end.x - 10), randf_range(BOUNDS.position.y + 10, BOUNDS.end.y - 10))


func far_spot(from: Vector2) -> Vector2:
	var best := random_spot()
	for i in range(12):
		var c := random_spot()
		if c.distance_to(from) > best.distance_to(from):
			best = c
		if best.distance_to(from) > 150.0:
			break
	return best


func exit_point(p: Vector2) -> Vector2:
	var opts := [Vector2(-16, p.y), Vector2(SCREEN.x + 16, p.y), Vector2(p.x, SCREEN.y + 18), Vector2(p.x, 4)]
	var best: Vector2 = opts[0]
	for o in opts:
		if o.distance_to(p) < best.distance_to(p):
			best = o
	return best


func gate_point(p: Vector2) -> Vector2:
	return GATES[0] if p.distance_to(GATES[0]) < p.distance_to(GATES[1]) else GATES[1]


func vision_radius() -> float:
	return (64.0 - 14.0 * Clock.progress()) + (18.0 if Settings.assist else 0.0)


func path_dist(p: Vector2) -> float:
	## Same shape as the dirt path painted into the ground art.
	var c := Vector2(192, 114)
	var a := atan2((p.y - c.y) / 66.0, (p.x - c.x) / 128.0)
	var r := sqrt(pow((p.x - c.x) / 128.0, 2) + pow((p.y - c.y) / 66.0, 2))
	var loop := absf(r - (1.0 + 0.06 * sin(a * 3.0 + 1.3))) * 70.0
	var cross := absf(p.y - (c.y + 20.0 * sin(p.x / 60.0))) + (99.0 if p.x > 120 and p.x < 264 else 0.0)
	return minf(loop, cross)


func _room_for_tree(p: Vector2) -> bool:
	if not BOUNDS.grow(-8).has_point(p) or tree_count() >= MAX_TREES:
		return false
	for t in trees_list():
		if t.global_position.distance_to(p) < 17.0:
			return false
	for arr in props:
		if arr[0].global_position.distance_to(p) < 14.0 and not String(arr[1]).begins_with("fence"):
			return false
	return true


# ------------------------------------------------------------------ actions from the squirrel
func bury(p: Vector2) -> Node:
	var s: Node = stash_near(p, 10.0)
	if s:
		s.add(1)
	else:
		s = StashScript.new()
		s.acorns = 1
		s.position = clamp_in(p)
		add_child(s)
	# anyone watching saw that
	var seen := false
	for r in get_tree().get_nodes_in_group("rival"):
		seen = r.saw_bury(s) or seen
	if seen:
		Run.popup.emit("SEEN!", s.global_position + Vector2(0, -12), Color("ff9a3a"))
	_check_burrows()
	return s


func _check_burrows() -> void:
	for t in trees_list():
		if not t.climbable() or t.has_burrow or t.has_hive:
			continue
		var n := 0
		for s in get_tree().get_nodes_in_group("stash"):
			if not s.is_queued_for_deletion() and s.global_position.distance_to(t.global_position) < 40.0:
				n += s.acorns
		t.set_burrow_n(n)
		if n >= 3:
			t.add_burrow()


func pickup(sq: Node) -> void:
	_full_cd = maxf(0.0, _full_cd - get_physics_process_delta_time())
	for a in get_tree().get_nodes_in_group("acorn"):
		if a.is_queued_for_deletion() or not a.can_pick():
			continue
		if a.global_position.distance_to(sq.global_position) < 7.0:
			if Run.cheeks < Run.MAX_CHEEKS:
				Run.cheeks += 1
				a.queue_free()
				Snd.play("pickup")
				Run.changed.emit()
			elif _full_cd <= 0.0:
				_full_cd = 1.5
				Run.popup.emit("CHEEKS FULL", sq.global_position + Vector2(0, -26), Color("f2cc90"))


func scatter_acorns(p: Vector2, n: int) -> void:
	for i in range(n):
		var a := _spawn_acorn(clamp_in(p + Vector2(randf_range(-16, 16), randf_range(-10, 10))), 8.0)
		a.vz = randf_range(40, 70)


func flower_eaten(f: Node) -> void:
	# bees on that flower get shooed off
	for b in get_tree().get_nodes_in_group("bees"):
		if b.flower == f:
			b._pick_flower()
			b.state = "fly"


func bees_on_flower(swarm: Node, f: Node, delta: float) -> void:
	if atmos and atmos.raining:
		return  # bees hunker down in the rain
	var best: Node = null
	var bd := 44.0
	for t in trees_list():
		if t.stage == "sprout" or t.has_burrow or t.has_hive:
			continue
		var d: float = t.global_position.distance_to(f.global_position)
		if d < bd:
			bd = d
			best = t
	if best:
		best.bee_progress(delta)
		if best.hive_progress >= 1.0:
			best.add_hive(swarm)
			swarm.settle(best)


func dirt(p: Vector2, snow: bool) -> void:
	var c := CPUParticles2D.new()
	c.position = p
	c.z_as_relative = false
	c.z_index = 5
	c.amount = 8
	c.one_shot = true
	c.explosiveness = 1.0
	c.lifetime = 0.45
	c.direction = Vector2(0, -1)
	c.spread = 70.0
	c.initial_velocity_min = 25.0
	c.initial_velocity_max = 55.0
	c.gravity = Vector2(0, 180)
	c.texture = Art.dot_texture(1, 1, Color.WHITE)
	c.color = Color("f4f8fc") if snow else Color("8e6640")
	add_child(c)
	c.emitting = true
	get_tree().create_timer(1.0).timeout.connect(c.queue_free)


func puff(p: Vector2, snow: bool) -> void:
	## a little kicked-up dust (or snow) behind a sprinting squirrel
	var c := CPUParticles2D.new()
	c.position = p
	c.z_as_relative = false
	c.z_index = -2
	c.amount = 3
	c.one_shot = true
	c.explosiveness = 1.0
	c.lifetime = 0.35
	c.direction = Vector2(0, -1)
	c.spread = 80.0
	c.initial_velocity_min = 8.0
	c.initial_velocity_max = 18.0
	c.gravity = Vector2(0, 30)
	c.texture = Art.dot_texture(1, 1, Color.WHITE)
	c.color = Color(1, 1, 1, 0.9) if snow else [Color("c8b48a"), Color("d6c08a"), Color("b8945c"), Color("f2f6fa")][Clock.season]
	add_child(c)
	c.emitting = true
	get_tree().create_timer(0.8).timeout.connect(c.queue_free)


func shake(amount: float) -> void:
	if Settings.shake:
		_shake = maxf(_shake, amount)


# ------------------------------------------------------------------ spawning
func _spawn_acorn(p: Vector2, h: float) -> Node:
	var a: Node2D = AcornScript.new()
	a.position = p
	a.drop_from(h)
	add_child(a)
	return a


func spawn_flowers() -> void:
	var placed: Array = []
	var oaks := trees_list().filter(func(t): return t.climbable())
	var tries := 0
	while placed.size() < 20 and tries < 400:
		tries += 1
		var p: Vector2
		if placed.size() < 9 and not oaks.is_empty():  # a ring of flowers near trees: the bee danger
			var t: Node = oaks[randi() % oaks.size()]
			var a := randf() * TAU
			p = t.global_position + Vector2(cos(a) * randf_range(16, 34), sin(a) * randf_range(10, 24))
		else:
			p = random_spot()
		if not BOUNDS.grow(-4).has_point(p) or path_dist(p) < 9.0:
			continue
		var ok := true
		for q in placed:
			if q.distance_to(p) < 12.0:
				ok = false
		for t in trees_list():
			if t.global_position.distance_to(p) < 9.0:
				ok = false
		if not ok:
			continue
		placed.append(p)
		var f: Node2D = FlowerScript.new()
		f.position = p
		ents.add_child(f)


func spawn_swarm(at := Vector2.INF) -> Node:
	var b: Node2D = BeesScript.new()
	b.position = at if at != Vector2.INF else exit_point(random_spot()) + Vector2(0, -10)
	add_child(b)
	return b


func spawn_rival() -> Node:
	var r: Node2D = RivalScript.new()
	var side := randi() % 3
	r.position = [Vector2(-12, randf_range(50, 190)), Vector2(396, randf_range(50, 190)), Vector2(randf_range(40, 340), 228)][side]
	ents.add_child(r)
	return r


func spawn_dog() -> Node:
	var d: Node2D = DogScript.new()
	d.position = [Vector2(-4, 116), Vector2(388, 112)][randi() % 2]  # peeking in at a gate
	ents.add_child(d)
	d.done.connect(_threat_done)
	threat = d
	last_threat = "dog"
	return d


func spawn_hawk() -> Node:
	var h: Node2D = HawkScript.new()
	add_child(h)
	h.done.connect(_threat_done)
	threat = h
	last_threat = "hawk"
	return h


func spawn_fox() -> Node:
	var f: Node2D = FoxScript.new()
	f.position = far_spot(squirrel.global_position if squirrel else Vector2(192, 108))
	ents.add_child(f)
	return f


func _threat_done() -> void:
	threat = null
	# always a breather before the next one
	threat_cd = randf_range(20.0, 32.0) / (1.0 + 0.1 * (Clock.year - 1))


# ------------------------------------------------------------------ frame
func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 12.0)
		position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)).round()
	elif position != Vector2.ZERO:
		position = Vector2.ZERO
	if not Run.playing():
		return
	_director(delta)
	if Clock.season == Clock.AUTUMN:
		_drop_acorns(delta)


func _director(delta: float) -> void:
	var s := Clock.season
	# dog or hawk (summer + fall): one at a time, never back to back
	if (s == Clock.SUMMER or s == Clock.AUTUMN) and (threat == null or not is_instance_valid(threat)):
		threat = null
		threat_cd -= delta
		if threat_cd <= 0.0 and Clock.time_left() > 6.0:
			var dog_first := randf() < 0.5
			if last_threat != "":
				dog_first = randf() < (0.35 if last_threat == "dog" else 0.65)
			if dog_first:
				spawn_dog()
			else:
				spawn_hawk()
	# rivals come to spy (not in winter)
	if s != Clock.WINTER:
		rival_cd -= delta
		if rival_cd <= 0.0:
			rival_cd = randf_range(18.0, 30.0)
			var cap: int = [1, 1, 2, 0][s] + (1 if Clock.year > 1 else 0)
			if get_tree().get_nodes_in_group("rival").size() < cap and Clock.time_left() > 12.0:
				spawn_rival()
	# bees arrive through spring; never more than three swarms in the park
	if s == Clock.SPRING:
		bee_cd -= delta
		if bee_cd <= 0.0:
			bee_cd = randf_range(25.0, 35.0)
			var swarms := get_tree().get_nodes_in_group("bees").size()
			if swarms < 3 and not get_tree().get_nodes_in_group("flower").is_empty():
				spawn_swarm()
	# the fox turns up a little after winter starts
	if s == Clock.WINTER and fox_cd > 0.0:
		fox_cd -= delta
		if fox_cd <= 0.0:
			for i in range(mini(1 + (Clock.year - 1), 3)):
				spawn_fox()


func _drop_acorns(delta: float) -> void:
	var on_ground := get_tree().get_nodes_in_group("acorn").size()
	for t in trees_list():
		if not t.climbable():
			continue
		t.drop_t -= delta
		if t.drop_t <= 0.0:
			t.drop_t = randf_range(22.0, 32.0) * (1.6 if t.young else 1.0)
			if on_ground < MAX_GROUND_ACORNS:
				var p := clamp_in(t.global_position + Vector2(randf_range(-16, 16), randf_range(-4, 10)))
				_spawn_acorn(p, 26.0)
				on_ground += 1


# ------------------------------------------------------------------ seasons
func _on_warning(next: int) -> void:
	## A few seconds before each change, say what the next season will do to you.
	Snd.play("warn")
	if squirrel == null:
		return
	var msg := ""
	match next:
		Clock.WINTER:
			var n := get_tree().get_nodes_in_group("acorn").size()
			msg = "SNOW SOON: BURY THE %d ACORNS ON THE GROUND!" % n if n > 0 else "SNOW SOON: THE GROUND WILL FREEZE"
		Clock.SPRING:
			msg = "THAW SOON: FORGOTTEN STASHES WILL SPROUT"
		Clock.SUMMER:
			msg = "SUMMER SOON: THE DOG AND THE HAWK ARE COMING"
		Clock.AUTUMN:
			msg = "FALL SOON: ACORNS! EAT EXTRA TO FLUFF UP"
	Run.popup.emit(msg, Vector2(192, 196), Clock.COLORS[next])


func _on_season(s: int) -> void:
	_set_ground(s, 3.0)
	_apply_all(s)
	Snd.play("season")
	threat_cd = randf_range(10.0, 16.0)
	match s:
		Clock.SPRING:
			_sprout_forgotten()
			_spring_start()
		Clock.SUMMER:
			for f in get_tree().get_nodes_in_group("flower"):
				f.wilt()
			for b in get_tree().get_nodes_in_group("bees"):
				b.leave()
			for t in trees_list():
				if t.stage == "sprout":
					t.grow()
			rival_cd = 8.0
		Clock.AUTUMN:
			for t in trees_list():
				if t.stage == "sapling":
					t.grow()
				t.drop_t = randf_range(2.0, 12.0)
			rival_cd = 6.0
		Clock.WINTER:
			var lost := 0
			for a in get_tree().get_nodes_in_group("acorn"):
				snow_acorns.append(a.global_position)  # lost under the snow... for now
				dirt(a.global_position, true)
				a.queue_free()
				lost += 1
			if lost > 0 and squirrel:
				Run.popup.emit("%d ACORNS LOST IN THE SNOW" % lost, Vector2(192, 196), Color("a8d8f8"))
			for r in get_tree().get_nodes_in_group("rival"):
				r._leave()
			for dg in get_tree().get_nodes_in_group("dog"):
				dg._leave()
			for f in get_tree().get_nodes_in_group("flower"):
				f.wilt()
			fox_cd = 6.0
			if squirrel and Run.fluff < 40.0:
				Run.popup.emit("TOO THIN FOR WINTER!", squirrel.global_position + Vector2(0, -32), Color("a8d8f8"))
				Snd.play("shiver")


func _spring_start() -> void:
	spawn_flowers()
	bee_cd = 6.0
	var hives := 0
	for t in trees_list():
		if t.has_hive:
			hives += 1
	for i in range(maxi(0, 2 - hives)):
		spawn_swarm()


func _sprout_forgotten() -> void:
	## Spring: some forgotten stashes (one tree per stash, however many acorns)
	## and a few acorns lost in the snow come up as sprouts.
	for f in get_tree().get_nodes_in_group("fox"):
		f.queue_free()
	fox_prints.clear()
	squirrel_prints.clear()
	var n := 0
	var delay := 0.0
	for s in get_tree().get_nodes_in_group("stash"):
		if s.is_queued_for_deletion():
			continue
		var chance := 1.0 if s.acorns >= 2 else 0.7  # a bigger stash is a surer bet
		if randf() < chance and _room_for_tree(s.global_position):
			var p: Vector2 = s.global_position
			s.forget_all()
			s.queue_free()
			_sprout_at(p, delay)
			delay += 0.25
			n += 1
	for p in snow_acorns:
		if randf() < 0.25 and _room_for_tree(p):
			_sprout_at(p, delay)
			delay += 0.25
			n += 1
	snow_acorns.clear()
	Run.stats.sprouted += n


func _sprout_at(p: Vector2, delay: float) -> void:
	var t := add_tree("sprout", p)
	t.visible = false
	get_tree().create_timer(0.6 + delay).timeout.connect(func():
		if is_instance_valid(t):
			t.visible = true
			t.pop_in()
			Snd.play("sprout", 0.1, -4.0)
			Run.popup.emit("SPROUT!", p + Vector2(0, -14), Color("a8dc70")))


func _apply_all(s: int) -> void:
	for t in trees_list():
		t.apply_season(s)
	for b in get_tree().get_nodes_in_group("bush"):
		b.apply_season(s)
	for st in get_tree().get_nodes_in_group("stash"):
		st.apply_season(s)
	for arr in props:
		var sp: Sprite2D = arr[0]
		sp.texture = Art.tex("park/%s_%s" % [arr[1], Clock.NAMES[s]])
	if atmos:
		atmos.set_season(s)


func _set_ground(s: int, dur: float) -> void:
	# fade the new season's ground in over the old one
	if _ground_tw and _ground_tw.is_valid():
		_ground_tw.kill()
	ground_b.texture = ground_a.texture
	ground_b.modulate.a = 1.0
	ground_b.z_index = -11
	ground_a.texture = Art.tex("park/ground_" + Clock.NAMES[s])
	ground_a.z_index = -10
	if dur <= 0.0:
		ground_a.modulate.a = 1.0
		return
	ground_a.modulate.a = 0.0
	_ground_tw = create_tween()
	_ground_tw.tween_property(ground_a, "modulate:a", 1.0, dur)
