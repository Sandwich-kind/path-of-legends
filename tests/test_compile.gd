extends SceneTree
func _init():
	# все скрипты игры и сами проверочные сценарии должны компилироваться
	var n := 0
	for d in ["core", "ui", "characters", "weapons", "maps", "modes", "story", "tests", "tests/sim"]:
		for f in DirAccess.get_files_at("res://" + d):
			if f.ends_with(".gd"):
				var s = load("res://%s/%s" % [d, f])
				n += 1
				if s == null or not s.can_instantiate():
					print("FAIL ", d, "/", f)
	print("compiled ", n, " scripts")
	quit()
