class_name MenuScene
extends Node2D
# ---------- Живая заставка главного меню ----------
# Пиксельный пейзаж (гора, холмы, лес, поле, река) живёт своей жизнью:
#   — солнце встаёт справа из-за гор, проходит по небу и садится за большую вершину слева;
#     небо меняет цвет (утро, день, закат), потом наступает ночь — звёзды
#     и луна, светлячки над полем; луна уходит — снова рассвет, и так по кругу;
#   — облака плывут по ветру и окрашиваются в цвет неба;
#   — днём над долиной пролетают стаи птиц, ночью — летучие мыши;
#   — по реке бегут блики (ночью — лунная дорожка);
#   — ветер гнёт траву на переднем плане и носит лепестки, порывы то сильнее, то слабее.
# Всё рисуется теми же «крупными пикселями», что и пейзаж.

# Заставка одна на все экраны меню (её держит main.gd на своём слое под экранами):
# главное меню, настройки, управление, История — видно её; в Лавке, книгах и выборе
# режима она скрыта за их фоном, но время суток идёт дальше и при возвращении не сбрасывается.
static var shared: MenuScene

# Показать общую заставку под экраном (true — она есть)
static func reveal() -> bool:
	if shared != null and is_instance_valid(shared) and shared.get_parent() is CanvasLayer:
		(shared.get_parent() as CanvasLayer).visible = true
		return true
	return false

const IW := 320                      # размер пейзажа в пикселях рисунка
const IH := 180
const DAY := 110.0                   # секунд от восхода до заката
const NIGHT := 80.0                  # секунд от захода до восхода
const START := 0.22                  # меню открывается утром (доля дня)

var vs := Vector2(1152, 648)
var px := 4.0                        # размер «пикселя» на экране
var origin := Vector2.ZERO           # где на экране левый верхний угол пейзажа
var clock := START * DAY             # время суток, с

var _sky: TextureRect
var _grad: Gradient
var _stars: Node2D
var _star_list: Array = []
var _sun: Node2D
var _moon: Node2D
var _land: Sprite2D
var _clouds: Array = []
var _birds: Array = []
var _bird_t := 3.0
var _glints: Array = []
var _flies: Array = []
var _grass: Array = []
var _petals: Array = []
var _petal_t := 0.0
var _t := 0.0
var _wind := 1.0
var _rng := RandomNumberGenerator.new()

# Ключевые цвета неба: [верх, низ горизонта] и оттенок земли
const SKY_DAY := [Color(0.30, 0.50, 0.86), Color(0.98, 0.80, 0.62)]
const SKY_GOLD := [Color(0.38, 0.38, 0.72), Color(1.0, 0.62, 0.38)]
const SKY_NIGHT := [Color(0.02, 0.03, 0.10), Color(0.10, 0.12, 0.30)]
const LAND_DAY := Color(1, 1, 1)
const LAND_GOLD := Color(1.0, 0.80, 0.70)
const LAND_NIGHT := Color(0.32, 0.38, 0.62)

func setup(screen: Vector2) -> void:
	vs = screen
	px = maxf(vs.x / IW, vs.y / IH)
	origin = (vs - Vector2(IW, IH) * px) / 2.0

func at(x: float, y: float) -> Vector2:
	return origin + Vector2(x, y) * px

