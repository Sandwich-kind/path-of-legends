class_name RunShop
# ---------- Магазин на Арене ----------
# После каждой десятой волны (кроме последней и Босс-раша) герои попадают в проходную
# локацию «Магазин»: здесь нет боя, можно походить. На трёх прилавках — усиления до
# конца этого прохождения Арены, на четвёртом — дополнительная жизнь.
#   • Подойди к прилавку и нажми «атаку» — купишь (за монеты).
#   • Купил усиление — торговец ставит на прилавок другое (случайное, может и такое же —
#     эффект складывается). На каждом прилавке он меняет товар не больше двух раз.
#   • Жизнь продаётся на каждой остановке, но только одна: после покупки прилавок пуст.
#   • Вдвоём: каждый подходит и покупает себе сам (монеты общие, жизни — общие).
#   • Дверь справа — дальше в бой: когда все живые герои у двери.
# Усиления лежат в Player.run (сколько раз куплено) и сохраняются вместе с прогрессом Арены.

const POOL := {
	"hp":    {"name": "Крепкое здоровье", "short": "Здоровье +40", "price": 30, "col": Color(0.95, 0.35, 0.40), "letter": "З"},
	"speed": {"name": "Лёгкие ноги", "short": "Скорость бега +4%", "price": 22, "col": Color(0.45, 1.0, 0.55), "letter": "Б"},
	"rate":  {"name": "Быстрые руки", "short": "Скорость атаки +5%", "price": 28, "col": Color(1.0, 0.75, 0.25), "letter": "А"},
	"dmg":   {"name": "Острый глаз", "short": "Урон +5%", "price": 32, "col": Color(1.0, 0.35, 0.30), "letter": "У"},
	"armor": {"name": "Толстая кожа", "short": "Получаемый урон −5%", "price": 30, "col": Color(0.75, 0.75, 0.88), "letter": "Ж"},
	"regen": {"name": "Второе дыхание", "short": "Лечение +1 в секунду", "price": 26, "col": Color(0.55, 0.95, 0.75), "letter": "Д"},
	"cd":    {"name": "Ясная голова", "short": "Способности −6% перезарядки", "price": 30, "col": Color(0.40, 0.80, 1.0), "letter": "П"},
	"ult":   {"name": "Боевой задор", "short": "Ульта копится на 8% быстрее", "price": 26, "col": Color(0.95, 0.50, 1.0), "letter": "Ч"},
	"jump":  {"name": "Пружинистый шаг", "short": "Прыжок +5%", "price": 15, "col": Color(0.65, 0.95, 1.0), "letter": "Р"},
	"vamp":  {"name": "Жажда боя", "short": "Вампиризм: 2% урона в здоровье", "price": 34, "col": Color(0.80, 0.15, 0.25), "letter": "В"},
	"gold":  {"name": "Счастливая монета", "short": "Награда за волну +15%", "price": 20, "col": Color(1.0, 0.86, 0.30), "letter": "М"},
	"boss":  {"name": "Охотник на боссов", "short": "Урон по боссам +8%", "price": 30, "col": Color(1.0, 0.55, 0.20), "letter": "О"},
}
const LIFE_PRICE := 45
const RESTOCKS := 2

# Цена растёт с каждой остановкой (после 10-й волны — 1-я, после 20-й — 2-я…)
static func price(id: String, visit: int) -> int:
	return int(POOL[id]["price"]) + 6 * maxi(0, visit - 1)

static func life_price(visit: int) -> int:
	return LIFE_PRICE + 12 * maxi(0, visit - 1)

static func roll() -> String:
	var keys := POOL.keys()
	return keys[randi() % keys.size()]

# Купленное усиление — сразу в характеристики героя (или в счётчик Player.run)
static func apply(p: Player, id: String) -> void:
	p.run[id] = int(p.run.get(id, 0)) + 1
	match id:
		"hp":
			p.max_hp += 40
			p.heal(40)
		"speed":
			p.speed *= 1.04
		"rate":
			p.fire_cooldown *= 0.95
		"jump":
			p.jump_force *= 1.05
		"ult":
			p.ult_need *= 0.92

# Продолжение Арены с сохранения: усиления те же
static func restore(p: Player, run: Dictionary) -> void:
	for id in run:
		if POOL.has(id):
			for k in int(run[id]):
				apply(p, id)

