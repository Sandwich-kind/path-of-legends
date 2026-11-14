class_name Audio
extends Node
# ---------- Музыка и звуки ----------
# Один узел на всю игру (его создаёт main.gd), всё вызывается статически:
#   Audio.music("forest")      — трек (плавная смена); Audio.stop_music()
#   Audio.intensity(0..3)      — 0 обычный бой, 1 мини-босс, 2 босс, 3 последняя фаза
#   Audio.stinger("boss_down") — короткая музыкальная вставка поверх трека
#   Audio.sfx("hit", pos)      — звук (pos — точка в мире, без неё — «в ушах»)
# Музыка и звуки сгенерированы скриптами проекта (tools/music).
# Арена: у каждой локации своя боевая тема (tools/music/battle_tracks.py), а мини-босс
# и босс — это отдельные, более быстрые и тяжёлые треки: Audio.intensity(1/2) меняет
# трек целиком, intensity(3) — последняя фаза Тёмного Лорда и Предвестника.
# Дуэль и меню: у трека 3 слоя одной длины (base, battle, boss), они играют
# синхронно, и в «Мгновенную смерть» громкость слоёв нарастает.
# Громкость берётся из настроек (Музыка / Звуки) и обновляется сразу.
# Если узла нет (тесты без main) — все вызовы просто ничего не делают.

static var inst: Audio

const MUSIC_DIR := "res://audio/music/"
const SFX_DIR := "res://audio/sfx/"
const LAYERS := 3
# Спокойные темы локаций (audio/music/story/): в Арене больше не звучат — оставлены для Истории.
# В сборку APK не попадают (export_presets: exclude_filter).
const STAGE_TRACKS := ["forest", "village", "jungle", "jungle_night", "caves", "kingdom", "gems", "crystals",
		"colosseum", "colosseum_night", "eerie", "swamp", "ice", "storm", "lava", "throne", "citadel", "sky",
		"village_fire"]
const DUEL_TRACKS := ["duel1", "duel2", "duel3"]
# Арена: боевая тема каждой локации, мини-босс и босс по этапу пути, последние фазы
const STAGE_BATTLE := ["b_forest", "b_village", "b_jungle", "b_jungle", "b_caves", "b_caves", "b_deep", "b_deep",
		"b_colosseum", "b_colosseum", "b_eerie", "b_eerie", "b_frost", "b_frost", "b_inferno", "b_throne",
		"b_throne", "b_sky", "b_fire", "b_hills", "b_palace", "b_palace"]
const STAGE_MINI := ["mini_1", "mini_1", "mini_1", "mini_1", "mini_1", "mini_1", "mini_1", "mini_1",
		"mini_2", "mini_2", "mini_2", "mini_2", "mini_2", "mini_2", "mini_2", "mini_2", "mini_2", "mini_3", "mini_3",
		"mini_4", "mini_4", "mini_4"]
const STAGE_BOSS := ["boss_1", "boss_1", "boss_1", "boss_1", "boss_2", "boss_2", "boss_2", "boss_2",
		"boss_3", "boss_3", "boss_3", "boss_3", "boss_4", "boss_4", "boss_lord", "boss_lord", "boss_lord",
		"boss_rift", "boss_rift", "boss_rift", "boss_wanderer", "boss_lord"]
const FINAL := {"boss_lord": "boss_lord_final", "boss_rift": "boss_rift_final", "boss_wanderer": "boss_wanderer_final"}
var _arena_stage := -1            # Арена: этап, музыку которого сейчас выбираем (-1 — не Арена)
# Громкость слоёв (линейно) на каждой ступени напряжения
const LEVELS := [[1.0, 0.0, 0.0], [1.0, 1.0, 0.0], [1.0, 1.0, 1.0], [1.0, 1.0, 1.25]]
const LAYER_FADE := 0.9          # за столько секунд слой входит/уходит
const TRACK_FADE := 1.2          # смена трека
const STINGER_DUCK := 0.35       # музыка тише, пока играет вставка

