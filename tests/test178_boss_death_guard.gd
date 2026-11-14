extends SceneTree
# Гибель босса: пока идёт сцена, героя не ранят ни снаряды, ни взрывы, ни лава;
# подмога босса рассыпается; волна засчитывается. Проверка на Трясинном Владыке (60).
var main
var f := 0
var arena: ArenaMode
var p1: Player
var fails := 0
var killed_at := -1
var died := false
var summoned_before := 0

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.sel = [8, 0]
		main.start_arena(false, 60)
	if f == 125:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		p1.died.connect(func(_i): died = true)
	if arena == null or f < 130:
		return false
	var boss = arena._boss
	if killed_at < 0:
		if boss != null and is_instance_valid(boss) and not boss.cutscene_shield and not p1.frozen and f > 400:
			# подмога и снаряды в полёте, герой при смерти
			boss.summon.call("frogman", 2, boss.global_position)
			summoned_before = arena._alive.filter(func(b): return b.has_meta("summoned")).size()
			p1.hp = 3
			p1._protect = 0.0
			p1._invuln = 0.0
			for k in 3:
				var s := Bullet.new()
				s.shooter = boss
				s.team = boss.team
				s.direction = Vector2(signf(p1.global_position.x - boss.global_position.x), 0)
				s.speed = 300.0
				s.damage = 50
				s.position = p1.global_position - s.direction * (60.0 + k * 40.0)
				main.world.add_child(s)
			boss.hp = 1
			boss.take_damage(50, p1)
			killed_at = f
			print("boss killed at f=", f, " summoned=", summoned_before)
		if f > 3000:
			print("FAIL boss never became fightable")
			return true
		return false
	var g := f - killed_at
	if g == 2:
		Util.explode(main.world, p1.global_position, 120.0, 60, 40, 1, null)
		p1.take_damage(99, null)
		var left := arena._alive.filter(func(b): return is_instance_valid(b) and b.has_meta("summoned")).size()
		check(left == 0, "boss reinforcements vanished (%d -> %d)" % [summoned_before, left])
		var shots := 0
		for n in main.world.get_children():
			if n is Bullet and not n.is_queued_for_deletion() and n.team != 0:
				shots += 1
		check(shots == 0, "enemy shots cleared (%d left)" % shots)
	if g == 90:
		check(p1.is_alive() and p1.hp == 3 and not died, "hero untouched during the death scene (hp %d)" % p1.hp)
	if g == 60 * 6:
		check(arena._state in ["break", "shop"] or arena.wave == 61, "wave counted (state=%s wave=%d)" % [arena._state, arena.wave])
		check(not p1.cutscene_shield, "shield removed afterwards")
		print("RESULT fails=", fails)
		return true
	return false
