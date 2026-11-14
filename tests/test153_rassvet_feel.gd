extends SceneTree
# Рассвет: удобство. Серия меча доходит до врага чуть дальше удара и не отбрасывает
# его из-под меча; Шаг тени выбирает врага впереди; Чёрное солнце летит к врагу;
# Затмение ходит за Рассветом, над врагом — знак тьмы, меч светится.
# Печатает OK/FAIL по каждому пункту. SHOTS=1 — снимки в /tmp/claude-0/rework/.
var main
var f := 0
var p1: Player
var p2: Player
var ok := 0
var fail := 0
var hp0 := 0
var x0 := 0.0
var shots := false
func _initialize() -> void:
	shots = OS.get_environment("SHOTS") != ""
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func check(name: String, cond: bool, info := "") -> void:
	if cond:
		ok += 1
	else:
		fail += 1
	print(("OK   " if cond else "FAIL ") + name + "  " + info)
func shot(n: String) -> void:
	if shots:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/rework/ras_%s.png" % n)
func place(dx: float) -> void:
	p1.global_position.x = 1000
	p2.global_position = Vector2(1000 + dx, p1.global_position.y)
	p1.facing = 1
	p2.facing = -1
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
func _physics_process(_d: float) -> bool:
	f += 1
	for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult", "p1_right", "p1_left", "p1_shoot"]:
		Input.action_release(a)
	if f == 3:
		main._on_duel_ready("test_buffs", 9, 99, [13, 2], {})
	if f == 30:
		p1 = main.duel_players[0]
		p2 = main.duel_players[1]
		p2.max_hp = 5000
		p2.hp = 5000
	if f < 230:
		return false
	var g := f - 200
	p1._protect = 2.0
	p2._protect = 0.0
	p2.frozen = true                       # соперник стоит (как человек, который не уворачивается)
	if g % 60 == 0: p1._cd = [0.0, 0.0, 0.0]
	# 1. серия меча по врагу чуть дальше удара (230 px между центрами)
	if g >= 40 and g <= 44: place(230)
	if g == 45: hp0 = p2.hp
	if g >= 46 and g < 136:
		Input.action_press("p1_shoot")
	if g == 70: shot("1_combo")
	if g == 136:
		var dealt := hp0 - p2.hp
		var gap := absf(p2.global_position.x - p1.global_position.x)
		# в Дуэли урон Рассвета идёт с поправкой Balance.DUEL — порог считаем с ней же
		var k: float = float(Balance.DUEL.get("rassvet", {}).get("dmg", 1.0))
		check("combo lands from 230 px", dealt >= int(3 * 14 * k), "dealt=%d gap=%d" % [dealt, int(gap)])
		check("combo keeps foe close", gap < 260.0, "gap=%d" % int(gap))
	# 2. шаг тени: враг впереди дальше, чем «приманка» сзади
	if g == 200:
		place(420)
		p1.facing = 1
		var d := Bots.create("dummy", 1, p1.global_position + Vector2(-200, 0), p1, 4500.0)
		d.team = 1
		d.set_meta("kind", "dummy")
		main.world.add_child(d)
		d.add_to_group("tmp_dummy")
	if g == 205:
		x0 = p1.global_position.x
		Input.action_press("p1_a1")
	if g == 209:
		shot("2_step")
		check("step picks foe in front", p1.global_position.x > 1300.0, "x %d -> %d (front foe at 1420)" % [int(x0), int(p1.global_position.x)])
	if g == 240:
		for n in root.get_tree().get_nodes_in_group("tmp_dummy"):
			n.queue_free()
	# 3. чёрное солнце по врагу в 600 px
	if g >= 300 and g <= 304: place(600)
	if g == 305:
		hp0 = p2.hp
		x0 = p2.global_position.x
		Input.action_press("p1_a3")
	if g == 335:
		shot("3_sun")
		var sun: Array = main.world.get_children().filter(func(n): return n is RassvetKit.BlackSun)
		var near: bool = sun.size() > 0 and absf(sun[0].global_position.x - x0) < 140.0
		check("sun lands at foe 600 px away", near, "sun_x=%s foe_x=%d" % [str(int(sun[0].global_position.x)) if sun.size() > 0 else "-", int(x0)])
	if g == 440:
		check("sun burst hit", hp0 - p2.hp >= 20, "dealt=%d" % (hp0 - p2.hp))
	# 4. затмение ходит за Рассветом
	if g >= 460 and g <= 464: place(160)
	if g == 465:
		Input.action_press("p1_a2")
	if g == 480:
		check("blade glows in eclipse", p1.rig.blade_fire.a > 0.0)
		check("blind mark over foe", p2.get_children().any(func(c): return c is Node2D and c.z_index == 8), "")
		shot("4_eclipse")
	if g >= 481 and g < 520:
		Input.action_press("p1_left")      # уходит влево на ~300 px
	if g == 540:
		var e: Node2D = p1.kit._eclipse
		var dist := e.global_position.distance_to(p1.global_position) if e else 9999.0
		check("eclipse follows", dist < 40.0, "dist=%d" % int(dist))
		shot("5_eclipse_moved")
	if g == 760:
		check("eclipse ended, glow off", p1.rig.blade_fire.a == 0.0 and p1.kit._marks.is_empty())
		print("RESULT ok=", ok, " fail=", fail)
		return true
	return false
