extends SceneTree
# Снимок: каталог обликов легенды (HERO — номер в Characters.LIST)
var f := 0
func _initialize() -> void:
	Save.load_game()
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.2, 0.25)
	bg.size = Vector2(1600, 720)
	root.add_child(bg)
	var cat := SkinCatalog.new()
	cat.hero = int(OS.get_environment("HERO")) if OS.get_environment("HERO") != "" else 20
	root.add_child(cat)
func _process(_d: float) -> bool:
	f += 1
	if f == 40:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/catalog_%s.png" % OS.get_environment("HERO"))
		return true
	return false
