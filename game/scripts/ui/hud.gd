extends CanvasLayer
## HUD: hunger (with the 60% "rivals respect you" line), cheek acorns, fluff and
## warmth, the year track, trees + score, season banner, floating popups, and
## wordless key / mouse glyph hints above the squirrel.

var root: Control
var canvas: Control
var popups: Control
var banner: Label
var sub: Label
var banner_bg: ColorRect
var lbl_year: Label
var lbl_score: Label
var lbl_trees: Label
var _banner_t := 0.0
var _flash := 0.0
var _hint_used := {}


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.size = Vector2(384, 216)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	canvas = Control.new()
	canvas.size = root.size
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_hud)
	root.add_child(canvas)
	popups = Control.new()
	popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(popups)
	lbl_year = _lbl(Vector2(186, 12), Color("f2e6d0"))
	lbl_trees = _lbl(Vector2(318, 3), Color("c8e6a0"))
	lbl_score = _lbl(Vector2(318, 12), Color("f2e6d0"))
	banner_bg = ColorRect.new()
	banner_bg.color = Color(0.13, 0.09, 0.07, 0.72)
	banner_bg.position = Vector2(0, 50)
	banner_bg.size = Vector2(384, 40)
	banner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner_bg)
	banner = Art.label("", Color.WHITE, 18)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.size = Vector2(384, 24)
	banner.position = Vector2(0, 52)
	root.add_child(banner)
	sub = Art.label("", Color("f2e6d0"), 9)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(384, 12)
	sub.position = Vector2(0, 76)
	root.add_child(sub)
	Run.popup.connect(_on_popup)
	Clock.season_changed.connect(_on_season)
	Clock.season_warning.connect(func(_n): _flash = Clock.WARN)


func _lbl(p: Vector2, c: Color) -> Label:
	var l := Art.label("", c, 9)
	l.position = p
	root.add_child(l)
	return l


const LINES := [
	"EAT FLOWERS NEAR YOUR TREES. BEES BUILD HIVES THERE.",
	"DOG AND HAWK ABOUT. CLIMB A TREE WITHOUT BEES.",
	"ACORNS FALL. EAT EXTRA TO FLUFF UP. BURY THE REST.",
	"FIND YOUR STASHES. HIDE IN A BURROW. WATCH FOR PRINTS.",
]


func _on_season(s: int) -> void:
	show_banner(Clock.TITLES[s] + ("  YEAR %d" % Clock.year if s == Clock.SPRING else ""), LINES[s], Clock.COLORS[s])


func show_banner(text: String, line: String, col: Color) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", col)
	sub.text = line
	_banner_t = 4.0


func _process(delta: float) -> void:
	root.visible = Run.state != Run.TITLE
	_flash = maxf(0.0, _flash - delta)
	_banner_t = maxf(0.0, _banner_t - delta)
	banner.modulate.a = clampf(_banner_t, 0.0, 1.0)
	sub.modulate.a = banner.modulate.a
	banner_bg.modulate.a = banner.modulate.a
	lbl_year.text = "YEAR %d" % Clock.year
	lbl_trees.text = "%d" % Run.trees()
	lbl_score.text = "%d" % Run.score()
	canvas.queue_redraw()


func _bar(p: Vector2, w: float, frac: float, col: Color, icon: String, mark := -1.0) -> void:
	canvas.draw_texture(Art.tex("ui/icon_" + icon), p + Vector2(0, -2))
	var b := p + Vector2(11, 1)
	canvas.draw_rect(Rect2(b - Vector2(1, 1), Vector2(w + 2, 6)), Color("221612"))
	canvas.draw_rect(Rect2(b, Vector2(w, 4)), Color("4a3a30"))
	canvas.draw_rect(Rect2(b, Vector2(round(w * clampf(frac, 0.0, 1.0)), 4)), col)
	canvas.draw_rect(Rect2(b, Vector2(round(w * clampf(frac, 0.0, 1.0)), 1)), col.lightened(0.35))
	if mark >= 0.0:
		canvas.draw_rect(Rect2(b + Vector2(round(w * mark), -2), Vector2(1, 8)), Color("fbf6ec"))


