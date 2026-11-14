extends SceneTree
# Замер баланса Арены: герой на автопилоте проходит указанные волны.
# HERO=индекс легенды, WAVES=5,10,15 (по умолчанию все боссы), MAXT=секунд на волну,
# COOP=1 — вдвоём (второй — та же легенда, тоже на автопилоте).
# Герой не умирает насовсем: здоровье после каждого кадра восстанавливается,
# весь полученный урон считается. Вывод: строка RES на волну.
const AP := preload("res://tests/sim/autopilot.gd")
var main
var f := 0
var arena: ArenaMode
var waves: Array = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80]
var wi := -1
var hero := 0
var coop := false
var maxt := 200.0
var pilots: Array = []
var t_fight := -1.0
var t_wave := 0.0
var dmg := 0.0
var deaths := 0
var boss_max := 0
var boss_kind := ""
var started := false
var dealt := 0.0
var _bref: Player
var _bhp := 0

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	if OS.get_environment("WAVES") != "":
		waves = Array(OS.get_environment("WAVES").split(",")).map(func(x): return int(x))
	if OS.get_environment("HERO") != "":
		hero = int(OS.get_environment("HERO"))
	if OS.get_environment("MAXT") != "":
		maxt = float(OS.get_environment("MAXT"))
	coop = OS.get_environment("COOP") == "1"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _next() -> bool:
	for pl in pilots:
		if is_instance_valid(pl):
			pl.release_all()
	pilots.clear()
	wi += 1
	if wi >= waves.size():
		return false
	main.sel = [hero, hero]
	main.start_arena(coop, waves[wi], OS.get_environment("RULES") if OS.get_environment("RULES") != "" else "normal")
	arena = null
	for n in main.world.get_children():
		if n is ArenaMode:
			arena = n
	t_fight = -1.0
	dealt = 0.0
	_bref = null
	t_wave = 0.0
	dmg = 0.0
	deaths = 0
	boss_max = 0
	boss_kind = ""
	started = false
	for i in arena.players.size():
		var ap: Node = AP.new()
		ap.setup(arena.players[i], 7 + wi * 13 + i)
		ap.prefix = arena.players[i].prefix
		main.world.add_child(ap)
		ap.add_to_group("persist")
		pilots.append(ap)
		arena.players[i].died.connect(func(_i): deaths += 1)
	return true

func _report(done: bool) -> void:
	var hp_left := 0.0
	if arena._boss != null and is_instance_valid(arena._boss):
		hp_left = float(arena._boss.hp) / maxf(1.0, arena._boss.max_hp)
	var hk: String = Characters.LIST[hero].get("kit", "?")
	var fight := t_wave - maxf(t_fight, 0.0)
	print("RES hero=%s wave=%d boss=%s bossmax=%d done=%s time=%.1f dmg=%.0f dps_in=%.1f deaths=%d left=%.2f dealt=%.0f php=%d coop=%s" % [
		hk, waves[wi], boss_kind, boss_max, str(done), fight, dmg, dmg / maxf(1.0, fight), deaths, hp_left, dealt,
		arena.players[0].max_hp, str(coop)])

func _physics_process(d: float) -> bool:
	f += 1
	if f == 3:
		_next()
	if arena == null or not is_instance_valid(arena):
		return false
	arena.lives = 99
	for p in arena.players:
		if p.is_alive() and p.hp < p.max_hp:
			if t_fight >= 0.0:
				dmg += p.max_hp - p.hp
			p.hp = p.max_hp
	t_wave += d
	if started and arena._boss != null and is_instance_valid(arena._boss):
		if arena._boss != _bref:
			_bref = arena._boss
			_bhp = _bref.hp
		elif _bref.hp < _bhp:
			dealt += _bhp - _bref.hp
			_bhp = _bref.hp
		else:
			_bhp = _bref.hp
	var boss_wave := false
	for k in Bots.WAVES[int(waves[wi]) - 1]:
		if Bots.is_boss(k):
			boss_wave = true
	if t_fight < 0.0:
		var ready: bool = arena._state == "fight" and (arena._cut_cam == null or not is_instance_valid(arena._cut_cam))
		if boss_wave:
			ready = ready and arena._boss != null and is_instance_valid(arena._boss) and not arena._boss.cutscene_shield
		if ready:
			t_fight = t_wave
			if boss_wave:
				boss_kind = arena._boss.get_meta("kind")
				boss_max = arena._boss.max_hp
			started = true
	if started:
		var over := false
		if boss_wave:
			over = arena._boss == null or not is_instance_valid(arena._boss) or arena._state == "break"
		else:
			over = arena._state == "break"
		if over:
			_report(true)
			if not _next():
				print("DONE")
				return true
		elif t_wave - t_fight > maxt:
			_report(false)
			if not _next():
				print("DONE")
				return true
	elif t_wave > 60.0:
		print("RES hero=? wave=%d STUCK state=%s" % [waves[wi], arena._state])
		if not _next():
			return true
	return false
