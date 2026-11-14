extends SceneTree
# Магазин Арены: после 10-й волны — проходная локация, покупка усилений (товар
# сменяется не больше двух раз), жизнь — одна за остановку, дверь — дальше в бой;
# усиления сохраняются в прогрессе. Сердечко жизней, подсказка босса — в паузе.
var main
var f := 0
var arena: ArenaMode
var p1: Player
var fails := 0
var spd0 := 0.0
var lives0 := 0

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.unlock_all_heroes()
	Save.add_gold(5000)
	Save.clear_arena_progress("solo")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func shot(n: String) -> void:
	if OS.get_environment("SHOTS") == "1":
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/shop_%s.png" % n)

func _stand(x: float) -> void:
	p1.global_position = Vector2(x, arena.info["floor"] - p1.body_size.y / 2 - 2)
	p1.velocity = Vector2.ZERO

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.sel = [0, 0]
		main.start_arena(false, 10)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
	if arena == null:
		return false
	if f >= 200 and f < 2500 and arena._state == "fight" and not has_meta("cleared"):
		set_meta("cleared", f)
		check(arena.boss_tip != "", "boss tip stored (shown in full in the pause)")
		main.open_pause()
		var pz: BattlePause = null
		for n in main.world.get_children():
			if n is BattlePause:
				pz = n
		var texts: Array = []
		if pz:
			for b in pz._box.get_children():
				if b is Button:
					texts.append(b.text)
		check("Как победить босса" in texts and "Усиления забега" in texts, "pause has boss help + run buffs")
		if pz:
			pz._boss_help()
			pz._run_info()
			pz.resume()
		arena._queue.clear()
		for b in arena._alive:
			if is_instance_valid(b):
				b.queue_free()
		arena._alive.clear()
		if arena._boss and is_instance_valid(arena._boss):
			arena._boss.queue_free()
		arena._boss = null
		arena._hold = 0.0
	if f == int(get_meta("cleared", 99999)) + 220:
		check(arena._state == "shop", "after wave 10 heroes enter the Shop (%s)" % arena._state)
		check(arena._slots.size() == 4, "3 buff stalls + 1 life stall")
		check(arena.hud._lives != null and arena.hud._lives_l.text.begins_with("×"), "lives shown with a heart")
		shot("stop")
	if f == int(get_meta("cleared", 99999)) + 230:
		var s: RunShop.Slot = arena._slots[0]
		s.id = "speed"
		spd0 = p1.speed
		_stand(s.global_position.x)
	if f == int(get_meta("cleared", 99999)) + 232:
		Input.action_press("p1_shoot")
	if f == int(get_meta("cleared", 99999)) + 234:
		Input.action_release("p1_shoot")
	if f == int(get_meta("cleared", 99999)) + 240:
		var s: RunShop.Slot = arena._slots[0]
		check(int(p1.run.get("speed", 0)) == 1 and p1.speed > spd0, "bought a run buff (speed %d -> %d)" % [spd0, p1.speed])
		check(s.restocks == 1 and not s.sold, "merchant restocked the stall")
		shot("bought")
	# ещё две покупки на том же прилавке — потом «Распродано»
	if f - int(get_meta("cleared", 99999)) in [250, 270]:
		Input.action_press("p1_shoot")
	if f - int(get_meta("cleared", 99999)) in [252, 272]:
		Input.action_release("p1_shoot")
	if f == int(get_meta("cleared", 99999)) + 290:
		var s: RunShop.Slot = arena._slots[0]
		check(s.sold, "a stall restocks at most twice")
		var total := 0
		for k in p1.run:
			total += int(p1.run[k])
		check(total == 3, "three buffs bought from one stall (%d)" % total)
	# жизнь
	if f == int(get_meta("cleared", 99999)) + 300:
		lives0 = arena.lives
		_stand(arena._slots[3].global_position.x)
	if f == int(get_meta("cleared", 99999)) + 302:
		Input.action_press("p1_shoot")
	if f == int(get_meta("cleared", 99999)) + 304:
		Input.action_release("p1_shoot")
	if f == int(get_meta("cleared", 99999)) + 310:
		check(arena.lives == lives0 + 1 and arena._slots[3].sold, "extra life: +1, once per stop")
	# к двери
	if f == int(get_meta("cleared", 99999)) + 320:
		_stand(arena.info["door_x"])
	if f == int(get_meta("cleared", 99999)) + 400:
		check(arena._state != "shop" and arena.wave >= 10, "door leads on (%s)" % arena._state)
		var pr := Save.arena_progress("solo")
		check(pr.has("run") and (pr["run"] as Array).size() == 1 and not (pr["run"][0] as Dictionary).is_empty(), "run buffs saved with progress")
	if f == int(get_meta("cleared", 99999)) + 640:
		check(arena.wave == 11 and arena._state in ["fight", "cutscene"], "wave 11 starts after the Shop (%d %s)" % [arena.wave, arena._state])
		print("RESULT fails=", fails)
		return true
	return false
