extends SceneTree
# Лист общих эффектов (кольцо, ударная волна, искры, пыль, обломки, дым, огненный шар,
# вспышка, звёздочка, свечение) в два момента — для сравнения «до/после». OUT=путь к PNG.
var f := 0
var host: Node2D
var imgs: Array = []
const NAMES := ["ring", "shockwave", "sparks", "dust", "debris", "smoke", "fireball", "flash", "star", "glow"]

func _initialize() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.13, 0.17)
	bg.size = Vector2(1600, 720)
	root.add_child(bg)
	host = Node2D.new()
	root.add_child(host)

func _spawn() -> void:
	seed(3)
	for i in NAMES.size():
		var at := Vector2(160 + (i % 5) * 320, 190 + (i / 5) * 340)
		var c := Color(1.0, 0.75, 0.3)
		match NAMES[i]:
			"ring": Fx.ring(host, at, 110.0, Color(0.5, 0.9, 1.0), 0.45, 8.0)
			"shockwave": Fx.shockwave(host, at, 120.0, Color(1.0, 0.6, 0.9))
			"sparks": Fx.sparks(host, at, c, 16, 420.0, 6.0)
			"dust": Fx.dust(host, at + Vector2(0, 60), 8)
			"debris": Fx.debris(host, at + Vector2(0, 60), 10)
			"smoke":
				for k in 3: Fx.smoke(host, at + Vector2(k * 30 - 30, 40), 26.0)
			"fireball": Fx.fireball(host, at, 80.0)
			"flash": Util.flash(host, at, 70.0, Color(1.0, 0.95, 0.7, 0.9))
			"star": Fx.star(host, at, 46.0, Color(1, 1, 1, 0.95), 0.5)
			"glow": Fx.glow(host, at, 80.0, Color(0.6, 1.0, 0.6, 0.6), 0.6)

func _process(_d: float) -> bool:
	f += 1
	if f == 5 or f == 40:
		for n in host.get_children():
			n.queue_free()
	if f == 6 or f == 41:
		_spawn()
	if f == 6 + 6 or f == 41 + 14:
		imgs.append(root.get_viewport().get_texture().get_image())
	if f == 60:
		var sheet := Image.create(1600, 1440, false, Image.FORMAT_RGBA8)
		for i in imgs.size():
			var im: Image = imgs[i]
			im.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(im, Rect2i(0, 0, 1600, 720), Vector2i(0, i * 720))
		sheet.save_png(OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/claude-0/st/fx_sheet.png")
		return true
	return false
