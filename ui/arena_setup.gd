class_name ArenaSetup
extends CanvasLayer
# Подготовка Арены (тоже свиток): сначала режим (обычный, сложный, Босс-раш), потом
# в одиночку или вдвоём, новая игра или продолжение с сохранённой волны.
# Затем — выбор легенд на колоннах. Сложный режим и Босс-раш открываются после
# победы над Странником (100-я волна обычного режима).

signal start_pressed(coop: bool, wave: int, sel: Array, rules: String)
signal back_pressed

const INK := ScrollPaper.INK

var coop := false
var sel := [0, 1]
var rules := "normal"
# Сначала — сложность (обычная / сложная), потом — волны или Босс-раш.
# rules для ArenaMode: "normal", "hard", "rush" (обычный Босс-раш), "hard_rush"
var hard := false
var rush := false
var _step := "difficulty"
var _pw := 0.0
const WAVES_DESC := ["100 волн — от лесной деревни до Дворца Бездны, где ждёт Странник.",
		"Те же 100 волн: враги сильнее и с особенностями, у боссов — новые приёмы и фазы."]
const RUSH_DESC := ["Только боссы и мини-боссы — один за другим, без обычных волн.",
		"Все боссы и мини-боссы сложного режима подряд — с новыми приёмами и фазами."]
var _rule_btns: Array = []
var _rule_lbl: Label

var _vs := Vector2.ZERO
var _paper: ScrollPaper
var _mode_btns: Array = []
var _cont_btn: Button
var _progress_lbl: Label
var _picker: LegendPicker
var _back: Button
var _wave := 1
var _any_wave := 1
var _any_lbl: Label

func _ready() -> void:
	_vs = Config.screen(self)
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.11, 0.08)
	bg.size = _vs
	add_child(bg)
	for i in int(_vs.y / 54.0) + 1:
		var plank := ColorRect.new()
		plank.color = Color(0.2, 0.13, 0.09) if i % 2 == 0 else Color(0.18, 0.12, 0.08)
		plank.position = Vector2(0, i * 54.0)
		plank.size = Vector2(_vs.x, 52)
		add_child(plank)
	_paper = ScrollPaper.new()
	var pw := minf(780.0, _vs.x - 300.0)
	_paper.paper_rect = Rect2((_vs.x - pw) / 2, 34, pw, _vs.y - 68)
	add_child(_paper)
	_pw = pw - 40.0
	hard = rules.begins_with("hard") and Save.arena_done()
	rush = rules.ends_with("rush")
	_fill_difficulty(_paper.content, _pw)
	_back = MainMenu.make_button(self, "Назад", Vector2(20, 20), Vector2(130, 55), 26)
	_back.pressed.connect(_on_back)
	CoinBadge.corner(self)

func _label(parent: Control, text: String, pos: Vector2, size: Vector2, font: int) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # перенос строк — до размера
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", INK)
	l.add_theme_constant_override("outline_size", 0)
	parent.add_child(l)
	return l

# Шаг 1: сложность
func _fill_difficulty(c: Control, w: float) -> void:
	_step = "difficulty"
	_label(c, "Арена", Vector2(0, 6), Vector2(w, 50), 38)
	_label(c, "Выбери сложность", Vector2(0, 66), Vector2(w, 36), 26)
	var names := ["Обычная", "Сложная"]
	for i in 2:
		var x := w / 2 - 330 + i * 350
		var b := MainMenu.make_button(c, names[i], Vector2(x, 120), Vector2(310, 96), 34)
		b.pressed.connect(_pick_difficulty.bind(i == 1))
		var txt: String = WAVES_DESC[i]
		if i == 1 and not Save.arena_done():
			b.disabled = true
			_lock_icon(b, Vector2(278, 48))
			txt = "Откроется после победы над Странником (волна 100)."
		elif i == 1:
			txt += " Золото ×1,5.\nПройдёшь до конца — откроется сложный Босс-раш."
		else:
			txt += "\nПосле победы над Странником откроются Босс-раш и сложный режим."
		_label(c, txt, Vector2(x - 10, 228), Vector2(330, 150), 16)
		if (i == 1) == hard and not b.disabled:
			b.set_meta("pad_default", true)
	_paper.content_height = 400.0

func _pick_difficulty(h: bool) -> void:
	hard = h
	_switch(func(): _fill_mode(_paper.content, _pw))

# Сменить содержимое свитка: свернуть, переложить, развернуть
func _switch(fill: Callable) -> void:
	_paper.rolled_up.connect(func():
		for ch in _paper.content.get_children():
			_paper.content.remove_child(ch)
			ch.queue_free()
		_rule_btns.clear()
		_mode_btns.clear()
		_any_lbl = null
		fill.call()
		_paper.scroll_to(0.0, false)
		_paper.unroll(), CONNECT_ONE_SHOT)
	_paper.roll_up()

func _rush_open() -> bool:
	return Save.hard_done() if hard else Save.arena_done()

