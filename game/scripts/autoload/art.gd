extends Node
## Loads the generated art: textures, sprite sheets (+ json meta -> SpriteFrames),
## the pixel font, and makes outlined pixel labels.

var font: FontFile
var _tex := {}
var _frames := {}


func _ready() -> void:
	font = load("res://assets/fonts/acorn5x7.png")


func tex(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load("res://assets/%s.png" % path)
	return _tex[path]


func frames(path: String) -> SpriteFrames:
	## path like "sprites/squirrel" or "park/flower_daisy"
	if _frames.has(path):
		return _frames[path]
	var t: Texture2D = load("res://assets/%s.png" % path)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/%s.json" % path))
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var w: int = meta.w
	var h: int = meta.h
	for an in meta.anims:
		var a: Dictionary = meta.anims[an]
		sf.add_animation(an)
		sf.set_animation_speed(an, a.fps)
		sf.set_animation_loop(an, a.loop)
		for i in range(int(a.n)):
			var at := AtlasTexture.new()
			at.atlas = t
			at.region = Rect2(i * w, int(a.row) * h, w, h)
			sf.add_frame(an, at)
	_frames[path] = sf
	return sf


func label(text: String, color := Color.WHITE, size := 9, outline := true) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline:
		l.add_theme_color_override("font_outline_color", Color("221612"))
		l.add_theme_constant_override("outline_size", 2)
	return l


func dot_texture(w: int, h: int, c: Color) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)
