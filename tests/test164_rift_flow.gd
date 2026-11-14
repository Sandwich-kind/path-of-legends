extends SceneTree
# Ход Арены после Лорда: 80 → 81 (Летающие острова, карта Цитадели открыта),
# 85 → 86 (Деревня в огне, карта островов открыта), 90 — победа (карта деревни открыта).
var main
var f := 0
var arena: ArenaMode
var step := 0
var t0 := 0
var won := []
func _initialize() -> void:
	Save.load_game()
	Save.reset()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _start(w: int) -> void:
	main.sel = [0, 0]
	main.start_arena(false, w)
	arena = null
	for n in main.world.get_children():
		if n is ArenaMode: arena = n
	arena.finished.connect(func(v, wd, g): won.append([v, wd]))
	t0 = f
func _physics_process(_d: float) -> bool:
	f += 1
	if arena and is_instance_valid(arena):
		for p in arena.players:
			p._protect = 1.0
	match step:
		0:
			if f == 3:
				print("stage_for: 80->", ArenaMode.stage_for(80), " 81->", ArenaMode.stage_for(81), " 85->", ArenaMode.stage_for(85),
						" 86->", ArenaMode.stage_for(86), " 90->", ArenaMode.stage_for(90), " names=", ArenaMode.STAGE_NAMES.size(), " waves=", Bots.WAVES.size())
				_start(80)
				step = 1
		1:
			if f - t0 == 400:
				for b in arena._alive.duplicate():
					if is_instance_valid(b): b.queue_free()
				arena._alive.clear()
				arena._queue.clear()
				arena._boss = null
				arena.place_name = "Вершина цитадели"
				arena.wave = 80
				arena._wave_cleared()
				print("after 80: state=", arena._state, " citadel unlocked=", Save.stage_unlocked(16), " progress=", Save.arena_progress("solo"))
				t0 = f
				step = 2
		2:
			if f - t0 == 60 * 9:
				print("now wave=", arena.wave, " stage=", arena.stage, " place='", arena.place_name, "' segs=", arena.info.get("isle_segs", []).size(),
						" cam_current=", main.world.get_viewport().get_camera_2d() == arena._cam)
				var img := root.get_viewport().get_texture().get_image()
				if img: img.save_png("/tmp/claude-0/arena90/flow_81.png")
				for b in arena._alive.duplicate():
					if is_instance_valid(b): b.queue_free()
				arena._alive.clear()
				arena._queue.clear()
				arena.wave = 85
				arena._wave_cleared()
				print("after 85: sky unlocked=", Save.stage_unlocked(17))
				t0 = f
				step = 3
		3:
			if f - t0 == 60 * 9:
				print("now wave=", arena.wave, " stage=", arena.stage, " debris=", arena.info.has("debris"))
				var img := root.get_viewport().get_texture().get_image()
				if img: img.save_png("/tmp/claude-0/arena90/flow_86.png")
				for b in arena._alive.duplicate():
					if is_instance_valid(b): b.queue_free()
				arena._alive.clear()
				arena._queue.clear()
				arena.wave = 90
				arena._wave_cleared()
				t0 = f
				step = 4
		4:
			if f - t0 == 60 * 4:
				print("after 90: state=", arena._state, " burning unlocked=", Save.stage_unlocked(18), " finished=", won, " progress=", Save.arena_progress("solo"))
				Save.reset()
				return true
	return false
