extends SceneTree
# Замер нагрузки: Арена вдвоём (Почти легенда и DJ Клима на автопилоте), толпа врагов,
# обе ульты разом (Титан и Рейв-пати), способности по готовности. Печатает строку PERF:
# время кадра (вся работа движка и скриптов за кадр), число узлов и сколько из них — частицы эффектов.
#   BOTS=30     — сколько врагов держать на поле      SECS=20  — сколько секунд мерить
#   FX=full|lite — качество эффектов (как в настройках)
#   HEROES=22,21 — кто дерётся                        ULT=0 — без ульт
# Без окна (--headless) меряется только работа скриптов и физики; число отрисовок (draw calls)
# видно только в окне (xvfb): тогда в строке есть draws=…
const AP := preload("res://tests/sim/autopilot.gd")
var main
var f := 0
var arena: ArenaMode
var bots_n := 30
var secs := 20.0
var heroes := [22, 21]
var t := 0.0
var started := false
var frames: Array = []          # время кадра, мс
var nodes: Array = []
var world_n: Array = []
var fx_n: Array = []
var draws: Array = []
var ult_t := 2.0
var kinds := ["grunt", "tank", "soldier", "grunt", "bomber", "grunt"]
var top := {}
var _last_us := 0
var _slow_printed := 0

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.unlock_all_heroes()
	if OS.get_environment("BOTS") != "":
		bots_n = int(OS.get_environment("BOTS"))
	if OS.get_environment("SECS") != "":
		secs = float(OS.get_environment("SECS"))
	if OS.get_environment("HEROES") != "":
		heroes = Array(OS.get_environment("HEROES").split(",")).map(func(x): return int(x))
	seed(7)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _alive_bots() -> int:
	var n := 0
	for b in arena._alive:
		if is_instance_valid(b) and b.is_alive():
			n += 1
	return n

func _is_fx(n: Node) -> bool:
	# мелкие узлы эффектов: без скрипта, не игрок и не стена
	return n.get_script() == null and (n is Polygon2D or n is Line2D or n is CPUParticles2D or n is Sprite2D or (n is Node2D and n.get_class() == "Node2D"))

func _physics_process(d: float) -> bool:
	f += 1
	if f == 3:
		if OS.get_environment("FX") == "lite":
			(load("res://core/fx.gd") as Script).set("lite", true)      # через скрипт: замер работает и на версиях без настройки
		main.sel = heroes.duplicate()
		main.start_arena(heroes.size() > 1, 21)
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
	if arena == null or not is_instance_valid(arena):
		return false
	if f == 200:
		arena._queue.clear()
		for b in arena._alive:
			if is_instance_valid(b):
				b.queue_free()
		arena._alive.clear()
		for i in arena.players.size():
			var ap: Node = AP.new()
			ap.setup(arena.players[i], 11 + i)
			main.world.add_child(ap)
			ap.add_to_group("persist")
		started = true
	if not started:
		return false
	arena._queue.clear()
	arena.lives = 99
	for p in arena.players:
		if p.is_alive():
			p.hp = p.max_hp
	# толпа: держим на поле BOTS врагов
	if f % 6 == 0 and _alive_bots() < bots_n:
		var kind: String = kinds[randi() % kinds.size()]
		if not Bots.TYPES.has(kind):
			kind = "grunt"
		var b: Player = arena.spawn_at(kind, Vector2(randf_range(300.0, Colosseum.W - 300.0), arena.info["floor"] - 60.0))
		b.remove_meta("summoned")
		b.max_hp *= 6
		b.hp = b.max_hp
		# опыты «что сколько стоит»: EXP=norig — модели врагов не двигаются, EXP=frozen — враги стоят
		if OS.get_environment("EXP") == "norig" and b.rig:
			b.rig.set_process(false)
		if OS.get_environment("EXP") == "frozen":
			b.frozen = true
	t += d
	# ульты у обоих разом — каждые 14 секунд
	ult_t -= d
	if ult_t <= 0.0 and OS.get_environment("ULT") != "0":
		ult_t = 14.0
		for p in arena.players:
			p.ult_charge = p.ult_need
	# цена кадра: без окна и с --fixed-fps движок не ждёт, поэтому время между соседними
	# кадрами — это и есть вся работа за кадр (физика + скрипты + подготовка отрисовки)
	var now_us := Time.get_ticks_usec()
	var frame_ms := (now_us - _last_us) / 1000.0
	_last_us = now_us
	if t > 1.0:
		frames.append(frame_ms)
		if frame_ms > 40.0 and _slow_printed < 10:          # рывки: когда и что было на поле
			_slow_printed += 1
			var names := {}
			for n in main.world.get_children():
				if n.get_script() != null and not (n is Player):
					names[String(n.get_script().resource_path).get_file().trim_suffix(".gd")] = true
			print("SLOW t=%.2f %.0f ms ult_in=%.1f | %s" % [t, frame_ms, ult_t, ",".join(names.keys()).left(160)])
		nodes.append(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		if f % 10 == 0:
			var kids: Array = main.world.get_children()
			world_n.append(kids.size())
			var fx := 0
			for n in kids:
				if _is_fx(n):
					fx += 1
				var cn: String = n.get_class()
				if n.get_script() != null:
					cn = String(n.get_script().resource_path).get_file()
				top[cn] = maxi(int(top.get(cn, 0)), 0) + 1
			fx_n.append(fx)
	if t >= secs + 1.0:
		frames.sort()
		var mean := 0.0
		for x in frames:
			mean += x
		mean /= maxf(frames.size(), 1.0)
		var p50: float = frames[frames.size() / 2]
		var p95: float = frames[int(frames.size() * 0.95)]
		var p99: float = frames[int(frames.size() * 0.99)]
		var slow := frames.filter(func(x): return x > 16.7).size()
		print("PERF fx=%s bots=%d heroes=%s frames=%d mean=%.2fms p50=%.2f p95=%.2f p99=%.2f max=%.2f over16ms=%.1f%% nodes_mean=%d nodes_max=%d world_children_mean=%d world_children_max=%d fx_children_mean=%d fx_children_max=%d draws_mean=%d draws_max=%d" % [
			("lite" if (load("res://core/fx.gd") as Script).get("lite") == true else "full"), bots_n, str(heroes), frames.size(), mean, p50, p95, p99, frames[-1], 100.0 * slow / maxf(frames.size(), 1.0),
			_mean(nodes), int(nodes.max()), _mean(world_n), int(world_n.max()), _mean(fx_n), int(fx_n.max()), _mean(draws), int(draws.max())])
		var keys := top.keys()
		keys.sort_custom(func(a, b): return int(top[a]) > int(top[b]))
		var s := "TOP world children (среднее на замер):"
		for k in keys.slice(0, 12):
			s += " %s=%.0f" % [k, float(top[k]) / maxf(world_n.size(), 1.0)]
		print(s)
		return true
	return false

func _mean(a: Array) -> int:
	if a.is_empty():
		return 0
	var s := 0.0
	for x in a:
		s += float(x)
	return int(s / a.size())
