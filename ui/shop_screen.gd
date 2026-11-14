class_name ShopScreen
extends CanvasLayer
# Магазин: лавка в таверне. За стойкой — торговец, по бокам — полки с товарами.
# Вкладки на стойке: «Герои», «Предметы», «Усиления», «Сундуки».
# При смене вкладки торговец поворачивается, машет руками и переставляет товары
# (около 1,2 секунды); пока он занят, другую вкладку выбрать нельзя.
# «Герои» — легенды за монеты, «МЕГА» — МЕГА-усиление для каждой легенды
# (на выборе легенды появляется кнопка «МЕГА»). Нажми на товар — откроется
# карточка с ценой и кнопкой «Купить». Остальные вкладки пока для витрины.

signal back_pressed

const TABS := ["Герои", "МЕГА", "Предметы", "Сундуки"]
const SWAP_TIME := 1.2

var _k := 4.0
var _off := Vector2.ZERO
var _merchant: Merchant
var _tab := 0
var _busy := false
var _tab_btns: Array = []
var _items: Array = []
var _shelf_layer: Node2D
var _hot_layer: Control        # невидимые кнопки поверх товаров
var _offers: Array = []        # что продаётся в каждом слоте полки
var _coins: CoinBadge
var _popup: Control
var _hot_btns := {}            # слот полки -> кнопка товара (для геймпада)
var _last_j := -1

func _ready() -> void:
	var vs := Config.screen(self)
	var img := PixelArt.tavern()
	_k = maxf(vs.x / img.get_width(), vs.y / img.get_height())
	var bg := PixelArt.make_sprite(img, _k)
	_off = (vs - Vector2(img.get_size()) * _k) / 2
	bg.position = _off
	add_child(bg)
	_shelf_layer = Node2D.new()
	_shelf_layer.position = _off
	_shelf_layer.scale = Vector2(_k, _k)
	add_child(_shelf_layer)
	_merchant = Merchant.new()
	_merchant.position = _off + Vector2(160, 126) * _k
	_merchant.scale = Vector2(_k, _k) * 1.55
	add_child(_merchant)
	var counter := PixelArt.make_sprite(PixelArt.tavern_counter(), _k)
	counter.position = _off
	add_child(counter)
	# вывеска
	var sign := Label.new()
	sign.text = "ЛАВКА"
	sign.position = _off + Vector2(125, 18) * _k
	sign.size = Vector2(70, 16) * _k
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sign.add_theme_font_size_override("font_size", int(9 * _k))
	sign.add_theme_color_override("font_color", Color(0.25, 0.13, 0.05))
	sign.add_theme_constant_override("outline_size", 0)
	add_child(sign)
	# вкладки — деревянные таблички на стойке
	# вкладка «МЕГА» появляется только после первого полного прохождения Арены
	var mega_open := not Save.arena_heroes().is_empty() or _any_mega()
	var slot := 0
	for i in TABS.size():
		var b := Button.new()
		b.text = TABS[i]
		b.visible = i != 1 or mega_open
		b.position = _off + Vector2((38 + 31 if not mega_open else 38) + slot * 62, 130) * _k
		if b.visible:
			slot += 1
		b.size = Vector2(56, 22) * _k
		b.add_theme_font_size_override("font_size", int(6.5 * _k))
		for st_name in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(st_name, _plank(st_name))
		b.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
		b.add_theme_color_override("font_disabled_color", Color(0.8, 0.7, 0.55))
		b.pressed.connect(_select.bind(i))
		add_child(b)
		_tab_btns.append(b)
	_hot_layer = Control.new()
	_hot_layer.size = vs
	_hot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hot_layer)
	var note := Label.new()
	note.text = "Нажми на товар, чтобы посмотреть и купить"
	note.size = Vector2(vs.x, 30)
	note.position = Vector2(0, vs.y - 34)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 18)
	note.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	add_child(note)
	_coins = CoinBadge.corner(self)
	# «Назад» — внизу слева, чтобы не закрывать товары на верхней полке
	var back := MainMenu.make_button(self, "Назад", Vector2(16, vs.y - 72), Vector2(130, 55), 26)
	back.pressed.connect(func(): back_pressed.emit())
	_fill_shelves(0, false)
	_refresh_tabs()

func _plank(st_name: String) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	var c := Color(0.50, 0.31, 0.16)
	if st_name == "hover":
		c = c.lightened(0.1)
	elif st_name == "pressed":
		c = c.darkened(0.1)
	st.bg_color = c
	st.border_color = Color(0.28, 0.16, 0.08)
	st.set_border_width_all(4)
	if st_name == "focus":
		st.draw_center = false
		st.border_color = Color(1.0, 0.85, 0.35)       # выбрана геймпадом — золотая рамка
		st.set_border_width_all(6)
	st.set_corner_radius_all(4)
	return st

