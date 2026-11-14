class_name ScribeKit
extends HeroKit
# ---------- ЛЕТОПИСЕЦ — легенда из Лавки (её придумал Claude, ИИ, что помогал делать игру) ----------
# Тот, кто пишет Книгу легенд. Сам он не воин: его оружие — перо, чернила и слово.
# Тёмно-синяя мантия писаря, бумажный шарф с строчками, берет с пером, круглые очки,
# за спиной — толстая книга на ремне с золотой застёжкой, пальцы в чернилах.
#
# Оружие «Перо»: летят чернильные буквы. Каждое попадание дописывает слово ЛЕГЕНДА
#   над головой (7 букв — столько же в обойме). Слово дописано — следующий выстрел
#   ставит «Точку»: тяжёлая клякса, бьёт втрое сильнее и забрызгивает чернилами всех
#   рядом (ранит и замедляет).
# 1 «Сноска» — надстрочная цифра летит в ближайшего врага: ранит и на 6 с помечает —
#   по нему проходит на 25% больше урона от всех (по боссам — на 15%). Если помеченный
#   погиб, сноска перескакивает на соседа. МЕГА: три сноски — три врага (¹ ² ³).
# 2 «Черновик» — оставляет на месте чернильную копию себя. В течение 4 с нажми ещё раз —
#   «Отменить»: Летописец возвращается к черновику, возвращает 60% здоровья, потерянного
#   с тех пор, а там, где он стоял, разбрызгиваются чернила. Не нажал — черновик
#   «сохраняется» и лечит 15% потерянного. МЕГА: возвращает всё потерянное, снимает
#   оглушение и замедление, черновик живёт 5 с.
# 3 «Абзац» — пишет перед собой страницу-стену: она ловит чужие снаряды и отталкивает
#   врагов. Когда страница кончается (через 4 с или если её пробили), буквы с неё
#   слетают вперёд залпом. МЕГА: страница выше и прочнее, буквы пробивают насквозь.
# Ульта «Последняя глава» — в небе раскрывается огромная книга. 3 с с её страниц на
#   врагов падают строки: каждая ранит и «зачёркивает» (враг на миг замирает). Потом
#   книга захлопывается — и на самого сильного врага ложится печать «КОНЕЦ».
#   МЕГА: глава длиннее, строк больше, а в конце «…и жили они долго и счастливо» —
#   все свои лечатся на 20%.

const INK := Color(0.16, 0.24, 0.55)
const INK_HI := Color(0.50, 0.68, 1.0)
const PAPER := Color(0.96, 0.92, 0.80)
const GOLD := Color(1.0, 0.82, 0.38)
const WORD := "ЛЕГЕНДА"

var _shot_i := 0
var _letters := 0                # сколько букв слова уже дописано попаданиями
var _dot_ready := false
var _word: Node2D                # слово над головой
var _word_lit: Label
var _word_dim: Label
var _draft: Node2D               # черновик (пока жив — можно «Отменить»)
var _draft_i := -1
var _draft_t := 0.0
var _draft_hp := 0
var _draft_mega := false
var _ult_t := 0.0
var _ult_mega := false
var _line_t := 0.0
var _book: Node2D

# ---------- Оружие: перо ----------
func weapon(delta: float, shoot: bool) -> void:
	var rapid := p.has_buff("rapid")
	_word_tick()
	if p._reloading > 0.0:
		p._reloading -= delta
		if p._reloading <= 0.0:
			p._reloading = 0.0
			p.ammo = p.clip_size
	elif not p.is_bot and Input.is_action_just_pressed(p.prefix + "_reload") and p.ammo < p.clip_size:
		p._reloading = p.reload_time
	if rapid:
		p._reloading = 0.0
		p.ammo = p.clip_size
	if not shoot or p._cooldown_left > 0.0 or p._reloading > 0.0:
		return
	if _dot_ready:
		_shoot_dot()
	else:
		var b := p._shoot_bullet(p.bullet_speed, p.bullet_damage, 0.0, p.bullet_size, randf_range(-0.02, 0.02))
		b.glyph = WORD[_shot_i % WORD.length()]
		b.restyle("ink")
		b.on_hit = _letter_hit
		if rapid and p.is_mega("rapid"):
			b.pierce = 2
		_shot_i += 1
	p._anim("throw")
	p._cooldown_left = p.fire_cooldown * (0.5 if rapid else 1.0)
	if not rapid:
		p.ammo -= 1
		if p.ammo <= 0:
			p._reloading = p.reload_time

