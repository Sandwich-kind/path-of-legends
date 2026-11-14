extends SceneTree
# Крупные кадры модели: Колосс в броне (с трещинами и раскалённым ядром) и остов
# (ядро закрыто / раскрыто / рёв / выдохся). Снимки — в /tmp/claude-0/rework/.
var rigs := []
var f := 0
func _initialize() -> void:
	var holder := Node2D.new()
	root.add_child(holder)
	var bg := ColorRect.new()
	bg.color = Color(0.42, 0.36, 0.30)
	bg.size = Vector2(1600, 720)
	holder.add_child(bg)
	var setups := [["colossus", {}], ["colossus", {"heat": 1.0, "cracks": 3}], ["colossus_endo", {}],
			["colossus_endo", {"open": 1.0}], ["colossus_endo", {"roar": true}], ["colossus_endo", {"spent": true}]]
	for i in setups.size():
		var br := BotRig.new()
		br.kind = setups[i][0]
		br.size = Vector2(160, 220)
		br.position = Vector2(200 + (i % 4) * 400, 420)
		br.scale = Vector2(1.6, 1.6)
		br.visible = i < 4
		holder.add_child(br)
		rigs.append([br, setups[i][1]])
func _process(_d: float) -> bool:
	f += 1
	if f == 3:
		for r in rigs:
			var br: BotRig = r[0]
			var o: Dictionary = r[1]
			if o.has("heat"): br.core_heat = o["heat"]
			if o.has("cracks"): br.shell_cracks(o["cracks"])
			if o.has("open"): br.core_open = o["open"]
			if o.has("spent"):
				br.core_state = "spent"
				br.core_open = 1.0
	if f % 50 == 1:
		for r in rigs:
			if r[1].has("roar"): r[0].play("roar")
	if f == 40:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/rework/r_rigs_a.png")
		for i in rigs.size():
			rigs[i][0].visible = i >= 4
	if f == 46:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/rework/r_rigs_b.png")
		return true
	return false