func _refresh_tabs() -> void:
	# пока торговец переставляет товары, вкладки не нажимаются (но остаются выбранными
	# для геймпада — иначе выбор прыгал бы на «Назад»)
	for i in _tab_btns.size():
		var b: Button = _tab_btns[i]
		var k := 0.75 if _busy else 1.0
		b.modulate = (Color(1.3, 1.15, 0.7) if i == _tab else Color(0.85, 0.85, 0.85)) * Color(k, k, k)
		if i == _tab:
			b.set_meta("pad_default", true)
		elif b.has_meta("pad_default"):
			b.remove_meta("pad_default")

# ---------- Смена вкладки ----------
func _any_mega() -> bool:
	for ch in Characters.LIST:
		if Save.has_mega(ch["name"]):
			return true
	return false

func _select(i: int) -> void:
	if _busy or i == _tab:
		return
	_busy = true
	_tab = i
	_refresh_tabs()
	_merchant.turn(true)
	_merchant.busy = true
	# старые товары улетают к торговцу
	var mpos := Vector2(160, 70)
	var n := _items.size()
	for j in n:
		var it: Node2D = _items[j]
		var t := it.create_tween()
		t.tween_interval(0.05 + 0.4 * j / maxf(n, 1))
		t.tween_property(it, "position", mpos, 0.16).set_trans(Tween.TRANS_SINE)
		t.parallel().tween_property(it, "scale", Vector2(0.2, 0.2), 0.16)
		t.tween_callback(it.queue_free)
	_items.clear()
	_clear_hot()
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(_fill_shelves.bind(i, true))
	tw.tween_interval(SWAP_TIME - 0.5 - 0.15)
	tw.tween_callback(func():
		_merchant.busy = false
		_merchant.turn(false))
	tw.tween_interval(0.15)
	tw.tween_callback(func():
		_busy = false
		_refresh_tabs())

# Полки: по 3 слота на каждой из 6 полок
func _slots() -> Array:
	var res := []
	for row in 3:
		for x0 in PixelArt.SHELF_X:
			for k in 3:
				res.append(Vector2(x0 + 16 + k * 30, PixelArt.SHELF_Y[row]))
	return res

func _fill_shelves(tab: int, animate: bool) -> void:
	var goods := _goods(tab)
	var slots := _slots()
	var mpos := Vector2(160, 70)
	_offers.clear()
	_clear_hot()
	for j in mini(goods.size(), slots.size()):
		var g = goods[j]
		var offer: Dictionary = {}
		var it: Node2D
		if g is Dictionary:
			offer = g
			it = _offer_node(g)
		else:
			var sp := PixelArt.make_sprite(g, 1.0)
			sp.centered = true
			sp.offset = Vector2(0, -g.get_height() / 2.0)
			it = sp
		_shelf_layer.add_child(it)
		_items.append(it)
		_offers.append(offer)
		var target: Vector2 = slots[j]
		if not offer.is_empty():
			_add_hot(target, offer, j)
		if animate:
			it.position = mpos
			it.scale = Vector2(0.2, 0.2)
			var t := it.create_tween()
			t.tween_interval(0.4 * j / maxf(goods.size(), 1))
			t.tween_property(it, "position", target, 0.16).set_trans(Tween.TRANS_SINE)
			t.parallel().tween_property(it, "scale", Vector2.ONE, 0.16)
		else:
			it.position = target

# ---------- Товары (маленькие пиксельные картинки) ----------
func _goods(tab: int) -> Array:
	var res := []
	match tab:
		0:   # герои: легенды за монеты, остальное место — таинственные коробки
			for i in Characters.LIST.size():
				if Characters.LIST[i].has("price"):
					res.append({"kind": "hero", "idx": i, "price": Characters.LIST[i]["price"]})
			for i in 7:
				res.append(_mystery_box())
		1:   # МЕГА: только для легенд, с которыми пройдена Арена (и уже купленные раньше)
			for i in Characters.display_order():
				if i in Save.arena_heroes() or Save.has_mega(Characters.LIST[i]["name"]):
					res.append({"kind": "mega", "idx": i, "price": Characters.MEGA_PRICE})
		2:   # предметы: зелья, бомбы, свитки, щиты
			var potions := [Color(0.9, 0.2, 0.25), Color(0.25, 0.5, 1.0), Color(0.3, 0.85, 0.35), Color(0.9, 0.75, 0.2)]
			for c in potions:
				res.append(_potion(c))
			res.append(_bomb())
			res.append(_bomb())
			res.append(_scroll())
			res.append(_scroll())
			res.append(_small_shield())
		3:   # сундуки: тематические — с обликами легенд (без повторов)
			res.append({"kind": "chest", "series": "fire", "idx": 0, "price": int(Skins.SERIES["fire"]["price"])})
			res.append({"kind": "chest", "series": "ice", "idx": 0, "price": int(Skins.SERIES["ice"]["price"])})
			for c in [Color(0.55, 0.36, 0.18), Color(0.9, 0.72, 0.25)]:
				res.append(_chest(c))
	return res

