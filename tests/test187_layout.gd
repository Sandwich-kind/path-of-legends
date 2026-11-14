extends SceneTree
# Своя раскладка экранных кнопок: сохраняется, применяется в бою, сбрасывается.
var main
var f := 0
var fails := 0
var ed: LayoutEditor
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])
func _physics_process(_d: float) -> bool:
	f += 1
	var vs := Config.screen(main)
	if f == 5:
		TouchControls.set_custom("solo", {})
		ed = LayoutEditor.new()
		root.add_child(ed)
	if f == 20:
		ed._select("a1")
		ed._resize(0.3)
		ed._place("a1", Vector2(vs.x * 0.5, vs.y * 0.5))
		ed._done()
	if f == 30:
		var c := TouchControls.custom("solo")
		check(c.has("a1") and absf(float(c["a1"][2]) - 1.3) < 0.01, "custom size saved (%s)" % str(c.get("a1")))
		var g := TouchControls.geometry(vs, "solo", false, true)
		var a1: Array = g["actions"][0]
		var r := Rect2(Vector2(a1[1], a1[2]), a1[4])
		check(r.get_center().distance_to(vs * 0.5) < 3.0 and absf(r.size.x - Config.BTN * 1.3) < 1.0, "geometry uses custom place and size")
		TouchControls.set_custom("solo", {})
		var g2 := TouchControls.geometry(vs, "solo", false, true)
		check(Rect2(Vector2(g2["actions"][0][1], g2["actions"][0][2]), g2["actions"][0][4]).get_center().distance_to(vs * 0.5) > 50.0, "reset restores default")
		print("RESULT fails=", fails)
		return true
	return false
