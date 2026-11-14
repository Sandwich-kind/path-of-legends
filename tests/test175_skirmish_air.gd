extends SceneTree
# 1) Ближники (снежные волки, 4 шт.) против героя: урон в секунду, когда герой
#    а) стоит, б) бегает туда-сюда, в) стоит и стреляет; сколько волков вплотную,
#    заходят ли с двух сторон. 2) Автонаводка по летунам (хрустальные моли).
var main
var f := 0
var arena: ArenaMode
var p1: Player
var phase := 0
var t0 := 0
var hp0 := 0
var close_sum := 0.0
var close_max := 0
var both_sides := 0
var frames := 0
var bots: Array = []
var heroes := [0, 15]
var hi := 0
var mode_i := 0
const MODES := ["stand", "kite", "shoot"]
const SECS := 12

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _start(w: int, h: int) -> void:
	main.sel = [h, 0]
	main.start_arena(false, w)

func _grab() -> void:
	for n in main.world.get_children():
		if n is ArenaMode:
			arena = n
	p1 = arena.players[0]
	p1.frozen = false
	for b in arena._alive:
		if is_instance_valid(b):
			b.queue_free()
	arena._queue.clear()

func _wolves() -> void:
	for b in bots:
		if is_instance_valid(b):
			b.queue_free()
	p1.max_hp = 99999
	p1.hp = 99999
	p1.global_position.x = 1400
	p1.velocity = Vector2.ZERO
	bots = []
	for k in 4:
		var w := arena.spawn_at("snow_wolf", p1.global_position + Vector2(-500 + k * 330, -30))
		w.bot_abilities.erase("howl")
		if MODES[mode_i] == "shoot":
			w.max_hp = 99999
			w.hp = 99999
		bots.append(w)
	hp0 = p1.hp
	close_sum = 0.0
	close_max = 0
	both_sides = 0
	frames = 0

func _physics_process(_d: float) -> bool:
	f += 1
	for a in ["p1_shoot", "p1_left", "p1_right"]:
		Input.action_release(a)
	if f == 5:
		_start(61, 0)
	if f == 125:
		_grab()
		_wolves()
		t0 = f
		phase = 1
	if phase == 1:
		var m: String = MODES[mode_i]
		var g := f - t0
		if m == "kite":
			Input.action_press("p1_right" if (g / 50) % 2 == 0 else "p1_left")
		elif m == "shoot":
			var tx := 0.0
			var best := INF
			for b in bots:
				if is_instance_valid(b) and absf(b.global_position.x - p1.global_position.x) < best:
					best = absf(b.global_position.x - p1.global_position.x)
					tx = b.global_position.x
			p1.facing = 1 if tx > p1.global_position.x else -1
			if g % 14 < 3:
				Input.action_press("p1_shoot")
		var c := 0
		var sides := {}
		for b in bots:
			if is_instance_valid(b) and b.is_alive() and absf(b.global_position.x - p1.global_position.x) < 95.0:
				c += 1
				sides[signf(b.global_position.x - p1.global_position.x)] = true
		if sides.size() == 2:
			both_sides += 1
		close_sum += c
		close_max = maxi(close_max, c)
		frames += 1
		if g >= 60 * SECS:
			print("WOLVES %-5s dps=%.1f avg_close=%.2f max_close=%d both_sides=%d%%" % [m, (hp0 - p1.hp) / float(SECS),
					close_sum / frames, close_max, int(100.0 * both_sides / frames)])
			mode_i += 1
			if mode_i < MODES.size():
				_wolves()
				t0 = f
			else:
				for b in bots:
					if is_instance_valid(b):
						b.queue_free()
				phase = 2
				_start(36, heroes[hi])
				t0 = f
	if phase == 2 and f - t0 == 120:
		_grab()
		p1._protect = 999.0
		p1.global_position.x = 1200
		bots = []
		for k in 2:
			var m := arena.spawn_at("crystal_moth", p1.global_position + Vector2(300 + k * 200, -200))
			m.max_hp = 99999
			m.hp = 99999
			m.bot_abilities.erase("dust")
			bots.append(m)
		phase = 3
		t0 = f
	if phase == 3:
		p1._cd = [99.0, 99.0, 99.0]
		var tx2 := 0.0
		for b in bots:
			if is_instance_valid(b):
				tx2 = b.global_position.x
		p1.facing = 1 if tx2 > p1.global_position.x else -1
		Input.action_press("p1_shoot")
		if f - t0 >= 60 * 8:
			var dealt := 0
			for b in bots:
				if is_instance_valid(b):
					dealt += 99999 - b.hp
			print("AIR hero=%d dealt=%d (8 s)" % [heroes[hi], dealt])
			hi += 1
			if hi >= heroes.size():
				print("RESULT done")
				return true
			phase = 2
			_start(36, heroes[hi])
			t0 = f
	return false
