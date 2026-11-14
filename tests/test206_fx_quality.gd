extends SceneTree
# Настройка «Эффекты: полные / упрощённые»: переключатель есть на вкладке «Игра и звук»,
# выбор сохраняется; в упрощённых нет пыли, дыма, обломков и конфетти, искр меньше,
# а кольца, вспышки и сам урон остаются. Одноразовые эффекты складываются в общий слой,
# а не в список детей мира.
var main
var f := 0
var fails := 0
var saved

func _initialize() -> void:
	Save.load_game()
	saved = StorySettings.get_value("fx_lite")
	StorySettings.set_value("fx_lite", false)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _fx_nodes() -> int:
	var l = main.world.get_meta("fx_layer") if main.world.has_meta("fx_layer") else null
	return l.get_child_count() if l != null and is_instance_valid(l) else 0

func _burst() -> int:
	var w: Node = main.world
	var before := _fx_nodes()
	Fx.sparks(w, Vector2(300, 300), Color.WHITE, 10)
	Fx.dust(w, Vector2(300, 300), 8)
	Fx.debris(w, Vector2(300, 300), 8)
	Fx.smoke(w, Vector2(300, 300))
	Fx.confetti(w, Vector2(300, 300), 20)
	Fx.ring(w, Vector2(300, 300), 60.0, Color.WHITE)
	Util.flash(w, Vector2(300, 300), 30.0, Color.WHITE)
	return _fx_nodes() - before

func _button(text: String) -> Button:
	for n in main.world.find_children("*", "Button", true, false):
		if (n as Button).text == text:
			return n
	return null

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		SettingsScreen._tab = 1
		main._on_mode_chosen("settings")
	if f == 12:
		check(not Fx.lite, "effects are full by default")
		check(_button("Полные") != null and _button("Упрощённые") != null, "Settings → Game and sound has the «Эффекты» switch")
		if DisplayServer.get_name() != "headless" and OS.get_environment("SHOTS") == "1":
			root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/settings_fx.png")
		_button("Упрощённые").pressed.emit()
	if f == 16:
		check(Fx.lite and StorySettings.get_value("fx_lite") == true, "choosing «Упрощённые» turns lite effects on and is saved")
		if DisplayServer.get_name() != "headless" and OS.get_environment("SHOTS") == "1":
			root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/settings_fx2.png")
		main.sel = [0, 1]
		main.map_id = "test_field"
		main.start_duel()
	if f == 20:
		var world_kids: int = main.world.get_child_count()
		var lite_n := _burst()
		check(lite_n == 4 + 1 + 1, "lite: only 4 of 10 sparks, the ring and the flash (%d nodes)" % lite_n)
		check(main.world.get_child_count() <= world_kids + 1, "one-shot effects go to the shared layer, not into the world's children")
		Fx.lite = false
		var full_n := _burst()
		check(full_n == 10 + 8 + 8 + 1 + 20 + 1 + 1, "full: sparks, dust, debris, smoke, confetti, ring, flash (%d nodes)" % full_n)
		Fx.lite = true
		# урон от взрыва в упрощённых эффектах тот же
		var p2: Player = main.duel_players[1]
		var hp0: int = p2.hp
		Util.explode(main.world, p2.global_position, 60.0, 20, 0, 0, main.duel_players[0])
		check(p2.hp < hp0, "lite effects don't change damage (-%d)" % (hp0 - p2.hp))
	if f == 30:
		StorySettings.set_value("fx_lite", saved if saved != null else false)
		Fx.load_setting()
		print("RESULT fails=", fails)
		return true
	return false
