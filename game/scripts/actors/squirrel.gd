extends CharacterBody2D
## You: a red squirrel. WASD move, Shift sprint, Space bury / dig up,
## left click eat, right click climb a tree (or slip into its burrow).

const SPEED := 64.0
const SPRINT := 1.5

var facing := 1.0
var state := "move"  # move, busy, hurt, climbing, tree, burrowing, burrow, unburrow, dead
var st_t := 0.0
var busy_for := 0.0
var tree: Node = null
var invuln := 0.0
var anim: AnimatedSprite2D
var shadow: Sprite2D
var mouth: Sprite2D
var _set := ""
var _stage := -1
var _print_t := 0.0
var _step_t := 0.0
var _cold_warned := false
var _hunger_warned := false
var _thin_warned := false
var _dust_t := 0.0
var bot_dir := Vector2.INF     # set by the balance bot instead of real input
var bot_sprint := false


func _ready() -> void:
	Run.squirrel = self
	add_to_group("squirrel")
	collision_layer = 1
	collision_mask = 2
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 3.0
	cs.shape = c
	add_child(cs)
	shadow = Sprite2D.new()
	shadow.texture = Art.tex("park/shadow_small")
	shadow.position = Vector2(0, 1)
	shadow.z_as_relative = false
	shadow.z_index = -4
	add_child(shadow)
	anim = AnimatedSprite2D.new()
	anim.position = Vector2(-1, -10)
	add_child(anim)
	anim.animation_finished.connect(_on_anim_done)
	mouth = Sprite2D.new()
	mouth.texture = Art.tex("ui/acorn_tiny")
	add_child(mouth)
	_refresh_set()
	anim.play("idle")


# ------------------------------------------------------------------ queries
func hidden() -> bool:
	return state in ["climbing", "tree", "burrowing", "burrow", "unburrow"]


func covered() -> bool:
	## Safe from the hawk: up a tree, in a burrow, or under a leafy crown.
	return hidden() or (Run.park != null and Run.park.under_canopy(global_position))


func can_act() -> bool:
	return Run.playing() and state == "move"


# ------------------------------------------------------------------ input
func _unhandled_input(e: InputEvent) -> void:
	if not Run.playing():
		return
	if e.is_action_pressed("act"):
		_act()
	elif e.is_action_pressed("eat"):
		_eat()
	elif e.is_action_pressed("climb"):
		_climb()


func _act() -> void:
	if not can_act():
		return
	var park = Run.park
	var s: Node = park.stash_near(global_position, 10.0)
	# carrying acorns: bury (stacking onto a stash you're standing on);
	# empty cheeks: dig up what's here (in winter, the ground is frozen: dig only)
	var digging: bool = s != null and (Run.cheeks == 0 or Clock.season == Clock.WINTER) and Run.cheeks < Run.MAX_CHEEKS
	if digging:
		var got: int = s.take(Run.MAX_CHEEKS - Run.cheeks)
		Run.cheeks += got
		Run.stats.dug += got
		Snd.play("dig")
		park.dirt(s.global_position, Clock.season == Clock.WINTER)
		Run.popup.emit("+%d" % got, global_position + Vector2(0, -22), Color("f2cc90"))
		_busy("dig", 0.35)
		Run.changed.emit()
	elif Run.cheeks > 0:
		if Clock.season == Clock.WINTER:
			_deny("FROZEN")
			Snd.play("step_snow")
			return
		Run.cheeks -= 1
		Run.stats.buried += 1
		var st: Node = park.bury(s.global_position if s else global_position + Vector2(facing * 3.0, 0))
		Snd.play("bury")
		park.dirt(st.global_position, false)
		_busy("dig", 0.4)
		Run.changed.emit()
	elif s:
		_deny("CHEEKS FULL")
	else:
		_deny("")


