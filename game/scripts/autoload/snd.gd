extends Node
## Sound: a small pool of SFX players and one crossfading music track per season.

const POOL := 12
var _players: Array[AudioStreamPlayer] = []
var _cache := {}
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current := ""
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	add_child(_music_a)
	add_child(_music_b)


func _stream(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


func play(name: String, pitch_jitter := 0.08, db := 0.0) -> void:
	if Settings.sfx_vol <= 0.0:
		return
	var s := _stream("res://assets/audio/sfx/%s.wav" % name)
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = s
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.volume_db = linear_to_db(Settings.sfx_vol) + db
	p.play()


func music(name: String, fade := 1.5) -> void:
	if name == _current:
		return
	_current = name
	var s: AudioStreamWAV = _stream("res://assets/audio/music/%s.wav" % name)
	var old := _music_a
	_music_a = _music_b
	_music_b = old
	if s:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = int(s.data.size() / 2.0)
		_music_a.stream = s
		_music_a.volume_db = -40.0
		_music_a.play()
		create_tween().tween_property(_music_a, "volume_db", _music_db(), fade)
	if _music_b.playing:
		var tw := create_tween()
		tw.tween_property(_music_b, "volume_db", -40.0, fade)
		tw.tween_callback(_music_b.stop)


func _music_db() -> float:
	return linear_to_db(maxf(0.0001, Settings.music_vol)) - 6.0


func refresh_volume() -> void:
	if _music_a.playing:
		_music_a.volume_db = _music_db()