func _letter_hit(body: Node) -> void:
	if not (body is Player) or not is_instance_valid(p) or _dot_ready:
		return
	_letters += 1
	if _letters >= WORD.length():
		_letters = WORD.length()
		_dot_ready = true
		p._float_label("ЛЕГЕНДА.", Skins.col(p, INK_HI))
	_word_update()

# «Точка»: тяжёлая клякса, в конце пути забрызгивает всех рядом
func _shoot_dot() -> void:
	_dot_ready = false
	_letters = 0
	_word_update()
	var b := p._shoot_bullet(p.bullet_speed * 0.85, p.bullet_damage * 3, 0.0, p.bullet_size * 2.0, 0.0)
	b.glyph = "•"
	b.restyle("ink_dot")
	var me: WeakRef = weakref(self)
	var bw: WeakRef = weakref(b)
	b.tree_exiting.connect(func():
		var k: Variant = me.get_ref()
		var bb: Variant = bw.get_ref()
		if k and bb and is_instance_valid(k.p) and k.p.is_inside_tree() and float(bb.get("_life")) > 0.0:
			k._splash.call_deferred(bb.global_position, 110.0, 12))     # мир сейчас занят удалением капли

func _splash(at: Vector2, r: float, dmg: int) -> void:
	var world := p.get_parent()
	if world == null:
		return
	Fx.ring(world, at, r, Color(Skins.col(p, INK), 0.85), 0.35, 7.0)
	Fx.sparks(world, at, Skins.col(p, INK), 16, 300.0, 5.0)
	Fx.sparks(world, at, Skins.col(p, INK_HI), 6, 200.0, 3.0)
	_blot(world, at, r * 0.55)
	for e in _enemies():
		if (e.hurt_center() - at).length() < r + e.body_size.x * 0.4:
			e.take_damage(dmg, p)
			e.slow(1.5, 0.6, "water")

# Клякса на месте брызг: тает за секунду
func _blot(world: Node, at: Vector2, r: float) -> void:
	var bl := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 14:
		var a := TAU * k / 14.0
		pts.append(Vector2(cos(a), sin(a) * 0.6) * r * (0.7 + 0.3 * absf(sin(k * 2.3))))
	bl.polygon = pts
	bl.color = Color(Skins.col(p, INK), 0.7)
	bl.position = at
	bl.z_index = -1
	world.add_child(bl)
	var tw := bl.create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(bl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(bl.queue_free)

# Слово над головой: дописанные буквы яркие, остальные — бледные
func _word_tick() -> void:
	if _word == null or not is_instance_valid(_word):
		_word = Node2D.new()
		_word.z_index = 8
		p.add_child(_word)
		_word_dim = Label.new()
		_word_lit = Label.new()
		for l in [_word_dim, _word_lit]:
			(l as Label).add_theme_font_size_override("font_size", 15)
			(l as Label).add_theme_constant_override("outline_size", 4)
			(l as Label).add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.10))
			_word.add_child(l)
		_word_dim.text = WORD
		_word_dim.modulate = Color(1, 1, 1, 0.28)
		_word_update()
	_word.position = Vector2(-_word_dim.get_minimum_size().x / 2, -p.body_size.y / 2 - 48)
	_word.visible = p.is_alive() and (_letters > 0 or _dot_ready)
	if _dot_ready:
		_word_lit.modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.012)

func _word_update() -> void:
	if _word_lit == null or not is_instance_valid(_word_lit):
		return
	_word_lit.text = WORD.substr(0, _letters) + ("." if _dot_ready else "")
	_word_lit.add_theme_color_override("font_color", Skins.col(p, INK_HI) if not _dot_ready else Skins.col(p, GOLD))
	_word_lit.modulate.a = 1.0

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	if ab == "draft" and _draft != null and is_instance_valid(_draft):
		p._cd[i] = 0.0                                   # пока черновик жив — кнопка «Отменить»
		if Input.is_action_just_pressed(action):
			_undo()
		return
	super(i, ab, action, delta)
	if ab == "draft" and _draft != null and is_instance_valid(_draft):
		_draft_i = i
		p._cd[i] = 0.0

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"footnote":
			_footnote(mega)
		"draft":
			_place_draft(mega)
		"paragraph":
			_paragraph(mega)

