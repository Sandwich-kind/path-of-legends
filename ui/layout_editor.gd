class_name LayoutEditor
extends CanvasLayer
# ---------- Редактор экранных кнопок ----------
# Кнопки можно перетащить пальцем в любое место и поменять размер выбранной (−/+).
# Своя раскладка — отдельно для одиночной игры и для каждого игрока Дуэли.
# «Сбросить» возвращает расположение и размер всех кнопок к исходным.

signal closed

const SIDES := ["solo", "left", "right"]
const SIDE_NAMES := ["Один", "Дуэль: игрок 1", "Дуэль: игрок 2"]
const NAMES := {"a1": "1", "a2": "2", "a3": "3", "ult": "Ульта", "reload": "R", "shoot": "Атака", "jump": "Прыжок",
		"dpad": "Крестовина", "stick": "Стик"}

var _vs := Vector2.ZERO
var _side := "solo"
var _stick := false
var _items := {}          # ключ -> {"node": Panel, "base": Rect2 (исходный), "scale": float}
var _sel := ""
var _drag := ""
var _grab := Vector2.ZERO
var _layer: Control
var _tabs: Array = []
var _size_lbl: Label
var _hint: Label

func _ready() -> void:
	# поверх того окна, из которого открыт: в бою настройки — уже на 21-м слое (над паузой),
	# и редактор на 20-м оказывался под ними — его не было видно и кнопки не двигались
	var host := get_parent() as CanvasLayer
	layer = maxi(20, host.layer + 1) if host else 20
	_vs = Config.screen(self)
	_stick = TouchControls.use_stick()
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.09, 0.96)
	bg.size = _vs
	add_child(bg)
	for x in range(0, int(_vs.x), 60):                 # сетка, чтобы было легче выравнивать
		var l := ColorRect.new()
		l.color = Color(1, 1, 1, 0.04)
		l.position = Vector2(x, 0)
		l.size = Vector2(1, _vs.y)
		add_child(l)
	_layer = Control.new()
	_layer.size = _vs
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_layer)
	for i in 3:
		var t := _button(SIDE_NAMES[i], Vector2(20 + i * 230, 16), Vector2(220, 50), 20)
		t.pressed.connect(_load.bind(SIDES[i]))
		_tabs.append(t)
	var reset := _button("Сбросить всё", Vector2(_vs.x - 430, 16), Vector2(200, 50), 20)
	reset.pressed.connect(_reset)
	var done := _button("Готово", Vector2(_vs.x - 220, 16), Vector2(200, 50), 22)
	done.pressed.connect(_done)
	var minus := _button("−", Vector2(_vs.x / 2 - 170, 80), Vector2(60, 50), 28)
	minus.pressed.connect(_resize.bind(-0.1))
	_size_lbl = Label.new()
	_size_lbl.position = Vector2(_vs.x / 2 - 105, 80)
	_size_lbl.size = Vector2(210, 50)
	_size_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_size_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_size_lbl.add_theme_font_size_override("font_size", 19)
	add_child(_size_lbl)
	var plus := _button("+", Vector2(_vs.x / 2 + 110, 80), Vector2(60, 50), 28)
	plus.pressed.connect(_resize.bind(0.1))
	_hint = Label.new()
	_hint.text = "Перетащи кнопку пальцем. Нажми на кнопку и меняй её размер: − и +."
	_hint.position = Vector2(0, 136)
	_hint.size = Vector2(_vs.x, 30)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	add_child(_hint)
	_load("solo")

func _button(t: String, pos: Vector2, size: Vector2, font: int) -> Button:
	var b := Button.new()
	b.text = t
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", font)
	add_child(b)
	return b

