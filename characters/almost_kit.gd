class_name AlmostKit
extends HeroKit
# ---------- ПОЧТИ ЛЕГЕНДА — легенда из Лавки (персонаж друга автора игры) ----------
# Свой облик: белый боевой костюм с оранжевыми полосами, круглый шлем с голубым визором,
# силовые перчатки и серебряная медаль «2» на груди — до легенды ему всего чуть-чуть.
# Оружие «Кулаки» — нажал и отпустил: короткий удар вблизи. Зажал — кулак заряжается
#   (до 1 с) и бьёт ударной волной: чем дольше заряд, тем дальше летит и сильнее бьёт,
#   задевая всех на пути. Держишь полный заряд дольше — удар срывается сам.
# 1 «Рельмотрон» — достаёт рельсовую винтовку: доля секунды на прицел — и один мгновенный
#   луч через весь экран. Пробивает насквозь всех врагов и постройки на линии.
#   МЕГА: луч толще, сильнее и оглушает.
# 2 «Пока от владыки льда» — вокруг него встаёт ледяная область (ходит вместе с ним): враги
#   в ней замедлены, понемногу мёрзнут (урон), а иногда поскальзываются и падают.
#   МЕГА: шире, дольше, поскальзываются чаще.
# 3 «Метеоритный удар» — с неба в ближайшего врага летит метеорит, каждый раз случайный:
#   обыкновенный (больше урона), огненный (поджигает), ледяной (замедляет), грозовой
#   (молния по цепочке), травяной (зона, где лечатся свои), банановый (разлетается
#   кусочками шоколада: врагов ранят, своих лечат, под врагом — шоколадная лужа) и очень
#   редкий баганный (сбивает врагам управление). МЕГА: два метеорита.
# Ульта «Привет от Титана» — за ареной поднимается огромный робот и бьёт по всей карте сам,
#   пока герой сражается: три удара кулаком (тень показывает, куда), град ракет, лазеры из
#   глаз метут по полу, топот — ударные волны по земле (перепрыгни), и напоследок ядро в
#   груди выпускает шар энергии — взрыв на всю карту. МЕГА: ударов и ракет больше, взрыв сильнее.

const ORANGE := Color(1.0, 0.52, 0.14)
const CYAN := Color(0.30, 0.90, 1.0)
const WHITE := Color(0.94, 0.95, 0.98)
const CHARGE_MAX := 1.0
const TAP := 0.18
const METEORS := {
	"stone": {"name": "Обыкновенный", "w": 22, "color": Color(0.62, 0.55, 0.50)},
	"fire": {"name": "Огненный", "w": 18, "color": Color(1.0, 0.45, 0.12)},
	"ice": {"name": "Ледяной", "w": 18, "color": Color(0.55, 0.85, 1.0)},
	"storm": {"name": "Грозовой", "w": 16, "color": Color(0.75, 0.70, 1.0)},
	"grass": {"name": "Травяной", "w": 10, "color": Color(0.40, 0.85, 0.35)},
	"banana": {"name": "Банановый", "w": 11, "color": Color(1.0, 0.88, 0.30)},
	"glitch": {"name": "Баганный", "w": 5, "color": Color(1.0, 0.25, 0.85)},
}
const G := 1400.0

var _charging := false
var _charge := 0.0
var _hold_full := 0.0
var _glow: Polygon2D
var _titan: Node2D

# ---------- Оружие: кулаки ----------
func weapon(delta: float, shoot: bool) -> void:
	var rapid := p.has_buff("rapid")
	p.ammo = p.clip_size
	p._reloading = 0.0
	if shoot:
		if not _charging and p._cooldown_left <= 0.0:
			_charging = true
			_charge = 0.0
			_hold_full = 0.0
		if _charging:
			_charge = minf(CHARGE_MAX, _charge + delta * (1.7 if rapid else 1.0))
			if _charge >= CHARGE_MAX:
				_hold_full += delta
			_charge_fx()
			if _hold_full > 0.6:
				_release()                             # держал полный заряд — удар срывается сам
		return
	if _charging:
		_release()

func _release() -> void:
	_charging = false
	var k := _charge
	_charge = 0.0
	if is_instance_valid(_glow):
		_glow.queue_free()
	_glow = null
	if k < TAP:
		_jab()
		p._cooldown_left = p.fire_cooldown
	else:
		_power_punch(clampf((k - TAP) / (CHARGE_MAX - TAP), 0.0, 1.0))
		p._cooldown_left = p.fire_cooldown * 1.3

