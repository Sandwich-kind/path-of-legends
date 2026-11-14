extends SceneTree
# Снимки: приёмы Солдата, Самурая и Пивозавра в проработанных обликах
var main
var f := 0
var run := -1
var t0 := 0
var held := {}
var runs: Array = []
const PLAN := {
	"soldier": [[210, "press", "p1_shoot", 30], [234, "shot", "1rifle"], [250, "press", "p1_a2", 2], [272, "shot", "2grenade"],
			[300, "press", "p1_ult", 2], [330, "shot", "3mark"], [520, "shot", "4plane"]],
	"samurai": [[210, "press", "p1_shoot", 14], [221, "shot", "1slash"], [250, "press", "p1_a1", 2], [262, "shot", "2wave"],
			[290, "press", "p1_a2", 2], [300, "shot", "3shuriken"], [330, "press", "p1_ult", 2], [400, "shot", "4ult"],
			[410, "press", "p1_shoot", 10], [421, "shot", "5flame"]],
	"pivozavr": [[210, "press", "p1_shoot", 30], [236, "shot", "1caps"], [250, "press", "p1_a1", 2], [300, "shot", "2puddle"],
			[320, "press", "p1_a3", 2], [350, "shot", "3burp"], [380, "press", "p1_ult", 2], [440, "shot", "4ult"]],
}

func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/sk2_%s_%s.png" % [runs[run][1], n])

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
		foe.position = Vector2(700, 570)
		me.facing = 1
	for st in PLAN[runs[run][2]]:
		if d == st[0]:
			if st[1] == "press":
				me._cd = [0.0, 0.0, 0.0]
				me.ult_charge = 9999
				press(st[2], st[3])
			else:
				shot(st[2])
	if d == 560:
		run += 1
		if run >= runs.size():
			return true
		start()
	return false
