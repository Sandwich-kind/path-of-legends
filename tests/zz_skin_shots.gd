extends SceneTree
# Снимок: проработанные облики Охотницы и Кузнеца рядом с обычными (для проверки глазами)
var f := 0

func _initialize() -> void:
	Save.load_game()
	var bg := ColorRect.new()
	bg.color = Color(0.20, 0.22, 0.26)
	bg.size = Vector2(1600, 720)
	root.add_child(bg)
	var layer := Node2D.new()
	root.add_child(layer)
	var names := Characters.LIST.map(func(c): return c["name"])
	var row := 0
	var heroes := OS.get_environment("HEROES").split(",") if OS.get_environment("HEROES") != "" else PackedStringArray(["ОХОТНИЦА", "КУЗНЕЦ"])
	var k0 := 4.0 if heroes.size() <= 2 else 2.6
	for hero in heroes:
		var i: int = names.find(hero)
		var kit: String = Characters.LIST[i]["kit"]
		var ids := ["", "fire_" + kit, "ice_" + kit, "abyss_" + kit, "champ_" + kit]
		for k in ids.size():
			HeroFigure.draw(layer, Vector2(160 + k * 280, (320 + row * 340) if heroes.size() <= 2 else (230 + row * 235)), k0, i, Color(0, 0, 0, 0), 1, false, ids[k])
		row += 1

func _process(_d: float) -> bool:
	f += 1
	if f == 40:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/skins_hs.png")
		return true
	return false
