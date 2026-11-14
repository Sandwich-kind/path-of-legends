extends SceneTree
# Замер баланса Дуэли: две легенды на автопилоте (tests/sim/autopilot.gd) дерутся
# до KILLS убийств (или пока не выйдет MAXT секунд). На каждый бой — строка DUEL.
#   PAIRS=0:8,5:19        — пары номеров легенд из Characters.LIST
#   или A=0,5 REFS=0,7,8  — каждая из A против каждой из REFS
#   MAPS=test_field,arena_colosseum   KILLS=3   MAXT=120   SEED=1
#   SWAP=1 — каждый бой ещё и со сменой сторон (по умолчанию включено)
# Автопилот не уворачивается и играет одинаково за обе стороны, поэтому числа
# показывают силу набора, а не мастерство: смотреть стоит на перекосы.
const AP := preload("res://tests/sim/autopilot.gd")
var main
var f := 0
var jobs: Array = []            # [a, b, карта]: a играет за первого игрока
var ji := -1
var kills_n := 3
var maxt := 120.0
var seed0 := 1
var pilots: Array = []
var pl: Array = []
var t := 0.0
var fighting := false
var dmg := [0.0, 0.0]           # сколько урона нанёс игрок 0 и 1
var heal := [0.0, 0.0]
var prev := [0, 0]
var alive := [true, true]

func _env(k: String, d: String) -> String:
	return OS.get_environment(k) if OS.get_environment(k) != "" else d

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.unlock_all_heroes()
	kills_n = int(_env("KILLS", "3"))
	maxt = float(_env("MAXT", "120"))
	seed0 = int(_env("SEED", "1"))
	var maps := _env("MAPS", "test_field,arena_colosseum").split(",")
	var pairs: Array = []
	if OS.get_environment("PAIRS") != "":
		for e in OS.get_environment("PAIRS").split(","):
			pairs.append([int(e.split(":")[0]), int(e.split(":")[1])])
	else:
		for a in _env("A", "0").split(","):
			for b in _env("REFS", "0,7,8,10").split(","):
				if int(a) != int(b):
					pairs.append([int(a), int(b)])
	for pr in pairs:
		for m in maps:
			jobs.append([pr[0], pr[1], m])
			if _env("SWAP", "1") == "1":
				jobs.append([pr[1], pr[0], m])
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _next() -> bool:
	for ap in pilots:
		if is_instance_valid(ap):
			ap.release_all()
	pilots.clear()
	ji += 1
	if ji >= jobs.size():
		return false
	seed(seed0 * 1000 + ji)
	main.sel = [int(jobs[ji][0]), int(jobs[ji][1])]
	main.map_id = String(jobs[ji][2])
	main.kills_needed = kills_n
	main.wins_needed = 99
	main.duel_opts = {"heal": false, "buffs": false, "mega": false, "sd": false, "sd_time": 120}
	main.start_duel()
	pl = main.duel_players.duplicate()
	for i in 2:
		var ap: Node = AP.new()
		ap.setup(pl[i], seed0 * 100 + ji * 2 + i)
		ap.duel = true
		main.world.add_child(ap)
		pilots.append(ap)
	t = 0.0
	fighting = false
	dmg = [0.0, 0.0]
	heal = [0.0, 0.0]
	prev = [pl[0].hp, pl[1].hp]
	alive = [true, true]
	return true

func _name(i: int) -> String:
	return String(Characters.LIST[i].get("kit", "legend%d" % i))

func _report(why: String) -> void:
	var k: Array = main.kills
	var win := "draw"
	if int(k[0]) != int(k[1]):
		win = "p1" if int(k[0]) > int(k[1]) else "p2"
	elif absf(float(dmg[0]) - float(dmg[1])) > 30.0:
		win = "p1" if float(dmg[0]) > float(dmg[1]) else "p2"       # по времени: у кого больше урона
	print("DUEL p1=%s p2=%s map=%s win=%s kills=%d:%d time=%.1f dmg=%.0f:%.0f heal=%.0f:%.0f hp=%d:%d end=%s" % [
		_name(int(jobs[ji][0])), _name(int(jobs[ji][1])), String(jobs[ji][2]), win, int(k[0]), int(k[1]), t,
		float(dmg[0]), float(dmg[1]), float(heal[0]), float(heal[1]), pl[0].max_hp, pl[1].max_hp, why])

func _physics_process(d: float) -> bool:
	f += 1
	if f == 3:
		if not _next():
			return true
		return false
	if f < 3 or pl.size() < 2:
		return false
	if not fighting:
		if not main.round_over:
			fighting = true
		return false
	t += d
	for i in 2:
		var p: Player = pl[i]
		if not is_instance_valid(p):
			continue
		var now_alive := p.is_alive()
		var hp := maxi(p.hp, 0)
		if alive[i] and hp < int(prev[i]):
			dmg[1 - i] = float(dmg[1 - i]) + (int(prev[i]) - hp)
		elif alive[i] and now_alive and hp > int(prev[i]):
			heal[i] = float(heal[i]) + (hp - int(prev[i]))
		prev[i] = hp
		alive[i] = now_alive
	if OS.get_environment("DEBUG") == "1" and f % 180 == 0:
		print("  t=%.0f p1=%s hp=%d  p2=%s hp=%d floor=%s/%s" % [t, str(Vector2i(pl[0].global_position)), pl[0].hp, str(Vector2i(pl[1].global_position)), pl[1].hp, str(pl[0].is_on_floor()), str(pl[1].is_on_floor())])
	if main.round_over or t > maxt:
		_report("kills" if main.round_over else "time")
		if not _next():
			print("DONE")
			return true
	return false