# заряд виден: у кулака разгорается оранжевое свечение
func _charge_fx() -> void:
	if _glow == null or not is_instance_valid(_glow):
		_glow = Polygon2D.new()
		_glow.polygon = Util.circle(1.0, 12)
		_glow.z_index = 6
		p.add_child(_glow)
	var q := _charge / CHARGE_MAX
	_glow.position = Vector2(p.facing * 22.0, 6.0)
	_glow.scale = Vector2.ONE * (5.0 + 11.0 * q) * (1.0 + 0.12 * sin(Time.get_ticks_msec() * 0.03))
	_glow.color = Color(Skins.col(p, ORANGE) if q < 1.0 else Skins.col(p, CYAN), 0.35 + 0.35 * q)

# короткий удар вблизи
func _jab() -> void:
	p._anim("punch")
	var world := p.get_parent()
	var best: Player = null
	var bd := 95.0
	for e in _enemies():
		var to: Vector2 = e.global_position - p.global_position
		var dx: float = to.x * p.facing - e.body_size.x * 0.5
		if dx > -20.0 and dx < bd and absf(to.y) < 40.0 + e.body_size.y * 0.5 and not e.cutscene_shield:
			bd = dx
			best = e
	var at := p.global_position + Vector2(p.facing * 46.0, 2.0)
	var a0 := -0.7 if p.facing > 0 else PI - 0.7
	Fx.arc(world, p.global_position + Vector2(0, 2), 56.0, a0, a0 + 1.4, Color(Skins.col(p, ORANGE), 0.8), 0.16, 14.0)
	Audio.sfx("punch", at)
	if best:
		best.take_damage(p.bullet_damage, p)
		if best.stagger_max <= 0.0 and best.is_alive():
			best.velocity.x = p.facing * 260.0
		Fx.sparks(world, best.hurt_center(), Skins.col(p, ORANGE), 5, 180.0, 3.5)

# заряженный удар: ударная волна-кулак летит вперёд и бьёт всех на пути
func _power_punch(k: float) -> void:
	p._anim("punch")
	var dist := lerpf(200.0, 560.0, k)
	var dmg := int(round(lerpf(12.0, 30.0, k)))
	var b := p._shoot_bullet(1400.0, dmg, 0.0, lerpf(24.0, 40.0, k), 0.0)
	b.color = Skins.col(p, ORANGE if k < 0.99 else CYAN)
	b.restyle("fist")
	b.position = Vector2(p.global_position.x + p.facing * 18.0, p.global_position.y - 4.0)   # от груди: волна не чиркает по полу
	b.pierce = 99
	b._life = dist / 1400.0
	var world := p.get_parent()
	var col := b.color
	b.on_hit = func(body):
		if body is Player:
			if is_instance_valid(world):
				Fx.ring(world, body.hurt_center(), 34.0 + 30.0 * k, Color(col, 0.9), 0.25, 5.0)
				Fx.sparks(world, body.hurt_center(), col.lightened(0.3), 4 + int(6 * k), 240.0, 3.5)
			if body.is_alive() and body.stagger_max <= 0.0:
				body.velocity = Vector2(signf(b.direction.x) * (220.0 + 260.0 * k), -120.0 - 140.0 * k)
	Audio.sfx("punch", p.global_position, 2.0 * k)
	var fist_at := p.global_position + Vector2(p.facing * 30.0, -4.0)
	Fx.ring(world, fist_at, 30.0 + 40.0 * k, Color(col, 0.9), 0.25, 4.0)
	if k > 0.5:
		for j in 3:                                             # линии скорости
			var sl := Line2D.new()
			var y := randf_range(-22.0, 18.0)
			sl.points = PackedVector2Array([fist_at + Vector2(-p.facing * 10.0, y), fist_at + Vector2(-p.facing * 70.0, y)])
			sl.width = 2.0
			sl.default_color = Color(col.lightened(0.4), 0.7)
			sl.z_index = 7
			world.add_child(sl)
			var st := sl.create_tween()
			st.tween_property(sl, "modulate:a", 0.0, 0.2)
			st.tween_callback(sl.queue_free)
	if k > 0.99:
		Fx.shockwave(world, fist_at, 70.0, Skins.col(p, CYAN), 1.0)
		Fx.dust(world, p.global_position + Vector2(0, p.body_size.y / 2), 4, Color(0.6, 0.56, 0.5), 60.0, 12.0)

