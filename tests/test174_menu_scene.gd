extends SceneTree
# Живая заставка главного меню: снимки утром, днём, на закате, ночью и на рассвете,
# и проверка, что цикл дня и ночи идёт по кругу.
var main
var f := 0
var out := "/tmp/claude-0/menu/"
var scene: MenuScene
var times := []
var ti := 0
var fails := 0
var stage2 := -1
var c0 := 0.0

func _initialize() -> void:
	Save.load_game()
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 10:
		for n in main.world.get_children():
			if n is MainMenu:
				scene = n._scene
		if scene == null:
			print("FAIL no scene")
			return true
		times = [["1_morning", MenuScene.DAY * 0.22], ["2_noon", MenuScene.DAY * 0.5], ["3_sunset", MenuScene.DAY * 0.96],
				["4_night", MenuScene.DAY + MenuScene.NIGHT * 0.5], ["5_dawn", MenuScene.DAY + MenuScene.NIGHT * 0.985]]
	if scene == null or f < 10:
		return false
	var k := f - 10
	if k % 90 == 0 and ti < times.size():
		scene.clock = times[ti][1]
	if k % 90 == 80 and ti < times.size():
		var img := root.get_viewport().get_texture().get_image()
		if img:
			if img: img.save_png(out + times[ti][0] + ".png")
		var e := scene._elev()
		print("%s elev=%.2f sun=%s moon=%s stars=%.2f birds=%d" % [times[ti][0], e, str(scene._sun.visible), str(scene._moon.visible),
				scene._stars.modulate.a, scene._birds.size()])
		if times[ti][0] == "4_night" and not (scene._moon.visible and scene._stars.modulate.a > 0.9):
			fails += 1
		if times[ti][0] == "2_noon" and not (scene._sun.visible and scene._stars.modulate.a < 0.05):
			fails += 1
		ti += 1
	if ti >= times.size() and stage2 < 0:
		# цикл замыкается: после ночи снова день
		scene.clock = (MenuScene.DAY + MenuScene.NIGHT) * 3.0 + MenuScene.DAY * 0.5
		scene._apply_time(0.0)
		if not scene._sun.visible:
			fails += 1
		# переходы по экранам меню: заставка та же, время не сбрасывается
		scene.clock = MenuScene.DAY * 0.9
		c0 = scene.clock
		main._on_mode_chosen("settings")
		stage2 = f
	if stage2 > 0 and f == stage2 + 60:
		var vis: bool = MenuScene.shared.get_parent().visible
		print("settings: shared=%s visible=%s clock=%.1f" % [str(MenuScene.shared == scene), str(vis), scene.clock])
		if not (MenuScene.shared == scene and vis and scene.clock > c0 + 0.5):
			fails += 1
		var img := root.get_viewport().get_texture().get_image()
		if img:
			if img: img.save_png(out + "6_settings.png")
		main._on_mode_chosen("shop")
	if stage2 > 0 and f == stage2 + 120:
		print("shop: visible=%s clock=%.1f" % [str(MenuScene.shared.get_parent().visible), scene.clock])
		if MenuScene.shared.get_parent().visible or scene.clock < c0 + 1.5:
			fails += 1
		main.show_menu()
	if stage2 > 0 and f == stage2 + 160:
		var mm: MainMenu = null
		for n in main.world.get_children():
			if n is MainMenu:
				mm = n
		print("menu again: same=%s visible=%s clock=%.1f (was %.1f)" % [str(mm._scene == scene), str(MenuScene.shared.get_parent().visible), scene.clock, c0])
		if not (mm._scene == scene and MenuScene.shared.get_parent().visible and scene.clock > c0 + 2.0):
			fails += 1
		var img2 := root.get_viewport().get_texture().get_image()
		if img2:
			if img2: img2.save_png(out + "7_back.png")
		print("RESULT fails=", fails)
		return true
	return false
