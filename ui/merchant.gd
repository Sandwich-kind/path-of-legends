class_name Merchant
extends Node2D
# Торговец за стойкой — добродушный пожилой лавочник: зелёная кепка с пёрышком,
# круглые очки в золотой оправе, приподнятые брови, румяные щёки, закрученные
# кверху усы и широкая улыбка, аккуратная седая бородка. Кремовая рубашка с
# закатанными рукавами, синяя бабочка, бордовый жилет с золотыми пуговицами и
# цепочкой часов, фартук с карманом (из кармана торчат карандаш и монетка).
# Стоит и дышит, иногда моргает. Когда переставляет товары — поворачивается
# спиной и быстро машет руками, а закончив — довольно жмурится.
# Рисунок 40 × 48 «пикселей», точка (0, 0) — середина нижнего края.

const SKIN := Color(0.96, 0.77, 0.63)
const SKIN_SH := Color(0.86, 0.63, 0.51)
const CHEEK := Color(0.98, 0.56, 0.50)
const HAIR := Color(0.78, 0.74, 0.70)          # седые с тёплым отливом
const HAIR_SH := Color(0.62, 0.58, 0.55)
const CAP := Color(0.28, 0.46, 0.30)
const FEATHER := Color(1.0, 0.82, 0.30)
const SHIRT := Color(0.96, 0.92, 0.82)
const VEST := Color(0.58, 0.18, 0.20)
const BOW := Color(0.22, 0.40, 0.70)
const GOLD := Color(0.95, 0.76, 0.30)
const APRON := Color(0.86, 0.80, 0.64)
const EYE := Color(0.20, 0.13, 0.09)
const OUT := Color(0.14, 0.09, 0.07)

var _body: Sprite2D
var _arm_l: Sprite2D
var _arm_r: Sprite2D
var _front_tex: Texture2D
var _blink_tex: Texture2D
var _happy_tex: Texture2D
var _back_tex: Texture2D
var _t := 0.0
var busy := false            # переставляет товары
var _back := false
var _blink_t := 2.5
var _blinking := 0.0
var _happy := 0.0
var _was_busy := false

func _ready() -> void:
	_front_tex = ImageTexture.create_from_image(_draw_body(false, "open"))
	_blink_tex = ImageTexture.create_from_image(_draw_body(false, "blink"))
	_happy_tex = ImageTexture.create_from_image(_draw_body(false, "happy"))
	_back_tex = ImageTexture.create_from_image(_draw_body(true, "open"))
	var arm := ImageTexture.create_from_image(_draw_arm())
	_body = Sprite2D.new()
	_body.texture = _front_tex
	_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body.centered = false
	_body.offset = Vector2(-20, -48)
	add_child(_body)
	_arm_l = _part(arm, Vector2(3, 1), Vector2(-13, -27))
	_arm_r = _part(arm, Vector2(3, 1), Vector2(13, -27))
	_arm_r.scale.x = -1