# ---------- Способности ----------
func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"railmotron":
			_rail(mega)
		"ice_farewell":
			_ice_zone(mega)
		"meteor_strike":
			_meteor(mega)

# ----- 1. Рельмотрон -----
func _rail(mega: bool) -> void:
	var world := p.get_parent()
	p._forced_time = 0.32
	p._forced_vx = 0.0
	var gun := Node2D.new()                                    # винтовка в руках на миг
	gun.z_index = 6
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-6, -3), Vector2(44, -3), Vector2(46, 0), Vector2(44, 3), Vector2(-6, 4)])
	body.color = Color(0.22, 0.24, 0.30)
	gun.add_child(body)
	for x in [8.0, 18.0, 28.0, 38.0]:
		var coil := Polygon2D.new()
		coil.polygon = PackedVector2Array([Vector2(x, -4), Vector2(x + 4, -4), Vector2(x + 4, 4), Vector2(x, 4)])
		coil.color = Skins.col(p, CYAN)
		gun.add_child(coil)
	gun.position = Vector2(p.facing * 6.0, 2.0)
	gun.scale.x = float(p.facing)
	p.add_child(gun)
	var from := p.global_position + Vector2(p.facing * 52.0, 2.0)
	var dir := Vector2(p.facing, 0)
	if Balance.arena(p):
		dir = p.assist_dir(from, dir, 0.0)
	var line := LightBeam.aim_line(world, from, from + dir * 1700.0, Color(Skins.col(p, CYAN), 0.6), 0.28)
	if line:
		line.width = 2.0
	Audio.sfx("rail", from)
	for j in 10:                                                # энергия стекается к дулу
		var sp := Polygon2D.new()
		sp.polygon = Util.circle(3.0, 6)
		sp.color = Skins.col(p, CYAN).lightened(0.3)
		sp.position = from + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 80.0)
		sp.z_index = 8
		world.add_child(sp)
		var spt := sp.create_tween()
		spt.tween_interval(j * 0.02)
		spt.tween_property(sp, "position", from, 0.2).set_ease(Tween.EASE_IN)
		spt.tween_callback(sp.queue_free)
	_after(0.28, func():
		if is_instance_valid(gun):
			gun.queue_free()
		if not is_instance_valid(p) or not p.is_alive():
			return
		_fire_rail(p.global_position + Vector2(p.facing * 52.0, 2.0), dir, mega))

func _fire_rail(from: Vector2, dir: Vector2, mega: bool) -> void:
	var world := p.get_parent()
	var to := from + dir * 1700.0
	var w := 34.0 if mega else 22.0
	LightBeam.draw(world, [[from, to, 0]], Skins.col(p, CYAN), 16.0 if mega else 11.0, 0.3)
	LightBeam.draw(world, [[from, to, 0]], Color(1, 1, 1), 4.0, 0.22)
	LightBeam.draw(world, [[from, to, 0]], Color(Skins.col(p, CYAN), 0.35), 34.0 if mega else 26.0, 0.55)   # остывающее свечение
	Fx.star(world, from, 46.0, Color(1, 1, 1), 0.3)
	Fx.ring(world, from, 40.0, Color(Skins.col(p, CYAN), 0.9), 0.25, 5.0)
	for j in 2:
		Fx.smoke(world, from + Vector2(-p.facing * 10.0 * j, -4.0), 12.0, Color(0.75, 0.80, 0.85), 40.0)
	for j in 8:                                                 # искры вдоль луча
		Fx.sparks(world, from.lerp(to, randf()), Skins.col(p, CYAN).lightened(0.3), 1, 120.0, 3.0)
	var spiral := Line2D.new()                                 # спираль вокруг луча
	var pts := PackedVector2Array()
	var nrm := Vector2(-dir.y, dir.x)
	for i in 120:
		var q := i / 119.0
		pts.append(from.lerp(to, q) + nrm * sin(q * 70.0) * (w * 0.6))
	spiral.points = pts
	spiral.width = 2.0
	spiral.default_color = Color(Skins.col(p, ORANGE), 0.8)
	spiral.z_index = 7
	world.add_child(spiral)
	var tw := spiral.create_tween()
	tw.tween_property(spiral, "modulate:a", 0.0, 0.35)
	tw.tween_callback(spiral.queue_free)
	Fx.shake(world, 4.0)
	p.velocity.x = -p.facing * 260.0                            # отдача
	for e in _enemies():
		var c: Vector2 = e.hurt_center()
		var v := c - from
		var along := v.dot(dir)
		if along < -10.0 or along > 1700.0:
			continue
		if absf(v.dot(nrm)) < w + e.body_size.x * 0.35:
			e.take_damage(40 if mega else 30, p)
			Fx.sparks(world, c, Skins.col(p, CYAN), 6, 220.0, 4.0)
			if mega and e.is_alive():
				e.stun(0.6 if e.stagger_max <= 0.0 else 0.2)
	# насквозь: и постройки на линии
	var space := p.get_world_2d().direct_space_state
	var ex: Array = [p.get_rid()]
	for k in 12:
		var q := PhysicsRayQueryParameters2D.create(from, to, Layer.WORLD)
		q.exclude = ex
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			break
		var col: Object = hit["collider"]
		if col.has_method("hit"):
			col.hit(hit["position"], dir, 40, 0.0, p.team, {"attacker": p})
		ex.append(hit["rid"])

