class_name Balance
# ---------- Баланс легенд: отдельно для Дуэли и для Арены ----------
# Базовые числа легенды — в characters.gd. Здесь — поправки поверх них.
#
#   Дуэль — способности такие, как задуманы (базовые числа). Только постройки
#           ломаются чуть быстрее, чтобы карта разрушалась в бою.
#   Арена — те же способности, но в усиленном виде (больше стрел, шире взрыв,
#           дольше действует — см. наборы легенд, проверка Balance.arena(p)),
#           плюс больше здоровья и чуть сильнее урон. Перезарядки не сокращаются,
#           чтобы нельзя было победить одной кнопкой.
#
# Ключи поправок:
#   hp        — множитель здоровья
#   dmg       — множитель всего урона легенды по противникам
#   boss_dmg  — множитель урона по боссам и мини-боссам (Арена)
#   stagger   — как быстро легенда «пошатывает» босса до оглушения (Арена)
#   cds       — свои перезарядки способностей [1, 2, 3] (секунды)
#   cd_mult   — множитель всех перезарядок способностей
#   ult_mult  — множитель заряда ульты (меньше — ульта копится быстрее)
#   cell      — множитель урона по блокам и постройкам
#   blast     — множитель радиуса взрывов легенды
#   speed     — множитель скорости бега
# TESTIK_1 и UBER_TESTIK_2 (без набора способностей) не трогаются ни в одном режиме.

# Общие поправки режима — для всех легенд
const BASE := {
	"duel":  {"cell": 1.6},
	"arena": {"hp": 1.25, "dmg": 1.15},
}

const DUEL := {
	# Недопонятый гений: «Перегазрука» в Дуэли откатывается дольше (и лечит меньше — genius_kit.gd),
	# иначе против живого соперника он почти не убиваем
	"genius":     {"cds": [3.0, 5.0, 11.0]},
	# Поправки по замерам боёв на автопилоте (tests/sim_duel.gd, таблицы — в REPORT_FABLE.md):
	# Рассвет и Кузнец выигрывали почти всё, Терновник, Ассасин, Охотница и Главный — почти ничего.
	# Шаги осторожные: после них Рассвет всё ещё самый сильный, а Терновник — самый слабый.
	"rassvet":    {"dmg": 0.6},
	"smith":      {"dmg": 0.8, "hp": 0.85},
	"ternovnik":  {"dmg": 1.4, "hp": 1.15},
	"hunter":     {"dmg": 1.1, "hp": 1.2},
	"assassin":   {"dmg": 1.3},
	"glav":       {"dmg": 1.2},
}

const ARENA := {
	# Числа подобраны прогоном волн на автопилоте (tests/sim_arena.gd): «dmg» выравнивает,
	# как быстро легенда чистит обычные волны, «boss_dmg» — как быстро валит боссов.
	# Охотница бьёт по одному — ей заметно больше урона; кто косит толпы (Самурай,
	# Зарница) — меньше урона по толпе, но столько же по боссам.
	"hunter":    {"hp": 1.3, "dmg": 1.85, "boss_dmg": 0.85, "stagger": 1.4},
	"smith":     {"hp": 1.35, "dmg": 0.8, "boss_dmg": 1.2, "stagger": 0.9},
	"champion":  {"dmg": 1.55, "boss_dmg": 0.7, "stagger": 1.0},
	"ternovnik": {"dmg": 2.15, "boss_dmg": 1.6, "stagger": 1.3},
	# Мортис: скелеты и кости-обереги на Арене откатываются дольше, чем в Дуэли
	"mortis":    {"dmg": 1.35, "boss_dmg": 1.0, "stagger": 1.0, "cds": [6.5, 11.0, 5.0]},
	"soldier":   {"dmg": 1.45, "boss_dmg": 1.0, "stagger": 1.0},
	"samurai":   {"hp": 1.45, "dmg": 0.92, "boss_dmg": 1.5, "stagger": 1.1},
	"prism":     {"hp": 1.3, "dmg": 1.9, "boss_dmg": 1.25, "stagger": 1.1},
	"assassin":  {"hp": 1.35, "dmg": 1.5, "boss_dmg": 1.16, "stagger": 1.2},
	# Осока бьёт комьями по дуге — не быстро, зато держит поле лужами
	"osoka":     {"hp": 1.3, "dmg": 2.15, "boss_dmg": 1.55, "stagger": 1.2},
	# Зарница: цепные молнии бьют по всей толпе — урон по толпе ниже, по боссам — как у всех
	"zarnitsa":  {"hp": 1.4, "dmg": 0.78, "boss_dmg": 1.75, "stagger": 1.15},
	# Рассвет: широкие удары с шагом к врагу, Затмение ослепляет толпу, Чёрное солнце стягивает её —
	# по замерам самый сильный на Арене, поэтому множители ниже, чем у остальных
	"rassvet":   {"hp": 1.15, "dmg": 0.75, "boss_dmg": 0.85, "stagger": 1.0},
	"pivozavr":  {"hp": 1.4, "dmg": 1.1, "boss_dmg": 1.05, "stagger": 1.1},
	"gatekeeper": {"hp": 1.3, "dmg": 2.2, "boss_dmg": 1.15, "stagger": 1.2},
	"echo":       {"hp": 1.3, "dmg": 2.0, "boss_dmg": 1.0, "stagger": 1.15},
	"seam":       {"hp": 1.3, "dmg": 2.0, "boss_dmg": 1.0, "stagger": 1.15},
	# Главный: луч на Арене доводится на врага и пробивает сквозные платформы; по замерам
	# он теперь чуть выше среднего (боссов валит быстрее большинства)
	"glav":       {"hp": 1.5, "dmg": 2.7, "boss_dmg": 1.5, "stagger": 1.25},
	"genius":     {"hp": 1.3, "dmg": 2.0, "boss_dmg": 1.0, "stagger": 1.15},
	"scribe":     {"hp": 1.3, "dmg": 2.0, "boss_dmg": 1.15, "stagger": 1.15},
	# DJ Клима: между очередями пауза, слэм — вблизи; на Арене ноты ульты все летят во врагов
	"dj":         {"hp": 1.3, "dmg": 2.0, "boss_dmg": 1.25, "stagger": 1.15},
	"almost":     {"hp": 1.35, "dmg": 2.7, "boss_dmg": 1.3, "stagger": 1.2},
}

