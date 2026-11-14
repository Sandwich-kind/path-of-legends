class_name SettingsScreen
extends CanvasLayer
# ---------- Настройки (общие для всей игры, user://settings.json) ----------
# Вкладки: «Кнопки» (экранные кнопки поверх игры или полосой снизу, стик или крестовина,
# прозрачность), «Игра и звук» (числа урона, тряска, качество эффектов, громкость) и «Прогресс» — там
# же прячутся кнопки проверки главного меню, и там
# кнопка «Очистить прогресс»: после нажатия ещё 5 секунд, чтобы передумать, и только
# потом её можно подтвердить. Настройки при очистке не сбрасываются.

signal back_pressed

var overlay := false
var _vs := Vector2.ZERO
var _box: Control

const TABS := ["Кнопки", "Игра и звук", "Прогресс"]
const WIPE_WAIT := 5.0             # столько секунд нужно подумать, прежде чем подтвердить очистку
static var _tab := 0               # открытая вкладка запоминается, пока игра запущена
var _editor: LayoutEditor          # открытый редактор расположения кнопок
var _confirm: Control              # окошко «Точно очистить весь прогресс?»
var _yes: Button
var _wait := 0.0

func _ready() -> void:
	_vs = Config.screen(self)
	if overlay:
		var dim := ColorRect.new()
		dim.color = Color(0.05, 0.04, 0.05, 0.92)
		dim.size = _vs
		add_child(dim)
	else:
		StorySlots.backdrop(self, _vs)
	var t := Label.new()
	t.text = "Настройки"
	t.size = Vector2(_vs.x, 60)
	t.position = Vector2(0, 16)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 42)
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	t.add_theme_constant_override("outline_size", 10)
	t.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.08))
	add_child(t)
	var back := Button.new()
	back.text = "Назад"
	back.position = Vector2(24, 20)
	back.size = Vector2(150, 54)
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	PadGlyph.attach(back, "B")
	_build()

func _unhandled_input(event: InputEvent) -> void:
	if overlay and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("p1_menu")):
		get_viewport().set_input_as_handled()
		if not handle_back():
			back_pressed.emit()

# B на геймпаде: сначала закрывается окошко подтверждения
func handle_back() -> bool:
	if _editor and is_instance_valid(_editor) and not _editor.is_queued_for_deletion():
		_editor._done()                   # «Назад» в редакторе кнопок — сохранить и вернуться в настройки
		return true
	if _confirm and is_instance_valid(_confirm):
		_close_confirm()
		return true
	return false

func _process(delta: float) -> void:
	if _confirm == null or not is_instance_valid(_confirm) or _wait <= 0.0:
		return
	_wait -= delta
	if _wait > 0.0:
		_yes.text = "Очистить (%d)" % ceili(_wait)
	else:
		_yes.text = "Да, очистить всё"
		_yes.disabled = false

func _build() -> void:
	if _box:
		_box.queue_free()
	_box = Panel.new()
	_box.size = Vector2(minf(820.0, _vs.x - 60), 520)
	_box.position = Vector2((_vs.x - _box.size.x) / 2, 96)
	_box.add_theme_stylebox_override("panel", StoryHud.box(Color(0.10, 0.08, 0.07, 0.95), Color(0.8, 0.6, 0.3), 14, 3))
	add_child(_box)
	var s := StorySettings.load_all()
	var w := _box.size.x
	# вкладки
	var tw := (w - 60) / TABS.size()
	for i in TABS.size():
		var tb := Button.new()
		tb.text = TABS[i]
		tb.position = Vector2(30 + i * tw, 16)
		tb.size = Vector2(tw - 10, 46)
		tb.add_theme_font_size_override("font_size", 19)
		tb.modulate = Color(1.25, 1.15, 0.8) if i == _tab else Color(0.7, 0.7, 0.7)
		var ti := i
		tb.pressed.connect(func():
			_tab = ti
			_build()
			_refocus(TABS[ti]))
		_box.add_child(tb)
	var line := ColorRect.new()
	line.color = Color(0.8, 0.6, 0.3, 0.5)
	line.position = Vector2(30, 70)
	line.size = Vector2(w - 60, 2)
	_box.add_child(line)
	var y := 90.0
	match _tab:
		0:
			_buttons_tab(s, y)
		1:
			_game_tab(s, y)
		_:
			_progress_tab(y)