func _img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)

func _figurine(c: Color) -> Image:
	var im := _img(10, 16)
	im.fill_rect(Rect2i(1, 13, 8, 3), Color(0.35, 0.25, 0.18))      # подставка
	BotRig._box(im, 2, 2, 6, 11, c)
	im.fill_rect(Rect2i(5, 4, 2, 2), Color.BLACK)
	return im

func _mystery_box() -> Image:
	var im := _img(12, 12)
	BotRig._box(im, 0, 1, 12, 11, Color(0.55, 0.35, 0.6))
	im.fill_rect(Rect2i(5, 1, 2, 11), Color(0.95, 0.8, 0.3))
	im.fill_rect(Rect2i(4, 4, 4, 1), Color(1, 1, 1))
	im.fill_rect(Rect2i(7, 5, 1, 2), Color(1, 1, 1))
	im.fill_rect(Rect2i(5, 7, 2, 1), Color(1, 1, 1))
	im.fill_rect(Rect2i(5, 9, 2, 1), Color(1, 1, 1))
	return im

func _potion(c: Color) -> Image:
	var im := _img(9, 14)
	im.fill_rect(Rect2i(3, 0, 3, 2), Color(0.55, 0.38, 0.2))       # пробка
	im.fill_rect(Rect2i(3, 2, 3, 3), Color(0.85, 0.9, 0.95, 0.8))
	BotRig._box(im, 0, 5, 9, 9, Color(0.85, 0.9, 0.95))
	im.fill_rect(Rect2i(1, 8, 7, 5), c)
	im.set_pixel(2, 7, Color.WHITE)
	return im

func _bomb() -> Image:
	var im := _img(10, 12)
	BotRig._box(im, 0, 3, 10, 9, Color(0.15, 0.15, 0.17))
	im.fill_rect(Rect2i(4, 0, 2, 3), Color(0.6, 0.5, 0.35))
	im.set_pixel(5, 0, Color(1.0, 0.6, 0.2))
	im.set_pixel(2, 5, Color(0.5, 0.5, 0.55))
	return im

func _scroll() -> Image:
	var im := _img(14, 9)
	BotRig._box(im, 2, 1, 10, 7, Color(0.93, 0.85, 0.66))
	BotRig._box(im, 0, 0, 3, 9, Color(0.75, 0.6, 0.4))
	BotRig._box(im, 11, 0, 3, 9, Color(0.75, 0.6, 0.4))
	im.fill_rect(Rect2i(6, 3, 2, 3), Color(0.8, 0.15, 0.15))
	return im

func _small_shield() -> Image:
	var im := _img(11, 13)
	for y in 13:
		var hw := int(5.5 - maxf(0.0, y - 7) * 0.8)
		im.fill_rect(Rect2i(5 - hw, y, hw * 2 + 1, 1), Color(0.3, 0.45, 0.8))
	im.fill_rect(Rect2i(5, 1, 1, 10), Color(0.95, 0.8, 0.3))
	return im

func _gem(c: Color) -> Image:
	var im := _img(10, 11)
	for y in 11:
		var hw := 4 - absi(y - 4) if y <= 4 else int((10 - y) * 0.7)
		im.fill_rect(Rect2i(5 - hw, y, hw * 2, 1), c if y > 2 else c.lightened(0.35))
	im.set_pixel(4, 3, Color.WHITE)
	return im

func _rune(c: Color) -> Image:
	var im := _img(10, 12)
	BotRig._box(im, 0, 0, 10, 12, Color(0.45, 0.45, 0.5))
	im.fill_rect(Rect2i(4, 2, 2, 8), c)
	im.fill_rect(Rect2i(2, 4, 6, 1), c)
	im.fill_rect(Rect2i(3, 7, 4, 1), c)
	return im

func _chest(c: Color) -> Image:
	var im := _img(16, 12)
	BotRig._box(im, 0, 3, 16, 9, c)
	BotRig._box(im, 0, 0, 16, 5, c.lightened(0.12))
	im.fill_rect(Rect2i(0, 5, 16, 1), Color(0.2, 0.15, 0.1))
	im.fill_rect(Rect2i(7, 4, 2, 3), Color(0.95, 0.8, 0.3))
	for x in [2, 13]:
		im.fill_rect(Rect2i(x, 0, 1, 12), c.darkened(0.35))
	return im

