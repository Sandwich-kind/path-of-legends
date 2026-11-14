extends SceneTree
# Снимки: приёмы Охотницы и Кузнеца в проработанных обликах (огонь, бездна, чемпион)
var main
var f := 0
var run := -1
var t0 := 0
var held := {}
const RUNS := [[0, "fire_hunter"], [0, "abyss_hunter"], [0, "champ_hunter"], [1, "fire_smith"], [1, "abyss_smith"], [1, "champ_smith"]]

func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/sk_%s_%s.png" % [RUNS[run][1], n])

func press(a: String, n: int) -> void:
	Input.action_press(a)
	held[a] = f + n

func start() -> void:
	var hi: int = RUNS[run][0]
	Skins.give(RUNS[run][1])
	Skins.select(hi, RUNS[run][1])
	main._on_duel_ready("test_field", 9, 99, [hi, 1 - hi], {})
	t0 = f

func _physics_process(_d: float) -> bool:
	f += 1
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)
	if f == 10:
		run = 0
		start()
	if run < 0:
		return false
	var d := f - t0
	var me: Player = main.duel_players[0]
	var foe: Player = main.duel_players[1]
	me._protect = 1.0
	foe._protect = 0.0
	if foe.hp < 60:
		foe.hp = foe.max_hp
	if d == 200:
		me.position = Vector2(300, 570)
		foe.position = Vector2(760, 570)
		me.facing = 1
	if RUNS[run][0] == 0:
		match d:
			210: press("p1_shoot", 40)
			256: shot("1arrow")
			270: me._cd = [0.0, 0.0, 0.0]; press("p1_a2", 2)
			300: shot("2trap")
			310: me.position = Vector2(300, 570); press("p1_a3", 2)
			322: shot("3hook")
			345: me.position = Vector2(300, 570); me.ult_charge = 999; press("p1_ult", 2)
			470: shot("4ult")
	else:
		match d:
			210: me.facing = 1; press("p1_a2", 2)
			232: shot("1anvil")
			250: me._cd = [0.0, 0.0, 0.0]; foe.position = Vector2(760, 570); press("p1_a3", 2)
			268: shot("2throw")
			300: me.position = Vector2(200, 570); me._cd = [0.0, 0.0, 0.0]; press("p1_a1", 2)
			336: shot("3leap")
			380: me.position = Vector2(300, 570); foe.position = Vector2(470, 570); me.ult_charge = 999; press("p1_ult", 2)
			412: shot("4ult")
	if d == 520:
		run += 1
		if run >= RUNS.size():
			return true
		start()
	return false