func _eat() -> void:
	if not can_act():
		return
	var park = Run.park
	var f: Node = park.flower_near(global_position, 11.0)
	if f:
		f.eat()
		Run.feed(7.0)
		Run.stats.flowers += 1
		Snd.play("munch")
		Run.popup.emit("+7", global_position + Vector2(0, -22), Color("a8dc70"))
		park.flower_eaten(f)
		_busy("eat", 0.5)
		return
	var b: Node = park.bush_near(global_position, 16.0)
	if b and b.pick():
		Run.feed(6.0)
		Snd.play("berry")
		Run.popup.emit("+6", global_position + Vector2(0, -22), Color("ff7a88"))
		_busy("eat", 0.45)
		return
	if Run.cheeks <= 0:
		_deny("")
		return
	if Run.hunger >= 99.0 and Clock.season != Clock.AUTUMN:
		_deny("FULL")
		return
	Run.cheeks -= 1
	Run.stats.eaten += 1
	var fl := Run.feed(Run.ACORN_FOOD)
	Snd.play("eat")
	if fl > 0.0:
		Snd.play("fluff", 0.05, -4.0)
		Run.popup.emit("+FLUFF", global_position + Vector2(0, -24), Color("fbf6ec"))
	else:
		Run.popup.emit("+%d" % int(Run.ACORN_FOOD), global_position + Vector2(0, -22), Color("a8dc70"))
	_busy("eat", 0.6)


func _climb() -> void:
	if not Run.playing():
		return
	if state == "tree":
		_climb_down()
		return
	if state == "burrow":
		_leave_burrow()
		return
	if state != "move":
		return
	var t: Node = Run.park.tree_near(global_position, 13.0)
	if t == null:
		_deny("")
		return
	if t.has_burrow:
		_enter_burrow(t)
	elif t.has_hive and Clock.season != Clock.WINTER:
		sting(t.global_position)
		_deny("BEES!")
	elif t.climbable():
		_climb_up(t)
	else:
		_deny("TOO SMALL")


func _deny(msg: String) -> void:
	Snd.play("deny", 0.05, -6.0)
	if msg != "":
		Run.popup.emit(msg, global_position + Vector2(0, -24), Color("f2a088"))


func _busy(a: String, t: float) -> void:
	state = "busy"
	st_t = 0.0
	busy_for = t
	velocity = Vector2.ZERO
	anim.play(a)


# ------------------------------------------------------------------ trees + burrows
func _climb_up(t: Node) -> void:
	state = "climbing"
	tree = t
	velocity = Vector2.ZERO
	anim.play("climb")
	Snd.play("climb")
	z_as_relative = false
	z_index = 19  # above everything on the ground, just under the crown
	var tw := create_tween()
	tw.tween_property(self, "global_position", t.global_position + Vector2(0, 1), 0.12)
	tw.tween_property(self, "global_position", t.perch_point(), 0.45)
	tw.tween_callback(func():
		state = "tree"
		st_t = 0.0
		anim.play("sit"))


func _climb_down() -> void:
	state = "climbing"
	anim.play("climb")
	anim.flip_v = true
	Snd.play("climb")
	var land: Vector2 = tree.global_position + Vector2(facing * 9.0, 5.0)
	var tw := create_tween()
	tw.tween_property(self, "global_position", tree.global_position + Vector2(0, 1), 0.4)
	tw.tween_property(self, "global_position", land, 0.12)
	tw.tween_callback(func():
		anim.flip_v = false
		z_as_relative = true
		z_index = 0
		tree = null
		state = "move")


func _enter_burrow(t: Node) -> void:
	state = "burrowing"
	tree = t
	velocity = Vector2.ZERO
	facing = 1.0
	global_position = t.global_position + Vector2(-2, 3)
	anim.play("burrow")
	Snd.play("burrow")


func _leave_burrow() -> void:
	state = "unburrow"
	anim.visible = true
	shadow.visible = true
	anim.play_backwards("burrow")
	Snd.play("burrow", 0.1, -3.0)


func _on_anim_done() -> void:
	if state == "burrowing":
		state = "burrow"
		st_t = 0.0
		anim.visible = false
		shadow.visible = false
	elif state == "unburrow":
		state = "move"
		tree = null
		global_position += Vector2(0, 6)