# Звуки: сколько вариантов (_1.._N), пауза между повторами (с), сколько одновременно, громкость (дБ)
const SFX := {
	"shot_bow": [3, 0.05, 3, -3.0], "shot_gun": [3, 0.045, 3, -6.0], "shot_heavy": [2, 0.08, 2, -3.0],
	"shot_magic": [3, 0.05, 3, -6.0], "shot_throw": [3, 0.05, 3, -4.0], "swing": [3, 0.06, 3, -4.0],
	"swing_heavy": [2, 0.08, 2, -3.0], "hit": [3, 0.045, 4, -5.0], "hit_big": [1, 0.1, 2, -3.0],
	"clank": [2, 0.12, 2, -9.0], "impact": [3, 0.06, 3, -12.0], "boom_small": [2, 0.07, 3, -3.0],
	"boom_big": [2, 0.12, 2, 0.0], "break_wood": [2, 0.08, 2, -9.0], "break_stone": [2, 0.08, 2, -9.0],
	"break_glass": [2, 0.08, 2, -10.0], "hurt": [2, 0.14, 2, -2.0], "death_hero": [1, 0.2, 2, 0.0],
	"death_bot": [2, 0.06, 3, -6.0], "death_boss": [1, 0.5, 1, 0.0], "jump": [2, 0.08, 2, -12.0],
	"ability": [2, 0.08, 3, -4.0], "mega": [1, 0.12, 2, -3.0], "ult": [1, 0.3, 2, 0.0], "heal": [1, 0.15, 2, -4.0],
	"buff": [1, 0.15, 2, -3.0], "buff_mega": [1, 0.2, 2, -1.0], "coin": [2, 0.08, 2, -8.0], "click": [1, 0.03, 2, -8.0],
	"beep": [1, 0.1, 1, -5.0], "go": [1, 0.3, 1, -2.0], "horn": [1, 0.5, 1, -4.0], "roar": [1, 0.6, 1, -1.0],
	"stun": [1, 0.3, 2, -4.0], "siren": [1, 1.0, 1, -3.0], "zap": [2, 0.08, 3, -6.0], "slam": [2, 0.1, 2, -3.0],
	"fire": [1, 0.15, 2, -8.0], "splat": [2, 0.08, 2, -8.0], "notify": [1, 0.08, 3, -6.0],
	"scratch": [2, 0.08, 2, -4.0], "feedback": [1, 0.3, 1, -6.0], "drop": [1, 0.4, 1, -2.0], "vinyl": [3, 0.05, 3, -6.0],
	"baton": [2, 0.08, 2, -6.0],
	"punch": [2, 0.06, 3, -5.0], "rail": [1, 0.2, 2, -3.0], "meteor": [1, 0.3, 2, -5.0], "rocket": [1, 0.3, 1, -4.0],
	"laser": [1, 0.3, 1, -5.0], "servo": [1, 0.5, 1, -2.0], "orb": [1, 0.5, 1, -3.0],
	"intro_war": [1, 1.0, 1, 0.0], "intro_bandit": [1, 1.0, 1, 0.0], "intro_goblin": [1, 1.0, 1, 0.0],
	"intro_wood": [1, 1.0, 1, 0.0], "intro_insect": [1, 1.0, 1, 0.0], "intro_bone": [1, 1.0, 1, 0.0],
	"intro_mine": [1, 1.0, 1, 0.0], "intro_crystal": [1, 1.0, 1, 0.0], "intro_arena": [1, 1.0, 1, 0.0],
	"intro_giant": [1, 1.0, 1, 0.0], "intro_witch": [1, 1.0, 1, 0.0], "intro_swamp": [1, 1.0, 1, 0.0],
	"intro_ice": [1, 1.0, 1, 0.0], "intro_storm": [1, 1.0, 1, 0.0], "intro_hell": [1, 1.0, 1, 0.0],
	"intro_dark": [1, 1.0, 1, 0.0], "intro_void": [1, 1.0, 1, 0.0], "intro_herald": [1, 1.0, 1, 0.0],
	"intro_mill": [1, 1.0, 1, 0.0], "intro_headsman": [1, 1.0, 1, 0.0], "intro_weaver": [1, 1.0, 1, 0.0],
	"intro_wanderer": [1, 1.0, 1, 0.0], "intro_shepherd": [1, 1.0, 1, 0.0],
	"intro_abyss_lord": [1, 1.0, 1, 0.0], "intro_mad_wanderer": [1, 1.0, 1, 0.0],
}
# Появление босса: у каждого свой голос (tools/music/sfx.py --intros)
# Голоса, которые на слух громче остальных (фанфара с трибунами, рог великана) — тише
const INTRO_DB := {"intro_arena": -7.0, "intro_ice": -7.0}
const BOSS_INTRO := {
	"sergeant": "intro_war", "ataman": "intro_bandit", "chief": "intro_goblin", "treant": "intro_wood",
	"spider_queen": "intro_insect", "skeleton_king": "intro_bone", "baron_gryz": "intro_mine", "irida": "intro_crystal",
	"gladiator": "intro_arena", "colossus": "intro_giant", "witch": "intro_witch", "bog_lord": "intro_swamp",
	"jotun": "intro_ice", "storm_lord": "intro_storm", "cerberus": "intro_hell", "dark_lord": "intro_dark",
	"voidwing": "intro_void", "harbinger": "intro_herald", "mill_giant": "intro_mill", "void_shepherd": "intro_shepherd", "abyss_headsman": "intro_headsman",
	"rift_weaver": "intro_weaver", "wanderer": "intro_wanderer",
	"abyss_lord": "intro_abyss_lord", "mad_wanderer": "intro_mad_wanderer",      # финалы сложной Арены
}
# Чем стреляет легенда
const HERO_SHOT := {"hunter": "shot_bow", "smith": "swing_heavy", "champion": "shot_throw", "ternovnik": "shot_throw",
		"mortis": "shot_magic", "soldier": "shot_gun", "samurai": "swing", "prism": "shot_magic",
		"assassin": "shot_throw", "osoka": "shot_throw", "zarnitsa": "shot_magic", "rassvet": "swing", "echo": "shot_magic", "seam": "shot_throw", "glav": "shot_magic", "genius": "shot_throw", "scribe": "shot_magic", "dj": "vinyl", "almost": "punch",
		"pivozavr": "shot_throw", "gatekeeper": "shot_magic"}