# ----- 2. Пока от владыки льда -----
func _ice_zone(mega: bool) -> void:
	var z := IceZone.new()
	z.owner_p = p
	z.kit = self
	z.mega = mega
	z.radius = 220.0 if mega else 170.0
	z.life = (7.0 if mega else 5.0) + (1.0 if Balance.arena(p) else 0.0)
	z.slip_chance = 0.12 if mega else 0.06
	p.get_parent().add_child(z)
	p._float_label("Пока от владыки льда!", Skins.col(p, Color(0.70, 0.92, 1.0)))

# ----- 3. Метеоритный удар -----
func _meteor(mega: bool) -> void:
	var es := _enemies().filter(func(e): return e.global_position.distance_to(p.global_position) < 1200.0 and not e.cutscene_shield)
	es.sort_custom(func(a, b): return a.global_position.distance_to(p.global_position) < b.global_position.distance_to(p.global_position))
	p._anim("cast")
	for j in (2 if mega else 1):
		var at := p.global_position + Vector2(p.facing * (320.0 + j * 160.0), 0)
		if not es.is_empty():
			var e: Player = es[mini(j, es.size() - 1)]
			at = e.global_position + Vector2(randf_range(-20.0, 20.0) if j > 0 and es.size() == 1 else 0.0, 0)
		var m := Meteor.new()
		m.owner_p = p
		m.kit = self
		m.kind = roll_meteor()
		m.target = _ground_below(at)
		m.delay = 0.35 * j
		p.get_parent().add_child(m)

static func roll_meteor() -> String:
	var total := 0
	for k in METEORS:
		total += int(METEORS[k]["w"])
	var r := randi() % total
	for k in METEORS:
		r -= int(METEORS[k]["w"])
		if r < 0:
			return k
	return "stone"

func _ground_below(at: Vector2) -> Vector2:
	var hit := p.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(at + Vector2(0, -20), at + Vector2(0, 900), Layer.WORLD))
	return at if hit.is_empty() else hit["position"]

# что метеорит делает с теми, кого задел
func meteor_hit(kind: String, at: Vector2, r: float) -> void:
	var world := p.get_parent()
	var arena := Balance.arena(p)
	var hits: Array = []
	for e in _enemies():
		var d: Vector2 = e.global_position + Vector2(0, e.body_size.y / 2) - at
		if absf(d.x) < r + e.body_size.x * 0.4 and d.y > -r - e.body_size.y and d.y < 40.0:
			hits.append(e)
	var dmg: int = int({"stone": 26, "fire": 16, "ice": 15, "storm": 15, "grass": 10, "banana": 12, "glitch": 10}.get(kind, 15))
	for e in hits:
		e.take_damage(dmg, p)
		if not e.is_alive():
			continue
		var boss: bool = e.stagger_max > 0.0
		if not boss:
			e.velocity = Vector2(signf(e.global_position.x - at.x) * (360.0 if kind == "stone" else 220.0), -300.0)
		match kind:
			"fire":
				e.burn(3.0, 6.0, p)
			"ice":
				e.chill(2.5, 0.5)
			"glitch":
				e.glitch_t = maxf(e.glitch_t, 0.5 if boss else 2.0)
				e._float_label("ERR0R", Color(1.0, 0.3, 0.9))
	match kind:
		"storm":
			var done: Array = hits.duplicate()
			var from: Vector2 = at + Vector2(0, -30)
			for n in 3:
				var best: Player = null
				var bd := 320.0
				for e in _enemies():
					if e in done:
						continue
					var dd: float = e.hurt_center().distance_to(from)
					if dd < bd:
						bd = dd
						best = e
				if best == null:
					break
				Fx.bolt(world, from, best.hurt_center(), Color(0.80, 0.75, 1.0))
				best.take_damage(10, p)
				done.append(best)
				from = best.hurt_center()
		"grass":
			var gz := GrassZone.new()
			gz.owner_p = p
			gz.life = 5.0 + (1.0 if arena else 0.0)
			gz.position = at
			world.add_child(gz)
		"banana":
			for k in 8:
				var ch := Choco.new()
				ch.owner_p = p
				ch.position = at + Vector2(0, -24)
				ch.vel = Vector2(randf_range(-420.0, 420.0), randf_range(-620.0, -320.0))
				world.add_child(ch)
			var pd := ChocoPuddle.new()
			pd.owner_p = p
			pd.position = (hits[0].global_position + Vector2(0, hits[0].body_size.y / 2)) if not hits.is_empty() else at
			world.add_child(pd)

