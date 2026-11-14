extends SceneTree
# Снимки: новые события ульты Главного — спам-уведомления, звонок, разговор, поджог и заморозка
var main
var f := 0
var arena: ArenaMode
var p1: Player
var k: GlavKit

func _initialize() -> void:
	Save.load_game()
	PadGlyph.force = true                        # на снимке видны подсказки геймпада
	Save.data["skin_sel"] = {}
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/glav_%s.png" % n)

func _call() -> Node:
	for n in main.world.get_children():
		if n is GlavKit.PhoneCall:
			return n
	return null

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.sel = [Characters.LIST.map(func(c): return c.get("kit", "")).find("glav"), 0]
		main.start_arena(false, 21)
	if f == 150:
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
		p1 = arena.players[0]
		k = p1.kit
	if arena == null:
		return false
	if f > 150:
		p1.hp = p1.max_hp
	if f == 300:
		k._ev_spam()
	if f == 350:
		shot("spam")
	if f == 560:
		k._called = false
		k._ev_call()
	if f == 600:
		shot("call")
		_call().answer()
	if f == 640:
		shot("talk")
	if f == 1000:
		k._ev_ignite()
	if f == 1020:
		shot("ignite")
	if f == 1200:
		k._ev_freeze()
	if f == 1215:
		shot("freeze")
		return true
	return false