# ---------- Товары, которые можно купить ----------
# Фигурка легенды (настоящая модель) или МЕГА-кристалл с цветом легенды
func _offer_node(o: Dictionary) -> Node2D:
	var ch: Dictionary = Characters.LIST[o["idx"]]
	var root := Node2D.new()
	if o["kind"] == "chest":
		var ice: bool = o.get("series", "fire") == "ice"
		var cimg := _chest(Color(0.85, 0.32, 0.10) if not ice else Color(0.32, 0.55, 0.80))
		var cs := PixelArt.make_sprite(cimg, 1.0)
		cs.centered = true
		cs.offset = Vector2(0, -cimg.get_height() / 2.0)
		root.add_child(cs)
		if not ice:
			for k in 3:                                   # языки пламени над крышкой
				var fl := Polygon2D.new()
				fl.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(0, -6 - k), Vector2(2, 0)])
				fl.color = Color(1.0, 0.75, 0.2) if k != 1 else Color(1.0, 0.45, 0.1)
				fl.position = Vector2(-5 + k * 5, -cimg.get_height() - 1)
				root.add_child(fl)
		else:
			var snow := Polygon2D.new()                   # снег на крышке
			snow.polygon = PackedVector2Array([Vector2(-8, -12), Vector2(-6, -14), Vector2(-2, -13.5), Vector2(1, -15), Vector2(5, -13.5), Vector2(8, -14), Vector2(8, -12)])
			snow.color = Color(0.96, 0.99, 1.0)
			root.add_child(snow)
			for k in 4:                                   # сосульки по краю крышки
				var ic := Polygon2D.new()
				ic.polygon = PackedVector2Array([Vector2(-1, 0), Vector2(0, 2.5 + (k % 2) * 1.5), Vector2(1, 0)])
				ic.color = Color(0.80, 0.95, 1.0)
				ic.position = Vector2(-6 + k * 4, -7)
				root.add_child(ic)
			var fl2 := Polygon2D.new()                    # снежинка-искра над сундуком
			fl2.polygon = PackedVector2Array([Vector2(0, -3), Vector2(0.6, -0.6), Vector2(3, 0), Vector2(0.6, 0.6), Vector2(0, 3), Vector2(-0.6, 0.6), Vector2(-3, 0), Vector2(-0.6, -0.6)])
			fl2.color = Color(0.85, 0.97, 1.0)
			fl2.position = Vector2(0, -cimg.get_height() - 5)
			root.add_child(fl2)
			fl2.create_tween().set_loops().tween_property(fl2, "rotation", TAU, 3.0).from(0.0)
		return root
	if o["kind"] == "hero":
		var stand := Polygon2D.new()
		stand.polygon = PackedVector2Array([Vector2(-8, -2), Vector2(8, -2), Vector2(8, 0), Vector2(-8, 0)])
		stand.color = Color(0.35, 0.25, 0.18)
		root.add_child(stand)
		var rig := BotRig.new()
		rig.kind = ch["rig"]
		rig.size = Vector2(12, 19)
		rig.position = Vector2(0, -2 - 9.5)
		root.add_child(rig)
	else:
		var img := _gem(ch["color"].lightened(0.15))
		var sp := PixelArt.make_sprite(img, 1.0)
		sp.centered = true
		sp.offset = Vector2(0, -img.get_height() / 2.0)
		root.add_child(sp)
		var m := Label.new()
		m.text = "M"
		m.position = Vector2(-4, -9)
		m.size = Vector2(8, 8)
		m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		m.add_theme_font_size_override("font_size", 6)
		m.add_theme_color_override("font_color", Color(1, 1, 1))
		m.add_theme_constant_override("outline_size", 2)
		root.add_child(m)
	return root

func _owned(o: Dictionary) -> bool:
	if o["kind"] == "chest":
		return Skins.chest_left(o.get("series", "fire")).is_empty()
	var name: String = Characters.LIST[o["idx"]]["name"]
	return Save.owns_hero(name) if o["kind"] == "hero" else Save.has_mega(name)

func _clear_hot() -> void:
	_hot_btns.clear()
	if _hot_layer:
		for c in _hot_layer.get_children():
			c.queue_free()