# Показать раскладку одной стороны: исходные места + своя раскладка поверх
func _load(side: String) -> void:
	if not _items.is_empty():
		_save()                                   # переключение вкладки — раскладка не теряется
	_side = side
	for i in 3:
		_tabs[i].modulate = Color(1.3, 1.15, 0.7) if SIDES[i] == side else Color(0.8, 0.8, 0.8)
	for k in _items:
		_items[k]["node"].queue_free()
	_items.clear()
	_sel = ""
	var base := TouchControls.geometry(_vs, side, _stick, false)
	var cust := TouchControls.custom(side)
	var rects := {}
	for a in base["actions"]:
		rects[a[0]] = Rect2(Vector2(a[1], a[2]), a[4])
	if base.has("dpad"):
		rects["dpad"] = base["dpad"]
	if base.has("stick"):
		rects["stick"] = base["stick"]
	for k in rects:
		var r: Rect2 = rects[k]
		var sc := 1.0
		var at := r.get_center()
		if cust.has(k):
			var c: Array = cust[k]
			sc = clampf(float(c[2]), 0.5, 2.0)
			at = Vector2(float(c[0]) * _vs.x, float(c[1]) * _vs.y)
		var node := Panel.new()
		var st := StyleBoxFlat.new()
		st.bg_color = Color(1, 1, 1, 0.14)
		st.border_color = Color(1, 1, 1, 0.5)
		st.set_border_width_all(2)
		st.set_corner_radius_all(10)
		node.add_theme_stylebox_override("panel", st)
		node.mouse_filter = Control.MOUSE_FILTER_STOP
		var lbl := Label.new()
		lbl.text = NAMES.get(k, k)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(lbl)
		_layer.add_child(node)
		_items[k] = {"node": node, "base": r, "scale": sc, "label": lbl}
		_place(k, at)
		node.gui_input.connect(_on_input.bind(k))
	_select("")

func _place(k: String, center: Vector2) -> void:
	var it: Dictionary = _items[k]
	var sz: Vector2 = (it["base"] as Rect2).size * float(it["scale"])
	var pos := (center - sz / 2.0).clamp(Vector2(0, 0), (_vs - sz).max(Vector2.ZERO))
	var node: Panel = it["node"]
	node.position = pos
	node.size = sz
	(it["label"] as Label).size = sz

func _center(k: String) -> Vector2:
	var node: Panel = _items[k]["node"]
	return node.position + node.size / 2.0

func _on_input(ev: InputEvent, k: String) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_select(k)
			_drag = k
			_grab = ev.global_position - _center(k)
		else:
			_drag = ""
	elif ev is InputEventMouseMotion and _drag == k:
		_place(k, ev.global_position - _grab)

func _select(k: String) -> void:
	_sel = k
	for key in _items:
		var st: StyleBoxFlat = (_items[key]["node"] as Panel).get_theme_stylebox("panel")
		st.border_color = Color(1.0, 0.8, 0.3) if key == k else Color(1, 1, 1, 0.5)
		st.bg_color = Color(1.0, 0.8, 0.3, 0.22) if key == k else Color(1, 1, 1, 0.14)
	_size_lbl.text = "Выбери кнопку" if k == "" else "%s: %d%%" % [NAMES.get(k, k), int(round(float(_items[k]["scale"]) * 100.0))]

func _resize(d: float) -> void:
	if _sel == "":
		return
	var c := _center(_sel)
	_items[_sel]["scale"] = clampf(snappedf(float(_items[_sel]["scale"]) + d, 0.1), 0.5, 2.0)
	_place(_sel, c)
	_select(_sel)

func _reset() -> void:
	for k in _items:
		_items[k]["node"].queue_free()
	_items.clear()
	TouchControls.set_custom(_side, {})
	_load(_side)

func _save() -> void:
	var d := {}
	for k in _items:
		var it: Dictionary = _items[k]
		var c := _center(k)
		var base_c: Vector2 = (it["base"] as Rect2).get_center()
		if c.distance_to(base_c) > 2.0 or absf(float(it["scale"]) - 1.0) > 0.01:
			d[k] = [c.x / _vs.x, c.y / _vs.y, float(it["scale"])]
	TouchControls.set_custom(_side, d)

func _done() -> void:
	_save()
	closed.emit()
	queue_free()
