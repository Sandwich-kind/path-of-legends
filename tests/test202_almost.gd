extends SceneTree
# Почти легенда: кулаки (удар вблизи и заряженная волна сквозь всех), Рельмотрон (мгновенный
# луч насквозь), ледяная область (замедляет, морозит), метеориты всех видов, ульта — Титан:
# кулаки, ракеты, лазеры, топот и взрыв шара на всю карту.
var main
var f := 0
var arena: ArenaMode
var p1: Player
var fails := 0
var hp0 := 0
var hp1 := 0
var t1: Player
var t2: Player
var k: AlmostKit
var slowed := false

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
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/almost_%s.png" % n)

func _count(cls) -> int:
	return main.world.get_children().filter(func(n): return is_instance_of(n, cls)).size()

func _physics_process(_d: float) -> bool:
	f += 1
	var idx := Characters.LIST.map(func(c): return c.get("kit", "")).find("almost")
	if f == 5:
		check(idx >= 0 and Characters.LIST[idx].get("price", 0) > 0, "Almost Legend sold in the shop")
		check(Characters.display_order().find(idx) < Characters.display_order().find(Characters.LIST.map(func(c): return c["name"]).find("TESTIK_1")), "test legends still last")
		main.sel = [idx, 0]
		main.start_arena(false, 21)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		k = p1.kit
		check(k is AlmostKit, "kit attached")
		check(p1.rig and p1.rig.spec.get("hat", "") == "moto_helm" and p1.rig.spec.get("weapon", "") == "gauntlet", "own model: helmet and power gloves")
	if arena == null:
		return false
	if f == 300:
		arena._queue.clear()
		for b in arena._alive:
			if is_instance_valid(b): b.queue_free()
		arena._alive.clear()
		p1.facing = 1
		t1 = arena.spawn_at("grunt", p1.global_position + Vector2(70, -20))
		t2 = arena.spawn_at("grunt", p1.global_position + Vector2(330, -20))
		for t in [t1, t2]:
			t.remove_meta("summoned")
			t.max_hp = 20000
			t.hp = 20000
			t.frozen = true
	if f > 300:
		p1.hp = p1.max_hp
		if is_instance_valid(t1):
			arena._queue.clear()
			for n in main.world.get_children():
				if n is Player and n.team != p1.team and n != t1 and n != t2 and n.is_alive():
					n.queue_free()
	# ----- кулаки: короткое нажатие — удар вблизи
	if f == 320:
		t1.global_position = p1.global_position + Vector2(70, 0)
		t2.global_position = p1.global_position + Vector2(330, 0)
		hp0 = t1.hp
		hp1 = t2.hp
		p1._cooldown_left = 0.0
		Input.action_press("p1_shoot")
	if f == 322:
		Input.action_release("p1_shoot")
	if f == 325:
		check(t1.hp < hp0 and t2.hp == hp1, "tap: a close punch hits only the foe in reach")
	# ----- зажал на секунду — ударная волна через обоих
	if f == 340:
		hp0 = t1.hp
		hp1 = t2.hp
		p1._cooldown_left = 0.0
	if f == 341:
		Input.action_press("p1_shoot")              # зажал «огонь» на секунду
	if f == 400:
		Input.action_release("p1_shoot")
	if f == 430:
		check(t1.hp < hp0 and t2.hp < hp1, "charged punch: shockwave hits everyone on its way (-%d, -%d)" % [hp0 - t1.hp, hp1 - t2.hp])
		shot("punch")
	# ----- Рельмотрон
	if f == 460:
		t1.global_position = p1.global_position + Vector2(250, 0)
		t2.global_position = p1.global_position + Vector2(700, 0)
		hp0 = t1.hp
		hp1 = t2.hp
		k.use("railmotron")
	if f == 462:
		shot("rail_aim")
	if f == 482:
		shot("rail")
	if f == 490:
		check(t1.hp <= hp0 - 50 and t2.hp <= hp1 - 50, "railmotron: one instant beam pierces both (-%d, -%d)" % [hp0 - t1.hp, hp1 - t2.hp])
	# ----- ледяная область
	if f == 520:
		for t in [t1, t2]:
			t.frozen = false
		t1.global_position = p1.global_position + Vector2(110, 0)
		hp0 = t1.hp
		k.use("ice_farewell")
		check(_count(AlmostKit.IceZone) == 1, "ice zone appears around him")
	if f > 520 and f < 600:
		t1.global_position = p1.global_position + Vector2(110.0, 0)
		t1.velocity = Vector2.ZERO
		if t1._slow_t > 0.0:
			slowed = true
	if f == 580:
		check(slowed and t1.hp < hp0, "ice zone slows and freezes foes (-%d)" % (hp0 - t1.hp))
		shot("ice")
	# ----- метеориты: все виды
	if f == 640:
		for t in [t1, t2]:
			t.frozen = true
		t1.global_position = p1.global_position + Vector2(300, 0)
		t2.global_position = p1.global_position + Vector2(420, 0)
		var at := t1.global_position + Vector2(0, t1.body_size.y / 2)
		hp0 = t1.hp
		k.meteor_hit("stone", at, 110.0)
		check(t1.hp < hp0, "stone meteor hits")
		k.meteor_hit("fire", at, 110.0)
		check(t1._burn_t > 0.0, "fire meteor burns")
		k.meteor_hit("ice", at, 110.0)
		check(t1._slow_t > 0.0, "ice meteor slows")
		hp1 = t2.hp
		k.meteor_hit("storm", at, 110.0)
		check(t2.hp < hp1, "storm meteor chains lightning to the neighbour")
		k.meteor_hit("glitch", at, 110.0)
		check(t1.glitch_t > 1.0, "glitched meteor scrambles controls")
		k.meteor_hit("grass", at, 110.0)
		check(_count(AlmostKit.GrassZone) == 1, "grass meteor leaves healing grass")
		k.meteor_hit("banana", at, 110.0)
		check(_count(AlmostKit.Choco) >= 6 and _count(AlmostKit.ChocoPuddle) == 1, "banana meteor: chocolate chunks and a puddle")
		var kinds := {}
		for i in 400:
			kinds[AlmostKit.roll_meteor()] = true
		check(kinds.size() == 7, "all 7 kinds can drop (%d)" % kinds.size())
	if f == 700:
		p1.global_position = t1.global_position + Vector2(40, 0)
		p1.hp = 30
		hp0 = p1.hp
	if f == 760:
		check(p1.hp > hp0, "grass heals allies (+%d)" % (p1.hp - hp0))
		p1.global_position = t1.global_position + Vector2(-300, 0)
	if f == 800:
		k.use("meteor_strike")
		check(_count(AlmostKit.Meteor) == 1, "meteor flies at the nearest foe")
	if f == 830:
		shot("meteor")
	# ----- ульта: Титан
	if f == 900:
		t1.global_position = p1.global_position + Vector2(300, 0)
		t2.global_position = p1.global_position + Vector2(-350, 0)
		hp0 = t1.hp + t2.hp
		k.ult()
		check(k.ulting() and _count(TitanRobot) == 1, "Titan rises behind the arena")
	for sh in [[60, "titan_rise"], [190, "titan_cock"], [205, "titan_strike"], [222, "titan_hit"], [380, "titan_rockets"], [480, "titan_lasers"], [590, "titan_stomp"], [740, "titan_core"], [800, "titan_blast"]]:
		if f == 900 + int(sh[0]):
			shot(String(sh[1]))
	if f == 900 + 60 * 10:
		check(t1.hp + t2.hp < hp0 - 100, "fists, rockets and lasers hurt (-%d)" % (hp0 - t1.hp - t2.hp))
		hp0 = t1.hp + t2.hp
	if f == 900 + 60 * 16:
		check(t1.hp < 20000 and t2.hp < 20000 and t1.hp + t2.hp < hp0, "energy orb blast hits the whole map (-%d)" % (hp0 - t1.hp - t2.hp))
		check(not k.ulting(), "Titan leaves after the blast")
		print("RESULT fails=", fails)
		return true
	return false