# Невидимая кнопка над товаром и ценник под ним
func _add_hot(slot: Vector2, o: Dictionary, j: int) -> void:
	var b := Button.new()
	b.flat = true
	b.position = _off + (slot + Vector2(-13, -22)) * _k
	b.size = Vector2(26, 24) * _k
	b.focus_mode = Control.FOCUS_ALL          # товар можно выбрать геймпадом
	for st_name in ["normal", "hover", "pressed", "focus"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(1, 1, 1, 0.0 if st_name == "normal" else 0.12)
		st.set_corner_radius_all(6)
		if st_name == "focus":
			st.bg_color = Color(1.0, 0.85, 0.35, 0.16)     # выбранный геймпадом — в золотой рамке
			st.border_color = Color(1.0, 0.85, 0.35, 0.95)
			st.set_border_width_all(4)
		b.add_theme_stylebox_override(st_name, st)
	b.pressed.connect(_open_offer.bind(j))
	_hot_layer.add_child(b)
	_hot_btns[j] = b
	var tag := Label.new()
	tag.position = _off + (slot + Vector2(-14, 0.5)) * _k
	tag.size = Vector2(28, 7) * _k
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", int(4.6 * _k))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _owned(o):
		tag.text = "есть"
		tag.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	else:
		tag.text = "%d G" % o["price"]
		tag.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_hot_layer.add_child(tag)

# ---------- Карточка товара ----------
func _open_offer(j: int) -> void:
	if _busy or j >= _offers.size() or _offers[j].is_empty():
		return
	_close_offer(false)
	_last_j = j
	var o: Dictionary = _offers[j]
	var ch: Dictionary = Characters.LIST[o["idx"]]
	var vs := Config.screen(self)
	_popup = Control.new()
	_popup.size = vs
	_popup.add_to_group("pad_scope")            # геймпад выбирает только кнопки карточки
	add_child(_popup)
	var dim := ColorRect.new()
	dim.size = vs
	dim.color = Color(0, 0, 0, 0.55)
	dim.gui_input.connect(_dim_input)
	_popup.add_child(dim)
	var card := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.93, 0.86, 0.68)
	st.border_color = Color(0.45, 0.28, 0.12)
	st.set_border_width_all(6)
	st.set_corner_radius_all(14)
	card.add_theme_stylebox_override("panel", st)
	card.size = Vector2(760, 470)
	card.position = (vs - card.size) / 2
	_popup.add_child(card)
	var mega: bool = o["kind"] == "mega"
	var ink := Color(0.25, 0.14, 0.06)
	if o["kind"] == "chest":
		_chest_card(card, o, ink)
		return
	var title: String = ("МЕГА: " if mega else "") + ch["name"]
	_card_label(card, title, Vector2(250, 22), Vector2(490, 50), 34, ink)
	var text := ""
	if mega:
		text = "Постоянный МЕГА для легенды «%s».\nНа выборе легенды под героем появится кнопка «МЕГА». Включишь — герой всегда использует только МЕГА-способности и МЕГА-ульту, даже без баффа. Выключишь — обычные способности, а МЕГА — только с баффом «МЕГА-усиление»." % ch["name"]
	else:
		text = ch["role"] + "\n" + ch["weapon"] + "\nЗдоровье: %d   Скорость: %d" % [ch["hp"], int(ch["speed"])]
	_card_label(card, text, Vector2(250, 80), Vector2(480, 260), 19, ink)
	HeroFigure.draw(card, Vector2(130, 330), 3.0, o["idx"], Color(0, 0, 0, 0), 1, not Characters.unlocked(o["idx"]) and mega)
	if mega:
		var glow := Label.new()
		glow.text = "МЕГА"
		glow.position = Vector2(40, 345)
		glow.size = Vector2(180, 40)
		glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glow.add_theme_font_size_override("font_size", 30)
		glow.add_theme_color_override("font_color", Color(0.75, 0.35, 1.0))
		card.add_child(glow)
	var owned := _owned(o)
	var can_open: bool = Characters.unlocked(o["idx"]) or not mega
	var buy := MainMenu.make_button(card, "", Vector2(250, 370), Vector2(300, 74), 30)
	if owned:
		buy.text = "Уже куплено"
		buy.disabled = true
	elif not can_open:
		buy.text = "Сначала открой легенду"
		buy.add_theme_font_size_override("font_size", 20)
		buy.disabled = true
	elif Save.gold() < o["price"]:
		buy.text = "Нужно %d G" % o["price"]
		buy.disabled = true
	else:
		buy.text = "Купить за %d G" % o["price"]
		buy.pressed.connect(_buy.bind(o))
	var close := MainMenu.make_button(card, "Закрыть", Vector2(570, 370), Vector2(160, 74), 24)
	close.pressed.connect(_close_offer)
	# геймпад: сразу на «Купить» (или на «Закрыть», если купить нельзя)
	var first: Button = close if buy.disabled else buy
	first.grab_focus.call_deferred()

# Сундук серии (огненный, ледяной): что внутри и что уже собрано
func _chest_card(card: Panel, o: Dictionary, ink: Color) -> void:
	var ser: String = o.get("series", "fire")
	var ice := ser == "ice"
	_card_label(card, "Ледяной сундук" if ice else "Огненный сундук", Vector2(40, 18), Vector2(680, 50), 34, ink)
	_card_label(card, "Внутри — случайный облик %s серии, которого у тебя ещё нет. Облик — другая модель легенды и %s вид её способностей; механика та же." %
			(["ледяной", "ледяной"] if ice else ["огненной", "огненный"]), Vector2(40, 66), Vector2(680, 60), 17, ink)
	var ids: Array = Skins.chest_series(ser).keys()
	var half := ceili(ids.size() / 2.0)
	for c in 2:                                    # список — в два столбца, чтобы влез
		var lines := ""
		for j in range(c * half, mini(ids.size(), (c + 1) * half)):
			var id: String = ids[j]
			var hi := _kit_index(Skins.chest_series(ser)[id][0])
			lines += "• %s — %s%s\n" % [Skins.chest_series(ser)[id][1], String(Characters.LIST[hi]["name"]).capitalize(), " (есть)" if Skins.owned(id) else ""]
		_card_label(card, lines, Vector2(40 + c * 345, 126), Vector2(340, 240), 14, ink)
	var buy := MainMenu.make_button(card, "", Vector2(250, 370), Vector2(300, 74), 28)
	if Skins.chest_left(ser).is_empty():
		buy.text = "Всё собрано"
		buy.disabled = true
	elif Save.gold() < o["price"]:
		buy.text = "Нужно %d G" % o["price"]
		buy.disabled = true
	else:
		buy.text = "Открыть за %d G" % o["price"]
		buy.pressed.connect(_open_chest.bind(o))
	var close := MainMenu.make_button(card, "Закрыть", Vector2(570, 370), Vector2(160, 74), 24)
	close.pressed.connect(_close_offer)
	(close if buy.disabled else buy).grab_focus.call_deferred()