# ----- 1. Сноска -----
func _footnote(mega: bool) -> void:
	p._anim("throw")
	var es := _enemies().filter(func(e): return not e.cutscene_shield and e.global_position.distance_to(p.global_position) < 1000.0)
	es.sort_custom(func(a, b):
		var da: float = a.global_position.distance_to(p.global_position) - (200.0 if signf(a.global_position.x - p.global_position.x) == p.facing else 0.0)
		var db: float = b.global_position.distance_to(p.global_position) - (200.0 if signf(b.global_position.x - p.global_position.x) == p.facing else 0.0)
		return da < db)
	var n := 3 if mega else 1
	var marks := ["¹", "²", "³"]
	for k in n:
		var f := Footnote.new()
		f.owner_p = p
		f.glyph = marks[k]
		f.target = es[k] if k < es.size() else null
		f.dir = Vector2(p.facing, -0.15 * k).normalized()
		f.position = p.global_position + Vector2(p.facing * 22.0, -26.0 - k * 10.0)
		p.get_parent().add_child(f)

# ----- 2. Черновик -----
func _place_draft(mega: bool) -> void:
	p._anim("cast")
	_draft_mega = mega
	_draft_t = 5.0 if mega else 4.0
	_draft_hp = p.hp
	_draft = Draft.new()
	_draft.owner_p = p
	_draft.life = _draft_t
	_draft.position = p.global_position
	p.get_parent().add_child(_draft)
	p._float_label("Черновик сохранён", Skins.col(p, INK_HI))

func _draft_tick(delta: float) -> void:
	if _draft == null or not is_instance_valid(_draft):
		_draft = null                                    # черновик пропал вместе с картой (смена локации)
		_end_draft()
		return
	_draft_t -= delta
	(_draft as Draft).life = _draft_t
	if _draft_t <= 0.0:
		# не отменил — черновик «сохраняется»: немного лечит
		var lost := maxi(0, _draft_hp - p.hp)
		if lost > 0:
			p.heal(int(lost * 0.15))
		p._float_label("Сохранено", Skins.col(p, INK_HI))
		Fx.sparks(p.get_parent(), _draft.global_position, Skins.col(p, INK_HI), 10, 160.0, 3.0, true)
		_end_draft()

func _undo() -> void:
	if _draft == null or not is_instance_valid(_draft):
		return
	var world := p.get_parent()
	var from := p.global_position
	var to: Vector2 = _draft.global_position
	_splash(from, 120.0 if _draft_mega else 100.0, 18)              # там, где стоял, — брызги чернил
	p.global_position = to
	p.velocity = Vector2.ZERO
	var lost := maxi(0, _draft_hp - p.hp)
	if lost > 0:
		p.heal(int(lost * (1.0 if _draft_mega else 0.6)))
	if _draft_mega:
		p._stun_t = 0.0
		p._slow_t = 0.0
		p.glitch_t = 0.0
	p._float_label("Отменить!", Skins.col(p, GOLD))
	var tr := Line2D.new()                                        # чернильный росчерк от места к черновику
	tr.points = PackedVector2Array([from, (from + to) / 2 + Vector2(0, -60), to])
	tr.width = 6.0
	tr.default_color = Color(Skins.col(p, INK_HI), 0.8)
	world.add_child(tr)
	var tw := tr.create_tween()
	tw.tween_property(tr, "modulate:a", 0.0, 0.35)
	tw.tween_callback(tr.queue_free)
	Fx.ring(world, to, 70.0, Color(Skins.col(p, INK_HI), 0.9), 0.3, 5.0)
	_end_draft()

func _end_draft() -> void:
	if _draft and is_instance_valid(_draft):
		(_draft as Draft).vanish()
	_draft = null
	if _draft_i >= 0:
		p._cd[_draft_i] = p.ability_cds[_draft_i]                  # откат — после черновика
	_draft_i = -1