# Боссы Арены: сколько урона (доля здоровья) нужно, чтобы босс пошатнулся и был оглушён
const STAGGER_SHARE := 0.10
const STAGGER_STUN := 2.2          # сколько секунд оглушён
const STAGGER_COOLDOWN := 9.0      # после оглушения — столько секунд не копится

static func hero_key(p: Player) -> String:
	return String(p.kit.hero) if p.kit else ""

static func get_mods(mode: String, key: String) -> Dictionary:
	if key == "":
		return {}                      # тестовые легенды — как есть
	var t: Dictionary = ARENA if mode == "arena" else DUEL
	var m: Dictionary = (BASE.get(mode, {}) as Dictionary).duplicate()
	m.merge(t.get(key, {}), true)
	return m

static func apply(p: Player, mode: String) -> void:
	var m := get_mods(mode, hero_key(p))
	if m.has("hp"):
		p.max_hp = int(round(p.max_hp * float(m["hp"])))
		p.hp = p.max_hp
	if m.has("cds"):
		p.ability_cds = (m["cds"] as Array).duplicate()
	var cdm := float(m.get("cd_mult", 1.0))
	if cdm != 1.0:
		for i in p.ability_cds.size():
			p.ability_cds[i] = float(p.ability_cds[i]) * cdm
	if m.has("ult_mult"):
		p.ult_need *= float(m["ult_mult"])
	if m.has("speed"):
		p.speed *= float(m["speed"])
	p.set_meta("bal_mode", mode)
	p.set_meta("bal_dmg", float(m.get("dmg", 1.0)))
	p.set_meta("boss_dmg", float(m.get("boss_dmg", 1.0)))
	p.set_meta("stagger", float(m.get("stagger", 1.0)))
	p.set_meta("cd_mult", cdm)
	p.set_meta("ult_mult", float(m.get("ult_mult", 1.0)))
	p.set_meta("cell_mult", float(m.get("cell", 1.0)))
	p.set_meta("blast_mult", float(m.get("blast", 1.0)))

# Призванные союзники (скелеты, деревца, приманки) бьют с теми же поправками, что и хозяин
static func inherit(minion: Node, owner: Node) -> void:
	for k in ["bal_dmg", "cell_mult", "blast_mult"]:
		if owner.has_meta(k):
			minion.set_meta(k, owner.get_meta(k))

# Множитель урона по блокам и радиуса взрывов того, кто бьёт
static func cell_mult(attacker) -> float:
	if attacker != null and is_instance_valid(attacker) and attacker is Node:
		return float(attacker.get_meta("cell_mult", 1.0))
	return 1.0

static func blast_mult(attacker) -> float:
	if attacker != null and is_instance_valid(attacker) and attacker is Node:
		return float(attacker.get_meta("blast_mult", 1.0))
	return 1.0

# Легенда на Арене — способности работают в усиленном виде
static func arena(p: Node) -> bool:
	return p != null and is_instance_valid(p) and String(p.get_meta("bal_mode", "")) == "arena"
