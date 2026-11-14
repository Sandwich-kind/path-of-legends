class_name MainMenu
extends CanvasLayer
# Главное меню: пиксельная заставка (поле, река, лес, гора) и выбор режима.

signal mode_chosen(mode: String)   # "story", "duel", "arena", "shop", "inventory", "bestiary"

var _scene: MenuScene
var _scale := 4.0
var _vs := Vector2.ZERO
var _coins: CoinBadge

func _ready() -> void:
	_vs = Config.screen(self)
	# живая заставка: пейзаж со сменой дня и ночи, птицами, рекой и ветром.
	# Обычно она общая (слой под экранами в main.gd) и не сбрасывается при переходах
	if MenuScene.reveal():
		_scene = MenuScene.shared
	else:
		var scene := MenuScene.new()
		scene.setup(_vs)
		add_child(scene)
		_scene = scene
	# затемнение под надписями, чтобы их было лучше видно
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.18)
	shade.size = _vs
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var title := Label.new()
	title.text = "PATH OF LEGENDS"
	title.size = Vector2(_vs.x, 100)
	title.position = Vector2(0, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	title.add_theme_constant_override("outline_size", 16)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.08))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	add_child(title)

	# режимы — крупно, магазин и инвентарь — под ними
	var cx := _vs.x / 2
	var bs := make_button(self, "История", Vector2(cx - 330, 186), Vector2(660, 92), 40)
	bs.pressed.connect(func(): mode_chosen.emit("story"))
	bs.modulate = Color(1.12, 1.05, 0.9)
	var b1 := make_button(self, "Дуэль", Vector2(cx - 330, 292), Vector2(320, 74), 32)
	b1.pressed.connect(func(): mode_chosen.emit("duel"))
	var b2 := make_button(self, "Арена", Vector2(cx + 10, 292), Vector2(320, 74), 32)
	b2.pressed.connect(func(): mode_chosen.emit("arena"))
	var b3 := make_button(self, "Магазин", Vector2(cx - 330, 380), Vector2(320, 64), 26)
	b3.pressed.connect(func(): mode_chosen.emit("shop"))
	var b4 := make_button(self, "Инвентарь", Vector2(cx + 10, 380), Vector2(320, 64), 26)
	b4.pressed.connect(func(): mode_chosen.emit("inventory"))
	var b5 := make_button(self, "Бестиарий", Vector2(cx - 330, 458), Vector2(213, 60), 22)
	b5.pressed.connect(func(): mode_chosen.emit("bestiary"))
	var b6 := make_button(self, "Управление", Vector2(cx - 106, 458), Vector2(213, 60), 22)
	b6.pressed.connect(func(): mode_chosen.emit("controls"))
	var b7 := make_button(self, "Настройки", Vector2(cx + 117, 458), Vector2(213, 60), 22)
	b7.pressed.connect(func(): mode_chosen.emit("settings"))
	_coins = CoinBadge.corner(self)
	# кнопки для проверки (одной строкой внизу): по умолчанию скрыты, включаются в Настройках → «Прогресс»
	if StorySettings.get_value("debug_buttons") != true:
		return
	var dbg := [["Добавить 100 золотых", func(b: Button):
				Save.add_gold(100)
				_coins.refresh()],
			["Очистить прогресс", func(b: Button):
				Save.reset()                   # золото, арена и бестиарий — всё заново
				_coins.refresh()
				b.text = "Прогресс очищен"],
			["Открыть все арены", func(b: Button):
				Save.unlock_all_stages()
				b.text = "Арены открыты"],
			["Открыть всех легенд", func(b: Button):
				Save.unlock_all_heroes()
				b.text = "Легенды открыты"],
			["Удалить все облики", func(b: Button):
				Save.clear_skins()
				b.text = "Облики удалены"]]
	var gap := 10.0
	var bw := minf(260.0, (_vs.x - 40 - gap * (dbg.size() - 1)) / dbg.size())
	for i in dbg.size():
		var d := make_button(self, dbg[i][0], Vector2(20 + i * (bw + gap), _vs.y - 70), Vector2(bw, 50), 17 if bw < 230 else 18)
		d.pressed.connect((dbg[i][1] as Callable).bind(d))

static func make_button(parent: Node, text: String, pos: Vector2, size: Vector2,
		font: int) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", font)
	parent.add_child(b)
	return b