# ----- 3. Абзац -----
func _paragraph(mega: bool) -> void:
	p._anim("cast")
	var pg := Page.new()
	pg.owner_p = p
	pg.mega = mega
	pg.dir = p.facing
	pg.life = (5.0 if mega else 4.0) + (1.0 if Balance.arena(p) else 0.0)
	pg.hp = 320 if mega else 220
	pg.tall = 190.0 if mega else 150.0
	pg.position = p.global_position + Vector2(p.facing * 80.0, p.body_size.y / 2)
	p.get_parent().add_child(pg)

# ---------- Ульта: Последняя глава ----------
func ult() -> void:
	_ult_mega = p._mega_ab()
	_ult_t = 4.0 if _ult_mega else 3.0
	_line_t = 0.3
	p._anim("cast")
	p._float_label("Последняя глава!", Skins.col(p, GOLD))
	_book = BigBook.new()
	_book.owner_p = p
	_book.position = p.global_position + Vector2(0, -260)
	p.get_parent().add_child(_book)

func ulting() -> bool:
	return _ult_t > 0.0

func _ult_tick(delta: float) -> void:
	_ult_t -= delta
	if is_instance_valid(_book):
		_book.position = _book.position.lerp(p.global_position + Vector2(0, -260), minf(1.0, delta * 2.0))
	_line_t -= delta
	if _line_t <= 0.0:
		_line_t = 0.14 if _ult_mega else 0.2
		_strike_line()
	if _ult_t <= 0.0:
		_the_end()

func _ult_targets() -> Array:
	var at: Vector2 = _book.global_position if is_instance_valid(_book) else p.global_position
	return _enemies().filter(func(e): return not e.cutscene_shield and absf(e.global_position.x - at.x) < 1100.0)

# строка падает со страницы на врага и «зачёркивает» его
func _strike_line() -> void:
	var es := _ult_targets()
	if es.is_empty():
		return
	var e: Player = es[randi() % es.size()]
	var world := p.get_parent()
	var from: Vector2 = (_book.global_position if is_instance_valid(_book) else p.global_position) + Vector2(randf_range(-60, 60), 10)
	var to := e.hurt_center()
	var ln := InkLine.new()
	ln.from = from
	ln.to = to
	ln.col = Skins.col(p, INK_HI)
	world.add_child(ln)
	var wr: WeakRef = weakref(e)
	var me: WeakRef = weakref(self)
	ln.landed.connect(func():
		var ee: Variant = wr.get_ref()
		var k: Variant = me.get_ref()
		if ee == null or k == null or not is_instance_valid(k.p) or not ee.is_alive():
			return
		ee.take_damage(9 if not k._ult_mega else 11, k.p)
		if ee.stagger_max <= 0.0:
			ee.root(0.35)
		var cross := Line2D.new()                                   # зачёркнуто
		var c: Vector2 = ee.hurt_center()
		cross.points = PackedVector2Array([c + Vector2(-ee.body_size.x * 0.7, -4), c + Vector2(ee.body_size.x * 0.7, 4)])
		cross.width = 4.0
		cross.default_color = Skins.col(k.p, ScribeKit.INK)
		cross.z_index = 7
		ee.get_parent().add_child(cross)
		var tw := cross.create_tween()
		tw.tween_interval(0.25)
		tw.tween_property(cross, "modulate:a", 0.0, 0.25)
		tw.tween_callback(cross.queue_free))