func _draw_hud() -> void:
	if Run.state == Run.TITLE:
		return
	# top strip
	canvas.draw_rect(Rect2(0, 0, 384, 21), Color(0.13, 0.09, 0.07, 0.78))
	canvas.draw_rect(Rect2(0, 21, 384, 1), Color("221612"))
	var blink := fmod(Time.get_ticks_msec() / 1000.0, 0.5) < 0.25
	var hcol := Color("8fd05a") if Run.hunger >= Run.RIVAL_LINE else (Color("f6c83a") if Run.hunger > 25 else Color("f05a4a"))
	if Run.hunger < 20 and blink:
		hcol = Color.WHITE
	_bar(Vector2(4, 3), 58, Run.hunger / 100.0, hcol, "hunger", Run.RIVAL_LINE / 100.0)
	if Run.hunger < Run.RIVAL_LINE and _rival_close() and blink:
		canvas.draw_rect(Rect2(15 + round(58 * Run.RIVAL_LINE / 100.0) - 1, 1, 3, 9), Color("f05a4a"))
	# cheeks
	for i in range(Run.MAX_CHEEKS):
		canvas.draw_texture(Art.tex("ui/icon_acorn" if i < Run.cheeks else "ui/icon_acorn_empty"), Vector2(78 + i * 9, 1))
	# acorns you have in the ground right now (your winter larder)
	var stashed := 0
	for s in get_tree().get_nodes_in_group("stash"):
		if not s.is_queued_for_deletion():
			stashed += s.acorns
	var st := Art.tex("park/stash2_" + Clock.NAMES[Clock.season] if Clock.season != Clock.WINTER else "park/stash2_autumn")
	canvas.draw_texture(st, Vector2(99, 11))
	canvas.draw_string(Art.font, Vector2(114, 19), "%d" % stashed, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("f2cc90"))
	# fluff (fall + winter) and warmth (winter)
	if Clock.season == Clock.AUTUMN or Clock.season == Clock.WINTER or Run.fluff > 0.0:
		_bar(Vector2(4, 12), 34, Run.fluff / 100.0, Color("fbf6ec"), "fluff")
	if Clock.season == Clock.WINTER or Run.warmth < 100.0:
		var wcol := Color("f08a3a").lerp(Color("a8d8f8"), 1.0 - Run.warmth / 100.0)
		if Run.warmth < 25 and blink:
			wcol = Color.WHITE
		_bar(Vector2(51, 12), 34, Run.warmth / 100.0, wcol, "warm")
	# the year: four seasons in a row with a playhead
	var x0 := 144.0
	var seg := 30.0
	for i in range(4):
		var r := Rect2(x0 + i * (seg + 1), 4, seg, 5)
		var c: Color = Clock.COLORS[i]
		canvas.draw_rect(r.grow(1), Color("221612"))
		canvas.draw_rect(r, c.darkened(0.45) if i != Clock.season else c)
	var ph := x0 + Clock.season * (seg + 1) + seg * Clock.progress()
	canvas.draw_rect(Rect2(ph - 1, 2, 2, 9), Color("fbf6ec"))
	var nxt := Clock.next_season()
	var icon := Art.tex("ui/season_" + Clock.NAMES[Clock.season])
	canvas.draw_texture(icon, Vector2(x0 - 14, 1))
	if _flash > 0.0 and fmod(Time.get_ticks_msec() / 1000.0, 0.4) < 0.25:
		canvas.draw_texture(Art.tex("ui/season_" + Clock.NAMES[nxt]), Vector2(x0 + 4 * (seg + 1) + 2, 1))
	canvas.draw_texture(Art.tex("ui/icon_tree"), Vector2(306, 2))
	canvas.draw_texture(Art.tex("ui/icon_star"), Vector2(306, 11))
	_danger_hints()
	_hints()
	_intro_card()


func _hints() -> void:
	## Wordless tutorial: show the key / mouse glyph for what you can do right here.
	var sq = Run.squirrel
	if sq == null or not Run.playing() or Clock.year > 1:
		return
	var p: Vector2 = sq.global_position + (Run.park.position if Run.park else Vector2.ZERO)
	var glyph := ""
	if sq.state == "tree" or sq.state == "burrow":
		glyph = "ui/mouse_right"
	elif sq.state == "move":
		var park = Run.park
		var t = park.tree_near(sq.global_position, 13.0)
		if park.stash_near(sq.global_position, 10.0) and Run.cheeks == 0:
			glyph = "ui/key_SPACE"
		elif t and t.climbable() and not t.has_hive and _count("climb") < 4:
			glyph = "ui/mouse_right"
		elif park.flower_near(sq.global_position, 11.0) or park.bush_near(sq.global_position, 16.0):
			glyph = "ui/mouse_left"
		elif Run.cheeks > 0 and Run.hunger < 55.0:
			glyph = "ui/mouse_left"
		elif Run.cheeks > 0 and Clock.season != Clock.WINTER and Run.stats.buried < 3:
			glyph = "ui/key_SPACE"
	if glyph == "":
		return
	var t := Art.tex(glyph)
	var bob := roundf(sin(Time.get_ticks_msec() / 160.0))
	canvas.draw_texture(t, (p + Vector2(-t.get_width() / 2.0, -36 + bob)).round())


