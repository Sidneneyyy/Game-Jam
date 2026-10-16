extends CanvasLayer
## Title, pause, settings and end-of-year screens. Mouse, keyboard or gamepad.

signal play
signal resume
signal restart
signal to_title
signal keep_going

var panel: PanelContainer
var box: VBoxContainer
var theme_: Theme
var _back_to := ""
var _waiting := ""     # action waiting for a new key / button
var mascot: AnimatedSprite2D


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme_ = Theme.new()
	theme_.default_font = Art.font
	theme_.default_font_size = 9
	var normal := _box(Color("4a3424"), Color("221612"))
	var hover := _box(Color("74502e"), Color("f2cc90"))
	var press := _box(Color("c05a28"), Color("fbf6ec"))
	for st in ["normal", "disabled"]:
		theme_.set_stylebox(st, "Button", normal)
	theme_.set_stylebox("hover", "Button", hover)
	theme_.set_stylebox("focus", "Button", hover)
	theme_.set_stylebox("pressed", "Button", press)
	theme_.set_color("font_color", "Button", Color("f2e6d0"))
	theme_.set_color("font_hover_color", "Button", Color("fff6e0"))
	theme_.set_color("font_focus_color", "Button", Color("fff6e0"))
	theme_.set_stylebox("panel", "PanelContainer", _box(Color(0.13, 0.09, 0.07, 0.92), Color("74502e"), 8))
	panel = PanelContainer.new()
	panel.theme = theme_
	add_child(panel)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	mascot = AnimatedSprite2D.new()
	mascot.sprite_frames = Art.frames("sprites/squirrel_fluffy")
	mascot.play("eat")
	mascot.visible = false
	add_child(mascot)


func _box(bg: Color, border: Color, pad := 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.content_margin_left = pad + 2
	s.content_margin_right = pad + 2
	s.content_margin_top = maxi(1, pad - 3)
	s.content_margin_bottom = maxi(1, pad - 3)
	return s


func _clear() -> void:
	mascot.visible = false
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	panel.visible = true


func _title_text(t: String, c: Color, size := 18) -> void:
	var l := Art.label(t, c, size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)


func _text(t: String, c := Color("f2e6d0")) -> void:
	var l := Art.label(t, c, 9, false)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)