func _part(tex: Texture2D, pivot: Vector2, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.offset = -pivot
	s.position = pos
	add_child(s)
	return s

static func _r(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	im.fill_rect(Rect2i(x, y, w, h), c)

static func _p(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, c)

# eyes: "open" — глаза открыты, "blink" — моргнул, "happy" — довольно жмурится (^^)
func _draw_body(back: bool, eyes: String) -> Image:
	var im := Image.create(40, 48, false, Image.FORMAT_RGBA8)
	# ---------- туловище: рубашка, жилет, фартук ----------
	_r(im, 6, 28, 28, 20, OUT)
	_r(im, 7, 29, 26, 19, VEST)
	_r(im, 7, 29, 26, 1, VEST.lightened(0.18))                    # плечи
	if not back:
		_r(im, 16, 29, 8, 8, SHIRT)                               # ворот рубашки в вырезе жилета
		for k in 4:
			_p(im, 15 + k / 2, 30 + k, OUT)                         # края выреза
			_p(im, 24 - k / 2, 30 + k, OUT)
		_r(im, 17, 30, 6, 2, BOW)                                 # бабочка
		_r(im, 16, 29, 2, 4, BOW)
		_r(im, 22, 29, 2, 4, BOW)
		_r(im, 19, 30, 2, 2, BOW.darkened(0.25))
		_p(im, 16, 29, BOW.lightened(0.25))
		for y in [34, 37]:                                        # пуговицы жилета
			_p(im, 15, y, GOLD)
			_p(im, 24, y, GOLD)
		for k in 6:                                               # цепочка карманных часов
			_p(im, 9 + k, 34 + int(abs(sin(k * 0.6)) * 2.0), GOLD)
		_r(im, 8, 33, 2, 2, GOLD.darkened(0.15))                 # часы в кармашке
		# фартук
		_r(im, 12, 37, 16, 11, APRON)
		_r(im, 12, 37, 16, 1, APRON.lightened(0.12))
		_r(im, 11, 37, 1, 11, OUT)
		_r(im, 28, 37, 1, 11, OUT)
		_r(im, 15, 41, 10, 5, APRON.darkened(0.10))                # карман
		_r(im, 15, 41, 10, 1, APRON.darkened(0.22))
		_r(im, 17, 39, 1, 3, Color(0.95, 0.80, 0.25))              # карандаш
		_p(im, 17, 38, Color(0.25, 0.20, 0.18))
		_r(im, 21, 40, 2, 2, GOLD)                                 # монетка
		_p(im, 21, 40, GOLD.lightened(0.4))
		_r(im, 12, 37, 16, 1, Color(0.70, 0.62, 0.45))             # тесёмка
	else:
		_r(im, 19, 30, 2, 18, VEST.darkened(0.25))                # шов на спине
		_r(im, 9, 40, 22, 1, APRON)                                # завязки фартука
		_r(im, 18, 40, 4, 3, APRON)
		_r(im, 17, 43, 2, 3, APRON.darkened(0.1))
		_r(im, 21, 43, 2, 3, APRON.darkened(0.1))
	# ---------- голова ----------
	_r(im, 10, 6, 20, 23, OUT)
	_r(im, 11, 7, 18, 21, SKIN if not back else HAIR)
	_r(im, 8, 15, 3, 6, SKIN)                                      # уши
	_r(im, 29, 15, 3, 6, SKIN)
	_r(im, 8, 15, 1, 6, OUT)
	_r(im, 31, 15, 1, 6, OUT)
	_p(im, 9, 17, SKIN_SH)
	_p(im, 30, 17, SKIN_SH)
	if not back:
		_r(im, 11, 9, 2, 8, HAIR)                                  # седые виски
		_r(im, 27, 9, 2, 8, HAIR)
		_p(im, 12, 16, HAIR_SH)
		_p(im, 27, 16, HAIR_SH)
		# брови — приподняты домиком, добрые
		for i in 4:
			_p(im, 13 + i, 12 - (1 if i == 1 or i == 2 else 0), HAIR_SH)
			_p(im, 23 + i, 12 - (1 if i == 1 or i == 2 else 0), HAIR_SH)
		# глаза
		match eyes:
			"open":
				_r(im, 14, 14, 3, 3, Color.WHITE)
				_r(im, 23, 14, 3, 3, Color.WHITE)
				_r(im, 15, 15, 2, 2, EYE)
				_r(im, 24, 15, 2, 2, EYE)
				_p(im, 16, 15, Color(1, 1, 1))                         # блик
				_p(im, 25, 15, Color(1, 1, 1))
			"blink":
				_r(im, 14, 16, 3, 1, EYE)
				_r(im, 23, 16, 3, 1, EYE)
			"happy":                                                  # жмурится от удовольствия: ^^
				for e in [14, 23]:
					_p(im, e, 16, EYE)
					_r(im, e + 1, 15, 1, 1, EYE)
					_p(im, e + 2, 16, EYE)
					_p(im, e + 1, 14, SKIN_SH)
		_p(im, 13, 17, SKIN_SH)                                        # морщинки-смешинки
		_p(im, 26, 17, SKIN_SH)
		# круглые очки в золотой оправе
		for e in [13, 22]:
			_r(im, e, 13, 5, 1, GOLD)
			_r(im, e, 17, 5, 1, GOLD)
			_r(im, e, 14, 1, 3, GOLD)
			_r(im, e + 4, 14, 1, 3, GOLD)
		_r(im, 18, 14, 4, 1, GOLD)                                     # перемычка
		# нос-картошка и румянец
		_r(im, 19, 17, 3, 3, SKIN_SH)
		_r(im, 19, 18, 3, 2, SKIN.darkened(0.05))
		_p(im, 20, 18, SKIN.lightened(0.2))
		_r(im, 12, 18, 3, 2, CHEEK)
		_r(im, 25, 18, 3, 2, CHEEK)
		# усы, закрученные кверху
		_r(im, 15, 20, 10, 2, HAIR)
		_r(im, 15, 20, 10, 1, HAIR.lightened(0.1))
		_r(im, 13, 19, 2, 2, HAIR)
		_r(im, 25, 19, 2, 2, HAIR)
		_p(im, 12, 18, HAIR)
		_p(im, 27, 18, HAIR)
		_p(im, 19, 21, HAIR_SH)
		_p(im, 20, 21, HAIR_SH)
		# широкая улыбка
		_r(im, 16, 22, 8, 2, Color(0.50, 0.18, 0.16))
		_r(im, 17, 22, 6, 1, Color(1.0, 0.98, 0.94))                   # зубы
		_p(im, 15, 21, Color(0.50, 0.18, 0.16))
		_p(im, 24, 21, Color(0.50, 0.18, 0.16))
		_r(im, 17, 24, 6, 1, SKIN_SH)                                  # нижняя губа
		# аккуратная бородка клинышком
		_r(im, 13, 25, 14, 2, HAIR)
		_r(im, 15, 27, 10, 1, HAIR)
		_r(im, 18, 28, 4, 1, HAIR)
		_p(im, 19, 29, HAIR_SH)
		_p(im, 20, 29, HAIR_SH)
		_p(im, 15, 26, HAIR_SH)
		_p(im, 24, 26, HAIR_SH)
	else:
		_r(im, 11, 22, 18, 6, HAIR_SH)                                 # затылок
		_r(im, 13, 27, 14, 1, SKIN_SH)                                 # шея
	# ---------- кепка с пёрышком ----------
	_r(im, 9, 1, 22, 9, OUT)
	_r(im, 10, 2, 20, 7, CAP)
	_r(im, 10, 2, 20, 1, CAP.lightened(0.22))
	_r(im, 10, 7, 20, 2, CAP.darkened(0.30))                           # околыш
	_p(im, 20, 3, CAP.lightened(0.10))                                 # пуговка на макушке
	if not back:
		_r(im, 9, 9, 23, 1, OUT)
		_r(im, 22, 9, 10, 2, CAP.darkened(0.15))                       # козырёк
		_r(im, 22, 11, 10, 1, OUT)
	for k in 6:                                                         # пёрышко за лентой
		_p(im, (27 if not back else 12) + k / 2, 6 - k, FEATHER if k < 5 else FEATHER.lightened(0.3))
		_p(im, (28 if not back else 13) + k / 2, 6 - k, FEATHER.darkened(0.15))
	return im

func _draw_arm() -> Image:
	var im := Image.create(7, 20, false, Image.FORMAT_RGBA8)
	_r(im, 0, 0, 7, 12, OUT)
	_r(im, 1, 1, 5, 11, SHIRT)                       # рукав рубашки
	_r(im, 1, 1, 5, 1, SHIRT.lightened(0.05))
	_r(im, 1, 4, 5, 1, SHIRT.darkened(0.08))         # складки
	_r(im, 0, 10, 7, 3, OUT)
	_r(im, 1, 10, 5, 2, SHIRT.darkened(0.12))        # закатанный рукав
	_r(im, 0, 12, 7, 8, OUT)
	_r(im, 1, 12, 5, 4, SKIN)                        # предплечье
	_r(im, 1, 16, 5, 3, SKIN)                        # кисть
	_p(im, 0, 16, SKIN)                              # большой палец
	_r(im, 2, 18, 1, 1, SKIN_SH)                     # пальцы
	_r(im, 4, 18, 1, 1, SKIN_SH)
	return im

# Повернуться спиной (true) или лицом (false)
func turn(to_back: bool, time := 0.14) -> void:
	if _back == to_back:
		return
	_back = to_back
	var t := create_tween()
	t.tween_property(_body, "scale:x", 0.0, time / 2.0)
	t.tween_callback(func(): _body.texture = _back_tex if to_back else _face())
	t.tween_property(_body, "scale:x", 1.0, time / 2.0)

func _face() -> Texture2D:
	if _happy > 0.0:
		return _happy_tex
	return _blink_tex if _blinking > 0.0 else _front_tex

func _process(delta: float) -> void:
	_t += delta
	if _was_busy and not busy:
		_happy = 0.9                                 # всё расставил — довольно жмурится
	_was_busy = busy
	if not _back:
		_happy = maxf(0.0, _happy - delta)
		_blink_t -= delta
		if _blink_t <= 0.0:
			_blink_t = randf_range(2.2, 4.5)
			_blinking = 0.13
		_blinking = maxf(0.0, _blinking - delta)
		_body.texture = _face()
	if busy:
		# быстро машет руками, переставляя товары
		_arm_l.rotation = sin(_t * 32.0) * 1.4 + 0.6
		_arm_r.rotation = -sin(_t * 32.0 + 1.3) * 1.4 - 0.6
		_body.position.y = absf(sin(_t * 16.0)) * -1.0
		_body.position.x = sin(_t * 9.0) * 1.0
	else:
		# спокойно дышит и чуть покачивается, будто напевает
		var b := sin(_t * 2.2)
		_body.scale.y = 1.0 + b * 0.018
		_body.position = Vector2.ZERO
		_body.rotation = sin(_t * 1.1) * 0.02
		_arm_l.rotation = lerp_angle(_arm_l.rotation, -0.32 + b * 0.02, minf(1.0, delta * 10.0))
		_arm_r.rotation = lerp_angle(_arm_r.rotation, 0.32 - b * 0.02, minf(1.0, delta * 10.0))
		_arm_l.position.y = -27 - b * 0.4
		_arm_r.position.y = -27 - b * 0.4
