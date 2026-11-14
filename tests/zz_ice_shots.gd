extends SceneTree
# Снимок: ледяная серия — у каждой легенды обычный вид и ледяной облик рядом (для проверки глазами).
# PAGE=1 — первые 10 легенд, PAGE=2 — остальные; SER=fire|abyss|champ — другая серия для сравнения
var f := 0

func _initialize() -> void:
	Save.load_game()
	var bg := ColorRect.new()
	bg.color = Color(0.20, 0.22, 0.26)
	bg.size = Vector2(1600, 720)
	root.add_child(bg)
	var layer := Node2D.new()
	root.add_child(layer)
	var ser := OS.get_environment("SER") if OS.get_environment("SER") != "" else "ice"
	var list: Array = []
	for i in Characters.display_order():
		var ch: Dictionary = Characters.LIST[i]
		if ch.has("kit") and not (ch["name"] in Characters.TEST_NAMES):
			list.append(i)
	var page := int(OS.get_environment("PAGE")) if OS.get_environment("PAGE") != "" else 1
	list = list.slice(0, 10) if page == 1 else list.slice(10)
	for n in list.size():
		var i: int = list[n]
		var kit: String = Characters.LIST[i]["kit"]
		var cx := 150.0 + (n % 5) * 285.0
		var cy := 250.0 + (n / 5) * 315.0
		HeroFigure.draw(layer, Vector2(cx - 55, cy), 2.2, i, Color(0, 0, 0, 0), 1, false, "")
		HeroFigure.draw(layer, Vector2(cx + 55, cy), 2.2, i, Color(0, 0, 0, 0), 1, false, ser + "_" + kit)
		var l := Label.new()
		var info := Skins.info(ser + "_" + kit)
		l.text = String(info.get("name", "?"))
		l.position = Vector2(cx - 140, cy + 10)
		l.size = Vector2(280, 30)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 16)
		root.add_child(l)

func _process(_d: float) -> bool:
	f += 1
	if f == 50:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/%s_p%s.png" % [OS.get_environment("SER") if OS.get_environment("SER") != "" else "ice", OS.get_environment("PAGE") if OS.get_environment("PAGE") != "" else "1"])
		return true
	return false