func _button(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(func():
		Snd.play("ui", 0.0, -4.0)
		cb.call())
	box.add_child(b)
	return b


func _finish(focus: Button) -> void:
	panel.reset_size()
	await get_tree().process_frame
	panel.reset_size()
	panel.position = ((Vector2(384, 216) - panel.size) / 2.0).round()
	if focus:
		focus.grab_focus()


func hide_all() -> void:
	panel.visible = false
	mascot.visible = false


func show_title() -> void:
	_clear()
	_title_text("FORGOTTEN ACORNS", Color("f2a83a"), 18)
	_text("BURY ACORNS. SURVIVE THE YEAR.")
	_text("EVERY STASH YOU FORGET BECOMES A TREE.", Color("c8e6a0"))
	_text(" ")
	var p := _button("PLAY", func(): play.emit())
	_button("HOW TO PLAY", func(): show_help("title"))
	_button("SETTINGS", func(): show_settings("title"))
	_button("QUIT", func(): get_tree().quit())
	_text(" ")
	_text("%s%s%s%s MOVE  %s SPRINT  %s BURY/DIG" % [Settings.bind_label("move_up"), Settings.bind_label("move_left"),
		Settings.bind_label("move_down"), Settings.bind_label("move_right"), Settings.bind_label("sprint"), Settings.bind_label("act")], Color("bfa98c"))
	_text("%s EAT   %s CLIMB/BURROW" % [Settings.bind_label("eat"), Settings.bind_label("climb")], Color("bfa98c"))
	_text("F11 FULLSCREEN   ESC PAUSE", Color("8e7a64"))
	if Run.best > 0:
		_text("BEST %d" % Run.best, Color("f6c83a"))
	await _finish(p)
	mascot.visible = true
	mascot.position = panel.position + Vector2(panel.size.x - 30, -10)  # sitting on the panel


func show_pause() -> void:
	_clear()
	_title_text("PAUSED", Color("f2e6d0"), 18)
	var r := _button("RESUME", func(): resume.emit())
	_button("HOW TO PLAY", func(): show_help("pause"))
	_button("SETTINGS", func(): show_settings("pause"))
	_button("RESTART", func(): restart.emit())
	_button("TITLE", func(): to_title.emit())
	_text(" ")
	_text("%s BURY/DIG   %s EAT" % [Settings.bind_label("act"), Settings.bind_label("eat")], Color("bfa98c"))
	_text("%s CLIMB/BURROW   %s SPRINT" % [Settings.bind_label("climb"), Settings.bind_label("sprint")], Color("bfa98c"))
	_finish(r)


func show_help(back: String) -> void:
	_clear()
	_title_text("HOW TO PLAY", Color("f2a83a"), 18)
	_text("LIVE THROUGH ONE YEAR. EVERY STASH YOU FORGET", Color("f2e6d0"))
	_text("SPROUTS INTO A TREE NEXT SPRING. TREES = SCORE.", Color("f2e6d0"))
	_text(" ")
	var rows := [
		["SPRING", "EAT FLOWERS BY YOUR TREES OR BEES BUILD HIVES."],
		["SUMMER", "DOG + HAWK. CLIMB A TREE WITHOUT BEES."],
		["FALL", "EAT EXTRA TO FLUFF UP. BURY THE REST."],
		["WINTER", "FROZEN + DARK. DIG STASHES. FOX ABOUT."],
	]
	for i in range(4):
		_text("%s: %s" % rows[i], Clock.COLORS[i])
	_text(" ")
	_text("STASH 3 ACORNS ROUND A TREE = A WARM BURROW.", Color("f2cc90"))
	_text("RIVALS STEAL WHAT THEY SEE YOU BURY.", Color("f2cc90"))
	_text("RUN AT THEM WITH HUNGER OVER THE 60% LINE.", Color("f2cc90"))
	_text(" ")
	var b := _button("BACK", func():
		if back == "pause":
			show_pause()
		else:
			show_title())
	_finish(b)


func show_settings(back: String) -> void:
	_back_to = back
	_clear()
	_title_text("SETTINGS", Color("f2e6d0"), 18)
	var first := _button("SEASON LENGTH  %s" % Settings.season_label(), func():
		var i := Settings.SEASON_STEPS.find(Settings.season_secs)
		Settings.season_secs = Settings.SEASON_STEPS[(i + 1) % Settings.SEASON_STEPS.size()]
		Settings.save()
		_refresh_settings(0))
	_button("ASSIST  %s" % _onoff(Settings.assist), func():
		Settings.assist = not Settings.assist
		Settings.save()
		_refresh_settings(1))
	_button("MUSIC  %d%%" % int(Settings.music_vol * 100), func():
		Settings.music_vol = 0.0 if Settings.music_vol >= 0.99 else snappedf(Settings.music_vol + 0.1, 0.1)
		Settings.save()
		Snd.refresh_volume()
		_refresh_settings(2))
	_button("SOUND  %d%%" % int(Settings.sfx_vol * 100), func():
		Settings.sfx_vol = 0.0 if Settings.sfx_vol >= 0.99 else snappedf(Settings.sfx_vol + 0.1, 0.1)
		Settings.save()
		_refresh_settings(3))
	_button("SCREEN SHAKE  %s" % _onoff(Settings.shake), func():
		Settings.shake = not Settings.shake
		Settings.save()
		_refresh_settings(4))
	_button("HIGH CONTRAST  %s" % _onoff(Settings.high_contrast), func():
		Settings.high_contrast = not Settings.high_contrast
		Settings.save()
		_refresh_settings(5))
	_button("CONTROLS", func(): show_controls())
	_button("BACK", func():
		if _back_to == "pause":
			show_pause()
		else:
			show_title())
	_text("ASSIST: SLOWER HUNGER, WIDER SIGHT IN WINTER", Color("bfa98c"))
	_finish(first)


func show_controls(focus_i := 0) -> void:
	_clear()
	_title_text("CONTROLS", Color("f2e6d0"), 18)
	var buttons: Array[Button] = []
	for a in Settings.DEFAULT_BINDS:
		var label: String = "%s:  %s" % [Settings.BIND_NAMES[a], "PRESS A KEY..." if _waiting == a else Settings.bind_label(a)]
		var act: String = a
		buttons.append(_button(label, func():
			_waiting = act
			show_controls(Settings.DEFAULT_BINDS.keys().find(act))))
	_button("RESET TO DEFAULT", func():
		Settings.reset_binds()
		show_controls())
	_button("BACK", func():
		_waiting = ""
		show_settings(_back_to))
	_text("ARROWS, E/F AND A GAMEPAD ALWAYS WORK TOO", Color("bfa98c"))
	_finish(buttons[clampi(focus_i, 0, buttons.size() - 1)])


func _input(e: InputEvent) -> void:
	if _waiting == "" or not panel.visible:
		return
	var pressed: bool = (e is InputEventKey and e.pressed and not e.echo) or (e is InputEventMouseButton and e.pressed)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	var a := _waiting
	if e is InputEventKey and e.physical_keycode == KEY_ESCAPE:
		_waiting = ""
	elif Settings.rebind(a, e):
		_waiting = ""
		Snd.play("ui")
	else:
		Snd.play("deny")
		return
	show_controls(Settings.DEFAULT_BINDS.keys().find(a))


func _refresh_settings(focus_i: int) -> void:
	show_settings(_back_to)
	await get_tree().process_frame
	var buttons := box.get_children().filter(func(c): return c is Button)
	if focus_i < buttons.size():
		buttons[focus_i].grab_focus()


func _onoff(v: bool) -> String:
	return "ON" if v else "OFF"


func show_end(won: bool, forest := false) -> void:
	_clear()
	var new_best := Run.commit_best()
	if forest:
		_title_text("THE PARK IS A FOREST", Color("8fd05a"), 18)
		_text("EVERY TREE HERE IS AN ACORN YOU FORGOT.")
		_text("THAT IS HOW SQUIRRELS PLANT FORESTS.", Color("c8e6a0"))
	elif won:
		_title_text("A YEAR IN THE PARK", Color("8fd05a"), 18)
		_text("YOU MADE IT THROUGH WINTER.")
		_text("THE STASHES YOU FORGOT ARE GROWING.", Color("c8e6a0"))
		_text("KEEP GOING UNTIL THE PARK IS A FOREST (%d TREES)." % Run.park.FOREST, Color("bfa98c"))
	else:
		_title_text("YOU %s" % Run.death, Color("f05a4a"), 18)
		_text("IN %s, YEAR %d." % [Clock.TITLES[Clock.season], Clock.year])
		_text(_tip(), Color("f2cc90"))
	_text(" ")
	_text("TREES %d   NEW SPROUTS %d" % [Run.trees(), Run.stats.sprouted])
	_text("BURIED %d   EATEN %d   STOLEN %d" % [Run.stats.buried, Run.stats.eaten, Run.stats.stolen])
	_text("RIVALS CHASED %d   BURROWS %d   HIVES %d" % [Run.stats.chased, Run.stats.burrows, Run.stats.hives])
	_text("SCORE %d%s" % [Run.score(), "  NEW BEST!" if new_best else ""], Color("f6c83a"))
	_text(" ")
	var f: Button
	if won and not forest:
		f = _button("KEEP GOING", func(): keep_going.emit())
		_button("PLAY AGAIN", func(): restart.emit())
	else:
		f = _button("PLAY AGAIN", func(): restart.emit())
	_button("TITLE", func(): to_title.emit())
	_finish(f)


func _tip() -> String:
	match Clock.season:
		Clock.WINTER:
			return "FLUFF UP IN FALL, AND HIDE ACORNS NEAR TREES FOR BURROWS."
		Clock.SUMMER:
			return "KEEP A FEW ACORNS STASHED FOR THE LEAN MONTHS."
		Clock.AUTUMN:
			return "EAT AS YOU GO. FALL IS THE TIME TO GET FAT."
	return "DIG UP OLD STASHES AND MUNCH FLOWERS IN SPRING."