# Множители, которые считаются в бою
static func dmg_mult(p: Player) -> float:
	return 1.0 + 0.05 * int(p.run.get("dmg", 0))

static func armor_mult(p: Player) -> float:
	return maxf(0.6, 1.0 - 0.05 * int(p.run.get("armor", 0)))

static func cd_mult(p: Player) -> float:
	return 1.0 + 0.06 * int(p.run.get("cd", 0))

static func boss_mult(p: Player) -> float:
	return 1.0 + 0.08 * int(p.run.get("boss", 0))

# Список усилений героя для паузы и подсказок: «Урон +5% ×2, Прыжок +5%»
static func describe(run: Dictionary) -> String:
	var parts: Array = []
	for id in run:
		if POOL.has(id):
			var n := int(run[id])
			parts.append(String(POOL[id]["short"]) + (" ×%d" % n if n > 1 else ""))
	return ", ".join(parts) if not parts.is_empty() else "пока нет"


# =====================================================================
# Локация «Магазин»: деревянная лавка под навесом, торговец за прилавком, фонари,
# полки с товарами. Слева герои входят, справа — дверь дальше в бой.
class Stop:
	const W := Colosseum.W
	const H := Colosseum.H
	const FLOOR_Y := Colosseum.FLOOR_Y
	const WALL := Colosseum.WALL
	const WOOD := Color(0.42, 0.27, 0.16)
	const PLANK := Color(0.52, 0.34, 0.20)

	static func build(world: Node) -> Dictionary:
		var cx := W / 2.0
		# задник: бревенчатая стена с досками и окнами
		var back := Polygon2D.new()
		back.polygon = PackedVector2Array([Vector2(0, -800), Vector2(W, -800), Vector2(W, FLOOR_Y), Vector2(0, FLOOR_Y)])
		back.color = Color(0.20, 0.13, 0.09)
		back.z_index = -10
		world.add_child(back)
		for y in range(-760, int(FLOOR_Y), 46):
			var pl := ColorRect.new()
			pl.position = Vector2(0, y)
			pl.size = Vector2(W, 42)
			pl.color = Color(0.26, 0.17, 0.11) if (y / 46) % 2 == 0 else Color(0.29, 0.19, 0.12)
			pl.z_index = -10
			world.add_child(pl)
		for wx in [cx - 900.0, cx + 760.0]:                          # окна: ночное небо и звёзды
			var win := ColorRect.new()
			win.position = Vector2(wx, FLOOR_Y - 520)
			win.size = Vector2(140, 120)
			win.color = Color(0.10, 0.12, 0.28)
			win.z_index = -9
			world.add_child(win)
			for k in 5:
				var st := ColorRect.new()
				st.position = Vector2(wx + 14 + (k * 29) % 120, FLOOR_Y - 508 + (k * 41) % 96)
				st.size = Vector2(3, 3)
				st.color = Color(1.0, 0.95, 0.75)
				st.z_index = -9
				world.add_child(st)
			for b in [Rect2(wx - 6, FLOOR_Y - 526, 152, 8), Rect2(wx - 6, FLOOR_Y - 406, 152, 8), Rect2(wx + 66, FLOOR_Y - 520, 8, 120)]:
				var fr := ColorRect.new()
				fr.position = b.position
				fr.size = b.size
				fr.color = WOOD
				fr.z_index = -9
				world.add_child(fr)
		# полки с товарами по стенам (бутылочки, свитки, мешочки)
		for sx in [cx - 640.0, cx + 420.0]:
			for row in 2:
				var sh := ColorRect.new()
				sh.position = Vector2(sx, FLOOR_Y - 330 + row * 110)
				sh.size = Vector2(240, 10)
				sh.color = PLANK
				sh.z_index = -8
				world.add_child(sh)
				for k in 6:
					var it := Polygon2D.new()
					var hh := 18.0 + (k * 7) % 14
					it.polygon = PackedVector2Array([Vector2(0, 0), Vector2(14, 0), Vector2(14, -hh), Vector2(0, -hh)])
					it.position = Vector2(sx + 12 + k * 38, FLOOR_Y - 330 + row * 110)
					it.color = [Color(0.85, 0.30, 0.30), Color(0.35, 0.65, 0.95), Color(0.95, 0.80, 0.35), Color(0.45, 0.80, 0.40)][(k + row) % 4]
					it.z_index = -8
					world.add_child(it)
		# фонари и тёплый свет
		for lx in [cx - 760.0, cx - 260.0, cx + 260.0, cx + 760.0]:
			var g := Torch.make_glow(110.0, Color(1.0, 0.75, 0.40, 0.55))
			g.position = Vector2(lx, FLOOR_Y - 420)
			g.z_index = -7
			world.add_child(g)
			var lamp := Polygon2D.new()
			lamp.polygon = PackedVector2Array([Vector2(-8, -12), Vector2(8, -12), Vector2(10, 10), Vector2(-10, 10)])
			lamp.color = Color(1.0, 0.78, 0.35)
			lamp.position = Vector2(lx, FLOOR_Y - 420)
			lamp.z_index = -7
			world.add_child(lamp)
			var cord := ColorRect.new()
			cord.position = Vector2(lx - 1, -800)
			cord.size = Vector2(2, FLOOR_Y - 420 + 800 - 12)
			cord.color = Color(0.15, 0.10, 0.08)
			cord.z_index = -7
			world.add_child(cord)
		# пол и стены
		Maps.add_block(world, Rect2(0, FLOOR_Y, W, H - FLOOR_Y + 40), Color(0.36, 0.24, 0.15))
		Maps.add_block(world, Rect2(0, FLOOR_Y, W, 10), PLANK)
		for x in [0.0, W - WALL]:
			Maps.add_block(world, Rect2(x, -800, WALL, H + 800), WOOD)
		# прилавок и торговец за ним
		var m := Merchant.new()
		m.position = Vector2(cx, FLOOR_Y - 10)                    # стоит за прилавком
		m.scale = Vector2(3.4, 3.4)
		m.z_index = -6
		world.add_child(m)
		var counter := Polygon2D.new()
		counter.polygon = PackedVector2Array([Vector2(cx - 170, FLOOR_Y - 84), Vector2(cx + 170, FLOOR_Y - 84), Vector2(cx + 170, FLOOR_Y), Vector2(cx - 170, FLOOR_Y)])
		counter.color = WOOD
		counter.z_index = -5
		world.add_child(counter)
		var top := ColorRect.new()
		top.position = Vector2(cx - 182, FLOOR_Y - 92)
		top.size = Vector2(364, 12)
		top.color = PLANK.lightened(0.15)
		top.z_index = -5
		world.add_child(top)
		var sign := Label.new()
		sign.text = "ЛАВКА"
		sign.position = Vector2(cx - 120, FLOOR_Y - 640)
		sign.size = Vector2(240, 50)
		sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign.add_theme_font_size_override("font_size", 36)
		sign.add_theme_color_override("font_color", Color(1.0, 0.86, 0.50))
		sign.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.04))
		sign.add_theme_constant_override("outline_size", 8)
		sign.z_index = -6
		world.add_child(sign)
		# дверь дальше в бой — справа
		var door_x := W - WALL - 150.0
		var door := Polygon2D.new()
		door.polygon = PackedVector2Array([Vector2(door_x - 60, FLOOR_Y), Vector2(door_x - 60, FLOOR_Y - 190), Vector2(door_x, FLOOR_Y - 230),
				Vector2(door_x + 60, FLOOR_Y - 190), Vector2(door_x + 60, FLOOR_Y)])
		door.color = Color(0.30, 0.18, 0.10)
		door.z_index = -6
		world.add_child(door)
		var glow := Torch.make_glow(90.0, Color(1.0, 0.85, 0.5, 0.5))
		glow.position = Vector2(door_x, FLOOR_Y - 110)
		glow.z_index = -6
		world.add_child(glow)
		var dl := Label.new()
		dl.text = "Дальше в бой →"
		dl.position = Vector2(door_x - 120, FLOOR_Y - 290)
		dl.size = Vector2(240, 40)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.add_theme_font_size_override("font_size", 24)
		dl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
		dl.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.03))
		dl.add_theme_constant_override("outline_size", 6)
		dl.z_index = -6
		world.add_child(dl)
		return {"size": Vector2(W, H), "center": Vector2(cx - 650.0, FLOOR_Y - 32), "gates": [Vector2(cx - 650.0, FLOOR_Y)],
				"glow": null, "floor": FLOOR_Y, "spawners": [], "totems": [], "shop": true,
				"slots_x": [cx - 420.0, cx - 230.0, cx + 230.0], "life_x": cx + 430.0, "door_x": door_x}