# книга захлопывается: печать «КОНЕЦ» на самого сильного врага
func _the_end() -> void:
	_ult_t = 0.0
	var world := p.get_parent()
	var es := _ult_targets()
	var best: Player = null
	for e in es:
		if best == null or e.hp > best.hp:
			best = e
	if is_instance_valid(_book):
		(_book as BigBook).slam()
	if best:
		var at := best.hurt_center()
		var stamp := Label.new()
		stamp.text = "КОНЕЦ"
		stamp.add_theme_font_size_override("font_size", 46)
		stamp.add_theme_color_override("font_color", Skins.col(p, Color(0.85, 0.15, 0.15)))
		stamp.add_theme_constant_override("outline_size", 8)
		stamp.add_theme_color_override("font_outline_color", Color(0.10, 0.04, 0.04))
		stamp.position = at + Vector2(-80, -40)
		stamp.rotation = -0.12
		stamp.z_index = 9
		stamp.scale = Vector2(2.2, 2.2)
		world.add_child(stamp)
		var tw := stamp.create_tween()
		tw.tween_property(stamp, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(0.7)
		tw.tween_property(stamp, "modulate:a", 0.0, 0.4)
		tw.tween_callback(stamp.queue_free)
		Fx.shake(world, 10.0)
		Fx.ring(world, at, 120.0, Color(Skins.col(p, GOLD), 0.95), 0.4, 8.0)
		best.take_damage(90 if _ult_mega else 60, p)
		for e in es:
			if e != best and (e.hurt_center() - at).length() < 130.0:
				e.take_damage(20, p)
	if _ult_mega:
		p._float_label("…и жили они долго и счастливо", Skins.col(p, GOLD))
		for n in world.get_children():
			if n is Player and n.team == p.team and n.is_alive():
				n.heal(int(n.max_hp * 0.2))
				Fx.sparks(world, n.hurt_center(), Skins.col(p, GOLD), 10, 160.0, 3.0, true)

func _physics_process(delta: float) -> void:
	if p == null or not p.is_alive():
		return
	if _draft != null:
		_draft_tick(delta)
	if _ult_t > 0.0:
		_ult_tick(delta)

func on_death() -> void:
	super()
	_end_draft()
	_letters = 0
	_dot_ready = false
	_word_update()
	if _ult_t > 0.0:
		_ult_t = 0.0
		if is_instance_valid(_book):
			(_book as BigBook).slam()


# =====================================================================
# Сноска: надстрочная цифра летит к врагу, ранит и помечает его
class Footnote extends Node2D:
	var owner_p: Player
	var target: Variant = null
	var glyph := "¹"
	var dir := Vector2.RIGHT
	var _t := 0.0
	var _lbl: Label
	var _mark_t := 0.0             # >0 — уже висит над врагом
	var _hit := false

	func _ready() -> void:
		z_index = 8
		_lbl = Label.new()
		_lbl.text = glyph
		_lbl.add_theme_font_size_override("font_size", 30)
		_lbl.add_theme_color_override("font_color", Skins.col(owner_p, ScribeKit.INK_HI))
		_lbl.add_theme_constant_override("outline_size", 6)
		_lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.14))
		_lbl.position = Vector2(-8, -20)
		add_child(_lbl)

	func _physics_process(delta: float) -> void:
		_t += delta
		if not is_instance_valid(owner_p):
			queue_free()
			return
		if not _hit:
			_fly(delta)
		else:
			_hang(delta)

	func _fly(delta: float) -> void:
		if target != null and (not is_instance_valid(target) or not target.is_alive()):
			target = owner_p.kit._nearest_enemy(900.0) if owner_p.kit else null
		if target != null:
			var want: Vector2 = (target.hurt_center() - global_position).normalized()
			dir = dir.lerp(want, minf(1.0, delta * 8.0)).normalized()
			if global_position.distance_to(target.hurt_center()) < 26.0:
				_land()
				return
		global_position += dir * 950.0 * delta
		if randf() < 0.5:
			Fx.sparks(get_parent(), global_position, Skins.col(owner_p, ScribeKit.INK_HI), 1, 40.0, 2.5)
		if _t > 1.6:
			queue_free()

	func _land() -> void:
		_hit = true
		_mark_t = 6.0
		target.take_damage(16, owner_p)
		_apply()
		Fx.ring(get_parent(), target.hurt_center(), 40.0, Color(Skins.col(owner_p, ScribeKit.INK_HI), 0.9), 0.25, 4.0)

	func _apply() -> void:
		target.mark_t = maxf(target.mark_t, _mark_t)
		target.mark_mult = 1.15 if target.stagger_max > 0.0 else 1.25

	# висит над врагом; враг погиб — перескакивает на соседа
	func _hang(delta: float) -> void:
		_mark_t -= delta
		if _mark_t <= 0.0:
			queue_free()
			return
		if not is_instance_valid(target) or not target.is_alive():
			var at := global_position
			var best: Player = null
			var bd := 420.0
			for e in owner_p.kit._enemies():
				var d: float = e.global_position.distance_to(at)
				if d < bd and e.mark_t <= 0.0:
					bd = d
					best = e
			if best == null:
				queue_free()
				return
			target = best
			_apply()
			Fx.bolt(get_parent(), at, best.hurt_center(), Skins.col(owner_p, ScribeKit.INK_HI))
		target.mark_t = maxf(target.mark_t, minf(_mark_t, 0.2))
		global_position = target.global_position + Vector2(target.body_size.x * 0.4, -target.body_size.y / 2 - 18 + sin(_t * 4.0) * 3.0)
		_lbl.modulate.a = 0.6 + 0.4 * sin(_t * 6.0) if _mark_t < 1.5 else 1.0

