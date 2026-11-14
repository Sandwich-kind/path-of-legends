extends SceneTree
var f := 0
var inv
var bes
func _initialize() -> void:
	Save.load_game()
	for k in Bots.TYPES:
		Save.see(k)
	inv = InventoryScreen.new()
	root.add_child(inv)
func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		inv._select_tab(1)
	if f == 20:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/ui_inv.png")
		inv.queue_free()
		bes = BestiaryScreen.new()
		root.add_child(bes)
	if f == 26:
		for t in bes.TABS.size():
			var kinds: Array = Bots.LOCATIONS[bes.TABS[t][0]]
			var j := kinds.find("colossus")
			if j >= 0:
				bes._tab = t
				bes._refresh()
				bes._select(j)
	if f == 40:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/ui_bes.png")
		return true
	return false