# ---------- Каждый кадр ----------
func _physics_process(_delta: float) -> void:
	if p == null or not p.is_alive():
		if _charging:
			_charging = false
			if is_instance_valid(_glow):
				_glow.queue_free()
		return

# ---------- Ульта: Привет от Титана ----------
func ult() -> void:
	var mega := p._mega_ab()
	var world := p.get_parent()
	var x := clampf(p.global_position.x, 320.0, maxf(640.0, p.map_w - 320.0))
	var t := TitanRobot.new()
	t.owner_p = p
	t.kit = self
	t.mega = mega
	var gnd := _ground_below(Vector2(x, p.global_position.y))
	t.floor_y = gnd.y
	t.base = gnd + Vector2(0, 100)   # модель Титана — characters/titan_robot.gd
	world.add_child(t)
	_titan = t

func ulting() -> bool:
	return _titan != null and is_instance_valid(_titan) and not (_titan as TitanRobot).done

func on_death() -> void:
	super()
	_charging = false
	if is_instance_valid(_glow):
		_glow.queue_free()


# =====================================================================
# Ледяная область вокруг героя: замедляет, морозит, иногда враг поскальзывается и падает
class IceZone extends Node2D:
	var owner_p: Player
	var kit: AlmostKit
	var mega := false
	var radius := 170.0
	var life := 5.0
	var slip_chance := 0.06
	var _t := 0.0
	var _tick := 0.0
	var _ring: Line2D
	var _fill: Polygon2D

	func _ready() -> void:
		z_index = -1
		_fill = Polygon2D.new()
		var pts := PackedVector2Array()
		for k in 32:
			var a := TAU * k / 32.0
			pts.append(Vector2(cos(a) * radius, sin(a) * radius * 0.32))
		_fill.polygon = pts
		_fill.color = Color(0.70, 0.92, 1.0, 0.18)
		add_child(_fill)
		_ring = Line2D.new()
		var rp := pts.duplicate()
		rp.append(pts[0])
		_ring.points = rp
		_ring.width = 3.0
		_ring.default_color = Color(0.80, 0.95, 1.0, 0.85)
		add_child(_ring)
		for k in 7:                                            # ледяные кристаллы по кромке
			var cr := Polygon2D.new()
			var a := TAU * k / 7.0
			cr.polygon = PackedVector2Array([Vector2(-4, 0), Vector2(0, -12 - (k % 3) * 4), Vector2(4, 0)])
			cr.position = Vector2(cos(a) * radius * 0.9, sin(a) * radius * 0.29)
			cr.color = Color(0.75, 0.93, 1.0, 0.9)
			add_child(cr)

	func _physics_process(delta: float) -> void:
		if not is_instance_valid(owner_p) or not owner_p.is_alive():
			queue_free()
			return
		_t += delta
		global_position = owner_p.global_position + Vector2(0, owner_p.body_size.y / 2)
		_ring.rotation = 0.0
		_ring.width = 3.0 + sin(_t * 6.0) * 1.0
		if randf() < 0.5:                                    # снежинки
			Fx.sparks(get_parent(), global_position + Vector2(randf_range(-radius, radius), -randf_range(0, 70)), Color(0.9, 0.97, 1.0), 1, 40.0, 3.0)
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.5
			var arena := Balance.arena(owner_p)
			for e in kit._enemies():
				var d: Vector2 = e.global_position + Vector2(0, e.body_size.y / 2) - global_position
				if absf(d.x) < radius + e.body_size.x * 0.3 and absf(d.y) < 110.0:
					e.chill(0.7, 0.55)
					e.take_damage(4 if arena else 3, owner_p)
					if e.is_alive() and e.stagger_max <= 0.0 and randf() < slip_chance:
						e.stun(0.7)
						e.velocity = Vector2(randf_range(-1.0, 1.0) * 260.0, -120.0)
						e._float_label("Поскользнулся!", Color(0.75, 0.93, 1.0))
						Fx.debris(get_parent(), e.global_position + Vector2(0, e.body_size.y / 2), 6, Color(0.75, 0.92, 1.0), 300.0, 4.0)
						Fx.ring(get_parent(), e.global_position + Vector2(0, e.body_size.y / 2), 50.0, Color(0.85, 0.97, 1.0, 0.9), 0.3, 4.0, 0.3)
			Fx.smoke(get_parent(), global_position + Vector2(randf_range(-radius, radius) * 0.8, -10), 22.0, Color(0.80, 0.93, 1.0), 30.0)
		if _t >= life:
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 0.0, 0.3)
			tw.tween_callback(queue_free)
			set_physics_process(false)