# Черновик: чернильная копия Летописца, тает по краям, пока не кончится время
class Draft extends Node2D:
	var owner_p: Player
	var life := 4.0
	var _max := 4.0
	var _t := 0.0
	var _ring: Line2D
	var _ghost: Node2D

	func _ready() -> void:
		z_index = -1
		_max = life
		var bs: Vector2 = owner_p.body_size
		_ghost = Node2D.new()
		add_child(_ghost)
		var body := Polygon2D.new()                                 # силуэт: голова, мантия, книга за спиной
		body.polygon = PackedVector2Array([Vector2(-bs.x * 0.36, bs.y * 0.5), Vector2(-bs.x * 0.30, -bs.y * 0.12),
				Vector2(-bs.x * 0.18, -bs.y * 0.30), Vector2(bs.x * 0.18, -bs.y * 0.30), Vector2(bs.x * 0.30, -bs.y * 0.12), Vector2(bs.x * 0.40, bs.y * 0.5)])
		body.color = Color(Skins.col(owner_p, ScribeKit.INK), 0.55)
		_ghost.add_child(body)
		var head := Polygon2D.new()
		head.polygon = Util.circle(bs.x * 0.22, 10)
		head.position = Vector2(0, -bs.y * 0.42)
		head.color = Color(Skins.col(owner_p, ScribeKit.INK), 0.6)
		_ghost.add_child(head)
		for k in 4:                                                 # строчки по силуэту — это черновик
			var ln := Line2D.new()
			var y := -bs.y * 0.18 + k * bs.y * 0.16
			ln.points = PackedVector2Array([Vector2(-bs.x * 0.22, y), Vector2(bs.x * (0.10 + 0.08 * (k % 2)), y)])
			ln.width = 2.0
			ln.default_color = Color(Skins.col(owner_p, ScribeKit.INK_HI), 0.7)
			_ghost.add_child(ln)
		_ring = Line2D.new()
		_ring.width = 3.0
		_ring.default_color = Color(Skins.col(owner_p, ScribeKit.INK_HI), 0.8)
		_ring.position = Vector2(0, -bs.y * 0.42)
		add_child(_ring)
		var tag := Label.new()
		tag.text = "Ctrl+Z"
		tag.add_theme_font_size_override("font_size", 14)
		tag.add_theme_color_override("font_color", Color(Skins.col(owner_p, ScribeKit.INK_HI), 0.9))
		tag.add_theme_constant_override("outline_size", 4)
		tag.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.14))
		tag.position = Vector2(-24, -bs.y * 0.42 - 44)
		add_child(tag)

	func _process(delta: float) -> void:
		_t += delta
		_ghost.position.y = sin(_t * 3.0) * 2.0
		var k := clampf(life / _max, 0.0, 1.0)
		var pts := PackedVector2Array()
		for i in int(k * 24.0) + 1:
			var a := -PI / 2 + TAU * i / 24.0
			pts.append(Vector2(cos(a), sin(a)) * 18.0)
		_ring.points = pts
		if randf() < 0.15:
			Fx.sparks(get_parent(), global_position + Vector2(randf_range(-12, 12), randf_range(-20, 20)), Color(Skins.col(owner_p, ScribeKit.INK), 0.8), 1, 40.0, 2.5, true)

	func vanish() -> void:
		set_process(false)
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.3)
		tw.tween_callback(queue_free)

