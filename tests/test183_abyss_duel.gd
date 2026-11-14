extends SceneTree
# Дуэль на новых картах «Ветряные холмы» и «Дворец Бездны»: строятся, звучат как
# свои локации, аномалии бьют обоих игроков (не только первого).
var main
var f := 0
var fails := 0
var maps := ["arena_hills", "arena_palace"]
var mi := 0
var t0 := 0

func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5 + t0:
		main.sel = [0, 1]
		main.map_id = maps[mi]
		main.start_duel()
	if f == 200 + t0:
		var ids: Array = Maps.DUEL_MAPS.map(func(m): return m["id"])
		check(maps[mi] in ids, "%s listed in duel maps" % maps[mi])
		check(Audio.duel_track(maps[mi]) == ("b_hills" if mi == 0 else "b_palace"), "%s plays its stage theme (%s)" % [maps[mi], Audio.duel_track(maps[mi])])
		var p2: Player = main.duel_players[1]
		var hs := AbyssBits._heroes(main.world)
		check(hs.size() == 2 and p2 in hs, "both duelists are affected by abyss hazards (%d)" % hs.size())
	if f == 400 + t0:
		mi += 1
		if mi >= maps.size():
			print("RESULT fails=", fails)
			return true
		t0 = f
	return false
