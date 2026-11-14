extends SceneTree
# Снимки: реклама (все 5 видов), «Перерыв на кофе», «Хотфикс босса», «Бесконечная сила», лаги
var main
var f := 0
var arena: ArenaMode
var p1: Player
var k: GlavKit
var ad: Node
var kind := 0
var t0 := 0
var step := "ads"

func _initialize() -> void:
	Save.load_game()
	PadGlyph.force = true
	Save.data["skin_sel"] = {}
	Save.clear_arena_progress("solo")
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/ad_%s.png" % n)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.sel = [Characters.LIST.map(func(c): return c.get("kit", "")).find("glav"), 0]
		main.start_arena(false, int(OS.get_environment("WAVE")) if OS.get_environment("WAVE") != "" else 25)
	if f == 150:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		k = p1.kit
		t0 = f
	if arena == null:
		return false
	p1.hp = p1.max_hp
	if step == "ads" and OS.get_environment("WAVE") != "":
		step = "boss"
	if step == "ads":
		var d := f - t0
		if d == 1:
			ad = GlavKit.AdBreak.new()
			ad.kind = kind
			main.world.add_child(ad)
		if d == 100:
			shot("k%d_a" % kind)
		if d == 380:
			shot("k%d_b" % kind)
			ad.finish()
		if d == 400:
			kind += 1
			t0 = f
			if kind >= GlavKit.AdBreak.ADS.size():
				step = "boss"
	elif step == "boss":
		if OS.get_environment("WAVE") != "":
			k._ev_power()
			step = "boss2"
			t0 = f
		elif arena._boss != null and is_instance_valid(arena._boss) and not arena._boss.cutscene_shield and arena._state == "fight":
			k._ev_boss_fix()
			k._ev_power()
			k._ev_lag()
			step = "boss2"
			t0 = f
	elif step == "boss2":
		if f - t0 == 40:
			shot("bossfix")
			k._coffee_used = false
			k._ev_coffee()
		if f - t0 == 40 + 70:
			shot("coffee")
		if f - t0 == 40 + 130:
			shot("coffee2")
			return true
	return false
