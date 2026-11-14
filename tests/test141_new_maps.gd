extends SceneTree
# Новые карты Дуэли («Замки», «Экспресс»): строятся, эскиз рисуется, герои
# появляются не в стенах и могут бегать/прыгать, места возрождения свободны,
# «Мгновенная смерть» идёт ~30 с без ошибок и действительно опасна.
#   godot --path . -s res://tests/test141_new_maps.gd [-- shots] [-- only=castles]
var main
var f := 0
var t0 := 0
var mi := 0
var phase := ""
var shots := false
var maps := ["castles", "train"]
var stat := {}
var fails := 0
var x0 := [0.0, 0.0]
var min_y := [INF, INF]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	shots = "shots" in args
	for a in args:
		if a.begins_with("only="):
			maps = [a.substr(5)]
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _shot(name: String) -> void:
	if shots:
		DirAccess.make_dir_recursive_absolute("/tmp/claude-0/duel")
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/duel/%s.png" % name)

func _check(cond: bool, what: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + what)
	if not cond:
		fails += 1

func _free_at(pos: Vector2, size: Vector2) -> bool:
	var space: PhysicsDirectSpaceState2D = main.world.get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var rs := RectangleShape2D.new()
	rs.size = size - Vector2(6, 8)
	q.shape = rs
	q.transform = Transform2D(0, pos)
	q.collision_mask = Layer.WORLD
	return space.intersect_shape(q, 1).is_empty()

func _count(cls) -> int:
	var n := 0
	for c in main.world.get_children():
		if is_instance_of(c, cls):
			n += 1
	return n

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		_start()
		return false
	if phase == "" or f < 3:
		return false
	var id: String = maps[mi]
	var t := f - t0
	var ps: Array = main.duel_players
	match phase:
		"spawn":
			if t == 5:
				for i in 2:
					var p: Player = ps[i]
					_check(_free_at(p.global_position, p.body_size), "%s: P%d spawn free at %s" % [id, i + 1, p.global_position])
				var img := Maps.preview_image(id, Vector2(700, 300))
				_check(img.get_width() > 100, "%s: preview %dx%d" % [id, img.get_width(), img.get_height()])
				if shots:
					if img: img.save_png("/tmp/claude-0/duel/preview_%s.png" % id)
			if t == 150:
				_shot("%s_start" % id)
			if t >= 200 and not ps[0].frozen:
				phase = "move"
				t0 = f
				for i in 2:
					x0[i] = ps[i].global_position.x
				Input.action_press("p1_right")
				Input.action_press("p2_left")
		"move":
			for i in 2:
				min_y[i] = minf(min_y[i], ps[i].global_position.y)
			if t == 20 or t == 50:
				Input.action_press("p1_jump")
				Input.action_press("p2_jump")
			if t == 22 or t == 52:
				Input.action_release("p1_jump")
				Input.action_release("p2_jump")
			if t == 75:
				Input.action_release("p1_right")
				Input.action_release("p2_left")
				_check(ps[0].global_position.x > x0[0] + 60.0, "%s: P1 runs (%.0f -> %.0f)" % [id, x0[0], ps[0].global_position.x])
				_check(ps[1].global_position.x < x0[1] - 60.0, "%s: P2 runs (%.0f -> %.0f)" % [id, x0[1], ps[1].global_position.x])
				_check(min_y[0] < main.map_info["p1"].y - 60.0, "%s: P1 jumps" % id)
				_shot("%s_moved" % id)
				phase = "doom"
				t0 = f
				stat = {"balls": 0, "hp0": ps[0].hp + ps[1].hp, "dmg": 0, "bridge0": _bridge_cells(), "spawn_bad": 0,
						"spawns": 0, "deaths": 0, "tunnels": 0}
		"doom":
			if not main.events.doom:
				if t > 60 * 12:
					_check(false, "%s: doom started" % id)
					return _next()
				return false
			if stat.get("doom_f", 0) == 0:
				stat["doom_f"] = f
			var dt: int = f - int(stat["doom_f"])
			stat["balls"] = maxi(stat["balls"], _count(Castles.CannonBall))
			for p in ps:
				if p.hp < 40 and p.is_alive():
					var hp_before: int = p.hp
					p.heal(150)                     # пусть живут — проверяем саму «смерть», а не счёт
					stat["dmg"] += p.hp - hp_before # считаем то, что долечено на деле (лечение упирается в максимум)
			if id == "train" and main.events._special and main.events._special.get("tunnel_on"):
				stat["tunnels"] = maxi(stat["tunnels"], 1)
			if dt % 90 == 0:
				for p in ps:
					var r: Dictionary = main._pick_spawn(p)
					stat["spawns"] += 1
					var pos: Vector2 = r["pos"]
					var bad: bool = not r["parachute"] and not _free_at(pos, p.body_size)
					if main.map_info.has("spawn_max_y") and not r["parachute"] and pos.y > main.map_info["spawn_max_y"]:
						bad = true
					if bad:
						stat["spawn_bad"] += 1
						print("    bad spawn ", pos)
			if dt == 180:
				_shot("%s_doom3" % id)
			if dt == 60 * 12:
				_shot("%s_doom12" % id)
			if dt >= 60 * 30:
				var hp_lost: int = stat["hp0"] + stat["dmg"] - (ps[0].hp + ps[1].hp)
				print("  %s doom: balls_max=%d hp_lost=%d kills=%s bridge %d->%d spawns=%d bad=%d" % [id, stat["balls"],
						hp_lost, main.kills, stat["bridge0"], _bridge_cells(), stat["spawns"], stat["spawn_bad"]])
				_check(hp_lost > 150, "%s: sudden death hurts (%d hp)" % [id, hp_lost])
				_check(stat["spawn_bad"] == 0, "%s: respawn points free" % id)
				if id == "castles":
					_check(stat["balls"] > 0, "castles: cannons fire")
					_check(_bridge_cells() < stat["bridge0"], "castles: bridge burns")
				_shot("%s_doom30" % id)
				return _next()
	return false

func _bridge_cells() -> int:
	var b = main.map_info.get("bridge")
	if b != null and is_instance_valid(b):
		return b.cells.size()
	return 0

func _next() -> bool:
	mi += 1
	if mi >= maps.size():
		print("RESULT fails=", fails)
		return true
	_start()
	return false

func _start() -> void:
	main._on_duel_ready(maps[mi], 9, 99, [0, 1], {"heal": true, "buffs": true, "mega": true, "sd": true, "sd_time": 4})
	phase = "spawn"
	t0 = f
	min_y = [INF, INF]