func _ready() -> void:
	_rng.randomize()
	# небо — градиент, цвет меняется со временем суток
	_grad = Gradient.new()
	_grad.set_color(0, SKY_DAY[0])
	_grad.set_color(1, SKY_DAY[1])
	var gt := GradientTexture2D.new()
	gt.gradient = _grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	_sky = TextureRect.new()
	_sky.texture = gt
	_sky.stretch_mode = TextureRect.STRETCH_SCALE
	_sky.position = Vector2.ZERO
	_sky.size = Vector2(vs.x, at(0, 128).y)
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sky)
	# звёзды
	_stars = Node2D.new()
	add_child(_stars)
	for i in 90:
		var s := ColorRect.new()
		var big := _rng.randf() < 0.15
		s.size = Vector2.ONE * px * (2.0 if big else 1.0)
		s.position = at(_rng.randf_range(0, IW), _rng.randf_range(0, 110))
		s.color = Color(1, 1, 0.92) if _rng.randf() < 0.7 else Color(0.8, 0.88, 1.0)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stars.add_child(s)
		_star_list.append([s, _rng.randf_range(0.0, TAU), _rng.randf_range(1.5, 4.0)])
	# солнце и луна (за горами)
	_sun = _disc_sprite(_sun_img(), Vector2(42, 42))
	_moon = _disc_sprite(_moon_img(), Vector2(18, 18))
	# облака
	for i in 6:
		var c := PixelArt.make_sprite(PixelArt.cloud(), px)
		c.position = Vector2(_rng.randf_range(-100, vs.x), at(0, _rng.randf_range(6, 60)).y)
		c.set_meta("speed", _rng.randf_range(0.6, 1.4))
		add_child(c)
		_clouds.append(c)
	# пейзаж без неба
	_land = PixelArt.make_sprite(PixelArt.title_landscape(false), px)
	_land.position = origin
	add_child(_land)
	# блики на реке
	for i in 46:
		var g := ColorRect.new()
		g.size = Vector2(px * _rng.randi_range(1, 3), px)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(g)
		_glints.append([g, _rng.randf_range(121.0, IH), _rng.randf_range(-1.0, 1.0), _rng.randf_range(6.0, 12.0)])
	# светлячки
	for i in 18:
		var fly := ColorRect.new()
		fly.size = Vector2.ONE * px
		fly.color = Color(0.85, 1.0, 0.45)
		fly.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fly)
		_flies.append([fly, Vector2(_rng.randf_range(0, IW), _rng.randf_range(132, IH - 6)), _rng.randf_range(0, TAU)])
	# трава переднего плана — гнётся на ветру
	var gx := 0.0
	while gx < IW:
		var tuft := Polygon2D.new()
		var hgt := _rng.randf_range(5.0, 11.0)
		var wid := _rng.randf_range(1.5, 2.6)
		tuft.polygon = PackedVector2Array([Vector2(-wid, 0), Vector2(-wid * 0.3, -hgt), Vector2(wid * 0.4, -hgt * 0.7), Vector2(wid, 0)])
		tuft.color = Color(0.26, 0.50, 0.20) if _rng.randf() < 0.5 else Color(0.32, 0.58, 0.24)
		tuft.position = at(gx, IH + 1)
		tuft.scale = Vector2(px, px)
		add_child(tuft)
		_grass.append([tuft, gx])
		gx += _rng.randf_range(2.0, 4.5)
	_apply_time(0.0)

func _disc_sprite(img: Image, center: Vector2) -> Node2D:
	var n := Node2D.new()
	var s := PixelArt.make_sprite(img, px)
	s.position = -center * px
	n.add_child(s)
	add_child(n)
	return n

static func _sun_img() -> Image:
	var img := Image.create(84, 84, false, Image.FORMAT_RGBA8)
	PixelArt._halo(img, 42, 42, 40, Color(1.0, 0.92, 0.72, 0.3))
	PixelArt._circle(img, 42, 42, 19, Color(1.0, 0.88, 0.66))
	PixelArt._circle(img, 42, 42, 13, Color(1.0, 0.96, 0.78))
	return img

static func _moon_img() -> Image:
	var img := Image.create(36, 36, false, Image.FORMAT_RGBA8)
	PixelArt._halo(img, 18, 18, 17, Color(0.75, 0.82, 1.0, 0.35))
	PixelArt._circle(img, 18, 18, 9, Color(0.90, 0.92, 0.98))
	for c in [[15, 15, 2], [21, 19, 2], [16, 22, 1], [22, 14, 1]]:
		PixelArt._circle(img, c[0], c[1], c[2], Color(0.76, 0.79, 0.88))
	return img

# ---------- Время суток ----------
# Возвращает высоту светила над горизонтом: >0 день, <0 ночь (−1…1)
func _elev() -> float:
	var cyc := DAY + NIGHT
	var t := fmod(clock, cyc)
	if t < DAY:
		return sin(PI * t / DAY)
	return -sin(PI * (t - DAY) / NIGHT)

func _arc(k: float) -> Vector2:
	# путь светила: встаёт справа из-за низких гор, проходит высоко над долиной
	# и садится слева за большую вершину
	return Vector2(lerpf(325.0, -5.0, k), 112.0 - sin(PI * k) * 100.0)