# Метеорит: на земле заранее светится круг его цвета, сам летит наискосок с неба
class Meteor extends Node2D:
	var owner_p: Player
	var kit: AlmostKit
	var kind := "stone"
	var target := Vector2.ZERO
	var delay := 0.0
	var _t := 0.0
	var _rock: Node2D
	var _mark: Line2D
	var _from := Vector2.ZERO
	const FALL := 0.85
	const R := 110.0

	func _ready() -> void:
		z_index = 7
		var c: Color = AlmostKit.METEORS[kind]["color"]
		_mark = Line2D.new()
		var pts := PackedVector2Array()
		for k in 25:
			var a := TAU * k / 24.0
			pts.append(Vector2(cos(a) * R, sin(a) * R * 0.28))
		_mark.points = pts
		_mark.width = 3.0
		_mark.default_color = Color(c, 0.8)
		_mark.position = target
		_mark.z_index = -1
		add_child(_mark)
		_rock = Node2D.new()
		add_child(_rock)
		var trail := Polygon2D.new()                           # хвост
		trail.polygon = PackedVector2Array([Vector2(-18, -10), Vector2(-120, -70), Vector2(-26, 14)])
		trail.color = Color(c, 0.45)
		_rock.add_child(trail)
		var rock := Polygon2D.new()
		var rp := PackedVector2Array()
		for k in 11:
			var a := TAU * k / 11.0
			rp.append(Vector2(cos(a), sin(a)) * (30.0 + ((k * 7) % 5) * 2.5))
		rock.polygon = rp
		rock.color = c.darkened(0.25) if kind != "banana" else Color(1.0, 0.86, 0.30)
		_rock.add_child(rock)
		var core := Polygon2D.new()
		core.polygon = Util.circle(14.0, 10)
		core.position = Vector2(4, -4)
		core.color = c.lightened(0.3)
		_rock.add_child(core)
		if kind == "banana":                                   # банан в шоколаде
			var choc := Polygon2D.new()
			choc.polygon = PackedVector2Array([Vector2(-30, 4), Vector2(30, 4), Vector2(26, 18), Vector2(-26, 18)])
			choc.color = Color(0.36, 0.20, 0.10)
			_rock.add_child(choc)
		elif kind == "glitch":
			for k in 4:
				var gl := Polygon2D.new()
				gl.polygon = PackedVector2Array([Vector2(0, 0), Vector2(16, 0), Vector2(16, 4), Vector2(0, 4)])
				gl.position = Vector2(randf_range(-30, 14), randf_range(-24, 20))
				gl.color = [Color(0.3, 1.0, 0.5), Color(1.0, 0.25, 0.85), Color(0.3, 0.6, 1.0)][k % 3]
				_rock.add_child(gl)
		_from = target + Vector2(-owner_p.facing * 520.0, -900.0)
		_rock.position = _from
		_rock.rotation = (target - _from).angle()
		_rock.visible = false
		Audio.sfx("meteor", target)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t < delay:
			return
		_rock.visible = true
		var q := clampf((_t - delay) / FALL, 0.0, 1.0)
		_rock.position = _from.lerp(target, q * q)
		_mark.width = 3.0 + q * 4.0
		var c: Color = AlmostKit.METEORS[kind]["color"]
		if randf() < 0.55:                                     # хвост: дым и искры по пути
			Fx.smoke(get_parent(), _rock.global_position, 14.0, c.darkened(0.5), 10.0)
		if randf() < 0.5:
			Fx.sparks(get_parent(), _rock.global_position, c.lightened(0.3), 1, 90.0, 4.0)
		if q >= 1.0:
			_land()

	func _land() -> void:
		set_physics_process(false)
		if not is_instance_valid(owner_p) or kit == null or not is_instance_valid(kit):
			queue_free()
			return
		var world := get_parent()
		var c: Color = AlmostKit.METEORS[kind]["color"]
		Util.flash(world, target + Vector2(0, -30), R, Color(c.lightened(0.4), 0.85))
		Fx.shockwave(world, target, R * 1.3, c, 0.3)
		Fx.sparks(world, target, c, 18, 340.0, 5.0, true)
		Fx.cracks(world, target, c.darkened(0.6), 110.0)
		Fx.dust(world, target, 8, Color(0.58, 0.54, 0.50), 140.0, 22.0)
		Fx.debris(world, target, 10, Color(0.45, 0.40, 0.36), 480.0, 7.0)
		Fx.shake(world, 9.0)
		match kind:                                            # у каждого вида — свой взрыв
			"stone":
				Fx.debris(world, target, 10, Color(0.55, 0.50, 0.46), 620.0, 9.0)
				Fx.dust(world, target, 8, Color(0.55, 0.50, 0.45), 200.0, 30.0)
			"fire":
				Fx.fireball(world, target + Vector2(0, -30), 80.0)
			"ice":
				Fx.debris(world, target, 14, Color(0.75, 0.93, 1.0), 560.0, 6.0)
				Fx.sparks(world, target, Color(1, 1, 1), 12, 300.0, 4.0, true)
				Fx.smoke(world, target, 40.0, Color(0.85, 0.95, 1.0), 50.0)
			"storm":
				for j in 3:
					Fx.bolt(world, target + Vector2(randf_range(-160, 160), -700), target + Vector2(randf_range(-40, 40), 0), Color(0.85, 0.80, 1.0))
			"grass":
				Fx.leaf_burst(world, target + Vector2(0, -20), 26)
			"banana":
				Fx.debris(world, target, 12, Color(0.40, 0.22, 0.10), 500.0, 6.0)
				Fx.debris(world, target, 6, Color(1.0, 0.88, 0.30), 420.0, 5.0)
			"glitch":
				for j in 10:
					var g := Polygon2D.new()
					var w := randf_range(14, 40)
					g.polygon = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, 6), Vector2(0, 6)])
					g.color = [Color(0.3, 1.0, 0.5), Color(1.0, 0.25, 0.85), Color(0.3, 0.6, 1.0)][j % 3]
					g.position = target + Vector2(randf_range(-120, 100), randf_range(-140, -10))
					g.z_index = 9
					world.add_child(g)
					var gt := g.create_tween()
					for s in 4:
						gt.tween_property(g, "position:x", g.position.x + randf_range(-30, 30), 0.05)
					gt.tween_property(g, "modulate:a", 0.0, 0.15)
					gt.tween_callback(g.queue_free)
		Audio.sfx("boom_big", target)
		var l := Label.new()
		l.text = String(AlmostKit.METEORS[kind]["name"]) + "!"
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", c.lightened(0.2))
		l.add_theme_constant_override("outline_size", 6)
		l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
		l.position = target + Vector2(-60, -150)
		l.z_index = 9
		world.add_child(l)
		var tw := l.create_tween()
		tw.tween_property(l, "position:y", l.position.y - 30.0, 0.8)
		tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.4)
		tw.tween_callback(l.queue_free)
		kit.meteor_hit(kind, target, R)
		queue_free()