const POOL_2D := 14
const POOL_UI := 5

var _music: Array = []           # два проигрывателя для плавной смены трека
var _cur := 0                    # какой из них сейчас звучит
var _track := ""
var _track_vol := [0.0, 0.0]     # громкость проигрывателей (линейно)
var _track_want := [0.0, 0.0]
var _layers := [1.0, 0.0, 0.0]   # громкость слоёв текущего трека
var _level := 0
var _streams := {}               # кэш загруженных звуков
var _sting: AudioStreamPlayer
var _sting_queue: Array = []
var _sting_prio := 0
var _duck := 1.0
var _pool2d: Array = []
var _pool_ui: Array = []
var _last := {}                  # когда звучал каждый звук (мс)
var _settings_t := 0.0
var _vol := [-1.0, -1.0]
var _gold := -1
var _bus_music := 0
var _bus_sfx := 0
var _bus_ring := 0
var _hero: AudioStreamPlayer      # своя музыка приёма легенды (слэм и рейв DJ Климы) поверх трека
var _hero_vol := 0.0
var _hero_want := 0.0
var _hero_fade := 0.6
var _muffle_t := 0.0              # микрофон DJ Климы фонит: звук игры глохнет
var _muffle := 0.0

# ---------- Создание ----------
static func setup(parent: Node) -> void:
	if inst != null and is_instance_valid(inst):
		return
	var a := Audio.new()
	a.name = "Audio"
	parent.add_child(a)

func _enter_tree() -> void:
	inst = self

func _exit_tree() -> void:
	if inst == self:
		inst = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS     # и на паузе: щелчки кнопок, музыка
	_bus_music = _ensure_bus("Music")
	_bus_sfx = _ensure_bus("SFX")
	_bus_ring = _ensure_bus("Ring")          # звон в ушах — мимо заглушки
	for b in [_bus_music, _bus_sfx]:
		if AudioServer.get_bus_effect_count(b) == 0:
			var lpf := AudioEffectLowPassFilter.new()
			lpf.cutoff_hz = 20000.0
			AudioServer.add_bus_effect(b, lpf)
	_hero = AudioStreamPlayer.new()
	_hero.bus = "Music"
	_hero.volume_db = -80.0
	_hero.process_mode = Node.PROCESS_MODE_PAUSABLE   # игра на паузе — и музыка приёма замирает (бит не убежит)
	add_child(_hero)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -80.0
		add_child(p)
		_music.append(p)
	_sting = AudioStreamPlayer.new()
	_sting.bus = "Music"
	add_child(_sting)
	_sting.finished.connect(_next_sting)
	for i in POOL_2D:
		var p2 := AudioStreamPlayer2D.new()
		p2.bus = "SFX"
		p2.max_distance = 2600.0
		p2.attenuation = 1.2
		p2.panning_strength = 0.6
		add_child(p2)
		_pool2d.append(p2)
	for i in POOL_UI:
		var pu := AudioStreamPlayer.new()
		pu.bus = "SFX"
		add_child(pu)
		_pool_ui.append(pu)
	_apply_settings()
	get_tree().node_added.connect(_on_node_added)