func _buttons_tab(s: Dictionary, y: float) -> void:
	var w := _box.size.x
	_section("Экранные кнопки (телефон)", y)
	var lay := Button.new()
	lay.text = "Расположение кнопок…"
	lay.position = Vector2(w - 290, y - 6)
	lay.size = Vector2(260, 40)
	lay.add_theme_font_size_override("font_size", 17)
	lay.pressed.connect(func():
		_editor = LayoutEditor.new()
		add_child(_editor))
	_box.add_child(lay)
	y += 44.0
	y = _choice("Где кнопки", "touch_panel", [[false, "На экране"], [true, "Полоса снизу"]], s, y)
	y = _choice("Движение", "touch_move", [["stick", "Виртуальный стик"], ["dpad", "Крестовина"]], s, y)
	y = _slider("Видимость кнопок", "touch_alpha", 20, 100, s, y)
	y = _slider("Размер крестовины, %", "dpad_size", 60, 160, s, y)
	var note := _label("Размер — для режима «Крестовина». Изменения — со следующего боя (в Истории — после закрытия меню). С контроллером экранные кнопки прячутся.",
			Vector2(30, y), 14, Color(1, 1, 1, 0.55))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.update_minimum_size()
	note.size = Vector2(w - 60, 40)

func _game_tab(s: Dictionary, y: float) -> void:
	var w := _box.size.x
	_section("Игра", y)
	y += 40.0
	# флажки в два столбца
	var rows := [["damage_numbers", "Показывать числа урона"], ["screen_shake", "Тряска экрана"],
			["touch_on_pc", "Экранные кнопки на компьютере"]]
	for i in rows.size():
		var row: Array = rows[i]
		var cb := CheckButton.new()
		cb.text = row[1]
		cb.button_pressed = bool(s.get(row[0], true))
		cb.position = Vector2(30 + (i % 2) * (w / 2 - 10), y + (i / 2) * 42.0)
		cb.size = Vector2(w / 2 - 40, 40)
		cb.add_theme_font_size_override("font_size", 17)
		var key: String = row[0]
		cb.toggled.connect(func(on: bool): StorySettings.set_value(key, on))
		_box.add_child(cb)
	y += 42.0 * ceili(rows.size() / 2.0) + 6.0
	# упрощённые эффекты — для слабых телефонов: без пыли, дыма, обломков и конфетти, искр меньше
	if not s.has("fx_lite"):
		s["fx_lite"] = false
	y = _choice("Эффекты", "fx_lite", [[false, "Полные"], [true, "Упрощённые"]], s, y) + 6.0
	_section("Звук", y)
	y += 40.0
	y = _slider("Музыка", "music", 0, 100, s, y)
	y = _slider("Звуки", "sfx", 0, 100, s, y)

# ---------- Прогресс: очистка ----------
func _progress_tab(y: float) -> void:
	var w := _box.size.x
	_section("Прогресс", y)
	y += 40.0
	var heroes := 0
	for i in Characters.LIST.size():
		if Characters.unlocked(i) and not (Characters.LIST[i]["name"] in Characters.TEST_NAMES):
			heroes += 1
	var total := Characters.LIST.size() - Characters.TEST_NAMES.size()
	var info := _label("Золото: %d    ·    Легенд открыто: %d из %d    ·    Обликов: %d" % [Save.gold(), heroes, total, (Save.data.get("skins", []) as Array).size()],
			Vector2(30, y), 18)
	info.name = "Info"
	y += 44.0
	var t := _label("Очистка удалит всё: золото, купленных и открытых легенд, МЕГА, облики, прогресс Арены, " +
			"открытые карты, бестиарий и все три ячейки Истории. Настройки (кнопки, звук) останутся. Отменить очистку нельзя.",
			Vector2(30, y), 17, Color(1, 0.95, 0.85, 0.8))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.update_minimum_size()
	t.size = Vector2(w - 60, 80)
	y += 110.0
	var b := Button.new()
	b.text = "Очистить прогресс"
	b.size = Vector2(340, 60)
	b.position = Vector2((w - b.size.x) / 2, y)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color(1.0, 0.62, 0.55))
	b.pressed.connect(_ask_wipe)
	_box.add_child(b)
	if overlay:
		b.disabled = true                 # посреди боя прогресс не трогаем
		var n := _label("Очистить прогресс можно в настройках главного меню.", Vector2(30, y + 74), 15, Color(1, 1, 1, 0.55))
		n.size = Vector2(w - 60, 30)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# кнопки проверки внизу главного меню: показать или спрятать (по умолчанию скрыты)
	y += 112.0
	var s := StorySettings.load_all()
	if not s.has("debug_buttons"):
		s["debug_buttons"] = false
	y = _choice("Кнопки проверки", "debug_buttons", [[false, "Скрыть"], [true, "Показывать"]], s, y)
	var dh := _label("Кнопки внизу главного меню, «начать с любой волны» на Арене и «Открыть всё» в бестиарии.",
			Vector2(30, y - 4), 14, Color(1, 1, 1, 0.55))
	dh.size = Vector2(w - 60, 22)

