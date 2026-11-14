extends SceneTree
# Раунды, возрождение, парашют, деревья, задние стены
var main
var f := 0
var t0 := 0
var spawns: Array = []
var sky_count := 0
var bw0 := 0
var tree0 := 0
var tree_ref: Destructible
var fails := 0
func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func ps() -> Array:
	var r := []
	for n in main.world.get_children():
		if n is Player:
			r.append(n)
	return r

func trees() -> Array:
	var r := []
	for n in main.world.get_children():
		if n is Destructible and n.background and not n.ghost:
			r.append(n)
	return r

func backwalls() -> Array:
	var r := []
	for n in main.world.get_children():
		if n is Destructible and n.ghost:
			r.append(n)
	return r

func _physics_process(_d: float) -> bool:
	f += 1
	match f:
		3:
			main._on_duel_ready("two_houses", 2, 2, [0, 1])
		10:
			check(main.round_num == 1 and ps()[0].frozen and main.round_over, "round 1 starts frozen for the countdown")
			check(trees().size() >= 2 and backwalls().size() == 2, "map has trees (%d) and house back walls (%d)" % [trees().size(), backwalls().size()])
		200:
			check(not ps()[0].frozen and not main.round_over, "after the countdown the fight is on")
		# --- убийство 1
		205:
			ps()[1].take_damage(999, ps()[0])
		206:
			check(main.kills == [1, 0], "a kill is counted (%s)" % str(main.kills))
		# --- статистика возрождений игрока 2
		330:
			var p: Player = ps()[1]
			check(p.is_alive() and p.last_spawn_kind != "", "player 2 respawned (%s at %s)" % [p.last_spawn_kind, str(p.position.round())])
		# --- 40 возрождений подряд: где появляется
		340:
			var p: Player = ps()[1]
			for k in 40:
				var r: Dictionary = main._pick_spawn(p)
				spawns.append(r["pos"])
				if r["parachute"]:
					sky_count += 1
			var left := 0
			var xs := []
			for s in spawns:
				if s.x < 2000:
					left += 1
				xs.append(int(s.x))
			xs.sort()
			check(left == 0, "40 respawns of player 2: none on the enemy half (x %d..%d, from the sky %d)" % [xs[0], xs[-1], sky_count])
			var ys := {}
			for s in spawns:
				ys[int(s.y / 100) * 100] = true
			check(ys.size() >= 2, "respawns use several heights (%s)" % str(ys.keys()))
		# --- парашют: принудительно в небо
		350:
			var p: Player = ps()[0]
			p.position = map_sky(0)
			p.velocity = Vector2.ZERO
			p._para = 1
			t0 = f
		400:
			check(ps()[0]._para == 1 and ps()[0].velocity.y > 900.0, "parachute: free fall first (vy=%d)" % int(ps()[0].velocity.y))
		460:
			check(ps()[0]._para == 2 and ps()[0].velocity.y < 300.0, "parachute: canopy opens and slows the fall (vy=%d)" % int(ps()[0].velocity.y))
		560:
			check(ps()[0]._para == 0 and ps()[0].is_on_floor(), "parachute: landed")
		600:
			var lying := 0
			for n in main.world.get_children():
				if n is Node2D and not (n is CollisionObject2D) and n.z_index == -1 and n.get_child_count() >= 2 and n.modulate.a > 0.9:
					lying += 1
			check(ps()[0]._para == 0 and lying >= 1, "the canopy stays lying on the ground (%d)" % lying)
		# --- гранатa поджигает дерево
		610:
			var tr: Destructible = trees()[0]
			tree0 = tr.cells.size()
			tree_ref = tr
			var g := Grenade.new()
			g.team = 0
			g.attacker = ps()[0]
			g.position = tr.global_position + Vector2(0, 170)
			main.world.add_child(g)
		611:
			for n in main.world.get_children():
				if n is Grenade:
					n.linear_velocity = Vector2.ZERO
		900:
			var left: int = tree_ref.cells.size() if is_instance_valid(tree_ref) else 0
			var pieces := 0
			for n in main.world.get_children():
				if n is Destructible and not n.background and n.flammable:
					pieces += 1
			check(left < tree0, "grenade and fire eat the tree (%d -> %d cells, fallen pieces %d)" % [tree0, left, pieces])
		# --- тяжёлый снаряд сквозь задние стены и деревья
		910:
			var p: Player = ps()[1]
			p.position = Vector2(3950 - 300, 1215)
			p.facing = -1
			var bw: Destructible = backwalls()[1]
			bw0 = bw.cells.size()
			p._fire_shell()
		1050:
			var bw: Destructible = backwalls()[1]
			check(bw.cells.size() < bw0, "heavy shell breaks through the back wall (%d -> %d cells)" % [bw0, bw.cells.size()])
		# --- раунд 1 до 2 убийств
		1060:
			ps()[1].take_damage(999, ps()[0])
		1065:
			check(main.round_wins == [1, 0] and main.round_over, "2 kills win the round (%s)" % str(main.round_wins))
		1250:
			check(main.round_num == 2 and main.kills == [0, 0] and trees().size() >= 2, "round 2: score reset, map rebuilt whole")
		1420:
			ps()[1].take_damage(999, ps()[0])
		1600:
			ps()[1].take_damage(999, ps()[0])
		1720:
			var ended := false
			for n in main.world.get_children():
				if n is MatchEnd:
					ended = true
			check(ended and main.round_wins == [2, 0], "2 rounds win the match, the end screen shows")
			print("RESULT fails=", fails)
			return true
	return false

func map_sky(team: int) -> Vector2:
	return main.map_info["sky"][team]
