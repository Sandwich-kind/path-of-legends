extends SceneTree
# Сколько стоит появление одного врага/героя (сборка модели): мс на штуку
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 0]
		main.start_arena(false, 21)
	if f == 120:
		var arena: ArenaMode
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
		arena._queue.clear()
		var kinds: Array = OS.get_environment("KINDS").split(",") if OS.get_environment("KINDS") != "" else ["grunt", "tank", "soldier", "bomber", "runner", "ghoul"]
		for k in kinds:
			if not Bots.TYPES.has(k):
				continue
			var t0 := Time.get_ticks_usec()
			for i in 10:
				var b: Player = arena.spawn_at(k, Vector2(600 + i * 60, 800))
			var ms := (Time.get_ticks_usec() - t0) / 10000.0
			print("SPAWN %s %.2f ms each" % [k, ms])
		for hi in [0, 8, 21, 22]:
			var t1 := Time.get_ticks_usec()
			var p := Characters.create(hi, "p2", 1, 0, Vector2(500, 800), 1, Color.WHITE)
			main.world.add_child(p)
			print("HERO %s %.2f ms" % [Characters.LIST[hi].get("kit", "?"), (Time.get_ticks_usec() - t1) / 1000.0])
			p.queue_free()
		var t2 := Time.get_ticks_usec()
		var tr := TitanRobot.new()
		tr.owner_p = arena.players[0] if "owner_p" in tr else null
		print("TITAN new %.2f ms" % ((Time.get_ticks_usec() - t2) / 1000.0))
		tr.free()
		return true
	return false