# ------------------------------------------------------------------ hits
func take_hit(loss: float, from: Vector2, drop := true, cold := 0.0) -> bool:
	if hidden() or invuln > 0.0 or state == "dead" or not Run.playing():
		return false
	Run.hunger -= loss
	Run.warmth = maxf(0.0, Run.warmth - cold)
	Run.stats.hits += 1
	if drop and Run.cheeks > 0:
		Run.park.scatter_acorns(global_position, Run.cheeks)
		Run.popup.emit("DROPPED!", global_position + Vector2(0, -30), Color("f2a83a"))
		Run.cheeks = 0
	Run.popup.emit("-%d" % int(loss), global_position + Vector2(0, -22), Color("f05a4a"))
	state = "hurt"
	st_t = 0.0
	invuln = 1.3
	var away := (global_position - from)
	velocity = (away.normalized() if away.length() > 0.5 else Vector2(-facing, 0)) * 150.0
	anim.play("hurt")
	Snd.play("hurt")
	Run.park.shake(3.0)
	Run.changed.emit()
	return true


func sting(from: Vector2) -> void:
	if invuln > 0.0 or hidden():
		return
	Snd.play("sting")
	take_hit(6.0, from, false)


func shove(from: Vector2, loss: float) -> void:
	## A rival fighting you off: knocked back, a little hungrier, keeps acorns.
	take_hit(loss, from, false)


# ------------------------------------------------------------------ frame
func _physics_process(delta: float) -> void:
	if not Run.playing():
		if state != "dead" and Run.state == Run.OVER:
			state = "dead"
			anim.play("hurt")
		return
	st_t += delta
	invuln = maxf(0.0, invuln - delta)
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var sprint_key := Input.is_action_pressed("sprint")
	if bot_dir != Vector2.INF:
		dir = bot_dir
		sprint_key = bot_sprint
	var sprinting := sprint_key and dir != Vector2.ZERO
	match state:
		"move":
			var sp := SPEED * _speed_mult() * (SPRINT if sprinting else 1.0)
			velocity = velocity.move_toward(dir * sp, 900.0 * delta)
			if dir.x != 0.0:
				facing = signf(dir.x)
			move_and_slide()
			global_position = Run.park.clamp_in(global_position)
			Run.park.pickup(self)
			if velocity.length() > 8.0:
				anim.play("run")
				anim.speed_scale = 1.35 if sprinting else 1.0
				_footsteps(delta)
			else:
				anim.play("idle")
				anim.speed_scale = 1.0
		"busy":
			if st_t >= busy_for:
				state = "move"
		"hurt":
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			move_and_slide()
			global_position = Run.park.clamp_in(global_position)
			if st_t > 0.45:
				state = "move"
		"tree", "burrow":
			if dir != Vector2.ZERO and st_t > 0.3:
				if state == "tree":
					_climb_down()
				else:
					_leave_burrow()
	anim.flip_h = facing < 0.0
	anim.position.x = -1.0 * facing
	anim.modulate.a = 0.45 if (invuln > 0.0 and fmod(invuln, 0.2) < 0.1) else 1.0
	shadow.visible = not hidden()
	mouth.visible = Run.cheeks > 0 and (state == "move" or state == "hurt")
	if mouth.visible:
		var bob := -1.0 if anim.animation == "run" and anim.frame in [1, 2] else 0.0
		mouth.position = Vector2(facing * (8.0 + Run.fluff_stage() * 0.5), -10.0 + bob - Run.fluff_stage() * 0.5)
	_survive(delta, sprinting and state == "move")
	_refresh_set()


func _speed_mult() -> float:
	var m := 1.0
	if Clock.season == Clock.WINTER:
		m *= 0.8
	if Run.fluff_stage() == 2:
		m *= 0.92
	return m


