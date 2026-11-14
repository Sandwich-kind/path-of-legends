extends SceneTree
# Отголосок (легенда за Странника): выстрел с эхом, Шаг на изнанку, Грань раздваивает
# свои сгустки, Тяга бездны подбрасывает, ульта повторяет выстрелы.
var main
var f := 0
var arena: ArenaMode
var p1: Player
var fails := 0
var hp0 := 0
var x0 := 0.0
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
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/echo_%s.png" % n)

func _bullets() -> int:
	var n := 0
	for b in main.world.get_children():
		if b is Bullet and b.team == 0 and not b.is_queued_for_deletion():
			n += 1
	return n

func _physics_process(_d: float) -> bool:
	f += 1
	var idx := Characters.LIST.map(func(c): return c.get("kit", "")).find("echo")
	if f == 5:
		check(Characters.LIST[idx]["kit"] == "echo", "echo hero in LIST")
		main.sel = [idx, 0]
		main.start_arena(false, 21)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		check(p1.kit is EchoKit, "kit attached")
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
		target.max_hp = 5000
		target.hp = 5000
		target.frozen = true
	if f == 340:
		hp0 = target.hp
		p1._cooldown_left = 0.0
		p1.kit.weapon(0.016, true)
	if f == 340 + 75:
		var lost := hp0 - target.hp
		check(lost > p1.bullet_damage, "lamp hit plus echo hit (%d dmg)" % lost)
	if f == 430:
		x0 = p1.global_position.x
		p1.kit.use("rift_step")
	if f == 432:
		check(p1.global_position.x > x0 + 150.0, "rift step moved forward (%d)" % int(p1.global_position.x - x0))
	if f == 520:
		p1.global_position.x = target.global_position.x - 450.0
		p1.facing = 1
		p1.kit.use("edge_line")
		p1._cooldown_left = 0.0
	if f == 530:
		p1.kit.weapon(0.016, true)
	if f == 545:
		check(_bullets() >= 2, "edge splits own shot (%d shots)" % _bullets())
		shot("edge")
	if f == 600:
		target.frozen = false
		p1.kit.use("abyss_pull")
	if f == 600 + 40:
		check(target.velocity.y < -200.0 or target.global_position.y < p1.global_position.y - 40.0, "abyss pull lifts the foe (vy %d)" % int(target.velocity.y))
		shot("pull")
	if f == 700:
		target.frozen = true
		p1.ult_charge = p1.ult_need
		p1.kit.ult()
		p1._cooldown_left = 0.0
		p1.kit.weapon(0.016, true)
	if f == 700 + 40:
		check(p1.kit.ulting(), "path echo active")
		check(_bullets() >= 1, "echo repeats the shot")
		shot("ult")
	if f == 700 + 60 * 9:
		check(not p1.kit.ulting(), "path echo ends")
		print("RESULT fails=", fails)
		return true
	return false
