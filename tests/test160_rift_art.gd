extends SceneTree
# Фоны земель Странника: Летающие острова и горящая окраина (картинки в /tmp/claude-0/arena90/)
func _initialize() -> void:
	var out := "/tmp/claude-0/arena90/"
	var imgs := {"sky": RiftArt.sky_backdrop(2600, 940, 360), "burning": RiftArt.burning_village_backdrop(2600, 940)}
	for k in imgs:
		var im: Image = imgs[k]
		im.resize(im.get_width() * 2, im.get_height() * 2, Image.INTERPOLATE_NEAREST)
		im.save_png(out + "bg_" + k + ".png")
	print("fires=", RiftArt.fires.size())
	print("ok")
	quit()