func _ask_wipe() -> void:
	_close_confirm()
	_confirm = Control.new()
	_confirm.size = _vs
	_confirm.add_to_group("pad_scope")        # геймпад выбирает только кнопки окошка
	add_child(_confirm)
	var dim := ColorRect.new()
	dim.size = _vs
	dim.color = Color(0, 0, 0, 0.65)
	_confirm.add_child(dim)
	var p := Panel.new()
	p.size = Vector2(minf(640.0, _vs.x - 40), 300)
	p.position = (_vs - p.size) / 2
	p.add_theme_stylebox_override("panel", StoryHud.box(Color(0.14, 0.06, 0.05, 0.98), Color(0.95, 0.40, 0.30), 14, 3))
	_confirm.add_child(p)
	var t := Label.new()
	t.text = "Точно очистить весь прогресс?"
	t.size = Vector2(p.size.x, 50)
	t.position = Vector2(0, 18)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", Color(1.0, 0.75, 0.6))
	p.add_child(t)
	var l := Label.new()
	l.text = "Золото, легенды, облики, Арена, бестиарий и История удалятся навсегда. Подумай пару секунд — кнопка станет доступна через %d с." % int(WIPE_WAIT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size = Vector2(p.size.x - 60, 100)
	l.position = Vector2(30, 76)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(1, 0.95, 0.88))
	p.add_child(l)
	var bw := (p.size.x - 90) / 2
	_yes = Button.new()
	_yes.size = Vector2(bw, 64)
	_yes.position = Vector2(30, 200)
	_yes.add_theme_font_size_override("font_size", 22)
	_yes.add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))
	_yes.disabled = true
	_yes.pressed.connect(_wipe)
	p.add_child(_yes)
	var no := Button.new()
	no.text = "Отмена"
	no.size = Vector2(bw, 64)
	no.position = Vector2(60 + bw, 200)
	no.add_theme_font_size_override("font_size", 22)
	no.pressed.connect(_close_confirm)
	p.add_child(no)
	_wait = WIPE_WAIT
	_yes.text = "Очистить (%d)" % int(WIPE_WAIT)
	no.grab_focus.call_deferred()

func _close_confirm() -> void:
	if _confirm and is_instance_valid(_confirm):
		_confirm.remove_from_group("pad_scope")
		_confirm.queue_free()
	_confirm = null
	_wait = 0.0

func _wipe() -> void:
	if _wait > 0.0:
		return
	Save.wipe_all()
	_close_confirm()
	_build()
	var done := _label("Прогресс очищен.", Vector2(0, _box.size.y - 60), 22, Color(0.6, 1.0, 0.6))
	done.size = Vector2(_box.size.x, 40)
	done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_refocus("Очистить прогресс")

func _section(t: String, y: float) -> void:
	_label(t, Vector2(30, y), 20, Color(1.0, 0.85, 0.45))

func _label(t: String, pos: Vector2, size: int, c := Color(1, 0.95, 0.85)) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(l)
	return l

# Выбор из вариантов кнопками
func _choice(title: String, key: String, opts: Array, s: Dictionary, y: float) -> float:
	_label(title, Vector2(30, y + 8), 18)
	var x := 260.0
	for o in opts:
		var b := Button.new()
		b.text = o[1]
		b.position = Vector2(x, y)
		b.size = Vector2(240, 42)
		b.add_theme_font_size_override("font_size", 17)
		var on: bool = s.get(key) == o[0]
		b.modulate = Color(1.25, 1.15, 0.8) if on else Color(0.7, 0.7, 0.7)
		var v = o[0]
		b.pressed.connect(func():
			StorySettings.set_value(key, v)
			Fx.load_setting()
			_build()
			_refocus(o[1]))
		_box.add_child(b)
		x += 252.0
	return y + 50.0

func _refocus(text: String) -> void:
	await get_tree().process_frame
	for c in _box.get_children():
		if c is Button and c.text == text:
			c.grab_focus()

func _slider(title: String, key: String, lo: float, hi: float, s: Dictionary, y: float) -> float:
	_label(title, Vector2(30, y + 6), 18)
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = 5
	sl.value = float(s.get(key, hi))
	sl.position = Vector2(260, y + 10)
	sl.size = Vector2(_box.size.x - 380, 30)
	var val := _label(str(int(sl.value)), Vector2(_box.size.x - 100, y + 6), 18)
	sl.value_changed.connect(func(v: float):
		StorySettings.set_value(key, v)
		val.text = str(int(v)))
	_box.add_child(sl)
	return y + 46.0
