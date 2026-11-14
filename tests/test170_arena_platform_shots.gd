extends SceneTree
# Арена: пули, стрелы и копья пролетают сквозные платформы; в Дуэли — как раньше.
var main
var f := 0
var arena
var plat: Node2D
var shots := {}
var fails := 0

func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _find_plat() -> Node2D:
	for n in main.world.get_children():
		if n is StaticBody2D and Util.is_one_way(n) and n.global_position.y < 800.0:
			return n
	return null

func _fire(kind: String, y_off: float) -> void:
	var from := plat.global_position + Vector2(-260, y_off)
	var hero: Player = arena.players[0]
	match kind:
		"bullet":
			var b := Bullet.new()
			b.shooter = hero
			b.team = 0
			b.direction = Vector2.RIGHT
			b.speed = 900.0
			b.damage = 5
			b.size = 8.0
			b.position = from
			main.world.add_child(b)
			shots[kind] = b
		"arrow":
			var a := Arrow.new()
			a.shooter = hero
			a.team = 0
			a.damage = 5
			a.gravity = 0.0
			a.position = from
			a.velocity = Vector2(1200, 0)
			main.world.add_child(a)
			shots[kind] = a

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 0]
		main.start_arena(false, 2)
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
	if f == 30:
		plat = _find_plat()
		print("platform at ", plat.global_position if plat else null)
		_fire("bullet", 0.0)
		_fire("arrow", 2.0)
	if f == 70:
		for k in shots:
			var s = shots[k]
			var ok: bool = is_instance_valid(s) and s.global_position.x > plat.global_position.x + 150.0
			if not ok:
				fails += 1
			print("%s %s x=%s" % ["ok  " if ok else "FAIL", k, str(s.global_position.x) if is_instance_valid(s) else "gone"])
		# контроль: без режима Арены пуля разбивается о платформу
		arena.remove_from_group("arena_mode")
		shots.clear()
		_fire("bullet", 0.0)
	if f == 110:
		var s = shots["bullet"]
		var stopped: bool = not is_instance_valid(s) or s.global_position.x < plat.global_position.x + 150.0
		if not stopped:
			fails += 1
		print("%s outside arena the bullet stops at the platform" % ("ok  " if stopped else "FAIL"))
		print("RESULT fails=", fails)
		return true
	return false