func _apply_time(delta: float) -> void:
	clock += delta
	var cyc := DAY + NIGHT
	var t := fmod(clock, cyc)
	var e := _elev()
	# цвета: ночь — золото заката/рассвета — день
	var top: Color
	var bot: Color
	var land: Color
	if e >= 0.0:
		var k := clampf(e / 0.35, 0.0, 1.0)
		top = SKY_GOLD[0].lerp(SKY_DAY[0], k)
		bot = SKY_GOLD[1].lerp(SKY_DAY[1], k)
		land = LAND_GOLD.lerp(LAND_DAY, k)
		var k0 := clampf(e / 0.08, 0.0, 1.0)                 # у самого горизонта — уже сумерки
		top = SKY_NIGHT[0].lerp(top, 0.35 + 0.65 * k0)
		bot = SKY_NIGHT[1].lerp(bot, 0.35 + 0.65 * k0)
		land = LAND_NIGHT.lerp(land, 0.4 + 0.6 * k0)
	else:
		var k2 := clampf(-e / 0.25, 0.0, 1.0)
		top = SKY_GOLD[0].lerp(SKY_NIGHT[0], 0.35 + 0.65 * k2)
		bot = SKY_GOLD[1].lerp(SKY_NIGHT[1], 0.35 + 0.65 * k2)
		land = LAND_GOLD.lerp(LAND_NIGHT, 0.4 + 0.6 * k2)
	_grad.set_color(0, top)
	_grad.set_color(1, bot)
	_land.modulate = land
	var night := clampf(-e * 3.0, 0.0, 1.0)
	_stars.modulate.a = night
	# солнце и луна идут по дуге
	if t < DAY:
		_sun.visible = true
		_moon.visible = false
		_sun.position = at(_arc(t / DAY).x, _arc(t / DAY).y)
		_sun.modulate = Color(1.0, 0.75 + 0.25 * clampf(e / 0.3, 0.0, 1.0), 0.6 + 0.4 * clampf(e / 0.3, 0.0, 1.0))
	else:
		_sun.visible = false
		_moon.visible = true
		var km := (t - DAY) / NIGHT
		_moon.position = at(_arc(km).x, _arc(km).y)
	# облака: днём белые, на закате розовые, ночью тёмные и прозрачнее
	var cloud := Color(1.0, 0.86, 0.80).lerp(Color.WHITE, clampf(e / 0.35, 0.0, 1.0)) if e >= 0.0 \
			else Color(1.0, 0.86, 0.80).lerp(Color(0.32, 0.36, 0.55, 0.75), clampf(-e / 0.25, 0.0, 1.0))
	for c in _clouds:
		c.modulate = cloud

func _process(delta: float) -> void:
	_t += delta
	var layer := get_parent() as CanvasLayer
	if layer != null and not layer.visible:
		clock = fmod(clock + delta, DAY + NIGHT)       # скрыта — сутки всё равно идут
		return
	_apply_time(delta)
	var e := _elev()
	var night := clampf(-e * 3.0, 0.0, 1.0)
	# ветер: медленно «дышит», иногда порыв
	_wind = 1.0 + 0.6 * sin(_t * 0.23) + 0.5 * maxf(0.0, sin(_t * 0.9)) * maxf(0.0, sin(_t * 0.17))
	for st in _star_list:
		st[0].modulate.a = 0.55 + 0.45 * sin(_t * st[2] + st[1])
	for c in _clouds:
		c.position.x += float(c.get_meta("speed")) * px * 2.2 * _wind * delta
		if c.position.x > vs.x + 20.0:
			c.position.x = -50.0 * px
			c.position.y = at(0, _rng.randf_range(6, 60)).y
	_update_birds(delta, e)
	_update_river(delta, night)
	_update_flies(delta, night)
	_update_grass(delta)
	_update_petals(delta, e)

# ---------- Птицы (днём) и летучие мыши (ночью) ----------
func _update_birds(delta: float, e: float) -> void:
	_bird_t -= delta
	if _bird_t <= 0.0 and absf(e) > 0.15:
		_bird_t = _rng.randf_range(7.0, 14.0)
		var dir := 1.0 if _rng.randf() < 0.6 else -1.0
		var y := _rng.randf_range(18.0, 70.0)
		var bat := e < 0.0
		var n := _rng.randi_range(2, 3) if bat else _rng.randi_range(3, 6)
		for i in n:
			var b := Node2D.new()
			var wing := Line2D.new()
			wing.width = px
			wing.default_color = Color(0.10, 0.08, 0.12) if bat else Color(0.22, 0.22, 0.30)
			b.add_child(wing)
			var x0 := -10.0 if dir > 0 else IW + 10.0
			var off := Vector2(-dir * i * _rng.randf_range(6.0, 9.0), (i % 2) * 4.0 + i * 1.5)
			b.position = at(x0 + off.x, y + off.y)
			add_child(b)
			_birds.append({"n": b, "wing": wing, "dir": dir, "speed": _rng.randf_range(22.0, 30.0) * (1.4 if bat else 1.0),
					"phase": _rng.randf_range(0.0, TAU), "bat": bat, "bob": _rng.randf_range(0.0, TAU)})
	for bd in _birds.duplicate():
		var b: Node2D = bd["n"]
		bd["phase"] += delta * (16.0 if bd["bat"] else 9.0)
		var flap := sin(bd["phase"])
		var w: Line2D = bd["wing"]
		var s := px
		if bd["bat"]:
			w.points = PackedVector2Array([Vector2(-3 * s, flap * 2 * s), Vector2(-1 * s, 0), Vector2(0, s * 0.5), Vector2(1 * s, 0), Vector2(3 * s, flap * 2 * s)])
		else:
			w.points = PackedVector2Array([Vector2(-3 * s, -flap * 1.6 * s), Vector2(0, 0), Vector2(3 * s, -flap * 1.6 * s)])
		b.position.x += bd["dir"] * bd["speed"] * px * delta * 0.6
		b.position.y += sin(_t * 1.3 + bd["bob"]) * px * delta * 2.0
		if b.position.x < -60.0 or b.position.x > vs.x + 60.0:
			b.queue_free()
			_birds.erase(bd)

