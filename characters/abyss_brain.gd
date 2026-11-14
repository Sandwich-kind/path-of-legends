class_name AbyssBrain
extends Node
# ---------- Особое поведение мини-боссов последних земель ----------
#   mill_giant     — Мельник Жернов (95): с половины здоровья бездна овладевает им
#                    целиком — он лиловеет, ускоряется и учится «Мельнице в бурю»:
#                    раскручивается на месте, тянет героев к себе, задевает лопастями;
#   abyss_headsman — Палач Бездны (98): с половины здоровья — «Казнь!»: из земли под
#                    героями рвутся цепи, крюк летает чаще;
#   rift_weaver    — Ткачиха Разлома (99): парит над землёй; с половины здоровья рвёт
#                    ткань мира — нитей четыре, порталы и отражения чаще.

var p: Player
var kind := ""
var rage := false
var _t := 0.0
var _mill_t := 0.0
var _mill_tick := 0.0
var _arcs: Node2D

func _ready() -> void:
	name = "AbyssBrain"
	if kind == "rift_weaver" and p.rig and "levitate" in p.rig:
		p.rig.levitate = 1.0

func busy() -> bool:
	return _mill_t > 0.0

func _am() -> Node:
	return p.get_tree().get_first_node_in_group("arena_mode") if p.is_inside_tree() else null

func _banner(text: String, c := Color(0.85, 0.6, 1.0), hold := 1.6) -> void:
	var am := _am()
	if am and am.hud:
		am.hud.show_banner(text, c)
		am._after(hold, am.hud.hide_banner)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		_end_mill()
		return
	_t += delta
	if not rage and p.hp <= p.max_hp / 2 and not p.cutscene_shield:
		_enrage()
	if _mill_t > 0.0:
		_mill_tick_fn(delta)

func _enrage() -> void:
	rage = true
	var world := p.get_parent()
	if p.rig:
		p.rig.play("roar")
	Fx.shake(world, 10.0)
	Fx.ring(world, p.global_position, 320.0, Color(0.85, 0.5, 1.0, 0.9), 0.5, 9.0)
	Fx.sparks(world, p.global_position, Color(0.78, 0.36, 1.0), 24, 320.0, 5.0)
	for k in p.bot_abilities:
		p.bot_abilities[k] = float(p.bot_abilities[k]) * 0.85
	match kind:
		"mill_giant":
			_banner("Бездна овладевает Мельником!")
			p.set_tint(Color(0.95, 0.80, 1.15))
			p.speed *= 1.2
			p.bot_abilities["void_mill"] = 9.0
			p._bot_cd["void_mill"] = 2.0
		"void_shepherd":
			_banner("Пастух: «Стадо, ко мне — со всех сторон!»")
			p.set_tint(Color(1.0, 0.86, 1.2))
			p.speed *= 1.15
			p.bot_abilities["stampede"] = 5.0
			p._bot_cd["stampede"] = 1.0
		"abyss_headsman":
			_banner("Палач: «Казнь!»")
			p.set_tint(Color(1.05, 0.85, 1.2))
			p.bot_abilities["void_chains"] = 8.0
			p._bot_cd["void_chains"] = 1.5
		"rift_weaver":
			_banner("Ткачиха рвёт ткань мира!")
			p.set_tint(Color(1.1, 0.9, 1.25))
			p.bot_abilities["thread_lines"] = 4.8

# ----- Мельница в бурю -----
func start_mill() -> void:
	_mill_t = 2.8
	_mill_tick = 0.0
	p._forced_time = 2.8
	p._forced_vx = 0.0
	_banner("Мельница в бурю! Держись подальше!", Color(0.9, 0.7, 1.0), 1.2)
	_arcs = Node2D.new()
	_arcs.z_index = 6
	p.add_child(_arcs)
	for k in 4:                                            # лопасти бездны вокруг Мельника
		var bl := Polygon2D.new()
		bl.polygon = PackedVector2Array([Vector2(20, -6), Vector2(170, -16), Vector2(180, 0), Vector2(170, 16), Vector2(20, 6)])
		bl.color = Color(0.78, 0.40, 1.0, 0.55)
		bl.rotation = k * PI / 2
		_arcs.add_child(bl)

func _mill_tick_fn(delta: float) -> void:
	_mill_t -= delta
	var world := p.get_parent()
	if _arcs and is_instance_valid(_arcs):
		_arcs.rotation += delta * 9.0
	if p.rig and fmod(_mill_t, 0.35) < delta:
		p.rig.play("slam")
	_mill_tick -= delta
	for n in AbyssAbilities._foes(p):
		var dx: float = n.global_position.x - p.global_position.x
		if absf(dx) < 900.0:
			n.push_wind(-signf(dx) * 420.0)               # ветер тянет к Мельнику
	if _mill_tick <= 0.0:
		_mill_tick = 0.4
		for n in AbyssAbilities._foes(p):
			if n.global_position.distance_to(p.global_position) < 190.0:
				n.take_damage(int(10 * float(p.get_meta("bal_dmg", 1.0)) / 1.5), p)
				n.velocity = Vector2(signf(n.global_position.x - p.global_position.x) * 380.0, -320.0)
		Fx.sparks(world, p.global_position + Vector2(randf_range(-160, 160), randf_range(-60, 40)), Color(0.85, 0.6, 1.0), 4, 260.0, 4.0)
	if _mill_t <= 0.0:
		_end_mill()

func _end_mill() -> void:
	_mill_t = 0.0
	if _arcs and is_instance_valid(_arcs):
		_arcs.queue_free()
	_arcs = null
