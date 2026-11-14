class_name TitanRobot
extends Node2D
# ---------- Титан — ульта Почти легенды «Привет от Титана» ----------
# Огромный робот поднимается из-под арены и бьёт по всей карте сам, пока герой сражается.
# Модель — пиксель-арт, как у героев (каждая деталь — маленькая картинка ×4): ноги с
# наколенниками, таз, бронированный торс с ядром, голова с визором и антенной, наплечники с
# ракетными люками. Руки собраны из плеча, локтя и предплечья с выдвижным поршнем:
# рука замахивается (локоть сгибается), разгибается к цели, поршень выстреливает кулак —
# так он дотягивается до любого места на арене.
# Порядок: машет «ПРИВЕТ!» → удары кулаками (тень показывает, куда) → град ракет из
# наплечников → лазеры из глаз метут по полу → топот (ударные волны по земле) → ядро в груди
# копит энергию и выпускает шар — взрыв на всю карту → уходит под землю.

const PX := 4.0
const STEEL := Color(0.25, 0.27, 0.32)
const STEEL_L := Color(0.38, 0.41, 0.48)
const STEEL_H := Color(0.58, 0.62, 0.70)
const STEEL_D := Color(0.15, 0.16, 0.20)
const OUTL := Color(0.06, 0.06, 0.08)
const WHITE := Color(0.90, 0.92, 0.95)
const L1 := 34.0 * PX               # плечо
const L2 := 30.0 * PX               # предплечье
const EXT_MAX := 1150.0             # насколько выдвигается поршень

var owner_p: Player
var kit: Node
var mega := false
var base := Vector2.ZERO
var floor_y := 0.0                  # где пол арены (сам робот стоит глубже — за ареной)
var done := false

var _orange := Color(1.0, 0.52, 0.14)
var _cyan := Color(0.30, 0.90, 1.0)
var _root: Node2D
var _head: Node2D
var _eyes: Array = []
var _eye_glow := 1.0
var _antenna: Polygon2D
var _core: Polygon2D
var _core_glow: Polygon2D
var _arms: Array = []
var _pads: Array = []
var _t := 0.0
var _queue: Array = []
var _step := 0.0
var _laser: Array = []
var _scorch_t := 0.0
var _vent_t := 1.0
var _fist_i := 0

class Arm:
	var side := 1
	var shoulder: Node2D
	var elbow: Node2D
	var piston: Polygon2D
	var piston_in: Polygon2D
	var piston_hi: Polygon2D
	var fist: Node2D
	var cur := Vector2.ZERO          # куда тянется кисть (в координатах тела)
	var rest := Vector2.ZERO
	var busy := false

func _ready() -> void:
	z_index = -3
	_orange = Skins.col(owner_p, AlmostKit.ORANGE)
	_cyan = Skins.col(owner_p, AlmostKit.CYAN)
	_root = Node2D.new()
	add_child(_root)
	_build()
	position = base + Vector2(0, 640)
	_eye_glow = 0.0
	var tw := create_tween()
	tw.tween_property(self, "position", base, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _eye_glow = 1.0)
	var world := get_parent()
	Fx.shake(world, 12.0)
	Audio.sfx("servo", base)
	for k in 6:
		Fx.dust(world, Vector2(base.x + randf_range(-200, 200), floor_y), 4, Color(0.55, 0.50, 0.45), 120.0, 24.0)
	Fx.debris(world, Vector2(base.x, floor_y), 14, Color(0.45, 0.40, 0.36), 560.0, 8.0)
	var n_fist := 5 if mega else 3
	_queue = [[1.1, "wave"]]
	for k in n_fist:
		_queue.append([0.95, "fist"])
	_queue.append_array([[1.5, "rockets"], [2.1, "lasers"], [1.2, "stomp"], [1.4, "core"], [1.4, "orb"], [0.0, "leave"]])
	_step = 1.4

# ======================= модель (пиксель-арт) =======================
static func _im(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)

static func _px(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, c)

