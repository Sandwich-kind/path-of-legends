extends SceneTree
# Странник, последняя фаза (в небе на крыльях): после «Веера» и «Сверхновой» не замирает —
# продолжает атаковать; держится сбоку от героя и чуть выше, чтобы по нему можно было попасть.
var main
var f := 0
var fails := 0
var arena: ArenaMode
var p1: Player
var boss: Player
var brain
var uses := 0
var cd0 := {}
var side_ok := 0
var side_n := 0
var late_uses := 0
var stuck := 0
var stuck_max := 0
var fprev := -1.0

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.clear_arena_progress("solo")
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func shot(n: String) -> void:
	if OS.get_environment("SHOTS") == "1":
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/wsky_%s.png" % n)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.sel = [0, 1]
		main.start_arena(false, 100)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
	if arena == null:
		return false
	if f > 120 and boss == null:
		for n in main.world.get_children():
			if n is Player and n.get_node_or_null("WandererBrain") != null and n.is_alive():
				boss = n
				brain = n.get_node("WandererBrain")
		if boss:
			print("   boss found at f=", f)
	if boss == null:
		if f > 3000:
			check(false, "wanderer spawned")
			print("RESULT fails=", fails)
			return true
		return false
	p1.hp = p1.max_hp
	if not brain.has_meta("t5"):
		brain.set_meta("t5", f)
		boss.frozen = false
		boss.cutscene_shield = false
		brain._busy = false
		brain._resume(5)
		boss._bot_cd["nova"] = 2.0
	var t5: int = brain.get_meta("t5")
	if f - t5 > 30:
		for k in boss._bot_cd:
			if float(boss._bot_cd[k]) > float(cd0.get(k, 0.0)) + 0.5:
				uses += 1
				if f - t5 > 60 * 10:
					late_uses += 1
		cd0 = boss._bot_cd.duplicate()
		# «застрял»: в полёте вынужденная пауза не убывает
		if boss.flying and boss._forced_time > 0.0 and is_equal_approx(boss._forced_time, fprev):
			stuck += 1
			stuck_max = maxi(stuck_max, stuck)
		else:
			stuck = 0
		fprev = boss._forced_time
		if f % 10 == 0 and boss.flying and brain._charge_t <= 0.0 and not brain._diving:
			var to: Vector2 = boss.global_position - p1.global_position
			side_n += 1
			if absf(to.x) > 150.0 and to.y < -40.0 and to.y > -220.0:
				side_ok += 1
	if f == t5 + 60 * 8 or f == t5 + 60 * 13 or f == t5 + 60 * 17:
		shot("hover%d" % ((f - t5) / 60))
	if f == t5 + 60 * 25:
		print("   uses=", uses, " late=", late_uses, " side=", side_ok, "/", side_n, " forced=", boss._forced_time, " stuck_max=", stuck_max)
		check(late_uses >= 5, "keeps attacking in the sky (%d abilities in the last 15 s)" % late_uses)
		check(stuck_max < 60, "never stuck after a fan or a nova (longest freeze %d frames)" % stuck_max)
		check(side_n > 0 and float(side_ok) / side_n > 0.6, "hovers beside the hero and a bit higher (%d/%d)" % [side_ok, side_n])
		print("RESULT fails=", fails)
		return true
	return false
