extends Node2D
## A tree in the park: sprout -> sapling -> oak. Oaks can be climbed (escape the
## dog / hawk / fox), drop acorns in fall, may get a beehive (bees sting: no
## climbing) or a burrow (warm hideout; burrow trees can never get a hive).

const HIVE_TIME := 18.0        # seconds of bees on nearby flowers to build a hive
const CANOPY_UP := 26.0        # canopy centre above the trunk base

var stage := "oak"             # sprout, sapling, oak
var variant := 0
var young := false             # grew this year: smaller crown, fewer acorns
var has_hive := false
var has_burrow := false
var hive_progress := 0.0
var burrow_n := 0              # acorns stashed around this tree (3 = burrow)
var drop_t := 0.0
var swarm: Node = null

var shadow: Sprite2D
var trunk: Sprite2D
var canopy: Sprite2D
var small: Sprite2D           # sprout / sapling sprite
var burrow: Sprite2D
var hive: AnimatedSprite2D
var body: StaticBody2D
var _alpha := 1.0


func setup(st: String, v := 0) -> void:
	stage = st
	variant = v


func _ready() -> void:
	add_to_group("tree")
	shadow = Sprite2D.new()
	shadow.texture = Art.tex("park/shadow_tree")
	shadow.position = Vector2(0, 1)
	shadow.z_index = -6
	shadow.z_as_relative = false
	add_child(shadow)
	burrow = Sprite2D.new()
	burrow.position = Vector2(0, 2)
	burrow.z_index = -4
	burrow.z_as_relative = false
	burrow.visible = false
	add_child(burrow)
	trunk = Sprite2D.new()
	trunk.offset = Vector2(0, -9)
	add_child(trunk)
	small = Sprite2D.new()
	add_child(small)
	canopy = Sprite2D.new()
	canopy.position = Vector2(0, -CANOPY_UP)
	canopy.z_as_relative = false
	canopy.z_index = 20
	add_child(canopy)
	hive = AnimatedSprite2D.new()
	hive.position = Vector2(9, -14)
	hive.z_as_relative = false
	hive.z_index = 21
	hive.visible = false
	add_child(hive)
	body = StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 3.0
	cs.shape = c
	body.add_child(cs)
	add_child(body)
	drop_t = randf_range(4.0, 20.0)
	apply_season(Clock.season)


func apply_season(s: int) -> void:
	var n: String = Clock.NAMES[s]
	trunk.texture = Art.tex("park/trunk_" + n)
	canopy.texture = Art.tex("park/canopy%d_%s" % [variant, n])
	burrow.texture = Art.tex("park/burrow_" + n)
	hive.sprite_frames = Art.frames("park/hive_" + n)
	hive.play("idle")
	if stage == "sprout":
		small.texture = Art.tex("park/sprout_" + n)
		small.offset = Vector2(0, -5)
	elif stage == "sapling":
		small.texture = Art.tex("park/sapling_" + n)
		small.offset = Vector2(0, -12)
	_refresh()


func _refresh() -> void:
	var oak := stage == "oak"
	trunk.visible = oak
	canopy.visible = oak
	shadow.visible = stage != "sprout"
	shadow.scale = Vector2.ONE if oak else Vector2(0.45, 0.6)
	small.visible = not oak
	canopy.scale = Vector2(0.86, 0.86) if young else Vector2.ONE
	body.collision_layer = 2 if stage != "sprout" else 0
	burrow.visible = has_burrow
	hive.visible = has_hive or hive_progress > 0.15


func grow() -> void:
	## Called at season changes: sprout -> sapling (summer), sapling -> oak (fall).
	if stage == "sprout":
		stage = "sapling"
	elif stage == "sapling":
		stage = "oak"
		young = true
	else:
		return
	apply_season(Clock.season)
	var target: Node2D = canopy if stage == "oak" else small
	target.scale = Vector2(0.3, 0.3)
	var full := Vector2(0.86, 0.86) if (stage == "oak" and young) else Vector2.ONE
	create_tween().tween_property(target, "scale", full, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func pop_in() -> void:
	small.scale = Vector2(0.1, 0.1)
	create_tween().tween_property(small, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func climbable() -> bool:
	return stage == "oak"


func canopy_center() -> Vector2:
	return global_position + Vector2(0, -CANOPY_UP)


func under_canopy(p: Vector2) -> bool:
	if stage != "oak":
		return false
	var d := (p - canopy_center() - Vector2(0, 8)) / Vector2(19, 15)
	return d.length_squared() < 1.0


func perch_point() -> Vector2:
	return global_position + Vector2(0, -20)


func add_hive(by: Node) -> void:
	if has_hive or has_burrow:
		return
	has_hive = true
	swarm = by
	hive.modulate.a = 1.0
	_refresh()
	Run.stats.hives += 1
	Snd.play("buzz", 0.05, -2.0)
	Run.popup.emit("HIVE!", global_position + Vector2(0, -44), Color("f6c83a"))


func add_burrow() -> void:
	if has_burrow or has_hive:
		return
	has_burrow = true
	hive_progress = 0.0
	_refresh()
	Run.stats.burrows += 1
	Snd.play("burrow_made")
	Run.popup.emit("BURROW!", global_position + Vector2(0, 6), Color("f2cc90"))


func _draw() -> void:
	if has_burrow or has_hive or stage != "oak":
		return
	for i in range(mini(burrow_n, 2)):
		var x := -9 + i * 14
		draw_rect(Rect2(x, 3, 3, 1), Color("4e341e"))
		draw_rect(Rect2(x + 1, 2, 1, 1), Color("8e6640"))


func set_burrow_n(n: int) -> void:
	if n != burrow_n:
		burrow_n = n
		queue_redraw()


func bee_progress(delta: float) -> void:
	if has_hive or has_burrow or stage == "sprout":
		return
	hive_progress += delta / HIVE_TIME
	_refresh()


func _process(delta: float) -> void:
	# the half-built hive shows up faintly so you can see the bees settling in
	if not has_hive and hive.visible:
		hive.modulate.a = clampf(hive_progress, 0.15, 0.85)
	# see-through crown when the squirrel (or something it should see) is under it
	var want := 1.0
	var sq = Run.squirrel
	if stage == "oak" and sq and (sq.tree == self or under_canopy(sq.global_position)):
		want = 0.45
	_alpha = move_toward(_alpha, want, delta * 4.0)
	canopy.modulate.a = _alpha
	hive.self_modulate.a = _alpha