# Шаг 2: волны или Босс-раш, один или вдвоём, продолжить или заново
func _fill_mode(c: Control, w: float) -> void:
	_step = "mode"
	var y := 6.0
	_label(c, "Арена · " + ("Сложная" if hard else "Обычная"), Vector2(0, y), Vector2(w, 50), 38)
	y += 56.0
	# 1) режим  2) один или вдвоём  3) продолжить или заново
	var mnames := ["Волны", "Босс-раш"]
	for i in 2:
		var rb := MainMenu.make_button(c, mnames[i], Vector2(w / 2 - 250 + i * 260, y), Vector2(240, 64), 26)
		rb.pressed.connect(_set_rush.bind(i == 1))
		if i == 1 and not _rush_open():
			rb.disabled = true
			_lock_icon(rb, Vector2(214, 32))
		_rule_btns.append(rb)
	y += 72.0
	_rule_lbl = _label(c, "", Vector2(10, y), Vector2(w - 20, 72), 16)
	y += 76.0
	var names := ["Один", "Вдвоём"]
	for i in 2:
		var b := MainMenu.make_button(c, names[i], Vector2(w / 2 - 250 + i * 260, y), Vector2(240, 64), 28)
		b.pressed.connect(_set_coop.bind(i == 1))
		_mode_btns.append(b)
	y += 70.0
	_label(c, "Вдвоём — на одном телефоне, в одной команде. Прогресс сохраняется после каждой волны.",
			Vector2(10, y), Vector2(w - 20, 26), 15).modulate = Color(1, 1, 1, 0.75)
	y += 32.0
	_progress_lbl = _label(c, "", Vector2(0, y), Vector2(w, 34), 20)
	y += 40.0
	var new_btn := MainMenu.make_button(c, "Новая игра", Vector2(w / 2 - 300, y), Vector2(280, 72), 28)
	new_btn.pressed.connect(_go.bind(false))
	new_btn.set_meta("pad_default", true)
	_cont_btn = MainMenu.make_button(c, "Продолжить", Vector2(w / 2 + 20, y), Vector2(280, 72), 28)
	_cont_btn.pressed.connect(_go.bind(true))
	y += 92.0
	# Проверка: начать с любой волны. Видна, только если в Настройках → «Прогресс» включены
	# «Кнопки проверки» (вместе со строкой кнопок главного меню); по умолчанию скрыта.
	if StorySettings.get_value("debug_buttons") == true:
		_label(c, "Проверка: начать с любой волны (временно)", Vector2(0, y), Vector2(w, 30), 18).modulate = Color(1, 1, 1, 0.8)
		y += 36.0
		var bx := w / 2 - 330.0
		for d in [-10, -1]:
			var bd := MainMenu.make_button(c, str(d), Vector2(bx, y), Vector2(70, 60), 24)
			bd.pressed.connect(_step_any.bind(d))
			bx += 78.0
		_any_lbl = _label(c, "", Vector2(bx - 10, y - 2), Vector2(170, 64), 18)
		bx += 158.0
		for d in [1, 10]:
			var bu := MainMenu.make_button(c, "+" + str(d), Vector2(bx, y), Vector2(70, 60), 24)
			bu.pressed.connect(_step_any.bind(d))
			bx += 78.0
		var go_any := MainMenu.make_button(c, "Старт", Vector2(bx + 8, y), Vector2(170, 60), 24)
		go_any.pressed.connect(_go_any)
		_step_any(0)
		y += 80.0
	_paper.content_height = y
	_set_rush(rush and _rush_open())

func _mode_key() -> String:
	return ArenaMode.key_for(rules, coop)

# Замочек на закрытой кнопке режима
func _lock_icon(b: Control, at: Vector2) -> void:
	var n := Node2D.new()
	n.position = at
	b.add_child(n)
	var arc := Line2D.new()
	var pts := PackedVector2Array()
	for i in 9:
		pts.append(Vector2.from_angle(PI + PI * i / 8.0) * 7.0 + Vector2(0, -3))
	arc.points = pts
	arc.width = 3.0
	arc.default_color = Color(0.75, 0.72, 0.66)
	n.add_child(arc)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-10, -3), Vector2(10, -3), Vector2(10, 11), Vector2(-10, 11)])
	body.color = Color(0.80, 0.68, 0.36)
	n.add_child(body)
	var hole := Polygon2D.new()
	hole.polygon = Util.circle(2.2, 8)
	hole.position = Vector2(0, 3)
	hole.color = Color(0.25, 0.18, 0.10)
	n.add_child(hole)

func _set_rush(r: bool) -> void:
	rush = r
	rules = ("hard" if hard else "normal") if not r else ("hard_rush" if hard else "rush")
	for i in 2:
		_rule_btns[i].modulate = Color(1.25, 1.12, 0.75) if (i == 1) == r else Color(0.85, 0.85, 0.85)
	var txt: String = (RUSH_DESC if r else WAVES_DESC)[1 if hard else 0]
	if not _rush_open():
		txt += "\nБосс-раш откроется после " + ("прохождения сложного режима до конца." if hard else "победы над Странником (волна 100).")
	_rule_lbl.text = txt
	_any_wave = ArenaMode.first_rush_wave() if r else 1
	_step_any(0)
	_set_coop(coop)

