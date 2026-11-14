extends SceneTree
# Музыка и звуки: все треки и звуки на месте, слои переключаются, громкость из настроек,
# звуки не наслаиваются бесконечно, в бою (Арена, Дуэль) ничего не ломается.
var main
var f := 0
var errors := 0
var saved := {}

func _initialize() -> void:
	Save.load_game()
	saved = StorySettings.load_all()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		errors += 1
		print("FAIL: ", what)

func _physics_process(_d: float) -> bool:
	f += 1
	match f:
		3:
			check(Audio.inst != null, "Audio node exists")
			check(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0, "buses")
			check(Audio.current_track() == "menu", "menu track: " + Audio.current_track())
			# треки Дуэли — 3 слоя одной длины; меню, Лавка и вся Арена — по одному слою; петля включена
			var arena_ids := {}
			for a in Audio.STAGE_BATTLE + Audio.STAGE_MINI + Audio.STAGE_BOSS + Audio.FINAL.values():
				arena_ids[a] = true
			var ids: Array = Audio.DUEL_TRACKS + ["menu", "shop"] + arena_ids.keys()
			for id in ids:
				var st: AudioStream = Audio.inst._track_stream(id)
				check(st != null, "track " + id)
				if st == null:
					continue
				var n: int = st.stream_count
				check(n == (3 if id in Audio.DUEL_TRACKS else 1), "layers %s = %d" % [id, n])
				var l0: float = st.get_sync_stream(0).get_length()
				for i in n:
					var s: AudioStream = st.get_sync_stream(i)
					check(s is AudioStreamOggVorbis and s.loop, "loop %s_%d" % [id, i])
					check(absf(s.get_length() - l0) < 0.05, "same length %s_%d: %.3f vs %.3f" % [id, i, s.get_length(), l0])
				check(l0 > 20.0 and l0 < 95.0, "length %s %.1f" % [id, l0])
			for sid in Audio.STINGER_PRIO:
				check(ResourceLoader.exists("res://audio/music/sting_%s.ogg" % sid), "stinger " + sid)
			for id in Audio.SFX:
				var n: int = Audio.SFX[id][0]
				for k in n:
					var p := "res://audio/sfx/%s.wav" % id if n <= 1 else "res://audio/sfx/%s_%d.wav" % [id, k + 1]
					check(ResourceLoader.exists(p), "sfx " + p)
			# у каждого босса Арены — свой голос появления, и все разные
			var voices := {}
			for k in Bots.TYPES:
				if Bots.TYPES[k].get("boss", false) and Bots.first_wave(k) > 0:
					var vid: String = Audio.BOSS_INTRO.get(k, "")
					check(vid != "" and Audio.SFX.has(vid), "boss intro for " + k)
					voices[vid] = true
			check(voices.size() >= 18, "boss intros distinct: %d" % voices.size())
			# громкость из настроек — сразу
			StorySettings.set_value("music", 50)
			StorySettings.set_value("sfx", 0)
		25:
			var mi := AudioServer.get_bus_index("Music")
			var si := AudioServer.get_bus_index("SFX")
			check(absf(AudioServer.get_bus_volume_db(mi) - Audio.slider_db(50)) < 0.01, "music volume %.2f" % AudioServer.get_bus_volume_db(mi))
			check(AudioServer.is_bus_mute(si), "sfx muted at 0")
			StorySettings.set_value("music", int(saved.get("music", 80)))
			StorySettings.set_value("sfx", int(saved.get("sfx", 80)))
			# слои Дуэли: в «Мгновенную смерть» громче
			Audio.music("duel1")
			Audio.intensity(2)
		160:
			check(Audio.current_track() == "duel1", "duel1 playing")
			var st: AudioStreamSynchronized = Audio.inst._music[Audio.inst._cur].stream
			for i in 3:
				check(st.get_sync_stream_volume(i) > -1.0, "layer %d up: %.1f" % [i, st.get_sync_stream_volume(i)])
			Audio.intensity(0)
			# лавина звуков: одинаковых сразу не больше заданного
			for k in 60:
				for id in Audio.SFX:
					Audio.sfx(id, Vector2(randf_range(0, 2000), 500))
					Audio.sfx(id)
			var counts := {}
			for p in Audio.inst._pool2d + Audio.inst._pool_ui:
				if p.playing:
					counts[p.get_meta("sfx")] = counts.get(p.get_meta("sfx"), 0) + 1
			for id in counts:
				check(counts[id] <= int(Audio.SFX[id][2]), "too many " + id)
			Audio.stinger("wave_clear")
			Audio.stinger("boss_down")
			Audio.stinger("victory")
		260:
			var st: AudioStreamSynchronized = Audio.inst._music[Audio.inst._cur].stream
			check(st.get_sync_stream_volume(1) < -40.0 and st.get_sync_stream_volume(2) < -40.0, "layers down")
			check(Audio.inst._sting.playing, "stinger playing")
			# Арена: боевая тема локации, мини-босс и босс — свои треки
			main.start_arena(false, 1)
		300:
			check(Audio.current_track() == "b_forest", "arena stage 0 = b_forest: " + Audio.current_track())
			Audio.intensity(1)
			check(Audio.current_track() == "mini_1", "mini-boss track: " + Audio.current_track())
			Audio.intensity(2)
			check(Audio.current_track() == "boss_1", "boss track: " + Audio.current_track())
			Audio.intensity(0)
			check(Audio.current_track() == "b_forest", "back to battle: " + Audio.current_track())
			check(Audio.arena_track(15, 3) == "boss_lord_final" and Audio.arena_track(18, 3) == "boss_rift_final", "final phases")
			check(Audio.arena_track(17, 1) == "mini_3" and Audio.arena_track(18, 0) == "b_fire", "rift stages")
		700:
			# Дуэль: карта-арена звучит боевой темой своей локации, остальные — темы Дуэли
			check(Audio.duel_track("arena_ice") == "b_frost", "arena_ice")
			check(Audio.duel_track("arena_citadel") == "b_throne", "citadel")
			check(Audio.duel_track("castles") in Audio.DUEL_TRACKS, "castles fallback")
			check(Audio.duel_track("some_new_map") in Audio.DUEL_TRACKS, "unknown map fallback")
			main.map_id = "two_houses"
			main.duel_opts = {"heal": true, "buffs": true, "mega": false, "sd": true, "sd_time": 3}
			main.start_duel()
		720:
			check(Audio.current_track() in Audio.DUEL_TRACKS, "duel track " + Audio.current_track())
		1150:
			check(Audio.current_level() == 2, "sudden death raises music: %d" % Audio.current_level())
			main.show_menu()
		1160:
			check(Audio.current_track() == "menu", "back to menu")
			main._on_mode_chosen("shop")
		1170:
			check(Audio.current_track() == "shop", "shop music: " + Audio.current_track())
			main.show_menu()
		1180:
			check(Audio.current_track() == "menu", "menu again")
			print("audio errors: ", errors)
			print("AUDIO TEST " + ("OK" if errors == 0 else "FAILED"))
			return true
	return false
