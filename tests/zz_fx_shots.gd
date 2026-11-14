extends SceneTree
# Снимки общих эффектов: заставка ульты, вспышка приёма, попадания (HERO_KIT=набор легенды)
var main
var f := 0
var arena: ArenaMode
var p1: Player
var tag := ""

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.clear_arena_progress("solo")
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/fx_%s_%s.png" % [tag, n])

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		tag = OS.get_environment("HERO_KIT")
		main.sel = [Characters.LIST.map(func(c): return c.get("kit", "")).find(tag), 0]
		main.start_arena(false, 21)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
		p1 = arena.players[0]
	if arena == null:
		return false
	if f == 300:
		arena._queue.clear()
		for b in arena._alive:
			if is_instance_valid(b): b.queue_free()
		arena._alive.clear()
		p1.facing = 1
		for k in 3:
			var t := arena.spawn_at("grunt", p1.global_position + Vector2(220 + k * 120, -20))
			t.remove_meta("summoned")
			t.max_hp = 9000
			t.hp = 9000
	if f > 300:
		p1.hp = p1.max_hp
		arena._queue.clear()
	if f == 330:
		p1._cd[0] = 0.0
		p1.kit.handle_ability(0, p1.abilities[0], "p1_a1", 0.0)
		p1._cd[0] = p1.ability_cds[0]
		Input.action_press("p1_a1")
	if f == 332:
		Input.action_release("p1_a1")
	if f == 336:
		shot("cast")
	if f == 400:
		p1.ult_charge = p1.ult_need
		Input.action_press("p1_ult")
	if f == 402:
		Input.action_release("p1_ult")
	if f == 410:
		shot("ult1")
	if f == 430:
		shot("ult2")
	if f == 500:
		Input.action_press("p1_shoot")
	if f == 530:
		shot("hits")
		Input.action_release("p1_shoot")
		return true
	return false
