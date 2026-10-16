extends Node
## One run: the squirrel's body (hunger, fluff, warmth, cheeks), stats, score,
## and the game state. Hunger is food; fluff is fat you build by over-eating in
## fall and burn through in winter; warmth only matters in the cold.

signal changed
signal popup(text: String, pos: Vector2, color: Color)
signal state_changed(s: int)

enum { TITLE, PLAYING, PAUSED, OVER, ENDED }
const MAX_CHEEKS := 4
const RIVAL_LINE := 60.0   # below this much hunger, rivals stand their ground
const ACORN_FOOD := 24.0
const SAVE := "user://save.cfg"

var state := TITLE
var hunger := 80.0
var fluff := 0.0
var warmth := 100.0
var cheeks := 0
var endless := false
var testing := false     # autotest / screenshot runs never touch the saved best
var death := ""
var best := 0
var stats := {}
var park: Node = null
var squirrel: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var c := ConfigFile.new()
	if c.load(SAVE) == OK:
		best = int(c.get_value("score", "best", 0))
	reset()


func reset() -> void:
	hunger = 80.0
	fluff = 0.0
	warmth = 100.0
	cheeks = 0
	endless = false
	death = ""
	stats = {"buried": 0, "dug": 0, "eaten": 0, "flowers": 0, "stolen": 0, "chased": 0,
		"sprouted": 0, "hits": 0, "burrows": 0, "hives": 0}
	changed.emit()


func set_state(s: int) -> void:
	state = s
	get_tree().paused = (s == PAUSED)
	Clock.running = (s == PLAYING)
	state_changed.emit(s)


func playing() -> bool:
	return state == PLAYING


func feed(amount: float) -> float:
	## Fill hunger; in fall the overflow becomes fluff. Returns the fluff gained.
	var into := minf(100.0 - hunger, amount)
	hunger += into
	var gained := 0.0
	var over := amount - into
	if over > 0.0 and Clock.season == Clock.AUTUMN:
		gained = minf(100.0 - fluff, over * 0.85)
		fluff += gained
	changed.emit()
	return gained


func fluff_stage() -> int:
	## 0 lean, 1 plump, 2 winter-fluffy: drives which sprite set the squirrel wears.
	if fluff >= 65.0:
		return 2
	if fluff >= 25.0:
		return 1
	return 0


func trees() -> int:
	return park.tree_count() if park else 0


func score() -> int:
	return trees() * 40 + int(stats.sprouted) * 150 + int(stats.chased) * 20 \
		+ Clock.seasons_passed * 50 + int(stats.buried) * 2


func commit_best() -> bool:
	var s := score()
	if s <= best or testing:
		return false
	best = s
	var c := ConfigFile.new()
	c.set_value("score", "best", best)
	c.save(SAVE)
	return true


func game_over(reason: String) -> void:
	if state != PLAYING:
		return
	death = reason
	set_state(OVER)