func _kit_index(kit: String) -> int:
	for i in Characters.LIST.size():
		if Characters.LIST[i].get("kit", "") == kit:
			return i
	return 0

# ---------- Открытие сундука: лента обликов, как кейс ----------
# По ленте в случайном порядке стоят облики серии, которых у игрока ещё нет (выпавшие на
# ленту больше не попадают). Лента разгоняется и плавно тормозит; облик, остановившийся
# под чертой посередине, — твой. «Пропустить» — сразу к концу.
const ROLL_CARDS := 48                 # сколько карточек на ленте
const ROLL_WIN := 40                   # на каком месте лежит выигрыш
const ROLL_CW := 150.0                 # ширина карточки
const ROLL_STEP := 162.0               # шаг ленты (карточка + зазор)
const ROLL_TIME := 6.0

var roll_ids: Array = []               # что лежит на ленте (для проверок)
var roll_win := ""
var _roll_strip: Control
var _roll_tw: Tween
var _roll_win_card: Control
var _roll_last := -1
var _roll_cx := 0.0
var _roll_done := false
var _roll_stop := 0.0

func _open_chest(o: Dictionary) -> void:
	var ser: String = o.get("series", "fire")
	var pool := Skins.chest_left(ser)
	if Save.gold() < o["price"] or pool.is_empty():
		return
	Save.data["gold"] = Save.gold() - int(o["price"])
	var id := Skins.open_chest(ser)                    # облик выдаётся сразу (и сохраняется)
	_close_offer(false)
	if _coins:
		_coins.refresh()
	roll_win = id
	var ice := ser == "ice"
	var vs := Config.screen(self)
	_popup = Control.new()
	_popup.size = vs
	_popup.add_to_group("pad_scope")
	add_child(_popup)
	var dim := ColorRect.new()
	dim.size = vs
	dim.color = Color(0.02, 0.03, 0.06, 0.88)
	_popup.add_child(dim)
	var title := Label.new()
	title.text = "Ледяной сундук" if ice else "Огненный сундук"
	title.size = Vector2(vs.x, 60)
	title.position = Vector2(0, vs.y * 0.08)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.70, 0.92, 1.0) if ice else Color(1.0, 0.75, 0.3))
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_outline_color", Color(0.04, 0.10, 0.22) if ice else Color(0.25, 0.08, 0.02))
	_popup.add_child(title)
	# лента: случайные облики из тех, которых не было; выигрыш — на месте ROLL_WIN
	roll_ids.clear()
	for k in ROLL_CARDS:
		roll_ids.append(pool[randi() % pool.size()])
	roll_ids[ROLL_WIN] = id
	var previews := {}
	for pid in pool:
		previews[pid] = _skin_preview(pid)
	var win := Panel.new()                                # окно ленты
	win.size = Vector2(vs.x - 60.0, 232)
	win.position = Vector2(30, vs.y * 0.5 - 116)
	win.clip_contents = true
	var wst := StyleBoxFlat.new()
	wst.bg_color = Color(0.07, 0.07, 0.10)
	wst.border_color = Color(0.30, 0.30, 0.36)
	wst.set_border_width_all(3)
	wst.set_corner_radius_all(10)
	win.add_theme_stylebox_override("panel", wst)
	_popup.add_child(win)
	_roll_strip = Control.new()
	_roll_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win.add_child(_roll_strip)
	for k in ROLL_CARDS:
		var c := _roll_card(roll_ids[k], previews[roll_ids[k]])
		c.position = Vector2(k * ROLL_STEP, 12)
		_roll_strip.add_child(c)
		if k == ROLL_WIN:
			_roll_win_card = c
	_roll_cx = win.size.x / 2
	var line := ColorRect.new()                           # черта посередине
	line.size = Vector2(4, win.size.y + 24)
	line.position = Vector2(win.position.x + _roll_cx - 2, win.position.y - 12)
	line.color = Color(1.0, 0.82, 0.30)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup.add_child(line)
	for s2 in [-1.0, 1.0]:
		var tri := Polygon2D.new()
		var y := win.position.y - 14.0 if s2 < 0 else win.position.y + win.size.y + 14.0
		tri.polygon = PackedVector2Array([Vector2(-10, 0), Vector2(10, 0), Vector2(0, -s2 * 14.0)])
		tri.position = Vector2(win.position.x + _roll_cx, y)
		tri.color = Color(1.0, 0.82, 0.30)
		_popup.add_child(tri)
	# где остановиться: черта попадает в случайное место выигрышной карточки
	var stop_x := _roll_cx - (ROLL_WIN * ROLL_STEP + ROLL_CW * randf_range(0.12, 0.88))
	_roll_stop = stop_x
	_roll_strip.position.x = _roll_cx - ROLL_STEP * 2.5
	_roll_last = -1
	_roll_done = false
	_roll_tw = _roll_strip.create_tween()
	_roll_tw.tween_property(_roll_strip, "position:x", stop_x, ROLL_TIME).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_roll_tw.tween_callback(_roll_finish)
	var skip := MainMenu.make_button(_popup, "Пропустить", Vector2(vs.x / 2 - 120, win.position.y + win.size.y + 40), Vector2(240, 64), 24)
	skip.name = "Skip"
	skip.pressed.connect(_roll_skip)
	skip.grab_focus.call_deferred()
	Audio.sfx("buff")