static func _ensure_bus(bus_name: String) -> int:
	var i := AudioServer.get_bus_index(bus_name)
	if i == -1:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, "Master")
	return i

# Ползунок 0–100 -> децибелы (кривая мягче линейной: 50 ≈ −10 дБ)
static func slider_db(v: float) -> float:
	if v <= 0.0:
		return -80.0
	return linear_to_db(pow(clampf(v / 100.0, 0.0, 1.0), 1.6))

func _apply_settings() -> void:
	var s: Dictionary = StorySettings._cache if not StorySettings._cache.is_empty() else StorySettings.load_all()
	var m := float(s.get("music", 80))
	var e := float(s.get("sfx", 80))
	if m != _vol[0]:
		_vol[0] = m
		AudioServer.set_bus_volume_db(_bus_music, slider_db(m))
		AudioServer.set_bus_mute(_bus_music, m <= 0.0)
	if e != _vol[1]:
		_vol[1] = e
		AudioServer.set_bus_volume_db(_bus_sfx, slider_db(e))
		AudioServer.set_bus_mute(_bus_sfx, e <= 0.0)
		AudioServer.set_bus_volume_db(_bus_ring, slider_db(e))
		AudioServer.set_bus_mute(_bus_ring, e <= 0.0)

# Любая кнопка в игре щёлкает
func _on_node_added(n: Node) -> void:
	if n is BaseButton and not n.has_meta("silent"):
		n.pressed.connect(func(): sfx("click"))

# ---------- Музыка ----------
static func music(id: String) -> void:
	if inst:
		inst._arena_stage = -1            # меню, Дуэль, Лавка — уже не Арена
		inst._play_track(id)

# Музыка приёма легенды поверх трека (основной трек на это время почти стихает)
static func hero_track(id: String) -> void:
	if inst == null:
		return
	var st: AudioStream = inst._sfx_stream(MUSIC_DIR + id + ".ogg")
	if st == null:
		return
	inst._hero.stream = st
	inst._hero.play()
	inst._hero_vol = 1.0
	inst._hero_want = 1.0
	inst._hero.volume_db = 0.0

static func stop_hero_track(fade := 0.6) -> void:
	if inst:
		inst._hero_want = 0.0
		inst._hero_fade = maxf(0.05, fade)

static func hero_track_playing() -> bool:
	return inst != null and inst._hero.playing and inst._hero_want > 0.0

# Звук игры глохнет на t секунд (фонящий микрофон), звон в ушах — отдельным звуком
static func muffle(t: float) -> void:
	if inst:
		inst._muffle_t = maxf(inst._muffle_t, t)

# Звук мимо заглушки (звон в ушах при фонящем микрофоне)
static func ring_sfx(id: String, db := 0.0) -> void:
	if inst == null:
		return
	var st := inst._sfx_stream(SFX_DIR + id + ".wav")
	if st == null:
		return
	var p := AudioStreamPlayer.new()
	p.bus = "Ring"
	p.stream = st
	p.volume_db = db
	inst.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

static func is_muffled() -> bool:
	return inst != null and inst._muffle > 0.5

static func stop_music(fade := TRACK_FADE) -> void:
	if inst:
		inst._track = ""
		inst._track_want = [0.0, 0.0]

static func intensity(level: int) -> void:
	if inst == null:
		return
	var lv := clampi(level, 0, LEVELS.size() - 1)
	if inst._arena_stage >= 0:
		inst._play_track(arena_track(inst._arena_stage, lv))      # Арена: другой трек целиком
		return
	inst._level = lv

# Трек Арены для этапа и уровня напряжения: 0 волна, 1 мини-босс, 2 босс, 3 последняя фаза
static func arena_track(s: int, level: int) -> String:
	s = clampi(s, 0, STAGE_BATTLE.size() - 1)
	match level:
		0:
			return STAGE_BATTLE[s]
		1:
			return STAGE_MINI[s]
		2:
			return STAGE_BOSS[s]
	var b: String = STAGE_BOSS[s]
	return FINAL.get(b, b)