# ---------- Река: бегущие блики ----------
func _river_x(y: float) -> Vector2:
	var t := y - 121.0
	return Vector2(100.0 + t * 0.9 + 14.0 * sin(t / 9.0), 1.0 + t * 0.12)     # середина и полуширина

func _update_river(delta: float, night: float) -> void:
	var day_c := Color(0.80, 0.92, 1.0)
	var night_c := Color(0.90, 0.92, 0.75)
	for g in _glints:
		g[1] += g[3] * delta
		if g[1] >= IH:
			g[1] = 121.0 + _rng.randf_range(0.0, 6.0)
			g[2] = _rng.randf_range(-1.0, 1.0)
		var r := _river_x(g[1])
		var x: float = r.x + g[2] * r.y * (0.4 if night > 0.5 else 1.0)       # ночью блики собираются в лунную дорожку
		var rect: ColorRect = g[0]
		rect.position = at(floorf(x), floorf(g[1]))
		var a := 0.35 + 0.45 * absf(sin(_t * 3.0 + g[1]))
		rect.color = Color(day_c.lerp(night_c, night), a * (0.7 + 0.3 * night))

# ---------- Светлячки над полем ночью ----------
func _update_flies(delta: float, night: float) -> void:
	for fd in _flies:
		var fly: ColorRect = fd[0]
		fd[2] += delta
		var p: Vector2 = fd[1] + Vector2(sin(fd[2] * 0.7) * 6.0, cos(fd[2] * 0.9) * 3.0)
		fly.position = at(floorf(p.x), floorf(p.y))
		fly.modulate.a = night * clampf(0.5 + 0.5 * sin(fd[2] * 2.3), 0.0, 1.0)
		fly.visible = night > 0.02

# ---------- Трава гнётся на ветру ----------
func _update_grass(_delta: float) -> void:
	for gd in _grass:
		var tuft: Polygon2D = gd[0]
		var sway: float = sin(_t * 2.1 + gd[1] * 0.11) * 0.12 + 0.18 * (_wind - 1.0)
		tuft.skew = clampf(sway, -0.6, 0.7)

# ---------- Лепестки и листья носит ветер ----------
func _update_petals(delta: float, e: float) -> void:
	_petal_t -= delta * _wind
	if _petal_t <= 0.0:
		_petal_t = _rng.randf_range(0.25, 0.9)
		var p := Polygon2D.new()
		p.polygon = PackedVector2Array([Vector2(-1, 0), Vector2(0, -0.7), Vector2(1, 0), Vector2(0, 0.7)])
		p.scale = Vector2(px, px)
		var cols := [Color(1, 0.9, 0.95), Color(1, 0.85, 0.4), Color(0.55, 0.8, 0.35), Color(0.95, 0.55, 0.6)]
		p.color = cols[_rng.randi_range(0, cols.size() - 1)]
		if e < 0.0:
			p.color = p.color.darkened(0.55)
		p.position = Vector2(-10.0, at(0, _rng.randf_range(100.0, IH)).y)
		add_child(p)
		_petals.append([p, _rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 1.3)])
	for pd in _petals.duplicate():
		var p: Polygon2D = pd[0]
		pd[1] += delta * 3.0
		p.position += Vector2(px * 18.0 * _wind * pd[2], px * sin(pd[1]) * 6.0) * delta
		p.rotation += delta * 4.0
		if p.position.x > vs.x + 20.0:
			p.queue_free()
			_petals.erase(pd)