# Живой снимок облика для карточек ленты (одна картинка на облик)
func _skin_preview(id: String) -> Texture2D:
	var vp := SubViewport.new()
	vp.size = Vector2i(120, 150)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_popup.add_child(vp)
	var hi := _kit_index(String(Skins.info(id).get("kit", "")))
	var photo: bool = (BotRig.SPECS.get(Characters.LIST[hi].get("rig", ""), {}) as Dictionary).get("photo", false)
	HeroFigure.draw(vp, Vector2(60, 146), 1.6 if photo else 2.1, hi, Color(0, 0, 0, 0), 1, false, id)   # у фото-легенд голова крупнее
	return vp.get_texture()

func _roll_card(id: String, tex: Texture2D) -> Control:
	var info := Skins.info(id)
	var sc: Color = Skins.SERIES[info.get("series", "fire")]["color"]
	var c := Panel.new()
	c.size = Vector2(ROLL_CW, 212)
	c.pivot_offset = c.size / 2
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.14, 0.13, 0.18)
	st.border_color = sc.darkened(0.35)
	st.set_border_width_all(2)
	st.border_width_bottom = 6
	st.set_corner_radius_all(6)
	c.add_theme_stylebox_override("panel", st)
	var glow := ColorRect.new()                           # подсветка снизу в цвете серии
	glow.color = Color(sc, 0.16)
	glow.size = Vector2(ROLL_CW - 4, 70)
	glow.position = Vector2(2, 92)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(glow)
	var pic := TextureRect.new()
	pic.texture = tex
	pic.size = Vector2(120, 150)
	pic.position = Vector2((ROLL_CW - 120) / 2, 0)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(pic)
	var nm := Label.new()
	nm.text = String(info.get("name", ""))
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.size = Vector2(ROLL_CW - 8, 36)
	nm.position = Vector2(4, 143)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 13)
	nm.add_theme_color_override("font_color", Color(1, 0.97, 0.90))
	c.add_child(nm)
	var hn := Label.new()
	hn.text = String(Characters.LIST[_kit_index(String(info.get("kit", "")))]["name"]).capitalize()
	hn.size = Vector2(ROLL_CW - 8, 18)
	hn.position = Vector2(4, 188)
	hn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hn.add_theme_font_size_override("font_size", 11)
	hn.add_theme_color_override("font_color", sc.lightened(0.2))
	c.add_child(hn)
	return c

func _process(_delta: float) -> void:
	if _roll_strip == null or not is_instance_valid(_roll_strip) or _roll_done:
		return
	# щелчок каждый раз, когда под чертой проходит новая карточка
	var k := int(floor((_roll_cx - _roll_strip.position.x) / ROLL_STEP))
	if k != _roll_last:
		if _roll_last >= 0:
			Audio.sfx("click", Vector2.INF, 0.0, 0.15)
		_roll_last = k

func _roll_skip() -> void:
	if _roll_done or _roll_strip == null or not is_instance_valid(_roll_strip):
		return
	if _roll_tw and _roll_tw.is_valid():
		_roll_tw.kill()
	_roll_strip.position.x = _roll_stop                    # лента сразу доезжает до конца
	_roll_finish()

