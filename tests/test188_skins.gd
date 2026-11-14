extends SceneTree
# Облики: огненный сундук без повторов и закрывается, когда всё собрано; облик «Бездна»
# за Арену; выбранный облик меняет модель героя в бою и вид его снарядов.
var main
var f := 0
var fails := 0
var arena: ArenaMode
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])
func shot(n: String) -> void:
	if OS.get_environment("SHOTS") == "1":
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/sk_%s.png" % n)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		Save.data["skins"] = []
		Save.data["skin_sel"] = {}
		var got := {}
		for k in Skins.FIRE.size():
			var id := Skins.open_fire_chest()
			check(id != "" and not got.has(id), "chest gives a new fire skin (%s)" % id)
			got[id] = true
		check(Skins.open_fire_chest() == "" and Skins.fire_left().is_empty(), "chest closed when the series is complete")
		check(Skins.give_abyss(0) and Skins.owned("abyss_hunter"), "abyss skin for finishing the arena")
		var sp := Skins.spec("samurai", "fire_samurai")
		check(sp["hat"] == "ember_kabuto" and sp.get("weapon_look", "") == "ember_katana", "fire samurai has its own headgear")
		Skins.select(0, "abyss_hunter")
		Skins.select(8, "fire_samurai")
		main.sel = [0, 8]
		main.start_arena(true, 1)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
		var p1: Player = arena.players[0]
		check(p1.get_meta("skin", "") == "abyss_hunter" and p1._skin_fx != null, "hero enters with the chosen skin")
		check(p1.rig and (p1.rig as BotRig).spec.get("hat", "") == "void_hood" and (p1.rig as BotRig).spec.get("weapon_look", "") == "void_bow", "rig uses the elaborated skin model")
		p1._cooldown_left = 0.0
		p1.kit.weapon(0.016, true)
	if f == 125:
		var dressed := false
		for n in main.world.get_children():
			if "shooter" in n and n.get("shooter") == arena.players[0]:
				for c in n.get_children():
					if c is Skins.Emitter:
						dressed = true
		check(dressed, "skin dresses the hero's shots")
	if f == 160:
		shot("arena")
		var cat := SkinCatalog.new()
		cat.hero = 8
		root.add_child(cat)
	if f == 190:
		shot("catalog")
		Save.data["skin_sel"] = {}
		print("RESULT fails=", fails)
		return true
	return false
