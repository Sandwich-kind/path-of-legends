extends SceneTree
# Лорд Бездны, фаза «Якоря Бездны» (сложная Арена, волна 102): в полёте он неуязвим, но
# не просто парит — продолжает атаковать (метеоры, лучи, шипы); якоря висят там, куда
# достаёт любой герой с ярусов площадки; когда якоря разбиты, Лорд падает и открыт для ударов.
var main
var f := 0
var fails := 0
var arena: ArenaMode
var p1: Player
var b: Player
var br
var t0 := 0
var seen := {}
var casts := 0
var prev_cd := {}
var hp0 := 0

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func shot(n: String) -> void:
	if OS.get_environment("SHOTS") == "1" and DisplayServer.get_name() != "headless":
		root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/lordsky_%s.png" % n)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.sel = [0, 0]
		main.start_arena(false, 102, "hard")
	if f == 105:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
	if arena == null:
		return false
	if is_instance_valid(p1):
		p1.hp = p1.max_hp
	if b == null:
		if f > 300 and arena._boss and is_instance_valid(arena._boss) and not arena._boss.cutscene_shield:
			b = arena._boss
			br = b.get_node("AbyssLordBrain")
			b.hp = int(b.max_hp * 0.2)                 # сразу к третьей фазе
			b.heal(0)
			t0 = f
		return false
	var g := f - t0
	if br.phase < 3 or br._busy:
		t0 = f - 1 if br.phase < 3 else t0
		if g > 60 * 40:
			check(false, "phase 3 never started")
			print("RESULT fails=", fails)
			return true
		return false
	if not seen.has("start"):
		seen["start"] = true
		t0 = f
		g = 0
		for k in br._cd:
			prev_cd[k] = float(br._cd[k])
	# приём сработал — его откат вырос
	for k in br._cd:
		if float(br._cd[k]) > float(prev_cd.get(k, 0.0)) + 1.0:
			casts += 1
			seen[k] = true
		prev_cd[k] = float(br._cd[k])
	if g == 30:
		check(b.flying and b.invulnerable and br._anchors.size() == 3, "phase 3: the Lord flies, invulnerable, held by 3 anchors")
		# якоря — в досягаемости с ярусов: над каждым есть площадка не дальше прыжка
		var fy: float = arena.info["floor"]
		var reach := true
		for a in br._anchors:
			var h: float = fy - a.global_position.y
			var best := h                               # с пола
			for pd in AbyssStages.PAL_LEVEL + [[Colosseum.W / 2, Colosseum.STEP * 4 + 10, 160.0]]:
				if absf(float(pd[0]) - a.global_position.x) < float(pd[2]) / 2.0 + 140.0:
					best = minf(best, h - float(pd[1]))
			if best > 200.0:
				reach = false
				print("   anchor at ", a.global_position, " is ", int(best), " px above the nearest tier")
		check(reach, "every anchor hangs within a jump of some tier")
		hp0 = b.hp
		b.take_damage(500, p1)
		check(b.hp == hp0, "hits on the flying Lord do nothing while anchors hold")
	if g == 200:
		shot("fly")
	if g == 60 * 16:
		check(casts >= 3 and seen.size() - 1 >= 2, "in flight he keeps attacking: %d casts of %d kinds in 16 s" % [casts, seen.size() - 1])
		var dy: float = p1.global_position.y - b.global_position.y
		check(dy > 120.0, "he hovers above the hero (%d px)" % int(dy))
		for a in br._anchors.duplicate():
			if is_instance_valid(a):
				a.take_damage(99999, p1)
	if g == 60 * 16 + 90:
		check(not b.invulnerable and not b.flying, "anchors broken — he falls and can be hurt")
		hp0 = b.hp
		b.take_damage(40, p1)
		check(b.hp < hp0, "the fallen Lord takes damage (-%d)" % (hp0 - b.hp))
		shot("fallen")
		print("RESULT fails=", fails)
		return true
	return false
