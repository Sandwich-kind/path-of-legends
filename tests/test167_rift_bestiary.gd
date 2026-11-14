extends SceneTree
# Бестиарий: вкладка «Странник» — все противники свиты, описание Предвестника
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	Save.see_all()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func find(t):
	for n in main.world.get_children():
		if is_instance_of(n, t): return n
	return null
func _physics_process(_d: float) -> bool:
	f += 1
	match f:
		5: main._on_mode_chosen("bestiary")
		15:
			var b = find(BestiaryScreen)
			b._tab = BestiaryScreen.TABS.size() - 1
			b._refresh()
			print("tab ", BestiaryScreen.TABS[b._tab], " kinds=", Bots.LOCATIONS["rift"].size())
		40:
			if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/arena90/bestiary_rift.png")
			var b2 = find(BestiaryScreen)
			b2._select(Bots.LOCATIONS["rift"].size() - 1)
		60:
			if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/arena90/bestiary_harbinger.png")
			return true
	return false
