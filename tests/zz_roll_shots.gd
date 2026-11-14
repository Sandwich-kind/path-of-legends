extends SceneTree
# Снимки: открытие Ледяного сундука — лента обликов в разгоне, у остановки и итог
var main
var f := 0
var shop: ShopScreen

func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/roll_%s.png" % n)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 20:
		Save.data["gold"] = 5000
		Save.data["skins"] = (Save.data.get("skins", []) as Array).filter(func(id): return not String(id).begins_with("ice_"))
		Save.data["skins"].append("ice_hunter")             # один уже есть — его на ленте быть не должно
	if f == 30:
		main._on_mode_chosen("shop")
	if f == 60:
		for n in main.world.get_children():
			if n is ShopScreen:
				shop = n
		shop._select(3)
	if f == 160:
		for o in shop._offers:
			if o is Dictionary and o.get("series", "") == "ice":
				shop._open_chest(o)
	if f == 160 + 70:
		shot("spin")
	if f == 160 + 300:
		shot("slow")
	if f == 160 + 372:
		shot("stop")
	if f == 160 + 470:
		shot("won")
		return true
	return false