func _set_coop(v: bool) -> void:
	coop = v
	for i in 2:
		_mode_btns[i].modulate = Color(1.25, 1.12, 0.75) if (i == 1) == v else Color(0.85, 0.85, 0.85)
	var p := Save.arena_progress(_mode_key())
	if rules != "normal":
		_progress_lbl.text = "Сохранённой игры нет" if p.is_empty() else "Сохранено: %s %d" % ["бой с волны" if rush else "начало волны", int(p["wave"])]
		_cont_btn.disabled = p.is_empty()
		_cont_btn.text = "Продолжить" if p.is_empty() else "С волны %d" % int(p["wave"])
	elif p.is_empty() and Save.stage_unlocked(18) and not Save.stage_unlocked(19):
		# Предвестник уже повержен раньше (когда волн было 90) — сразу к новым землям
		_progress_lbl.text = "Новые земли: Ветряные холмы и Дворец Бездны"
		_cont_btn.disabled = false
		_cont_btn.text = "С волны 91"
	elif p.is_empty() and Save.stage_unlocked(16) and not Save.stage_unlocked(17):
		# Тёмный Лорд уже повержен раньше (когда волн было 80) — сразу к новой угрозе
		_progress_lbl.text = "Новая угроза: Летающие острова"
		_cont_btn.disabled = false
		_cont_btn.text = "С волны 81"
	elif p.is_empty() and Save.stage_unlocked(9) and not Save.stage_unlocked(11):
		# Колизей уже пройден раньше (когда волн было 50) — можно сразу в новые земли
		_progress_lbl.text = "Новые земли открыты: Жуткий лес и Болото"
		_cont_btn.disabled = false
		_cont_btn.text = "С волны 51"
	elif p.is_empty():
		_progress_lbl.text = "Сохранённой игры нет"
		_cont_btn.disabled = true
		_cont_btn.text = "Продолжить"
	else:
		_progress_lbl.text = "Сохранено: начало волны %d" % int(p["wave"])
		_cont_btn.disabled = false
		_cont_btn.text = "С волны %d" % int(p["wave"])

func _step_any(d: int) -> void:
	_any_wave = clampi(_any_wave + d, 1, ArenaMode.max_wave(hard))
	if rush:
		_any_wave = ArenaMode.rush_wave_from(_any_wave, signi(d), hard)
	if _any_lbl:
		var place: String = ArenaMode.STAGE_NAMES[ArenaMode.stage_for(_any_wave)]
		_any_lbl.text = "Волна %d\n%s" % [_any_wave, place]

func _go_any() -> void:
	_wave = _any_wave
	_paper.rolled_up.connect(_show_picker, CONNECT_ONE_SHOT)
	_paper.roll_up()

func _go(cont: bool) -> void:
	_wave = 1 if not rush else ArenaMode.first_rush_wave()
	if cont:
		var p := Save.arena_progress(_mode_key())
		var fresh := 1 if not rush else ArenaMode.first_rush_wave()
		if rules != "normal":
			pass
		elif Save.stage_unlocked(18) and not Save.stage_unlocked(19):
			fresh = 91
		elif Save.stage_unlocked(16) and not Save.stage_unlocked(17):
			fresh = 81
		elif Save.stage_unlocked(9) and not Save.stage_unlocked(11):
			fresh = 51
		_wave = int(p.get("wave", fresh))
		var ch: Array = p.get("chars", [])
		for i in mini(ch.size(), 2):
			sel[i] = int(ch[i])
	_paper.rolled_up.connect(_show_picker, CONNECT_ONE_SHOT)
	_paper.roll_up()

func _show_picker() -> void:
	_paper.visible = false
	_picker = LegendPicker.new()
	_picker.count = 2 if coop else 1
	_picker.sel = sel.duplicate()
	_picker.titles = ["Игрок 1", "Игрок 2"] if coop else ["Твоя легенда"]
	_picker.go_text = "НА АРЕНУ!" if _wave == 1 else "ВОЛНА %d!" % _wave
	_picker.style = "lift"
	add_child(_picker)
	_picker.rise()
	var started := [false]
	_picker.go_pressed.connect(func():
		if started[0]:
			return
		started[0] = true
		var chosen: Array = _picker.sel.duplicate()
		# подъёмники уезжают наверх — на арену
		_picker.lift_up(func(): start_pressed.emit(coop, _wave, chosen, rules)))
	_picker.back_pressed.connect(_on_back)
	_back.visible = false

func _on_back() -> void:
	if _picker:
		sel = _picker.sel.duplicate()
		_picker.queue_free()
		_picker = null
		_back.visible = true
		_paper.visible = true
		_paper.unroll()
		return
	if _step == "mode":
		_switch(func(): _fill_difficulty(_paper.content, _pw))
		return
	back_pressed.emit()