# прямоугольник с фаской: светлый верх и левый край, тёмный низ и правый, тёмный контур
static func _plate(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	im.fill_rect(Rect2i(x, y, w, h), c)
	im.fill_rect(Rect2i(x + 1, y + 1, w - 2, 1), c.lightened(0.22))
	im.fill_rect(Rect2i(x + 1, y + 1, 1, h - 2), c.lightened(0.12))
	im.fill_rect(Rect2i(x + 1, y + h - 2, w - 2, 1), c.darkened(0.25))
	im.fill_rect(Rect2i(x + w - 2, y + 1, 1, h - 2), c.darkened(0.18))
	im.fill_rect(Rect2i(x, y, w, 1), OUTL)
	im.fill_rect(Rect2i(x, y + h - 1, w, 1), OUTL)
	im.fill_rect(Rect2i(x, y, 1, h), OUTL)
	im.fill_rect(Rect2i(x + w - 1, y, 1, h), OUTL)

static func _rivet(im: Image, x: int, y: int) -> void:
	_px(im, x, y, STEEL_H)
	_px(im, x + 1, y + 1, STEEL_D)

func _sprite(parent: Node2D, im: Image, pivot: Vector2, at: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(im)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.offset = -pivot
	s.scale = Vector2(PX, PX)
	s.position = at
	parent.add_child(s)
	return s

func _build() -> void:
	for s in [-1, 1]:                                        # ноги
		var foot := _im(28, 10)
		_plate(foot, 0, 2, 28, 8, STEEL)
		foot.fill_rect(Rect2i(1 if s < 0 else 18, 3, 9, 6), _orange)        # носок
		foot.fill_rect(Rect2i(4, 0, 20, 3), STEEL_D)
		_rivet(foot, 12, 4)
		_sprite(_root, foot, Vector2(14, 10), Vector2(s * 13 * PX, 0))
		var shin := _im(16, 26)
		_plate(shin, 1, 0, 14, 26, STEEL)
		_plate(shin, 0, 2, 16, 9, WHITE)                                  # наколенник
		shin.fill_rect(Rect2i(3, 5, 10, 1), _orange)
		for k in 3:
			shin.fill_rect(Rect2i(4, 14 + k * 4, 8, 1), STEEL_D)              # рёбра голени
		_sprite(_root, shin, Vector2(8, 26), Vector2(s * 13 * PX, -10 * PX))
		var thigh := _im(18, 22)
		_plate(thigh, 0, 0, 18, 22, STEEL_L)
		thigh.fill_rect(Rect2i(2, 8, 14, 2), STEEL_D)
		thigh.fill_rect(Rect2i(s * 4 + 7, 2, 3, 18), _orange.darkened(0.15))   # полоса
		_rivet(thigh, 3, 3)
		_rivet(thigh, 13, 3)
		_sprite(_root, thigh, Vector2(9, 22), Vector2(s * 13 * PX, -36 * PX))
	var pelvis := _im(46, 12)                                 # таз с предупреждающими полосами
	_plate(pelvis, 0, 0, 46, 12, STEEL_D)
	for x in range(2, 44, 4):
		pelvis.fill_rect(Rect2i(x, 3, 2, 6), _orange)
	pelvis.fill_rect(Rect2i(19, 2, 8, 8), STEEL_L)
	_sprite(_root, pelvis, Vector2(23, 12), Vector2(0, -58 * PX))
	_sprite(_root, _torso_img(), Vector2(32, 46), Vector2(0, -70 * PX))
	_core_glow = Polygon2D.new()                              # свечение ядра поверх груди
	_core_glow.polygon = Util.circle(15.0 * PX, 24)
	_core_glow.color = Color(_cyan, 0.22)
	_core_glow.position = Vector2(0, -96 * PX)
	_root.add_child(_core_glow)
	_core = Polygon2D.new()
	_core.polygon = Util.circle(5.0 * PX, 16)
	_core.color = _cyan.lightened(0.2)
	_core.position = _core_glow.position
	_root.add_child(_core)
	for s in [-1, 1]:
		_arms.append(_make_arm(s))
	for s in [-1, 1]:                                         # наплечники с ракетными люками
		var pad := _im(26, 18)
		for y in 18:
			var inset := maxi(0, 4 - y)
			pad.fill_rect(Rect2i(inset, y, 26 - inset * 2, 1), _orange if y < 13 else _orange.darkened(0.25))
		pad.fill_rect(Rect2i(0, 0, 26, 1), OUTL)
		pad.fill_rect(Rect2i(2, 13, 22, 2), WHITE)
		for k in 3:
			pad.fill_rect(Rect2i(5 + k * 6, 3, 4, 4), STEEL_D)               # люки
			_px(pad, 6 + k * 6, 4, Color(1.0, 0.85, 0.5))
		_rivet(pad, 2, 9)
		_rivet(pad, 22, 9)
		var ps := _sprite(_root, pad, Vector2(13, 12), Vector2(s * 36 * PX, -110 * PX))
		_pads.append(ps)
	_head = Node2D.new()
	_head.position = Vector2(0, -116 * PX)
	_root.add_child(_head)
	var hd := _im(30, 26)
	_plate(hd, 2, 4, 26, 22, STEEL)
	hd.fill_rect(Rect2i(3, 4, 24, 3), _orange)                          # гребень
	hd.fill_rect(Rect2i(5, 11, 20, 6), OUTL)                            # визор
	hd.fill_rect(Rect2i(6, 12, 18, 4), STEEL_D)
	hd.fill_rect(Rect2i(0, 13, 3, 7), STEEL_L)                          # «уши»-вентиляция
	hd.fill_rect(Rect2i(27, 13, 3, 7), STEEL_L)
	for y in range(14, 20, 2):
		_px(hd, 1, y, STEEL_D)
		_px(hd, 28, y, STEEL_D)
	hd.fill_rect(Rect2i(9, 20, 12, 2), STEEL_D)                         # решётка рта
	for x in range(10, 21, 2):
		_px(hd, x, 20, STEEL_H)
	hd.fill_rect(Rect2i(14, 0, 2, 4), STEEL_D)                          # антенна
	_sprite(_head, hd, Vector2(15, 26), Vector2.ZERO)
	for s in [-1, 1]:
		var eye := Polygon2D.new()
		eye.polygon = PackedVector2Array([Vector2(-3, -1.5) * PX, Vector2(3, -1.5) * PX, Vector2(3, 1.5) * PX, Vector2(-3, 1.5) * PX])
		eye.position = Vector2(s * 5 * PX, -12 * PX)
		eye.color = _cyan
		_head.add_child(eye)
		_eyes.append(eye)
	_antenna = Polygon2D.new()
	_antenna.polygon = Util.circle(1.5 * PX, 8)
	_antenna.position = Vector2(0, -27 * PX)
	_antenna.color = Color(1.0, 0.3, 0.25)
	_head.add_child(_antenna)

func _torso_img() -> Image:
	var im := _im(64, 46)
	for y in 46:                                              # трапеция: шире в плечах
		var inset := int(y * 7 / 46)
		im.fill_rect(Rect2i(inset, y, 64 - inset * 2, 1), STEEL if y > 2 else STEEL_L)
		_px(im, inset, y, OUTL)
		_px(im, 63 - inset, y, OUTL)
	im.fill_rect(Rect2i(0, 0, 64, 1), OUTL)
	im.fill_rect(Rect2i(7, 45, 50, 1), OUTL)
	_plate(im, 6, 3, 22, 16, STEEL_L)                         # грудные пластины
	_plate(im, 36, 3, 22, 16, STEEL_L)
	im.fill_rect(Rect2i(7, 17, 20, 1), _orange)
	im.fill_rect(Rect2i(37, 17, 20, 1), _orange)
	for k in 3:
		im.fill_rect(Rect2i(10 + k * 5, 6, 3, 1), STEEL_H)                 # щели на пластинах
		im.fill_rect(Rect2i(40 + k * 5, 6, 3, 1), STEEL_H)
	for y in 15:                                              # гнездо ядра
		for x in 15:
			var d := Vector2(x - 7, y - 7).length()
			if d <= 7.4:
				_px(im, 25 + x, 19 + y, OUTL if d > 6.2 else STEEL_D)
	im.fill_rect(Rect2i(14, 36, 36, 2), STEEL_D)              # пресс-рёбра и вентиляция
	for x in range(16, 48, 3):
		im.fill_rect(Rect2i(x, 39, 2, 4), STEEL_D)
	im.fill_rect(Rect2i(2, 22, 6, 12), _orange.darkened(0.1))   # боковые полосы
	im.fill_rect(Rect2i(56, 22, 6, 12), _orange.darkened(0.1))
	_px(im, 5, 25, WHITE)
	_px(im, 58, 25, WHITE)
	for p in [[4, 4], [59, 4], [11, 30], [52, 30]]:
		_rivet(im, p[0], p[1])
	return im

func _make_arm(s: int) -> Arm:
	var a := Arm.new()
	a.side = s
	a.shoulder = Node2D.new()
	a.shoulder.position = Vector2(s * 36 * PX, -108 * PX)
	_root.add_child(a.shoulder)
	var up := _im(14, 36)                                     # плечо: гидравлика и шарнир
	_plate(up, 2, 2, 10, 32, STEEL)
	up.fill_rect(Rect2i(0, 0, 14, 6), STEEL_D)
	up.fill_rect(Rect2i(4, 8, 1, 22), _cyan.darkened(0.3))              # шланг
	up.fill_rect(Rect2i(9, 10, 2, 16), STEEL_H)
	for y in 7:
		for x in 7:
			if Vector2(x - 3, y - 3).length() <= 3.5:
				_px(up, 4 + x, 29 + y, STEEL_D if Vector2(x - 3, y - 3).length() > 2.0 else STEEL_H)
	_sprite(a.shoulder, up, Vector2(7, 3), Vector2.ZERO)
	a.elbow = Node2D.new()
	a.elbow.position = Vector2(0, L1)
	a.shoulder.add_child(a.elbow)
	var fore := _im(18, 32)                                   # предплечье: броня, полоса, гнездо поршня
	_plate(fore, 1, 0, 16, 30, STEEL_L)
	fore.fill_rect(Rect2i(2, 10, 14, 4), _orange)
	fore.fill_rect(Rect2i(2, 13, 14, 1), _orange.darkened(0.3))
	fore.fill_rect(Rect2i(5, 26, 8, 6), OUTL)
	fore.fill_rect(Rect2i(6, 27, 6, 4), STEEL_D)
	_rivet(fore, 3, 3)
	_rivet(fore, 13, 3)
	_rivet(fore, 3, 20)
	_rivet(fore, 13, 20)
	_sprite(a.elbow, fore, Vector2(9, 2), Vector2.ZERO)
	a.piston = Polygon2D.new()                                # поршень: контур, сталь, блик (в пикселях)
	a.piston.color = OUTL
	a.elbow.add_child(a.piston)
	a.piston_in = Polygon2D.new()
	a.piston_in.color = STEEL_H
	a.elbow.add_child(a.piston_in)
	a.piston_hi = Polygon2D.new()
	a.piston_hi.color = Color(0.86, 0.89, 0.95)
	a.elbow.add_child(a.piston_hi)
	a.fist = Node2D.new()
	a.elbow.add_child(a.fist)
	var fs := _im(24, 22)                                     # кулак: пальцы, костяшки, огни
	_plate(fs, 1, 0, 22, 20, STEEL)
	fs.fill_rect(Rect2i(2, 12, 20, 8), WHITE)
	for k in 4:
		fs.fill_rect(Rect2i(3 + k * 5, 12, 1, 8), STEEL_D)                 # пальцы
		_px(fs, 4 + k * 5, 18, _cyan)                                       # огоньки на костяшках
	fs.fill_rect(Rect2i(0, 4, 3, 8), STEEL_L)                            # большой палец
	fs.fill_rect(Rect2i(21, 4, 3, 8), STEEL_L)
	fs.fill_rect(Rect2i(2, 20, 20, 2), OUTL)
	_sprite(a.fist, fs, Vector2(12, 2), Vector2.ZERO)
	a.rest = a.shoulder.position + Vector2(s * 58.0, L1 + L2 - 30.0)
	a.cur = a.rest
	_solve(a, a.cur)
	return a

# ======================= руки: двухзвенная «инверсная кинематика» =======================
# Кисть тянется в точку: локоть сгибается наружу и вверх, а если не хватает длины —
# выдвигается поршень предплечья.
func _solve(a: Arm, target: Vector2) -> void:
	var S := a.shoulder.position
	var v := target - S
	var d := maxf(v.length(), 1.0)
	var ext := clampf(d - L1 - L2 + 2.0, 0.0, EXT_MAX)
	var l2 := L2 + ext
	var dd := clampf(d, absf(L1 - l2) + 1.0, L1 + l2 - 1.0)
	var phi := v.angle()
	var ca := clampf((L1 * L1 + dd * dd - l2 * l2) / (2.0 * L1 * dd), -1.0, 1.0)
	var al := acos(ca)
	var best := 0.0
	var best_score := -INF
	for sg in [1.0, -1.0]:
		var e: Vector2 = Vector2.from_angle(phi + sg * al) * L1
		var score: float = a.side * e.x - 0.6 * e.y          # локоть — наружу и вверх
		if score > best_score:
			best_score = score
			best = phi + sg * al
	var E := S + Vector2.from_angle(best) * L1
	var phi2 := (target - E).angle()
	a.shoulder.rotation = best - PI / 2
	a.elbow.rotation = phi2 - best
	var y0 := L2 - 6.0
	var y1 := L2 + ext
	a.piston.polygon = _bar(-3.0 * PX, 3.0 * PX, y0, y1)
	a.piston_in.polygon = _bar(-2.0 * PX, 2.0 * PX, y0, y1)
	a.piston_hi.polygon = _bar(-1.0 * PX, 0.0, y0, y1)
	for pp in [a.piston, a.piston_in, a.piston_hi]:
		(pp as Polygon2D).visible = ext > 2.0
	a.fist.position = Vector2(0, L2 + ext - 4.0)

static func _bar(x0: float, x1: float, y0: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])

func _move_arm(a: Arm, to: Vector2, time: float, trans := Tween.TRANS_SINE, ease := Tween.EASE_IN_OUT) -> Tween:
	var tw := create_tween()
	tw.tween_method(func(q: Vector2):
		a.cur = q, a.cur, to, time).set_trans(trans).set_ease(ease)
	return tw

# ======================= каждый кадр =======================
func _physics_process(delta: float) -> void:
	if done:
		return
	if not is_instance_valid(owner_p) or kit == null or not is_instance_valid(kit):
		_leave()
		return
	_t += delta
	_root.position.y = sin(_t * 1.6) * 3.0                    # «дыхание» корпуса
	_head.rotation = sin(_t * 0.9) * 0.03
	for a in _arms:
		var arm: Arm = a
		if not arm.busy:
			arm.cur = arm.cur.lerp(arm.rest + Vector2(0, sin(_t * 1.3 + arm.side) * 6.0), delta * 4.0)
		_solve(arm, arm.cur)
	var blink := 0.25 if fmod(_t, 3.7) < 0.12 else 1.0
	for e in _eyes:
		(e as Polygon2D).color = Color(_cyan.lightened(0.15 * sin(_t * 8.0)), _eye_glow * blink)
	_antenna.visible = fmod(_t, 1.0) < 0.5
	_core_glow.scale = _core_glow.scale.lerp(Vector2.ONE * (1.0 + 0.08 * sin(_t * 5.0)), delta * 3.0)
	_vent_t -= delta
	if _vent_t <= 0.0:                                        # пар из наплечников
		_vent_t = randf_range(1.2, 2.2)
		for p in _pads:
			Fx.smoke(get_parent(), (p as Node2D).global_position + Vector2(0, -40), 14.0, Color(0.85, 0.87, 0.9), 90.0)
	_tick_lasers(delta)
	_step -= delta
	if _step <= 0.0 and not _queue.is_empty():
		var item: Array = _queue.pop_front()
		_step = float(item[0])
		call("_do_" + String(item[1]))

func _foes() -> Array:
	if not is_instance_valid(owner_p) or kit == null or not is_instance_valid(kit):
		return []
	return kit._enemies()

func _ground(at: Vector2) -> Vector2:
	return kit._ground_below(at)

func _local(world_pt: Vector2) -> Vector2:
	return _root.to_local(world_pt)

# ======================= приёмы =======================
# Машет «ПРИВЕТ!»: правая рука поднимается, локоть сгибается и разгибается
func _do_wave() -> void:
	var l := Label.new()
	l.text = "ПРИВЕТ!"
	l.add_theme_font_size_override("font_size", 44)
	l.add_theme_color_override("font_color", _orange)
	l.add_theme_constant_override("outline_size", 9)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.07))
	l.position = global_position + Vector2(-90, -700)
	l.z_index = 9
	get_parent().add_child(l)
	var lt := l.create_tween()
	lt.tween_property(l, "scale", Vector2(1.15, 1.15), 0.12)
	lt.tween_property(l, "scale", Vector2.ONE, 0.12)
	lt.tween_interval(0.8)
	lt.tween_property(l, "modulate:a", 0.0, 0.3)
	lt.tween_callback(l.queue_free)
	var a: Arm = _arms[1]
	a.busy = true
	var up := a.shoulder.position + Vector2(70, -150)
	var tw := _move_arm(a, up, 0.3)
	for k in 3:
		tw.tween_method(func(q: Vector2): a.cur = q, up, up + Vector2(70, 40), 0.16)
		tw.tween_method(func(q: Vector2): a.cur = q, up + Vector2(70, 40), up, 0.16)
	tw.tween_method(func(q: Vector2): a.cur = q, up, a.rest, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): a.busy = false)

