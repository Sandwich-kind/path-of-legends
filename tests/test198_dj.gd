extends SceneTree
# DJ Клима: пластинки очередью по 3 (жанр меняется с очередью, у жанров свои эффекты),
# микрофон (оглушает и заглушает, звук глохнет), Лютый слэм (волны в бит, своя музыка,
# финальный удар), Скретч-порт (меняется местами; босса не двигает), Рейв-пати (дроп,
# ноты в такт, финальный аккорд; МЕГА — охранники).
var main
var f := 0
var arena: ArenaMode
var p1: Player
var fails := 0
var hp0 := 0
var pos0 := Vector2.ZERO
var pos1 := Vector2.ZERO
var t1: Player
var t2: Player
var k: DjKit
var g0 := ""
var shots := 0
var seen := {}

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
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/dj_%s.png" % n)

func _count(cls) -> int:
	return main.world.get_children().filter(func(n): return is_instance_of(n, cls)).size()

func _records() -> Array:
	return main.world.get_children().filter(func(n): return n is Bullet and n.style == "vinyl" and not n.is_queued_for_deletion())

func _physics_process(_d: float) -> bool:
	f += 1
	var idx := Characters.LIST.map(func(c): return c.get("kit", "")).find("dj")
	if f == 5:
		check(idx >= 0 and Characters.LIST[idx].get("price", 0) > 0, "DJ Klima sold in the shop")
		check(Characters.display_order().find(idx) < Characters.display_order().find(Characters.LIST.map(func(c): return c["name"]).find("TESTIK_1")), "test legends still last")
		main.sel = [idx, 0]
		main.start_arena(false, 21)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		k = p1.kit
		check(k is DjKit, "kit attached")
		check(p1.rig and p1.rig.spec.get("photo_face", "") == "dj" and p1.rig.spec.get("weapon", "") == "vinyl" and p1.rig.spec.get("hoodie", false), "DJ model: photo face, hoodie, vinyl")
	if arena == null:
		return false
	if f == 300:
		arena._queue.clear()
		for b in arena._alive:
			if is_instance_valid(b): b.queue_free()
		arena._alive.clear()
		p1.facing = 1
		t1 = arena.spawn_at("grunt", p1.global_position + Vector2(240, -20))
		t2 = arena.spawn_at("grunt", p1.global_position + Vector2(330, -20))
		for t in [t1, t2]:
			t.remove_meta("summoned")
			t.max_hp = 5000
			t.hp = 5000
			t.frozen = true
	if f > 300:
		p1.hp = p1.max_hp
		if is_instance_valid(t1):
			arena._queue.clear()
			for n in main.world.get_children():
				if n is Player and n.team != p1.team and n != t1 and n != t2 and n.is_alive():
					n.queue_free()
	# ----- пластинки: одно нажатие — очередь из трёх одного жанра, потом пауза и новый жанр
	if f == 320:
		p1._cooldown_left = 0.0
		p1._reloading = 0.0
		p1.ammo = p1.clip_size
		k.weapon(1.0 / 60.0, true)
		g0 = k.genre
		check(g0 in DjKit.GENRES and k._genre_lbl != null and k._genre_lbl.text.contains(DjKit.GENRE[g0]["name"]), "burst starts a track, genre shown over the head (%s)" % g0)
	if f >= 320 and f < 360:
		for b in _records():                          # кнопку отпустили — очередь всё равно идёт до конца
			seen[b.get_instance_id()] = true
		shots = seen.size()
	if f == 360:
		check(shots == 3 and p1._reloading > 0.0, "one press throws 3 records, then a pause")
	if f == 400:
		p1._reloading = 0.0
		p1.ammo = p1.clip_size
		p1._cooldown_left = 0.0
		k.weapon(1.0 / 60.0, true)
		check(k.genre != g0, "next burst — another genre (%s)" % k.genre)
	# ----- жанры
	if f == 430:
		for t in [t1, t2]:
			t.frozen = false
		k.genre_hit(t1, "jazz", 7, 1.0)
		check(t1._slow_t > 0.0 and t1._slow_mult < 0.8, "jazz slows")
		hp0 = t2.hp
		k.genre_hit(t1, "electro", 7, 1.0)
		check(t2.hp < hp0, "electro jumps to the neighbour (-%d)" % (hp0 - t2.hp))
		k._rock_cd.clear()
		t1._stun_t = 0.0
		k.genre_hit(t1, "rock", 7, 1.0)
		check(t1.is_stunned(), "rock stuns")
		t1._stun_t = 0.0
		k.genre_hit(t1, "rock", 7, 1.0)
		check(not t1.is_stunned(), "rock does not stun the same foe again within 2 s")
		check(int(round(7 * DjKit.POP_MULT)) > 7, "pop hits harder")
		for t in [t1, t2]:
			t.frozen = true
	# ----- микрофон
	if f == 470:
		t1.global_position = p1.global_position + Vector2(170, 0)
		p1.facing = 1
		t1.frozen = false
		t1._stun_t = 0.0
		t1.bot_abilities = {"charge": 6.0}
		hp0 = t1.hp
		k.use("mic_drop")
	if f == 500:
		check(t1.hp < hp0 and t1.is_stunned() and t1.mute_t > 2.0, "mic: hurt, stunned, muted (%.1f s)" % t1.mute_t)
		check(Audio.is_muffled(), "game sound muffles while the mic squeals")
		t1._bot_cd["charge"] = 0.0
		t1._bot_use_abilities(1.0 / 60.0, Vector2(120, 0))
		check(float(t1._bot_cd["charge"]) >= 0.15, "muted foe can't use abilities")
		shot("mic")
	if f == 640:
		check(not Audio.is_muffled(), "sound comes back")
	if f == 700:
		check(t1.mute_t <= 0.0, "mute wears off after 3 s")
		t1.frozen = true
	# ----- Лютый слэм
	if f == 720:
		t1.global_position = p1.global_position + Vector2(90, 0)
		hp0 = t1.hp
		k.use("mosh_slam")
		check(k.slamming() and is_equal_approx(p1.move_mult, 0.75) and is_equal_approx(p1.armor_mult, 0.75), "slam: slower, takes 25 pct less damage")
	if f == 760:
		check(Audio.hero_track_playing(), "slam plays its own music")
		t1.global_position = p1.global_position + Vector2(90, 0)
	if f == 800:
		check(t1.hp < hp0, "slam waves hit on the beat (-%d)" % (hp0 - t1.hp))
		shot("slam")
	if f > 720 and f < 1100 and is_instance_valid(t1):
		t1.global_position.x = p1.global_position.x + 90.0
	if f == 720 + int((DjKit.SLAM_BEATS + 2) * DjKit.BEAT * 60.0) + 40:
		check(not k.slamming() and is_equal_approx(p1.move_mult, 1.0) and is_equal_approx(p1.armor_mult, 1.0), "slam over: speed and armor back")
		check(t1.hp < hp0 - 60, "final stomp landed (total -%d)" % (hp0 - t1.hp))
	# ----- Скретч-порт
	if f == 1150:
		p1.facing = 1
		t1.global_position = p1.global_position + Vector2(300, 0)
		pos0 = p1.global_position
		pos1 = t1.global_position
		hp0 = t1.hp
		k.use("scratch_port")
		check(absf(p1.global_position.x - pos1.x) < 4.0 and absf(t1.global_position.x - pos0.x) < 4.0, "scratch-port swaps places")
		check(t1.hp < hp0 and t1._slow_t > 1.5, "swapped foe hurt and slowed")
	if f == 1180:
		t2.stagger_max = 50.0                          # t2 — «босс»
		p1.facing = 1
		t2.global_position = p1.global_position + Vector2(260, 0)
		pos1 = t2.global_position
		k.use("scratch_port")
		check(t2.global_position.distance_to(pos1) < 2.0 and p1.global_position.x > pos1.x, "boss is not moved — DJ jumps behind it")
		t2.stagger_max = 0.0
	# ----- Рейв-пати
	if f == 1250:
		t1.global_position = p1.global_position + Vector2(200, 0)
		t2.global_position = p1.global_position + Vector2(-220, 0)
		t1.max_hp = 20000
		t1.hp = 20000
		hp0 = t1.hp + t2.hp
		k.ult()
		check(k.ulting() and Audio.hero_track_playing(), "rave: console up, own music on")
	if f > 1250 and f < 1850:
		for t in [t1, t2]:
			if is_instance_valid(t):
				t.velocity = Vector2.ZERO
	if f == 1250 + 100:
		check(t1.hp + t2.hp < hp0, "DROP hit around the console (-%d)" % (hp0 - t1.hp - t2.hp))
		check(_count(DjKit.Note) >= 1, "notes fall on the beat")
		shot("rave")
	if f == 1250 + 200:
		shot("rave2")
	if f == 1250 + int(24.5 * DjKit.BEAT * 60.0):
		check(not k.ulting(), "rave ends after the final chord")
		check(t1.hp + t2.hp < hp0 - 150, "notes + final chord hurt (-%d)" % (hp0 - t1.hp - t2.hp))
	if f == 1860:
		k._rave = null
		var st := DjKit.RaveStage.new()
		st.owner_p = p1
		st.kit = k
		st.mega = true
		st.position = p1.global_position + Vector2(0, p1.body_size.y / 2)
		main.world.add_child(st)
		k._rave = st
		t1.global_position = p1.global_position + Vector2(100, 0)
		hp0 = t1.hp
	if f == 1890:
		check(st_guards() == 2, "MEGA rave: two guards next to the DJ")
	if f == 1960:
		check(t1.hp < hp0, "guards hit whoever comes close (-%d)" % (hp0 - t1.hp))
		shot("guards")
	if f == 2060:
		(k._rave as DjKit.RaveStage).finish()
	if f == 2100:
		# заглушённый игрок не может применять способности
		p1.mute(2.0)
		p1._cd[0] = 0.0
		Input.action_press("p1_a1")
	if f == 2102:
		Input.action_release("p1_a1")
		check(p1._cd[0] <= 0.0, "muted player can't use abilities")
		print("RESULT fails=", fails)
		return true
	return false

func st_guards() -> int:
	var n := 0
	if k._rave and is_instance_valid(k._rave):
		for c in k._rave.get_children():
			if c is DjKit.Guard:
				n += 1
	return n
