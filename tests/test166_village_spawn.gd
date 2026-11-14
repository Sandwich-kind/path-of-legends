extends SceneTree
# Окраина деревни (волны 6–10): у места появления героев нет стен, вышка доступна прыжками;
# эскизы новых карт Дуэли строятся. Снимок — /tmp/claude-0/arena90/village_spawn.png
var main
var f := 0
var arena
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	for id in ["arena_sky", "arena_burning", "arena_village"]:
		var img := Maps.preview_image(id, Vector2(360, 200))
		if img: img.save_png("/tmp/claude-0/arena90/preview_%s.png" % id)
		print("preview ", id, " ", img.get_size())
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main.start_arena(true, 6)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if f == 200:
		var space: PhysicsDirectSpaceState2D = main.world.get_world_2d().direct_space_state
		var c: Vector2 = arena.info["center"]
		var fy: float = arena.info["floor"]
		for dx in [-70.0, 0.0, 70.0]:
			var q := PhysicsShapeQueryParameters2D.new()
			var rs := RectangleShape2D.new()
			rs.size = Vector2(40, 60)
			q.shape = rs
			q.transform = Transform2D(0, Vector2(c.x + dx, fy - 32))
			q.collision_mask = Layer.WORLD
			print("spawn dx=", dx, " blocked=", not space.intersect_shape(q, 4).is_empty())
		# путь наверх: ступени через каждые 120 пикселей (прыжок ≈156)
		for h in [120.0, 240.0, 360.0]:
			var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(c.x + 20, fy - h - 30), Vector2(c.x + 20, fy - h + 30), Layer.WORLD))
			print("step at ", h, ": ", not hit.is_empty())
		# стенки по бокам в пределах 200 пикселей от центра на высоте героя
		for dx2 in [-150.0, -110.0, 110.0, 150.0]:
			var hit2 := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(c.x, fy - 30), Vector2(c.x + dx2, fy - 30), Layer.WORLD))
			print("wall toward ", dx2, ": ", "none" if hit2.is_empty() else str(hit2["position"]))
		var img := root.get_viewport().get_texture().get_image()
		if img: img.save_png("/tmp/claude-0/arena90/village_spawn.png")
		return true
	return false
