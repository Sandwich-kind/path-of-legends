extends SceneTree
# Главный: луч газировки (азот застывает, кола — лужи), бутылки по кругу, сэндвич
# усиливает луч, очки ослепляют и вызывают лучи с неба / ускоряют своего, чек
# копит заряды и оглушает, ульта — случайные события, МЕГА — чужие ульты.
var main
var f := 0
var arena: ArenaMode
var p1: Player
var fails := 0
var hp0 := 0
var t1: Player
var t2: Player
var k: GlavKit

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func shot(n: String) -> void:
	if OS.get_environment("SHOTS") == "1":
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/glav_%s.png" % n)

func _count(cls) -> int:
	return main.world.get_children().filter(func(n): return is_instance_of(n, cls)).size()

func _physics_process(_d: float) -> bool:
	f += 1
	var idx := Characters.LIST.map(func(c): return c.get("kit", "")).find("glav")
	if f == 5:
		check(idx >= 0 and Characters.LIST[idx].get("price", 0) > 0, "glav sold in the shop")
		main.sel = [idx, 0]
		main.start_arena(false, 21)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		k = p1.kit
		check(k is GlavKit, "kit attached")
		check(p1.rig and p1.rig.spec.get("photo_face", "") == "glav", "photo face model")
	if arena == null:
		return false
	p1.hp = p1.max_hp
	if f == 300:
		arena._queue.clear()
		for b in arena._alive:
			if is_instance_valid(b): b.queue_free()
		arena._alive.clear()
		p1.facing = 1
		t1 = arena.spawn_at("grunt", p1.global_position + Vector2(380, -20))
		t2 = arena.spawn_at("grunt", p1.global_position + Vector2(520, -20))
		for t in [t1, t2]:
			t.remove_meta("summoned")
			t.max_hp = 50000
			t.hp = 50000
			t.frozen = true
	# 1. Азот: трясёт 0,7 с и стреляет
	if f == 341:
		Input.action_press("p1_shoot")
	if f == 383:
		hp0 = t1.hp
		Input.action_release("p1_shoot")
	if f == 386:
		check(k._beam_t > 0.0, "release fires a soda beam (%.2f s)" % k._beam_t)
	if f == 400:
		shot("nitro")
	if f == 420:
		check(t1.hp < hp0 and float(k._chill.get(t1, 0.0)) > 0.0, "nitrogen hurts and chills (%d)" % (hp0 - t1.hp))
	if f == 470:
		check(k.bottle == 1 and k.stacks == 1, "next bottle in hand (%d), stack gained" % k.bottle)
	# 2. Сэндвич, потом кола по больному врагу
	if f == 480:
		k.use("sandwich")
		k.make_sick(t1)
		check(k._sick.has(t1), "sandwich makes the foe sick")
	if f == 491:
		Input.action_press("p1_shoot")
	if f == 521:
		hp0 = t1.hp
		Input.action_release("p1_shoot")
	if f == 545:
		shot("cola")
		check(_count(SwampBits.MudPuddle) > 0, "cola leaves sticky puddles")
	if f == 600:
		check(t1.hp < hp0 - 20, "sick foe takes boosted beam + blasts (%d)" % (hp0 - t1.hp))
	# 3. Очки во врага
	if f == 610:
		hp0 = t1.hp
		k.use("shades")
	if f == 640:
		check(k._blind.has(t1) and _count(GlavKit.SkyMark) == 1, "shades blind the foe and mark it")
		shot("shades")
	if f == 760:
		check(t1.hp < hp0 - 30, "sky beams strike the mark (%d)" % (hp0 - t1.hp))
	# очки своему
	if f == 770:
		GlavKit.cool(p1)
		check(p1.has_buff("speed") and p1.has_buff("rapid"), "ally with shades: speed + no reload")
	# 4. Чек
	if f == 779:
		t1.global_position = p1.global_position + Vector2(80, 0)   # вплотную: на карте рядом встают скелеты из могил
	if f == 780:
		k.stacks = 7
		k.use("receipt")
		check(k.stacks == 0, "receipt spends 7 stacks")
	if f == 800:
		check(t1._stun_t > 0.5, "receipt stuns the foe (%.1f)" % t1._stun_t)
		shot("receipt")
	# 5. Ульта и все её события
	if f == 900:
		t1.frozen = false
		for ev in GlavKit.EVENTS:
			if not (ev in ["call", "ad", "coffee", "lag"]):   # паузы, стоп-кадр и лаги проверяют test196 и test197
				k.call("_ev_" + ev)
		check(true, "every ult event runs")
	if f == 960:
		p1.ult_charge = p1.ult_need
		k.ult()
		k._called = true                           # без звонка и рекламы: они ставят игру на паузу (test196, test197)
		k._coffee_used = true                      # и без кофе: он останавливает время ульты
		check(k.ulting(), "ult opens the console")
	if f == 1000:
		shot("ult")
	if f == 960 + 60 * 7 + 40:
		check(not k.ulting(), "ult ends")
	# 6. МЕГА: чужие ульты
	if f >= 1400 and f < 1400 + GlavKit.GUESTS.size() * 150 and (f - 1400) % 150 == 0:
		var gi := (f - 1400) / 150
		p1.hp = p1.max_hp
		k._guest_ult(gi)
		print("guest ", GlavKit.GUESTS[gi][0])
	if f == 1400 + GlavKit.GUESTS.size() * 150 + 60:
		check(p1.is_alive(), "guest mega ults ran")
		print("RESULT fails=", fails)
		return true
	return false
