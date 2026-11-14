extends SceneTree
# Расположение кнопок можно менять прямо в бою: пауза → Настройки → «Расположение кнопок…».
# Редактор открывается поверх окна настроек (раньше оказывался под ним), «Назад» закрывает
# сначала редактор, а после выхода из настроек экранные кнопки боя перестраиваются.
var main
var f := 0
var fails := 0
var pz: BattlePause
var st: SettingsScreen
var ed: LayoutEditor

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _find(cls, from: Node = null) -> Node:
	for n in (from if from else main.world).find_children("*", "", true, false):
		if is_instance_of(n, cls):
			return n
	return null

func _button(from: Node, text: String) -> Button:
	for n in from.find_children("*", "Button", true, false):
		if (n as Button).text == text:
			return n
	return null

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.sel = [0, 0]
		main.start_arena(false, 1)
	if f == 120:
		main.open_pause()
	if f == 124:
		pz = _find(BattlePause)
		check(pz != null and paused, "battle is paused, the pause window is open")
		SettingsScreen._tab = 0
		pz._settings()
	if f == 130:
		st = _find(SettingsScreen, pz)
		check(st != null and st.layer > pz.layer, "settings open above the pause window")
		_button(st, "Расположение кнопок…").pressed.emit()
	if f == 136:
		ed = _find(LayoutEditor, st)
		check(ed != null and ed.layer > st.layer, "button layout editor opens above the settings (layer %d over %d)" % [ed.layer if ed else -1, st.layer])
		check(ed != null and ed.can_process(), "the editor works while the battle is paused")
		check(ed != null and not ed._items.is_empty(), "the editor shows the buttons to drag (%d)" % (ed._items.size() if ed else 0))
		if DisplayServer.get_name() != "headless" and OS.get_environment("SHOTS") == "1":
			root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/layout_in_battle.png")
		# «Назад» (Esc / B на геймпаде) закрывает редактор, а не настройки
		check(st.handle_back(), "Back closes the editor first")
	if f == 142:
		check((ed == null or not is_instance_valid(ed)) and is_instance_valid(st), "editor closed, settings still open")
		st.back_pressed.emit()
	if f == 150:
		check(not is_instance_valid(st) and is_instance_valid(pz), "back to the pause window")
		var touch := get_nodes_in_group("touch_ui").size() + get_nodes_in_group("pad_ui").size()
		check(touch > 0, "battle controls are rebuilt after settings (%d nodes)" % touch)
		pz.resume()
	if f == 160:
		check(not paused, "battle goes on")
		print("RESULT fails=", fails)
		return true
	return false
