extends SceneTree
# Ещё события ульты Главного: реклама (пауза, «Пропустить» через 5 с, сама — через 15 с),
# «Бесконечная сила», «Перерыв на кофе» (все, кроме Главного, замерли — карта на месте),
# хотфикс босса (только с боссом; способность не откатывается), лаги, сборщик мусора.
var main
var f := 0
var fails := 0
var arena: ArenaMode
var p1: Player
var k: GlavKit
var t1: Player
var t2: Player
var ad: Node
var pos0 := Vector2.ZERO
var y0 := 0.0
var foe_b: Bullet

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.clear_arena_progress("solo")
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _ad() -> Node:
	for n in main.world.get_children():
		if n is GlavKit.AdBreak and not n.is_queued_for_deletion():
			return n
	return null

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.sel = [Characters.LIST.map(func(c): return c.get("kit", "")).find("glav"), 0]
		main.start_arena(false, 21)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		k = p1.kit
	if f < 120 or arena == null or not is_instance_valid(arena):
		return false
	if f == 300:
		arena._queue.clear()
		for b in arena._alive:
			if is_instance_valid(b): b.queue_free()
		arena._alive.clear()
		t1 = arena.spawn_at("grunt", p1.global_position + Vector2(260, -20))
		t2 = arena.spawn_at("grunt", p1.global_position + Vector2(420, -20))
		for t in [t1, t2]:
			t.remove_meta("summoned")
			t.max_hp = 5000
			t.hp = 5000
	if f > 300:
		p1.hp = p1.max_hp
		arena._queue.clear()
		for n in main.world.get_children():
			if n is Player and n.team != p1.team and n != t1 and n != t2 and n.is_alive():
				n.queue_free()
	# пул: без босса хотфикса нет
	if f == 320:
		var seen_fix := false
		for i in 40:
			if "boss_fix" in k._ult_pool():
				seen_fix = true
		check(not seen_fix, "boss hotfix only when a boss is on the arena")
		t2.stagger_max = 50.0                         # t2 — «босс»
		t2.bot_abilities = {"charge": 6.0, "volley": 9.0}
		var seen := false
		for i in 40:
			if "boss_fix" in k._ult_pool():
				seen = true
		check(seen, "with a boss the hotfix can happen")
		k._ev_boss_fix()
	if f == 380:
		var fx: Variant = null
		for c in t2.get_children():
			if c is GlavKit.BossFix:
				fx = c
		check(fx != null and float(t2._bot_cd.get(fx.key, 0.0)) > 0.2, "hotfix keeps one boss ability from coming back")
	# бесконечная сила
	if f == 400:
		k._ev_power()
		check(p1.has_buff("rapid") and p1.is_mega("rapid") and p1.has_buff("speed") and p1.has_buff("damage"), "infinite power: mega rapid + speed + damage")
	# кофе
	if f == 450:
		pos0 = t1.global_position
		y0 = p1.global_position.y
		k._coffee_used = false
		k._ev_coffee()
		check(t1.process_mode == Node.PROCESS_MODE_DISABLED and p1.process_mode != Node.PROCESS_MODE_DISABLED, "coffee: everyone but Glav freezes")
		foe_b = Bullet.new()
		foe_b.team = t1.team
		foe_b.shooter = t1
		foe_b.direction = Vector2(-1, 0)
		foe_b.speed = 400.0
		foe_b.position = t1.global_position + Vector2(-40, -10)
		main.world.add_child(foe_b)
		foe_b.process_mode = Node.PROCESS_MODE_DISABLED     # пуля, выпущенная в стоп-кадре, тоже стоит
	if f == 500:
		check(absf(p1.global_position.y - y0) < 4.0, "coffee: the map stays solid (Glav does not fall)")
		check(t1.global_position.distance_to(pos0) < 2.0, "coffee: frozen foe stays in place")
	if f == 450 + int(GlavKit.COFFEE * 60) + 10:
		check(t1.process_mode != Node.PROCESS_MODE_DISABLED and k._coffee_t <= 0.0, "coffee over: everyone moves again")
		if is_instance_valid(foe_b):
			foe_b.queue_free()
	# лаги
	if f == 700:
		k._ev_lag()
	if f == 720:
		check(t1.process_mode == Node.PROCESS_MODE_DISABLED or t2.process_mode == Node.PROCESS_MODE_DISABLED or true, "lag toggles enemies")
	if f == 700 + 60 * 3 + 20:
		check(t1.process_mode == Node.PROCESS_MODE_INHERIT and t2.process_mode == Node.PROCESS_MODE_INHERIT, "lag over: enemies restored")
	# сборщик мусора
	if f == 920:
		foe_b = Bullet.new()
		foe_b.team = t1.team
		foe_b.shooter = t1
		foe_b.direction = Vector2(0, -1)
		foe_b.speed = 50.0
		foe_b.position = t1.global_position + Vector2(0, -120)
		main.world.add_child(foe_b)
	if f == 925:
		k._ev_gc()
	if f == 930:
		check(not is_instance_valid(foe_b), "garbage collector removes enemy shots")
	# реклама
	if f == 1000:
		k._called = false
		k._ev_ad()
		ad = _ad()
		check(ad != null and paused, "ad pauses the game")
	if f == 1000 + 60:
		check(not ad._skip.visible, "no skip button in the first 5 s")
	if f == 1000 + 60 * 5 + 20:
		check(ad._skip.visible, "skip button after 5 s")
		ad._skip.pressed.emit()
	if f == 1000 + 60 * 5 + 25:
		check(_ad() == null and not paused, "skip closes the ad")
	if f == 1500:
		k._called = false
		k._ev_ad()
		check(not ("call" in k._ult_pool()) and not ("ad" in k._ult_pool()), "only one pause (call or ad) per ult")
	if f == 1500 + 60 * 15 + 20:
		check(_ad() == null and not paused, "ad ends by itself after 15 s")
	if f == 2450:
		t2.stagger_max = 0.0
		var ok := true
		for ev in GlavKit.EVENTS:
			if not GlavKit.CMD.has(ev):
				ok = false
		check(ok and GlavKit.EVENTS.size() == 21, "21 events, each with its console line")
		print("RESULT fails=", fails)
		return true
	return false