func _roll_finish() -> void:
	if _roll_done:
		return
	_roll_done = true
	if is_instance_valid(_roll_win_card):
		var tw := _roll_win_card.create_tween()
		tw.tween_property(_roll_win_card, "scale", Vector2(1.12, 1.12), 0.15).set_trans(Tween.TRANS_BACK)
		tw.tween_property(_roll_win_card, "scale", Vector2(1.05, 1.05), 0.2)
		var hl := ColorRect.new()
		hl.color = Color(1.0, 0.95, 0.70, 0.35)
		hl.size = _roll_win_card.size
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_roll_win_card.add_child(hl)
		hl.create_tween().tween_property(hl, "modulate:a", 0.0, 0.6)
	Audio.stinger("unlock")
	var sk: Variant = _popup.get_node_or_null("Skip") if _popup else null
	if sk is Button:
		(sk as Button).visible = false
	var me: WeakRef = weakref(self)
	get_tree().create_timer(0.9).timeout.connect(func():
		var s3: Variant = me.get_ref()
		if s3 and is_instance_valid(s3._popup):
			s3._show_won(s3.roll_win))

# Итог: облик крупно, его имя и «Отлично!»
func _show_won(id: String) -> void:
	var info := Skins.info(id)
	var ice: bool = info.get("series", "") == "ice"
	for c in _popup.get_children():
		if not (c is SubViewport):
			c.queue_free()
	_roll_strip = null
	var vs := Config.screen(self)
	var dim := ColorRect.new()
	dim.size = vs
	dim.color = Color(0, 0, 0, 0.7)
	dim.gui_input.connect(_dim_input)
	_popup.add_child(dim)
	var hi := _kit_index(String(info["kit"]))
	var glow := Polygon2D.new()
	glow.polygon = Util.circle(170.0, 32)
	glow.color = Color(0.45, 0.80, 1.0, 0.35) if ice else Color(1.0, 0.45, 0.12, 0.35)
	glow.position = Vector2(vs.x / 2, vs.y * 0.52)
	_popup.add_child(glow)
	glow.scale = Vector2(0.1, 0.1)
	glow.create_tween().tween_property(glow, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
	HeroFigure.draw(_popup, Vector2(vs.x / 2, vs.y * 0.52 + 110), 4.0, hi, Color(0, 0, 0, 0), 1, false, id)
	var t := Label.new()
	t.text = "Новый облик: «%s»!\n%s" % [info["name"], String(Characters.LIST[hi]["name"]).capitalize()]
	t.size = Vector2(vs.x, 100)
	t.position = Vector2(0, vs.y * 0.08)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 38)
	t.add_theme_color_override("font_color", Color(0.70, 0.92, 1.0) if ice else Color(1.0, 0.75, 0.3))
	t.add_theme_constant_override("outline_size", 8)
	t.add_theme_color_override("font_outline_color", Color(0.04, 0.10, 0.22) if ice else Color(0.25, 0.08, 0.02))
	_popup.add_child(t)
	var ok := MainMenu.make_button(_popup, "Отлично!", Vector2(vs.x / 2 - 120, vs.y - 110), Vector2(240, 70), 28)
	ok.pressed.connect(func(): _close_offer())
	ok.grab_focus.call_deferred()

func _card_label(parent: Control, text: String, pos: Vector2, size: Vector2, font: int, c: Color) -> void:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text = text
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", c)
	l.add_theme_constant_override("outline_size", 0)
	parent.add_child(l)

func _dim_input(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed:
		_close_offer()

func _close_offer(refocus := true) -> void:
	if _popup and is_instance_valid(_popup):
		_popup.remove_from_group("pad_scope")
		_popup.queue_free()
	_popup = null
	if refocus and _hot_btns.has(_last_j) and is_instance_valid(_hot_btns[_last_j]):
		_hot_btns[_last_j].grab_focus.call_deferred()      # выбор возвращается на товар

# B на геймпаде: сначала закрывает карточку товара, а уже потом — магазин
func handle_back() -> bool:
	if _popup and is_instance_valid(_popup):
		_close_offer()
		return true
	return false

func _buy(o: Dictionary) -> void:
	var ch: Dictionary = Characters.LIST[o["idx"]]
	if not Save.buy(o["kind"], ch["name"], o["price"]):
		return
	_close_offer(false)
	if _coins:
		_coins.refresh()
	# торговец радуется: поворачивается и машет, товар на полке подписан «есть»
	_merchant.turn(true)
	var t := create_tween()
	t.tween_interval(0.35)
	t.tween_callback(func(): _merchant.turn(false))
	_clear_hot()
	var slots := _slots()
	for j in _offers.size():
		if not _offers[j].is_empty():
			_add_hot(slots[j], _offers[j], j)
	if _hot_btns.has(_last_j):
		_hot_btns[_last_j].grab_focus.call_deferred()
	var vs := Config.screen(self)
	var msg := Label.new()
	msg.text = ("Куплено: МЕГА для «%s»!" if o["kind"] == "mega" else "Новая легенда: %s!") % ch["name"]
	msg.size = Vector2(vs.x, 60)
	msg.position = Vector2(0, vs.y * 0.18)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 40)
	msg.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	add_child(msg)
	var mt := msg.create_tween()
	mt.tween_interval(1.4)
	mt.tween_property(msg, "modulate:a", 0.0, 0.5)
	mt.tween_callback(msg.queue_free)
