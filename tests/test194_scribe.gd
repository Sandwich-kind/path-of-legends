extends SceneTree
# Летописец: буквы дописывают слово ЛЕГЕНДА и ставят «Точку», Сноска помечает (больше
# урона), Черновик возвращает к копии и лечит, Абзац ловит снаряды и выпускает буквы,
# Последняя глава — строки по врагам и печать «КОНЕЦ».
var main
var f := 0
var arena: ArenaMode
var p1: Player
var fails := 0
var hp0 := 0
var hp1 := 0
var pos0 := Vector2.ZERO
var t1: Player
var t2: Player
var k: ScribeKit
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

func shot(n: String) -> void:
	if OS.get_environment("SHOTS") == "1":
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/scribe_%s.png" % n)

func _count(cls) -> int:
	return main.world.get_children().filter(func(n): return is_instance_of(n, cls)).size()

func _physics_process(_d: float) -> bool:
	f += 1
	var idx := Characters.LIST.map(func(c): return c.get("kit", "")).find("scribe")
	if f == 5:
		check(idx >= 0 and Characters.LIST[idx].get("price", 0) > 0, "scribe sold in the shop")
		check(Characters.display_order().find(idx) < Characters.display_order().find(Characters.LIST.map(func(c): return c["name"]).find("TESTIK_1")), "test legends still last")
		main.sel = [idx, 0]
		main.start_arena(false, 21)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		k = p1.kit
		check(k is ScribeKit, "kit attached")
		check(p1.rig and p1.rig.spec.get("hat", "") == "scribe_cap", "scribe model")
	if arena == null:
		return false
	if f == 300:
		arena._queue.clear()
		for b in arena._alive:
			if is_instance_valid(b): b.queue_free()
		arena._alive.clear()
		p1.facing = 1
		t1 = arena.spawn_at("grunt", p1.global_position + Vector2(240, -20))
		t2 = arena.spawn_at("grunt", p1.global_position + Vector2(330, -20))
		for t in [t1, t2]:
			t.remove_meta("summoned")
			t.max_hp = 3000
			t.hp = 3000
			t.frozen = true
	if f < 560 or (f > 700 and f < 1150):
		p1.hp = p1.max_hp
	if f > 300 and is_instance_valid(t1):
		arena._queue.clear()                       # новые волны не мешают проверке
		for n in main.world.get_children():
			if n is Player and n.team != p1.team and n != t1 and n != t2 and n.is_alive():
				n.queue_free()
	# оружие: 7 попаданий дописывают слово, восьмой выстрел — «Точка»
	if f >= 320 and f < 440 and f % 12 == 0:
		p1._cooldown_left = 0.0
		p1._reloading = 0.0
		p1.ammo = p1.clip_size
		if k._dot_ready:
			hp0 = t1.hp + t2.hp
		k.weapon(1.0 / 60.0, true)
	if f == 330:
		var ink: Array = main.world.get_children().filter(func(n): return n is Bullet and n.style == "ink")
		check(ink.size() == 1 and ink[0].glyph == "Л", "first letter shot is «Л»")
	if f == 425:
		check(k._dot_ready or k._letters == 0, "word ЛЕГЕНДА completed by hits (letters=%d, dot=%s)" % [k._letters, k._dot_ready])
		shot("word")
	if f == 470:
		check(not k._dot_ready and hp0 > 0 and t1.hp + t2.hp < hp0 - 30, "«Точка» hit hard and splashed (%d)" % (hp0 - t1.hp - t2.hp))
	# сноска: помеченный получает больше урона
	if f == 480:
		k.use("footnote")
	if f == 520:
		check(t1.mark_t > 0.0 and is_equal_approx(t1.mark_mult, 1.25), "footnote marks the nearest foe")
		hp0 = t1.hp
		t1.take_damage(100, p1)
		var dealt := hp0 - t1.hp
		hp0 = t2.hp
		t2.take_damage(100, p1)
		check(dealt > hp0 - t2.hp, "marked foe takes more damage (%d vs %d)" % [dealt, hp0 - t2.hp])
		shot("footnote")
	# черновик: отменить — вернуться и вернуть здоровье
	if f == 560:
		pos0 = p1.global_position
		hp1 = p1.hp
		k.handle_ability(1, "draft", "p1_a2", 0.0)
		k.use("draft")
		k._draft_i = 1
		check(k._draft != null, "draft placed")
	if f == 580:
		p1.global_position = pos0 + Vector2(-160, 0)
		p1.hp = hp1 - 60
	if f == 600:
		shot("draft")
		k._undo()
		check(p1.global_position.distance_to(pos0) < 4.0, "undo returns to the draft")
		check(p1.hp >= hp1 - 60 + 35, "undo gives back 60 pct of lost hp (+%d)" % (p1.hp - (hp1 - 60)))
		check(p1._cd[1] > 0.0, "cooldown starts after the draft")
	# абзац: ловит чужой снаряд, в конце буквы летят вперёд
	if f == 640:
		k.use("paragraph")
		check(_count(ScribeKit.Page) == 1, "page wall written")
	if f == 660:
		foe_b = Bullet.new()
		foe_b.team = t1.team
		foe_b.shooter = t1
		foe_b.direction = Vector2(-1, 0)
		foe_b.speed = 500.0
		foe_b.damage = 10
		foe_b.position = p1.global_position + Vector2(160, -40)
		main.world.add_child(foe_b)
	if f == 690:
		check(not is_instance_valid(foe_b), "page catches enemy shots")
		shot("page")
	if f == 640 + 60 * 5 + 8:
		var ink2: int = main.world.get_children().filter(func(n): return n is Bullet and n.style == "ink").size()
		check(ink2 >= 5, "page released its letters (%d)" % ink2)
	# ульта
	if f == 1000:
		t1.max_hp = 20000
		t1.hp = 20000
		hp0 = t1.hp + t2.hp
		k.ult()
		check(_count(ScribeKit.BigBook) == 1 and k.ulting(), "giant book opens")
	if f == 1100:
		shot("ult")
	if f == 1000 + 60 * 3 + 30:
		check(not k.ulting() and t1.hp + t2.hp < hp0 - 120, "lines + «КОНЕЦ» hurt (%d)" % (hp0 - t1.hp - t2.hp))
		print("RESULT fails=", fails)
		return true
	return false