static func current_track() -> String:
	return inst._track if inst else ""

static func current_level() -> int:
	return inst._level if inst else 0

# Боевая тема локации Арены (волны); мини-босс и босс — через intensity()
static func stage(s: int) -> void:
	if inst == null:
		return
	inst._arena_stage = clampi(s, 0, STAGE_BATTLE.size() - 1)
	inst._play_track(STAGE_BATTLE[inst._arena_stage])
	inst._level = 0

# Трек Дуэли: карты-арены звучат как их локация, остальные — одна из тем Дуэли
static func duel_track(map_id: String, round_num := 1) -> String:
	if map_id == "arena_citadel":
		return "b_throne"
	for m in Maps.DUEL_MAPS:
		if m["id"] == map_id and m.has("stage"):
			var s := int(m["stage"])
			if s >= 0 and s < STAGE_BATTLE.size():
				return STAGE_BATTLE[s]
	var h := 0
	for c in map_id.to_utf8_buffer():
		h += c
	return DUEL_TRACKS[(h + round_num - 1) % DUEL_TRACKS.size()]

static func duel(map_id: String, round_num := 1) -> void:
	music(duel_track(map_id, round_num))
	intensity(0)

func _track_stream(id: String) -> AudioStream:
	var key := "track:" + id
	if _streams.has(key):
		return _streams[key]
	var layers: Array = []
	for i in LAYERS:
		var path := MUSIC_DIR + "%s_%d.ogg" % [id, i]
		if not ResourceLoader.exists(path):
			break
		var st = load(path)
		if st is AudioStreamOggVorbis:
			st.loop = true
		layers.append(st)
	if layers.is_empty():
		_streams[key] = null
		return null
	var sync := AudioStreamSynchronized.new()
	sync.stream_count = layers.size()
	for i in layers.size():
		sync.set_sync_stream(i, layers[i])
		sync.set_sync_stream_volume(i, 0.0 if i == 0 else -80.0)
	_streams[key] = sync
	return sync

func _play_track(id: String) -> void:
	if id == _track and _music[_cur].playing:
		return
	var st := _track_stream(id)
	_track = id
	if st == null:
		_track_want = [0.0, 0.0]
		return
	var old := _cur
	_cur = 1 - _cur
	var p: AudioStreamPlayer = _music[_cur]
	p.stream = st
	_layers = [1.0, 0.0, 0.0]
	_level = 0
	for i in st.stream_count:
		st.set_sync_stream_volume(i, linear_to_db(maxf(_layers[i], 0.0001)))
	_track_vol[_cur] = 0.0
	_track_want[_cur] = 1.0
	_track_want[old] = 0.0
	p.volume_db = -80.0
	p.play()

# ---------- Вставки ----------
const STINGER_PRIO := {"wave_clear": 1, "round_won": 2, "boss_down": 2, "unlock": 2, "victory": 3, "defeat": 3}

static func stinger(id: String) -> void:
	if inst:
		inst._stinger(id)

func _stinger(id: String) -> void:
	var path := MUSIC_DIR + "sting_%s.ogg" % id
	var prio: int = STINGER_PRIO.get(id, 1)
	if _sting.playing:
		if prio > _sting_prio and prio >= 3:
			_sting.stop()                    # победа и поражение перебивают всё
		elif prio >= 2:
			_sting_queue.append(id)          # вставка подождёт своей очереди
			return
		else:
			return                           # «волна пройдена» поверх другой вставки не нужна
	if not ResourceLoader.exists(path):
		return
	if not _streams.has(path):
		var st = load(path)
		if st is AudioStreamOggVorbis:
			st.loop = false
		_streams[path] = st
	_sting.stream = _streams[path]
	_sting_prio = prio
	_sting.play()

func _next_sting() -> void:
	_sting_prio = 0
	if not _sting_queue.is_empty():
		_stinger(_sting_queue.pop_front())

# ---------- Звуки ----------
static func sfx(id: String, pos := Vector2.INF, db := 0.0, pitch_var := 0.08) -> void:
	if inst:
		inst._sfx(id, pos, db, pitch_var)

# Голос босса при его появлении (табличка с именем)
static func boss_intro(kind: String) -> void:
	if inst:
		var id: String = BOSS_INTRO.get(kind, "roar")
		inst._sfx(id if ResourceLoader.exists(SFX_DIR + id + ".wav") else "roar", Vector2.INF, float(INTRO_DB.get(id, 0.0)), 0.0)

