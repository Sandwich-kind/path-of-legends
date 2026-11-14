extends SceneTree
# Снимки: приёмы Ассасина, Терновника и Мортиса в проработанных обликах
var main
var f := 0
var run := -1
var t0 := 0
var held := {}
var runs: Array = []
const PLAN := {
	"zarnitsa": [[210, "press", "p1_shoot", 4], [224, "shot", "1shot"], [240, "press", "p1_a1", 2], [262, "shot", "2a1"], [290, "press", "p1_a2", 2], [312, "shot", "3a2"], [340, "press", "p1_a3", 2], [362, "shot", "4a3"], [390, "press", "p1_ult", 2], [440, "shot", "5ult"]],
	"rassvet": [[210, "press", "p1_shoot", 4], [224, "shot", "1shot"], [240, "press", "p1_a1", 2], [262, "shot", "2a1"], [290, "press", "p1_a2", 2], [312, "shot", "3a2"], [340, "press", "p1_a3", 2], [362, "shot", "4a3"], [390, "press", "p1_ult", 2], [440, "shot", "5ult"]],
	"gatekeeper": [[210, "press", "p1_shoot", 4], [224, "shot", "1shot"], [240, "press", "p1_a1", 2], [262, "shot", "2a1"], [290, "press", "p1_a2", 2], [312, "shot", "3a2"], [340, "press", "p1_a3", 2], [362, "shot", "4a3"], [390, "press", "p1_ult", 2], [440, "shot", "5ult"]],
	"echo": [[210, "press", "p1_shoot", 4], [224, "shot", "1shot"], [240, "press", "p1_a1", 2], [262, "shot", "2a1"], [290, "press", "p1_a2", 2], [312, "shot", "3a2"], [340, "press", "p1_a3", 2], [362, "shot", "4a3"], [390, "press", "p1_ult", 2], [440, "shot", "5ult"]],
	"seam": [[210, "press", "p1_shoot", 4], [224, "shot", "1shot"], [240, "press", "p1_a1", 2], [262, "shot", "2a1"], [290, "press", "p1_a2", 2], [312, "shot", "3a2"], [340, "press", "p1_a3", 2], [362, "shot", "4a3"], [390, "press", "p1_ult", 2], [440, "shot", "5ult"]],
}

func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/sk6_%s_%s.png" % [runs[run][1], n])

func press(a: String, n: int) -> void:
	Input.action_press(a)
	held[a] = f + n

func start() -> void:
	var hi: int = runs[run][0]
	Skins.give(runs[run][1])
	Skins.select(hi, runs[run][1])
	main._on_duel_ready("test_field", 9, 99, [hi, 1], {})
	t0 = f

func _physics_process(_d: float) -> bool:
	f += 1
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)
	if f == 10:
		for i in Characters.LIST.size():
			var k: String = Characters.LIST[i].get("kit", "")
			if PLAN.has(k):
				for s in ["fire_", "abyss_", "champ_"]:
					runs.append([i, s + k, k])
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
		foe.position = Vector2(620, 570)
		me.facing = 1
	for st in PLAN[runs[run][2]]:
		if d == st[0]:
			if st[1] == "press":
				me._cd = [0.0, 0.0, 0.0]
				me.ult_charge = 9999
				press(st[2], st[3])
			else:
				shot(st[2])
	if d == 500:
		run += 1
		if run >= runs.size():
			return true
		start()
	return false
