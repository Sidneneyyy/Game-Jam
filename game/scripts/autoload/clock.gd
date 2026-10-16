extends Node
## The turning year. Spring -> summer -> fall -> winter; a warning fires a few
## seconds before each change so the next season can be seen coming.

signal season_changed(s: int)
signal season_warning(next: int)
signal year_changed(y: int)

enum { SPRING, SUMMER, AUTUMN, WINTER }
const NAMES := ["spring", "summer", "autumn", "winter"]
const TITLES := ["SPRING", "SUMMER", "FALL", "WINTER"]
const COLORS := [Color("8fd05a"), Color("f6c83a"), Color("ec8a34"), Color("a8d8f8")]
const WARN := 8.0

var season := SPRING
var year := 1
var t := 0.0
var running := false
var seasons_passed := 0
var _warned := false


func reset() -> void:
	season = SPRING
	year = 1
	t = 0.0
	seasons_passed = 0
	_warned = false


func length() -> float:
	return Settings.season_seconds()


func progress() -> float:
	return clampf(t / length(), 0.0, 1.0)


func time_left() -> float:
	return length() - t


func next_season() -> int:
	return (season + 1) % 4


func _process(delta: float) -> void:
	if not running:
		return
	t += delta
	if not _warned and time_left() <= WARN:
		_warned = true
		season_warning.emit(next_season())
	if t >= length():
		advance()


func advance() -> void:
	t = 0.0
	_warned = false
	seasons_passed += 1
	season = next_season()
	if season == SPRING:
		year += 1
		year_changed.emit(year)
	season_changed.emit(season)
