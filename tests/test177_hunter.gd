extends SceneTree
# Охотница на Арене: без перезарядки; стрела на полном натяжении прошивает
# 2 врагов (третий её останавливает); МЕГА-кувырок — стрела пригвождает врагов
# до взрыва следа, взрыв их ранит.
var main
var f := 0
var arena: ArenaMode
var p1: Player
var bots: Array = []
var hp := []
var fails := 0
var shots := "/tmp/claude-0/hunter/"
var reloaded := false

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}                 # облики не должны влиять на проверку (у них свои случайные искры)
	Save.unlock_all_heroes()
	DirAccess.make_dir_recursive_absolute(shots)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		if img: img.save_png(shots + n + ".png")

func line_up(kind: String) -> void:
	for b in bots:
		if is_instance_valid(b):
			b.queue_free()
	bots = []
	hp = []
	var feet := p1.global_position.y + p1.body_size.y / 2
	for k in 4:
		var b := arena.spawn_at(kind, p1.global_position + Vector2(260 + k * 110, -10))
		b.max_hp = 3000
		b.hp = 3000
		b.bot_abilities = {}
		b.global_position = Vector2(p1.global_position.x + 260 + k * 110, feet - b.body_size.y / 2 - 1)
		b.velocity = Vector2.ZERO
		b.frozen = true
		bots.append(b)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.sel = [0, 0]
		main.start_arena(false, 3)
	if f == 125:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		p1.frozen = false
		p1._protect = 999.0
		for b in arena._alive:
			if is_instance_valid(b):
				b.queue_free()
		arena._queue.clear()
		p1.global_position.x = 700
		p1.facing = 1
	# 1. без перезарядки: 12 коротких выстрелов
	if f > 130 and f < 330:
		if (f - 130) % 16 < 3:
			Input.action_press("p1_shoot")
		else:
			Input.action_release("p1_shoot")
		if p1._reloading > 0.0:
			reloaded = true
	if f == 330:
		Input.action_release("p1_shoot")
		check(not reloaded and p1.ammo == p1.clip_size, "no reload in Arena (ammo %d)" % p1.ammo)
	# 2. полное натяжение
	if f == 340:
		p1.global_position.x = 700
		p1.facing = 1
		line_up("fighter")
	if f == 358:
		for b in bots:
			b.frozen = true
		# убираем ящики на линии выстрела — проверяем только прошивание врагов
		for n in main.world.get_children():
			if n is Destructible and not n.background and n.global_position.x > 740.0 and n.global_position.x < 1450.0 \
					and absf(n.global_position.y - p1.global_position.y) < 120.0:
				n.queue_free()
	if f == 360:
		Input.action_press("p1_shoot")
	if f == 420:
		Input.action_release("p1_shoot")
	if f == 424:
		shot("power")
	if f == 470:
		var hits := []
		for b in bots:
			hits.append(3000 - b.hp)
		print("power hits: ", hits)
		check(hits[0] > 0 and hits[1] > 0 and hits[2] > 0 and hits[3] == 0, "full-draw arrow pierces 2 foes, 3rd stops it")
	# 3. МЕГА-кувырок: стрела пригвождает до взрыва следа
	if f == 480:
		p1.global_position.x = 700
		p1.facing = 1
		line_up("fighter")
		p1.mega_mode = true
		p1._cd = [0.0, 0.0, 0.0]
		Input.action_press("p1_a1")
	if f == 481:
		Input.action_release("p1_a1")
	if f == 500:
		for b in bots:
			b.frozen = true
	if f == 520:
		p1.facing = 1
		Input.action_press("p1_shoot")
	if f == 523:
		Input.action_release("p1_shoot")
	if f == 545:
		shot("ghost_pin")
		var st := []
		for b in bots:
			st.append(snappedf(maxf(b._root_t, b._stun_t), 0.1))
		print("pinned after ghost: ", st)
		check(st[0] > 1.0 and st[3] > 1.0, "ghost arrow pins foes in place")
		for b in bots:
			b.frozen = false
		for b in bots:
			hp.append(b.hp)
	if f == 520 + 60 * 2 + 10:
		var dmg := []
		for i in bots.size():
			dmg.append(hp[i] - bots[i].hp)
		print("trail blast dmg: ", dmg)
		check(dmg[0] > 0 and dmg[3] > 0, "trail blast hits the pinned foes")
		shot("ghost_boom")
	if f == 520 + 60 * 3:
		print("RESULT fails=", fails)
		return true
	return false
