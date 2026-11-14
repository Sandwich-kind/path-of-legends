extends SceneTree
# Снимки: кнопки проверки в меню, вкладка «Прогресс» в настройках с подтверждением,
# Ледяной сундук в Лавке и его карточка
var main
var f := 0
var shop: ShopScreen
var st: SettingsScreen

func _initialize() -> void:
	Save.load_game()
	Save.data["gold"] = 5000
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/ui_%s.png" % n)

func _find(cls) -> Node:
	for n in main.world.get_children():
		if is_instance_of(n, cls):
			return n
	return null

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 60:
		shot("menu")
		main._on_mode_chosen("settings")
	if f == 80:
		st = _find(SettingsScreen)
		SettingsScreen._tab = 2
		st._build()
	if f == 100:
		shot("settings")
		st._ask_wipe()
	if f == 160:
		shot("confirm_wait")
	if f == 100 + 60 * 5 + 20:
		shot("confirm_ready")
		st._close_confirm()
		main.show_menu()
		main._on_mode_chosen("shop")
	if f == 460:
		shop = _find(ShopScreen)
		shop._select(3)
	if f == 560:
		shot("shop_chests")
		for j in shop._offers.size():
			if shop._offers[j] is Dictionary and shop._offers[j].get("series", "") == "ice":
				shop._open_offer(j)
	if f == 600:
		shot("ice_card")
		for j in shop._offers.size():
			if shop._offers[j] is Dictionary and shop._offers[j].get("series", "") == "ice":
				shop._open_chest(shop._offers[j])
	if f == 660:
		shot("ice_open")
		return true
	return false
