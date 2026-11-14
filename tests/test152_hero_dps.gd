extends SceneTree
# Сколько урона наносит легенда на Арене (баланс Арены): по одной цели-боссу
# (с пошатыванием) и по толпе из 6 манекенов. Герой стоит на месте лицом к целям,
# жмёт оружие и способности, как только они готовы, ульту — когда накопится.
# HERO — номер легенды, PAT — как жать оружие: tap, mid, hold (по умолчанию — все три).
# Печатает: урон за 15 с по боссу и по толпе для каждого способа, лучший — в строке BEST.
var main
var arena
var p: Player
var f := 0
var hero := 13
var pats := ["tap", "mid", "hold"]
var scen := []                 # [сценарий, способ]
var si := -1
var t0 := 0
var dummies: Array = []
var total := 0
var res := {}
var abil := "1111"             # ABIL: какие кнопки жать (a1 a2 a3 ult), например 0000 — только оружие
const DUR := 900               # 15 с

func _initialize() -> void:
	if OS.get_environment("HERO") != "":
		hero = int(OS.get_environment("HERO"))
	if OS.get_environment("ABIL") != "":
		abil = OS.get_environment("ABIL")
	if OS.get_environment("PAT") != "":
		pats = [OS.get_environment("PAT")]
	var sc_list := ["boss", "crowd"]
	if OS.get_environment("SCEN") != "":
		sc_list = Array(OS.get_environment("SCEN").split(","))
	for s in sc_list:
		for pt in pats:
			scen.append([s, pt])
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _clear() -> void:
	for d in dummies:
		if is_instance_valid(d):
			d.queue_free()
	dummies.clear()
	for b in arena._alive:
		if is_instance_valid(b):
			b.queue_free()
	arena._alive.clear()

func _start(i: int) -> void:
	_clear()
	si = i
	t0 = f
	total = 0
	var floor_y: float = arena.info["floor"]
	var x0 := 900.0
	p.global_position = Vector2(x0, floor_y - p.body_size.y / 2 - 2)
	p.velocity = Vector2.ZERO
	p.facing = 1
	p._cd = [0.0, 0.0, 0.0]
	p.ult_charge = 0.0
	p.hp = p.max_hp
	if p.kit and p.kit.has_method("on_death"):
		pass
	var kind: String = scen[i][0]
	var n := 1 if kind == "boss" else 6
	for k in n:
		var pos := Vector2(x0 + 230.0 + k * 90.0, floor_y - 32.0)
		var walker := kind == "walkers"
		var b: Player = arena._make_bot("bandit_thug" if walker else "dummy", pos)
		b.max_hp = 200000
		b.hp = b.max_hp
		if not walker:
			b.speed = 0.0
			b.jump_force = 0.0
		if kind == "boss":
			b.stagger_max = 2600.0 * Balance.STAGGER_SHARE      # как у босса средней Арены
		b.on_hurt = func(a, _who): total += a
		dummies.append(b)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [hero, 0]
		main.start_arena(false, 1)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
		return false
	if arena == null:
		return false
	if si < 0:
		if f > 330:
			arena._state = "intro"          # волны не идут
			arena._queue.clear()
			p = arena.players[0]
			p.frozen = false
			_start(0)
		return false
	var k := f - t0
	for a in ["p1_shoot", "p1_a1", "p1_a2", "p1_a3", "p1_ult", "p1_left", "p1_right", "p1_jump"]:
		Input.action_release(a)
	p._protect = 1.0
	p.hp = p.max_hp
	# лицом к целям
	var tx: float = dummies[0].global_position.x if not dummies.is_empty() and is_instance_valid(dummies[0]) else p.global_position.x + 100
	p.facing = 1 if tx >= p.global_position.x else -1
	var pat: String = scen[si][1]
	var on := false
	match pat:
		"tap": on = k % 6 < 2
		"mid": on = k % 14 < 12
		"hold": on = k % 42 < 40
	if on:
		Input.action_press("p1_shoot")
	if k % 20 == 5 and abil[0] == "1": Input.action_press("p1_a1")
	if k % 20 == 11 and abil[1] == "1": Input.action_press("p1_a2")
	if k % 20 == 17 and abil[2] == "1": Input.action_press("p1_a3")
	if k % 30 == 8 and abil[3] == "1" and p.ult_charge >= p.ult_need: Input.action_press("p1_ult")
	# кто улетел/убежал — возвращаем к целям (в шаге от первой)
	if absf(p.global_position.x - tx) > 520.0:
		p.global_position.x = tx - 200.0
	if k >= DUR:
		var key: String = scen[si][0]
		print("hero=", Characters.LIST[hero]["name"], " ", key, " ", pat, " dmg=", total, " dps=", snappedf(total / 15.0, 0.1))
		res[key] = maxi(res.get(key, 0), total)
		print("    ", key, " hits left on targets: ", dummies.map(func(d): return int(d.global_position.x)))
		if si + 1 < scen.size():
			_start(si + 1)
		else:
			print("BEST ", Characters.LIST[hero]["name"], " ", res)
			return true
	return false
