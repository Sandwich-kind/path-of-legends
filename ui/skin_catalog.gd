class_name SkinCatalog
extends CanvasLayer
# ---------- Каталог обликов легенды ----------
# Открывается кнопкой «Облик» на выборе легенды и в Книге легенд. Слева направо —
# обычный вид и облики серий; полученные можно выбрать, закрытые — силуэт и подсказка,
# где их взять.

signal closed

var hero := 0
var _vs := Vector2.ZERO
var _cards: Array = []

func _ready() -> void:
	layer = 15
	_vs = Config.screen(self)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.06, 0.92)
	dim.size = _vs
	add_child(dim)
	var t := Label.new()
	t.text = "Облики: %s" % String(Characters.LIST[hero]["name"]).capitalize()
	t.size = Vector2(_vs.x, 60)
	t.position = Vector2(0, 18)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 38)
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	add_child(t)
	var back := MainMenu.make_button(self, "Готово", Vector2(_vs.x / 2 - 110, _vs.y - 90), Vector2(220, 66), 26)
	back.pressed.connect(func():
		closed.emit()
		queue_free())
	back.grab_focus.call_deferred()
	_build()

func _build() -> void:
	for c in _cards:
		c.queue_free()
	_cards.clear()
	var list: Array = [{"id": "", "name": "Обычный", "series": ""}] + Skins.for_hero(hero)
	var n := list.size()
	var cw := minf(240.0, (_vs.x - 80.0) / n - 16.0)
	var x0 := (_vs.x - n * (cw + 16.0) + 16.0) / 2.0
	var cur := Skins.selected(hero)
	for i in n:
		var s: Dictionary = list[i]
		var id: String = s["id"]
		var have := id == "" or Skins.owned(id)
		var card := Panel.new()
		var st := StyleBoxFlat.new()
		var sc: Color = Skins.SERIES[s["series"]]["color"] if s["series"] != "" else Color(0.8, 0.75, 0.6)
		st.bg_color = Color(0.12, 0.10, 0.14, 0.95)
		st.border_color = sc if id == cur else sc.darkened(0.55)
		st.set_border_width_all(5 if id == cur else 2)
		st.set_corner_radius_all(12)
		card.add_theme_stylebox_override("panel", st)
		card.position = Vector2(x0 + i * (cw + 16.0), 100)
		card.size = Vector2(cw, _vs.y - 210)
		add_child(card)
		_cards.append(card)
		HeroFigure.draw(card, Vector2(cw / 2, card.size.y - 150), 3.2, hero, Color(0, 0, 0, 0), 1, not have, id)
		var nm := Label.new()
		nm.text = s["name"]
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.size = Vector2(cw - 16, 56)
		nm.position = Vector2(8, 10)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.add_theme_font_size_override("font_size", 20)
		nm.add_theme_color_override("font_color", sc.lightened(0.3))
		card.add_child(nm)
		var sub := Label.new()
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.text = (Skins.SERIES[s["series"]]["name"] if s["series"] != "" else "Исходный вид") if have else Skins.how_to_get(id)
		sub.size = Vector2(cw - 16, 60)
		sub.position = Vector2(8, card.size.y - 132)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_font_size_override("font_size", 15)
		sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		card.add_child(sub)
		var b := MainMenu.make_button(card, "", Vector2(14, card.size.y - 66), Vector2(cw - 28, 52), 20)
		if not have:
			b.text = "Закрыт"
			b.disabled = true
		elif id == cur:
			b.text = "Выбран"
			b.disabled = true
		else:
			b.text = "Выбрать"
			b.pressed.connect(func():
				Skins.select(hero, id)
				_build())