# Травяная зона: свои в ней лечатся
class GrassZone extends Node2D:
	var owner_p: Player
	var life := 5.0
	var _t := 0.0
	var _tick := 0.0

	func _ready() -> void:
		z_index = -1
		for k in 22:                                            # травинки
			var g := Polygon2D.new()
			var x := randf_range(-140.0, 140.0)
			var h := randf_range(10.0, 24.0)
			g.polygon = PackedVector2Array([Vector2(x - 2, 0), Vector2(x + randf_range(-4, 4), -h), Vector2(x + 2, 0)])
			g.color = Color(0.35, 0.80, 0.30).lightened(randf_range(0.0, 0.25))
			add_child(g)
		var base := Polygon2D.new()
		var pts := PackedVector2Array()
		for k in 24:
			var a := TAU * k / 24.0
			pts.append(Vector2(cos(a) * 150.0, sin(a) * 26.0))
		base.polygon = pts
		base.color = Color(0.30, 0.70, 0.25, 0.35)
		add_child(base)

	func _physics_process(delta: float) -> void:
		_t += delta
		_tick -= delta
		if _tick <= 0.0 and is_instance_valid(owner_p):
			_tick = 0.5
			for n in get_parent().get_children():
				if n is Player and n.team == owner_p.team and n.is_alive():
					var d: Vector2 = n.global_position + Vector2(0, n.body_size.y / 2) - global_position
					if absf(d.x) < 150.0 and absf(d.y) < 90.0:
						n.heal(maxi(1, int(n.max_hp * 0.02)))
						Fx.sparks(get_parent(), n.global_position, Color(0.5, 1.0, 0.4), 2, 80.0, 3.0, true)
		if _t >= life:
			set_physics_process(false)
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 0.0, 0.4)
			tw.tween_callback(queue_free)