# Страница-стена «Абзаца»: ловит чужие снаряды, отталкивает врагов, в конце буквы слетают залпом
class Page extends Node2D:
	var owner_p: Player
	var mega := false
	var dir := 1
	var life := 4.0
	var hp := 220
	var tall := 150.0
	var _t := 0.0
	var _push_t := 0.0
	var _done := false
	var _sheet: Polygon2D
	const W := 30.0

	func _ready() -> void:
		z_index = 4
		_sheet = Polygon2D.new()
		_sheet.polygon = PackedVector2Array([Vector2(-W / 2, 0), Vector2(-W / 2, -tall), Vector2(W / 2 - 6, -tall), Vector2(W / 2, -tall + 6), Vector2(W / 2, 0)])
		_sheet.color = Skins.col(owner_p, ScribeKit.PAPER)
		add_child(_sheet)
		var edge := Line2D.new()
		edge.points = PackedVector2Array([Vector2(-W / 2, 0), Vector2(-W / 2, -tall), Vector2(W / 2 - 6, -tall), Vector2(W / 2, -tall + 6), Vector2(W / 2, 0), Vector2(-W / 2, 0)])
		edge.width = 2.0
		edge.default_color = Skins.col(owner_p, ScribeKit.GOLD)
		add_child(edge)
		var cap := Label.new()                                      # буквица
		cap.text = "А"
		cap.add_theme_font_size_override("font_size", 22)
		cap.add_theme_color_override("font_color", Skins.col(owner_p, Color(0.75, 0.15, 0.15)))
		cap.position = Vector2(-W / 2 + 3, -tall + 2)
		add_child(cap)
		var y := -tall + 34.0
		while y < -8.0:                                             # строчки текста
			var ln := Line2D.new()
			var x1 := W / 2 - 4 - fmod(absf(y) * 0.37, 9.0)
			ln.points = PackedVector2Array([Vector2(-W / 2 + 4, y), Vector2(x1, y)])
			ln.width = 2.0
			ln.default_color = Color(Skins.col(owner_p, ScribeKit.INK), 0.85)
			add_child(ln)
			y += 9.0
		scale = Vector2(0.2, 1.0)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
		Fx.sparks(get_parent(), position + Vector2(0, -tall / 2), Skins.col(owner_p, ScribeKit.INK_HI), 10, 200.0, 3.0)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _done:
			return
		if not is_instance_valid(owner_p):
			queue_free()
			return
		_sheet.position.x = sin(_t * 5.0) * 0.8
		var rect := Rect2(global_position + Vector2(-W / 2 - 6, -tall), Vector2(W + 12, tall))
		for n in get_parent().get_children():
			if n is Bullet and n.team != owner_p.team and not n.is_queued_for_deletion() and rect.has_point(n.global_position):
				hp -= int(n.damage)
				Fx.sparks(get_parent(), n.global_position, Skins.col(owner_p, ScribeKit.PAPER), 4, 140.0, 3.0)
				n.queue_free()
				modulate = Color(1.3, 1.3, 1.5)
				create_tween().tween_property(self, "modulate", Color.WHITE, 0.12)
		_push_t -= delta
		if _push_t <= 0.0:
			_push_t = 0.35
			for e in owner_p.kit._enemies():
				var d: Vector2 = e.global_position - global_position
				if absf(d.x) < W / 2 + e.body_size.x / 2 + 10.0 and d.y < 10.0 and d.y > -tall - e.body_size.y / 2:
					e.take_damage(6, owner_p)
					if e.stagger_max <= 0.0:
						e.velocity = Vector2((signf(d.x) if d.x != 0.0 else float(dir)) * 460.0, -200.0)
		if _t >= life or hp <= 0:
			_release()

	# страница кончилась — буквы слетают вперёд залпом
	func _release() -> void:
		_done = true
		var world := get_parent()
		var word := ScribeKit.WORD
		var n := word.length()
		for k in n:
			var b := Bullet.new()
			b.shooter = owner_p
			b.team = owner_p.team
			b.speed = 1000.0
			b.damage = 12 if mega else 9
			b.size = 14.0
			b.glyph = word[k]
			b.style = "ink"
			b.direction = Vector2(dir, 0)
			b.position = global_position + Vector2(dir * (W / 2 + 6), -tall + 16 + (tall - 26) * k / maxf(1.0, n - 1.0))
			if mega:
				b.pierce = 1
			world.add_child(b)
		Fx.sparks(world, global_position + Vector2(0, -tall / 2), Skins.col(owner_p, ScribeKit.PAPER), 14, 220.0, 4.0)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(0.1, 1.0), 0.15)
		tw.tween_callback(queue_free)

