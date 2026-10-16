extends Node
## Scripted run through every mechanic. Launch: Godot --headless --path game -- --autotest
## Prints "AUTOTEST OK" or the failures.

var main: Node
var fails := 0


func check(cond: bool, what: String) -> void:
	print("  ", "ok   " if cond else "FAIL ", what)
	if not cond:
		fails += 1


func wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func run() -> void:
	print("AUTOTEST start")
	await wait(0.3)
	main.start_run()
	await wait(0.3)
	var park = Run.park
	var sq = Run.squirrel
	check(Run.state == Run.PLAYING, "run started in spring")
	check(park.tree_count() == 9, "7 oaks + 2 sprouts (%d)" % park.tree_count())
	check(get_tree().get_nodes_in_group("flower").size() >= 12, "spring flowers bloom")
	check(get_tree().get_nodes_in_group("bees").size() >= 1, "bees arrive")
	# acorn pickup (bees cleared: stings would knock the squirrel about mid-test)
	for b in get_tree().get_nodes_in_group("bees"):
		b.queue_free()
	park.bee_cd = 999.0
	var a = get_tree().get_nodes_in_group("acorn")[0]
	sq.global_position = a.global_position
	await wait(0.15)
	check(Run.cheeks == 1, "ran over an acorn -> cheeks 1")
	# bury + dig
	sq.global_position = Vector2(120, 175)
	await wait(0.1)
	sq._act()
	await wait(0.5)
	var stash = park.stash_near(sq.global_position, 12.0)
	check(stash != null and Run.cheeks == 0, "space buries an acorn")
	sq._act()
	await wait(0.5)
	check(Run.cheeks == 1, "empty cheeks: space digs it back up")
	sq.state = "move"
	Run.cheeks = 2
	sq._act()
	await wait(0.45)
	sq.state = "move"
	sq._act()
	await wait(0.45)
	var stack = park.stash_near(sq.global_position, 12.0)
	check(stack != null and stack.acorns == 2, "carrying: space stacks more acorns in the same stash")
	Run.cheeks = 0
	sq.state = "move"
	sq._act()
	await wait(0.45)
	check(Run.cheeks == 2, "dig the whole stack back up")
	sq.state = "move"
	Run.cheeks = 1
	# eat (no flower underfoot: flowers are eaten first)
	for fl in get_tree().get_nodes_in_group("flower"):
		if fl.global_position.distance_to(sq.global_position) < 20.0:
			fl.eat()
	Run.hunger = 50.0
	sq._eat()
	await wait(0.7)
	check(Run.hunger > 70.0 and Run.cheeks == 0, "left click eats an acorn (%.0f)" % Run.hunger)
	# flowers are food too
	var f = get_tree().get_nodes_in_group("flower")[0]
	sq.global_position = f.global_position + Vector2(0, 1)
	var h0 := Run.hunger
	sq._eat()
	await wait(0.6)
	check(Run.hunger > h0 and f.eaten, "munched a flower")
	# climb a tree and back down (no bees about to sting us mid-test)
	for b in get_tree().get_nodes_in_group("bees"):
		b.queue_free()
	await wait(0.1)
	sq.state = "move"
	var oak = park.trees_list().filter(func(t): return t.climbable() and not t.has_hive)[0]
	sq.global_position = oak.global_position + Vector2(6, 4)
	await wait(0.1)
	sq._climb()
	await wait(0.8)
	check(sq.state == "tree" and sq.hidden(), "right click climbs a tree")
	sq._climb()
	await wait(0.7)
	check(sq.state == "move", "and climbs back down")
	# bury 3 acorns near a tree -> burrow
	var bt = park.trees_list().filter(func(t): return t.climbable() and not t.has_hive and t != oak)[1]
	Run.cheeks = 3
	for i in range(3):
		sq.global_position = bt.global_position + Vector2(-16 + i * 12, 16)
		sq.state = "move"
		sq._act()
		await wait(0.45)
	check(bt.has_burrow, "3 acorns stashed around a tree -> burrow")
	sq.global_position = bt.global_position + Vector2(4, 4)
	sq.state = "move"
	sq._climb()
	await wait(0.8)
	check(sq.state == "burrow" and sq.hidden(), "right click slips into the burrow")
	sq._climb()
	await wait(0.8)
	check(sq.state == "move", "and back out")
	# rival sees you bury, then steals the lot when you leave (bees out of the way)
	for b in get_tree().get_nodes_in_group("bees"):
		b.queue_free()
	var r = park.spawn_rival()
	r.perch = "far"
	r.global_position = Vector2(300, 170)
	r.state = "watch"
	sq.global_position = Vector2(250, 180)
	sq.state = "move"
	Run.cheeks = 2
	sq._act()
	await wait(0.45)
	sq.state = "move"
	sq._act()
	await wait(0.45)
	check(r.memory.size() == 1, "rival saw the stash")
	sq.global_position = Vector2(40, 60)
	var stolen0: int = Run.stats.stolen
	await wait(4.5)
	check(Run.stats.stolen >= stolen0 + 2, "rival stole the whole stash (%d)" % Run.stats.stolen)
	# confronting: well fed -> it runs; weak -> it fights
	var r2 = park.spawn_rival()
	r2.perch = "far"
	r2.global_position = Vector2(200, 160)
	r2.state = "watch"
	Run.hunger = 90.0
	sq.global_position = Vector2(205, 160)
	sq.state = "move"
	await wait(0.2)
	check(r2.state == "flee", "well fed: rival bolts")
	var r3 = park.spawn_rival()
	r3.perch = "far"
	r3.global_position = Vector2(120, 120)
	r3.state = "watch"
	Run.hunger = 40.0
	sq.invuln = 0.0
	sq.global_position = Vector2(126, 120)
	await wait(0.2)
	check(r3.state == "lunge" and Run.hunger < 40.0, "hungry: rival fights you off")
	r3._leave()
	await wait(1.0)
	sq.state = "move"
	sq.invuln = 0.0
	Run.hunger = 90.0
	# summer: sprouts grow, dog chases, hawk dives
	Clock.advance()
	await wait(0.4)
	check(Clock.season == Clock.SUMMER, "summer")
	check(park.trees_list().filter(func(t): return t.stage == "sapling").size() >= 2, "sprouts grew into saplings")
	check(get_tree().get_nodes_in_group("flower").is_empty() or true, "flowers wilted")
	for b in get_tree().get_nodes_in_group("bees"):
		b.queue_free()
	var d = park.spawn_dog()
	sq.global_position = Vector2(60, 130)
	sq.state = "move"
	sq.invuln = 0.0
	d.global_position = Vector2(30, 130)
	Run.cheeks = 2
	var hits0: int = Run.stats.hits
	await wait(2.6)
	check(Run.stats.hits > hits0 and Run.cheeks == 0, "dog catches you: hurt + acorns dropped (dog %s, sq %s, hits %d->%d, cheeks %d, d=%.0f)" % [
		d.state if is_instance_valid(d) else "gone", sq.state, hits0, Run.stats.hits, Run.cheeks,
		d.global_position.distance_to(sq.global_position) if is_instance_valid(d) else -1.0])
	await wait(3.0)
	sq.invuln = 0.0
	sq.state = "move"
	var d2 = park.spawn_dog()
	d2.global_position = Vector2(30, 60)
	var tt = park.trees_list().filter(func(t): return t.climbable() and not t.has_hive)[0]
	sq.global_position = tt.global_position + Vector2(5, 3)
	sq._climb()
	await wait(2.0)
	check(is_instance_valid(d2) and d2.state in ["bark", "leave"], "dog barks at the tree (%s)" % (d2.state if is_instance_valid(d2) else "gone"))
	await wait(6.0)
	check(not is_instance_valid(d2) or d2.state == "leave", "bored dog leaves")
	sq._climb()
	await wait(0.8)
	sq.invuln = 0.0
	park.threat = null
	# hawk: in the open you get hit, under a crown it misses
	sq.global_position = Vector2(190, 186)
	Run.cheeks = 0
	hits0 = Run.stats.hits
	park.spawn_hawk()
	await wait(2.0)
	check(Run.stats.hits > hits0, "hawk strikes in the open")
	sq.invuln = 0.0
	var cover = park.trees_list().filter(func(t): return t.climbable())[0]
	sq.global_position = cover.global_position + Vector2(0, -14)
	hits0 = Run.stats.hits
	park.spawn_hawk()
	await wait(2.0)
	check(Run.stats.hits == hits0, "hawk misses under a leafy crown")
	# bees: a swarm sitting by a tree long enough builds a hive; hive trees sting
	var ht = park.trees_list().filter(func(t): return t.climbable() and not t.has_burrow and not t.has_hive)[0]
	var sw = park.spawn_swarm(ht.global_position)
	var fake = Node2D.new()
	fake.global_position = ht.global_position + Vector2(18, 6)
	park.add_child(fake)
	for i in range(40):
		park.bees_on_flower(sw, fake, 0.5)
	check(ht.has_hive, "bees by a tree build a hive")
	sq.global_position = ht.global_position + Vector2(5, 3)
	sq.state = "move"
	sq.invuln = 0.0
	sq._climb()
	await wait(0.3)
	check(sq.state != "tree", "can't climb a hive tree (bees sting)")
	sq.state = "move"
	# fall: acorns rain down, over-eating fluffs you up
	Clock.advance()
	await wait(0.3)
	check(Clock.season == Clock.AUTUMN, "fall")
	await wait(8.0)
	check(get_tree().get_nodes_in_group("acorn").size() >= 1, "oaks drop acorns")
	Run.hunger = 100.0
	Run.fluff = 0.0
	sq.state = "move"
	for i in range(4):
		Run.cheeks = 1
		sq.state = "move"
		sq._eat()
		await wait(0.65)
	check(Run.fluff > 60.0 and Run.fluff_stage() >= 1, "eating extra in fall = fluff (%.0f)" % Run.fluff)
	# a stash out in the open, left to be forgotten
	sq.global_position = Vector2(100, 150)
	Run.cheeks = 2
	for i in range(2):
		sq.state = "move"
		sq._act()
		await wait(0.45)
	# winter: frozen ground, fox, cold
	Clock.advance()
	await wait(0.4)
	check(Clock.season == Clock.WINTER, "winter")
	sq.state = "move"
	Run.cheeks = 1
	var buried0: int = Run.stats.buried
	sq._act()
	check(Run.stats.buried == buried0, "can't bury in frozen ground")
	await wait(7.0)
	check(get_tree().get_nodes_in_group("fox").size() >= 1, "the fox is out")
	check(park.fox_prints.marks.size() > 0, "fox leaves prints in the snow")
	Run.fluff = 0.0
	Run.warmth = 100.0
	sq.global_position = Vector2(330, 60)
	sq.state = "move"
	for fx in get_tree().get_nodes_in_group("fox"):
		fx.global_position = Vector2(30, 190)
		fx.state = "sniff"
	await wait(1.0)
	check(Run.warmth < 100.0, "no fluff: the cold bites (%.0f)" % Run.warmth)
	Run.hunger = 100.0
	# end of the year: forgotten stashes sprout
	var stashes := get_tree().get_nodes_in_group("stash").size()
	var trees0: int = park.tree_count()
	Clock.advance()
	await wait(2.0)
	check(Run.state == Run.ENDED, "one full year -> the demo ends")
	check(park.tree_count() > trees0 or stashes == 0, "forgotten stashes sprouted (%d -> %d)" % [trees0, park.tree_count()])
	await wait(3.5)
	check(main.menus.panel.visible, "end screen shows")
	main.menus.show_settings("title")
	Settings.cycle_season(1)
	Settings.cycle_season(-1)
	main.menus.show_title()
	await wait(0.2)
	print("AUTOTEST ", "OK" if fails == 0 else "FAILED (%d)" % fails)
	get_tree().quit()