# Кусочек шоколада: летит по дуге; врага ранит, своего лечит
class Choco extends Node2D:
	var owner_p: Player
	var vel := Vector2.ZERO
	var _t := 0.0

	func _ready() -> void:
		z_index = 7
		var c := Polygon2D.new()
		c.polygon = PackedVector2Array([Vector2(-6, -5), Vector2(6, -5), Vector2(6, 5), Vector2(-6, 5)])
		c.color = Color(0.40, 0.22, 0.10)
		add_child(c)
		var hl := Polygon2D.new()
		hl.polygon = PackedVector2Array([Vector2(-5, -4), Vector2(0, -4), Vector2(0, -1), Vector2(-5, -1)])
		hl.color = Color(0.58, 0.36, 0.20)
		add_child(hl)

	func _physics_process(delta: float) -> void:
		_t += delta
		if not is_instance_valid(owner_p) or _t > 2.0:
			queue_free()
			return
		vel.y += AlmostKit.G * delta
		var from := position
		position += vel * delta
		rotation += delta * 9.0
		for n in get_parent().get_children():
			if n is Player and n.is_alive() and n.hurt_center().distance_to(global_position) < n.body_size.x * 0.5 + 10.0:
				if n.team == owner_p.team:
					n.heal(6)
					Fx.sparks(get_parent(), global_position, Color(1.0, 0.85, 0.5), 3, 90.0, 3.0, true)
				else:
					n.take_damage(5, owner_p)
				queue_free()
				return
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, position, Layer.WORLD))
		if not hit.is_empty() and not Util.shot_passes(hit["collider"], self):
			queue_free()

# Шоколадная лужа: враги в ней вязнут
class ChocoPuddle extends Node2D:
	var owner_p: Player
	var _t := 0.0

	func _ready() -> void:
		z_index = -1
		var base := Polygon2D.new()
		var pts := PackedVector2Array()
		for k in 20:
			var a := TAU * k / 20.0
			pts.append(Vector2(cos(a) * (90.0 + (k % 3) * 6.0), sin(a) * 14.0))
		base.polygon = pts
		base.color = Color(0.32, 0.18, 0.08, 0.9)
		add_child(base)
		var gl := Polygon2D.new()
		gl.polygon = PackedVector2Array([Vector2(-40, -4), Vector2(10, -6), Vector2(14, -3), Vector2(-36, -1)])
		gl.color = Color(0.55, 0.34, 0.18, 0.9)
		add_child(gl)

	func _physics_process(delta: float) -> void:
		_t += delta
		if not is_instance_valid(owner_p):
			queue_free()
			return
		for n in get_parent().get_children():
			if n is Player and n.team != owner_p.team and n.is_alive():
				var d: Vector2 = n.global_position + Vector2(0, n.body_size.y / 2) - global_position
				if absf(d.x) < 95.0 and absf(d.y) < 40.0:
					n.slow(0.25, 0.45, "mud")
		if _t >= 4.0:
			set_physics_process(false)
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 0.0, 0.5)
			tw.tween_callback(queue_free)