# Удар кулаком: тень на полу растёт, рука замахивается (локоть сгибается за плечом),
# потом разгибается к цели — поршень выстреливает кулак — удар, кулак возвращается
func _do_fist() -> void:
	var es := _foes()
	var at := global_position + Vector2(randf_range(-600.0, 600.0), 0)
	if not es.is_empty():
		var e: Player = es[_fist_i % es.size()]
		at = e.global_position + Vector2(0, e.body_size.y / 2)
	_fist_i += 1
	at = _ground(at + Vector2(0, -30))
	var a: Arm = _arms[0 if at.x < global_position.x else 1]
	if a.busy:
		a = _arms[1 - _arms.find(a)]
	a.busy = true
	var world := get_parent()
	var shadow := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 24:
		var ang := TAU * k / 24.0
		pts.append(Vector2(cos(ang) * 120.0, sin(ang) * 24.0))
	shadow.polygon = pts
	shadow.color = Color(0, 0, 0, 0.4)
	shadow.position = at
	shadow.scale = Vector2(0.15, 0.15)
	shadow.z_index = 4
	world.add_child(shadow)
	var st := shadow.create_tween()
	st.tween_property(shadow, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var mark := Fx.rune_circle(world, at, 120.0, Color(_orange, 0.75), 0.8)
	var cock := a.shoulder.position + Vector2(-a.side * 40.0, -170.0)   # замах: кисть за плечом
	var hit_local := _local(at + Vector2(0, -10))
	var tw := _move_arm(a, cock, 0.55, Tween.TRANS_BACK, Tween.EASE_OUT)
	tw.tween_callback(func():
		a.shoulder.z_index = 8                                 # рука выходит на передний план
		Audio.sfx("swing_heavy", global_position))
	tw.tween_method(func(q: Vector2): a.cur = q, cock, hit_local, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if is_instance_valid(shadow):
			shadow.queue_free()
		if is_instance_valid(mark):
			mark.queue_free()
		_fist_hit(at))
	tw.tween_interval(0.28)
	tw.tween_method(func(q: Vector2): a.cur = q, hit_local, a.rest, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		a.shoulder.z_index = 0
		a.busy = false)

func _fist_hit(at: Vector2) -> void:
	var world := get_parent()
	Fx.shake(world, 13.0)
	Fx.shockwave(world, at, 170.0, Color(1.0, 0.85, 0.6, 0.9), 0.3)
	Fx.dust(world, at, 10, Color(0.60, 0.55, 0.50), 170.0, 26.0)
	Fx.debris(world, at, 14, Color(0.42, 0.38, 0.34), 520.0, 8.0)
	Fx.cracks(world, at, Color(0.15, 0.13, 0.12), 170.0)
	Fx.sparks(world, at, Color(1.0, 0.8, 0.5), 10, 320.0, 4.0, true)
	Audio.sfx("slam", at)
	for e in _foes():
		var d: Vector2 = e.global_position + Vector2(0, e.body_size.y / 2) - at
		if absf(d.x) < 125.0 + e.body_size.x * 0.4 and d.y > -170.0 and d.y < 40.0:
			e.take_damage(26 if mega else 20, owner_p)
			if e.is_alive() and e.stagger_max <= 0.0:
				e.velocity = Vector2(signf(d.x if d.x != 0.0 else 1.0) * 420.0, -420.0)

# Град ракет из наплечников: люки дымят, ракеты уходят вверх с дымным следом и падают в круги
func _do_rockets() -> void:
	var n := 16 if mega else 10
	var es := _foes()
	var world := get_parent()
	for p in _pads:
		var pp: Node2D = p
		var tw := pp.create_tween()
		tw.tween_property(pp, "position:y", pp.position.y + 10.0, 0.08)
		tw.tween_property(pp, "position:y", pp.position.y, 0.2)
	for k in n:
		var at := global_position + Vector2(randf_range(-780.0, 780.0), 0)
		if k % 2 == 0 and not es.is_empty():
			var e: Player = es[(k / 2) % es.size()]
			at = e.global_position + Vector2(randf_range(-60.0, 60.0), e.body_size.y / 2)
		at = _ground(at + Vector2(0, -40))
		var pad: Node2D = _pads[k % 2]
		var r := TitanRocket.new()
		r.titan = self
		r.src = pad.global_position + Vector2(randf_range(-30, 30), -40)
		r.at = at
		r.delay = k * 0.09
		world.add_child(r)
	Audio.sfx("rocket", global_position)

func rocket_hit(at: Vector2) -> void:
	var world := get_parent()
	Fx.fireball(world, at + Vector2(0, -18), 46.0)
	Fx.debris(world, at, 5, Color(0.40, 0.36, 0.32), 360.0, 5.0)
	Audio.sfx("boom_small", at)
	for e in _foes():
		var d: Vector2 = e.global_position + Vector2(0, e.body_size.y / 2) - at
		if absf(d.x) < 70.0 + e.body_size.x * 0.4 and d.y > -110.0 and d.y < 40.0:
			e.take_damage(8, owner_p)

# Лазеры из глаз: глаза разгораются, тонкие прицелы, потом два толстых луча метут пол
# навстречу друг другу и оставляют выжженный след
func _do_lasers() -> void:
	var gy := floor_y
	var x0 := global_position.x - 840.0
	var x1 := global_position.x + 840.0
	_laser = []
	var tw := create_tween()
	tw.tween_property(self, "_eye_glow", 2.2, 0.5)
	for i in 2:
		var lines: Array = []
		for k in 3:
			var l := Line2D.new()
			l.z_index = 8
			l.begin_cap_mode = Line2D.LINE_CAP_ROUND
			l.end_cap_mode = Line2D.LINE_CAP_ROUND
			get_parent().add_child(l)
			lines.append(l)
		_laser.append({"lines": lines, "from": x0 if i == 0 else x1, "to": x1 if i == 0 else x0, "t": -0.65, "hit": {}, "eye": i, "y": gy})
	Audio.sfx("laser", global_position)

func _tick_lasers(delta: float) -> void:
	if _laser.is_empty():
		return
	_scorch_t -= delta
	var alive: Array = []
	for L in _laser:
		var d: Dictionary = L
		d["t"] = float(d["t"]) + delta
		var lines: Array = d["lines"]
		var q := clampf(float(d["t"]) / 1.4, 0.0, 1.0)
		var x := lerpf(float(d["from"]), float(d["to"]), q)
		var eye: Vector2 = (_eyes[int(d["eye"])] as Node2D).global_position
		var hit_pt := _ground(Vector2(x, float(d["y"]) - 400.0))
		if float(d["t"]) < 0.0:                               # прицел
			var aim := Vector2(float(d["from"]), float(d["y"]))
			for k in 3:
				(lines[k] as Line2D).points = PackedVector2Array([eye, aim])
				(lines[k] as Line2D).width = [1.5, 0.0, 0.0][k]
				(lines[k] as Line2D).default_color = Color(1.0, 0.3, 0.3, 0.7)
			alive.append(d)
			continue
		var widths := [26.0, 13.0, 4.0]
		var cols := [Color(1.0, 0.20, 0.20, 0.30), Color(1.0, 0.35, 0.30, 0.85), Color(1.0, 0.95, 0.9)]
		for k in 3:
			var l: Line2D = lines[k]
			l.points = PackedVector2Array([eye, hit_pt])
			l.width = float(widths[k]) * (1.0 + 0.15 * sin(_t * 40.0 + k))
			l.default_color = cols[k]
		Fx.sparks(get_parent(), hit_pt, Color(1.0, 0.55, 0.3), 2, 200.0, 3.0, true)
		if _scorch_t <= 0.0:
			_scorch(hit_pt)
		for e in _foes():
			if (d["hit"] as Dictionary).has(e):
				continue
			var seg_d := Geometry2D.get_closest_point_to_segment(e.hurt_center(), eye, hit_pt).distance_to(e.hurt_center())
			if seg_d < e.body_size.x * 0.5 + 10.0:
				(d["hit"] as Dictionary)[e] = true
				e.take_damage(14, owner_p)
				e.burn(1.5, 4.0, owner_p)
		if q >= 1.0:
			for l in lines:
				(l as Line2D).queue_free()
			continue
		alive.append(d)
	if _scorch_t <= 0.0:
		_scorch_t = 0.05
	_laser = alive
	if _laser.is_empty():
		var tw := create_tween()
		tw.tween_property(self, "_eye_glow", 1.0, 0.4)

func _scorch(at: Vector2) -> void:
	var s := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 10:
		var a := TAU * k / 10.0
		pts.append(Vector2(cos(a) * 22.0, sin(a) * 5.0))
	s.polygon = pts
	s.color = Color(0.10, 0.06, 0.05, 0.75)
	s.position = at
	s.z_index = 3
	get_parent().add_child(s)
	var tw := s.create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(s, "modulate:a", 0.0, 0.8)
	tw.tween_callback(s.queue_free)
	if randf() < 0.3:
		Fx.smoke(get_parent(), at, 12.0, Color(0.25, 0.22, 0.22), 50.0)

# Топот: приседает, подпрыгивает и бьёт ногами — по полу в обе стороны бегут волны
func _do_stomp() -> void:
	var tw := create_tween()
	tw.tween_property(_root, "position:y", 18.0, 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position:y", base.y - 60.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", base.y, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_stomp_land)

func _stomp_land() -> void:
	var world := get_parent()
	Fx.shake(world, 16.0)
	Audio.sfx("slam", base)
	for s in [-1, 1]:
		Fx.dust(world, Vector2(base.x + s * 52, floor_y), 8, Color(0.58, 0.53, 0.48), 160.0, 26.0)
		Fx.debris(world, Vector2(base.x + s * 52, floor_y), 8, Color(0.42, 0.38, 0.34), 460.0, 7.0)
		var wv := TitanWave.new()
		wv.titan = self
		wv.dir = s
		wv.position = Vector2(base.x + s * 130.0, floor_y)
		world.add_child(wv)

func wave_hit(e: Player) -> void:
	e.take_damage(10, owner_p)
	if e.is_alive() and e.stagger_max <= 0.0:
		e.velocity.y = -520.0

# Ядро: глаза гаснут, вокруг груди бьют молнии, энергия стекается в ядро
func _do_core() -> void:
	var world := get_parent()
	Audio.sfx("orb", global_position)
	var tw := create_tween()
	tw.tween_property(_core_glow, "scale", Vector2(2.8, 2.8), 1.4).set_trans(Tween.TRANS_SINE)
	var ct := create_tween()
	ct.tween_property(_core_glow, "color", Color(_cyan, 0.55), 1.4)
	for a in _arms:                                           # руки расходятся — «раскрывает грудь»
		var arm: Arm = a
		arm.busy = true
		_move_arm(arm, arm.shoulder.position + Vector2(arm.side * 170.0, 40.0), 0.6, Tween.TRANS_BACK, Tween.EASE_OUT)
	for k in 22:
		var sp := Polygon2D.new()
		sp.polygon = Util.circle(5.0, 6)
		sp.color = Color(_cyan.lightened(0.3), 0.95)
		var ang := randf() * TAU
		sp.position = _core.global_position + Vector2.from_angle(ang) * randf_range(220.0, 320.0)
		sp.z_index = 8
		world.add_child(sp)
		var st := sp.create_tween()
		st.tween_interval(k * 0.055)
		st.tween_property(sp, "position", _core.global_position, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		st.tween_callback(sp.queue_free)
	for k in 6:
		get_tree().create_timer(0.2 + k * 0.2).timeout.connect(func():
			if is_instance_valid(self) and not done:
				var c := _core.global_position
				Fx.bolt(world, c + Vector2.from_angle(randf() * TAU) * 120.0, c, _cyan.lightened(0.3)))

func _do_orb() -> void:
	var world := get_parent()
	var es := _foes()
	var goal := global_position + Vector2(0, -260)
	if not es.is_empty():
		var sum := Vector2.ZERO
		for e in es:
			sum += (e as Player).global_position
		goal = sum / es.size() + Vector2(0, -120)
	var orb := TitanOrb.new()
	orb.titan = self
	orb.mega = mega
	orb.position = _core.global_position
	orb.goal = goal
	world.add_child(orb)
	Util.flash(world, _core.global_position, 160.0, Color(0.85, 0.97, 1.0, 0.9))
	var tw := create_tween()
	tw.tween_property(_core_glow, "scale", Vector2.ONE, 0.3)
	tw.parallel().tween_property(_core_glow, "color", Color(_cyan, 0.22), 0.3)
	tw.parallel().tween_property(_root, "position:y", 12.0, 0.1)        # отдача
	for a in _arms:
		var arm: Arm = a
		_move_arm(arm, arm.rest, 0.6).tween_callback(func(): arm.busy = false)

func orb_blast(at: Vector2) -> void:
	var world := get_parent()
	Util.flash(world, at, 2200.0, Color(0.85, 0.95, 1.0, 0.95))
	Fx.shockwave(world, at, 900.0, _cyan, 1.0)
	Fx.ring(world, at, 520.0, Color(1, 1, 1, 0.9), 0.5, 12.0)
	Fx.ring(world, at, 1300.0, Color(_cyan, 0.5), 0.9, 22.0)
	Fx.sparks(world, at, _cyan.lightened(0.3), 40, 900.0, 6.0)
	Fx.debris(world, at + Vector2(0, 120), 18, Color(0.5, 0.6, 0.7), 700.0, 7.0)
	Fx.shake(world, 22.0)
	Audio.sfx("drop", at)
	Audio.sfx("boom_big", at)
	for e in _foes():
		e.take_damage(30 if mega else 22, owner_p)
		if e.is_alive() and e.stagger_max <= 0.0:
			e.velocity = (e.global_position - at).normalized() * 600.0 + Vector2(0, -300)

func _do_leave() -> void:
	_leave()

func _leave() -> void:
	if done:
		return
	done = true
	for L in _laser:
		for l in (L as Dictionary)["lines"]:
			if is_instance_valid(l):
				(l as Line2D).queue_free()
	_laser = []
	_eye_glow = 0.0
	for e in _eyes:
		(e as Polygon2D).color.a = 0.0
	var world := get_parent()
	if is_instance_valid(world):
		for k in 5:
			Fx.smoke(world, Vector2(base.x + randf_range(-160, 160), floor_y), 26.0, Color(0.7, 0.72, 0.75), 120.0)
	var tw := create_tween()
	tw.tween_property(self, "position:y", base.y + 680.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


# =====================================================================
# Ракета: вылетает вверх из наплечника с дымным следом, потом падает в метку
class TitanRocket extends Node2D:
	var titan: Node2D
	var src := Vector2.ZERO
	var at := Vector2.ZERO
	var delay := 0.0
	var _t := 0.0
	var _mark: Line2D
	var _body: Node2D
	var _trail: Line2D
	const UP := 0.35
	const DOWN := 0.75

	func _ready() -> void:
		z_index = 8
		_mark = Line2D.new()
		var pts := PackedVector2Array()
		for k in 17:
			var a := TAU * k / 16.0
			pts.append(Vector2(cos(a) * 70.0, sin(a) * 18.0))
		_mark.points = pts
		_mark.width = 2.0
		_mark.default_color = Color(1.0, 0.45, 0.2, 0.75)
		_mark.position = at
		add_child(_mark)
		_trail = Line2D.new()
		_trail.width = 6.0
		_trail.default_color = Color(0.85, 0.85, 0.88, 0.45)
		_trail.top_level = true
		add_child(_trail)
		_body = Node2D.new()
		_body.visible = false
		add_child(_body)
		var hull := Polygon2D.new()
		hull.polygon = PackedVector2Array([Vector2(-12, -3), Vector2(8, -3), Vector2(14, 0), Vector2(8, 3), Vector2(-12, 3)])
		hull.color = Color(0.92, 0.92, 0.96)
		_body.add_child(hull)
		var tip := Polygon2D.new()
		tip.polygon = PackedVector2Array([Vector2(8, -3), Vector2(14, 0), Vector2(8, 3)])
		tip.color = Color(1.0, 0.45, 0.15)
		_body.add_child(tip)
		var flame := Polygon2D.new()
		flame.polygon = PackedVector2Array([Vector2(-12, -2.5), Vector2(-24, 0), Vector2(-12, 2.5)])
		flame.color = Color(1.0, 0.75, 0.3)
		flame.name = "Flame"
		_body.add_child(flame)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t < delay:
			return
		_body.visible = true
		var t := _t - delay
		var prev := _body.position
		if t < UP:
			_body.position = src + Vector2(0, -900.0 * (t / UP) * (t / UP))
		else:
			var q := clampf((t - UP) / DOWN, 0.0, 1.0)
			_body.position = Vector2(at.x, at.y - 900.0).lerp(at, q * q)
		if _body.position != prev:
			_body.rotation = (_body.position - prev).angle()
		(_body.get_node("Flame") as Polygon2D).scale.x = randf_range(0.7, 1.3)
		_trail.add_point(_body.global_position)
		while _trail.get_point_count() > 10:
			_trail.remove_point(0)
		_mark.width = 2.0 + clampf(t / (UP + DOWN), 0.0, 1.0) * 3.0
		if randf() < 0.15:
			Fx.smoke(get_parent(), _body.global_position, 8.0, Color(0.75, 0.75, 0.78), 20.0)
		if t >= UP + DOWN:
			if is_instance_valid(titan):
				titan.rocket_hit(at)
			queue_free()

# Ударная волна топота: гребень пыли бежит по полу, бьёт тех, кто на земле
class TitanWave extends Node2D:
	var titan: Node2D
	var dir := 1
	var _t := 0.0
	var _hit := {}

	func _ready() -> void:
		z_index = 7
		var back := Polygon2D.new()
		back.polygon = PackedVector2Array([Vector2(-60, 0), Vector2(-10, -30), Vector2(10, -56), Vector2(30, 0)])
		back.color = Color(0.62, 0.56, 0.50, 0.55)
		add_child(back)
		var w := Polygon2D.new()
		w.polygon = PackedVector2Array([Vector2(-30, 0), Vector2(4, -50), Vector2(30, 0)])
		w.color = Color(1.0, 0.72, 0.38, 0.85)
		add_child(w)
		scale.x = float(dir)

	func _physics_process(delta: float) -> void:
		_t += delta
		position.x += dir * 900.0 * delta
		scale.y = 1.0 + 0.2 * sin(_t * 30.0)
		if randf() < 0.5:
			Fx.dust(get_parent(), position, 1, Color(0.6, 0.55, 0.5), 40.0, 14.0)
		if not is_instance_valid(titan) or _t > 1.4:
			queue_free()
			return
		for e in titan._foes():
			if _hit.has(e):
				continue
			var d: Vector2 = e.global_position + Vector2(0, e.body_size.y / 2) - position
			if absf(d.x) < 30.0 + e.body_size.x * 0.4 and d.y > -40.0 and d.y < 30.0:
				_hit[e] = true
				titan.wave_hit(e)

# Шар энергии из груди: слои света, вихри, искры следом; долетел — взрыв на всю карту
class TitanOrb extends Node2D:
	var titan: Node2D
	var mega := false
	var goal := Vector2.ZERO
	var _t := 0.0
	var _from := Vector2.ZERO
	var _rings: Array = []

	func _ready() -> void:
		z_index = 9
		_from = position
		var layers := [[96.0 if mega else 80.0, Color(0.45, 0.65, 1.0, 0.25)], [62.0 if mega else 52.0, Color(0.20, 0.50, 1.0)],
				[40.0 if mega else 34.0, Color(0.35, 0.85, 1.0)], [18.0, Color(0.92, 0.98, 1.0)]]
		for ly in layers:
			var b := Polygon2D.new()
			b.polygon = Util.circle(float(ly[0]), 28)
			b.color = ly[1]
			add_child(b)
		for k in 6:                                            # «осколки» света внутри
			var sh := Polygon2D.new()
			sh.polygon = PackedVector2Array([Vector2(-4, -6), Vector2(4, -5), Vector2(5, 4), Vector2(-3, 6)])
			sh.position = Vector2.from_angle(TAU * k / 6.0) * 24.0
			sh.color = Color(0.75, 0.95, 1.0, 0.6)
			add_child(sh)
		for k in 3:
			var r := Line2D.new()
			var pts := PackedVector2Array()
			for i in 29:
				var a := TAU * i / 28.0
				pts.append(Vector2(cos(a) * (76.0 + k * 10.0), sin(a) * (24.0 + k * 9.0)))
			r.points = pts
			r.width = 3.0
			r.default_color = Color(0.55, 0.95, 1.0, 0.75 - k * 0.15)
			r.rotation = 0.6 - k * 0.9
			add_child(r)
			_rings.append(r)

	func _physics_process(delta: float) -> void:
		_t += delta
		var q := clampf(_t / 0.75, 0.0, 1.0)
		position = _from.lerp(goal, q * (2.0 - q))
		scale = Vector2.ONE * (0.35 + 0.65 * q) * (1.0 + 0.05 * sin(_t * 30.0))
		for i in _rings.size():
			(_rings[i] as Line2D).rotation += delta * [3.0, -2.4, 1.7][i]
		if randf() < 0.7:
			Fx.sparks(get_parent(), global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40)), Color(0.6, 0.9, 1.0), 1, 80.0, 4.0)
		if q >= 1.0:
			if is_instance_valid(titan):
				titan.orb_blast(global_position)
			queue_free()
