extends SceneTree
# Недопонятый гений: флешки, Ethernet-кнут сбивает управление, пингвин-турель стреляет
# и взрывается, Перегазрука лечит (если не попали) или отбрасывает, Перестройка —
# зона со стойкой и взрыв дрона.
var main
var f := 0
var arena: ArenaMode
var p1: Player
var fails := 0
var hp0 := 0
var hp1 := 0
var t1: Player
var t2: Player
var k: GeniusKit

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
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/genius_%s.png" % n)

func _count(cls) -> int:
	return main.world.get_children().filter(func(n): return is_instance_of(n, cls)).size()

func _physics_process(_d: float) -> bool:
	f += 1
	var idx := Characters.LIST.map(func(c): return c.get("kit", "")).find("genius")
	if f == 5:
		check(idx >= 0 and Characters.LIST[idx].get("price", 0) > 0, "genius sold in the shop")
		main.sel = [idx, 0]
		main.start_arena(false, 21)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		k = p1.kit
		check(k is GeniusKit, "kit attached")
		check(p1.rig and p1.rig.spec.get("photo_face", "") == "genius", "photo face model")
	if arena == null:
		return false
	if f == 300:
		arena._queue.clear()
		for b in arena._alive:
			if is_instance_valid(b): b.queue_free()
		arena._alive.clear()
		p1.facing = 1
		t1 = arena.spawn_at("grunt", p1.global_position + Vector2(240, -20))
		t2 = arena.spawn_at("grunt", p1.global_position + Vector2(460, -20))
		for t in [t1, t2]:
			t.remove_meta("summoned")
			t.max_hp = 2000
			t.hp = 2000
			t.frozen = true
	if f < 600:
		p1.hp = p1.max_hp
	if f > 300 and is_instance_valid(t1):
		arena._queue.clear()                       # новые волны не мешают проверке
		for n in main.world.get_children():
			if n is Player and n.team != p1.team and n != t1 and n != t2 and n.is_alive():
				n.queue_free()
	if f == 330:
		p1._cooldown_left = 0.0
		k.weapon(1.0 / 60.0, true)
		var usb: int = main.world.get_children().filter(func(n): return n is Bullet and n.style == "usb").size()
		check(usb == 1, "throws a USB stick like a dagger")
	if f == 360:
		hp0 = t1.hp
		k.use("ether_whip")
		check(t1.glitch_t > 0.0 and t1.hp < hp0, "whip hurts and scrambles controls (%.1f s)" % t1.glitch_t)
		shot("whip")
	if f == 400:
		hp0 = t2.hp + t1.hp
		k.use("penguin_turret")
	if f == 470:
		check(_count(GeniusKit.PenguinTurret) == 1, "penguin turret landed")
		shot("turret")
	if f == 760:
		check(_count(GeniusKit.PenguinTurret) == 0 and t1.hp + t2.hp < hp0 - 40, "turret shot and exploded (%d)" % (hp0 - t1.hp - t2.hp))
	# Перегазрука: не попали — лечит
	if f == 780:
		p1.hp = p1.max_hp / 2
		hp1 = p1.hp
		k.use("overclock")
	if f == 800:
		shot("overclock")
	if f == 780 + 130:
		check(p1.hp >= hp1 + int(p1.max_hp * 0.2) - 1, "overclock heals when untouched (+%d)" % (p1.hp - hp1))
	# попали — не лечит, отбрасывает
	if f == 930:
		p1.hp = p1.max_hp / 2
		k.use("overclock")
	if f == 960:
		p1.take_damage(3, t1)
		hp1 = p1.hp
	if f == 930 + 125:
		check(p1.hp <= hp1 and k._oc_hit, "hit during overclock — no heal, shockwave instead")
	# Ульта
	if f == 1100:
		p1.hp = p1.max_hp
		t1.max_hp = 20000
		t1.hp = 20000
		hp0 = t1.hp
		k.ult()
		check(_count(GeniusKit.ServerRack) == 1, "server rack thrown")
	if f == 1190:
		check(t1._root_t > 0.5, "caught foe frozen in the zone")
		shot("rack")
	if f == 1100 + 60 * 8:
		check(_count(GeniusKit.ServerRack) == 0, "drone blows the rack up")
		check(is_instance_valid(t1) and t1.hp < hp0 - 200, "zone ticks + blast hurt (%d)" % (hp0 - t1.hp if is_instance_valid(t1) else -1))
		print("RESULT fails=", fails)
		return true
	return false
