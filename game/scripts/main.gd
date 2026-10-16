extends Node2D
## Builds the game: park, atmosphere, HUD, menus. Handles title / play / pause /
## end flow, F11 fullscreen, and a small test harness (user args after "--").

const ParkScript := preload("res://scripts/park/park.gd")
const AtmosScript := preload("res://scripts/park/atmos.gd")
const HudScript := preload("res://scripts/ui/hud.gd")
const MenusScript := preload("res://scripts/ui/menus.gd")

var park: Node2D
var atmos: Node
var hud: CanvasLayer
var menus: CanvasLayer
var args := {}
var _title_t := 0.0
var _title_season := 0
var _frame := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_parse_args()
	Run.testing = args.has("autotest") or args.has("shot") or args.has("bot")
	park = ParkScript.new()
	park.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(park)
	atmos = AtmosScript.new()
	atmos.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(atmos)
	park.atmos = atmos
	hud = HudScript.new()
	add_child(hud)
	menus = MenusScript.new()
	add_child(menus)
	menus.play.connect(start_run)
	menus.restart.connect(start_run)
	menus.resume.connect(_resume)
	menus.to_title.connect(_to_title)
	menus.keep_going.connect(_keep_going)
	Run.state_changed.connect(_on_state)
	Clock.year_changed.connect(_on_year)
	Clock.season_changed.connect(_on_season)
	_to_title()
	if args.has("autotest"):
		var t: Node = load("res://scripts/autotest.gd").new()
		t.main = self
		add_child(t)
		t.run.call_deferred()
	elif args.has("bot"):
		var b: Node = load("res://scripts/bot.gd").new()
		b.main = self
		add_child(b)
		b.run.call_deferred()
	elif args.has("play"):
		start_run.call_deferred()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"


func _to_title() -> void:
	Run.set_state(Run.TITLE)
	Clock.reset()
	Run.reset()
	park.title_scene()
	atmos.set_season(Clock.SPRING)
	_title_season = 0
	_title_t = 0.0
	menus.show_title()
	Snd.music("title")


func start_run() -> void:
	menus.hide_all()
	Clock.reset()
	Run.reset()
	park.new_game()
	atmos.set_season(Clock.SPRING)
	Run.set_state(Run.PLAYING)
	hud.show_banner("SPRING  YEAR 1", hud.LINES[0], Clock.COLORS[0])
	Snd.music("spring")


func _resume() -> void:
	menus.hide_all()
	Run.set_state(Run.PLAYING)


func _keep_going() -> void:
	Run.endless = true
	menus.hide_all()
	Run.set_state(Run.PLAYING)


func _on_state(s: int) -> void:
	if s == Run.OVER:
		await get_tree().create_timer(1.6).timeout
		if Run.state == Run.OVER:
			menus.show_end(false)
			Snd.music("title")


func _on_year(y: int) -> void:
	# the demo is one full year: when spring comes round again, show the grove
	if y >= 2 and not Run.endless and Run.state == Run.PLAYING:
		Run.set_state(Run.ENDED)
		Snd.play("win")
		await get_tree().create_timer(4.5).timeout
		if Run.state == Run.ENDED:
			menus.show_end(true)


func _on_season(s: int) -> void:
	Snd.music(Clock.NAMES[s])
	# the true ending: keep going until your forgetting has turned the park into a forest
	if s == Clock.SPRING and Run.endless and Run.state == Run.PLAYING:
		await get_tree().create_timer(3.0).timeout
		if Run.state == Run.PLAYING and park.tree_count() >= park.FOREST:
			Run.set_state(Run.ENDED)
			Snd.play("win")
			await get_tree().create_timer(2.0).timeout
			menus.show_end(true, true)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.physical_keycode == KEY_F11:
		var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if e.is_action_pressed("pause"):
		if Run.state == Run.PLAYING:
			Run.set_state(Run.PAUSED)
			menus.show_pause()
		elif Run.state == Run.PAUSED:
			_resume()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and Run.state == Run.PLAYING and not args.has("autotest") and not args.has("shot"):
		Run.set_state(Run.PAUSED)
		menus.show_pause()


