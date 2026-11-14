extends SceneTree
# Новые события ульты Главного (поджог всех, заморозка всех, спам-уведомления, звонок с
# паузой: ответить / отклонить / пропустить) и лента обликов при открытии сундука.
var main
var f := 0
var fails := 0
var arena: ArenaMode
var p1: Player
var k: GlavKit
var t1: Player
var t2: Player
var call: Node
var shop: ShopScreen
var f0 := 0

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
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/gc_%s.png" % n)

func _call() -> Node:
	for n in main.world.get_children():
		if n is GlavKit.PhoneCall and not n.is_queued_for_deletion():
			return n
	return null

func _toasts() -> int:
	var l: Variant = main.world.get_node_or_null("GlavToasts")
	return 0 if l == null else (l as Node).get_children().filter(func(c): return not c.is_queued_for_deletion()).size()

func _physics_process(_d: float) -> bool:
	f += 1
	var idx := Characters.LIST.map(func(c): return c.get("kit", "")).find("glav")
	if f == 5:
		main.sel = [idx, 0]
		main.start_arena(false, 21)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		k = p1.kit
	if f < 2150 and (arena == null or not is_instance_valid(arena)):
		return false
	if f == 300:
		arena._queue.clear()
		for b in arena._alive:
			if is_instance_valid(b): b.queue_free()
		arena._alive.clear()
		t1 = arena.spawn_at("grunt", p1.global_position + Vector2(240, -20))
		t2 = arena.spawn_at("grunt", p1.global_position + Vector2(420, -20))
		for t in [t1, t2]:
			t.remove_meta("summoned")
			t.max_hp = 5000
			t.hp = 5000
			t.frozen = true
	if f > 300 and f < 2150:
		p1.hp = p1.max_hp
		if is_instance_valid(t1):
			arena._queue.clear()
			for n in main.world.get_children():
				if n is Player and n.team != p1.team and n != t1 and n != t2 and n.is_alive():
					n.queue_free()
	if f == 330:
		k._ev_ignite()
		check(t1._burn_t > 3.0 and t2._burn_t > 3.0, "ignite: enemies burn")
		check(p1._burn_t > 0.0 and p1._burn_t < 2.0 and p1._burn_dps <= 2.0, "ignite: allies burn too, but weakly")
		t1._burn_t = 0.0
		t2._burn_t = 0.0
		p1._burn_t = 0.0
	if f == 360:
		k._ev_freeze()
		check(t1._freeze_t > 2.0, "freeze: enemies frozen in ice (%.1f s)" % t1._freeze_t)
		check(p1._freeze_t > 0.0 and p1._freeze_t <= 0.8, "freeze: allies frozen briefly")
	# события задевают и боссов (послабее): t2 на время — «босс»
	if f == 420:
		t2.stagger_max = 50.0
		k._ev_freeze()
		check(t2._freeze_t > 0.0 and t2._freeze_t <= 0.8, "freeze: a boss is frozen briefly")
		k._ev_gravity()
		check(t2.velocity.y < -300.0 and t2.velocity.y > -600.0, "gravity: a boss is tossed too, lower")
		t1.set_meta("glav_small", true)
		k._ev_shrink()
		t1.remove_meta("glav_small")
		check(t2.has_meta("glav_small"), "shrink: a boss can be shrunk")
	if f == 420 + 60 * 3 + 30:
		check(not t2.has_meta("glav_small") and is_equal_approx(t2._rig_root.scale.x, 1.0), "shrunk boss grows back")
		t2.stagger_max = 0.0
	if f == 560:
		k._ev_spam()
	if f == 620:
		check(_toasts() >= 3, "spam: notifications pop up (%d)" % _toasts())
		check(t1.glitch_t > 0.0 or t2.glitch_t > 0.0, "spam: enemies are distracted")
		shot("spam")
	# звонок 1: ответить
	if f == 800:
		k._called = false
		k._ev_call()
		call = _call()
		check(call != null and paused, "call pauses the game")
	if f == 830:
		shot("call")
		call.answer()
		check(not paused and call.state == "talk", "answer: game goes on, call keeps talking")
		check(call._voice != null and call._voice.playing, "answer: garbled speech plays")
		f0 = f
	if f == f0 + 60 * 5 + 20 and f0 > 0 and f < 1300:
		check(_call() == null, "talk ends after 5 s")
	# звонок 2: отклонить — приходит сообщение
	if f == 1200:
		k._called = false
		k._ev_call()
	if f == 1210:
		f0 = _toasts()
		var ev := InputEventJoypadButton.new()       # кнопка B на геймпаде — «Отклонить»
		ev.button_index = JOY_BUTTON_B
		ev.pressed = true
		Input.parse_input_event(ev)
	if f == 1216:
		check(not paused and _call() == null, "gamepad B declines, game goes on")
	if f == 1260:
		check(_toasts() > f0, "decline: caller sends a message")
	# звонок 3: не трогать — сбросится через 10 с
	if f == 1500:
		k._called = false
		k._ev_call()
	if f == 1500 + 60 * 10 + 20:
		check(_call() == null and not paused, "unanswered call drops after 10 s")
	if f == 2150:
		check(k.EVENTS.has("call") and k.EVENTS.has("spam") and k.EVENTS.has("ignite") and k.EVENTS.has("freeze"), "new events are in the ult pool")
		# лента обликов в сундуке
		Save.data["gold"] = 5000
		Save.data["skins"] = (Save.data.get("skins", []) as Array).filter(func(id): return not String(id).begins_with("ice_"))
		Save.data["skins"].append("ice_hunter")
		main.show_menu()
		main._on_mode_chosen("shop")
	if f == 2180:
		for n in main.world.get_children():
			if n is ShopScreen:
				shop = n
		shop._select(3)                            # вкладка «Сундуки»
	if f == 2280:
		for o in shop._offers:
			if o is Dictionary and o.get("series", "") == "ice":
				shop._open_chest(o)
		check(shop.roll_ids.size() == ShopScreen.ROLL_CARDS and not ("ice_hunter" in shop.roll_ids), "strip holds only skins you don't have")
		check(shop.roll_ids[ShopScreen.ROLL_WIN] == shop.roll_win and Skins.owned(shop.roll_win), "the skin under the line is granted")
		check(Save.gold() == 5000 - int(Skins.SERIES["ice"]["price"]), "chest paid")
	if f == 2280 + 60 * 3:
		check(not shop._roll_done, "strip is still rolling after 3 s")
	if f == 2280 + 60 * 8:
		check(shop._roll_done and shop._popup != null and is_instance_valid(shop._popup), "strip stops and shows the result")
		var won := shop.roll_win
		shop._close_offer()
		for o in shop._offers:
			if o is Dictionary and o.get("series", "") == "ice":
				shop._open_chest(o)
		check(not (won in shop.roll_ids), "a skin you already got is not on the strip anymore")
		shop._roll_skip()
		check(shop._roll_done, "skip jumps to the end")
	if f == 2280 + 60 * 10:
		Save.data["skin_sel"] = {}
		print("RESULT fails=", fails)
		return true
	return false
