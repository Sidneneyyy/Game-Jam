extends Node
## Player options (saved to user://settings.cfg) and the input map.
## Controls: WASD move, Shift sprint, Space bury/dig, left click eat,
## right click climb / burrow. E and F mirror the mouse buttons; arrows and a
## gamepad work too.

const PATH := "user://settings.cfg"
const SEASON_STEPS := [60, 90, 120, 180, 240]

var season_secs := 90
var assist := false
var music_vol := 0.7
var sfx_vol := 0.8
var shake := true
var high_contrast := false
# remappable primary bindings: action -> ["key", keycode] or ["mouse", button]
const DEFAULT_BINDS := {
	"move_up": ["key", KEY_W], "move_left": ["key", KEY_A], "move_down": ["key", KEY_S],
	"move_right": ["key", KEY_D], "sprint": ["key", KEY_SHIFT], "act": ["key", KEY_SPACE],
	"eat": ["mouse", MOUSE_BUTTON_LEFT], "climb": ["mouse", MOUSE_BUTTON_RIGHT],
}
const BIND_NAMES := {"move_up": "UP", "move_left": "LEFT", "move_down": "DOWN", "move_right": "RIGHT",
	"sprint": "SPRINT", "act": "BURY / DIG", "eat": "EAT", "climb": "CLIMB / BURROW"}
var binds := DEFAULT_BINDS.duplicate(true)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	_build_input()


func season_seconds() -> float:
	return float(season_secs)


func season_label() -> String:
	var m := season_secs / 60
	var s := season_secs % 60
	return "%d:%02d" % [m, s]


func cycle_season(dir: int) -> void:
	var i := SEASON_STEPS.find(season_secs)
	season_secs = SEASON_STEPS[clampi(i + dir, 0, SEASON_STEPS.size() - 1)] if i >= 0 else 90
	save()


func save() -> void:
	var c := ConfigFile.new()
	c.set_value("game", "season_secs", season_secs)
	c.set_value("game", "assist", assist)
	c.set_value("audio", "music", music_vol)
	c.set_value("audio", "sfx", sfx_vol)
	c.set_value("access", "shake", shake)
	c.set_value("access", "high_contrast", high_contrast)
	c.set_value("input", "binds", binds)
	c.save(PATH)


func _load() -> void:
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	season_secs = int(c.get_value("game", "season_secs", season_secs))
	if not SEASON_STEPS.has(season_secs):
		season_secs = 90
	assist = bool(c.get_value("game", "assist", assist))
	music_vol = float(c.get_value("audio", "music", music_vol))
	sfx_vol = float(c.get_value("audio", "sfx", sfx_vol))
	shake = bool(c.get_value("access", "shake", shake))
	high_contrast = bool(c.get_value("access", "high_contrast", high_contrast))
	var b = c.get_value("input", "binds", {})
	if b is Dictionary:
		for k in b:
			if DEFAULT_BINDS.has(k):
				binds[k] = b[k]


func _key(action: String, codes: Array) -> void:
	for k in codes:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)


func _mouse(action: String, button: int) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	InputMap.action_add_event(action, e)


func _pad(action: String, button: int) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	InputMap.action_add_event(action, e)


func _axis(action: String, axis: int, dir: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = dir
	InputMap.action_add_event(action, e)


func bind_label(action: String) -> String:
	var b: Array = binds[action]
	if b[0] == "mouse":
		return "LEFT CLICK" if b[1] == MOUSE_BUTTON_LEFT else ("RIGHT CLICK" if b[1] == MOUSE_BUTTON_RIGHT else "MOUSE %d" % b[1])
	return OS.get_keycode_string(b[1]).to_upper()


func rebind(action: String, ev: InputEvent) -> bool:
	var nb: Array
	if ev is InputEventKey:
		var code: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
		if code == KEY_ESCAPE or code == KEY_P or code == KEY_F11:
			return false  # reserved for pause / fullscreen
		nb = ["key", code]
	elif ev is InputEventMouseButton:
		nb = ["mouse", ev.button_index]
	else:
		return false
	# one input per action: whoever had it before takes over this action's old one
	for other in binds:
		if other != action and binds[other] == nb:
			binds[other] = binds[action]
	binds[action] = nb
	save()
	_build_input()
	return true


func reset_binds() -> void:
	binds = DEFAULT_BINDS.duplicate(true)
	save()
	_build_input()


func _build_input() -> void:
	var alts := {
		"move_left": [KEY_LEFT], "move_right": [KEY_RIGHT], "move_up": [KEY_UP], "move_down": [KEY_DOWN],
		"sprint": [], "act": [KEY_J], "eat": [KEY_E, KEY_K], "climb": [KEY_F, KEY_L], "pause": [KEY_ESCAPE, KEY_P],
	}
	for a in alts:
		if InputMap.has_action(a):
			InputMap.erase_action(a)
		InputMap.add_action(a, 0.3)
		_key(a, alts[a])
		if binds.has(a):
			var b: Array = binds[a]
			if b[0] == "mouse":
				_mouse(a, int(b[1]))
			else:
				_key(a, [int(b[1])])
	_axis("move_left", JOY_AXIS_LEFT_X, -1.0); _axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("move_up", JOY_AXIS_LEFT_Y, -1.0); _axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_pad("move_left", JOY_BUTTON_DPAD_LEFT); _pad("move_right", JOY_BUTTON_DPAD_RIGHT)
	_pad("move_up", JOY_BUTTON_DPAD_UP); _pad("move_down", JOY_BUTTON_DPAD_DOWN)
	_pad("act", JOY_BUTTON_A); _pad("eat", JOY_BUTTON_X); _pad("climb", JOY_BUTTON_B)
	_pad("sprint", JOY_BUTTON_RIGHT_SHOULDER); _pad("pause", JOY_BUTTON_START)