func _sfx_stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	var st: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_streams[path] = st
	return st

func _sfx(id: String, pos: Vector2, db: float, pitch_var: float) -> void:
	if not SFX.has(id):
		return
	var rule: Array = SFX[id]
	var now := Time.get_ticks_msec()
	if now - int(_last.get(id, -100000)) < int(float(rule[1]) * 1000.0):
		return                                   # тот же звук только что был — не наслаиваем
	var n: int = rule[0]
	var path := SFX_DIR + (id + ".wav" if n <= 1 else "%s_%d.wav" % [id, randi() % n + 1])
	var st := _sfx_stream(path)
	if st == null:
		return
	# не больше rule[2] одинаковых сразу
	var same := 0
	var pool: Array = _pool2d if pos != Vector2.INF else _pool_ui
	var free_p = null
	var oldest = null
	for p in pool:
		if p.playing:
			if p.get_meta("sfx", "") == id:
				same += 1
			if oldest == null or int(p.get_meta("t", 0)) < int(oldest.get_meta("t", 0)):
				oldest = p
		elif free_p == null:
			free_p = p
	if same >= int(rule[2]):
		return
	var pl = free_p if free_p != null else oldest
	if pl == null:
		return
	_last[id] = now
	pl.stop()
	pl.stream = st
	pl.volume_db = float(rule[3]) + db
	pl.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	pl.set_meta("sfx", id)
	pl.set_meta("t", now)
	if pos != Vector2.INF:
		pl.global_position = pos
	pl.play()

# ---------- Подсказки для мест в коде ----------
# Выстрел (зовёт Player, когда оружие сработало)
static func shot(p: Node) -> void:
	if inst == null or not is_instance_valid(p):
		return
	var id := "shot_gun"
	var db := -3.0
	if p.kit != null:
		id = HERO_SHOT.get(String(p.kit.hero), "shot_gun")
	elif p.is_bot:
		db = -9.0                                # враги потише героев
		if p.gun_kind == "spear":
			id = "shot_throw"
		elif p.bullet_style == "arrow":
			id = "shot_bow"
		elif p.bullet_style in ["shuriken", "kunai"]:
			id = "shot_throw"
		elif p.bullet_style in ["spark", "ember", "soul"]:
			id = "shot_magic"
		elif p.bullet_blast > 0.0:
			id = "shot_heavy"
	elif p.bullet_blast > 0.0:
		id = "shot_heavy"
	sfx(id, p.global_position, db)

# Способности: Player передаёт откаты до обработки — если откат вырос, способность сработала
static func casts(p: Node, before: Array) -> void:
	if inst == null:
		return
	for i in mini(before.size(), p._cd.size()):
		if float(p._cd[i]) > float(before[i]) + 0.01:
			sfx("mega" if p._mega_ab() else "ability", p.global_position, 0.0 if not p.is_bot else -6.0)
			return

static func ult(p: Node) -> void:
	if p.is_bot:
		sfx("slam", p.global_position)
	else:
		sfx("ult", p.global_position)

static func hurt(p: Node, amount: int) -> void:
	if inst == null:
		return
	if not p.is_bot:
		if amount >= 6:
			sfx("hurt", p.global_position)
		else:
			sfx("hit", p.global_position, -10.0)     # яд, огонь и прочие тики — тихо, без вскрика
	elif p.stagger_max > 0.0:
		sfx("hit_big" if amount >= 20 else "hit", p.global_position, -2.0)
	else:
		sfx("hit", p.global_position, -2.0 if p.team != 0 else -8.0)

static func death(p: Node) -> void:
	if inst == null:
		return
	if not p.is_bot:
		sfx("death_hero", p.global_position)
	elif p.has_meta("kind") and Bots.TYPES.has(p.get_meta("kind")) and Bots.is_boss(p.get_meta("kind")) \
			and p.get_meta("kind") != "totem":
		sfx("death_boss", p.global_position)
	else:
		sfx("death_bot", p.global_position, 0.0 if p.team != 0 else -6.0)

static func explosion(pos: Vector2, radius: float) -> void:
	sfx("boom_big" if radius >= 110.0 else "boom_small", pos)