func _footsteps(delta: float) -> void:
	if Input.is_action_pressed("sprint") or bot_sprint:
		_dust_t -= delta
		if _dust_t <= 0.0:
			_dust_t = 0.18
			Run.park.puff(global_position + Vector2(-facing * 4.0, 0), Clock.season == Clock.WINTER)
	if Clock.season != Clock.WINTER:
		return
	_print_t -= delta
	if _print_t <= 0.0:
		_print_t = 0.16
		Run.park.squirrel_prints.add(global_position + Vector2(randf_range(-1, 1), 1), 0.0)
		Snd.play("step_snow", 0.2, -14.0)


func _survive(delta: float, sprinting: bool) -> void:
	var easy := 0.7 if Settings.assist else 1.0
	var drain := 0.75 * easy * (1.0 + 0.1 * (Clock.year - 1))
	if sprinting:
		drain += 0.9
	var resting := state == "tree" or state == "burrow"
	if resting:
		drain *= 0.6
	if Clock.season == Clock.WINTER:
		# you still get hungry (eat from your stashes), and the cold burns extra:
		# fluff pays that first; with no fluff left it comes out of your food too
		Run.hunger -= drain * delta
		var burn := 0.9 * easy * (0.5 if resting else 1.0)
		if Run.fluff > 0.0:
			Run.fluff = maxf(0.0, Run.fluff - burn * delta)
		else:
			Run.hunger -= burn * 1.15 * delta  # a lean body burns its food to keep warm
		# fluff also insulates; a burrow is the only real shelter
		if state == "burrow":
			# a burrow stops the cold, but only a well-fed, fluffy body warms back up
			var heat := 9.0 * clampf(Run.fluff / 40.0, 0.0, 1.0) * (1.4 if Settings.assist else 1.0)
			Run.warmth = minf(100.0, Run.warmth + heat * delta)
			if heat < 2.0 and not _thin_warned:
				_thin_warned = true
				Run.popup.emit("TOO THIN TO WARM UP", global_position + Vector2(0, -26), Color("a8d8f8"))
			_cold_warned = false
		else:
			var chill := 2.6 * pow(1.0 - Run.fluff / 100.0, 1.5) * easy
			Run.warmth -= chill * delta
			if Run.warmth < 50.0 and not _cold_warned:
				_cold_warned = true
				Snd.play("shiver")
				Run.popup.emit("FREEZING!", global_position + Vector2(0, -26), Color("a8d8f8"))
	else:
		Run.hunger -= drain * delta
		Run.warmth = minf(100.0, Run.warmth + 12.0 * delta)
		# body fat thins out again through spring
		if Clock.season == Clock.SPRING and Run.fluff > 0.0:
			Run.fluff = maxf(0.0, Run.fluff - 0.8 * delta)
	if Run.hunger < 20.0 and not _hunger_warned:
		_hunger_warned = true
		Run.popup.emit("HUNGRY!", global_position + Vector2(0, -26), Color("f05a4a"))
	elif Run.hunger > 30.0:
		_hunger_warned = false
	Run.hunger = minf(Run.hunger, 100.0)
	if Run.hunger <= 0.0:
		Run.hunger = 0.0
		_die("STARVED")
	elif Run.warmth <= 0.0:
		Run.warmth = 0.0
		_die("FROZE")


func _die(reason: String) -> void:
	state = "dead"
	anim.play("hurt")
	Snd.play("death")
	Run.game_over(reason)


func _refresh_set() -> void:
	var stage := Run.fluff_stage()
	if stage == _stage:
		return
	var grew := _stage >= 0 and stage > _stage
	_stage = stage
	var n: String = ["sprites/squirrel", "sprites/squirrel_plump", "sprites/squirrel_fluffy"][stage]
	_set = n
	var cur := anim.animation
	var fr := anim.frame
	anim.sprite_frames = Art.frames(n)
	if anim.sprite_frames.has_animation(cur):
		anim.play(cur)
		anim.frame = fr
	if grew:
		Snd.play("fluff")
		var tw := create_tween()
		anim.scale = Vector2(1.25, 1.25)
		tw.tween_property(anim, "scale", Vector2.ONE, 0.25)
