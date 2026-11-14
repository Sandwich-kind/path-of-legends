extends SceneTree
# Снимок карты целиком с отметками алтарей (красные круги) — для проверки подъёмов.
# MAPS=id1,id2  OUT=/tmp/claude-0/maps/
var ids: Array = ["arena_swamp"]
var out := "/tmp/claude-0/maps/"

func _initialize() -> void:
	Save.load_game()
	if OS.get_environment("MAPS") != "":
		ids = Array(OS.get_environment("MAPS").split(","))
	if OS.get_environment("OUT") != "":
		out = OS.get_environment("OUT")
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()

func _run() -> void:
	for id in ids:
		var world := Node2D.new()
		root.add_child(world)
		var info: Dictionary = Maps.build(world, id)
		var size: Vector2 = info["size"]
		var r: Rect2 = info.get("cam_rect", Rect2(Vector2.ZERO, size))
		var top := minf(r.position.y, size.y - 1300.0) if id == "mountain" else r.position.y
		r = Rect2(Vector2(r.position.x, top), Vector2(r.size.x, r.end.y - top))
		for n in world.get_children():
			if n is PickupSpawner:
				var m := Line2D.new()
				var pts := Util.circle(34.0, 20)
				pts.append(pts[0])
				m.points = pts
				m.width = 6.0
				m.default_color = Color(1, 0.1, 0.1) if n.kind == "buff" else Color(0.1, 1, 0.3)
				m.position = n.global_position
				m.z_index = 50
				world.add_child(m)
		var cam := Camera2D.new()
		var vs := root.get_visible_rect().size
		var z := minf(vs.x / r.size.x, vs.y / r.size.y)
		cam.zoom = Vector2(z, z)
		cam.position = r.get_center()
		world.add_child(cam)
		cam.make_current()
		for k in 12:
			await process_frame
		var img := root.get_viewport().get_texture().get_image()
		if img:
			if img: img.save_png(out + id + ".png")
		print("shot ", id)
		world.queue_free()
		await process_frame
	quit()