# Выбиты клетки: дерево, камень или кристалл — по виду постройки
static func broke(d: Node, pos: Vector2) -> void:
	if inst == null or not is_instance_valid(d):
		return
	var c: Color = d.color
	var id := "break_stone"
	if d.flammable:
		id = "break_wood"
	elif c.b > c.r + 0.15 and c.v > 0.6:
		id = "break_glass"
	sfx(id, pos)

static func picked(kind: String, mega: bool, pos: Vector2) -> void:
	if kind == "heal":
		sfx("heal", pos)
	else:
		sfx("buff_mega" if mega else "buff", pos)

# Монеты: звенят, когда золота стало больше
static func coins() -> void:
	if inst == null:
		return
	var g := Save.gold()
	if inst._gold >= 0 and g > inst._gold:
		sfx("coin")
	inst._gold = g

# Надписи на весь экран: отсчёт, «Бой!», волны, раунды, победа и поражение
static func banner(text: String) -> void:
	if inst == null:
		return
	if text in ["3", "2", "1"]:
		sfx("beep")
	elif text == "Бой!":
		sfx("go")
	elif text.begins_with("Волна") and text.ends_with("пройдена"):
		stinger("wave_clear")
	elif text.begins_with("Волна"):
		sfx("horn")
	elif text.begins_with("МГНОВЕННАЯ СМЕРТЬ"):
		sfx("siren")
		intensity(2)
	elif text.begins_with("Раунд за"):
		stinger("round_won")
	elif text.begins_with("Матч за") or text == "Победа!":
		stinger("victory")
		intensity(0)
	elif text == "Поражение":
		stinger("defeat")
		intensity(0)
	elif text.begins_with("Новая легенда"):
		stinger("unlock")

# ---------- Каждый кадр ----------
func _process(delta: float) -> void:
	_settings_t -= delta
	if _settings_t <= 0.0:
		_settings_t = 0.25
		_apply_settings()
	# вставка играет — музыка чуть тише; играет музыка приёма легенды — почти стихает
	var want_duck := STINGER_DUCK if _sting.playing else 1.0
	if _hero.playing and _hero_vol > 0.05:
		want_duck = 0.12
	_duck = move_toward(_duck, want_duck, delta * 2.5)
	if _hero.playing:
		_hero_vol = move_toward(_hero_vol, _hero_want, delta / _hero_fade)
		_hero.volume_db = linear_to_db(maxf(_hero_vol, 0.0001))
		if _hero_vol <= 0.0:
			_hero.stop()
	# фонящий микрофон: всё глухо и тише, потом звук возвращается
	_muffle_t = maxf(0.0, _muffle_t - delta)
	var mw := 1.0 if _muffle_t > 0.0 else 0.0
	var m0 := _muffle
	_muffle = move_toward(_muffle, mw, delta * (8.0 if mw > _muffle else 1.6))
	if _muffle != m0:
		for b in [_bus_music, _bus_sfx]:
			var fx := AudioServer.get_bus_effect(b, 0)
			if fx is AudioEffectLowPassFilter:
				(fx as AudioEffectLowPassFilter).cutoff_hz = lerpf(20000.0, 420.0, pow(_muffle, 0.5))
		AudioServer.set_bus_volume_db(_bus_sfx, slider_db(_vol[1]) - 10.0 * _muffle)
		AudioServer.set_bus_volume_db(_bus_music, slider_db(_vol[0]) - 10.0 * _muffle)
	# смена трека
	for i in 2:
		_track_vol[i] = move_toward(_track_vol[i], _track_want[i], delta / TRACK_FADE)
		var p: AudioStreamPlayer = _music[i]
		if _track_vol[i] <= 0.0 and _track_want[i] <= 0.0:
			if p.playing:
				p.stop()
			continue
		p.volume_db = linear_to_db(maxf(_track_vol[i] * _duck, 0.0001))
	# слои текущего трека
	var p2: AudioStreamPlayer = _music[_cur]
	if p2.stream is AudioStreamSynchronized:
		var st: AudioStreamSynchronized = p2.stream
		var want: Array = LEVELS[_level]
		for i in st.stream_count:
			var target := float(want[i]) if i < want.size() else 0.0
			var v: float = move_toward(float(_layers[i]), target, delta / LAYER_FADE)
			if v != _layers[i]:
				_layers[i] = v
				st.set_sync_stream_volume(i, linear_to_db(maxf(v, 0.0001)))
