extends SceneTree
# Ледяная серия: у каждой легенды свой ледяной облик со своими деталями модели, Ледяной сундук
# без повторов закрывается, когда всё собрано; ледяной облик в бою одевает снаряды; кнопка
# «Удалить все облики» и «Очистить прогресс» (вместе с ячейками Истории).
var main
var f := 0
var fails := 0
var arena: ArenaMode
var sc: int

func _initialize() -> void:
	Save.load_game()
	Save.clear_arena_progress("solo")
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		Save.clear_skins()
		check(Save.data["skins"].is_empty() and Save.data["skin_sel"].is_empty(), "debug button clears all skins")
		# у каждой легенды (кроме тестовых) — ровно один ледяной и один огненный облик
		var kits := {}
		for ch in Characters.LIST:
			if ch.has("kit") and not (ch["name"] in Characters.TEST_NAMES):
				kits[ch["kit"]] = ch["rig"]
		var all_ok := true
		var own_look := true
		for kit in kits:
			var n_ice := Skins.ICE.keys().filter(func(id): return Skins.ICE[id][0] == kit).size()
			var n_fire := Skins.FIRE.keys().filter(func(id): return Skins.FIRE[id][0] == kit).size()
			if n_ice != 1 or n_fire != 1:
				all_ok = false
				print("   missing for ", kit, " ice=", n_ice, " fire=", n_fire)
			var id := "ice_" + String(kit)
			var sp := Skins.spec(kits[kit], id)
			var details: Dictionary = Skins.ICE.get(id, ["", "", {}])[2]
			# своя деталь: головной убор, оружие, рамка фото или палитра модели
			if not (details.has("hat") or details.has("weapon_look") or details.has("photo_frame") or details.has("hair_pal") or details.has("helm")):
				own_look = false
				print("   no own look: ", id)
			if sp.get("eye_glow", null) == null and not sp.get("photo", false):
				own_look = false
			if Skins.series_of(id) != "ice":
				all_ok = false
		check(all_ok and kits.size() == Skins.ICE.size(), "every legend has its own ice skin (%d)" % Skins.ICE.size())
		check(own_look, "every ice skin has its own headgear / weapon / frame")
		check(Skins.spec("hunter", "ice_hunter")["hat"] == "frost_hood" and Skins.spec("hunter", "ice_hunter")["back_look"] == "quiver_ice", "ice hunter: frost hood and ice quiver")
		check(Skins.spec("pivozavr", "ice_pivozavr")["photo_frame"] == "frost", "photo legends get a frost frame")
		# сундук
		var got := {}
		for k in Skins.ICE.size():
			var id2 := Skins.open_chest("ice")
			if id2 == "" or got.has(id2) or not Skins.ICE.has(id2):
				check(false, "ice chest gives a new ice skin (%s)" % id2)
			got[id2] = true
		check(got.size() == Skins.ICE.size(), "ice chest gives all %d skins without repeats" % got.size())
		check(Skins.open_chest("ice") == "" and Skins.chest_left("ice").is_empty(), "ice chest closed when the series is complete")
		check(not Skins.chest_left("fire").is_empty(), "fire chest is separate")
		check(Skins.how_to_get("ice_smith") == "Ледяной сундук в Лавке", "catalog says where to get it")
		# модели строятся
		var ok_rigs := true
		for kit in kits:
			var rig := BotRig.new()
			rig.kind = kits[kit]
			rig.custom_spec = Skins.spec(kits[kit], "ice_" + String(kit))
			main.world.add_child(rig)
			if rig.get_child_count() == 0:
				ok_rigs = false
			rig.queue_free()
		check(ok_rigs, "all ice models build")
		sc = Characters.LIST.map(func(c): return c.get("kit", "")).find("smith")
		Skins.select(0, "ice_hunter")
		Skins.select(sc, "ice_smith")
		main.sel = [0, sc]
		main.start_arena(true, 1)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
		var p1: Player = arena.players[0]
		check(p1.get_meta("skin", "") == "ice_hunter" and p1._skin_fx != null and p1._skin_fx.theme == "ice", "hero enters in the ice skin")
		check(p1.rig and (p1.rig as BotRig).spec.get("weapon_look", "") == "ice_bow", "rig uses the ice bow")
		p1._cooldown_left = 0.0
		p1.kit.weapon(0.016, true)
		p1.kit.use(p1.abilities[1])
	if f == 130:
		var dressed := false
		for n in main.world.get_children():
			if "shooter" in n and n.get("shooter") == arena.players[0]:
				for c in n.get_children():
					if c is Skins.Emitter:
						dressed = true
		check(dressed, "ice skin dresses the hero's shots")
		arena.players[0]._start_ult()
	if f == 200:
		var sig := false
		for n in main.world.get_children():
			if n is Skins.Sigil and n.theme == "ice":
				sig = true
		check(sig, "ice ult opens a snowflake sigil")
	if f == 230:
		# «Очистить прогресс»: всё, кроме настроек, и ячейки Истории
		var had := Save.data.duplicate(true)
		StorySave.save_slot(3, {"name": "Проверка", "level": 2})
		check(StorySave.exists(3), "story slot written")
		Save.wipe_all()
		check(Save.gold() == 0 and Save.data.get("skins", []).is_empty() and Save.data["bought"].is_empty() and Save.data["heroes"].is_empty(), "wipe clears gold, legends, skins")
		check(not StorySave.exists(3), "wipe clears story slots")
		# вернуть всё как было (контейнер проверок)
		Save.data = had
		Save.data["skin_sel"] = {}
		Save.save_game()
		print("RESULT fails=", fails)
		return true
	return false
