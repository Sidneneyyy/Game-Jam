extends Sprite2D
## A berry bush: in summer it fruits (quick food you can't stash).

var berries := 0
var _regrow := 0.0


func _ready() -> void:
	add_to_group("bush")
	offset = Vector2(0, -8)
	apply_season(Clock.season)


func apply_season(s: int) -> void:
	berries = 3 if s == Clock.SUMMER else 0
	_show()


func _show() -> void:
	var n: String = Clock.NAMES[Clock.season]
	if berries >= 4:
		texture = Art.tex("park/bush6_" + n)
	elif berries > 0:
		texture = Art.tex("park/bush3_" + n)
	else:
		texture = Art.tex("park/bush_" + n)


func pick() -> bool:
	if berries <= 0:
		return false
	berries -= 1
	_show()
	return true


func _process(delta: float) -> void:
	if Clock.season != Clock.SUMMER or not Run.playing():
		return
	_regrow += delta
	if _regrow >= 18.0:
		_regrow = 0.0
		if berries < 3:
			berries += 1
			_show()
