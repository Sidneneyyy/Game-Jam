extends Node
## Balance bot: plays a whole year with simple sensible priorities, at speed, and
## reports how close it came to starving or freezing. Not part of the game.
## Run: Godot --headless --path game -- --bot [--speed=4] [--skill=1.0]

var main: Node
var sq: Node
var park: Node
var blog := {"min_hunger": 100.0, "min_warmth": 100.0, "fluff_at_winter": -1.0, "stash_at_winter": 0}
var _think := 0.0
var _goal := Vector2.ZERO
var _mode := ""
var skill := 1.0
var modes := {}


func run() -> void:
	skill = float(main.args.get("skill", "1.0"))
	Engine.time_scale = float(main.args.get("speed", "4"))
	main.start_run()
	await get_tree().process_frame
	sq = Run.squirrel
	park = Run.park
	Clock.season_changed.connect(_on_season)
	Run.state_changed.connect(_on_state)


func _on_season(s: int) -> void:
	var stashed := 0
	for st in get_tree().get_nodes_in_group("stash"):
		stashed += st.acorns
	print("[bot] -> %s  hunger %.0f fluff %.0f warmth %.0f cheeks %d stashed %d trees %d stolen %d hits %d" % [
		Clock.TITLES[s], Run.hunger, Run.fluff, Run.warmth, Run.cheeks, stashed, park.tree_count(), Run.stats.stolen, Run.stats.hits])
	var m := {}
	for k in modes:
		m[k] = int(modes[k])
	print("[bot]    time spent: ", m, " acorns on ground ", get_tree().get_nodes_in_group("acorn").size())
	modes.clear()
	if s == Clock.WINTER:
		blog.fluff_at_winter = Run.fluff
		blog.stash_at_winter = stashed


func _on_state(s: int) -> void:
	if s == Run.ENDED and main.args.has("endless") and not Run.endless:
		await get_tree().create_timer(5.0 * Engine.time_scale).timeout
		print("[bot] year done -> keep going (trees %d)" % park.tree_count())
		main.menus.hide_all()
		main._keep_going()
		return
	if s == Run.OVER or s == Run.ENDED:
		await get_tree().create_timer(1.0 * Engine.time_scale).timeout
		print("[bot] RESULT %s  season %s  min hunger %.0f  min warmth %.0f  fluff@winter %.0f  stash@winter %d" % [
			"SURVIVED" if s == Run.ENDED else "DIED (" + Run.death + ")", Clock.TITLES[Clock.season],
			blog.min_hunger, blog.min_warmth, blog.fluff_at_winter, blog.stash_at_winter])
		print("[bot] stats ", Run.stats, " trees ", park.tree_count(), " score ", Run.score())
		get_tree().quit()


func _physics_process(delta: float) -> void:
	if sq == null or not Run.playing():
		return
	blog.min_hunger = minf(blog.min_hunger, Run.hunger)
	blog.min_warmth = minf(blog.min_warmth, Run.warmth)
	modes[_mode] = modes.get(_mode, 0.0) + delta
	_think -= delta
	if _think <= 0.0:
		_think = 0.15 / skill
		_decide()
	_steer()


func _threat() -> Node:
	for d in get_tree().get_nodes_in_group("dog"):
		if d.state in ["arrive", "chase"]:
			return d
	for f in get_tree().get_nodes_in_group("fox"):
		if f.state == "chase" or f.global_position.distance_to(sq.global_position) < 70.0:
			return f
	for h in get_tree().get_nodes_in_group("hawk"):
		if h.phase == "mark":
			return h
	return null


func _safe_tree() -> Node:
	var best: Node = null
	var bd := 1e9
	for t in park.trees_list():
		if not t.climbable() or (t.has_hive and Clock.season != Clock.WINTER):
			continue
		var d: float = t.global_position.distance_to(sq.global_position)
		if d < bd:
			bd = d
			best = t
	return best


func _nearest(group: String, filter := Callable()) -> Node:
	var best: Node = null
	var bd := 1e9
	for n in get_tree().get_nodes_in_group(group):
		if n.is_queued_for_deletion() or (filter.is_valid() and not filter.call(n)):
			continue
		var d: float = n.global_position.distance_to(sq.global_position)
		if d < bd:
			bd = d
			best = n
	return best


