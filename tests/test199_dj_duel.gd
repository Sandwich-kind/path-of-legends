extends SceneTree
# DJ Клима в Дуэли: всё работает и без Арены (ноты, слэм, скретч, микрофон по живому
# игроку — тот не может применить способность), раунд не ломается, музыка приёма стихает.
var main
var f := 0
var fails := 0
var p1: Player
var p2: Player
var k: DjKit
var hp0 := 0

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		var idx := Characters.LIST.map(func(c): return c.get("kit", "")).find("dj")
		main.sel = [idx, Characters.LIST.map(func(c): return c.get("kit", "")).find("genius")]
		main.map_id = "test_field"
		main.start_duel()
	if f == 5:
		for n in main.world.get_children():
			if n is Destructible: n.queue_free()
			if n is Player and n.index == 0: p1 = n
			if n is Player and n.index == 1: p2 = n
		k = p1.kit
	if f < 8 or p1 == null:
		return false
	if f == 8:
		p1.frozen = false
		p2.frozen = false
		p1.position = Vector2(600, 565)
		p2.position = Vector2(860, 565)
		p1.facing = 1
	if f > 8:
		p1.hp = p1.max_hp
	if f > 8 and f < 720 and p2.is_alive():
		p2.hp = maxi(p2.hp, 60)
	if f == 30:
		hp0 = p2.hp
		k.use("mic_drop")
	if f == 60:
		check(p2.hp < hp0 and p2.is_stunned() and p2.mute_t > 1.0, "duel: mic stuns and mutes the other player")
		p2._stun_t = 0.0
		p2._cd[0] = 0.0
		Input.action_press("p2_a1")
	if f == 62:
		Input.action_release("p2_a1")
		check(p2._cd[0] <= 0.0, "muted player 2 can't cast")
	if f == 300:
		p2.position = Vector2(700, 565)
		k.use("mosh_slam")
	if f == 300 + int((DjKit.SLAM_BEATS + 1) * DjKit.BEAT * 60.0) + 40:
		check(not k.slamming() and not Audio.hero_track_playing(), "duel slam ends, its music fades out")
	if f == 700:
		p2.position = Vector2(900, 565)
		k.use("scratch_port")
	if f == 720:
		p2.position = Vector2(820, 565)
		p2.hp = p2.max_hp
		hp0 = p2.hp
		k.ult()
	if f == 900:
		check(k.ulting() and p2.hp < hp0, "duel rave: notes hit the other player (-%d)" % (hp0 - p2.hp))
	if f == 720 + 600:
		check(not k.ulting() and not Audio.hero_track_playing(), "duel rave ends (12 beats), music fades out")
		print("RESULT fails=", fails)
		return true
	return false
