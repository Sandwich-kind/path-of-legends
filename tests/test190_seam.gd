extends SceneTree
# Шов (легенда за Странника, поглощённого бездной): игла пришивает каждым 3-м попаданием,
# комбо «Лоскут прошлого» (до 5 в МЕГА, обрыв через секунду), нить, щупальца, ульта.
var main
var f := 0
var arena: ArenaMode
var p1: Player
var fails := 0
var hp0 := 0
var target: Player

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}                 # облики не должны влиять на проверку
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func shot(n: String) -> void:
	if OS.get_environment("SHOTS") == "1":
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/seam_%s.png" % n)

func _physics_process(_d: float) -> bool:
	f += 1
	var idx := Characters.LIST.map(func(c): return c.get("kit", "")).find("seam")
	if f == 5:
		check(idx >= 0 and Characters.LIST[idx]["unlock"] == "mad_wanderer", "seam hero unlocked by mad wanderer")
		main.sel = [idx, 0]
		main.start_arena(false, 21)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		check(p1.kit is SeamKit, "kit attached")
	if arena == null:
		return false
	p1.hp = p1.max_hp
	if f == 300:
		arena._queue.clear()
		for b in arena._alive:
			if is_instance_valid(b): b.queue_free()
		arena._alive.clear()
		p1.facing = 1
		target = arena.spawn_at("grunt", p1.global_position + Vector2(420, -20))
		target.remove_meta("summoned")
		target.max_hp = 50000
		target.hp = 50000
		target.frozen = true
	if f in [340, 350, 360]:
		p1._cooldown_left = 0.0
		p1.ammo = p1.clip_size
		p1.kit.weapon(0.016, true)
	if f == 400:
		check(p1.kit._hits == 3 and target._root_t > 0.0, "3rd needle pins the foe (hits %d)" % p1.kit._hits)
		shot("needle")
	# МЕГА-комбо: 5 нажатий
	if f == 420:
		hp0 = target.hp
		p1.kit._combo_i = 0
		p1.kit._combo_mega = true
		p1.kit._combo_next()
	if f in [440, 460, 480]:
		check(p1.kit._combo_step > 0, "combo continues (step %d)" % p1.kit._combo_step)
		p1.kit._combo_next()
		if f == 460:
			shot("combo3")
	if f == 500:
		p1.kit._combo_next()
	if f == 510:
		check(p1.kit._combo_step == 0 and p1._cd[0] > 0.0, "mega combo ends after 5 and goes on cooldown")
		shot("beam")
	if f == 560:
		check(target.hp < hp0 - 60, "combo strikes hurt (%d)" % (hp0 - target.hp))
	# обычное комбо обрывается через секунду
	if f == 600:
		p1._cd[0] = 0.0
		p1.kit._combo_i = 0
		p1.kit._combo_mega = false
		p1.kit._combo_next()
	if f == 690:
		check(p1.kit._combo_step == 0 and p1._cd[0] > 0.0, "combo drops after 1 s without a press")
	if f == 700:
		target._root_t = 0.0
		hp0 = target.hp
		p1.kit.use("seam_thread")
	if f == 760:
		check(target.hp < hp0, "thread cuts the foe (%d)" % (hp0 - target.hp))
		shot("thread")
	if f == 800:
		hp0 = target.hp
		p1.kit.use("abyss_tentacles")
	if f == 900:
		var n := 0
		for c in main.world.get_children():
			if c is SeamKit.Tentacle:
				n += 1
		check(n == 2, "two tentacles stand (%d)" % n)
		check(target.hp < hp0, "tentacles hit the area (%d)" % (hp0 - target.hp))
		shot("tentacles")
	if f == 960:
		hp0 = target.hp
		p1.ult_charge = p1.ult_need
		p1.kit.ult()
	if f == 1000:
		check(p1.kit.ulting(), "ult running")
	if f == 1100:
		shot("ult")
	if f == 960 + 330:
		check(target.hp < hp0 - 150, "ult chain hurts a lot (%d)" % (hp0 - target.hp))
		check(not p1.kit.ulting(), "ult ends")
		print("RESULT fails=", fails)
		return true
	return false
