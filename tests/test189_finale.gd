extends SceneTree
# Сложная Арена, 101–103: волны есть только в сложном режиме; Совет из трёх (узы, ритуал,
# смена полоски), Лорд Бездны (три фазы, столпы, якоря), Странник, поглощённый бездной
# (три фазы, Пожирание), победа — отметка «Чемпион» и чемпионский облик.
var main
var f := 0
var fails := 0
var arena: ArenaMode
var p1: Player
var step := 0
var t0 := 0
var b
var stage_t := 0
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	Save.data["hard_heroes"] = []
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])
func shot(n: String) -> void:
	if OS.get_environment("SHOTS") == "1":
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/fin_%s.png" % n)
func _find() -> void:
	for n in main.world.get_children():
		if n is ArenaMode: arena = n
	p1 = arena.players[0]
func start(w: int, rules := "hard") -> void:
	main.sel = [0, 0]
	main.start_arena(false, w, rules)
	t0 = f
	b = null
	stage_t = 0
func _physics_process(_d: float) -> bool:
	f += 1
	if arena and is_instance_valid(p1):
		p1.hp = p1.max_hp
		p1._protect = 1.0
	var g := f - t0
	match step:
		0:
			if f == 5:
				check(ArenaMode.max_wave(false) == 100 and ArenaMode.max_wave(true) == 103, "101–103 only in hard mode")
				check(not (101 in ArenaMode.rush_waves(false)) and 103 in ArenaMode.rush_waves(true), "hard Boss Rush includes 101–103")
				start(101)
			if g == 100:
				_find()
			if g == 1000:
				var council := arena._alive.filter(func(x): return is_instance_valid(x) and x.has_meta("council"))
				check(council.size() == 3, "Council of three is out (%d)" % council.size())
				check(arena._boss != null and arena._boss.get_meta("kind") == "harbinger", "boss bar is the Harbinger")
				shot("council")
				for x in council:
					if x.get_meta("kind") == "abyss_headsman":
						x.take_damage(99999, p1)
			if g == 1060:
				var alive := arena._alive.filter(func(x): return is_instance_valid(x) and x.has_meta("council") and x.is_alive())
				check(alive.size() == 2 and arena._state == "fight", "fight goes on after one member falls")
			if g == 1600:
				shot("ritual")
				for x in arena._alive.duplicate():
					if is_instance_valid(x) and x.is_alive():
						x.take_damage(99999, p1)
			if g == 2100:
				check(arena.wave >= 101 and (arena._state == "break" or arena.wave == 102), "wave 101 cleared (wave %d, %s)" % [arena.wave, arena._state])
				step = 1
				start(102)
		1:
			if g == 100:
				_find()
			if stage_t == 0 and g > 200 and arena._boss and is_instance_valid(arena._boss) and not arena._boss.cutscene_shield:
				b = arena._boss
				stage_t = g
			if stage_t > 0 and g == stage_t + 60:
				check(b.get_meta("kind") == "abyss_lord" and absf(b.armor_mult - 0.55) < 0.01, "Abyss Lord armored")
				b.hp = int(b.max_hp * 0.55)
				b.heal(0)
			if stage_t > 0 and g == stage_t + 400:
				var br = b.get_node("AbyssLordBrain")
				check(br.phase == 2 and br._pillars.size() == 3, "phase 2: three Dawn Pillars")
				shot("lord2")
				b.hp = int(b.max_hp * 0.2)
				b.heal(0)
			if stage_t > 0 and g == stage_t + 800:
				var br2 = b.get_node("AbyssLordBrain")
				check(br2.phase == 3 and b.invulnerable and br2._anchors.size() == 3, "phase 3: anchored and invulnerable")
				shot("lord3")
				for a in br2._anchors.duplicate():
					if is_instance_valid(a):
						a.take_damage(99999, p1)
			if stage_t > 0 and g == stage_t + 900:
				check(not b.invulnerable, "anchors broken — Lord can be hurt")
				b.take_damage(b.hp + 99999, p1)
			if stage_t > 0 and g == stage_t + 1400:
				check(arena.wave == 103 or arena._upcoming() == 103, "wave 102 cleared")
				step = 2
				start(103)
		2:
			if g == 100:
				_find()
			if stage_t == 0 and g > 200 and arena._boss and is_instance_valid(arena._boss) and not arena._boss.cutscene_shield:
				b = arena._boss
				stage_t = g
			if stage_t > 0 and g == stage_t + 120:
				check(b.flying or b.get_node("WandererBrain")._diving, "Mad Wanderer flies from the start")
				shot("mad1")
				b.hp = int(b.max_hp * 0.6)
			if stage_t > 0 and g == stage_t + 500:
				var mb = b.get_node("WandererBrain")
				check(mb.mad == 2, "phase 2")
				b.hp = int(b.max_hp * 0.3)
			if stage_t > 0 and g == stage_t + 900:
				var mb2 = b.get_node("WandererBrain")
				check(mb2.mad == 3, "phase 3 (chaos)")
				shot("mad3")
				mb2._chaos()
			if stage_t > 0 and g == stage_t + 1200:
				b.take_damage(b.hp + 99999, p1)
			if stage_t > 0 and g == stage_t + 2000:
				check(Save.hard_done() and 0 in Save.hard_heroes(), "hard arena complete: champion mark")
				check(Skins.owned("champ_hunter"), "champion skin unlocked")
				print("RESULT fails=", fails)
				return true
	if f > 60 * 200:
		print("FAIL timeout step ", step)
		return true
	return false
