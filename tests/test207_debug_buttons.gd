extends SceneTree
# Кнопки проверки в главном меню («Добавить 100 золотых», «Открыть все арены» и другие)
# по умолчанию скрыты; включаются и выключаются в Настройках → «Прогресс», выбор сохраняется.
var main
var f := 0
var fails := 0
var saved
var setup: ArenaSetup

func _initialize() -> void:
	Save.load_game()
	saved = StorySettings.get_value("debug_buttons")
	if saved != null:                       # проверяем именно «как у нового игрока»: настройки ещё нет
		var s: Dictionary = StorySettings.load_all()
		s.erase("debug_buttons")
		StorySettings._cache = s
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _button(text: String) -> Button:
	for n in main.world.find_children("*", "Button", true, false):
		if (n as Button).text == text:
			return n
	return null

func _debug_count() -> int:
	var n := 0
	for t in ["Добавить 100 золотых", "Очистить прогресс", "Открыть все арены", "Открыть всех легенд", "Удалить все облики"]:
		if _button(t) != null:
			n += 1
	return n

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.show_menu()
	if f == 8:
		check(_debug_count() == 0 and _button("Настройки") != null, "main menu hides the check buttons by default")
		SettingsScreen._tab = 2
		main._on_mode_chosen("settings")
	if f == 14:
		check(_button("Показывать") != null and _button("Скрыть") != null, "Settings → Progress has the «Кнопки проверки» switch")
		if DisplayServer.get_name() != "headless" and OS.get_environment("SHOTS") == "1":
			root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/settings_debug.png")
		_button("Показывать").pressed.emit()
	if f == 18:
		check(StorySettings.get_value("debug_buttons") == true, "choice «Показывать» is saved")
		main.show_menu()
	if f == 22:
		check(_debug_count() == 5, "main menu: all 5 check buttons are shown")
		SettingsScreen._tab = 2
		main._on_mode_chosen("settings")
	if f == 28:
		_button("Скрыть").pressed.emit()
	if f == 32:
		main.show_menu()
	if f == 36:
		check(_debug_count() == 0, "«Скрыть» hides them again")
		main.show_arena_setup()
		for n in main.world.get_children():
			if n is ArenaSetup:
				setup = n
				n._pick_difficulty(false)
	if f == 130:
		check(setup != null and setup._any_lbl == null and _button("Новая игра") != null, "Arena setup: «start from any wave» is hidden too, the rest is in place")
		StorySettings.set_value("debug_buttons", true)
		main.show_arena_setup()
		for n in main.world.get_children():
			if n is ArenaSetup:
				setup = n
				n._pick_difficulty(false)
	if f == 230:
		check(setup != null and setup._any_lbl != null and _button("Старт") != null, "with check buttons shown, «start from any wave» is back")
		main._on_mode_chosen("bestiary")
	if f == 236:
		check(_button("Открыть\nвсё") != null, "bestiary: «Открыть всё» is shown with check buttons on")
		StorySettings.set_value("debug_buttons", false)
		main._on_mode_chosen("bestiary")
	if f == 242:
		check(_button("Открыть\nвсё") == null and _button("Назад") != null, "bestiary: «Открыть всё» is hidden by default")

		StorySettings.set_value("debug_buttons", saved if saved != null else false)
		SettingsScreen._tab = 0
		print("RESULT fails=", fails)
		return true
	return false