func _decide() -> void:
	var s := Clock.season
	var th := _threat()
	# up a tree / in a burrow: stay while danger or cold, else come down
	if sq.state == "tree" or sq.state == "burrow":
		if Engine.get_physics_frames() % 300 == 0:
			print("[bot]    hiding from ", th.name if th else "nothing", " ", th.get("state") if th else "", " dist ", int(th.global_position.distance_to(sq.global_position)) if th else -1, " sq ", sq.state)
		var cold: bool = s == Clock.WINTER and sq.state == "burrow" and Run.warmth < 95.0 and Run.fluff > 5.0 and Run.hunger > 30.0
		if th == null and not cold:
			sq._climb()
		_mode = "hide"
		return
	if sq.state != "move":
		return
	# danger: run for the nearest safe tree
	if th != null:
		var t := _safe_tree()
		if t:
			_go(t.global_position + Vector2(0, 3), "flee")
			if sq.global_position.distance_to(t.global_position) < 12.0:
				sq._climb()
			return
	# winter: keep warm in a burrow, eat from stashes
	if s == Clock.WINTER:
		if Run.warmth < 45.0:
			var b := _nearest("tree", func(t): return t.has_burrow)
			if b:
				_go(b.global_position + Vector2(0, 3), "warm")
				if sq.global_position.distance_to(b.global_position) < 12.0:
					sq._climb()
				return
	# eat when hungry
	var fluffs: bool = not main.args.has("nofluff")
	if Run.cheeks > 0 and (Run.hunger < 55.0 or (fluffs and s == Clock.AUTUMN and Run.fluff < 85.0 and Run.hunger > 70.0)):
		sq._eat()
		return
	# chase rivals off when strong enough
	if s != Clock.WINTER and Run.hunger >= Run.RIVAL_LINE + 5:
		var r := _nearest("rival", func(n): return n.state in ["watch", "sneak", "dig"])
		var busy_fall := s == Clock.AUTUMN and Run.cheeks < Run.MAX_CHEEKS and _nearest("acorn") != null
		if r and r.global_position.distance_to(sq.global_position) < (60.0 if busy_fall else 160.0):
			var rp: Vector2 = r.perch_tree.global_position if (r.perch == "tree" and r.state == "watch") else r.global_position
			_go(rp, "chase")
			return
	# spring flowers (near trees first, to keep bees off), summer berries
	if s == Clock.SPRING and Run.hunger < 93.0:
		var f := _nearest("flower")
		if f:
			_go(f.global_position + Vector2(0, 1), "flower")
			if sq.global_position.distance_to(f.global_position) < 10.0:
				sq._eat()
			return
	if s == Clock.SUMMER and Run.hunger < 85.0:
		var b := _nearest("bush", func(n): return n.berries > 0)
		if b:
			_go(b.global_position + Vector2(0, 6), "berry")
			if sq.global_position.distance_to(b.global_position) < 14.0:
				sq._eat()
			return
	# need food and have none on me: dig a stash up
	if Run.cheeks == 0 and (Run.hunger < 50.0 or s == Clock.WINTER and Run.hunger < 70.0):
		var st := _nearest("stash")
		if st:
			_go(st.global_position, "dig")
			if sq.global_position.distance_to(st.global_position) < 8.0:
				sq._act()
			return
	# gather acorns
	if Run.cheeks < Run.MAX_CHEEKS:
		var a := _nearest("acorn", func(n): return n.can_pick())
		if a:
			_go(a.global_position, "gather")
			return
	# stash a full mouth (round a tree, to earn a burrow), unless rivals are watching
	if Run.cheeks > 0 and s != Clock.WINTER and (Run.cheeks >= 3 or s != Clock.AUTUMN or _nearest("acorn") == null) and not (fluffs and s == Clock.AUTUMN and Run.fluff < 70.0):
		var watched := false
		for r in get_tree().get_nodes_in_group("rival"):
			watched = watched or r.state == "watch"
		if not watched or Run.hunger < Run.RIVAL_LINE:
			var t := _nearest("tree", func(n): return n.climbable() and not n.has_hive)
			if t:
				var spot: Vector2 = t.global_position + Vector2(-18 if (t.burrow_n % 2) == 0 else 18, 16)
				_go(spot, "bury")
				if sq.global_position.distance_to(spot) < 5.0:
					sq._act()
				return
	_go(Vector2(192, 120), "idle")


func _go(p: Vector2, mode: String) -> void:
	_goal = park.clamp_in(p)
	_mode = mode


func _steer() -> void:
	if sq.state != "move":
		sq.bot_dir = Vector2.ZERO
		return
	var d: Vector2 = _goal - sq.global_position
	sq.bot_dir = d.normalized() if d.length() > 2.0 else Vector2.ZERO
	sq.bot_sprint = _mode in ["flee", "chase"] and skill >= 1.0
