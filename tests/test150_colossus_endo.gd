extends SceneTree
# Колосс: вторая фаза — броня раскалывается, остаётся железный остов с ядром в груди.
# Кадры: первая фаза, трещины, взрыв брони, подъём остова, вторая фаза, атаки,
# раскрытое ядро (урон спереди ×1,5), гибель.
var main
var f := 0
var arena
var boss: Player
var p: Player
var t0 := -1
var shots := "/tmp/claude-0/rework/"
var order := ["fire_dash", "meteor_leap", "lava_volley", "core_nova", "shockwave"]
var tag := ""
var dead_at := -1

func _initialize() -> void:
	tag = OS.get_environment("TAG")
	if OS.get_environment("SKIP_ABIL") != "":
		order = []
	Save.load_game()
	Save.unlock_all_heroes()
	Save.unlock_all_stages()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		if img: img.save_png(shots + tag + "c_" + n + ".png")

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [int(OS.get_environment("HERO")) if OS.get_environment("HERO") != "" else 0, 0]
		main.start_arena(false, 50)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if arena == null:
		return false
	if t0 < 0:
		if arena._boss and is_instance_valid(arena._boss) and not arena._boss.frozen and not arena._boss.cutscene_shield:
			boss = arena._boss
			p = arena.players[0]
			t0 = f
			print("phase1: hp=", boss.hp, "/", boss.max_hp)
		return false
	var k := f - t0
	if is_instance_valid(p):
		p._protect = 1.0
		p.hp = p.max_hp
	if k == 20: shot("0_phase1")
	if k == 40:
		boss.hp = boss.max_hp / 4
	if k == 60: shot("0b_overheat")
	if k == 70:
		boss.take_damage(9999999, p)
		print("lethal: alive=", boss.is_alive(), " shield=", boss.cutscene_shield)
	for fr in [90, 130, 165, 185, 200, 215, 230, 245, 262, 280, 300, 330]:
		if k == fr: shot("1_t%03d" % fr)
	if k == 470:
		shot("2_phase2")
		print("phase2: hp=", boss.hp, "/", boss.max_hp, " title=", boss.get_meta("title", ""), " rig=", boss.rig.kind if boss.rig else "", " frozen=", boss.frozen, " shield=", boss.cutscene_shield)
	if dead_at > 0:
		var m3 := k - dead_at
		for fr2 in [4, 20, 40, 60, 80, 110, 140, 180, 240]:
			if m3 == fr2: shot("5_death_%03d" % fr2)
		if m3 == 300:
			print("end: state=", arena._state, " sky=", main.world.get_children().filter(func(n): return n is InfernoSky).size())
			return true
		return false
	if k >= 500 and is_instance_valid(boss) and boss.is_alive():
		var slot := (k - 500) / 300
		if slot < order.size():
			var ab: String = order[slot]
			for a in boss._bot_cd.keys():
				boss._bot_cd[a] = 999.0
			if (k - 500) % 300 == 0:
				boss._bot_cd[ab] = 0.0
				boss.hp = boss.max_hp
				boss._stun_t = 0.0
				p.global_position = Vector2(boss.global_position.x + (420.0 if boss.global_position.x < 1300 else -420.0), p.global_position.y)
				print("try ", ab)
			var m := (k - 500) % 300
			if m == 30 or m == 70 or m == 120 or m == 170:
				shot("3_%s_%d" % [ab, m])
			if m == 299:
				var br = boss.get_node("RaidBrain")
				print("   ", ab, ": core_open_t=", snappedf(br._core_open_t, 0.1), " front_mult=", boss.front_mult)
		elif slot == order.size():
			var m2 := (k - 500) % 300
			if m2 == 0:
				# раскрыть ядро и проверить урон спереди и сзади
				boss._stun_t = 0.0
				boss.hp = boss.max_hp
				var br2 = boss.get_node("RaidBrain")
				br2.open_core(3.0)
				p.global_position = Vector2(boss.global_position.x + boss.facing * 380.0, p.global_position.y)
			if m2 == 20:
				var h0 := boss.hp
				boss.take_damage(100, p)
				var front := h0 - boss.hp
				boss._stun_t = 0.0
				boss.stagger = 0.0
				p.global_position = Vector2(boss.global_position.x - boss.facing * 380.0, p.global_position.y)
				boss._stun_t = 0.0
				boss.stagger = 0.0
				h0 = boss.hp
				boss.take_damage(100, p)
				print("core open: front dmg=", front, " back dmg=", h0 - boss.hp)
				shot("4_core_open")
			if m2 == 60:
				p.global_position = Vector2(boss.global_position.x + (420.0 if boss.global_position.x < 1300 else -420.0), p.global_position.y)
				boss.take_damage(9999999, p)
				dead_at = k
				print("final hit: alive=", boss.is_alive())
	return false
