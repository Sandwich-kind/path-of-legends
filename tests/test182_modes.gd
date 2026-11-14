extends SceneTree
# Режимы Арены: Босс-раш (только бои с боссами, по порядку), сложный режим
# (прочнее враги, на четверть больше, особенности, новые приёмы и фаза у боссов).
var main
var f := 0
var arena: ArenaMode
var p1: Player
var fails := 0
var step := "rush"
var t0 := 0
var hp_before := 0
var phase_hp := 0
var normal_count := 0
var aff_bots: Array = []

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _find() -> void:
	arena = null
	for n in main.world.get_children():
		if n is ArenaMode:
			arena = n
	p1 = arena.players[0] if arena else null

func _guard() -> void:
	if p1:
		p1.hp = p1.max_hp
		p1._protect = 1.0

func _physics_process(_d: float) -> bool:
	f += 1
	match step:
		"rush":
			if f == 5:
				main.sel = [8, 0]
				Save.clear_arena_progress("rush_solo")
				main.start_arena(false, ArenaMode.first_rush_wave(), "rush")
			if f == 120:
				_find()
				check(arena.rules == "rush", "rush rules set")
				check(arena._upcoming() == 5, "rush starts at the first boss wave (%d)" % arena._upcoming())
				var rw := ArenaMode.rush_waves()
				check(rw.size() == 22 and rw[0] == 5 and rw[-1] == 100, "22 boss fights from 5 to 100 (%d)" % rw.size())
				check(ArenaMode.rush_wave_from(11) == 15 and ArenaMode.rush_wave_from(11, -1) == 10, "rush stepping")
			if f > 120:
				_guard()
				var b = arena._boss
				if f > 400 and b != null and is_instance_valid(b) and not b.cutscene_shield and t0 == 0:
					b.hp = 1
					b.take_damage(50, p1)
					t0 = f
				if t0 > 0 and f == t0 + 60 * 9:
					var pr := Save.arena_progress("rush_solo")
					check(int(pr.get("wave", 0)) == 10, "rush progress saved: next fight is 10 (%s)" % str(pr))
					check(arena.wave == 10 or arena._state == "break", "rush goes straight to wave 10 (wave %d, %s)" % [arena.wave, arena._state])
					step = "hard"
					f = 0
					t0 = 0
		"hard":
			if f == 5:
				Save.clear_arena_progress("hard_solo")
				main.start_arena(false, 41, "hard")
			if f == 120:
				_find()
				check(arena.rules == "hard", "hard rules set")
			if f == 399:
				var base := Bots.wave_list(41).size()
				normal_count = base
				var total := arena._queue.size() + arena._alive.size() + arena.kills
				check(total >= base + ceili(base * HardMode.EXTRA) - 1, "hard wave is bigger (%d vs %d)" % [total, base])
			if f > 120:
				_guard()
			if f == 400:
				var ok := true
				for b in arena._alive:
					if is_instance_valid(b) and not b.has_meta("summoned"):
						var k: String = b.get_meta("kind")
						if not b.has_meta("hard"):
							ok = false
				check(ok and not arena._alive.is_empty(), "every regular foe is hardened (%d alive)" % arena._alive.size())
				# все особенности разом: по одному врагу на каждую
				for k in HardMode.AFFIXES:
					var b := arena.spawn_at("grunt", p1.global_position + Vector2(400, -40))
					b.remove_meta("summoned")
					var a := HardMode.Affix.new()
					a.p = b
					a.am = arena
					a.kinds = [k]
					b.add_child(a)
					aff_bots.append(b)
				check(aff_bots[0].crust > 0.0, "shield affix gives a crust")
			if f == 400 + 60 * 8:
				for b in aff_bots:
					if is_instance_valid(b) and b.is_alive():
						b.take_damage(99999, p1)
			if f == 400 + 60 * 11:
				step = "boss"
				f = 0
		"boss":
			if f == 5:
				main.start_arena(false, 60, "hard")
			if f == 120:
				_find()
			if f > 120:
				_guard()
				var b = arena._boss
				if b != null and is_instance_valid(b) and not b.cutscene_shield and t0 == 0 and f > 300:
					t0 = f
					check(b.get_node_or_null("HardBoss") != null, "boss has new hard moves")
					var base_hp := int(Bots.TYPES["bog_lord"]["hp"])
					check(b.max_hp >= int(base_hp * HardMode.BOSS_HP * 0.95), "boss hp raised (%d)" % b.max_hp)
				if t0 > 0 and f == t0 + 60 * 14:
					phase_hp = int(b.max_hp * 0.38)
					b.hp = phase_hp
					b.heal(0)
				if t0 > 0 and f == t0 + 60 * 17:
					check(b.hp >= phase_hp + int(b.max_hp * 0.3), "phase healed the boss (%d -> %d)" % [phase_hp, b.hp])
					check(not b.cutscene_shield, "boss fightable after phase")
				if t0 > 0 and f == t0 + 60 * 26:
					print("RESULT fails=", fails)
					return true
	if f > 60 * 60:
		print("FAIL timeout in ", step)
		return true
	return false
