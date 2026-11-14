extends SceneTree
# Странник (волна 100): пять фаз, три смены места (Зал Бездны, Изнанка), в конце он
# уходит в разлом сам — победа засчитывается, открываются сложный режим и Босс-раш.
var main
var f := 0
var arena: ArenaMode
var p1: Player
var fails := 0
var b
var t0 := 0
var won := -1
var phases: Array = []
var places: Array = []

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	Save.data["arena_done"] = false
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.sel = [0, 0]
		Save.clear_arena_progress("solo")
		main.start_arena(false, 100)
	if f == 100:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		arena.finished.connect(func(v, w, _g): won = 1 if v else 0)
	if arena == null:
		return false
	p1.hp = p1.max_hp
	p1._protect = 1.0
	if b == null and arena._boss != null and not arena._boss.cutscene_shield and f > 200:
		b = arena._boss
		t0 = f
	if b == null or not is_instance_valid(b):
		if f > 60 * 120:
			print("FAIL no boss")
			return true
		if won < 0:
			return false
	var br = b.get_node_or_null("WandererBrain") if is_instance_valid(b) else null
	if br and (phases.is_empty() or phases[-1] != br.phase):
		phases.append(br.phase)
	if places.is_empty() or places[-1] != arena.place_name:
		places.append(arena.place_name)
	var g := f - t0
	# каждые 6 секунд бьём ровно до следующего порога
	if is_instance_valid(b) and b.is_alive() and g > 0 and g % 360 == 0 and not b.cutscene_shield:
		match br.phase:
			1: b.hp = int(b.max_hp * 0.6)
			2: b.hp = int(b.max_hp * 0.3)
			4: b.hp = int(b.max_hp * 0.45)
			_: b.take_damage(b.hp + 999, p1)
		b.heal(0)
	if won >= 0 or f > 60 * 150:
		print("phases ", phases, " places ", places)
		check(phases == [1, 2, 3, 4, 5], "Wanderer goes through all five phases")
		check(places.size() >= 3, "fight moves twice (%s)" % str(places))
		check(won == 1, "victory counted after he leaves")
		check(Save.arena_done(), "hard mode and Boss Rush unlocked")
		check(Save.stage_unlocked(20), "Abyss Palace duel map unlocked")
		print("RESULT fails=", fails)
		return true
	return false