# Строка, падающая со страницы книги на врага (InkLine)
class InkLine extends Node2D:
	signal landed
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var col := Color.WHITE
	var _t := 0.0
	var _ln: Line2D
	const FLY := 0.22

	func _ready() -> void:
		z_index = 7
		_ln = Line2D.new()
		_ln.width = 3.0
		_ln.default_color = col
		add_child(_ln)
		var words := ["однажды", "и тогда", "в тот день", "легенда", "глава", "строка", "и вот"]
		var l := Label.new()
		l.text = words[randi() % words.size()]
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color", col)
		l.add_theme_constant_override("outline_size", 4)
		l.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.14))
		l.name = "W"
		add_child(l)

	func _process(delta: float) -> void:
		_t += delta
		var k := minf(1.0, _t / FLY)
		var head := from.lerp(to, k)
		var tail := from.lerp(to, maxf(0.0, k - 0.35))
		_ln.points = PackedVector2Array([tail, head])
		(get_node("W") as Label).position = head + Vector2(-24, -22)
		if _t >= FLY and k >= 1.0 and not has_meta("done"):
			set_meta("done", true)
			landed.emit()
			Fx.sparks(get_parent(), to, col, 5, 140.0, 3.0)
		modulate.a = 1.0 if _t < FLY else maxf(0.0, 1.0 - (_t - FLY) / 0.2)
		if _t > FLY + 0.2:
			queue_free()

# Книга «Последней главы»: огромная, раскрытая, страницы листаются; в конце захлопывается
class BigBook extends Node2D:
	var owner_p: Player
	var _t := 0.0
	var _flip: Polygon2D
	var _l: Node2D
	var _r: Node2D
	var _closing := false

	func _ready() -> void:
		z_index = 6
		var cover := Skins.col(owner_p, Color(0.30, 0.10, 0.12))
		var paper := Skins.col(owner_p, ScribeKit.PAPER)
		var gold := Skins.col(owner_p, ScribeKit.GOLD)
		var glow := Polygon2D.new()
		glow.polygon = Util.circle(150.0, 24)
		glow.scale = Vector2(1.0, 0.6)
		glow.color = Color(gold, 0.18)
		add_child(glow)
		for s in [-1.0, 1.0]:
			var half := Node2D.new()
			add_child(half)
			var cv := Polygon2D.new()
			cv.polygon = PackedVector2Array([Vector2(0, -56), Vector2(s * 128, -64), Vector2(s * 130, 50), Vector2(0, 58)])
			cv.color = cover
			half.add_child(cv)
			var pg := Polygon2D.new()
			pg.polygon = PackedVector2Array([Vector2(0, -50), Vector2(s * 118, -58), Vector2(s * 120, 44), Vector2(0, 52)])
			pg.color = paper
			half.add_child(pg)
			for k in 9:
				var ln := Line2D.new()
				var y := -40.0 + k * 10.0
				ln.points = PackedVector2Array([Vector2(s * 12, y), Vector2(s * (100 - (k * 13) % 30), y - s * 0.0)])
				ln.width = 2.0
				ln.default_color = Color(Skins.col(owner_p, ScribeKit.INK), 0.8)
				half.add_child(ln)
			if s < 0:
				_l = half
			else:
				_r = half
		var spine := Line2D.new()
		spine.points = PackedVector2Array([Vector2(0, -58), Vector2(0, 60)])
		spine.width = 5.0
		spine.default_color = gold
		add_child(spine)
		_flip = Polygon2D.new()                                     # листающаяся страница
		_flip.polygon = PackedVector2Array([Vector2(0, -50), Vector2(118, -58), Vector2(120, 44), Vector2(0, 52)])
		_flip.color = paper.darkened(0.06)
		add_child(_flip)
		scale = Vector2(0.1, 0.1)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)

	func _process(delta: float) -> void:
		_t += delta
		if _closing:
			return
		_flip.scale.x = cos(_t * 7.0)
		position.y += sin(_t * 2.0) * 0.3
		if randf() < 0.4:
			Fx.sparks(get_parent(), global_position + Vector2(randf_range(-110, 110), randf_range(-40, 40)), Skins.col(owner_p, ScribeKit.GOLD), 1, 60.0, 3.0)

	func slam() -> void:
		if _closing:
			return
		_closing = true
		_flip.visible = false
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_l, "scale:x", 0.05, 0.16)
		tw.tween_property(_r, "scale:x", 0.05, 0.16)
		tw.chain().tween_property(self, "modulate:a", 0.0, 0.35)
		tw.chain().tween_callback(queue_free)
