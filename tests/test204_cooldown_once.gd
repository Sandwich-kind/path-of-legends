extends SceneTree
# Откат способностей идёт один раз за кадр: у каждой легенды с набором способностей
# указанная перезарядка (ability_cds) равна настоящему времени отката. Раньше набор
# уменьшал откат второй раз, и способности возвращались вдвое быстрее, чем написано.
# Заодно: число на кнопке способности показывает настоящие секунды.
var main
var f := 0
var fails := 0
var pairs: Array = []
var pi := -1
var t0 := 0
var pl: Array = []
var left: Array = []            # [игрок, номер способности, указанный откат]
var worst := 0.0

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	var kits: Array = []
	for i in Characters.LIST.size():
		if Characters.LIST[i].has("kit"):
			kits.append(i)
	for n in range(0, kits.size(), 2):
		pairs.append([kits[n], kits[mini(n + 1, kits.size() - 1)]])

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _next() -> bool:
	pi += 1
	if pi >= pairs.size():
		return false
	main.sel = pairs[pi].duplicate()
	main.map_id = "test_field"
	main.start_duel()
	t0 = f
	pl = []
	left = []
	return true

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		check(Characters.LIST[2]["cds"] == [8.0, 10.0, 9.0] and Characters.LIST[3]["cds"] == [7.0, 10.0, 10.0], "test legends keep their cooldowns")
		_next()
		return false
	if f < 3:
		return false
	var t := f - t0
	if t == 2:
		for n in main.world.get_children():
			if n is Destructible:
				n.queue_free()
			if n is Player:
				pl.append(n)
		pl.sort_custom(func(a, b): return a.index < b.index)
	if t == 5:
		for p in pl:
			p.frozen = false
			p.position = Vector2(400 + 700 * p.index, 565)
			for k in 3:
				if String(p.abilities[k]) == "receipt":
					continue                       # у чека Главного на кнопке — заряды, а не секунды
				p._cd[k] = float(p.ability_cds[k])
				left.append([p, k, float(p.ability_cds[k]), f])
	if t > 5:
		for p in pl:
			p.hp = p.max_hp
		for e in left.duplicate():
			var p: Player = e[0]
			if float(p._cd[int(e[1])]) <= 0.0:
				var real := (f - int(e[3])) / 60.0
				var err := absf(real - float(e[2]))
				worst = maxf(worst, err)
				if err > 0.06:
					check(false, "%s ability %d: listed %.1f s, real %.2f s" % [Characters.LIST[int(p.get_meta("legend"))]["name"], int(e[1]) + 1, float(e[2]), real])
				left.erase(e)
		if left.is_empty() or t > 60 * 30:
			check(left.is_empty(), "pair %s: all cooldowns ended" % str(pairs[pi]))
			if not _next():
				check(worst <= 0.06, "every kit legend: listed cooldown = real time (worst error %.3f s)" % worst)
				print("RESULT fails=", fails)
				return true
	return false