func _process(delta: float) -> void:
	_frame += 1
	if Run.state == Run.TITLE:
		# the park turns through the seasons behind the title
		_title_t += delta
		if _title_t > 4.0:
			_title_t = 0.0
			_title_season = (_title_season + 1) % 4
			Clock.season = _title_season
			park.show_season(_title_season)
	_harness()


func _harness() -> void:
	if not args.has("shot"):
		return
	var frames := int(args.get("frames", "90"))
	if _frame == 3 and not args.has("title"):
		start_run()
	if _frame == 6 and args.has("season"):
		var target: int = Clock.NAMES.find(args["season"])
		while Clock.season != target:
			Clock.advance()
		hud._banner_t = 0.0
	if _frame == 10:
		_stage_scene()
	if _frame == frames:
		var img := get_viewport().get_texture().get_image()
		img.save_png(args["shot"])
		print("SHOT ", args["shot"])
		get_tree().quit()


func _stage_scene() -> void:
	## Puts interesting things on screen for screenshots.
	var sq = Run.squirrel
	if args.has("dog"):
		park.spawn_dog()
	if args.has("hawk"):
		park.spawn_hawk()
	if args.has("rival"):
		for i in range(2):
			park.spawn_rival()
	if args.has("perch"):
		# one rival up a tree, one tucked behind a trunk
		var trees: Array = park.trees_list().filter(func(t): return t.climbable())
		for i in range(2):
			var r = park.spawn_rival()
			r.perch_tree = trees[1 + i]
			r.perch = "tree" if i == 0 else "behind"
			r.target = r.perch_tree.global_position + (Vector2(16, -30) if i == 0 else Vector2(0, -5))
			r.global_position = r.target
			r.state = "watch"
	if args.has("fox"):
		var f = park.spawn_fox()
		f.global_position = sq.global_position + Vector2(40, 10)
	if args.has("fluff"):
		Run.fluff = float(args["fluff"])
	if args.has("hive"):
		park.trees_list()[2].add_hive(park.spawn_swarm(Vector2(150, 70)))
		park.get_tree().get_nodes_in_group("bees")[0].settle(park.trees_list()[2])
	if args.has("burrow"):
		park.trees_list()[3].add_burrow()
	if args.has("tree"):
		sq._climb_up(park.trees_list()[2])
	if args.has("stash"):
		for p in [Vector2(120, 170), Vector2(260, 60), Vector2(40, 120)]:
			park.bury(p)
	if args.has("acorns"):
		park.scatter_acorns(sq.global_position + Vector2(30, 0), 5)
	if args.has("cheeks"):
		Run.cheeks = int(args["cheeks"])
	if args.has("hc"):
		Settings.high_contrast = true
	if args.has("hunger"):
		Run.hunger = float(args["hunger"])
	if args.has("rain"):
		atmos._shower_cd = 0.0
	if args.has("burrowin"):
		var t = park.trees_list()[3]
		t.add_burrow()
		sq.global_position = t.global_position + Vector2(4, 4)
		sq._climb()
	if args.has("climbdown"):
		sq._climb_up(park.trees_list()[2])
		get_tree().create_timer(0.7).timeout.connect(func(): sq._climb())
	if args.has("yearend"):
		# jump to the end of winter with a few forgotten stashes in the ground
		for p in [Vector2(120, 175), Vector2(260, 175), Vector2(330, 100), Vector2(40, 120)]:
			var st = park.StashScript.new()
			st.acorns = 2
			st.position = p
			park.add_child(st)
		Clock.advance()
	match args.get("menu", ""):
		"controls":
			menus.show_controls()
		"settings":
			menus.show_settings("pause")
		"help":
			menus.show_help("title")
		"pause":
			menus.show_pause()
		"end":
			menus.show_end(true)
		"over":
			Run.death = "STARVED"
			menus.show_end(false)