# Прилавок с товаром: подставка, парящий значок усиления, название и цена
class Slot extends Node2D:
	var kind := "buff"            # "buff" или "life"
	var id := ""
	var restocks := RESTOCKS
	var visit := 1
	var sold := false
	var _icon: Node2D
	var _name: Label
	var _price: Label
	var _prompt: Label
	var _t := 0.0

	func _ready() -> void:
		z_index = 2
		var stand := Polygon2D.new()
		stand.polygon = PackedVector2Array([Vector2(-34, 0), Vector2(-26, -40), Vector2(26, -40), Vector2(34, 0)])
		stand.color = Color(0.48, 0.32, 0.19)
		add_child(stand)
		var cloth := Polygon2D.new()
		cloth.polygon = PackedVector2Array([Vector2(-30, -40), Vector2(30, -40), Vector2(26, -30), Vector2(-26, -30)])
		cloth.color = Color(0.55, 0.12, 0.16) if kind == "life" else Color(0.22, 0.30, 0.55)
		add_child(cloth)
		_name = _label(Vector2(-110, -150), Vector2(220, 46), 17, Color(1.0, 0.95, 0.85))
		_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_price = _label(Vector2(-80, -104), Vector2(160, 26), 20, Color(1.0, 0.86, 0.35))
		_prompt = _label(Vector2(-120, 6), Vector2(240, 26), 16, Color(0.7, 1.0, 0.7))
		_prompt.text = "Атака — купить"
		_prompt.visible = false
		_refresh()

	func _label(pos: Vector2, size: Vector2, font: int, c: Color) -> Label:
		var l := Label.new()
		l.position = pos
		l.size = size
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", font)
		l.add_theme_color_override("font_color", c)
		l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03))
		l.add_theme_constant_override("outline_size", 5)
		add_child(l)
		return l

	func price() -> int:
		return RunShop.life_price(visit) if kind == "life" else RunShop.price(id, visit)

	func _refresh() -> void:
		if is_instance_valid(_icon):
			_icon.queue_free()
		if sold:
			_name.text = "Распродано"
			_price.text = ""
			return
		_icon = Node2D.new()
		_icon.position = Vector2(0, -66)
		add_child(_icon)
		if kind == "life":
			_icon.add_child(RunShop.heart(16.0, Color(0.95, 0.25, 0.30)))
			_name.text = "Дополнительная жизнь"
		else:
			var info: Dictionary = RunShop.POOL[id]
			var orb := Polygon2D.new()
			orb.polygon = Util.circle(16.0, 18)
			orb.color = info["col"]
			_icon.add_child(orb)
			var core := Polygon2D.new()
			core.polygon = Util.circle(10.0, 14)
			core.color = (info["col"] as Color).lightened(0.4)
			_icon.add_child(core)
			var let := Label.new()
			let.text = info["letter"]
			let.position = Vector2(-16, -16)
			let.size = Vector2(32, 32)
			let.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			let.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			let.add_theme_font_size_override("font_size", 18)
			let.add_theme_color_override("font_color", Color(0.12, 0.08, 0.06))
			_icon.add_child(let)
			_name.text = info["short"]
		_price.text = "%d монет" % price()

	func set_near(on: bool, can_pay: bool) -> void:
		_prompt.visible = on and not sold
		_prompt.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7) if can_pay else Color(1.0, 0.5, 0.45))
		_prompt.text = "Атака — купить" if can_pay else "Не хватает монет"

	# Купили: торговец ставит новый товар (не больше двух раз), жизнь — только одна
	func bought() -> void:
		if kind == "life" or restocks <= 0:
			sold = true
		else:
			restocks -= 1
			id = RunShop.roll()
		Fx.sparks(get_parent(), global_position + Vector2(0, -66), Color(1.0, 0.9, 0.5), 14, 220.0, 4.0)
		_refresh()

	func _process(delta: float) -> void:
		_t += delta
		if is_instance_valid(_icon):
			_icon.position.y = -66.0 + sin(_t * 2.5) * 4.0

# Сердечко из полигонов (в шрифте нет символа ♥)
static func heart(r: float, c: Color) -> Polygon2D:
	var h := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 32:
		var t := TAU * k / 32.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(Vector2(x, y) * r / 16.0)
	h.polygon = pts
	h.color = c
	return h
