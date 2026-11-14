extends SceneTree
# Боссы свиты Странника: Пустокрыл (85) и Предвестник (90) — появление, способности,
# ярость/вторая фаза, гибель. Герой бессмертен. Снимки — /tmp/claude-0/arena90/boss_*.png
var main
var f := 0
var arena: ArenaMode
var t0 := 0
var step := 0
var boss: Player
var won := []
var out := "/tmp/claude-0/arena90/"

func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _start(w: int) -> void:
	main.sel = [int(OS.get_environment("HERO")) if OS.get_environment("HERO") != "" else 0, 0]
	main.start_arena(false, w)
	arena = null
	for n in main.world.get_children():
		if n is ArenaMode: arena = n
	arena.finished.connect(func(v, wd, g): won.append([v, wd]))
	t0 = f

func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		if img: img.save_png(out + "boss_" + n + ".png")

func _brain() -> RiftBrain:
	return boss.get_node_or_null("RiftBrain") if is_instance_valid(boss) else null

func _use(ab: String) -> void:
	var b := _brain()
	if b and is_instance_valid(boss.target):
		print("  use ", ab, " -> ", b.use(ab, boss.target.global_position - boss.global_position), " state=", b._state)

# Способность Предвестника напрямую (без проверок ИИ — чтобы проверить каждую)
func _force(fn: String) -> void:
	var b := _brain()
	if b and is_instance_valid(boss) and boss.is_alive():
		boss._forced_time = 0.0
		b._charge_t = 0.0
		var r = b.call(fn)
		print("  force ", fn, " -> ", r)

func _wipe() -> void:
	for x in arena._alive.duplicate():
		if is_instance_valid(x) and x.is_alive():
			x.take_damage(999999)

func _physics_process(_d: float) -> bool:
	f += 1
	if arena and is_instance_valid(arena):
		for p in arena.players:
			p._protect = 1.0
			p.hp = p.max_hp
		if boss == null and arena._boss and is_instance_valid(arena._boss):
			boss = arena._boss
	var k := f - t0
	match step:
		0:
			if f == 3:
				_start(85)
				step = 1
		1:   # Пустокрыл
			if k == 60 * 7: shot("vw_intro")
			if k == 60 * 13:
				shot("vw_fight")
				print("voidwing: hp=", boss.hp, "/", boss.max_hp, " pos=", boss.global_position.round(), " state=", _brain()._state, " frozen=", boss.frozen)
			if k == 60 * 14: _use("void_rain")
			if k == 60 * 15: shot("vw_rain")
			if k == 60 * 18: _use("swoop")
			if k == 60 * 19: shot("vw_swoop")
			if k == 60 * 20 + 20:
				shot("vw_crash")
				print("  after swoop: state=", _brain()._state, " stunned=", boss.is_stunned(), " pos=", boss.global_position.round())
			if k == 60 * 24:
				_use("wing_gust")
			if k == 60 * 26:
				_use("sky_rift")
			if k == 60 * 29:
				boss.hp = boss.max_hp / 2 - 5
			if k == 60 * 30:
				print("  rage=", _brain()._rage, " abilities=", boss.bot_abilities.keys())
				_use("tail_beam")
			if k == 60 * 31: shot("vw_beam")
			if k == 60 * 34:
				print("  alive foes=", arena._alive.size())
				boss.take_damage(999999)
				print("  voidwing dead=", not boss.is_alive())
			if k == 60 * 36:
				_wipe()
			if k == 60 * 35 + 30: shot("vw_death1")
			if k == 60 * 37: shot("vw_death2")
			if k == 60 * 44:
				print("after voidwing: wave=", arena.wave, " stage=", arena.stage, " state=", arena._state)
				boss = null
				_start(90)
				step = 2
		2:   # Предвестник
			if k == 60 * 7: shot("hb_intro1")
			if k == 60 * 9: shot("hb_intro2")
			if k == 60 * 14:
				shot("hb_fight")
				print("harbinger: hp=", boss.hp, "/", boss.max_hp, " pos=", boss.global_position.round(), " frozen=", boss.frozen)
				boss.global_position.x = arena.players[0].global_position.x + 180.0
			if k == 60 * 15: _force("_combo")
			if k == 60 * 16 + 30: shot("hb_combo")
			if k == 60 * 17: _force("_rift_cut")
			if k == 60 * 17 + 40: shot("hb_cut")
			if k == 60 * 19: _force("_mark_storm")
			if k == 60 * 20: shot("hb_marks")
			if k == 60 * 21:
				RiftAbilities.mark(arena.players[0], boss, 2)
				_force("_harvest")
			if k == 60 * 23: _force("_phase_step")
			if k == 60 * 24: shot("hb_step")
			if k == 60 * 26:
				boss.take_damage(boss.hp + 10)
				print("  lethal -> alive=", boss.is_alive(), " waking=", _brain()._waking)
			if k == 60 * 28: shot("hb_phase_mid")
			if k == 60 * 33:
				shot("hb_phase2")
				print("  phase2=", _brain()._phase2, " hp=", boss.hp, "/", boss.max_hp, " title=", boss.get_meta("title", ""))
			if k == 60 * 34: _force("_shard_rain")
			if k == 60 * 35: shot("hb_rain")
			if k == 60 * 36: _force("_void_well")
			if k == 60 * 37: shot("hb_well")
			if k == 60 * 39: _force("_mirror_cuts")
			if k == 60 * 39 + 50: shot("hb_mirror")
			if k == 60 * 42: _force("_start_collapse")
			if k == 60 * 43: shot("hb_collapse")
			if k == 60 * 43 + 10:
				boss.take_damage(int(boss.max_hp * 0.09), arena.players[0])
			if k == 60 * 44:
				print("  after interrupt: stunned=", boss.is_stunned(), " charge=", _brain()._charge_t)
			if k == 60 * 48:
				boss._stun_t = 0.0
				boss.take_damage(999999)
				print("  harbinger dead=", not boss.is_alive())
			if k == 60 * 50:
				_wipe()
			if k == 60 * 49 + 20: shot("hb_death1")
			if k == 60 * 51: shot("hb_death2")
			if k == 60 * 58:
				print("after harbinger: state=", arena._state, " finished=", won)
				return true
	return false