func _off() -> Vector2:
	return Run.park.position if Run.park else Vector2.ZERO


func _danger_hints() -> void:
	## When something is chasing you, point at the nearest safe tree. Also warn
	## when the dog is about to burst in through a gate.
	var sq = Run.squirrel
	if sq == null or not Run.playing():
		return
	var blink := fmod(Time.get_ticks_msec() / 1000.0, 0.4) < 0.25
	for dg in get_tree().get_nodes_in_group("dog"):
		var x: float = dg.global_position.x
		if (x < 14.0 or x > 370.0) and dg.state != "leave" and blink:
			var ex := 4.0 if x < 192.0 else 370.0
			canvas.draw_texture(Art.tex("ui/icon_paw"), Vector2(ex, dg.global_position.y - 12) + _off())
	var chased := false
	for dg in get_tree().get_nodes_in_group("dog"):
		chased = chased or dg.state == "chase"
	for fx in get_tree().get_nodes_in_group("fox"):
		chased = chased or fx.state == "chase"
	for hk in get_tree().get_nodes_in_group("hawk"):
		chased = chased or hk.phase == "mark"
	if not chased or sq.hidden():
		return
	var best: Node = null
	var bd := 1e9
	for t in Run.park.trees_list():
		if not t.climbable() or (t.has_hive and Clock.season != Clock.WINTER):
			continue
		var dist: float = t.global_position.distance_to(sq.global_position)
		if dist < bd:
			bd = dist
			best = t
	if best == null:
		return
	var bob := roundf(sin(Time.get_ticks_msec() / 110.0) * 1.5)
	var p: Vector2 = best.global_position + _off()
	canvas.draw_texture(Art.tex("ui/arrow_up"), (p + Vector2(-3, 8 + bob)).round())
	canvas.draw_texture(Art.tex("ui/mouse_right"), (p + Vector2(-5, 16 + bob)).round())


func _intro_card() -> void:
	## First seconds of the game: the whole idea in pictures, no words.
	## acorn -> SPACE -> stash -> winter -> sprout, then the three verbs below.
	if not Run.playing() or Clock.year != 1 or Clock.season != Clock.SPRING or Clock.t > 11.0:
		return
	var a := clampf(11.0 - Clock.t, 0.0, 1.0)
	var col := Color(1, 1, 1, a)
	var y := 150.0
	canvas.draw_rect(Rect2(40, y - 6, 304, 60), Color(0.13, 0.09, 0.07, 0.8 * a))
	var row := ["ui/icon_acorn", ">", "ui/key_SPACE", ">", "park/stash2_spring", ">", "ui/season_winter", ">", "park/sprout_spring"]
	var w := 0.0
	for it in row:
		w += 10.0 if it == ">" else Art.tex(it).get_width() * 2.0 + 6.0
	var x := 192.0 - w / 2.0
	for it in row:
		if it == ">":
			canvas.draw_string(Art.font, Vector2(x, y + 15), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)
			x += 10.0
		else:
			var t := Art.tex(it)
			var sz := t.get_size() * 2.0
			canvas.draw_texture_rect(t, Rect2(Vector2(x, y + 12 - sz.y / 2.0).round(), sz), false, col)
			x += sz.x + 6.0
	var row2 := [["ui/mouse_left", "ui/icon_hunger"], ["ui/mouse_right", "ui/icon_tree"], ["ui/key_SHIFT", "ui/icon_paw"]]
	x = 104.0
	for pair in row2:
		for it in pair:
			var t := Art.tex(it)
			canvas.draw_texture(t, Vector2(x, y + 40 - t.get_height() / 2.0).round(), col)
			x += t.get_width() + 3.0
		x += 22.0


func _rival_close() -> bool:
	var sq = Run.squirrel
	if sq == null:
		return false
	for r in get_tree().get_nodes_in_group("rival"):
		if r.global_position.distance_to(sq.global_position) < 50.0:
			return true
	return false


func _count(k: String) -> int:
	return int(_hint_used.get(k, 0))


func _on_popup(text: String, pos: Vector2, col: Color) -> void:
	var l := Art.label(text, col, 9)
	var off: Vector2 = Run.park.position if Run.park else Vector2.ZERO
	var w := text.length() * 6.0
	var x := clampf(pos.x + off.x - w / 2.0, 2.0, 382.0 - w)
	l.position = Vector2(x, clampf(pos.y + off.y, 24.0, 204.0)).round()
	popups.add_child(l)
	var long := text.length() > 14
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - (6 if long else 12), 2.6 if long else 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5).set_delay(2.1 if long else 0.6)
	tw.tween_callback(l.queue_free)
