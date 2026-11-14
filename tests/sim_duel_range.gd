extends SceneTree
# С какой дистанции легенда на автопилоте лучше всего попадает в Дуэли (там нет доводки
# снарядов). Герой держит заданную дистанцию до стоящей на месте цели и бьёт SECS секунд;
# печатается урон в секунду для каждой дистанции и лучшая из них — она идёт в
# DUEL_DIST автопилота (tests/sim/autopilot.gd).
#   A=0,5,8 — номера легенд (по умолчанию все с набором)   DISTS=70,140,...   SECS=8
const AP := preload("res://tests/sim/autopilot.gd")
var main
var f := 0
var heroes: Array = []
var dists: Array = [70, 130, 200, 280, 360, 450, 560]
var secs := 8.0
var hi := 0
var di := -1
var pl: Array = []
var ap: Node
var t := 0.0
var dmg := 0.0
var prev := 0
var res := {}
var settle := 0.0

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.unlock_all_heroes()
	if OS.get_environment("A") != "":
		heroes = Array(OS.get_environment("A").split(",")).map(func(x): return int(x))
	else:
		for i in Characters.LIST.size():
			if Characters.LIST[i].has("kit"):
				heroes.append(i)
	if OS.get_environment("DISTS") != "":
		dists = Array(OS.get_environment("DISTS").split(",")).map(func(x): return int(x))
	if OS.get_environment("SECS") != "":
		secs = float(OS.get_environment("SECS"))
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _next() -> bool:
	if ap and is_instance_valid(ap):
		ap.release_all()
	di += 1
	if di >= dists.size():
		_best()
		di = 0
		hi += 1
	if hi >= heroes.size():
		return false
	seed(100 + hi * 10 + di)
	main.sel = [int(heroes[hi]), 8]
	main.map_id = "test_field"
	main.duel_opts = {"heal": false, "buffs": false, "mega": false, "sd": false, "sd_time": 120}
	main.kills_needed = 99
	main.start_duel()
	pl = main.duel_players.duplicate()
	for n in main.world.get_children():
		if n is Destructible:
			n.queue_free()
	for n in main.world.get_children():
		if n is StaticBody2D and n.position.y < 560.0 and not (n is Player):
			pass
	main.round_over = false
	if main.events and is_instance_valid(main.events):
		main.events.active = false
	var d := float(dists[di])
	pl[0].frozen = false
	pl[0].position = Vector2(576.0 - d / 2.0, 565.0)
	pl[0].facing = 1
	pl[1].position = Vector2(576.0 + d / 2.0, 565.0)
	pl[1].frozen = true
	pl[1].max_hp = 100000
	pl[1].hp = 100000
	ap = AP.new()
	ap.setup(pl[0], 5 + hi)
	ap.duel = true
	ap.dist_override = d
	main.world.add_child(ap)
	t = 0.0
	dmg = 0.0
	prev = pl[1].hp
	return true

func _best() -> void:
	var key: String = Characters.LIST[int(heroes[hi])].get("kit", "?")
	var row: Dictionary = res.get(key, {})
	var best := 0
	var bv := 0.0
	var s := ""
	for d in dists:
		bv = maxf(bv, float(row.get(d, 0.0)))
	for d in dists:
		var v := float(row.get(d, 0.0))
		s += " %d:%.0f" % [d, v]
		if v >= bv * 0.92:             # из почти равных — самая дальняя: издалека бить безопаснее
			best = int(d)
	print("RANGE %s best=%d dps=%.0f |%s" % [key, best, float(row.get(best, 0.0)), s])

func _physics_process(d: float) -> bool:
	f += 1
	if f == 3:
		_next()
		return false
	if f < 3 or pl.size() < 2:
		return false
	var e: Player = pl[1]
	var h: Player = pl[0]
	if not is_instance_valid(e) or not is_instance_valid(h):
		return false
	# цель стоит на месте и не умирает; герой не умирает тоже
	e.position = Vector2(576.0 + float(dists[di]) / 2.0, 565.0)
	e.velocity = Vector2.ZERO
	h.hp = h.max_hp
	if e.hp < prev:
		dmg += prev - e.hp
	e.hp = 100000
	prev = e.hp
	t += d
	if t >= secs:
		var key: String = Characters.LIST[int(heroes[hi])].get("kit", "?")
		if not res.has(key):
			res[key] = {}
		res[key][dists[di]] = dmg / secs
		if not _next():
			print("DONE")
			return true
	return false
