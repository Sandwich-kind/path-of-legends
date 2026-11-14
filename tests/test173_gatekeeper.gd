extends SceneTree
# Легенда ПРИВРАТНИЦА: посох-ключ (замок каждое 4-е попадание), Парные врата, Цепь-замок,
# Схлопывание, ульта Запечатывание — в Дуэли, потом Цепь-замок на Арене (общий урон).
var main
var f := 0
var shots := "/tmp/claude-0/gk/"
var p1: Player
var p2: Player
var gi := -1
var hp0 := 0
var fails := 0
var arena: ArenaMode
var bots: Array = []

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	DirAccess.make_dir_recursive_absolute(shots)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		if img: img.save_png(shots + "gk_%s.png" % n)

func place(dx: float) -> void:
	p1.global_position.x = 1200
	p2.global_position = Vector2(1200 + dx, p1.global_position.y)
	p1.facing = 1
	p2.facing = -1
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO

func find(cls) -> Node:
	for n in main.world.get_children():
		if is_instance_of(n, cls):
			return n
	return null

func _physics_process(_d: float) -> bool:
	f += 1
	for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult", "p1_shoot"]:
		Input.action_release(a)
	if f == 3:
		for i in Characters.LIST.size():
			if Characters.LIST[i]["name"] == "ПРИВРАТНИЦА":
				gi = i
		print("gatekeeper index=", gi, " order tail=", Characters.display_order().slice(-4))
		main._on_duel_ready("test_buffs", 9, 99, [gi, 2], {})
	if f == 30:
		p1 = main.duel_players[0]
		p2 = main.duel_players[1]
		check(p1.kit is GatekeeperKit, "kit is GatekeeperKit, abilities=%s" % str(p1.abilities))
		p2.max_hp = 3000
		p2.hp = 3000
	if f < 240:
		return false
	var g := f - 240
	if g < 640:
		p2._protect = 0.0
		p1._protect = 2.0
	if g % 90 == 0 and is_instance_valid(p1):
		p1._cd = [0.0, 0.0, 0.0]
	# 1. посох: 6 выстрелов — после 4-го враг «заперт»
	if g >= 1 and g <= 5:
		place(420)
	if g == 6:
		hp0 = p2.hp
	if g > 6 and g < 200 and g % 12 < 2:
		Input.action_press("p1_shoot")
	if g == 40:
		shot("1_staff")
	if g == 60:
		var nb := 0
		for n in main.world.get_children():
			if n is Bullet:
				nb += 1
		print("dbg ammo=%d cd=%.2f rel=%.2f frozen=%s bullets=%d" % [p1.ammo, p1._cooldown_left, p1._reloading, str(p1.frozen), nb])
	if g > 6 and g < 200 and p1.kit._hits >= 4 and not has_meta("locked_seen"):
		set_meta("locked_seen", p2._slow_t > 0.0 or find(GatekeeperKit.LockIcon) != null)
	if g == 200:
		check(p2.hp < hp0, "staff hits: %d -> %d (%d hits)" % [hp0, p2.hp, p1.kit._hits])
		check(get_meta("locked_seen", false), "4th hit locks the target")
	# 2. врата: враг входит в первые и выходит из вторых
	if g >= 140 and g <= 145:
		place(900)
	if g == 146:
		Input.action_press("p1_a1")
	if g == 150:
		var gp: GatekeeperKit.GatePair = find(GatekeeperKit.GatePair)
		check(gp != null, "gates opened a=%s b=%s" % [str(gp.a) if gp else "-", str(gp.b) if gp else "-"])
		if gp:
			p2.global_position = gp.a + Vector2(5, 0)
			p2.velocity = Vector2(-50, 0)
	if g == 156:
		var gp2: GatekeeperKit.GatePair = find(GatekeeperKit.GatePair)
		if gp2:
			check(p2.global_position.distance_to(gp2.b) < 120.0, "enemy passed through the gates to %s" % str(p2.global_position))
			shot("2_gates")
			# снаряд сквозь врата
			var b := Bullet.new()
			b.shooter = p1
			b.team = p1.team
			b.direction = Vector2.RIGHT
			b.speed = 600.0
			b.damage = 1
			b.position = gp2.a + Vector2(-50, 0)
			main.world.add_child(b)
			b.set_meta("probe", true)
	if g == 175:
		var gp3: GatekeeperKit.GatePair = find(GatekeeperKit.GatePair)
		var probe: Node2D = null
		for n in main.world.get_children():
			if n is Bullet and n.has_meta("probe"):
				probe = n
		if gp3:
			check(probe != null and probe.global_position.x > gp3.b.x, "bullet passed through the gates")
	# 3. Схлопывание
	if g >= 300 and g <= 305:
		place(380)
	if g == 306:
		hp0 = p2.hp
		Input.action_press("p1_a3")
	if g == 340:
		shot("3_collapse")
	if g == 400:
		check(p2.hp < hp0, "collapse damages: %d -> %d" % [hp0, p2.hp])
	# 4. ульта: запечатывание
	if g >= 440 and g <= 445:
		place(260)
	if g == 446:
		p1.ult_charge = 9999
		Input.action_press("p1_ult")
	if g == 452:
		check(p2._stun_t > 0.0, "seal freezes the enemy (stun %.1f)" % p2._stun_t)
		hp0 = p2.hp
		shot("4_seal")
	if g > 452 and g < 560 and g % 16 < 2:
		Input.action_press("p1_shoot")
	if g == 470:
		var h1 := p2.hp
		p2.take_damage(10, p1)
		print("dbg direct dmg during seal: %d -> %d  invuln=%.2f prot=%.2f inv=%s shield=%s alive=%s" % [h1, p2.hp, p2._invuln, p2._protect, str(p2.invulnerable), str(p2.cutscene_shield), str(p2.is_alive())])
	if g == 480:
		var nb2 := 0
		for n in main.world.get_children():
			if n is Bullet:
				nb2 += 1
		for n in main.world.get_children():
			if n is Bullet:
				print("dbg bullet pos=%s dir=%s p2 top=%.0f bottom=%.0f" % [str(n.global_position), str(n.direction), p2.global_position.y - p2.body_size.y / 2, p2.global_position.y + p2.body_size.y / 2])
		print("dbg seal: ammo=%d cd=%.2f rel=%.2f p1=%s p2=%s bullets=%d facing=%d anim_frozen=%s" % [p1.ammo, p1._cooldown_left, p1._reloading, str(p1.global_position), str(p2.global_position), nb2, p1.facing, str(p1.frozen)])
	if g == 600:
		check(p2.hp < hp0, "seal echo: %d -> %d" % [hp0, p2.hp])
	# 4б. Цепь-замок в Дуэли (враг один): приковывает к земле
	if g >= 602 and g <= 607:
		place(400)
	if g == 608:
		p1._cd = [0.0, 0.0, 0.0]
		Input.action_press("p1_a2")
	if g == 614:
		check(p2._root_t > 0.5 and find(GatekeeperKit.AnchorChain) != null, "single enemy is anchored (root %.1f)" % p2._root_t)
		shot("4b_anchor")
	# 5. Арена: Цепь-замок делит урон между двумя врагами
	if g == 640:
		main.sel = [gi, 0]
		main.start_arena(false, 41)
	if g == 760:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		p1.frozen = false
		p1._protect = 99.0
		for b2 in arena._alive:
			if is_instance_valid(b2):
				b2.queue_free()
		arena._queue.clear()
		bots = [arena.spawn_at("fighter", p1.global_position + Vector2(240, -20)), arena.spawn_at("fighter", p1.global_position + Vector2(380, -20))]
		for b3 in bots:
			b3.max_hp = 2000
			b3.hp = 2000
			b3.frozen = true
	if g == 790 and is_instance_valid(p1):
		p1._cd = [0.0, 0.0, 0.0]
		Input.action_press("p1_a2")
	if g == 800:
		var ch: GatekeeperKit.LockChain = find(GatekeeperKit.LockChain)
		check(ch != null and ch.links.size() == 2, "chain links two enemies")
		bots[0].take_damage(200)
	if g == 806:
		print("chain: bot0=%d bot1=%d" % [bots[0].hp, bots[1].hp])
		check(bots[1].hp <= 2000 - 80, "linked enemy shares the damage (%d)" % bots[1].hp)
		shot("5_chain")
		print("RESULT fails=", fails)
		quit()
	return false
