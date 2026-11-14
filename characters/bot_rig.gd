class_name BotRig
extends Node2D
# «Модель» бота из отдельных частей: голова, туловище, две руки, две ноги и оружие.
# Каждая часть — маленькая пиксельная картинка, нарисованная кодом и растянутая
# без сглаживания. Части крутятся вокруг суставов (шея, плечи, бёдра) —
# так получаются анимации: ходьба, прыжок, выстрел, удар, бросок, оглушение
# и особые движения боссов (таран, замах мечом, топот, боевой клич, корни...).
#
# Анимацию запускает герой-бот: rig.play("shoot"), rig.play("throw") и т.д.
# Ходьба, прыжок, таран и оглушение включаются сами — по скорости и состоянию бота.

const SKIN := Color(0.93, 0.74, 0.58)
const GOBLIN := Color(0.45, 0.70, 0.30)
const DARK := Color(0.16, 0.14, 0.14)
const STEEL := Color(0.55, 0.57, 0.62)
const WOOD := Color(0.50, 0.33, 0.18)
const BRONZE := Color(0.80, 0.58, 0.25)
const BONE := Color(0.90, 0.88, 0.80)
# Остов Колосса (вторая фаза)
const ENDO := Color(0.36, 0.35, 0.40)
const ENDO_D := Color(0.20, 0.19, 0.23)
const ENDO_L := Color(0.62, 0.62, 0.66)
const RUST := Color(0.50, 0.29, 0.16)
const CABLE := Color(0.58, 0.13, 0.10)
const CAVITY := Color(0.07, 0.05, 0.06)
const TEETH := Color(0.84, 0.80, 0.68)

# Оружие, которое держат как ружьё — рука направлена вперёд
const AIMED := ["rifle", "pistol", "bazooka", "cannon", "blunderbuss", "blowpipe", "bow", "longbow", "assault", "soda_bottle"]
const TWO_HANDED := ["rifle", "bazooka", "blunderbuss", "assault"]
# Копьё и посох держат стоймя, как бы ни двигалась рука
const UPRIGHT := ["headsman_axe", "spear", "staff", "javelin", "trident", "necro_staff", "branch", "scythe", "hammer", "katana", "kama", "axe", "witch_staff", "lantern_staff",
		"storm_staff", "glaive", "thunder_staff", "storm_orb", "fire_staff", "warlock_staff", "war_fan", "beer_bottle", "key_staff", "echo_lantern", "quill"]
# Движения Кузнеца, во время которых молот продолжает руку (бьёт, а не стоит торчком)
const HAMMER_ACTS := ["hammer1", "hammer2", "hammer3", "slam", "big_swing", "forge", "finisher", "throw"]
# Удары Самурая: катана продолжает руку
# Серия ударов Самурая (МЕГА «Широкий взмах»): ~0,12 с опускается на колено,
# потом удар каждые 0,1 с — рука идёт от одного угла к другому, крест-накрест
const FLURRY_SET := 0.12
const FLURRY_STEP := 0.1
const FLURRY_CUTS := [Vector2(-2.5, -0.45), Vector2(-0.45, -2.3), Vector2(-2.2, -0.7), Vector2(-0.8, -2.6),
		Vector2(-2.0, -0.35), Vector2(-0.35, -2.1), Vector2(-2.6, -0.8), Vector2(-0.6, -2.4), Vector2(-2.3, -0.5)]
const SWORD_ACTS := ["cut1", "cut2", "cut3", "cut4", "cut5", "flurry", "big_cut", "wave_cut", "cut_down", "dash_up"]

# Пропорции в «пикселях рисунка»: [ширина, высота]
const SPECS := {
	"grunt":   {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": SKIN, "shirt": Color(0.80, 0.30, 0.28), "pants": Color(0.30, 0.28, 0.32), "hat": "hair", "weapon": "rifle"},
	"runner":  {"head": [8, 7], "torso": [8, 7], "arm": [3, 7], "leg": [4, 7],
			"skin": SKIN, "shirt": Color(0.80, 0.86, 0.28), "pants": Color(0.25, 0.25, 0.3), "hat": "band", "weapon": "pistol"},
	"soldier": {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": SKIN, "shirt": Color(0.42, 0.58, 0.34), "pants": Color(0.32, 0.40, 0.26), "hat": "helmet", "weapon": "rifle"},
	"tank":    {"head": [11, 9], "torso": [18, 12], "arm": [6, 12], "leg": [7, 11],
			"skin": SKIN, "shirt": Color(0.48, 0.50, 0.60), "pants": Color(0.34, 0.35, 0.42), "hat": "steel", "weapon": "cannon", "armor": true},
	"gunner":  {"head": [10, 9], "torso": [12, 10], "arm": [4, 10], "leg": [5, 10],
			"skin": SKIN, "shirt": Color(0.62, 0.40, 0.72), "pants": Color(0.30, 0.25, 0.35), "hat": "cap", "weapon": "pistol", "back": "mortar"},
	"breacher":{"head": [11, 10], "torso": [14, 12], "arm": [5, 12], "leg": [6, 12],
			"skin": SKIN, "shirt": Color(0.30, 0.52, 0.74), "pants": Color(0.22, 0.30, 0.42), "hat": "visor", "weapon": "bazooka"},
	"goblin":  {"head": [10, 9], "torso": [9, 8], "arm": [3, 8], "leg": [4, 8],
			"skin": GOBLIN, "shirt": Color(0.55, 0.40, 0.25), "pants": Color(0.42, 0.30, 0.20), "hat": "ears", "weapon": "spear"},
	"sneak":   {"head": [9, 8], "torso": [8, 7], "arm": [3, 7], "leg": [4, 8],
			"skin": Color(0.36, 0.56, 0.36), "shirt": Color(0.22, 0.30, 0.26), "pants": Color(0.18, 0.22, 0.2), "hat": "hood", "weapon": "blowpipe", "item": "smoke"},
	"bomber":  {"head": [10, 9], "torso": [10, 8], "arm": [3, 8], "leg": [4, 8],
			"skin": Color(0.58, 0.66, 0.26), "shirt": Color(0.45, 0.32, 0.20), "pants": Color(0.35, 0.28, 0.2), "hat": "goggles", "weapon": "bomb", "back": "bombs"},
	"shaman":  {"head": [10, 10], "torso": [10, 10], "arm": [3, 10], "leg": [4, 9],
			"skin": Color(0.40, 0.62, 0.52), "shirt": Color(0.35, 0.50, 0.45), "pants": Color(0.28, 0.36, 0.32), "hat": "mask", "weapon": "staff", "robe": true},
	"brute":   {"head": [11, 10], "torso": [18, 13], "arm": [6, 13], "leg": [7, 11],
			"skin": Color(0.38, 0.54, 0.26), "shirt": Color(0.40, 0.28, 0.16), "pants": Color(0.32, 0.24, 0.15), "hat": "ears_bald", "weapon": "blunderbuss"},
	# ----- мини-боссы и боссы: проработанные части -----
	"gladiator": {"head": [11, 11], "torso": [14, 14], "arm": [5, 13], "leg": [6, 14], "style": "gladiator",
			"skin": SKIN, "shirt": Color(0.55, 0.32, 0.18), "pants": Color(0.55, 0.32, 0.18), "hat": "", "weapon": "sword"},
	"colossus":  {"head": [14, 13], "torso": [22, 18], "arm": [8, 18], "leg": [9, 16], "style": "colossus",
			"skin": Color(0.30, 0.24, 0.36), "shirt": Color(0.26, 0.20, 0.32), "pants": Color(0.22, 0.18, 0.27), "hat": "", "weapon": "none",
			"cape": Color(0.36, 0.08, 0.08), "cape_trim": Color(0.20, 0.16, 0.22), "eye_glow": Color(1.0, 0.32, 0.2), "one_eye": true},
	# Колосс Пробуждённый: броня разлетелась — железный остов, в груди за рёбрами ядро
	"colossus_endo": {"head": [13, 13], "torso": [18, 18], "arm": [6, 18], "leg": [7, 16], "style": "colossus_endo",
			"skin": Color(0.36, 0.35, 0.40), "shirt": Color(0.36, 0.35, 0.40), "pants": Color(0.36, 0.35, 0.40), "hat": "", "weapon": "none"},
	"chief":     {"head": [13, 12], "torso": [14, 12], "arm": [5, 12], "leg": [6, 12], "style": "chief",
			"skin": Color(0.50, 0.66, 0.28), "shirt": Color(0.55, 0.38, 0.20), "pants": Color(0.45, 0.30, 0.18), "hat": "", "weapon": "spear"},
	"treant":    {"head": [18, 14], "torso": [22, 22], "arm": [6, 26], "leg": [10, 14], "style": "treant",
			"skin": Color(0.42, 0.30, 0.18), "shirt": Color(0.42, 0.30, 0.18), "pants": Color(0.36, 0.25, 0.15), "hat": "", "weapon": "none"},
	# ----- Драгоценные пещеры: кобольды и голем -----
	"kobold_miner":  {"head": [9, 8], "torso": [9, 8], "arm": [3, 8], "leg": [4, 7],
			"skin": Color(0.66, 0.40, 0.24), "shirt": Color(0.42, 0.30, 0.20), "pants": Color(0.30, 0.25, 0.22),
			"hat": "kobold", "weapon": "pickaxe", "armor_plate": Color(0.36, 0.26, 0.18)},
	"kobold_bomber": {"head": [9, 8], "torso": [9, 8], "arm": [3, 8], "leg": [4, 7],
			"skin": Color(0.70, 0.46, 0.26), "shirt": Color(0.55, 0.22, 0.18), "pants": Color(0.28, 0.24, 0.22),
			"hat": "kobold_goggles", "weapon": "dynamite", "back": "bombs"},
	"gem_shaman":    {"head": [9, 8], "torso": [9, 9], "arm": [3, 9], "leg": [4, 7],
			"skin": Color(0.62, 0.42, 0.30), "shirt": Color(0.26, 0.42, 0.36), "pants": Color(0.22, 0.30, 0.28),
			"hat": "kobold_hood", "weapon": "gem_staff", "robe": true},
	"cart_rider":    {"head": [9, 8], "torso": [9, 8], "arm": [3, 8], "leg": [4, 7],
			"skin": Color(0.62, 0.38, 0.22), "shirt": Color(0.40, 0.32, 0.26), "pants": Color(0.30, 0.25, 0.22),
			"hat": "kobold", "weapon": "pickaxe", "cart": true},
	"ruby_golem":    {"head": [10, 8], "torso": [18, 14], "arm": [6, 14], "leg": [7, 10], "style": "golem",
			"skin": Color(0.42, 0.36, 0.38), "shirt": Color(0.42, 0.36, 0.38), "pants": Color(0.38, 0.32, 0.34),
			"hat": "", "weapon": "none", "gem": Color(0.92, 0.16, 0.26), "eye_glow": Color(1.0, 0.35, 0.3)},
	# ----- Кристальные пещеры -----
	"crystal_guard": {"head": [10, 9], "torso": [14, 12], "arm": [5, 12], "leg": [6, 12], "style": "crystal",
			"skin": Color(0.62, 0.82, 1.0), "shirt": Color(0.50, 0.70, 0.98), "pants": Color(0.42, 0.60, 0.92),
			"hat": "crystal_helm", "weapon": "crystal_sword", "shield": "mirror", "armor_plate": Color(0.75, 0.88, 1.0),
			"eye_glow": Color(0.7, 0.95, 1.0)},
	"irida":         {"head": [12, 11], "torso": [16, 18], "arm": [5, 18], "leg": [7, 18], "style": "crystal",
			"skin": Color(0.80, 0.86, 1.0), "shirt": Color(0.66, 0.62, 1.0), "pants": Color(0.58, 0.55, 0.95),
			"hat": "crystal_crown", "weapon": "prism_staff", "robe": Color(0.55, 0.70, 1.0),
			"crown": Color(0.85, 0.95, 1.0), "eye_glow": Color(0.95, 0.85, 1.0), "cape": Color(0.55, 0.62, 0.98),
			"cape_trim": Color(0.9, 0.95, 1.0)},
	# ----- Легенда за Ириду -----
	"prism":         {"head": [9, 9], "torso": [10, 11], "arm": [3, 11], "leg": [4, 12],
			"skin": Color(0.96, 0.88, 0.84), "shirt": Color(0.88, 0.86, 0.96), "pants": Color(0.62, 0.55, 0.85),
			"hat": "prism_circlet", "weapon": "prism_staff", "robe": true,
			"cape": Color(0.55, 0.45, 0.85), "cape_trim": Color(0.85, 0.92, 1.0), "armor_plate": Color(0.72, 0.62, 0.95)},
	# ----- Легенда за Трясинного Владыку -----
	"osoka":         {"head": [9, 9], "torso": [10, 11], "arm": [3, 11], "leg": [4, 12],
			"skin": Color(0.76, 0.84, 0.70), "shirt": Color(0.47, 0.42, 0.25), "pants": Color(0.76, 0.84, 0.70),
			"boots": Color(0.30, 0.26, 0.17), "hat": "tina_hair", "weapon": "lantern_staff", "robe": true, "frog": true,
			"cape": Color(0.14, 0.32, 0.22), "cape_trim": Color(0.36, 0.56, 0.30), "armor_plate": Color(0.30, 0.46, 0.24)},
	# ----- Легенда за Громовника -----
	"zarnitsa":      {"head": [9, 9], "torso": [10, 11], "arm": [3, 11], "leg": [4, 12], "style": "storm_monk",
			"skin": Color(0.95, 0.80, 0.66), "shirt": Color(0.24, 0.32, 0.60), "pants": Color(0.30, 0.33, 0.46), "hakama": true,
			"hat": "zarnitsa_hair", "weapon": "war_fan", "trim": Color(0.95, 0.78, 0.32),
			"cape": Color(0.46, 0.62, 0.94), "cape_trim": Color(0.95, 0.78, 0.32)},
	# ----- Легенда за Тёмного Лорда -----
	"rassvet":       {"head": [10, 10], "torso": [12, 12], "arm": [4, 12], "leg": [5, 12], "style": "dark_plate",
			"skin": Color(0.88, 0.70, 0.56), "shirt": Color(0.12, 0.10, 0.15), "pants": Color(0.10, 0.09, 0.13),
			"hat": "rassvet_helm", "weapon": "dawn_blade", "vein": Color(1.0, 0.72, 0.28), "gem": Color(1.0, 0.80, 0.38),
			# Рыцарь затмения: корона из шипов вместо рогов, за головой — нимб-затмение (чёрный диск в золотом
			# кольце), рваный тёмный плащ с тлеющим краем, лиловые наплечники
			"crown_spikes": true, "halo": Color(1.0, 0.74, 0.30), "pauldron": Color(0.32, 0.23, 0.40),
			"cape": Color(0.19, 0.10, 0.27), "cape_trim": Color(0.32, 0.23, 0.40), "cape_torn": true, "cape_tear": 0.45, "cape_hem": Color(0.96, 0.46, 0.14)},
	# ----- Легенда за Предвестника -----
	"echo":          {"head": [9, 9], "torso": [10, 11], "arm": [3, 11], "leg": [4, 12],
			"skin": Color(0.80, 0.78, 0.86), "shirt": Color(0.26, 0.24, 0.32), "pants": Color(0.18, 0.17, 0.24),
			"hat": "echo_hood", "weapon": "echo_lantern", "robe": true,
			"cape": Color(0.36, 0.34, 0.44), "cape_trim": Color(0.72, 0.48, 1.0), "armor_plate": Color(0.55, 0.50, 0.66)},
	# ----- Легенда за Странника, поглощённого бездной -----
	"seam":          {"head": [9, 9], "torso": [10, 11], "arm": [3, 11], "leg": [4, 12],
			"skin": Color(0.92, 0.84, 0.80), "shirt": Color(0.30, 0.20, 0.36), "pants": Color(0.20, 0.16, 0.22),
			"hat": "seam_hood", "weapon": "needle_spear", "vein": Color(1.0, 0.82, 0.35),
			"cape": Color(0.42, 0.28, 0.46), "cape_trim": Color(1.0, 0.82, 0.35), "armor_plate": Color(0.62, 0.52, 0.40)},
	# ----- Легенда из Лавки: Недопонятый гений (персонаж друга автора) -----
	"genius":        {"head": [22, 29], "torso": [14, 12], "arm": [4, 12], "leg": [5, 11], "photo": true, "photo_face": "genius",
			"photo_frame": "headset", "skin": Color(0.92, 0.76, 0.66), "shirt": Color(0.24, 0.10, 0.28), "pants": Color(0.20, 0.08, 0.22),
			"hakama": true, "tabi": Color(0.10, 0.08, 0.12), "gi": true, "gi_trim": Color(0.55, 0.08, 0.14), "sode": Color(0.45, 0.07, 0.12),
			"cable": Color(0.25, 0.55, 0.95), "hat": "", "weapon": "usb_stick", "back": "genius_katana",
			"cape": Color(0.40, 0.06, 0.10), "cape_trim": Color(0.62, 0.28, 0.82), "cape_torn": true},
	# ----- Легенда из Лавки: Летописец (придумал Claude) -----
	"scribe":        {"head": [9, 9], "torso": [10, 11], "arm": [3, 11], "leg": [4, 12],
			"skin": Color(0.95, 0.82, 0.70), "shirt": Color(0.16, 0.20, 0.40), "pants": Color(0.13, 0.15, 0.30),
			"hat": "scribe_cap", "weapon": "quill", "back": "tome", "robe": true,
			"scarf": Color(0.95, 0.91, 0.78), "scarf_ink": Color(0.16, 0.24, 0.55), "trim": Color(1.0, 0.82, 0.38),
			"cape": Color(0.22, 0.26, 0.48), "cape_trim": Color(1.0, 0.82, 0.38), "armor_plate": Color(0.55, 0.45, 0.30)},
	# ----- Легенда из Лавки: Почти легенда (персонаж друга автора) -----
	# Свой облик: белый боевой костюм с оранжевыми полосами, круглый шлем с голубым визором,
	# силовые перчатки и серебряная медаль «2» на груди — почти легенда
	"almost":        {"head": [10, 10], "torso": [12, 12], "arm": [4, 11], "leg": [5, 12],
			"skin": Color(0.90, 0.72, 0.60), "shirt": Color(0.92, 0.93, 0.96), "pants": Color(0.20, 0.22, 0.28),
			"hat": "moto_helm", "weapon": "gauntlet", "suit": true, "back": "thruster",
			"suit_pal": [Color(0.92, 0.93, 0.96), Color(1.0, 0.52, 0.14), Color(0.20, 0.22, 0.28), Color(0.30, 0.90, 1.0), Color(0.80, 0.82, 0.88)],
			"helm_pal": [Color(0.94, 0.95, 0.98), Color(1.0, 0.52, 0.14), Color(0.30, 0.90, 1.0), Color(0.18, 0.20, 0.26)],
			"gpal": [Color(1.0, 0.52, 0.14), Color(0.94, 0.95, 0.98), Color(0.30, 0.90, 1.0), Color(0.18, 0.20, 0.26)]},
	# ----- Легенда из Лавки: DJ Клима (персонаж друга автора) -----
	"dj":            {"head": [22, 29], "torso": [14, 12], "arm": [4, 12], "leg": [5, 11], "photo": true, "photo_face": "dj",
			"photo_frame": "dj", "skin": Color(0.92, 0.76, 0.68), "shirt": Color(0.08, 0.08, 0.10), "pants": Color(0.24, 0.40, 0.68),
			"hoodie": true, "note": Color(0.96, 0.96, 1.0), "note_glow": Color(0.30, 0.90, 1.0), "chain": Color(1.0, 0.84, 0.40),
			"sneaker": Color(0.97, 0.97, 0.98), "sole": Color(1.0, 0.36, 0.80), "hat": "", "weapon": "vinyl", "back": "boombox"},
	# ----- Легенда из Лавки: Главный (персонаж друга автора) -----
	"glav":          {"head": [22, 29], "torso": [14, 12], "arm": [4, 12], "leg": [5, 11], "photo": true, "photo_face": "glav",
			"skin": Color(0.93, 0.78, 0.70), "shirt": Color(0.96, 0.96, 0.95), "pants": Color(0.17, 0.20, 0.30),
			"coat": Color(0.07, 0.06, 0.09), "coat_glow": Color(0.72, 0.42, 1.0), "hat": "", "weapon": "soda_bottle",
			"cape": Color(0.07, 0.06, 0.09), "cape_trim": Color(0.72, 0.42, 1.0)},
	"gatekeeper":    {"head": [9, 9], "torso": [10, 11], "arm": [3, 11], "leg": [4, 12],
			"skin": Color(0.94, 0.84, 0.78), "shirt": Color(0.20, 0.19, 0.44), "pants": Color(0.15, 0.14, 0.32),
			"hat": "gate_hood", "weapon": "key_staff", "robe": true,
			"cape": Color(0.24, 0.21, 0.52), "cape_trim": Color(1.0, 0.82, 0.38), "armor_plate": Color(0.86, 0.70, 0.36)},
	# ----- Пивозавр (Лавка) -----
	"pivozavr":      {"head": [22, 29], "torso": [18, 12], "arm": [5, 11], "leg": [6, 9], "photo": true,
			"skin": Color(0.90, 0.68, 0.55), "shirt": Color(0.50, 0.47, 0.30), "pants": Color(0.42, 0.40, 0.26),
			"camo": true, "armor_plate": Color(0.38, 0.40, 0.25), "hat": "", "weapon": "beer_bottle",
			"tail": Color(0.40, 0.62, 0.30)},
	# ----- История -----
	"bandit":    {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": Color(0.86, 0.66, 0.50), "shirt": Color(0.42, 0.22, 0.18), "pants": Color(0.28, 0.24, 0.22), "hat": "band",
			"weapon": "sword", "armor_plate": Color(0.35, 0.25, 0.16)},
	"dummy":     {"head": [10, 9], "torso": [12, 11], "arm": [4, 10], "leg": [4, 11],
			"skin": Color(0.86, 0.74, 0.42), "shirt": Color(0.62, 0.50, 0.32), "pants": Color(0.50, 0.36, 0.20), "hat": "band_brown",
			"weapon": "none"},
	# ----- Колизей: бойцы арены -----
	"fighter":   {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": SKIN, "shirt": Color(0.58, 0.40, 0.22), "pants": Color(0.62, 0.22, 0.18), "hat": "bronze_helm",
			"weapon": "sword", "shield": "buckler", "armor_plate": Color(0.55, 0.38, 0.2), "bare_legs": true},
	"thrower":   {"head": [10, 9], "torso": [11, 10], "arm": [4, 10], "leg": [5, 11],
			"skin": SKIN, "shirt": Color(0.86, 0.80, 0.64), "pants": Color(0.86, 0.80, 0.64), "hat": "hair",
			"weapon": "javelin", "bare_arms": true, "bare_legs": true},
	"slinger":   {"head": [9, 8], "torso": [10, 9], "arm": [3, 9], "leg": [4, 10],
			"skin": Color(0.80, 0.60, 0.45), "shirt": Color(0.55, 0.48, 0.30), "pants": Color(0.55, 0.48, 0.30), "hat": "band_brown",
			"weapon": "sling", "bare_arms": true, "bare_legs": true},
	"retiarius": {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": Color(0.85, 0.66, 0.50), "shirt": Color(0.85, 0.66, 0.50), "pants": Color(0.80, 0.70, 0.40), "hat": "hair",
			"weapon": "trident", "item": "net", "bare_arms": true, "bare_legs": true, "bare_chest": true},
	"murmillo":  {"head": [12, 10], "torso": [16, 13], "arm": [6, 12], "leg": [6, 12],
			"skin": SKIN, "shirt": SKIN, "pants": Color(0.75, 0.62, 0.35), "hat": "murmillo_helm",
			"weapon": "sword", "shield": "scutum", "bare_chest": true, "bare_legs": true},
	"beastmaster": {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": Color(0.82, 0.62, 0.46), "shirt": Color(0.55, 0.30, 0.22), "pants": Color(0.50, 0.30, 0.20), "hat": "lion_pelt",
			"weapon": "whip", "bare_arms": true, "bare_legs": true, "armor_plate": Color(0.45, 0.28, 0.16)},
	"sagittarius": {"head": [10, 9], "torso": [11, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": SKIN, "shirt": Color(0.36, 0.42, 0.30), "pants": Color(0.40, 0.30, 0.20), "hat": "bronze_helm",
			"weapon": "bow", "back": "quiver", "armor_plate": Color(0.42, 0.30, 0.18), "bare_legs": true},
	# ----- Лесная тропа: приспешники Тёмного лорда -----
	"minion":        {"head": [10, 9], "torso": [11, 11], "arm": [3, 11], "leg": [4, 11],
			"skin": Color(0.55, 0.58, 0.50), "shirt": Color(0.24, 0.22, 0.28), "pants": Color(0.20, 0.18, 0.22),
			"hat": "minion_hood", "weapon": "dagger", "robe": true},
	"imp":           {"head": [9, 8], "torso": [8, 7], "arm": [3, 7], "leg": [3, 7],
			"skin": Color(0.66, 0.26, 0.32), "shirt": Color(0.66, 0.26, 0.32), "pants": Color(0.32, 0.12, 0.16),
			"hat": "imp_horns", "weapon": "none", "bare_chest": true, "bare_legs": true},
	"minion_archer": {"head": [10, 9], "torso": [11, 11], "arm": [3, 11], "leg": [4, 11],
			"skin": Color(0.55, 0.58, 0.50), "shirt": Color(0.22, 0.28, 0.22), "pants": Color(0.18, 0.20, 0.18),
			"hat": "minion_hood", "weapon": "bow", "back": "quiver"},
	"minion_shield": {"head": [10, 9], "torso": [13, 12], "arm": [4, 12], "leg": [5, 11],
			"skin": Color(0.55, 0.58, 0.50), "shirt": Color(0.28, 0.26, 0.30), "pants": Color(0.20, 0.18, 0.22),
			"hat": "minion_hood", "weapon": "club", "shield": "door", "armor_plate": Color(0.36, 0.30, 0.26)},
	"sergeant":      {"head": [12, 11], "torso": [15, 13], "arm": [5, 13], "leg": [6, 12],
			"skin": Color(0.55, 0.58, 0.50), "shirt": Color(0.32, 0.26, 0.24), "pants": Color(0.22, 0.20, 0.22),
			"hat": "sergeant_helm", "weapon": "mace", "armor_plate": Color(0.42, 0.38, 0.36),
			"cape": Color(0.40, 0.12, 0.12), "cape_trim": Color(0.25, 0.08, 0.08), "boots": Color(0.25, 0.20, 0.16)},
	# ----- Окраина деревни: бандиты -----
	"bandit_thug":     {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": Color(0.88, 0.68, 0.52), "shirt": Color(0.62, 0.54, 0.42), "pants": Color(0.30, 0.26, 0.22),
			"hat": "bandit_mask", "mask": Color(0.62, 0.18, 0.15), "weapon": "club",
			"armor_plate": Color(0.45, 0.30, 0.20), "boots": Color(0.32, 0.22, 0.14)},
	"bandit_shuriken": {"head": [10, 9], "torso": [11, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": Color(0.88, 0.70, 0.55), "shirt": Color(0.20, 0.20, 0.26), "pants": Color(0.16, 0.16, 0.20),
			"hat": "ninja_hood", "mask": Color(0.20, 0.20, 0.26), "weapon": "shuriken", "boots": Color(0.12, 0.12, 0.14)},
	"bandit_kunai":    {"head": [10, 9], "torso": [11, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": Color(0.86, 0.66, 0.50), "shirt": Color(0.16, 0.14, 0.16), "pants": Color(0.14, 0.12, 0.14),
			"hat": "ninja_hood", "mask": Color(0.55, 0.12, 0.12), "weapon": "kunai", "item": "smoke",
			"armor_plate": Color(0.24, 0.20, 0.22), "boots": Color(0.10, 0.10, 0.12)},
	"bandit_torch":    {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": Color(0.86, 0.64, 0.48), "shirt": Color(0.58, 0.32, 0.18), "pants": Color(0.32, 0.24, 0.18),
			"hat": "bandit_mask", "mask": Color(0.28, 0.24, 0.22), "weapon": "firebottle", "back": "bombs",
			"boots": Color(0.30, 0.20, 0.12)},
	"bandit_bola":     {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": Color(0.84, 0.64, 0.48), "shirt": Color(0.45, 0.40, 0.24), "pants": Color(0.34, 0.28, 0.20),
			"hat": "band_brown", "weapon": "dagger", "item": "bola", "armor_plate": Color(0.40, 0.30, 0.18),
			"boots": Color(0.30, 0.22, 0.14)},
	"bandit_brute":    {"head": [11, 10], "torso": [18, 13], "arm": [6, 13], "leg": [7, 11],
			"skin": Color(0.86, 0.64, 0.48), "shirt": Color(0.42, 0.28, 0.20), "pants": Color(0.30, 0.24, 0.20),
			"hat": "bald_beard", "weapon": "none", "bare_arms": true, "armor_plate": Color(0.42, 0.28, 0.20),
			"boots": Color(0.28, 0.20, 0.14)},
	"ataman":          {"head": [13, 12], "torso": [18, 16], "arm": [6, 16], "leg": [7, 15],
			"skin": Color(0.84, 0.62, 0.46), "shirt": Color(0.20, 0.15, 0.14), "pants": Color(0.20, 0.17, 0.16),
			"hat": "ataman", "weapon": "axe", "armor_plate": Color(0.30, 0.22, 0.18),
			"cape": Color(0.28, 0.20, 0.15), "cape_trim": Color(0.58, 0.50, 0.42), "boots": Color(0.18, 0.13, 0.10),
			"knee": Color(0.45, 0.45, 0.50)},
	# ----- Легенда за Атамана -----
	"assassin":        {"head": [9, 9], "torso": [10, 11], "arm": [3, 11], "leg": [5, 12], "style": "ninja",
			"skin": Color(0.92, 0.76, 0.62), "shirt": Color(0.15, 0.28, 0.24), "pants": Color(0.12, 0.16, 0.16),
			"hat": "ninja_tail", "weapon": "kama", "item": "kunai", "wrap": Color(0.45, 0.56, 0.32),
			"rope": Color(0.46, 0.30, 0.18), "tattoo": Color(0.84, 0.80, 0.92)},
	# ----- Жуткий лес -----
	"ghoul":     {"head": [9, 9], "torso": [10, 10], "arm": [3, 13], "leg": [4, 10],
			"skin": Color(0.55, 0.58, 0.55), "shirt": Color(0.55, 0.58, 0.55), "pants": Color(0.25, 0.22, 0.24),
			"hat": "ghoul", "weapon": "claws", "bare_chest": true, "bare_legs": false},
	"scarecrow": {"head": [10, 10], "torso": [12, 12], "arm": [3, 12], "leg": [3, 12],
			"skin": Color(0.78, 0.66, 0.44), "shirt": Color(0.42, 0.34, 0.50), "pants": Color(0.40, 0.32, 0.20),
			"hat": "scarecrow", "weapon": "sickle", "armor_plate": Color(0.55, 0.30, 0.28)},
	"deadwood":  {"head": [14, 11], "torso": [16, 16], "arm": [5, 18], "leg": [8, 11], "style": "treant", "dead": true,
			"skin": Color(0.30, 0.26, 0.24), "shirt": Color(0.30, 0.26, 0.24), "pants": Color(0.26, 0.22, 0.20), "hat": "",
			"weapon": "none", "leaf": Color(0.20, 0.18, 0.17), "eye_col": Color(0.9, 0.35, 1.0)},
	"witch":     {"head": [9, 9], "torso": [10, 12], "arm": [3, 12], "leg": [4, 12],
			"skin": Color(0.62, 0.72, 0.55), "shirt": Color(0.20, 0.13, 0.24), "pants": Color(0.16, 0.10, 0.18),
			"hat": "witch", "weapon": "witch_staff", "robe": true, "cape": Color(0.26, 0.12, 0.30),
			"cape_trim": Color(0.45, 0.30, 0.10), "eye_glow": Color(0.8, 1.0, 0.3)},
	# ----- Болото -----
	"bogman":    {"head": [11, 10], "torso": [14, 13], "arm": [5, 13], "leg": [6, 11],
			"skin": Color(0.30, 0.32, 0.20), "shirt": Color(0.30, 0.32, 0.20), "pants": Color(0.26, 0.28, 0.17),
			"hat": "bogman", "weapon": "none", "bare_chest": true},
	"frogman":   {"head": [12, 8], "torso": [12, 10], "arm": [3, 10], "leg": [5, 9],
			"skin": Color(0.38, 0.58, 0.30), "shirt": Color(0.38, 0.58, 0.30), "pants": Color(0.30, 0.48, 0.24),
			"hat": "frog", "weapon": "trident", "bare_chest": true, "bare_legs": true, "armor_plate": Color(0.45, 0.35, 0.20)},
	"drowned":   {"head": [10, 9], "torso": [13, 12], "arm": [4, 12], "leg": [5, 12],
			"skin": Color(0.52, 0.62, 0.62), "shirt": Color(0.28, 0.32, 0.38), "pants": Color(0.22, 0.24, 0.28),
			"hat": "drowned", "weapon": "anchor", "boots": Color(0.20, 0.22, 0.20)},
	"bog_lord":  {"head": [18, 14], "torso": [24, 22], "arm": [7, 26], "leg": [11, 14], "style": "treant", "dead": true,
			"skin": Color(0.26, 0.30, 0.20), "shirt": Color(0.26, 0.30, 0.20), "pants": Color(0.22, 0.26, 0.17), "hat": "",
			"weapon": "none", "leaf": Color(0.40, 0.52, 0.26), "eye_col": Color(1.0, 0.85, 0.3)},
	# ----- Пещеры: скелеты -----
	"skeleton":     {"head": [10, 9], "torso": [10, 11], "arm": [3, 11], "leg": [4, 11], "style": "skeleton",
			"skin": BONE, "shirt": BONE, "pants": BONE, "hat": "", "weapon": "none"},
	"skel_sword":   {"head": [10, 9], "torso": [11, 11], "arm": [3, 11], "leg": [4, 11], "style": "skeleton",
			"skin": BONE, "shirt": BONE, "pants": BONE, "hat": "rusty_helm", "weapon": "sword",
			"armor_plate": Color(0.48, 0.42, 0.36), "shield": "rusty"},
	"skel_thrower": {"head": [10, 9], "torso": [11, 11], "arm": [3, 11], "leg": [4, 11], "style": "skeleton",
			"skin": BONE, "shirt": BONE, "pants": BONE, "hat": "", "weapon": "bone", "jacket": Color(0.45, 0.30, 0.18)},
	"necromancer":  {"head": [10, 10], "torso": [11, 13], "arm": [3, 12], "leg": [5, 11], "style": "skeleton",
			"skin": BONE, "shirt": BONE, "pants": BONE, "hat": "hood_dark", "weapon": "necro_staff",
			"robe": Color(0.18, 0.12, 0.24), "eye_glow": Color(0.75, 0.35, 1.0)},
	# ----- Новые легенды и их призванные союзники -----
	"champion":     {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": SKIN, "shirt": Color(0.78, 0.58, 0.28), "pants": Color(0.70, 0.18, 0.15), "hat": "bronze_helm",
			"weapon": "spear", "shield": "round", "armor_plate": Color(0.80, 0.60, 0.28), "bare_legs": true,
			"cape": Color(0.72, 0.14, 0.12)},
	"ternovnik":    {"head": [10, 9], "torso": [11, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": Color(0.58, 0.44, 0.28), "shirt": Color(0.30, 0.55, 0.24), "pants": Color(0.36, 0.27, 0.16),
			"hat": "leaves", "weapon": "branch"},
	"mortis":       {"head": [10, 10], "torso": [11, 12], "arm": [3, 12], "leg": [5, 11], "style": "skeleton",
			"skin": BONE, "shirt": BONE, "pants": BONE, "hat": "hood_dark", "weapon": "scythe",
			"robe": Color(0.22, 0.15, 0.30), "eye_glow": Color(0.75, 0.4, 1.0)},
	"mini_ent":     {"head": [16, 12], "torso": [18, 16], "arm": [5, 18], "leg": [8, 10], "style": "treant",
			"skin": Color(0.48, 0.34, 0.20), "shirt": Color(0.48, 0.34, 0.20), "pants": Color(0.40, 0.28, 0.16), "hat": "", "weapon": "none"},
	"sapling":      {"head": [10, 8], "torso": [10, 9], "arm": [3, 9], "leg": [5, 6], "style": "treant",
			"skin": Color(0.55, 0.40, 0.22), "shirt": Color(0.55, 0.40, 0.22), "pants": Color(0.45, 0.32, 0.18), "hat": "", "weapon": "none"},
	"skel_archer":  {"head": [10, 9], "torso": [11, 11], "arm": [3, 11], "leg": [4, 11], "style": "skeleton",
			"skin": BONE, "shirt": BONE, "pants": BONE, "hat": "rusty_helm", "weapon": "bow",
			"jacket": Color(0.35, 0.25, 0.4)},
	# ----- Стартовые легенды -----
	"hunter":       {"head": [9, 9], "torso": [10, 11], "arm": [3, 11], "leg": [4, 12],
			"skin": SKIN, "shirt": Color(0.30, 0.50, 0.27), "pants": Color(0.38, 0.29, 0.19), "hat": "hunter_hood",
			"weapon": "longbow", "back": "quiver", "cape": Color(0.20, 0.36, 0.19), "cape_trim": Color(0.55, 0.40, 0.22),
			"armor_plate": Color(0.45, 0.32, 0.20)},
	"smith":        {"head": [11, 10], "torso": [15, 12], "arm": [5, 12], "leg": [6, 10],
			"skin": Color(0.86, 0.64, 0.48), "shirt": Color(0.34, 0.30, 0.30), "pants": Color(0.30, 0.26, 0.24), "hat": "smith",
			"weapon": "hammer", "bare_arms": true, "apron": Color(0.48, 0.32, 0.18),
			"eye_glow": Color(1.0, 0.6, 0.15), "eyes_off": true, "one_eye": true},
	# ----- Легенды из Лавки -----
	"soldier_hero": {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 12],
			"skin": SKIN, "shirt": Color(0.38, 0.44, 0.28), "pants": Color(0.33, 0.37, 0.25), "hat": "combat_helm",
			"weapon": "assault", "armor_plate": Color(0.22, 0.26, 0.18), "camo": true, "alts": true, "port_arms": true},
	"samurai":      {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [6, 11],
			"skin": SKIN, "shirt": Color(0.66, 0.12, 0.12), "pants": Color(0.16, 0.14, 0.20), "hat": "topknot",
			"weapon": "katana", "armor_plate": Color(0.52, 0.10, 0.10), "sode": Color(0.62, 0.11, 0.11), "hakama": true},
	"skeleton_king":{"head": [14, 12], "torso": [22, 18], "arm": [7, 19], "leg": [8, 18], "style": "skeleton",
			"skin": BONE, "shirt": BONE, "pants": BONE, "hat": "crown", "weapon": "greatsword",
			"armor_plate": Color(0.30, 0.26, 0.32), "cape": Color(0.45, 0.08, 0.10), "eye_glow": Color(1.0, 0.25, 0.15)},
	# ----- Ледяная тропа (волны 61–65) -----
	"frost_archer": {"head": [10, 9], "torso": [11, 11], "arm": [3, 11], "leg": [4, 11],
			"skin": SKIN, "shirt": Color(0.82, 0.86, 0.93), "pants": Color(0.38, 0.42, 0.54), "hat": "fur_hood",
			"weapon": "ice_bow", "back": "quiver", "armor_plate": Color(0.60, 0.68, 0.80), "boots": Color(0.36, 0.30, 0.27)},
	"yeti":         {"head": [12, 11], "torso": [18, 14], "arm": [6, 15], "leg": [7, 11], "style": "fur",
			"skin": Color(0.88, 0.91, 0.96), "shirt": Color(0.88, 0.91, 0.96), "pants": Color(0.82, 0.86, 0.93), "hat": "yeti",
			"weapon": "none"},
	"frost_knight": {"head": [10, 9], "torso": [14, 12], "arm": [5, 12], "leg": [6, 12], "style": "crystal",
			"skin": Color(0.70, 0.84, 0.98), "shirt": Color(0.56, 0.70, 0.90), "pants": Color(0.44, 0.56, 0.78),
			"hat": "frost_helm", "weapon": "crystal_sword", "shield": "ice", "armor_plate": Color(0.82, 0.92, 1.0),
			"cape": Color(0.16, 0.22, 0.42), "cape_trim": Color(0.85, 0.92, 1.0), "eye_glow": Color(0.55, 0.9, 1.0)},
	"jotun":        {"head": [16, 14], "torso": [26, 22], "arm": [9, 24], "leg": [11, 20], "style": "jotun",
			"skin": Color(0.55, 0.68, 0.86), "shirt": Color(0.55, 0.68, 0.86), "pants": Color(0.46, 0.40, 0.34),
			"hat": "jotun_beard", "weapon": "ice_club", "armor_plate": Color(0.82, 0.93, 1.0),
			"cape": Color(0.32, 0.36, 0.48), "cape_trim": Color(0.92, 0.95, 1.0), "eye_glow": Color(0.6, 0.95, 1.0)},
	# ----- Храм шторма (волны 66–70) -----
	"storm_acolyte": {"head": [10, 9], "torso": [11, 12], "arm": [3, 12], "leg": [4, 11],
			"skin": SKIN, "shirt": Color(0.32, 0.40, 0.58), "pants": Color(0.24, 0.28, 0.40), "hat": "storm_hood",
			"weapon": "storm_staff", "robe": true},
	"temple_guard": {"head": [11, 10], "torso": [15, 13], "arm": [5, 13], "leg": [6, 12],
			"skin": Color(0.82, 0.64, 0.50), "shirt": Color(0.30, 0.40, 0.58), "pants": Color(0.28, 0.34, 0.46), "hat": "guard_helm",
			"weapon": "glaive", "shield": "storm", "armor_plate": BRONZE, "knee": BRONZE, "boots": Color(0.30, 0.26, 0.22),
			"cape": Color(0.20, 0.30, 0.55), "cape_trim": BRONZE},
	"thunder_priest": {"head": [10, 10], "torso": [12, 13], "arm": [3, 12], "leg": [5, 11],
			"skin": Color(0.86, 0.70, 0.58), "shirt": Color(0.86, 0.88, 0.94), "pants": Color(0.70, 0.72, 0.82), "hat": "priest_mitre",
			"weapon": "thunder_staff", "robe": true, "cape": Color(0.22, 0.32, 0.60), "cape_trim": Color(0.92, 0.78, 0.30)},
	"storm_lord":   {"head": [14, 13], "torso": [20, 22], "arm": [6, 22], "leg": [9, 18], "style": "storm",
			"skin": Color(0.70, 0.78, 0.92), "shirt": Color(0.28, 0.32, 0.46), "pants": Color(0.24, 0.27, 0.38), "hat": "storm_crown",
			"weapon": "storm_orb", "robe": Color(0.32, 0.38, 0.54), "cape": Color(0.20, 0.24, 0.38),
			"cape_trim": Color(0.72, 0.86, 1.0), "eye_glow": Color(0.92, 0.98, 1.0)},
	# ----- Лавовые просторы (волны 71–75) -----
	"fire_imp":     {"head": [9, 8], "torso": [8, 7], "arm": [3, 7], "leg": [3, 7],
			"skin": Color(0.95, 0.40, 0.14), "shirt": Color(0.95, 0.40, 0.14), "pants": Color(0.42, 0.12, 0.06),
			"hat": "imp_fire", "weapon": "none", "bare_chest": true, "bare_legs": true},
	"obsidian_golem": {"head": [10, 8], "torso": [18, 14], "arm": [6, 14], "leg": [7, 10], "style": "golem",
			"skin": Color(0.16, 0.13, 0.18), "shirt": Color(0.16, 0.13, 0.18), "pants": Color(0.13, 0.11, 0.15),
			"hat": "", "weapon": "none", "gem": Color(1.0, 0.50, 0.12), "eye_glow": Color(1.0, 0.55, 0.2)},
	"ash_walker":   {"head": [10, 9], "torso": [12, 12], "arm": [4, 12], "leg": [5, 11],
			"skin": Color(0.42, 0.40, 0.40), "shirt": Color(0.42, 0.40, 0.40), "pants": Color(0.22, 0.20, 0.20),
			"hat": "ash", "weapon": "claws", "bare_chest": true},
	"fire_cultist": {"head": [10, 10], "torso": [11, 13], "arm": [3, 12], "leg": [5, 11],
			"skin": Color(0.80, 0.60, 0.48), "shirt": Color(0.55, 0.10, 0.08), "pants": Color(0.30, 0.06, 0.05),
			"hat": "cult_hood", "weapon": "fire_staff", "robe": true},
	# ----- Тронный зал Тёмного лорда (волны 76–80) -----
	"dark_knight":  {"head": [11, 10], "torso": [15, 13], "arm": [5, 13], "leg": [6, 12], "style": "dark_plate",
			"skin": Color(0.22, 0.20, 0.24), "shirt": Color(0.17, 0.15, 0.19), "pants": Color(0.14, 0.12, 0.16),
			"hat": "dark_helm", "weapon": "dark_sword", "cape": Color(0.36, 0.05, 0.06), "cape_trim": Color(0.16, 0.12, 0.16)},
	"warlock":      {"head": [10, 10], "torso": [11, 13], "arm": [3, 12], "leg": [5, 11],
			"skin": Color(0.62, 0.55, 0.70), "shirt": Color(0.20, 0.12, 0.28), "pants": Color(0.15, 0.10, 0.20),
			"hat": "warlock_hood", "weapon": "warlock_staff", "robe": true},
	"shade":        {"head": [9, 9], "torso": [10, 11], "arm": [3, 11], "leg": [4, 12],
			"skin": Color(0.10, 0.08, 0.12), "shirt": Color(0.12, 0.10, 0.14), "pants": Color(0.10, 0.08, 0.12),
			"hat": "shade_mask", "weapon": "dagger", "cape": Color(0.07, 0.05, 0.09), "cape_trim": Color(0.25, 0.10, 0.30)},
	"executioner":  {"head": [12, 11], "torso": [18, 15], "arm": [6, 15], "leg": [7, 12],
			"skin": Color(0.80, 0.62, 0.50), "shirt": Color(0.80, 0.62, 0.50), "pants": Color(0.18, 0.14, 0.14), "hat": "exec_hood",
			"weapon": "headsman_axe", "bare_chest": true, "armor_plate": Color(0.25, 0.20, 0.20), "boots": Color(0.15, 0.12, 0.12),
			"knee": Color(0.35, 0.33, 0.36)},
	# ----- Ветряные холмы и Дворец Бездны (волны 91–100) -----
	"hollow_farmer": {"head": [10, 9], "torso": [12, 11], "arm": [4, 11], "leg": [5, 11],
			"skin": Color(0.70, 0.62, 0.74), "shirt": Color(0.78, 0.70, 0.52), "pants": Color(0.38, 0.32, 0.42), "hat": "straw_hat",
			"weapon": "trident", "eye_glow": Color(0.88, 0.58, 1.0)},
	"straw_golem":  {"head": [12, 11], "torso": [18, 15], "arm": [6, 15], "leg": [7, 12],
			"skin": Color(0.86, 0.72, 0.40), "shirt": Color(0.84, 0.70, 0.38), "pants": Color(0.74, 0.60, 0.32), "hat": "scarecrow",
			"weapon": "club", "bare_chest": true, "armor_plate": Color(0.46, 0.30, 0.52), "eye_glow": Color(0.88, 0.58, 1.0)},
	"mill_giant":   {"head": [13, 12], "torso": [22, 20], "arm": [7, 20], "leg": [9, 16],
			"skin": Color(0.74, 0.64, 0.72), "shirt": Color(0.92, 0.90, 0.84), "pants": Color(0.42, 0.34, 0.28), "hat": "bald_beard",
			"weapon": "hammer", "armor_plate": Color(0.86, 0.84, 0.78), "boots": Color(0.30, 0.24, 0.20), "eye_glow": Color(0.88, 0.58, 1.0)},
	"void_shepherd": {"head": [11, 10], "torso": [14, 15], "arm": [5, 15], "leg": [6, 14],
			"skin": Color(0.72, 0.66, 0.74), "shirt": Color(0.84, 0.80, 0.72), "pants": Color(0.36, 0.28, 0.22), "hat": "straw_hat",
			"weapon": "staff", "cape": Color(0.42, 0.32, 0.26), "armor_plate": Color(0.90, 0.86, 0.78), "boots": Color(0.24, 0.18, 0.14),
			"eye_glow": Color(0.88, 0.58, 1.0)},
	"void_guard":   {"head": [11, 10], "torso": [15, 13], "arm": [5, 13], "leg": [6, 12], "style": "dark_plate",
			"skin": Color(0.22, 0.18, 0.26), "shirt": Color(0.15, 0.11, 0.19), "pants": Color(0.12, 0.09, 0.15),
			"hat": "dark_helm", "weapon": "glaive", "shield": "storm", "cape": Color(0.30, 0.12, 0.42),
			"cape_trim": Color(0.62, 0.36, 0.86), "eye_glow": Color(0.88, 0.58, 1.0)},
	"void_mage":    {"head": [10, 10], "torso": [11, 13], "arm": [3, 12], "leg": [5, 11],
			"skin": Color(0.62, 0.55, 0.70), "shirt": Color(0.26, 0.10, 0.36), "pants": Color(0.18, 0.08, 0.24),
			"hat": "warlock_hood", "weapon": "storm_orb", "robe": true, "eye_glow": Color(0.88, 0.58, 1.0)},
	"abyss_headsman": {"head": [12, 11], "torso": [18, 15], "arm": [6, 15], "leg": [7, 12],
			"skin": Color(0.56, 0.46, 0.64), "shirt": Color(0.56, 0.46, 0.64), "pants": Color(0.12, 0.08, 0.16), "hat": "exec_hood",
			"weapon": "headsman_axe", "bare_chest": true, "armor_plate": Color(0.20, 0.12, 0.26), "boots": Color(0.10, 0.07, 0.12),
			"knee": Color(0.42, 0.30, 0.52), "eye_glow": Color(0.92, 0.65, 1.0)},
	# Лорд Бездны (102, сложная Арена): чёрно-лиловые латы из камня бездны, корона парящих
	# осколков, плащ с лиловой каймой, трещины света на груди
	"abyss_lord":   {"head": [14, 13], "torso": [24, 24], "arm": [8, 23], "leg": [10, 21], "style": "dark_plate",
			"skin": Color(0.30, 0.24, 0.36), "shirt": Color(0.12, 0.08, 0.17), "pants": Color(0.09, 0.06, 0.13),
			"hat": "abyss_crown", "weapon": "dark_greatsword", "cape": Color(0.07, 0.04, 0.11), "cape_trim": Color(0.72, 0.40, 1.0),
			"eye_glow": Color(0.85, 0.55, 1.0), "gem": Color(0.80, 0.45, 1.0), "vein": Color(0.75, 0.42, 1.0)},
	"dark_lord":    {"head": [14, 13], "torso": [22, 22], "arm": [7, 22], "leg": [9, 20], "style": "dark_plate",
			"skin": Color(0.22, 0.20, 0.24), "shirt": Color(0.21, 0.19, 0.23), "pants": Color(0.16, 0.14, 0.18),
			"hat": "dark_lord", "weapon": "dark_greatsword", "cape": Color(0.09, 0.06, 0.08), "cape_trim": Color(0.40, 0.06, 0.06),
			"eye_glow": Color(1.0, 0.55, 0.15), "gem": Color(1.0, 0.35, 0.10)},
}

var bot: Player
var kind := "grunt"
# «Кукла» без бота: для бестиария, магазина и кат-сцен (король на троне)
var size := Vector2(40, 60)
var puppet_vx := 0.0
var puppet_facing := 1
var instant := false           # тень-двойник: поза без сглаживания — точно по кадрам удара
var sit := 0.0                # 0 — стоит, 1 — сидит (король на троне)
var eyes_lit := true          # горят ли глаза (король пробуждается)
var _eye_glow: Node2D
var _cape: Sprite2D
var _halo: Sprite2D              # нимб-затмение за головой (Рассвет)
var spec := {}
var px := 2.0                 # во сколько раз растянут рисунок

var _art: Node2D              # всё тело (масштаб px, повёрнуто по направлению взгляда)
var _upper_b: Node2D          # верх тела: задняя рука
var _upper_f: Node2D          # верх тела: туловище, голова, передняя рука
var _torso: Sprite2D
var _head: Sprite2D
var _crown: Sprite2D
var _arm_f: Sprite2D
var _arm_b: Sprite2D
var _leg_f: Sprite2D
var _leg_b: Sprite2D
var _weapon: Sprite2D
var _item: Sprite2D           # то, что бросает (копьё, бомба, дымовуха)
var _flash: Polygon2D
var _glow: Polygon2D
var _hip := 0.0
var _phase := 0.0
var _t := 0.0
var _act := ""
var _act_t := 0.0
var _act_len := 0.0
var _item_hidden := 0.0
var _hurt := 0.0
var _arm_base_f := Vector2.ZERO
var _arm_base_b := Vector2.ZERO
var _turn_speed := 14.0
var hold := ""                # длительное движение (натянуть лук), пока не сброшено
var _hold_t := 0.0
var weapon_hidden := false    # оружие в полёте (брошенный молот)
var heat := 0.0               # раскалённый молот Кузнеца (0..1)
var _nock: Sprite2D           # стрела на тетиве
var _string: Line2D           # тетива лука
var alt := ""                 # что сейчас в руке вместо оружия: pistol, knife, radio
var _alts := {}
var blade_fire := Color(0, 0, 0, 0)   # пламя на клинке катаны (ульта Самурая)
var _blade_flame: Line2D
var _flip := 1.0
var core: Polygon2D            # рубиновое сердце голема
var custom_spec := {}          # своё описание модели (герой Истории); иначе — SPECS[kind]
var _back: Sprite2D           # предмет за спиной (лук, праща)
var _frog: Sprite2D           # жаба на плече (Осока)
var core_heat := 0.0           # Колосс в броне: ядро в нагруднике раскалено (0..1)
var core_open := 0.0           # Колосс-остов: насколько раскрыта грудная клетка (0..1, задаёт мозг)
var core_state := "on"         # ядро остова: off (не горит), on, hot (Сверхновая), spent (выдохлось)
var pupils_on := true          # зрачки остова горят
var tremble := 0.0             # дрожь всего тела (броня трескается)
var _endo := {}                # детали остова: ядро, рёбра, челюсть, зрачки, провода
var _heat: Polygon2D           # раскалённое ядро в нагруднике (броня)
var _cracks: Array = []        # огненные трещины на броне
var _twitch_t := 1.0
var _twitch := 0.0
var _twitch_left := 0.0
var _jaw_twitch := 0.0
var _arc_t := 0.5
var _core_flash := 0.0
var _step_acc := 0.0
static var _tex_cache := {}    # готовые текстуры частей тела: ключ — сами пиксели части
var _pose_acc := 0.0
var _pose_slot := randi() % 2      # половина врагов считает позу в чётные кадры, половина — в нечётные
var _jointed := false          # у модели есть колени и локти
var _shin_f: Node2D            # суставы: колени…
var _shin_b: Node2D
var _fore_f: Node2D            # …и локти
var _fore_b: Node2D
var _prev_af := 0.0            # куда смотрела рука в прошлом кадре (предплечье отстаёт на замахе)
var _prev_ab := 0.0
var _dyn_f := 0.0
var _dyn_b := 0.0
var smooth := true             # плавные добавки к движениям: сжатие-растяжение, шаг с подъёмом стопы, замах
var _run_k := 0.0              # 0 — стоит, 1 — бежит (шаг разгоняется и затухает плавно)
var _was_floor := true
var _fall_v := 0.0             # с какой скоростью падал перед приземлением
var _squash := 0.0             # >0 — вытянулся (толчок прыжка), <0 — сжался (приземление)
var _squash_v := 0.0
var _recoil := 1.0
var _last_shot := -9.0         # когда стрелял в прошлый раз (у скорострельных отдача мельче)
var _part_hint := ""          # какая часть тела сейчас рисуется (для мелких деталей)              # разворот всего тела (удар с разворотом)

func _ready() -> void:
	scale.x = float(_facing())          # сразу смотрит куда нужно (без разворота при появлении)
	if kind == "totem":
		_build_totem()
		return
	var spec_kind := "irida" if kind == "irida_image" else kind      # отражение выглядит как сама Ирида
	spec = custom_spec if not custom_spec.is_empty() else SPECS.get(spec_kind, SPECS["grunt"])
	var leg: Array = spec["leg"]
	var torso: Array = spec["torso"]
	var head: Array = spec["head"]
	var total: float = leg[1] + torso[1] + head[1] - 2
	px = _size().y / total
	_turn_speed = 2.2 if kind in ["colossus", "colossus_endo"] else 14.0
	_art = Node2D.new()
	_art.scale = Vector2(px, px)
	_art.position = Vector2(0, _size().y / 2)
	add_child(_art)
	_hip = -leg[1]
	_upper_b = Node2D.new()
	_upper_b.position = Vector2(0, _hip)
	_art.add_child(_upper_b)
	# хвост динозавра (Пивозавр) — позади всего
	if spec.has("tail"):
		var timg := _img(13, 7)
		var tc: Color = spec["tail"]
		for x in 13:
			var th2 := 1 + x * 4 / 12                              # у тела толще, к кончику тоньше
			var lift := (12 - x) / 4                               # кончик чуть задран
			timg.fill_rect(Rect2i(x, 7 - th2 - lift, 1, th2), tc if x % 3 != 0 else tc.darkened(0.1))
			_px(timg, x, 6 - lift, tc.darkened(0.3))
			if x % 3 == 1 and x > 2:
				_px(timg, x, 6 - th2 - lift, tc.lightened(0.3))     # гребешки
		var ts := _sprite(_art, timg, Vector2(12, 6), Vector2(-torso[0] / 2.0 + 1.0, _hip - 1.0))
		_art.move_child(ts, 0)                               # рисуется первым — позади ног и туловища
	# ноги: сначала задняя, потом передняя
	var leg_img := _draw_leg(leg[0], leg[1])
	_part_hint = "leg"
	_leg_b = _sprite(_art, leg_img, Vector2(leg[0] / 2.0, 0), Vector2(-1.5, _hip))
	_leg_b.modulate = Color(0.78, 0.78, 0.82)
	_leg_f = _sprite(_art, leg_img, Vector2(leg[0] / 2.0, 0), Vector2(1.5, _hip))
	# суставы: нога — бедро и голень, рука — плечо и предплечье (у Колосса и его остова — цельные)
	_jointed = not _colossal()
	if _jointed:
		_shin_b = _split(_leg_b, leg[0], leg[1], 0.0)
		_shin_f = _split(_leg_f, leg[0], leg[1], 0.0)
	_part_hint = ""
	_upper_f = Node2D.new()
	_upper_f.position = Vector2(0, _hip)
	_art.add_child(_upper_f)
	var th: int = torso[1]
	var shoulder := Vector2(0, 1 - th + 2)
	# задняя рука (за туловищем)
	var arm_img := _draw_arm(spec["arm"][0], spec["arm"][1])
	_arm_b = _sprite(_upper_b, arm_img, Vector2(spec["arm"][0] / 2.0, 1), shoulder + Vector2(-1, 0))
	if _jointed:
		_fore_b = _split(_arm_b, spec["arm"][0], spec["arm"][1], 1.0)
	_arm_b.modulate = Color(0.78, 0.78, 0.82)
	_arm_base_b = _arm_b.position
	if spec.has("back"):
		_back_item(shoulder)
	_part_hint = "torso"
	_torso = _sprite(_upper_f, _draw_torso(torso[0], th), Vector2(torso[0] / 2.0, th), Vector2(0, 1))
	var hp := _head_pad()
	_part_hint = "head"
	if spec.get("photo", false):
		_head = _photo_head(head, th)                      # Пивозавр: голова — фото в оранжевой рамке
	else:
		_head = _sprite(_upper_f, _draw_head(head[0], head[1]), Vector2(hp.x + head[0] / 2.0, hp.y + head[1]),
				Vector2(0, 1 - th + 1))
	_part_hint = ""
	if spec.get("style", "") == "treant" and not spec.get("dead", false):
		_crown = _sprite(_head, _draw_crown(), Vector2(20, 22), Vector2(0, -head[1] + 4))
	elif spec.get("style", "") == "treant":
		# мёртвое дерево: вместо листвы — голые корявые сучья (у Владыки — с тиной)
		_crown = _sprite(_head, _draw_dead_crown(), Vector2(24, 30), Vector2(0, -head[1] + 5))
	_arm_f = _sprite(_upper_f, arm_img, Vector2(spec["arm"][0] / 2.0, 1), shoulder + Vector2(1, 0))
	if _jointed:
		_fore_f = _split(_arm_f, spec["arm"][0], spec["arm"][1], 1.0)
	_arm_base_f = _arm_f.position
	if spec.get("frog", false):
		# жаба Квак сидит у Осоки на плече: выпученные глаза, светлое брюшко, широкий рот
		var fimg := _img(9, 7)
		var fc: Color = spec.get("frog_col", Color(0.40, 0.68, 0.28))
		fimg.fill_rect(Rect2i(0, 2, 9, 4), fc)
		fimg.fill_rect(Rect2i(1, 1, 7, 1), fc)
		for ex2 in [1, 6]:                                   # глаза-бугорки
			fimg.fill_rect(Rect2i(ex2, 0, 2, 2), fc.lightened(0.18))
			_px(fimg, ex2 + 1, 1, Color(0.06, 0.06, 0.04))
		fimg.fill_rect(Rect2i(1, 4, 8, 1), fc.darkened(0.35))     # рот
		fimg.fill_rect(Rect2i(1, 5, 7, 1), Color(0.86, 0.88, 0.55)) # брюшко
		_px(fimg, 0, 6, fc.darkened(0.2))                   # лапки
		_px(fimg, 8, 6, fc.darkened(0.2))
		_px(fimg, 4, 2, fc.darkened(0.15))                  # пятнышки
		_px(fimg, 2, 3, fc.darkened(0.15))
		# сидит на дальнем плече, за головой — лицо Осоки не закрывает
		_frog = _sprite(_upper_f, fimg, Vector2(4.5, 7), Vector2(-torso[0] / 2.0 - 0.5, 3.0 - th))
		_frog.z_index = 2
	_attach_weapon()
	if spec.get("cart", false):
		_add_cart()
	if _style() == "colossus_endo":
		_build_endo()
	elif _style() == "colossus":
		# ядро в нагруднике раскаляется (перегрев) — светится сам пиксельный квадрат
		_heat = Polygon2D.new()
		_heat.polygon = PackedVector2Array([Vector2(-3, -12), Vector2(3, -12), Vector2(3, -6), Vector2(-3, -6)])
		_heat.color = Color(1.0, 0.78, 0.4, 0.0)
		_torso.add_child(_heat)
	if _style() == "golem":
		# светящееся рубиновое сердце (гаснет, когда голем оглушён и сердце треснуло)
		core = Polygon2D.new()
		core.polygon = Util.circle(3.2, 12)
		core.color = Color(1.0, 0.3, 0.35, 0.55)
		core.position = Vector2(0, -th / 2.0 + 1)
		_torso.add_child(core)
	# щиты в задней руке
	if spec.has("shield"):
		var simg := _draw_shield(spec.get("shield_look", spec["shield"]))
		var sh2 := _sprite(_hand(_arm_b), simg, Vector2(simg.get_width() / 2.0, simg.get_height() / 2.0),
				_hp(_arm_b, Vector2(0, spec["arm"][1] - 3)))
		sh2.z_index = 2
		sh2.modulate = Color(1.25, 1.25, 1.2)
	# плащ короля — за спиной
	if spec.has("cape"):
		var cimg := _img(torso[0] - 2, int(th + leg[1] * 0.8))
		var cc: Color = spec["cape"]
		_box(cimg, 0, 0, cimg.get_width(), cimg.get_height(), cc)
		for y in range(3, cimg.get_height(), 4):
			_px(cimg, 1 + (y % 3), y, cc.darkened(0.3))
		cimg.fill_rect(Rect2i(0, 0, cimg.get_width(), 2), spec.get("cape_trim", Color(0.85, 0.7, 0.25)))
		if spec.get("cape_torn", false):
			_tear(cimg, float(spec.get("cape_tear", 1.0)))
		if spec.has("cape_hem"):                                   # тлеющий край: низ каждого лоскута «разгорается»
			var hem: Color = spec["cape_hem"]
			for x in cimg.get_width():
				var low := -1
				for y in range(cimg.get_height() - 1, -1, -1):
					if cimg.get_pixel(x, y).a > 0.0:
						low = y
						break
				for d in 5:
					if low - d >= 3 and cimg.get_pixel(x, low - d).a > 0.0 and (d < 3 or (x + d) % 2 == 0):
						cimg.set_pixel(x, low - d, Color(1.0, 0.86, 0.45) if d == 0 else cc.lerp(hem, 1.0 - d / 5.0))
		_cape = _sprite(_upper_b, cimg, Vector2(cimg.get_width() - 2, 0), shoulder + Vector2(-2, -1))
		_upper_b.move_child(_cape, 0)
	# нимб-затмение за головой (Рассвет): чёрный диск в светящемся кольце, сбоку — яркая «искра» короны
	if spec.has("halo"):
		var hc: Color = spec.get("helm_glow", spec["halo"])
		var himg := _img(23, 23)
		for y in 23:
			for x in 23:
				var d := Vector2(x - 11, y - 11).length()
				if d < 8.4:
					himg.set_pixel(x, y, Color(0.05, 0.04, 0.08))
				elif d < 10.4:
					var a := Vector2(x - 11, y - 11).angle()
					himg.set_pixel(x, y, hc.lightened(0.45) if absf(angle_difference(a, -0.75)) < 0.5 else (hc if d < 9.6 else hc.darkened(0.25)))
		for k in 3:                                                 # «искра» короны
			_px(himg, 18 + k, 4 - k, hc.lightened(0.6))
			_px(himg, 19 + k, 5 - k, hc.lightened(0.3))
		_halo = Sprite2D.new()
		_halo.texture = ImageTexture.create_from_image(himg)
		_halo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_halo.position = Vector2(0, -head[1] / 2.0 - 1.0)
		_halo.z_index = -1                                          # за головой, плечами и плащом
		_head.add_child(_halo)
	# светящиеся глаза (некромант, король)
	if spec.has("eye_glow"):
		_eye_glow = Node2D.new()
		if spec.get("eyes_off", false):
			eyes_lit = false
		for ex in ([0.0] if spec.get("one_eye", false) else [0.0, -4.0]):            # два глаза в глазницах
			var g2 := Polygon2D.new()
			g2.polygon = Util.circle(1.8, 10)
			g2.color = Color(spec["eye_glow"], 0.35)
			g2.position = Vector2(ex, 0)
			_eye_glow.add_child(g2)
			var g := Polygon2D.new()
			g.polygon = Util.circle(0.9, 8)
			g.color = spec["eye_glow"]
			g.position = Vector2(ex, 0)
			_eye_glow.add_child(g)
		_eye_glow.position = Vector2(head[0] / 2.0 - 2.5, -head[1] / 2.0 - 0.5)
		_head.add_child(_eye_glow)
	# щит гладиатора — в задней руке
	if spec.get("style", "") == "gladiator":
		var sh := _sprite(_hand(_arm_b), _draw_round_shield(), Vector2(5, 7), _hp(_arm_b, Vector2(0, spec["arm"][1] - 3)))
		sh.z_index = 2
		sh.modulate = Color(1.25, 1.25, 1.2)

# Голова-фотография: прозрачная часть нужного размера, а «кожа» вдвое детальнее —
# это и есть картинка лица (PivoFace, 44×58 при голове 22×29)
func _photo_head(head: Array, th: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(_img(head[0], head[1]))
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.offset = -Vector2(head[0] / 2.0, head[1])
	s.position = Vector2(0, 1 - th + 1)
	s.self_modulate = Color(1, 1, 1, 0)
	var skin := Sprite2D.new()
	skin.texture = {"glav": GlavFace.texture(), "genius": GeniusFace.texture(), "dj": DjFace.texture()}.get(spec.get("photo_face", ""), PivoFace.texture())
	skin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	skin.centered = false
	skin.position = -Vector2(head[0] / 2.0, head[1])
	skin.scale = Vector2(float(head[0]) / skin.texture.get_width(), float(head[1]) / skin.texture.get_height())
	skin.name = "Skin"
	s.add_child(skin)
	if spec.has("photo_tint"):
		skin.modulate = spec["photo_tint"]
	if spec.has("photo_frame"):
		# облик: поверх фото — своя рамка с украшениями (в пикселях фото, 44×58 + поля)
		var fr := Sprite2D.new()
		fr.texture = ImageTexture.create_from_image(_photo_frame(spec["photo_frame"]))
		fr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fr.centered = false
		fr.scale = skin.scale
		fr.position = skin.position - Vector2(10, 24) * skin.scale
		fr.name = "Frame"
		s.add_child(fr)
	_upper_f.add_child(s)
	return s

# DJ Клима: большие диджейские наушники поверх фото — дужка над головой, чашки у ушей
# с неоновым кольцом и огоньками-эквалайзером. Облик меняет цвета и добавляет свою рамку.
static func _dj_phones(theme: String) -> Image:
	var im := _img(64, 84) if theme == "" else _photo_frame(theme)
	var x0 := 10
	var y0 := 24
	var pal: Array = {"": [Color(0.10, 0.10, 0.13), Color(0.30, 0.90, 1.0), Color(1.0, 0.36, 0.80)],
			"ember": [Color(0.20, 0.08, 0.05), Color(1.0, 0.55, 0.15), Color(1.0, 0.86, 0.40)],
			"frost": [Color(0.20, 0.30, 0.45), Color(0.70, 0.92, 1.0), Color(0.96, 0.99, 1.0)],
			"void": [Color(0.10, 0.06, 0.15), Color(0.72, 0.40, 1.0), Color(0.95, 0.80, 1.0)],
			"sun": [Color(0.98, 0.92, 0.72), Color(1.0, 0.80, 0.32), Color(1.0, 1.0, 0.92)]}.get(theme, [Color(0.1, 0.1, 0.13), Color(0.3, 0.9, 1.0), Color(1.0, 0.36, 0.8)])
	var band: Color = pal[0]
	var glow: Color = pal[1]
	var led: Color = pal[2]
	for x in range(x0 - 1, x0 + 45):                                     # дужка над капюшоном
		var arc := int(round(9.0 * sin(PI * (x - x0 + 1) / 46.0)))
		im.fill_rect(Rect2i(x, y0 + 8 - arc, 1, 3), band)
		if (x / 2) % 2 == 0:
			im.set_pixel(x, y0 + 8 - arc, band.lightened(0.25))
	for cx in [x0 - 6, x0 + 40]:                                         # чашки у ушей
		im.fill_rect(Rect2i(cx, y0 + 18, 10, 18), band)
		im.fill_rect(Rect2i(cx + 1, y0 + 19, 8, 1), band.lightened(0.2))
		for y in range(y0 + 20, y0 + 34):                                 # неоновое кольцо
			im.set_pixel(cx + 1, y, glow)
			im.set_pixel(cx + 8, y, glow)
		im.fill_rect(Rect2i(cx + 2, y0 + 20, 6, 1), glow)
		im.fill_rect(Rect2i(cx + 2, y0 + 33, 6, 1), glow)
		for k in 3:                                                       # эквалайзер на чашке
			var hgt: int = [5, 9, 6][k]
			im.fill_rect(Rect2i(cx + 3 + k * 2 - (1 if k == 2 else 0), y0 + 32 - hgt, 1, hgt), led if k == 1 else glow.lightened(0.3))
		im.fill_rect(Rect2i(cx + 2, y0 + 15, 6, 4), band.darkened(0.2))   # крепление к дужке
	return im

# Рамка фото Пивозавра для облика: огненная (языки пламени сверху), бездны (рваная, с рогами
# и трещиной разлома) или солнечная (золото, корона с камнями, лучи). Фото 44×58 лежит в (10, 24).
static func _photo_frame(look: String) -> Image:
	if look.begins_with("dj"):
		return _dj_phones(look.trim_prefix("dj").trim_prefix("_"))
	var im := _img(64, 84)
	var x0 := 10
	var y0 := 24
	match look:
		"headset":   # гарнитура сисадмина поверх фото: дужка, чашки наушников, микрофон, зелёный огонёк
			var band := Color(0.12, 0.10, 0.14)
			for x in range(x0 + 6, x0 + 38):
				var arc := int(round(6.0 * sin(PI * (x - x0 - 6) / 32.0)))
				im.fill_rect(Rect2i(x, y0 - arc - 1, 1, 2), band)
			for cx in [x0 - 3, x0 + 41]:
				im.fill_rect(Rect2i(cx, y0 + 18, 6, 12), band)
				im.fill_rect(Rect2i(cx + 1, y0 + 19, 4, 10), Color(0.55, 0.08, 0.14))
			for k in 14:                                                      # штанга микрофона
				im.set_pixel(x0 + 44 - k / 2, y0 + 30 + k, band)
			im.fill_rect(Rect2i(x0 + 35, y0 + 43, 4, 3), band)
			im.set_pixel(x0 + 2, y0 + 22, Color(0.40, 1.0, 0.45))
		"ember":
			for k in 2:
				for x in range(x0 + k, x0 + 44 - k):
					var c := Color(1.0, 0.45, 0.10) if (x / 3) % 2 == 0 else Color(0.85, 0.22, 0.06)
					im.set_pixel(x, y0 + k, c)
					im.set_pixel(x, y0 + 57 - k, c.darkened(0.2))
				for y in range(y0 + k, y0 + 58 - k):
					var c2 := Color(1.0, 0.45, 0.10) if (y / 3) % 2 == 0 else Color(0.85, 0.22, 0.06)
					im.set_pixel(x0 + k, y, c2)
					im.set_pixel(x0 + 43 - k, y, c2)
			for k in 9:                                                    # языки пламени над рамкой
				var fx := x0 + 2 + k * 5
				var fh := 8 + (k * 7) % 9
				for j in fh:
					var hw := maxi(0, 2 - j * 3 / fh)
					var c3 := Color(1.0, 0.86, 0.40) if j > fh * 2 / 3 else (Color(1.0, 0.55, 0.12) if j > fh / 3 else Color(0.90, 0.28, 0.06))
					im.fill_rect(Rect2i(fx - hw, y0 - 1 - j, hw * 2 + 1, 1), c3)
			for c4 in [[x0 + 2, y0 + 2], [x0 + 41, y0 + 2], [x0 + 2, y0 + 55], [x0 + 41, y0 + 55]]:
				im.set_pixel(c4[0], c4[1], Color(0.15, 0.10, 0.08))         # сажа в углах
		"frost":     # ледяная рамка: голубой лёд, снежная шапка сверху, сосульки свисают с верхнего края
			var ice := Color(0.55, 0.82, 1.0)
			var deep := Color(0.30, 0.52, 0.78)
			for k in 2:
				for x in range(x0 + k, x0 + 44 - k):
					var c := ice if (x / 4) % 2 == 0 else deep
					im.set_pixel(x, y0 + k, c if k == 0 else Color(0.90, 0.97, 1.0))
					im.set_pixel(x, y0 + 57 - k, c.darkened(0.1))
				for y in range(y0 + k, y0 + 58 - k):
					var c2 := ice if (y / 4) % 2 == 0 else deep
					im.set_pixel(x0 + k, y, c2)
					im.set_pixel(x0 + 43 - k, y, c2)
			for x in range(x0 - 2, x0 + 46):                                      # снежная шапка
				var sh := 2 + int(round(1.6 * sin(x * 0.7) + sin(x * 0.23)))
				for j in maxi(1, sh):
					im.set_pixel(x, y0 - 1 - j, Color(0.96, 0.99, 1.0) if j < sh - 1 else Color(0.85, 0.94, 1.0))
			for k in 7:                                                            # сосульки
				var ix := x0 + 3 + k * 6 + (k % 2)
				var ln := 3 + (k * 5) % 4
				for j in ln:
					var hw := 1 if j < ln / 2 else 0
					for dx in range(-hw, hw + 1):
						im.set_pixel(ix + dx, y0 + 2 + j, Color(0.80, 0.94, 1.0, 0.95 - j * 0.08))
			for c4 in [[x0 + 2, y0 + 55], [x0 + 41, y0 + 55], [x0 + 41, y0 + 30], [x0 + 2, y0 + 20]]:
				im.set_pixel(c4[0], c4[1], Color(1, 1, 1))                           # искорки инея
		"void":
			var dk := Color(0.12, 0.07, 0.18)
			var vio := Color(0.72, 0.40, 1.0)
			for k in 2:
				for x in range(x0 + k, x0 + 44 - k):
					if (x * 7) % 11 != 0 or k == 1:
						im.set_pixel(x, y0 + k, dk if k == 0 else vio)
						im.set_pixel(x, y0 + 57 - k, dk if k == 0 else vio)
				for y in range(y0 + k, y0 + 58 - k):
					if (y * 5) % 13 != 0 or k == 1:
						im.set_pixel(x0 + k, y, dk if k == 0 else vio)
						im.set_pixel(x0 + 43 - k, y, dk if k == 0 else vio)
			for s in [-1, 1]:                                              # рога над углами
				var bx := x0 + 4 if s < 0 else x0 + 39
				for k in 14:
					var off: Variant = int(round(sin(k / 13.0 * PI * 0.8) * 5.0)) * s
					var hw := 2 if k < 6 else (1 if k < 11 else 0)
					im.fill_rect(Rect2i(bx + off - hw, y0 - 1 - k, hw * 2 + 1, 1), dk.lightened(0.12) if k < 11 else vio)
			var cx := x0 + 30                                               # трещина разлома по углу фото
			for k in 12:
				im.set_pixel(cx + k / 2 - (1 if k % 3 == 0 else 0), y0 + 2 + k, vio.lightened(0.3))
		"sun":
			var gold := Color(1.0, 0.80, 0.32)
			for k in 2:
				for x in range(x0 + k, x0 + 44 - k):
					im.set_pixel(x, y0 + k, gold if k == 0 else Color(1.0, 0.97, 0.85))
					im.set_pixel(x, y0 + 57 - k, gold if k == 0 else Color(1.0, 0.97, 0.85))
				for y in range(y0 + k, y0 + 58 - k):
					im.set_pixel(x0 + k, y, gold if k == 0 else Color(1.0, 0.97, 0.85))
					im.set_pixel(x0 + 43 - k, y, gold if k == 0 else Color(1.0, 0.97, 0.85))
			for c5 in [[x0, y0], [x0 + 41, y0], [x0, y0 + 55], [x0 + 41, y0 + 55]]:
				im.fill_rect(Rect2i(c5[0], c5[1], 3, 3), Color(1.0, 0.95, 0.70))      # золотые уголки
			im.fill_rect(Rect2i(x0 + 6, y0 - 4, 32, 4), gold)                     # корона
			for k in 5:
				var tx := x0 + 7 + k * 7
				var th := 6 if k % 2 == 0 else 4
				im.fill_rect(Rect2i(tx, y0 - 4 - th, 3, th), gold)
				im.set_pixel(tx + 1, y0 - 5 - th, Color(1.0, 0.98, 0.88))
			for g in [[x0 + 14, Color(0.85, 0.15, 0.15)], [x0 + 22, Color(0.25, 0.55, 1.0)], [x0 + 29, Color(0.25, 0.75, 0.35)]]:
				im.fill_rect(Rect2i(g[0], y0 - 3, 2, 2), g[1])                        # камни
			for k in 7:                                                            # лучи за короной
				var a := PI + PI * (k + 1) / 8.0
				for r in range(26, 34):
					im.set_pixel(x0 + 22 + int(cos(a) * r), y0 - 2 + int(sin(a) * r * 0.6), Color(1.0, 0.90, 0.55, 0.55))
	return im

func _size() -> Vector2:
	return bot.body_size if bot else size

func _vel() -> Vector2:
	return bot.velocity if bot else Vector2(puppet_vx, 0)

func _floor() -> bool:
	return bot.is_on_floor() if bot else true

func _facing() -> int:
	return bot.facing if bot else puppet_facing

# ---------- Суставы ----------
# Делит готовую часть (руку или ногу) пополам: верх остаётся на месте, низ уходит в дочерний
# узел-сустав и может сгибаться. Возвращает сустав (локоть или колено). pivot_y — где у части
# была точка крепления по высоте (у ноги 0, у руки 1).
func _split(limb: Sprite2D, w: int, h: int, pivot_y: float) -> Node2D:
	var cut := h / 2
	var skin := limb.get_node("Skin") as Sprite2D
	var tex := skin.texture
	skin.region_enabled = true
	skin.region_rect = Rect2(0, 0, w * 2, (cut + 1) * 2)              # верх — с запасом в клеточку: сгиб без щели
	var joint := Node2D.new()
	joint.name = "Joint"
	joint.position = Vector2(0, cut - pivot_y)
	limb.add_child(joint)
	var low := Sprite2D.new()
	low.name = "Low"
	low.texture = tex
	low.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	low.centered = false
	low.region_enabled = true
	low.region_rect = Rect2(0, (cut - 1) * 2, w * 2, (h - cut + 1) * 2)
	low.position = Vector2(-w / 2.0, -1.0)
	low.scale = Vector2(0.5, 0.5)
	joint.add_child(low)
	joint.set_meta("off", joint.position)
	return joint

# К чему крепить то, что держит рука (оружие, щит): к предплечью, если рука с локтем
func _hand(arm: Sprite2D) -> Node:
	var j := arm.get_node_or_null("Joint")
	return j if j else arm

# Точка в координатах руки → в координатах того, к чему крепим (предплечья)
func _hp(arm: Sprite2D, at: Vector2) -> Vector2:
	var j := arm.get_node_or_null("Joint") as Node2D
	return at - j.position if j else at

# ---------- Сборка ----------
func _sprite(parent: Node, img: Image, pivot: Vector2, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	# Одинаковые части (у всех гоблинов одни и те же ноги) делят одну пару текстур: «кожа» с
	# объёмом и деталями считается по пикселям один раз, а не при каждом появлении врага.
	var key := "%d:%d:%d:%s" % [img.get_width(), img.get_height(), hash(img.get_data()), _part_hint]
	var pair: Array = _tex_cache.get(key, [])
	if pair.is_empty():
		var hi := img.duplicate() as Image
		hi.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
		_details(hi, _part_hint)
		_volume(hi)
		pair = [ImageTexture.create_from_image(img), ImageTexture.create_from_image(hi)]
		if _tex_cache.size() > 1500:
			_tex_cache.clear()                               # на всякий случай: кэш не растёт без конца
		_tex_cache[key] = pair
	s.texture = pair[0]                                  # размер и точки крепления — в исходных пикселях
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.offset = -pivot
	s.position = pos
	s.self_modulate = Color(1, 1, 1, 0)                   # сама часть не рисуется...
	var skin := Sprite2D.new()                           # ...рисуется её «кожа» вдвое детальнее
	skin.texture = pair[1]
	skin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	skin.centered = false
	skin.position = -pivot
	skin.scale = Vector2(0.5, 0.5)
	skin.name = "Skin"
	s.add_child(skin)
	parent.add_child(s)
	return s

# Объём части тела: свет сверху-спереди, тень снизу и сзади, мягкий градиент
# сверху вниз и лёгкая фактура ткани/кожи — фигура выглядит выпуклой, а не плоской.
static func _volume(im: Image) -> void:
	var w := im.get_width()
	var h := im.get_height()
	var top := h
	var bottom := 0
	for y in h:
		for x in w:
			if im.get_pixel(x, y).a > 0.0:
				top = mini(top, y)
				bottom = maxi(bottom, y)
	if bottom < top:
		return
	var src: Image = im.duplicate()
	var span := maxf(bottom - top, 1.0)
	for y in range(top, bottom + 1):
		for x in w:
			var p: Color = src.get_pixel(x, y)
			if p.a <= 0.0:
				continue
			var up: Color = src.get_pixel(x, y - 1) if y > 0 else Color(0, 0, 0, 0)
			var dn: Color = src.get_pixel(x, y + 1) if y < h - 1 else Color(0, 0, 0, 0)
			var bk: Color = src.get_pixel(x - 1, y) if x > 0 else Color(0, 0, 0, 0)
			var fr: Color = src.get_pixel(x + 1, y) if x < w - 1 else Color(0, 0, 0, 0)
			var k := 0.06 - 0.16 * (y - top) / span                # свет сверху, к ногам темнее
			if up.a <= 0.0:
				k += 0.16                                          # блик по верхнему краю силуэта
			elif not _same(up, p):
				k += 0.07                                          # верх каждой детали (ремень, пластина) светлее
			if dn.a <= 0.0:
				k -= 0.18                                          # тень по нижнему краю
			elif not _same(dn, p):
				k -= 0.07
			if bk.a <= 0.0:
				k -= 0.10                                          # спина в тени
			if fr.a <= 0.0:
				k += 0.07                                          # перед — на свету
			var hsh := ((x * 73856093) ^ (y * 19349663)) & 7
			k += (hsh - 3.5) * 0.006                               # мелкая фактура ткани и кожи
			var q: Color = p.lightened(k) if k > 0.0 else p.darkened(-k)
			q.a = p.a
			im.set_pixel(x, y, q)

# Мелкие детали в удвоенном разрешении: блик в глазах, складки одежды, колени
static func _details(hi: Image, part: String) -> void:
	var w := hi.get_width()
	var h := hi.get_height()
	match part:
		"head":
			# глаз — отдельная тёмная точка на лице: ставим в неё белый блик (один на голову)
			var best := Vector2i(-1, -1)
			for y in range(2, h - 2, 2):
				for x in range(2, w - 3, 2):
					var c: Color = hi.get_pixel(x, y)
					if c.a <= 0.0 or not _same(c, DARK):
						continue
					var l: Color = hi.get_pixel(x - 1, y)
					var r: Color = hi.get_pixel(x + 2, y)
					var u: Color = hi.get_pixel(x, y - 1)
					if l.a > 0.0 and r.a > 0.0 and u.a > 0.0 and not _same(l, DARK) and not _same(r, DARK) \
							and not _same(u, DARK) and x > best.x:
						best = Vector2i(x, y)
			if best.x >= 0:
				hi.set_pixel(best.x + 1, best.y, Color(0.95, 0.95, 0.92))
		"torso":
			# складки ткани: тонкие тени в средней части
			for fx in range(5, w - 4, 7):
				for y in range(int(h * 0.3), int(h * 0.8)):
					var c2: Color = hi.get_pixel(fx, y)
					if c2.a > 0.0 and hi.get_pixel(fx - 2, y).a > 0.0 and hi.get_pixel(fx + 2, y).a > 0.0:
						hi.set_pixel(fx, y, c2.darkened(0.07))
		"leg":
			# складка у колена и светлая кромка обуви
			var ky := int(h * 0.45)
			for x in range(1, w - 1):
				var c3: Color = hi.get_pixel(x, ky)
				if c3.a > 0.0:
					hi.set_pixel(x, ky, c3.darkened(0.12))
					hi.set_pixel(x, ky + 1, c3.lightened(0.05))

static func _same(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.06

func _head_pad() -> Vector2:
	return Vector2(6, 12)

func _attach_weapon() -> void:
	var w: String = spec["weapon"]
	var hand := Vector2(0, spec["arm"][1] - 2)
	if _colossal():
		# у Колосса вместо кисти — пушка, она нарисована прямо на руке
		_flash = _muzzle(_arm_f, Vector2(0, spec["arm"][1] + 2))
		return
	if spec.get("style", "") == "treant":
		_item = _sprite(_hand(_arm_f), _draw_item("seed"), Vector2(3, 3), _hp(_arm_f, hand + Vector2(0, 2)))
		return
	if spec.get("hat", "") == "story":
		_story_alts(hand)
	if w == "none":
		return
	var img := _draw_weapon(spec.get("weapon_look", w))     # облик может перерисовать оружие, хват — прежний
	var grip := Vector2(2, img.get_height() / 2.0)
	if w in UPRIGHT:
		grip = Vector2(img.get_width() * 0.45, img.get_height() / 2.0)
	if w == "hammer" or w == "katana" or w == "dawn_blade":
		grip = Vector2(3, img.get_height() / 2.0)
	if w == "kama":
		grip = Vector2(3, 10)
	if w == "war_fan":
		grip = Vector2(1.5, img.get_height() / 2.0)     # веер держат за основание
	_weapon = _sprite(_hand(_arm_f), img, grip, _hp(_arm_f, hand))
	_weapon.rotation = PI / 2
	if w in AIMED:
		_flash = _muzzle(_weapon, Vector2(img.get_width() - 1, img.get_height() / 2.0))
	if w in ["spear", "bomb", "javelin", "bone"]:
		_item = _weapon
	if spec.has("item"):
		_item = _sprite(_hand(_arm_b), _draw_item(spec.get("item_look", spec["item"])), Vector2(2, 2), _hp(_arm_b, Vector2(0, spec["arm"][1] - 2)))
	if w == "longbow":
		# тетива — отдельная линия: её видно, как она натягивается
		_string = Line2D.new()
		_string.width = 0.5
		_string.default_color = spec.get("string", Color(0.95, 0.93, 0.85))
		_string.points = PackedVector2Array([Vector2(1, 0.5), Vector2(1, img.get_height() / 2.0), Vector2(1, img.get_height() - 0.5)])
		_string.position = -grip
		_weapon.add_child(_string)
		var aimg := _img(16, 3)
		var nk: Array = spec.get("nock", [Color(0.6, 0.45, 0.25), STEEL.lightened(0.2), Color(0.9, 0.3, 0.2)])
		aimg.fill_rect(Rect2i(2, 1, 12, 1), nk[0])
		aimg.fill_rect(Rect2i(13, 0, 3, 3), nk[1])
		aimg.fill_rect(Rect2i(0, 0, 3, 1), nk[2])
		aimg.fill_rect(Rect2i(0, 2, 3, 1), nk[2])
		_nock = _sprite(_weapon, aimg, Vector2(1, 1.5), Vector2(1, img.get_height() / 2.0) - grip)
		_nock.visible = false
	if spec.get("alts", false):
		# пистолет, нож и рация — достаёт вместо автомата
		for a in ["pistol", "knife", "radio"]:
			var aimg := _draw_weapon(a)
			var asp := _sprite(_hand(_arm_f), aimg, Vector2(2, aimg.get_height() / 2.0), _hp(_arm_f, hand))
			asp.rotation = PI / 2 if a != "radio" else 0.3
			asp.visible = false
			_alts[a] = asp
	if w == "katana" or w == "dawn_blade":     # пламя катаны / сияние меча Рассвета
		_blade_flame = Line2D.new()
		_blade_flame.points = PackedVector2Array([Vector2(8, img.get_height() / 2.0), Vector2(img.get_width(), img.get_height() / 2.0)])
		_blade_flame.position = -grip
		_blade_flame.width = 4.0
		_blade_flame.visible = false
		var gr := Gradient.new()
		gr.set_color(0, Color(1, 1, 1, 0.2))
		gr.set_color(1, Color(1, 1, 1, 0.9))
		_blade_flame.gradient = gr
		_weapon.add_child(_blade_flame)
	if w == "lantern_staff":
		var lg := Polygon2D.new()                  # мягкий свет фонарика
		lg.polygon = Util.circle(4.0, 12)
		lg.color = Color(spec.get("spell_glow", Color(0.6, 1.0, 0.5)), 0.35)
		lg.position = Vector2(20, 7.5) - grip
		_weapon.add_child(lg)
	if w in ["staff", "scythe", "branch", "necro_staff", "hammer"]:
		_glow = Polygon2D.new()
		_glow.polygon = Util.circle(3.0, 10)
		_glow.color = Color(0.75, 0.45, 1.0, 0.0) if w == "scythe" else Color(0.5, 1.0, 0.6, 0.0)
		if spec.has("spell_glow"):
			_glow.color = Color(spec["spell_glow"], 0.0)          # облик: колдовство светится цветом серии
		_glow.position = Vector2(img.get_width() - 2, img.get_height() / 2.0)
		if w == "hammer":
			_glow.color = Color(1.0, 0.5, 0.1, 0.0)
			_glow.polygon = Util.circle(4.5, 12)
			_glow.position = Vector2(img.get_width() - 4, img.get_height() / 2.0) - grip
		_weapon.add_child(_glow)

func _muzzle(parent: Node, pos: Vector2) -> Polygon2D:
	var f := Polygon2D.new()
	f.polygon = PackedVector2Array([Vector2(0, -2), Vector2(4, -1), Vector2(7, 0), Vector2(4, 1), Vector2(0, 2)])
	f.color = Color(1.0, 0.85, 0.3)
	f.position = pos
	f.visible = false
	if parent == _arm_f:
		f.rotation = PI / 2
	parent.add_child(f)
	return f

func _back_item(shoulder: Vector2) -> void:
	var img: Image
	match spec.get("back_look", spec["back"]):
		"tome":     # Летописец: толстая книга на ремне — переплёт, обрез страниц, золотая застёжка и знак
			var bpl: Array = spec.get("bpal", [Color(0.38, 0.12, 0.14), Color(0.96, 0.92, 0.80), Color(1.0, 0.82, 0.38), Color(0.22, 0.07, 0.08)])
			img = _img(8, 11)
			_box(img, 0, 0, 8, 11, bpl[0])
			img.fill_rect(Rect2i(6, 1, 2, 9), bpl[1])                             # обрез страниц
			for y in range(2, 10, 2):
				_px(img, 7, y, bpl[1].darkened(0.12))
			img.fill_rect(Rect2i(0, 1, 2, 9), bpl[3])                             # корешок
			img.fill_rect(Rect2i(2, 5, 6, 1), bpl[2])                             # застёжка
			_px(img, 6, 5, bpl[2].lightened(0.35))
			_px(img, 4, 2, bpl[2])                                                 # знак на обложке
			_px(img, 3, 3, bpl[2])
			_px(img, 5, 3, bpl[2])
			_px(img, 4, 8, bpl[2].darkened(0.2))
		"thruster":   # Почти легенда: ранец-ускоритель — корпус костюма, два сопла с голубым огнём, огонёк заряда
			var tp: Array = spec.get("suit_pal", [Color(0.92, 0.93, 0.96), Color(1.0, 0.52, 0.14), Color(0.20, 0.22, 0.28), Color(0.30, 0.90, 1.0)])
			img = _img(7, 12)
			_box(img, 0, 0, 7, 9, tp[0])
			img.fill_rect(Rect2i(1, 2, 5, 1), tp[1])
			_px(img, 3, 5, tp[3])
			img.fill_rect(Rect2i(0, 9, 3, 2), tp[2])                             # сопла
			img.fill_rect(Rect2i(4, 9, 3, 2), tp[2])
			_px(img, 1, 11, tp[3])
			_px(img, 5, 11, tp[3])
		"boombox":    # DJ Клима: маленькая колонка на ремне за спиной — два динамика, неоновая полоска
			var bc: Color = spec.get("note_glow", Color(0.30, 0.90, 1.0))
			img = _img(9, 7)
			_box(img, 0, 0, 9, 7, Color(0.12, 0.12, 0.15))
			for cx in [2, 6]:
				img.fill_rect(Rect2i(cx - 1, 2, 3, 3), Color(0.30, 0.30, 0.36))
				_px(img, cx, 3, Color(0.06, 0.06, 0.08))
			img.fill_rect(Rect2i(1, 1, 7, 1), bc)
			_px(img, 4, 5, spec.get("sole", Color(1.0, 0.36, 0.80)))
		"genius_katana":  # катана за спиной: тёмно-красные ножны, фиолетовая цуба, вместо кисточки — вилка RJ-45
			img = _img(4, 17)
			img.fill_rect(Rect2i(1, 5, 2, 12), Color(0.45, 0.07, 0.12))
			img.fill_rect(Rect2i(0, 4, 4, 1), Color(0.62, 0.28, 0.82))
			for y in 4:
				_px(img, 1 + (y % 2), y, Color(0.12, 0.10, 0.14) if y % 2 else Color(0.55, 0.08, 0.14))
			_px(img, 0, 0, Color(0.25, 0.55, 0.95))
			_px(img, 0, 1, Color(0.85, 0.88, 0.92))
		"quiver_flame":   # обугленный колчан, вместо оперения — язычки пламени
			img = _img(5, 15)
			_box(img, 0, 4, 5, 11, Color(0.22, 0.14, 0.11))
			img.fill_rect(Rect2i(0, 7, 5, 1), Color(1.0, 0.50, 0.12))
			img.fill_rect(Rect2i(1, 11, 3, 1), Color(0.85, 0.30, 0.08))
			for x in [0, 2, 4]:
				img.fill_rect(Rect2i(x, 1 + (x % 4) / 2, 1, 3), Color(1.0, 0.50, 0.12))
				img.set_pixel(x, (x % 4) / 2, Color(1.0, 0.86, 0.40))
		"quiver_ice":     # бело-голубой колчан в инее, стрелы — сосульки
			img = _img(5, 15)
			_box(img, 0, 4, 5, 11, Color(0.30, 0.46, 0.64))
			img.fill_rect(Rect2i(0, 6, 5, 1), Color(0.90, 0.97, 1.0))
			img.fill_rect(Rect2i(0, 12, 5, 1), Color(0.90, 0.97, 1.0))
			img.set_pixel(2, 9, Color(0.55, 0.86, 1.0))
			for x in [0, 2, 4]:
				img.fill_rect(Rect2i(x, 1 + (x % 4) / 2, 1, 3), Color(0.70, 0.90, 1.0))
				img.set_pixel(x, (x % 4) / 2, Color(0.95, 1.0, 1.0))
		"quiver_void":    # колчан из чёрной кости, стрелы — лиловые осколки
			img = _img(5, 15)
			_box(img, 0, 4, 5, 11, Color(0.13, 0.08, 0.19))
			img.fill_rect(Rect2i(0, 8, 5, 1), Color(0.72, 0.40, 1.0))
			img.set_pixel(2, 11, Color(0.95, 0.80, 1.0))
			for x in [0, 2, 4]:
				img.fill_rect(Rect2i(x, 1 + x / 2, 1, 3), Color(0.55, 0.28, 0.85))
				img.set_pixel(x, x / 2, Color(0.90, 0.75, 1.0))
		"quiver_sun":     # белый колчан с золотыми обручами, оперение — перья света
			img = _img(5, 15)
			_box(img, 0, 4, 5, 11, Color(0.93, 0.90, 0.82))
			img.fill_rect(Rect2i(0, 6, 5, 1), Color(1.0, 0.78, 0.30))
			img.fill_rect(Rect2i(0, 12, 5, 1), Color(1.0, 0.78, 0.30))
			img.set_pixel(2, 9, Color(1.0, 0.95, 0.70))
			for x in [0, 2, 4]:
				img.fill_rect(Rect2i(x, 0, 1, 4), Color(1.0, 0.86, 0.45) if x != 2 else Color(1.0, 0.98, 0.88))
		"mortar":   # артиллерист носит миномёт за спиной
			img = _img(4, 13)
			_box(img, 0, 0, 4, 13, Color(0.35, 0.38, 0.32))
			img.fill_rect(Rect2i(0, 0, 4, 2), DARK)
		"quiver":   # колчан со стрелами
			img = _img(5, 14)
			_box(img, 0, 3, 5, 11, Color(0.50, 0.32, 0.18))
			img.fill_rect(Rect2i(0, 6, 5, 1), Color(0.75, 0.6, 0.3))
			for x in [0, 2, 4]:
				img.fill_rect(Rect2i(x, 0, 1, 3), Color(0.92, 0.9, 0.85) if x != 2 else Color(0.9, 0.3, 0.2))
		"bow":      # охотничий лук за спиной
			img = _draw_weapon("bow")
		"sling":    # праща, свёрнутая на перевязи
			img = _img(5, 9)
			im_sling(img)
		"rifle":
			img = _draw_weapon("rifle")
		"pistol":   # кобура
			img = _img(4, 6)
			_box(img, 0, 0, 4, 6, Color(0.35, 0.24, 0.14))
		"bombs":    # сумка с бомбами
			img = _img(7, 7)
			_box(img, 0, 2, 7, 5, Color(0.45, 0.32, 0.18))
			for x in [1, 4]:
				img.fill_rect(Rect2i(x, 0, 2, 2), DARK)
	var s := _sprite(_upper_b, img, Vector2(img.get_width() / 2.0, 1), shoulder + Vector2(-3, 1))
	s.rotation = -0.35
	if spec["back"] in ["bow", "rifle"]:
		s.rotation = 0.5
		s.position += Vector2(1, -2)
	_back = s

# Жаба на плече: где она сейчас и спрятать/показать (когда прыгает на врага)
func frog_point() -> Vector2:
	if _frog and is_instance_valid(_frog):
		return _frog.to_global(Vector2(2, -2))         # рот жабы
	return muzzle()

func show_frog(v: bool) -> void:
	if _frog and is_instance_valid(_frog):
		_frog.visible = v

# Точка, откуда вылетает пуля или снаряд
func muzzle() -> Vector2:
	# Откуда вылетает снаряд. Согнутый локоть — только вид: точка считается так, будто рука прямая
	# и смотрит туда же, куда предплечье, — снаряды летят ровно оттуда же, откуда летели до суставов.
	if _jointed and _arm_f and _fore_f:
		var straight := (_arm_f.get_parent() as Node2D).global_transform * Transform2D(_arm_f.rotation + _fore_f.rotation, _arm_f.position)
		if _flash and is_instance_valid(_flash) and _weapon and _flash.get_parent() == _weapon:
			return straight * Transform2D(_weapon.rotation, _weapon.position + _fore_f.position) * _flash.position
		if not (_flash and is_instance_valid(_flash)):
			return straight * Vector2(0, spec["arm"][1])
	if _flash and is_instance_valid(_flash):
		return _flash.global_position
	if _arm_f:
		return _hand(_arm_f).to_global(_hp(_arm_f, Vector2(0, spec["arm"][1])))
	return global_position

# Плечо руки с оружием (центр дуги удара)
func shoulder() -> Vector2:
	return _arm_f.global_position if _arm_f else global_position

# Кончик клинка / оружия (для пламени катаны)
func tip() -> Vector2:
	if _weapon:
		return _weapon.to_global(Vector2(_weapon.texture.get_width() - 1, _weapon.texture.get_height() / 2.0) + _weapon.offset)
	return muzzle()

# ---------- Рисование частей ----------
static func _img(w: int, h: int) -> Image:
	return Image.create(maxi(w, 1), maxi(h, 1), false, Image.FORMAT_RGBA8)

# Прямоугольник с контуром, светлой кромкой сверху и тенью снизу
static func _box(im: Image, x: int, y: int, w: int, h: int, c: Color, outline := true) -> void:
	im.fill_rect(Rect2i(x, y, w, h), c)
	if w > 2 and h > 2:
		im.fill_rect(Rect2i(x + 1, y + 1, w - 2, 1), c.lightened(0.18))
		im.fill_rect(Rect2i(x + 1, y + h - 2, w - 2, 1), c.darkened(0.18))
	if outline:
		var o := c.darkened(0.6)
		im.fill_rect(Rect2i(x, y, w, 1), o)
		im.fill_rect(Rect2i(x, y + h - 1, w, 1), o)
		im.fill_rect(Rect2i(x, y, 1, h), o)
		im.fill_rect(Rect2i(x + w - 1, y, 1, h), o)

static func _px(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, c)

func _style() -> String:
	return spec.get("style", "")

func _colossal() -> bool:
	return _style() in ["colossus", "colossus_endo"]

func _draw_leg(w: int, h: int) -> Image:
	var im := _img(w, h)
	var pants: Color = spec["pants"]
	if spec.get("suit", false):
		# тёмные штаны костюма, белые наколенники, оранжевые ботинки
		var sp3: Array = spec.get("suit_pal", [Color(0.92, 0.93, 0.96), Color(1.0, 0.52, 0.14), pants])
		_box(im, 0, 0, w, h - 3, sp3[2])
		_box(im, 0, h / 2 - 2, w, 3, sp3[0])                                   # наколенник
		_box(im, 0, h - 3, w, 3, sp3[1])                                       # ботинок
		im.fill_rect(Rect2i(0, h - 1, w, 1), sp3[2].darkened(0.3))            # подошва
		return im
	if spec.get("hoodie", false):
		# DJ Клима: синие джинсы (шов, светлее на бёдрах, подвёрнутый низ) и белые кроссовки
		_box(im, 0, 0, w, h - 3, pants)
		for y in range(1, h - 4):
			if y % 2 == 1:
				_px(im, w - 2, y, pants.darkened(0.2))                            # боковой шов
		im.fill_rect(Rect2i(1, 1, w - 3, 2), pants.lightened(0.18))          # выцветшие бёдра
		im.fill_rect(Rect2i(0, h - 4, w, 1), pants.lightened(0.25))          # подворот
		_box(im, 0, h - 3, w, 3, spec.get("sneaker", Color(0.97, 0.97, 0.98)))
		im.fill_rect(Rect2i(0, h - 1, w, 1), spec.get("sole", Color(1.0, 0.36, 0.80)))
		_px(im, 1, h - 3, spec.get("note_glow", Color(0.3, 0.9, 1.0)))       # шнурок
		return im
	if spec.has("coat"):
		# Главный: тёмные джинсы с потёртостями и модные белые кроссовки с фиолетовой подошвой
		_box(im, 0, 0, w, h - 3, pants)
		for y in range(1, h - 4, 2):
			_px(im, w / 2, y, pants.lightened(0.15))                          # шов
		im.fill_rect(Rect2i(1, h / 2, w - 2, 1), pants.lightened(0.22))      # потёртость на колене
		_box(im, 0, h - 3, w, 3, Color(0.97, 0.97, 0.98))
		im.fill_rect(Rect2i(0, h - 1, w, 1), spec["coat_glow"])
		_px(im, w / 2, h - 2, Color(0.12, 0.10, 0.16))                      # значок
		_px(im, w / 2 + 1, h - 3, Color(0.12, 0.10, 0.16))
		return im
	if spec.get("hakama", false):     # широкие штаны-хакама и сандалии
		_box(im, 0, 0, w, h - 2, pants)
		for y in range(2, h - 3, 3):
			im.fill_rect(Rect2i(1, y, w - 2, 1), pants.lightened(0.08))
		im.fill_rect(Rect2i(0, h - 2, w, 2), spec.get("tabi", Color(0.85, 0.8, 0.7)))
		if spec.has("gi"):
			for y in range(1, h - 3, 3):
				_px(im, (y * 3) % w, y, spec["gi_trim"])                         # тёмно-красные складки хакамы
			im.fill_rect(Rect2i(0, h - 4, w, 1), spec["cable"].darkened(0.2))    # обмотка голени кабелем
		return im
	if spec.get("camo", false):       # камуфляж и высокие ботинки
		_box(im, 0, 0, w, h, pants)
		_px(im, 1, 2, pants.darkened(0.3))
		_px(im, w - 2, 5, pants.lightened(0.15))
		_px(im, 2, 7, pants.darkened(0.3))
		_box(im, 0, h - 4, w, 4, Color(0.15, 0.13, 0.11))
		return im
	match _style():
		"ninja":       # широкие тёмные штаны, обмотки на голенях, сандалии
			var pc: Color = spec["pants"]
			var wr: Color = spec.get("wrap", Color(0.45, 0.56, 0.32))
			_box(im, 0, 0, w, h - 4, pc)
			for y in range(2, h - 5, 3):
				_px(im, 1 + (y % 2), y, pc.lightened(0.1))
			_box(im, 0, h - 5, w, 3, wr.darkened(0.2))
			for x in range(0, w, 2):
				_px(im, x, h - 4, Color(0.42, 0.26, 0.15))
			_box(im, 0, h - 2, w, 2, Color(0.10, 0.09, 0.10))
		"gladiator":   # голая нога, бронзовый поножь, сандалия
			_box(im, 0, 0, w, h, spec["skin"])
			_box(im, 0, h - 8, w, 5, BRONZE)
			_box(im, 0, h - 3, w + 0, 3, Color(0.45, 0.28, 0.15))
		"colossus_endo":
			_endo_leg(im, w, h)
		"colossus":    # бронированная нога
			_box(im, 0, 0, w, h, pants)
			_box(im, 0, 3, w, 5, STEEL.darkened(0.3))
			_box(im, 0, h - 4, w, 4, DARK)
		"treant":      # корень-нога
			_box(im, 1, 0, w - 2, h - 3, spec["skin"])
			for k in 3:
				im.fill_rect(Rect2i(2 + k * 3, 1, 1, h - 5), Color(spec["skin"]).darkened(0.3))
			_box(im, 0, h - 4, w, 4, Color(spec["skin"]).darkened(0.15))
			_px(im, 0, h - 1, spec.get("leaf", Color(0.3, 0.5, 0.2)))
			_px(im, w - 1, h - 1, spec.get("leaf", Color(0.3, 0.5, 0.2)))
		"skeleton":
			if spec.has("robe"):       # некромант: длинная тёмная ряса
				_box(im, 0, 0, w, h, spec["robe"])
				_px(im, w / 2, h - 1, BONE)
			else:
				var bx := w / 2 - 1
				im.fill_rect(Rect2i(bx, 0, 2, h - 1), BONE)
				im.fill_rect(Rect2i(bx - 1, h / 2 - 1, 4, 2), BONE.darkened(0.08))   # колено
				im.fill_rect(Rect2i(bx - 1, h - 2, 4, 2), BONE)                     # стопа
				im.fill_rect(Rect2i(bx + 1, 1, 1, h - 3), BONE.darkened(0.25))
		"golem":       # каменная нога с рубиновыми вкраплениями
			_box(im, 0, 0, w, h, spec["skin"])
			for k in 3:
				_px(im, 1 + k % 2, 2 + k * 3, Color(spec["skin"]).darkened(0.35))
			_px(im, w - 2, h / 2, spec.get("gem", Color(0.9, 0.15, 0.25)))
			_box(im, 0, h - 3, w, 3, Color(spec["skin"]).darkened(0.25))
		"fur":         # мохнатая лапа йети
			var fc: Color = spec["pants"]
			_box(im, 0, 0, w, h, fc)
			for y in range(1, h - 2, 2):
				_px(im, (y * 3) % w, y, fc.darkened(0.15))
			_box(im, 0, h - 2, w, 2, fc.darkened(0.3))
			_px(im, w - 1, h - 1, Color(0.3, 0.3, 0.35))
		"jotun":       # голая синяя нога, меховая обмотка, ледяной наколенник
			_box(im, 0, 0, w, h, spec["skin"])
			_box(im, 0, 0, w, h / 3, spec["pants"])
			for x in range(0, w, 2):
				_px(im, x, h / 3, Color(spec["pants"]).darkened(0.25))
			_crystal_box(im, 0, h / 2 - 1, w, 3, spec["armor_plate"])
			_box(im, 0, h - 5, w, 5, Color(spec["pants"]).darkened(0.1))
			for x in range(1, w, 2):
				_px(im, x, h - 5, Color(0.9, 0.92, 0.95))
		"dark_plate":  # чёрные латы с серебристыми прожилками, шип на колене
			var pc2: Color = spec["pants"]
			_box(im, 0, 0, w, h, pc2)
			_box(im, 0, h / 2 - 2, w, 4, pc2.lightened(0.12))
			_px(im, w - 1, h / 2 - 3, Color(0.75, 0.72, 0.78))
			for y in range(1, h - 3, 3):
				_px(im, 1 + (y % (w - 2)), y, spec.get("vein", Color(0.55, 0.52, 0.60)))
			_box(im, 0, h - 3, w, 3, pc2.darkened(0.3))
		"storm":       # подол мантии развевается и тает облаком
			var rc3: Color = spec["robe"]
			for y in h:
				var a := 1.0 - maxf(0.0, float(y - h / 2) / (h / 2.0)) * 0.75
				im.fill_rect(Rect2i(0, y, w, 1), Color(rc3.r, rc3.g, rc3.b, a))
			for y in range(2, h, 4):
				_px(im, (y * 2) % w, y, Color(0.75, 0.88, 1.0, 0.8))
		"crystal":     # кристальная нога
			_crystal_box(im, 0, 0, w, h, spec["pants"])
			_crystal_box(im, 0, h - 3, w, 3, Color(spec["pants"]).darkened(0.2))
		_:
			if spec.get("bare_legs", false):
				_box(im, 0, 0, w, h, spec["skin"])
				_box(im, 0, 0, w, 3, pants)                                    # набедренная повязка
				im.fill_rect(Rect2i(0, h - 3, w, 3), Color(0.45, 0.28, 0.15))  # сандалии
				im.fill_rect(Rect2i(0, h - 6, w, 1), Color(0.45, 0.28, 0.15))
			else:
				_box(im, 0, 0, w, h, pants)
				if spec.has("boots"):          # сапоги повыше
					_box(im, 0, h - 5, w, 5, spec["boots"])
					im.fill_rect(Rect2i(0, h - 5, w, 1), Color(spec["boots"]).lightened(0.2))
				else:
					_box(im, 0, h - 3, w, 3, DARK)
				if spec.has("knee"):           # железные наколенники
					_box(im, 0, h / 2 - 2, w, 3, spec["knee"])
			if spec.get("robe", false) is bool and spec.get("robe", false):
				im.fill_rect(Rect2i(0, 0, w, h / 2), spec["shirt"])
	return im

func _draw_arm(w: int, h: int) -> Image:
	var im := _img(w, h)
	var shirt: Color = spec["shirt"]
	var skin: Color = spec["skin"]
	if spec.has("gi"):
		# рукав ги, тёмно-красный наплечник, кабель намотан на предплечье, ладонь
		_box(im, 0, 0, w, h - 2, shirt)
		_box(im, 0, 0, w, 4, spec["sode"])
		im.fill_rect(Rect2i(0, 2, w, 1), spec["sode"].darkened(0.35))
		for y in range(h - 6, h - 2, 2):
			im.fill_rect(Rect2i(0, y, w, 1), spec["cable"])
		_box(im, 0, h - 2, w, 2, skin)
		return im
	if spec.get("suit", false):
		# рукав костюма: белый наплечник с оранжевой каймой, тёмный рукав, голубой огонёк
		var sp2: Array = spec.get("suit_pal", [shirt, Color(1.0, 0.52, 0.14), Color(0.2, 0.22, 0.28), Color(0.3, 0.9, 1.0)])
		_box(im, 0, 0, w, h - 2, sp2[2])
		_box(im, 0, 0, w, 4, sp2[0])
		im.fill_rect(Rect2i(0, 3, w, 1), sp2[1])
		_px(im, w - 1, h / 2, sp2[3])
		_box(im, 0, h - 2, w, 2, sp2[2].lightened(0.15))
		return im
	if spec.get("hoodie", false):
		# длинный чёрный рукав кофты, манжета-резинка, ладонь
		_box(im, 0, 0, w, h - 2, shirt)
		im.fill_rect(Rect2i(0, h - 4, w, 1), shirt.lightened(0.14))
		for y in range(2, h - 5, 2):
			_px(im, w - 1, y, spec.get("note_glow", Color(0.3, 0.9, 1.0)).darkened(0.35))   # неоновый кант по рукаву
		_px(im, 1, 4, spec.get("sole", Color(1.0, 0.36, 0.8)).darkened(0.2))             # нашивка
		_box(im, 0, h - 2, w, 2, skin)
		return im
	if spec.has("coat"):
		# рукав пальто со светящимся швом и манжетой, ладонь
		var coat: Color = spec["coat"]
		var glow: Color = spec["coat_glow"]
		_box(im, 0, 0, w, h - 2, coat)
		im.fill_rect(Rect2i(w - 1, 0, 1, h - 3), glow.darkened(0.2))
		im.fill_rect(Rect2i(0, h - 4, w, 1), glow)
		_box(im, 0, h - 2, w, 2, skin)
		return im
	match _style():
		"ninja":       # голая рука с бледной татуировкой, обмотка на запястье
			_box(im, 0, 0, w, h, skin)
			var tc: Color = spec.get("tattoo", Color(0.84, 0.8, 0.92))
			for y in range(1, h - 4):
				if (y * 5) % 7 < 3:
					_px(im, (y / 2) % w, y, tc)
			_box(im, 0, h - 4, w, 3, spec.get("wrap", Color(0.45, 0.56, 0.32)))
		"gladiator":
			_box(im, 0, 0, w, h, skin)
			_box(im, 0, 0, w, 4, BRONZE)               # наплечник
			_box(im, 0, h - 6, w, 3, Color(0.45, 0.28, 0.15))   # наруч
		"colossus_endo":
			_endo_arm(im, w, h)
		"colossus":
			_box(im, 0, 0, w, h - 2, shirt)
			_box(im, 0, 0, w, 6, STEEL.darkened(0.25))
			for k in 3:                                                  # шипы на наплечнике
				_px(im, 1 + k * 3, 0, Color(0.85, 0.82, 0.75))
			for y in range(8, h - 8, 3):                                 # цепь на руке
				_px(im, w / 2, y, Color(0.55, 0.55, 0.6))
			_box(im, 0, h - 7, w, 7, STEEL.darkened(0.45))    # ствол-пушка
			im.fill_rect(Rect2i(2, h - 2, w - 4, 2), DARK)
		"treant":      # ветка с листьями
			_box(im, 1, 0, w - 2, h, skin)
			for k in 4:
				im.fill_rect(Rect2i(2, 3 + k * 6, 1, 3), skin.darkened(0.35))
			for y in [8, 16, 23]:
				_px(im, 0, y, spec.get("leaf", Color(0.3, 0.6, 0.25)))
				_px(im, w - 1, y + 2, spec.get("leaf", Color(0.3, 0.6, 0.25)))
		"skeleton":
			if spec.has("robe"):
				_box(im, 0, 0, w, h - 2, spec["robe"])
				im.fill_rect(Rect2i(w / 2 - 1, h - 2, 2, 2), BONE)
			else:
				im.fill_rect(Rect2i(w / 2 - 1, 0, 2, h), BONE)
				im.fill_rect(Rect2i(w / 2 - 1, h / 2, 2, 1), BONE.darkened(0.3))
				im.fill_rect(Rect2i(0, h - 2, w, 2), BONE)
				if spec.has("jacket"):
					_box(im, 0, 0, w, h / 2 + 1, spec["jacket"])
				if spec.has("armor_plate"):
					_box(im, 0, 0, w, 3, spec["armor_plate"])
		"golem":
			_box(im, 0, 0, w, h, skin)
			_box(im, 0, 0, w, 4, skin.darkened(0.15))
			for k in 2:
				_px(im, 1, 5 + k * 3, skin.darkened(0.35))
			var gc: Color = spec.get("gem", Color(0.9, 0.15, 0.25))
			_box(im, 0, h - 4, w, 4, gc)                       # рубиновые костяшки
			_px(im, 1, h - 3, gc.lightened(0.5))
		"fur":
			_box(im, 0, 0, w, h, shirt)
			for y in range(1, h - 3, 2):
				_px(im, (y * 5) % w, y, shirt.darkened(0.15))
			for k in 3:
				_px(im, k * 2, h - 1, Color(0.30, 0.30, 0.36))                    # когти
		"jotun":
			_box(im, 0, 0, w, h, skin)
			_crystal_box(im, 0, 0, w, 6, spec["armor_plate"])               # ледяной наплечник
			for k in 3:
				_px(im, 1 + k * 3, 0, Color(1, 1, 1))
			_box(im, 0, h - 7, w, 4, Color(spec["pants"]).darkened(0.05))   # меховой наруч
		"dark_plate":
			_box(im, 0, 0, w, h, shirt)
			_box(im, 0, 0, w, 6, spec.get("pauldron", shirt.lightened(0.1)))   # наплечник
			for k in 3:                                                      # шипы на наплечнике
				im.fill_rect(Rect2i(k * (w - 1) / 2, -0, 1, 2), Color(0.70, 0.68, 0.75))
			for y in range(7, h - 4, 3):
				_px(im, (y * 3) % w, y, spec.get("vein", Color(0.55, 0.52, 0.60)))
			_box(im, 0, h - 5, w, 5, shirt.darkened(0.25))                   # латная перчатка
		"storm":
			_box(im, 0, 0, w, h - 3, spec["robe"])
			im.fill_rect(Rect2i(0, h - 8, w, 2), Color(0.72, 0.86, 1.0))     # светящийся наруч
			_box(im, 0, h - 3, w, 3, skin)
		"crystal":
			_crystal_box(im, 0, 0, w, h, shirt)
			if spec.has("armor_plate"):
				_crystal_box(im, 0, 0, w, 4, spec["armor_plate"])
		"storm_monk":  # широкий рукав с золотой каймой, медный наруч
			_box(im, 0, 0, w, h - 3, shirt)
			im.fill_rect(Rect2i(0, h - 5, w, 1), spec.get("trim", Color(0.95, 0.78, 0.32)))
			_box(im, 0, h - 3, w, 3, skin)
			im.fill_rect(Rect2i(0, h - 3, w, 1), Color(0.78, 0.48, 0.24))
		_:
			if spec.get("bare_arms", false) or spec.get("bare_chest", false):
				_box(im, 0, 0, w, h, skin)
				if spec.has("armor_plate"):
					_box(im, 0, 0, w, 3, spec["armor_plate"])
				im.fill_rect(Rect2i(0, h - 5, w, 2), Color(0.45, 0.28, 0.15))   # наруч
			elif spec.get("bare_chest_story", false):
				_box(im, 0, 0, w, h, skin)
				_box(im, 0, h - 3, w, 3, spec.get("gloves", skin))
			else:
				_box(im, 0, 0, w, h, shirt.darkened(0.12) if spec.get("hat", "") == "story" else shirt)   # рукав темнее рубахи
				_box(im, 0, h - 3, w, 3, spec.get("gloves", skin))
				if spec.has("gloves"):
					im.fill_rect(Rect2i(0, h - 4, w, 1), Color(spec["gloves"]).lightened(0.15))   # раструб перчатки
				if spec.get("chain", false):  # кольчужный рукав
					var cc: Color = spec["armor_plate"]
					_box(im, 0, 0, w, h / 2, cc)
					for yy in range(1, h / 2 - 1):
						for xx in range(1, w - 1):
							if (xx + yy) % 2 == 0:
								_px(im, xx, yy, cc.darkened(0.25))
				if spec.has("sode"):          # наплечник самурая из пластин
					var sc: Color = spec["sode"]
					_box(im, 0, 0, w, 5, sc)
					im.fill_rect(Rect2i(0, 2, w, 1), sc.darkened(0.4))
					im.fill_rect(Rect2i(0, h - 6, w, 2), Color(0.2, 0.17, 0.2))     # наруч
				if spec.get("camo", false):
					_px(im, 1, 3, shirt.darkened(0.25))
					_px(im, 2, 6, shirt.lightened(0.15))
	if spec.has("arm_mark"):
		# облик: по руке бегут жилы лавы / руны бездны / золотые узоры
		var am: Color = spec["arm_mark"]
		for y in range(5, h - 2):
			if (y * 3) % 5 < 2:
				_px(im, (y / 2) % w, y, am)
		_px(im, w / 2, h - 3, am.lightened(0.3))
	return im

func _draw_torso(w: int, h: int) -> Image:
	var im := _img(w, h)
	var shirt: Color = spec["shirt"]
	if spec.has("gi"):
		# Недопонятый гений: ги с тёмно-красными лацканами, пояс из Ethernet-кабеля,
		# бейдж охраны на шнурке и зелёные «строчки терминала» по полам
		var trim: Color = spec["gi_trim"]
		var cab: Color = spec["cable"]
		_box(im, 0, 0, w, h, shirt)
		for y in h - 3:                                                        # запах ги крест-накрест
			_px(im, clampi(1 + y, 0, w - 1), y, trim)
			_px(im, clampi(w - 2 - y, 0, w - 1), y, trim)
			_px(im, clampi(2 + y, 0, w - 1), y, trim.lightened(0.15))
		im.fill_rect(Rect2i(0, h - 3, w, 2), trim)                            # пояс
		for x in range(0, w, 2):
			_px(im, x, h - 2, cab)                                              # кабель вплетён в пояс
		im.fill_rect(Rect2i(w / 2 - 1, h - 3, 2, 3), cab.lightened(0.2))      # узел-разъём RJ-45
		_px(im, 3, 1, Color(0.85, 0.85, 0.9))                                 # шнурок бейджа
		_px(im, 3, 2, Color(0.85, 0.85, 0.9))
		im.fill_rect(Rect2i(2, 3, 3, 4), Color(0.96, 0.96, 0.98))             # бейдж «ОХРАНА»
		im.fill_rect(Rect2i(2, 3, 3, 1), Color(0.85, 0.15, 0.20))
		_px(im, 3, 5, Color(0.3, 0.3, 0.35))
		for k in 4:                                                            # безумие: строчки терминала
			_px(im, w - 3 - (k % 2) * 2, 5 + k, Color(0.40, 1.0, 0.45))
		return im
	if spec.get("suit", false):
		# Почти легенда: белая грудная броня с оранжевыми полосами по бокам, тёмный пояс,
		# голубое ядро костюма и серебряная медаль «2» на ленте
		var sp: Array = spec.get("suit_pal", [shirt, Color(1.0, 0.52, 0.14), Color(0.2, 0.22, 0.28), Color(0.3, 0.9, 1.0), Color(0.8, 0.82, 0.88)])
		_box(im, 0, 0, w, h, sp[2])
		_box(im, 1, 0, w - 2, h - 3, sp[0])                                    # нагрудник
		im.fill_rect(Rect2i(1, 2, 1, h - 6), sp[1])                            # оранжевые полосы
		im.fill_rect(Rect2i(w - 2, 2, 1, h - 6), sp[1])
		im.fill_rect(Rect2i(0, h - 3, w, 2), sp[2])                            # пояс
		_px(im, w / 2, h - 3, sp[1])                                            # пряжка
		im.fill_rect(Rect2i(w / 2 - 1, h - 6, 2, 2), sp[3])                    # ядро костюма
		_px(im, 3, 1, sp[1])                                                    # лента медали
		_px(im, 4, 2, sp[1])
		im.fill_rect(Rect2i(3, 3, 3, 3), sp[4])                                # медаль «2»
		_px(im, 4, 4, sp[4].darkened(0.45))
		_px(im, 3, 3, sp[4].lightened(0.3))
		for x in range(3, w - 3, 3):                                           # пластины пресса
			_px(im, x, h - 5, sp[0].darkened(0.18))
		_px(im, w / 2 - 2, h - 6, sp[3].darkened(0.2))                        # светящиеся линии от ядра
		_px(im, w / 2 + 1, h - 6, sp[3].darkened(0.2))
		return im
	if spec.get("hoodie", false):
		# DJ Клима: чёрная кофта с длинными рукавами, на груди — нота, на шее — цепочка с кулоном-пластинкой
		var nc: Color = spec.get("note", Color(0.96, 0.96, 1.0))
		var ng: Color = spec.get("note_glow", Color(0.30, 0.90, 1.0))
		var ch: Color = spec.get("chain", Color(1.0, 0.84, 0.40))
		_box(im, 0, 0, w, h, shirt)
		im.fill_rect(Rect2i(4, 0, w - 8, 1), shirt.lightened(0.12))           # ворот
		for k in 4:                                                            # цепочка V-образно
			_px(im, 4 + k, k, ch if k % 2 == 0 else ch.darkened(0.25))
			_px(im, w - 5 - k, k, ch if k % 2 == 0 else ch.darkened(0.25))
		_px(im, w / 2 - 1, 4, ch)                                             # кулон-пластинка
		_px(im, w / 2, 4, ch.darkened(0.3))
		var nx := w / 2 - 2                                                    # нота ♪: головка, штиль, флажок
		im.fill_rect(Rect2i(nx, h - 5, 3, 2), nc)
		im.fill_rect(Rect2i(nx + 2, 5, 1, h - 9), nc)
		_px(im, nx + 3, 5, nc)
		_px(im, nx + 4, 6, nc)
		_px(im, nx + 4, 7, ng)
		_px(im, nx - 1, h - 4, ng.darkened(0.2))                               # неоновый отблеск
		im.fill_rect(Rect2i(1, h - 2, w - 2, 1), shirt.lightened(0.10))       # резинка кофты
		for sx in [w / 2 - 3, w / 2 + 2]:                                      # шнурки капюшона
			_px(im, sx, 1, Color(0.92, 0.92, 0.95))
			_px(im, sx, 2, Color(0.92, 0.92, 0.95))
			_px(im, sx, 3, Color(0.75, 0.75, 0.80))
		im.fill_rect(Rect2i(2, h - 5, 3, 2), shirt.lightened(0.07))           # карман-кенгуру
		im.fill_rect(Rect2i(w - 5, h - 5, 3, 2), shirt.lightened(0.07))
		return im
	if spec.has("scarf"):
		# Летописец: мантия писаря, на шее — бумажный шарф со строчками, пуговицы, пояс с чернильницей
		var sc: Color = spec["scarf"]
		var ink: Color = spec.get("scarf_ink", Color(0.16, 0.24, 0.55))
		var tr: Color = spec.get("trim", Color(1.0, 0.82, 0.38))
		_box(im, 0, 0, w, h, shirt)
		im.fill_rect(Rect2i(1, 0, w - 2, 2), sc)                              # шарф вокруг шеи
		im.fill_rect(Rect2i(w - 4, 2, 3, h - 4), sc)                          # конец шарфа свисает спереди
		for y in range(3, h - 3, 2):
			im.fill_rect(Rect2i(w - 4, y, 2, 1), ink)                         # строчки на шарфе
		_px(im, w - 2, h - 3, sc.darkened(0.15))
		for y in range(3, h - 5, 3):
			_px(im, w / 2 - 1, y, tr.darkened(0.15))                          # пуговицы мантии
		im.fill_rect(Rect2i(0, h - 4, w, 1), tr)                              # пояс
		im.fill_rect(Rect2i(1, h - 7, 3, 3), ink.darkened(0.25))              # чернильница на поясе
		_px(im, 2, h - 8, tr)
		_px(im, 2, h - 6, ink.lightened(0.45))
		return im
	if spec.has("coat"):
		# Главный: распахнутое чёрное пальто со светящимся фиолетовым контуром, белая футболка
		var coat: Color = spec["coat"]
		var glow: Color = spec["coat_glow"]
		_box(im, 0, 0, w, h, coat)
		im.fill_rect(Rect2i(w / 2 - 2, 0, 4, h - 1), shirt)                  # футболка
		_px(im, w / 2, 3, glow.lightened(0.2))                                # принт на футболке
		_px(im, w / 2 - 1, 4, glow)
		for y in h:                                                           # лацканы и края — светятся
			_px(im, w / 2 - 3, y, glow)
			_px(im, w / 2 + 2, y, glow)
		im.fill_rect(Rect2i(0, 0, 1, h), glow.darkened(0.25))
		im.fill_rect(Rect2i(w - 1, 0, 1, h), glow.darkened(0.25))
		im.fill_rect(Rect2i(0, h - 1, w, 1), glow)                           # подол
		im.fill_rect(Rect2i(1, 0, w - 2, 1), coat.lightened(0.15))           # плечи
		im.fill_rect(Rect2i(1, h - 4, 3, 1), glow.darkened(0.3))             # карманы
		im.fill_rect(Rect2i(w - 4, h - 4, 3, 1), glow.darkened(0.3))
		return im
	match _style():
		"ninja":       # короткий топ с перекрёстными лентами, голый живот, пояс из толстой верёвки
			var sk: Color = spec["skin"]
			var wr2: Color = spec.get("wrap", Color(0.45, 0.56, 0.32))
			var rc2: Color = spec.get("rope", Color(0.46, 0.30, 0.18))
			_box(im, 0, 0, w, h, sk)
			_box(im, 0, 0, w, h / 2 + 1, shirt)
			for i in h / 2 + 1:                                               # ленты крест-накрест
				_px(im, i % w, i, wr2)
				_px(im, (w - 1 - i) % w, i, wr2)
			_px(im, w / 2, h / 2 + 3, sk.darkened(0.2))                        # пупок
			_px(im, w / 2 - 2, h / 2 + 2, sk.darkened(0.08))
			_box(im, 0, h - 3, w, 3, rc2)                                      # верёвка
			for x in range(0, w, 2):
				_px(im, x, h - 2, rc2.lightened(0.2))
			_px(im, w - 2, h - 1, rc2.darkened(0.3))
		"gladiator":   # голый торс, ремни крест-накрест, кожаная юбка
			_box(im, 0, 0, w, h, spec["skin"])
			for i in h - 4:
				_px(im, 1 + i, 1 + i, Color(0.45, 0.28, 0.15))
			_box(im, 0, h - 5, w, 5, Color(0.55, 0.32, 0.18))
			for x in range(2, w - 1, 3):
				im.fill_rect(Rect2i(x, h - 4, 1, 4), Color(0.4, 0.22, 0.12))
			im.fill_rect(Rect2i(1, h - 6, w - 2, 1), BRONZE)
		"colossus_endo":
			_endo_torso(im, w, h)
		"colossus":    # нагрудник со светящимся ядром
			_box(im, 0, 0, w, h, shirt)
			_box(im, 2, 2, w - 4, h - 6, STEEL.darkened(0.35))
			_box(im, w / 2 - 3, 6, 6, 6, Color(1.0, 0.3, 0.2))
			im.fill_rect(Rect2i(w / 2 - 1, 8, 2, 2), Color(1.0, 0.85, 0.5))
			for x in range(3, w - 3, 4):
				_px(im, x, h - 3, STEEL)
		"chief":       # жилет из шкуры, ожерелье из клыков
			_box(im, 0, 0, w, h, spec["skin"])
			_box(im, 0, 3, w, h - 3, shirt)
			for x in range(2, w - 2, 2):
				_px(im, x, 3, Color(0.95, 0.92, 0.8))
			im.fill_rect(Rect2i(0, h - 3, w, 1), Color(0.8, 0.2, 0.15))
		"treant":      # ствол: кора, мох, дупло
			_box(im, 0, 0, w, h, spec["skin"])
			for k in 5:
				im.fill_rect(Rect2i(3 + k * 4, 2, 1, h - 4), Color(spec["skin"]).darkened(0.3))
			_box(im, w / 2 - 3, h / 2 - 2, 6, 7, Color(0.12, 0.08, 0.05))
			for x in range(0, w, 2):
				_px(im, x, 0, spec.get("leaf", Color(0.3, 0.6, 0.25)))
				_px(im, x + 1, 1, spec.get("leaf", Color(0.3, 0.6, 0.25)))
		"skeleton":
			if spec.has("robe"):
				_box(im, 0, 0, w, h, spec["robe"])
				im.fill_rect(Rect2i(w / 2, 1, 1, h - 2), Color(spec["robe"]).lightened(0.15))
				for x in range(1, w - 1, 3):
					_px(im, x, 2, BONE)                  # бусы из позвонков
				return im
			im.fill_rect(Rect2i(w / 2 - 1, 0, 2, h), BONE)               # позвоночник
			for k in 4:                                                  # рёбра
				var ry := 1 + k * 2
				im.fill_rect(Rect2i(1, ry, w - 2, 1), BONE.darkened(0.05 * k))
				_px(im, 0, ry + 1, BONE.darkened(0.2))
				_px(im, w - 1, ry + 1, BONE.darkened(0.2))
			im.fill_rect(Rect2i(1, h - 3, w - 2, 3), BONE.darkened(0.1))  # таз
			im.fill_rect(Rect2i(w / 2 - 1, h - 2, 2, 1), Color(0, 0, 0, 0))
			if spec.has("jacket"):                                        # кожаная куртка
				var jc: Color = spec["jacket"]
				_box(im, 0, 0, 3, h - 3, jc)
				_box(im, w - 3, 0, 3, h - 3, jc)
				im.fill_rect(Rect2i(0, 0, w, 2), jc)
			if spec.has("armor_plate"):                                   # ржавый доспех / латы короля
				var ac: Color = spec["armor_plate"]
				_box(im, 1, 0, w - 2, h * 2 / 3, ac)
				for i in 5:
					_px(im, 2 + (i * 7) % (w - 4), 1 + (i * 3) % 6, ac.lightened(0.25))
				if kind == "skeleton_king":
					_box(im, w / 2 - 3, 2, 6, 5, Color(0.85, 0.7, 0.25))
					im.fill_rect(Rect2i(w / 2 - 1, 3, 2, 3), Color(0.8, 0.15, 0.15))
		"golem":       # глыба с рубиновым сердцем
			var rc: Color = spec["skin"]
			_box(im, 0, 0, w, h, rc)
			for k in 4:
				im.fill_rect(Rect2i(1 + (k * 5) % (w - 2), 2 + k * 2, 3, 1), rc.darkened(0.3))
			var gc2: Color = spec.get("gem", Color(0.9, 0.15, 0.25))
			_box(im, w / 2 - 3, h / 2 - 3, 6, 6, gc2)
			_px(im, w / 2 - 2, h / 2 - 2, gc2.lightened(0.6))
			for x in [1, w - 3]:
				_box(im, x, 0, 2, 3, gc2.darkened(0.2))         # кристаллы на плечах
		"fur":         # косматая шкура, тёмная грудь
			_box(im, 0, 0, w, h, shirt)
			_box(im, w / 2 - 3, 3, 7, h - 6, shirt.darkened(0.12))
			for k in 10:
				_px(im, (k * 7) % w, (k * 5) % h, shirt.darkened(0.18))
			for x in range(0, w, 3):
				_px(im, x, h - 1, shirt.darkened(0.25))
		"jotun":       # голый синий торс, ледяные пластины на плечах, меховой пояс
			_box(im, 0, 0, w, h, spec["skin"])
			_px(im, w / 2 - 3, 5, Color(spec["skin"]).darkened(0.2))
			_px(im, w / 2 + 3, 5, Color(spec["skin"]).darkened(0.2))
			for k in 3:
				im.fill_rect(Rect2i(w / 2 - 3, 9 + k * 3, 7, 1), Color(spec["skin"]).darkened(0.12))
			_crystal_box(im, 0, 0, 7, 6, spec["armor_plate"])
			_crystal_box(im, w - 7, 0, 7, 6, spec["armor_plate"])
			_box(im, 0, h - 5, w, 5, spec["pants"])
			for x in range(1, w, 2):
				_px(im, x, h - 5, Color(0.92, 0.94, 0.96))
			_box(im, w / 2 - 2, h - 5, 4, 4, Color(0.82, 0.93, 1.0))        # ледяная пряжка
		"dark_plate":  # чёрный нагрудник с трещинами-прожилками; у Лорда — пылающий камень
			_box(im, 0, 0, w, h, shirt)
			_box(im, 1, 1, w - 2, h - 4, shirt.lightened(0.06))
			var vein: Color = spec.get("vein", Color(0.62, 0.60, 0.68))
			var q := Vector2i(2, 2)
			for i in w + h:
				_px(im, q.x, q.y, vein)
				q += Vector2i(1 if i % 3 != 2 else 0, 1 if i % 2 == 0 else 0)
				if q.x >= w - 2 or q.y >= h - 4:
					q = Vector2i(2 + (i * 5) % maxi(1, w - 6), 2)
			im.fill_rect(Rect2i(w / 2, 1, 1, h - 4), shirt.darkened(0.3))
			if spec.has("gem"):
				var gc4: Color = spec["gem"]
				_box(im, w / 2 - 2, 3, 5, 5, gc4)
				_px(im, w / 2 - 1, 4, gc4.lightened(0.6))
				for d in [Vector2i(-3, 5), Vector2i(3, 5), Vector2i(0, 9), Vector2i(0, 1)]:
					_px(im, w / 2 + d.x, 0 + d.y, Color(0.75, 0.72, 0.80))
			_box(im, 0, h - 3, w, 3, shirt.darkened(0.25))
		"storm":       # мантия бури: светлые зигзаги молний, пояс со сферой
			var rc4: Color = spec["robe"]
			_box(im, 0, 0, w, h, rc4)
			_box(im, 2, 0, w - 4, h / 2, shirt)
			var zx := 2
			for y in range(1, h - 2):
				zx += 1 if (y / 2) % 2 == 0 else -1
				_px(im, clampi(zx, 1, w - 2), y, Color(0.80, 0.92, 1.0))
			im.fill_rect(Rect2i(0, h / 2 + 2, w, 2), Color(0.55, 0.45, 0.30))
			_box(im, w / 2 - 2, h / 2 + 1, 4, 4, Color(0.80, 0.92, 1.0))
		"storm_monk":  # одежда послушницы: запах с золотой каймой, белый пояс с узлом-молнией
			var tr: Color = spec.get("trim", Color(0.95, 0.78, 0.32))
			_box(im, 0, 0, w, h, shirt)
			for y in range(0, h - 4):
				var cx := 1 + y * (w - 2) / (h - 3)
				_px(im, clampi(cx, 0, w - 1), y, tr)
			for y in range(0, (h - 4) / 2):
				_px(im, clampi(w - 2 - y, 0, w - 1), y, tr.darkened(0.15))
			im.fill_rect(Rect2i(0, h - 4, w, 2), Color(0.92, 0.93, 0.98))
			_px(im, w / 2 - 1, h - 4, Color(0.45, 0.65, 1.0))
			_px(im, w / 2, h - 3, Color(0.45, 0.65, 1.0))
			_px(im, w / 2 - 1, h - 2, Color(0.95, 0.85, 0.40))
			im.fill_rect(Rect2i(0, h - 2, w, 2), shirt.darkened(0.2))
		"crystal":     # кристальный доспех / платье
			_crystal_box(im, 0, 0, w, h, shirt)
			if spec.has("robe"):
				_crystal_box(im, 1, h / 2, w - 2, h / 2, spec["robe"])
			im.fill_rect(Rect2i(w / 2 - 1, 2, 2, 3), Color(1, 1, 1, 0.9))     # сияющий камень на груди
			_px(im, w / 2, 3, spec.get("eye_glow", Color(0.6, 0.9, 1.0)))
		_:
			if spec.get("bare_chest", false):
				_box(im, 0, 0, w, h, spec["skin"])
				_px(im, w / 2 - 2, 3, Color(spec["skin"]).darkened(0.2))
				_px(im, w / 2 + 2, 3, Color(spec["skin"]).darkened(0.2))
				im.fill_rect(Rect2i(0, h - 3, w, 3), Color(0.45, 0.28, 0.15))
				if kind == "retiarius":       # наплечник-манника на одном плече
					_box(im, w - 4, 0, 4, 4, BRONZE)
				return im
			_box(im, 0, 0, w, h, shirt)
			if spec.has("apron"):           # кожаный фартук кузнеца на лямках
				var apc: Color = spec["apron"]
				_box(im, 2, 3, w - 4, h - 3, apc)
				im.fill_rect(Rect2i(3, 0, 1, 3), apc.darkened(0.2))
				im.fill_rect(Rect2i(w - 4, 0, 1, 3), apc.darkened(0.2))
				_box(im, w / 2 - 2, h / 2, 4, 3, apc.darkened(0.25))      # карман
				for k in 3:
					_px(im, 3 + k * 4, h - 2, Color(0.2, 0.18, 0.16))   # подпалины
				return im
			if spec.get("camo", false):     # разгрузка с подсумками
				var vc: Color = spec["armor_plate"]
				_box(im, 1, 1, w - 2, h - 3, vc)
				for x in [2, w / 2 + 1]:
					_box(im, x, h / 2, 3, 3, vc.lightened(0.2))
				im.fill_rect(Rect2i(w / 2, 0, 1, h - 2), vc.darkened(0.3))
				im.fill_rect(Rect2i(1, h - 3, w - 2, 1), Color(0.15, 0.13, 0.1))
				return im
			if spec.get("bare_chest_story", false):   # без рубахи
				_box(im, 0, 0, w, h, spec["skin"])
				if spec.get("female", false):
					_box(im, 0, 2, w, 4, Color(0.75, 0.70, 0.60))
				im.fill_rect(Rect2i(0, h - 3, w, 3), spec["pants"])
				return im
			if spec.get("chain", false):    # кольчуга: плетение колечками, пояс
				var ch: Color = spec["armor_plate"]
				_box(im, 1, 0, w - 2, h - 2, ch)
				for yy in range(1, h - 3):
					for xx in range(2, w - 2):
						if (xx + yy) % 2 == 0:
							_px(im, xx, yy, ch.darkened(0.25))
						elif yy % 3 == 0:
							_px(im, xx, yy, ch.lightened(0.2))
				im.fill_rect(Rect2i(0, h - 3, w, 2), Color(0.30, 0.20, 0.12))
				_px(im, w / 2, h - 3, Color(0.85, 0.75, 0.35))
				return im
			if spec.has("sode"):            # доспех самурая: пластины со шнуровкой
				var ac3: Color = spec["armor_plate"]
				_box(im, 1, 1, w - 2, h - 3, ac3)
				for y in range(2, h - 3, 2):
					im.fill_rect(Rect2i(2, y, w - 4, 1), ac3.lightened(0.15))
					_px(im, 2 + (y * 3) % (w - 4), y, Color(0.8, 0.15, 0.15))
				im.fill_rect(Rect2i(0, h - 3, w, 2), Color(0.85, 0.75, 0.3))      # пояс-оби
				return im
			if spec.has("armor_plate"):     # лёгкий кожаный доспех
				var ac2: Color = spec["armor_plate"]
				_box(im, 1, 1, w - 2, h - 4, ac2)
				for x in range(2, w - 2, 3):
					im.fill_rect(Rect2i(x, 2, 1, h - 6), ac2.darkened(0.2))
			im.fill_rect(Rect2i(1, h - 3, w - 2, 1), Color(0.25, 0.18, 0.12))   # ремень
			_px(im, w / 2, h - 3, Color(0.9, 0.8, 0.3))
			if spec.get("armor", false):
				_box(im, 2, 1, w - 4, h - 5, shirt.darkened(0.3))
				_box(im, 0, 0, 4, 4, shirt.darkened(0.4))
				_box(im, w - 4, 0, 4, 4, shirt.darkened(0.4))
			elif w >= 10:
				im.fill_rect(Rect2i(w / 2, 1, 1, h - 4), shirt.darkened(0.15))   # застёжка
	return im

func _draw_head(w: int, h: int) -> Image:
	var pad := _head_pad()
	var im := _img(w + int(pad.x) * 2, h + int(pad.y))
	var x0 := int(pad.x)
	var y0 := int(pad.y)
	var skin: Color = spec["skin"]
	var ey := y0 + h / 2 - 1
	var ex := x0 + w - 3
	match _style():
		"gladiator":   # бронзовый шлем с красным гребнем
			_box(im, x0, y0, w, h, BRONZE)
			im.fill_rect(Rect2i(x0 + w - 5, y0 + 4, 4, 5), skin)     # лицо в прорези
			_px(im, ex, ey + 1, DARK)
			im.fill_rect(Rect2i(x0 + w - 5, y0 + 3, 5, 1), BRONZE.darkened(0.3))
			for i in w + 2:
				var hh := int(5.0 * sin(PI * i / (w + 1.0)))
				im.fill_rect(Rect2i(x0 - 1 + i, y0 - hh, 1, hh), Color(0.85, 0.12, 0.12))
		"colossus_endo":
			_endo_head(im, x0, y0, w, h)
		"colossus":    # рогатый шлем, красный глаз
			_box(im, x0, y0, w, h, Color(0.30, 0.26, 0.34))
			_box(im, x0 + 1, y0 + h / 2 - 2, w - 2, 4, DARK)
			im.fill_rect(Rect2i(ex - 1, ey, 3, 2), Color(1.0, 0.25, 0.2))
			for s in [0, 1]:
				var bx := x0 + 1 if s == 0 else x0 + w - 3
				for k in 12:
					var hx := bx + (-k / 2 if s == 0 else k / 2)
					im.fill_rect(Rect2i(hx, y0 - k, 2, 1), Color(0.9, 0.86, 0.76).darkened(0.03 * k))
			for x in range(x0 + w - 7, x0 + w - 1, 2):                     # решётка-пасть
				im.fill_rect(Rect2i(x, y0 + h - 4, 1, 3), Color(1.0, 0.45, 0.2))
		"chief":       # голова гоблина, клыки, корона из перьев
			_box(im, x0, y0, w, h, skin)
			_px(im, ex, ey, DARK)
			_px(im, ex + 1, ey, DARK)
			im.fill_rect(Rect2i(x0 + w - 4, y0 + h - 3, 1, 2), Color(0.95, 0.92, 0.8))
			im.fill_rect(Rect2i(x0 + w - 2, y0 + h - 3, 1, 2), Color(0.95, 0.92, 0.8))
			_ears(im, x0, y0, w, skin)
			var cols := [Color(0.9, 0.2, 0.15), Color(1.0, 0.8, 0.2), Color(0.2, 0.6, 0.9)]
			for k in 5:
				var fx := x0 + 1 + k * (w - 2) / 4
				var fh := 9 - absi(k - 2) * 2
				im.fill_rect(Rect2i(fx, y0 - fh, 2, fh), cols[k % 3])
			im.fill_rect(Rect2i(x0, y0, w, 2), Color(0.55, 0.3, 0.12))
		"treant":      # лицо в коре: светящиеся глаза, дупло-рот
			_box(im, x0, y0, w, h, skin)
			for k in 4:
				im.fill_rect(Rect2i(x0 + 2 + k * 4, y0 + 1, 1, h - 2), skin.darkened(0.3))
			im.fill_rect(Rect2i(x0 + w - 7, y0 + 4, 2, 2), spec.get("eye_col", Color(0.6, 1.0, 0.35)))
			im.fill_rect(Rect2i(x0 + w - 3, y0 + 4, 2, 2), spec.get("eye_col", Color(0.6, 1.0, 0.35)))
			_box(im, x0 + w - 7, y0 + 8, 5, 4, Color(0.1, 0.06, 0.04), false)
		"skeleton":    # череп: глазницы, нос, зубы
			_box(im, x0, y0, w, h - 2, BONE)
			_box(im, x0 + 2, y0 + h - 3, w - 3, 3, BONE.darkened(0.05))      # челюсть
			for x in range(x0 + 3, x0 + w - 1, 2):
				_px(im, x, y0 + h - 3, DARK)
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 3), Color(0.08, 0.06, 0.06))
			im.fill_rect(Rect2i(ex - 5, ey - 1, 2, 3), Color(0.08, 0.06, 0.06))
			_px(im, ex - 2, ey + 2, Color(0.08, 0.06, 0.06))
			if not spec.has("eye_glow"):
				_px(im, ex, ey, Color(0.9, 0.95, 1.0))
			_hat(im, x0, y0, w, h, ex, ey)
		"golem":       # маленькая каменная голова, глаза-угли
			_box(im, x0, y0 + 2, w, h - 2, skin)
			im.fill_rect(Rect2i(x0, y0 + 2, w, 2), skin.darkened(0.2))
			im.fill_rect(Rect2i(ex - 1, ey, 3, 2), Color(0.1, 0.05, 0.05))
			var gc3: Color = spec.get("gem", Color(0.9, 0.15, 0.25))
			for k in 3:
				_box(im, x0 + 1 + k * 3, y0 - 1 - (k % 2), 2, 3, gc3)
		"crystal":     # лицо из кристалла, светящиеся глаза
			_crystal_box(im, x0, y0, w, h, skin)
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(0.95, 1.0, 1.0))
			_hat(im, x0, y0, w, h, ex, ey)
		_:
			_box(im, x0, y0, w, h, skin)
			var es := 2 if w >= 10 else 1
			im.fill_rect(Rect2i(ex, ey, es, es), DARK)
			if spec.has("eye") and es == 2:
				_px(im, ex, ey, spec["eye"])                                # радужка своего цвета
				_px(im, ex, ey + 1, spec["eye"])
			_px(im, x0 + w - 3, y0 + h - 3, skin.darkened(0.35))           # рот
			_hat(im, x0, y0, w, h, ex, ey)
	return im

func _ears(im: Image, x0: int, y0: int, w: int, skin: Color) -> void:
	for k in 4:
		im.fill_rect(Rect2i(x0 - 1 - k, y0 + 2 + k / 2, 1, 2), skin.lightened(0.05))
		im.fill_rect(Rect2i(x0 + w + k, y0 + 2 + k / 2, 1, 2), skin.lightened(0.05))

# Головной убор и украшение облика поверх него (языки пламени / осколки бездны над головой)
func _hat(im: Image, x0: int, y0: int, w: int, h: int, ex: int, ey: int) -> void:
	_hat_base(im, x0, y0, w, h, ex, ey)
	match spec.get("ornament", ""):
		"flames":
			for k in range(-1, w + 2, 2):
				var fh := 2 + (k * 7 + 21) % 4
				for j in fh:
					_px(im, x0 + k, y0 - 4 - j, Color(1.0, 0.86, 0.40) if j >= fh - 1 else Color(1.0, 0.48, 0.12))
		"frost":         # ледяная серия: над головой парят кристаллы льда, в середине — снежинка
			for c in [[1, -6], [w - 1, -6]]:
				var fx: int = x0 + int(c[0])
				var fy: int = y0 + int(c[1])
				_px(im, fx, fy - 1, Color(0.95, 1.0, 1.0))
				_px(im, fx, fy, Color(0.55, 0.86, 1.0))
				_px(im, fx, fy + 1, Color(0.35, 0.65, 0.95))
			var sx := x0 + w / 2
			var sy := y0 - 9
			for d in [Vector2i(0, -2), Vector2i(0, -1), Vector2i(0, 1), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0)]:
				_px(im, sx + d.x, sy + d.y, Color(0.80, 0.95, 1.0))
			for d in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
				_px(im, sx + d.x, sy + d.y, Color(0.45, 0.80, 1.0, 0.8))
			_px(im, sx, sy, Color(1, 1, 1))
		"shards":
			for c in [[1, -7], [w / 2, -10], [w - 1, -7]]:
				var cx: int = x0 + int(c[0])
				var cy: int = y0 + int(c[1])
				_px(im, cx, cy - 1, Color(0.95, 0.85, 1.0))
				im.fill_rect(Rect2i(cx - 1, cy, 3, 1), Color(0.72, 0.40, 1.0))
				_px(im, cx, cy + 1, Color(0.45, 0.22, 0.70))

func _hat_base(im: Image, x0: int, y0: int, w: int, h: int, ex: int, ey: int) -> void:
	var shirt: Color = spec["shirt"]
	var skin: Color = spec["skin"]
	match spec["hat"]:
		"story":
			_story_head(im, x0, y0, w, h, ex, ey)
		"kobold", "kobold_goggles", "kobold_hood":
			_kobold_head(im, x0, y0, w, h, ex, ey)
		"crystal_crown":   # корона из кристальных шипов
			var cc: Color = spec.get("crown", Color(0.75, 0.9, 1.0))
			for i in 5:
				var cxx := x0 + i * (w - 1) / 4
				var chh := 4 + (4 if i == 2 else (2 if i % 2 == 1 else 0))
				for yy in chh:
					var hw := 1 if yy < chh - 2 else 0
					im.fill_rect(Rect2i(cxx - hw, y0 - yy, hw * 2 + 1, 1), cc.lightened(0.15 * (yy % 2)))
			im.fill_rect(Rect2i(x0, y0, w, 1), cc)
		"crystal_helm":    # гранёный шлем стража
			_crystal_box(im, x0 - 1, y0 - 2, w + 2, h / 2 + 2, spec.get("crown", Color(0.6, 0.8, 1.0)))
			im.fill_rect(Rect2i(x0 + w - 5, ey, 5, 1), Color(0.05, 0.05, 0.1))
		"prism_circlet":   # светлые волосы и обруч с призмой
			var hc := Color(0.92, 0.9, 0.98)
			_box(im, x0, y0 - 1, w, 3, hc, false)
			im.fill_rect(Rect2i(x0 - 1, y0, 3, h - 2), hc)
			for k in 5:
				_px(im, x0 - 2 - k / 3, y0 + 2 + k, hc.darkened(0.08 * (k % 2)))
			im.fill_rect(Rect2i(x0, y0 + 1, w, 1), Color(0.75, 0.75, 0.85))
			_box(im, x0 + w / 2 - 1, y0 - 1, 3, 3, Color(0.75, 0.55, 1.0), false)
			_px(im, x0 + w / 2, y0 - 1, Color(1, 1, 1))
		"minion_hood":     # тёмный рваный капюшон, из тени горят жёлтые глаза
			var hc4: Color = spec["shirt"]
			_box(im, x0 - 2, y0 - 3, w + 3, h + 1, hc4)
			im.fill_rect(Rect2i(x0 + 3, y0 + 1, w - 3, h - 2), Color(0.06, 0.05, 0.07))
			for k in 3:
				_px(im, x0 - 2 + k * 2, y0 + h - 1 + (k % 2), hc4.darkened(0.25))       # рваный край
			_px(im, x0 + w / 2 - 1, y0 - 4, hc4)
			im.fill_rect(Rect2i(ex - 1, ey, 2, 1), Color(1.0, 0.85, 0.2))
			im.fill_rect(Rect2i(ex - 5, ey, 2, 1), Color(1.0, 0.85, 0.2))
		"imp_horns":       # бесёнок: рожки, острые уши, жёлтые глаза и клыки
			for k in 4:
				_px(im, x0 + 1 + k / 2, y0 - 1 - k, Color(0.25, 0.18, 0.16))
				_px(im, x0 + w - 3 + k / 2, y0 - 1 - k, Color(0.25, 0.18, 0.16))
			_ears(im, x0, y0, w, skin)
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(1.0, 0.85, 0.2))
			_px(im, x0 + w - 3, y0 + h - 2, Color(0.95, 0.92, 0.85))
		"sergeant_helm":   # помятый железный шлем с шипом, гнилые зубы в ухмылке
			var ir := Color(0.42, 0.40, 0.42)
			_box(im, x0 - 1, y0 - 3, w + 2, h / 2 + 2, ir)
			im.fill_rect(Rect2i(x0 + 1, y0 - 2, w - 3, 1), ir.lightened(0.2))
			im.fill_rect(Rect2i(x0 + w / 2 - 1, y0 - 7, 2, 4), ir.darkened(0.2))         # шип
			_px(im, x0 + 3, y0 - 1, Color(0.5, 0.32, 0.18))                              # ржавчина
			im.fill_rect(Rect2i(x0 + w - 6, ey - 1, 6, 1), Color(0.08, 0.06, 0.06))       # прорезь
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(1.0, 0.7, 0.2))
			for x in range(x0 + w - 6, x0 + w - 1, 2):
				_px(im, x, y0 + h - 3, Color(0.75, 0.72, 0.45))
		"bandit_mask":     # повязка на лице и растрёпанные волосы
			var mc: Color = spec.get("mask", Color(0.6, 0.2, 0.15))
			_box(im, x0, y0 - 1, w, 3, Color(0.22, 0.15, 0.1), false)
			im.fill_rect(Rect2i(x0, y0, 2, 5), Color(0.22, 0.15, 0.1))
			_box(im, x0 + 2, ey + 1, w - 2, h - (ey - y0) - 1, mc)                     # платок до глаз
			_px(im, x0 + w - 3, ey + 3, mc.darkened(0.25))
			im.fill_rect(Rect2i(x0 - 3, ey + 2, 3, 1), mc)                             # узел сзади
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 1), Color(0.2, 0.14, 0.1))           # бровь
		"ninja_hood":      # чёрный капюшон с прорезью для глаз
			var nc: Color = spec["shirt"]
			_box(im, x0 - 1, y0 - 2, w + 1, h + 1, nc)
			im.fill_rect(Rect2i(x0 + 3, ey - 1, w - 3, 3), skin)
			im.fill_rect(Rect2i(ex, ey, 2, 1), DARK)
			var mc2: Color = spec.get("mask", nc)
			im.fill_rect(Rect2i(x0 - 1, ey - 2, w + 1, 1), mc2)                       # повязка
			im.fill_rect(Rect2i(x0 - 4, ey - 2, 3, 1), mc2)
			_px(im, x0 - 5, ey - 1, mc2)
		"bald_beard":      # лысый громила с рыжей бородой и шрамом
			var br2 := Color(0.62, 0.30, 0.14)
			im.fill_rect(Rect2i(x0 + 1, y0 + h / 2 + 1, w, h / 2 - 1), br2)
			im.fill_rect(Rect2i(x0 + w - 5, y0 + h / 2 + 1, 4, 1), br2.lightened(0.15))
			im.fill_rect(Rect2i(x0 + 2, y0, w - 3, 1), skin.lightened(0.15))                # блик лысины
			im.fill_rect(Rect2i(ex - 1, ey - 3, 1, 5), Color(0.7, 0.35, 0.3))               # шрам
			im.fill_rect(Rect2i(ex - 1, ey - 1, 4, 1), Color(0.3, 0.16, 0.08))
		"ataman":          # атаман: шлем с кабаньими клыками, повязка на глазу, чёрная борода
			var hc5 := Color(0.22, 0.20, 0.22)
			var beard3 := Color(0.12, 0.10, 0.10)
			im.fill_rect(Rect2i(x0 + 1, y0 + h / 2, w, h / 2), beard3)
			im.fill_rect(Rect2i(x0 + w, y0 + h / 2 + 1, 2, h / 2 - 2), beard3)
			im.fill_rect(Rect2i(x0 + w - 5, y0 + h / 2 + 1, 4, 1), Color(0.6, 0.35, 0.3))   # рот
			_box(im, x0 - 1, y0 - 4, w + 2, h / 2 + 2, hc5)
			im.fill_rect(Rect2i(x0, y0 - 3, w, 1), hc5.lightened(0.25))
			for k in 4:                                                                       # клыки на шлеме
				_px(im, x0 + w - 2 + k / 2, y0 - 4 - k, Color(0.92, 0.88, 0.76))
				_px(im, x0 + 2 - k / 2, y0 - 4 - k, Color(0.92, 0.88, 0.76))
			im.fill_rect(Rect2i(x0 - 1, ey - 1, w + 2, 1), Color(0.10, 0.08, 0.08))          # ремень повязки
			_box(im, ex - 1, ey - 1, 3, 3, Color(0.10, 0.08, 0.08), false)                    # повязка на глазу
			im.fill_rect(Rect2i(ex - 5, ey, 2, 1), Color(0.9, 0.3, 0.2))                      # злой глаз
		"lion_pelt":       # шкура льва на голове вместо капюшона
			var mane := Color(0.62, 0.40, 0.18)
			_box(im, x0 - 2, y0 - 3, w + 2, 6, Color(0.82, 0.62, 0.32))
			im.fill_rect(Rect2i(x0 - 3, y0 - 2, 3, h + 2), mane)
			for k in 4:
				_px(im, x0 - 4, y0 + k * 2, mane.darkened(0.2))
			_px(im, x0 + w - 2, y0 - 2, Color(0.1, 0.08, 0.06))                              # глаз шкуры
			im.fill_rect(Rect2i(x0 + w - 3, y0 + 1, 3, 1), Color(0.95, 0.92, 0.85))          # клыки
		"ninja_tail":      # Ассасин: высокий хвост, зелёная повязка-лента, маска на лице
			var hair4 := Color(0.07, 0.07, 0.09)
			var band: Color = spec.get("wrap", Color(0.45, 0.56, 0.32))
			_box(im, x0, y0 - 1, w, 4, hair4, false)
			im.fill_rect(Rect2i(x0, y0, 3, h - 2), hair4)
			for k in 8:                                                                        # высокий хвост: вверх и чуть назад
				im.fill_rect(Rect2i(x0 + 1 - k / 2, y0 - 2 - k, 3 - k / 4, 2), hair4.lightened(0.06 * (k % 2)))
			for k in 4:                                                                        # острые пряди на конце
				_px(im, x0 - 3 - k, y0 - 9 + k * 2, hair4)
				_px(im, x0 - 2 - k, y0 - 9 + k * 2, hair4)
			for k in 3:                                                                        # прядь на лицо
				_px(im, x0 + w - 2 - k, y0 + 1 + k, hair4)
			im.fill_rect(Rect2i(x0 - 1, y0 - 1, w + 1, 1), band)                              # лента
			for k in 4:                                                                        # концы ленты
				_px(im, x0 - 2 - k, y0 - 2 + (k % 2), band)
			_box(im, x0 + 2, ey + 1, w - 2, h - (ey - y0) - 1, Color(0.16, 0.30, 0.25))     # маска
			_px(im, x0 + w - 3, ey + 2, band)
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(0.75, 0.15, 0.15))                       # глаз
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 1), hair4)                                 # бровь
		"ghoul":           # лысый череп, впалые красные глаза, клыки
			im.fill_rect(Rect2i(x0, y0, w, 1), skin.lightened(0.12))
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 3), Color(0.08, 0.06, 0.06))
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(1.0, 0.25, 0.2))
			for x in range(x0 + w - 5, x0 + w, 2):
				_px(im, x, y0 + h - 2, Color(0.95, 0.92, 0.8))
			for k in 3:
				_px(im, x0 + 1 + k * 2, y0 + 2 + k, skin.darkened(0.25))        # шрамы
		"scarecrow":       # мешок-голова со швом, светящиеся глаза, соломенная шляпа
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 2), Color(0.1, 0.06, 0.04))
			im.fill_rect(Rect2i(ex, ey, 1, 1), Color(1.0, 0.6, 0.15))
			im.fill_rect(Rect2i(ex - 5, ey - 1, 2, 2), Color(0.1, 0.06, 0.04))
			for x in range(x0 + 2, x0 + w - 1):
				_px(im, x, y0 + h - 3, Color(0.25, 0.15, 0.08) if x % 2 == 0 else skin)   # шов-рот
			var straw := Color(0.86, 0.74, 0.36)
			im.fill_rect(Rect2i(x0 - 3, y0 - 1, w + 6, 2), straw)
			for k in 5:
				im.fill_rect(Rect2i(x0 + 1 + k, y0 - 2 - k, w - 2 - k * 2, 1), straw.darkened(0.06 * (k % 2)))
			_px(im, x0 - 4, y0, straw)
			_px(im, x0 + w + 3, y0 + 1, straw)
		"witch":           # высокая кривая шляпа, седые космы, крючковатый нос
			var hc6 := Color(0.16, 0.10, 0.20)
			var hair5 := Color(0.72, 0.72, 0.70)
			im.fill_rect(Rect2i(x0 - 1, y0 + 1, 3, h + 2), hair5)
			im.fill_rect(Rect2i(x0, y0, w, 2), hair5)
			im.fill_rect(Rect2i(x0 - 4, y0 - 1, w + 8, 2), hc6)                     # поля шляпы
			for k in 9:
				var hw6 := 4 - k / 2
				im.fill_rect(Rect2i(x0 + w / 2 - hw6 - k / 3, y0 - 2 - k, hw6 * 2 + 1, 1), hc6)
			_px(im, x0 + w / 2 - 4, y0 - 11, hc6)
			im.fill_rect(Rect2i(x0 + 1, y0 - 2, w - 2, 1), Color(0.55, 0.35, 0.12))  # лента
			im.fill_rect(Rect2i(x0 + w, ey + 1, 2, 2), skin.darkened(0.1))          # нос
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(0.85, 1.0, 0.3))
		"bogman":          # ком грязи: мох сверху, жёлтые глаза, стекающие капли
			im.fill_rect(Rect2i(x0, y0, w, 2), Color(0.32, 0.42, 0.22))
			for k in 4:
				_px(im, x0 + 1 + k * 3, y0 - 1, Color(0.36, 0.48, 0.24))
				im.fill_rect(Rect2i(x0 + 2 + k * 2, y0 + h - 1, 1, 2 + k % 2), skin.darkened(0.15))
			im.fill_rect(Rect2i(ex - 1, ey, 2, 2), Color(1.0, 0.85, 0.25))
			im.fill_rect(Rect2i(ex - 5, ey, 2, 2), Color(1.0, 0.85, 0.25))
		"frog":            # лягушачья голова: глаза навыкате сверху, широкий рот
			_box(im, x0 + w - 6, y0 - 4, 5, 5, skin)
			_box(im, x0 + w - 11, y0 - 3, 4, 4, skin.darkened(0.1))
			_px(im, x0 + w - 4, y0 - 2, Color(0.95, 0.85, 0.2))
			_px(im, x0 + w - 4, y0 - 1, Color(0.05, 0.05, 0.05))
			_px(im, x0 + w - 9, y0 - 1, Color(0.05, 0.05, 0.05))
			im.fill_rect(Rect2i(x0 + 2, y0 + h - 3, w - 2, 1), skin.darkened(0.45))
			im.fill_rect(Rect2i(x0 + 3, y0 + h - 2, w - 4, 1), Color(0.75, 0.75, 0.5))   # светлое горло
		"drowned":         # мокрые пряди, пустые глаза, водоросли
			var wet := Color(0.12, 0.14, 0.12)
			im.fill_rect(Rect2i(x0, y0 - 1, w, 2), wet)
			for k in 5:
				im.fill_rect(Rect2i(x0 + k * 2, y0, 1, 3 + (k * 3) % 4), wet)
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 2), Color(0.85, 0.92, 0.9))
			_px(im, ex, ey, Color(0.3, 0.4, 0.4))
			im.fill_rect(Rect2i(x0 - 2, y0 + 3, 2, 5), Color(0.25, 0.45, 0.25))       # водоросли
			_px(im, x0 + w - 3, y0 + h - 3, Color(0.25, 0.3, 0.3))
		"fur_hood":        # белый меховой капюшон, шарф, ледяной взгляд
			var fh: Color = spec["shirt"]
			_box(im, x0 - 2, y0 - 2, w + 2, h / 2 + 2, fh)
			_box(im, x0 - 3, y0, 4, h, fh)
			for k in 5:
				_px(im, x0 - 2 + k * 2, y0 - 2, fh.darkened(0.12))
			im.fill_rect(Rect2i(x0 + 1, y0 + h - 3, w, 3), Color(0.35, 0.50, 0.75))    # шарф до носа
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(0.45, 0.85, 1.0))
		"yeti":            # косматая голова: белая шерсть, серо-синее лицо, жёлтые глаза, клыки, рожки
			var face := Color(0.48, 0.56, 0.74)
			im.fill_rect(Rect2i(x0 - 2, y0 - 2, w + 3, 4), skin)
			for k in 7:
				_px(im, x0 - 2 + k * 2, y0 - 3, skin.darkened(0.08))
			im.fill_rect(Rect2i(x0 - 2, y0, 3, h + 1), skin)                              # космы сзади
			_box(im, x0 + 3, y0 + 2, w - 3, h - 2, face)                                   # лицо
			im.fill_rect(Rect2i(x0 + 3, y0 + 2, w - 3, 1), skin.darkened(0.12))            # мохнатая бровь
			im.fill_rect(Rect2i(ex - 1, ey, 2, 2), Color(1.0, 0.85, 0.3))
			im.fill_rect(Rect2i(ex - 5, ey, 2, 2), Color(1.0, 0.85, 0.3))
			_px(im, ex, ey + 1, DARK)
			_px(im, ex - 4, ey + 1, DARK)
			im.fill_rect(Rect2i(x0 + 4, y0 + h - 3, w - 5, 2), Color(0.35, 0.10, 0.12))   # пасть
			_px(im, x0 + 5, y0 + h - 4, Color(0.97, 0.97, 0.97))                           # клыки
			_px(im, x0 + w - 2, y0 + h - 4, Color(0.97, 0.97, 0.97))
			for s in [0, 1]:                                                               # загнутые рожки
				var hx := x0 + 1 if s == 0 else x0 + w - 3
				for k in 4:
					_px(im, hx + (-k / 2 if s == 0 else k / 2), y0 - 3 - k, Color(0.62, 0.62, 0.70))
		"frost_helm":      # закрытый ледяной шлем с голубым свечением прорези и шипами
			_crystal_box(im, x0 - 1, y0 - 2, w + 2, h + 1, spec["armor_plate"])
			im.fill_rect(Rect2i(x0 + w - 6, ey, 6, 1), Color(0.05, 0.08, 0.15))
			im.fill_rect(Rect2i(ex - 1, ey, 2, 1), Color(0.55, 0.9, 1.0))
			for k in 3:
				var sx := x0 + 1 + k * (w - 2) / 2
				im.fill_rect(Rect2i(sx, y0 - 5 - (2 if k == 1 else 0), 1, 3 + (2 if k == 1 else 0)), Color(0.9, 0.97, 1.0))
		"jotun_beard":     # корона из льдинок, огромная белая борода, голубые глаза
			var beard4 := Color(0.93, 0.95, 0.98)
			im.fill_rect(Rect2i(x0 + 1, y0 + h / 2, w, h / 2 + 2), beard4)
			im.fill_rect(Rect2i(x0 + w, y0 + h / 2 + 1, 2, h / 2), beard4)
			for k in 4:
				_px(im, x0 + 2 + k * 3, y0 + h + 2, beard4.darkened(0.1))
			im.fill_rect(Rect2i(x0 + w - 6, y0 + h / 2, 5, 1), beard4.darkened(0.12))   # усы
			im.fill_rect(Rect2i(x0, y0, w, 2), beard4)                                     # седые волосы
			im.fill_rect(Rect2i(x0 - 1, y0, 2, h / 2 + 2), beard4)
			for k in 5:                                                                    # ледяной венец
				var cx2 := x0 + 1 + k * (w - 2) / 4
				var ch2 := 3 + (3 if k == 2 else (1 if k % 2 else 0))
				im.fill_rect(Rect2i(cx2, y0 - ch2, 2, ch2), Color(0.70, 0.90, 1.0).lightened(0.1 * (k % 2)))
			im.fill_rect(Rect2i(ex - 1, ey - 2, 4, 1), beard4.darkened(0.2))               # густая бровь
		"storm_hood":      # синий капюшон со знаком молнии, глаза светятся
			var sh2: Color = spec["shirt"]
			_box(im, x0 - 2, y0 - 3, w + 3, h + 1, sh2)
			im.fill_rect(Rect2i(x0 + 3, y0 + 1, w - 3, h - 2), Color(0.05, 0.06, 0.10))
			im.fill_rect(Rect2i(ex - 1, ey, 2, 1), Color(0.75, 0.9, 1.0))
			im.fill_rect(Rect2i(ex - 5, ey, 2, 1), Color(0.75, 0.9, 1.0))
			_px(im, x0 + 1, y0 - 1, Color(0.95, 0.85, 0.3))
			_px(im, x0 + 2, y0, Color(0.95, 0.85, 0.3))
			_px(im, x0 + 1, y0 + 1, Color(0.95, 0.85, 0.3))
		"guard_helm":      # бронзовый шлем с синим гребнем и личиной
			_box(im, x0 - 1, y0 - 2, w + 2, h + 1, BRONZE)
			im.fill_rect(Rect2i(x0 + w - 6, ey - 1, 6, 3), Color(0.08, 0.06, 0.05))
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(0.8, 0.9, 1.0))
			for i in w + 2:
				var hh2 := int(5.0 * sin(PI * i / (w + 1.0)))
				im.fill_rect(Rect2i(x0 - 1 + i, y0 - 2 - hh2, 1, hh2), Color(0.20, 0.35, 0.75))
		"priest_mitre":    # высокая белая митра со знаком молнии, седая борода
			var mt := Color(0.92, 0.92, 0.96)
			for k in 8:
				im.fill_rect(Rect2i(x0 + 1 + k / 3, y0 - 1 - k, w - 2 - (k / 3) * 2, 1), mt.darkened(0.04 * (k % 2)))
			im.fill_rect(Rect2i(x0 + w / 2, y0 - 7, 1, 2), Color(0.95, 0.80, 0.25))
			_px(im, x0 + w / 2 - 1, y0 - 5, Color(0.95, 0.80, 0.25))
			_px(im, x0 + w / 2, y0 - 4, Color(0.95, 0.80, 0.25))
			im.fill_rect(Rect2i(x0 + 2, y0 + h / 2 + 1, w - 1, h / 2), Color(0.85, 0.85, 0.88))   # борода
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(0.3, 0.45, 0.8))
		"storm_crown":     # волосы-грозовые тучи, золотой венец-молнии, белые глаза, седая борода
			var cl := Color(0.30, 0.33, 0.44)
			for k in 8:                                                                    # клубящиеся «тучи» волос
				_box(im, x0 - 4 + k * 2, y0 - 4 + (k % 2), 4, 4, cl.lightened(0.07 * (k % 3)), false)
			im.fill_rect(Rect2i(x0 - 4, y0, 5, h + 3), cl)
			for k in 4:
				_px(im, x0 - 5, y0 + 2 + k * 3, cl.lightened(0.1))
			var gold := Color(1.0, 0.86, 0.35)
			im.fill_rect(Rect2i(x0, y0 - 1, w, 1), gold)                                   # обруч
			for k in 3:                                                                    # зубцы-молнии
				var bx2 := x0 + 2 + k * (w - 4) / 2
				for j in 4:
					_px(im, bx2 + (j % 2), y0 - 2 - j, gold if j < 3 else Color(1, 1, 1))
			im.fill_rect(Rect2i(ex - 1, ey, 3, 1), Color(1, 1, 1))
			im.fill_rect(Rect2i(ex - 6, ey, 2, 1), Color(1, 1, 1))
			im.fill_rect(Rect2i(x0 + 3, y0 + h - 4, w - 2, 4), Color(0.80, 0.84, 0.92))   # седая борода
			im.fill_rect(Rect2i(x0 + w - 1, y0 + h - 2, 2, 3), Color(0.80, 0.84, 0.92))
		"imp_fire":        # огненный бес: рожки и волосы-пламя
			for k in 4:
				_px(im, x0 + 1 + k / 2, y0 - 1 - k, Color(0.20, 0.10, 0.08))
				_px(im, x0 + w - 3 + k / 2, y0 - 1 - k, Color(0.20, 0.10, 0.08))
			for k in 5:
				im.fill_rect(Rect2i(x0 + 2 + k, y0 - 3 - (k % 3), 1, 3 + (k % 3)), Color(1.0, 0.75 + 0.05 * k, 0.2))
			_ears(im, x0, y0, w, skin)
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(1.0, 0.95, 0.4))
			_px(im, x0 + w - 3, y0 + h - 2, Color(0.95, 0.92, 0.85))
		"ash":             # потрескавшееся серое лицо, угольки-глаза, пепельные космы
			im.fill_rect(Rect2i(x0, y0 - 1, w, 2), Color(0.25, 0.24, 0.24))
			for k in 4:
				im.fill_rect(Rect2i(x0 + k * 2, y0, 1, 2 + k % 2), Color(0.25, 0.24, 0.24))
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 3), Color(0.10, 0.08, 0.08))
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(1.0, 0.5, 0.15))
			for k in 3:
				_px(im, x0 + 2 + k * 2, y0 + 3 + k, Color(1.0, 0.45, 0.15))                # тлеющие трещины
		"cult_hood":       # алый капюшон, чёрная маска с рожками
			var ch3: Color = spec["shirt"]
			_box(im, x0 - 2, y0 - 3, w + 3, h + 1, ch3)
			_box(im, x0 + 3, y0 + 1, w - 3, h - 2, Color(0.08, 0.06, 0.06))
			im.fill_rect(Rect2i(ex - 1, ey, 2, 1), Color(1.0, 0.6, 0.15))
			im.fill_rect(Rect2i(ex - 5, ey, 2, 1), Color(1.0, 0.6, 0.15))
			for k in 3:
				_px(im, x0 + 2 + k / 2, y0 - 4 - k, Color(0.15, 0.12, 0.12))
				_px(im, x0 + w - 2 - k / 2, y0 - 4 - k, Color(0.15, 0.12, 0.12))
		"rassvet_helm":    # чёрный шлем бывшего рыцаря Лорда: один рог обломан, прорезь светится золотом
			var hc9: Color = spec.get("helm", Color(0.17, 0.15, 0.19))
			var glow: Color = spec.get("helm_glow", Color(1.0, 0.82, 0.40))
			var horn: Color = spec.get("horn", Color(0.72, 0.70, 0.76))
			_box(im, x0 - 1, y0 - 2, w + 2, h + 1, hc9)
			im.fill_rect(Rect2i(x0, y0 - 1, w, 1), hc9.lightened(0.2))
			im.fill_rect(Rect2i(x0 + w - 7, ey, 7, 1), Color(0.05, 0.03, 0.04))
			im.fill_rect(Rect2i(ex - 2, ey, 4, 1), glow.lightened(0.15))
			im.fill_rect(Rect2i(x0 + w / 2, y0 - 1, 1, h - 2), glow)                     # светящаяся трещина
			if spec.get("crown_spikes", false):                                           # корона из шипов: зубцы с золотыми остриями
				for k in 4:
					var cx9 := x0 + 1 + k * (w - 3) / 3
					_px(im, cx9, y0 - 3, hc9.lightened(0.28))
					_px(im, cx9, y0 - 4, hc9.lightened(0.28))
					_px(im, cx9, y0 - 5, glow)
					if k < 3:
						_px(im, cx9 + 1, y0 - 3, hc9.lightened(0.12))
			else:
				for k in 5:                                                                 # целый рог
					_px(im, x0 + w - 2 + k / 2, y0 - 2 - k, horn)
				for k in (5 if spec.get("horn_whole", false) else 2):                     # обломанный (в облике — снова целый)
					_px(im, x0 + 1 - k / 2, y0 - 2 - k, horn)
				_px(im, x0, y0 - 4, glow.lightened(0.1))
		"dark_helm":       # чёрный рогатый шлем с красной прорезью
			var hc8 := Color(0.16, 0.14, 0.18)
			_box(im, x0 - 1, y0 - 2, w + 2, h + 1, hc8)
			im.fill_rect(Rect2i(x0, y0 - 1, w, 1), hc8.lightened(0.2))
			im.fill_rect(Rect2i(x0 + w - 7, ey, 7, 1), Color(0.03, 0.02, 0.03))
			im.fill_rect(Rect2i(ex - 1, ey, 3, 1), Color(1.0, 0.25, 0.12))
			for k in 5:
				_px(im, x0 + 1 - k / 2, y0 - 2 - k, Color(0.72, 0.70, 0.76))
				_px(im, x0 + w - 2 + k / 2, y0 - 2 - k, Color(0.72, 0.70, 0.76))
		"warlock_hood":    # тёмный капюшон, лиловые глаза, руны на краю
			var wh: Color = spec["shirt"]
			_box(im, x0 - 2, y0 - 3, w + 3, h + 1, wh)
			im.fill_rect(Rect2i(x0 + 3, y0 + 1, w - 3, h - 2), Color(0.04, 0.02, 0.06))
			im.fill_rect(Rect2i(ex - 1, ey, 2, 1), Color(0.85, 0.45, 1.0))
			im.fill_rect(Rect2i(ex - 5, ey, 2, 1), Color(0.85, 0.45, 1.0))
			for k in 3:
				_px(im, x0 - 1, y0 + 1 + k * 3, Color(0.7, 0.35, 0.95))
			_px(im, x0 + w / 2, y0 - 4, wh)
		"shade_mask":      # чёрный капюшон и белая гладкая маска без рта
			var sc2: Color = spec["shirt"]
			_box(im, x0 - 2, y0 - 3, w + 3, h + 1, sc2)
			_box(im, x0 + 3, y0 + 1, w - 3, h - 2, Color(0.88, 0.86, 0.84))
			im.fill_rect(Rect2i(ex - 1, ey, 2, 1), Color(0.05, 0.03, 0.06))
			im.fill_rect(Rect2i(ex - 4, ey, 2, 1), Color(0.05, 0.03, 0.06))
			_px(im, ex - 3, ey + 3, Color(0.75, 0.15, 0.2))
		"exec_hood":       # чёрный колпак палача с прорезями для глаз
			var eh := Color(0.10, 0.08, 0.09)
			_box(im, x0 - 1, y0 - 4, w + 1, h + 4, eh)
			for k in 4:
				im.fill_rect(Rect2i(x0 + 2 + k, y0 - 5 - k, w - 4 - k * 2, 1), eh)
			im.fill_rect(Rect2i(ex - 1, ey, 3, 1), Color(0.75, 0.2, 0.15))
			im.fill_rect(Rect2i(ex - 5, ey, 2, 1), Color(0.75, 0.2, 0.15))
		"dark_lord":       # высокий шлем с гребнем-лезвием и рогами, длинные чёрные волосы
			var hl := Color(0.24, 0.22, 0.27)
			var hair6 := Color(0.05, 0.04, 0.06)
			im.fill_rect(Rect2i(x0 - 3, y0 + 2, 4, h + 6), hair6)                           # волосы до плеч
			for k in 4:
				_px(im, x0 - 4, y0 + 4 + k * 3, hair6)
			_box(im, x0 - 1, y0 - 3, w + 2, h + 1, hl)
			for k in 3:                                                                     # серебристые прожилки
				_px(im, x0 + 2 + k * 3, y0 - 1 + k, Color(0.72, 0.70, 0.78))
			for k in 10:                                                                    # гребень-лезвие посередине
				var hw3 := 1 if k < 7 else 0
				im.fill_rect(Rect2i(x0 + w / 2 - hw3, y0 - 4 - k, hw3 * 2 + 1, 1), hl.lightened(0.15))
			_px(im, x0 + w / 2, y0 - 8, Color(1.0, 0.45, 0.15))
			for s in [0, 1]:                                                                # загнутые рога
				var bx3 := x0 + 1 if s == 0 else x0 + w - 2
				for k in 9:
					var hx2 := bx3 + (-k / 3 if s == 0 else k / 3)
					im.fill_rect(Rect2i(hx2, y0 - 3 - k, 2, 1), Color(0.68, 0.66, 0.72).darkened(0.03 * k))
			im.fill_rect(Rect2i(x0 + w - 8, ey - 1, 8, 3), Color(0.02, 0.01, 0.02))         # тень под забралом
			im.fill_rect(Rect2i(ex - 1, ey, 3, 1), Color(1.0, 0.5, 0.15))
			im.fill_rect(Rect2i(ex - 6, ey, 2, 1), Color(1.0, 0.5, 0.15))
			for k in 4:                                                                     # клыкастая личина
				_px(im, x0 + w - 7 + k * 2, y0 + h - 3, Color(0.6, 0.58, 0.64))
		"hair":
			_box(im, x0, y0 - 1, w, 3, Color(0.3, 0.2, 0.12), false)
			im.fill_rect(Rect2i(x0, y0 - 1, 2, 5), Color(0.3, 0.2, 0.12))
		"band":
			im.fill_rect(Rect2i(x0, y0 + 1, w, 2), Color(0.9, 0.15, 0.15))
			im.fill_rect(Rect2i(x0 - 3, y0 + 2, 3, 1), Color(0.9, 0.15, 0.15))
		"helmet":
			_box(im, x0 - 1, y0 - 2, w + 2, 5, shirt.darkened(0.25))
		"steel":
			_box(im, x0 - 1, y0 - 2, w + 2, h / 2 + 2, STEEL)
			im.fill_rect(Rect2i(x0 + w - 5, ey, 4, 1), DARK)
		"cap":
			_box(im, x0, y0 - 2, w, 4, shirt.darkened(0.3))
			im.fill_rect(Rect2i(x0 + w - 1, y0 + 1, 3, 1), shirt.darkened(0.45))
		"straw_hat":       # широкополая соломенная шляпа с лиловой лентой (бездна уже в нём)
			var stw := Color(0.86, 0.74, 0.36)
			im.fill_rect(Rect2i(x0 - 3, y0, w + 6, 2), stw)
			im.fill_rect(Rect2i(x0 + 1, y0 - 3, w - 2, 3), stw.darkened(0.05))
			im.fill_rect(Rect2i(x0 + 1, y0 - 1, w - 2, 1), Color(0.55, 0.30, 0.62))
			_px(im, x0 - 4, y0 + 1, stw)
			_px(im, x0 + w + 3, y0 + 1, stw)
		"visor":
			_box(im, x0 - 1, y0 - 2, w + 2, h - 2, STEEL.darkened(0.2))
			im.fill_rect(Rect2i(x0 + 2, ey - 1, w - 1, 3), Color(0.55, 0.85, 1.0))
		"ears":
			_ears(im, x0, y0, w, skin)
			im.fill_rect(Rect2i(x0 + w, ey + 2, 2, 2), skin.darkened(0.1))       # нос
		"ears_bald":
			_ears(im, x0, y0, w, skin)
			im.fill_rect(Rect2i(x0 + w - 4, y0 + h - 3, 1, 2), Color(0.95, 0.92, 0.8))   # клык
		"hood":
			_ears(im, x0, y0 + 2, w, skin)
			_box(im, x0 - 1, y0 - 2, w + 1, h - 1, shirt)
			im.fill_rect(Rect2i(x0 + w - 4, ey - 1, 4, 4), skin)
			im.fill_rect(Rect2i(ex, ey, 1, 1), Color(1.0, 0.9, 0.3))
		"goggles":
			_ears(im, x0, y0, w, skin)
			im.fill_rect(Rect2i(x0, ey - 1, w, 2), Color(0.25, 0.2, 0.15))
			_box(im, ex - 1, ey - 2, 4, 4, Color(1.0, 0.8, 0.2))
		"band_brown":
			im.fill_rect(Rect2i(x0, y0 + 1, w, 2), Color(0.45, 0.3, 0.15))
			_box(im, x0, y0 - 1, w, 2, Color(0.25, 0.16, 0.1), false)
		"bronze_helm":   # шлем бойца с нащёчниками
			_box(im, x0 - 1, y0 - 2, w + 2, 5, BRONZE)
			_box(im, x0 - 1, y0 + 2, 3, h - 3, BRONZE)
			im.fill_rect(Rect2i(x0 + 2, y0 - 4, w - 4, 2), Color(0.8, 0.15, 0.12))
		"murmillo_helm": # большой шлем мирмиллона с решёткой и гребнем
			_box(im, x0 - 1, y0 - 2, w + 2, h + 1, BRONZE)
			for yy in range(y0 + 2, y0 + h - 1, 2):
				im.fill_rect(Rect2i(x0 + w - 6, yy, 6, 1), DARK)
			for i in w:
				var hh := int(4.0 * sin(PI * i / (w - 1.0)))
				im.fill_rect(Rect2i(x0 + i, y0 - 2 - hh, 1, hh), BRONZE.darkened(0.25))
		"leaves":        # волосы-листья Терновника, веточки рожками
			for i in w + 2:
				var hh := 2 + (i * 7) % 3
				im.fill_rect(Rect2i(x0 - 1 + i, y0 - hh, 1, hh + 2), Color(0.30, 0.58, 0.24) if i % 2 == 0 else Color(0.38, 0.66, 0.28))
			im.fill_rect(Rect2i(x0 + 1, y0 - 6, 1, 4), Color(0.45, 0.32, 0.18))
			im.fill_rect(Rect2i(x0 + w - 3, y0 - 7, 1, 5), Color(0.45, 0.32, 0.18))
			im.fill_rect(Rect2i(x0 - 1, y0 + 2, 2, 5), Color(0.30, 0.58, 0.24))
		"combat_helm":   # закрытый шлем на всю голову: тёмное забрало, дыхательный фильтр
			var hc2 := Color(0.30, 0.36, 0.23)
			_box(im, x0 - 1, y0 - 3, w + 2, h + 3, hc2)
			im.fill_rect(Rect2i(x0, y0 - 2, w, 1), hc2.lightened(0.18))                 # блик сверху
			im.fill_rect(Rect2i(x0 - 1, y0 + h / 2 + 2, w + 2, 1), hc2.darkened(0.35))  # шов
			_box(im, x0 + w / 2 - 1, ey - 2, w / 2 + 2, 4, Color(0.08, 0.10, 0.12), false)   # забрало
			im.fill_rect(Rect2i(x0 + w / 2, ey - 1, w / 2, 1), Color(0.35, 0.75, 0.85))      # отблеск стекла
			_box(im, x0 + w - 3, y0 + h - 4, 4, 4, Color(0.18, 0.20, 0.17), false)          # фильтр
			_px(im, x0 + w - 2, y0 + h - 3, Color(0.4, 0.42, 0.38))
			_px(im, x0 + w, y0 + h - 2, Color(0.4, 0.42, 0.38))
			_box(im, x0 + 1, y0, 3, 4, hc2.darkened(0.2), false)                           # крепление сбоку
		"topknot":       # самурай: пучок на макушке и белая повязка с красным солнцем
			var hair2 := Color(0.08, 0.07, 0.08)
			_box(im, x0, y0 - 1, w, 4, hair2, false)
			im.fill_rect(Rect2i(x0, y0, 3, h - 3), hair2)
			_box(im, x0 + 2, y0 - 5, 4, 4, hair2, false)                                # пучок
			im.fill_rect(Rect2i(x0 - 1, y0 + 2, w + 1, 2), Color(0.95, 0.95, 0.92))     # хатимаки
			im.fill_rect(Rect2i(x0 + w / 2, y0 + 2, 2, 2), Color(0.85, 0.12, 0.12))
			im.fill_rect(Rect2i(x0 - 4, y0 + 3, 3, 1), Color(0.95, 0.95, 0.92))
			im.fill_rect(Rect2i(x0 - 5, y0 + 4, 2, 1), Color(0.95, 0.95, 0.92))
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 1), hair2)                           # бровь
		"zarnitsa_hair": # серебристые волосы в высоком хвосте с синими кончиками, медное кольцо, заколка-молния
			var zp: Array = spec.get("hair_pal", [Color(0.86, 0.88, 0.96), Color(0.40, 0.58, 0.98), Color(0.80, 0.48, 0.24), Color(1.0, 0.86, 0.36), Color(0.50, 0.82, 1.0)])
			var hc8: Color = zp[0]
			var tipc: Color = zp[1]
			_box(im, x0 - 1, y0 - 2, w + 1, 4, hc8, false)
			im.fill_rect(Rect2i(x0 - 1, y0, 3, h - 3), hc8)                       # волосы сзади
			im.fill_rect(Rect2i(x0 + 2, y0 + 1, w - 3, 1), hc8.lightened(0.05))   # чёлка
			_px(im, x0 + w - 1, y0 + 1, hc8)
			_px(im, x0 + w - 1, y0 + 2, hc8.darkened(0.08))                       # прядь у лица
			var tdx := [-3, -4, -5, -5, -6, -6, -6, -6, -5, -5]                   # высокий хвост до плеч
			var tw := [3, 3, 3, 3, 3, 2, 2, 2, 2, 1]
			for k in 10:
				var c8: Color = hc8.darkened(0.06 * (k % 2)) if k < 7 else tipc.lightened(0.1 * (k % 2))
				im.fill_rect(Rect2i(x0 + int(tdx[k]), y0 - 2 + k, int(tw[k]), 1), c8)
			_px(im, x0 - 4, y0 - 2, hc8.lightened(0.1))
			_box(im, x0 - 2, y0 - 2, 2, 3, zp[2], false)                          # кольцо
			var gz: Color = zp[3]                                                  # заколка-молния
			_px(im, x0 + 5, y0 - 3, gz)
			_px(im, x0 + 4, y0 - 2, gz)
			_px(im, x0 + 5, y0 - 2, gz)
			_px(im, x0 + 4, y0 - 1, gz)
			im.fill_rect(Rect2i(ex, ey, 1, 1), zp[4])                             # глаз
			_px(im, ex - 1, ey - 1, hc8.darkened(0.3))                            # бровь
		"tina_hair":     # волосы из тины: тёмные сине-зелёные пряди до плеч, глаз светится
			var hc7 := Color(0.14, 0.32, 0.22)
			_box(im, x0 - 1, y0 - 2, w + 1, 4, hc7, false)
			im.fill_rect(Rect2i(x0 - 2, y0, 4, h + 3), hc7)                     # пряди сзади, до плеч
			for k in 4:
				_px(im, x0 - 3 - (k % 2), y0 + 3 + k * 2, hc7.lightened(0.15))
			im.fill_rect(Rect2i(x0 + 2, y0 + 1, w - 3, 1), hc7.lightened(0.10))  # чёлка
			_px(im, x0 + w - 1, y0 + 1, hc7)
			for k in 3:                                                          # свисающие нитки тины
				_px(im, x0 + 2 + k * 2, y0 + 2, hc7.lightened(0.05 * k))
			im.fill_rect(Rect2i(ex, ey, 1, 1), Color(0.85, 1.0, 0.35))          # жёлто-зелёный глаз
			_px(im, ex - 1, ey - 1, hc7.darkened(0.1))                            # бровь
		# ----- Проработанные облики Призмы -----
		"ember_circlet", "void_circlet", "radiant_circlet", "ice_circlet":   # волосы и обруч с кристаллом облика
			var cp: Array = {"ember_circlet": [Color(0.80, 0.24, 0.08), Color(1.0, 0.55, 0.15), Color(0.20, 0.12, 0.10), Color(1.0, 0.86, 0.40)],
					"ice_circlet": [Color(0.90, 0.95, 1.0), Color(0.50, 0.84, 1.0), Color(0.55, 0.72, 0.90), Color(0.96, 1.0, 1.0)],
					"void_circlet": [Color(0.10, 0.07, 0.15), Color(0.62, 0.32, 0.92), Color(0.30, 0.22, 0.38), Color(0.95, 0.85, 1.0)],
					"radiant_circlet": [Color(0.98, 0.95, 0.85), Color(1.0, 0.80, 0.32), Color(1.0, 0.86, 0.45), Color(1.0, 1.0, 0.95)]}[spec["hat"]]
			var hc: Color = cp[0]
			_box(im, x0, y0 - 1, w, 3, hc, false)
			im.fill_rect(Rect2i(x0 - 1, y0, 3, h - 1), hc)
			for k in 7:                                                                      # длинные пряди за спину
				_px(im, x0 - 2 - k / 3, y0 + 2 + k, hc if k % 2 == 0 else cp[1])
			im.fill_rect(Rect2i(x0, y0 + 1, w, 1), cp[2])                                  # обруч
			for k in 3:                                                                      # кристалл-корона: три грани
				_px(im, x0 + w / 2 - 1 + k, y0 - 1 - (1 if k == 1 else 0), cp[1])
			im.fill_rect(Rect2i(x0 + w / 2, y0 - 4, 1, 3), cp[1])
			_px(im, x0 + w / 2, y0 - 4, cp[3])
			if spec["hat"] == "ember_circlet":
				for k in 3:
					_px(im, x0 + 1 + k * 3, y0 - 2 - (k % 2), Color(1.0, 0.55, 0.15))          # языки огня в волосах
			elif spec["hat"] == "ice_circlet":
				for d in [Vector2i(-2, -5), Vector2i(2, -5), Vector2i(-2, -3), Vector2i(2, -3)]:   # кристалл — снежинка
					_px(im, x0 + w / 2 + d.x, y0 + d.y, cp[3])
				_px(im, x0 + w / 2 - 1, y0 - 4, cp[1])
				_px(im, x0 + w / 2 + 1, y0 - 4, cp[1])
				for k in 3:
					_px(im, x0 - 1 + k * 2, y0 + h - 2 + (k % 2), Color(0.75, 0.92, 1.0))           # иней на кончиках прядей
			im.fill_rect(Rect2i(ex, ey, 1, 1), cp[1])
		# ----- Проработанные облики Чемпиона -----
		"ember_helm", "void_crest_helm", "laurel_helm", "frost_crest_helm":   # шлем бойца облика с гребнем
			var hp: Array = {"ember_helm": [Color(0.22, 0.16, 0.14), Color(1.0, 0.48, 0.12), Color(1.0, 0.86, 0.40)],
					"frost_crest_helm": [Color(0.66, 0.80, 0.94), Color(0.50, 0.84, 1.0), Color(0.95, 1.0, 1.0)],
					"void_crest_helm": [Color(0.12, 0.08, 0.17), Color(0.72, 0.40, 1.0), Color(0.95, 0.85, 1.0)],
					"laurel_helm": [Color(1.0, 0.82, 0.38), Color(0.98, 0.96, 0.90), Color(0.40, 0.70, 0.30)]}[spec["hat"]]
			_box(im, x0 - 1, y0 - 2, w + 2, 5, hp[0])
			_box(im, x0 - 1, y0 + 2, 3, h - 3, hp[0])                                     # нащёчник
			match spec["hat"]:
				"ember_helm":                                                                  # гребень из пламени
					for i in w - 3:
						var fh := 2 + (i * 5) % 3
						for j in fh:
							_px(im, x0 + 1 + i, y0 - 3 - j, hp[2] if j == fh - 1 else hp[1])
				"void_crest_helm":                                                             # гребень из осколков
					for i in range(0, w - 3, 2):
						var sh := 2 + (i % 4)
						im.fill_rect(Rect2i(x0 + 1 + i, y0 - 2 - sh, 1, sh), hp[1])
						_px(im, x0 + 1 + i, y0 - 3 - sh, hp[2])
					im.fill_rect(Rect2i(x0 + w - 4, ey, 3, 1), hp[1])                            # светящаяся прорезь
				"frost_crest_helm":                                                            # гребень из кристаллов льда, прорезь в инее
					for i in range(0, w - 2, 2):
						var ch2 := 3 + (i * 3) % 4
						im.fill_rect(Rect2i(x0 + 1 + i, y0 - 2 - ch2, 2, ch2), hp[1] if (i / 2) % 2 == 0 else hp[1].lightened(0.25))
						_px(im, x0 + 1 + i, y0 - 3 - ch2, hp[2])
					im.fill_rect(Rect2i(x0 + w - 4, ey, 3, 1), hp[2])
					im.fill_rect(Rect2i(x0 - 1, y0 + 2, w + 2, 1), Color(0.88, 0.97, 1.0))          # иней по краю шлема
				"laurel_helm":                                                                 # белый плюмаж и лавр
					for i in w - 2:
						var hh := int(4.0 * sin(PI * i / (w - 3.0)))
						im.fill_rect(Rect2i(x0 + i, y0 - 2 - hh, 1, hh), hp[1])
					for k in 4:
						_px(im, x0 + k * 2, y0 + 1, hp[2])
		# ----- Проработанные облики Осоки -----
		"ember_tina", "void_tina", "lotus_crown", "frost_tina":   # волосы-тина облика
			var tp: Array = {"ember_tina": [Color(0.16, 0.10, 0.08), Color(1.0, 0.48, 0.12), Color(1.0, 0.70, 0.25)],
					"frost_tina": [Color(0.62, 0.78, 0.88), Color(0.45, 0.82, 1.0), Color(0.94, 0.99, 1.0)],
					"void_tina": [Color(0.10, 0.07, 0.15), Color(0.62, 0.32, 0.92), Color(0.90, 0.70, 1.0)],
					"lotus_crown": [Color(0.94, 0.94, 0.88), Color(1.0, 0.80, 0.32), Color(1.0, 0.82, 0.86)]}[spec["hat"]]
			var hc7: Color = tp[0]
			_box(im, x0 - 1, y0 - 2, w + 1, 4, hc7, false)
			im.fill_rect(Rect2i(x0 - 2, y0, 4, h + 3), hc7)
			for k in 4:
				_px(im, x0 - 3 - (k % 2), y0 + 3 + k * 2, tp[1])                            # светящиеся пряди
			im.fill_rect(Rect2i(x0 + 2, y0 + 1, w - 3, 1), hc7.lightened(0.10))
			for k in 3:
				_px(im, x0 + 2 + k * 2, y0 + 2, tp[1] if k % 2 == 0 else hc7)
			if spec["hat"] == "lotus_crown":                                                # венок из лотосов
				for k in 3:
					var fx := x0 + 1 + k * 3
					_px(im, fx, y0 - 3, tp[2])
					_px(im, fx - 1, y0 - 2, tp[2])
					_px(im, fx + 1, y0 - 2, tp[2])
					_px(im, fx, y0 - 2, tp[1])
			elif spec["hat"] == "frost_tina":                                              # тина вмёрзла: сосульки на прядях, снежинки
				for k in 4:
					_px(im, x0 - 3 - (k % 2), y0 + 4 + k * 2, tp[2])
				for k in 3:
					var sx := x0 + 1 + k * 3
					_px(im, sx, y0 - 4, tp[2])
					_px(im, sx - 1, y0 - 3, tp[1])
					_px(im, sx + 1, y0 - 3, tp[1])
					_px(im, sx, y0 - 2, tp[2])
			else:
				for k in 3:                                                                    # над головой вьются огоньки / искры бездны
					_px(im, x0 + 1 + k * 3, y0 - 3 - (k % 2), tp[2])
			im.fill_rect(Rect2i(ex, ey, 1, 1), tp[2])
		# ----- Проработанные облики Ассасина -----
		"ember_tail", "void_tail", "sun_tail", "frost_tail":   # хвост волос облика: пламя, тьма с лиловыми кончиками, белое золото или иней
			var pal: Array = {"ember_tail": [Color(0.10, 0.06, 0.05), Color(1.0, 0.48, 0.12), Color(1.0, 0.86, 0.40), Color(0.20, 0.10, 0.08)],
					"frost_tail": [Color(0.90, 0.95, 1.0), Color(0.45, 0.80, 1.0), Color(0.96, 1.0, 1.0), Color(0.20, 0.32, 0.48)],
					"void_tail": [Color(0.10, 0.07, 0.15), Color(0.72, 0.40, 1.0), Color(0.95, 0.85, 1.0), Color(0.07, 0.05, 0.10)],
					"sun_tail": [Color(0.97, 0.95, 0.88), Color(1.0, 0.80, 0.32), Color(1.0, 1.0, 0.92), Color(0.96, 0.94, 0.88)]}[spec["hat"]]
			var hair: Color = pal[0]
			_box(im, x0, y0 - 1, w, 4, hair, false)
			im.fill_rect(Rect2i(x0, y0, 3, h - 2), hair)
			for k in 9:                                                                        # хвост вверх-назад, к концу — цвет облика
				var c: Color = hair if k < 4 else (pal[1] if k < 7 else pal[2])
				im.fill_rect(Rect2i(x0 + 1 - k / 2, y0 - 2 - k, 3 - k / 4, 2), c)
			for k in 4:
				_px(im, x0 - 3 - k, y0 - 9 + k * 2, pal[1])
				_px(im, x0 - 4 - k, y0 - 10 + k * 2, pal[2])
			im.fill_rect(Rect2i(x0 - 1, y0 - 1, w + 1, 1), pal[1])                             # лента
			_px(im, x0 + w / 2, y0 - 1, pal[2])
			for k in 5:
				_px(im, x0 - 2 - k, y0 - 2 + (k % 2), pal[1])
			im.fill_rect(Rect2i(x0 + 3, ey + 1, w - 3, h - (ey - y0) - 2), pal[3])            # маска на лице
			im.fill_rect(Rect2i(x0 + 3, ey + 1, w - 3, 1), pal[1])
			im.fill_rect(Rect2i(ex, ey, 1, 1), pal[2])
		# ----- Проработанные облики Терновника -----
		"ember_leaves":  # Пепельный терн: осенние листья горят, тлеющие веточки-рожки
			for i in w + 2:
				var hh := 2 + (i * 7) % 3
				var c: Variant = [Color(0.85, 0.30, 0.08), Color(1.0, 0.55, 0.12), Color(0.60, 0.16, 0.06)][i % 3]
				im.fill_rect(Rect2i(x0 - 1 + i, y0 - hh, 1, hh + 2), c)
				if i % 3 == 1:
					_px(im, x0 - 1 + i, y0 - hh - 1, Color(1.0, 0.86, 0.40))
			im.fill_rect(Rect2i(x0 + 1, y0 - 6, 1, 4), Color(0.18, 0.10, 0.08))
			im.fill_rect(Rect2i(x0 + w - 3, y0 - 7, 1, 5), Color(0.18, 0.10, 0.08))
			_px(im, x0 + 1, y0 - 7, Color(1.0, 0.55, 0.12))
			_px(im, x0 + w - 3, y0 - 8, Color(1.0, 0.55, 0.12))
			im.fill_rect(Rect2i(x0 - 1, y0 + 2, 2, 5), Color(0.85, 0.30, 0.08))
		"void_thorns":   # Терн Бездны: чёрный терновый венец, на шипах — лиловые почки
			for i in w + 2:
				var hh := 1 + (i * 5) % 2
				im.fill_rect(Rect2i(x0 - 1 + i, y0 - hh, 1, hh + 2), Color(0.12, 0.08, 0.16))
			for k in 5:
				var sx := x0 + k * (w / 4)
				var sh := 3 + (k % 2) * 2
				for j in sh:
					_px(im, sx + (j % 2) * (1 if k % 2 else -1), y0 - 2 - j, Color(0.18, 0.12, 0.24))
				_px(im, sx, y0 - 2 - sh, Color(0.80, 0.50, 1.0))
			im.fill_rect(Rect2i(x0 - 1, y0 + 2, 2, 6), Color(0.12, 0.08, 0.16))
			_px(im, x0 - 1, y0 + 8, Color(0.72, 0.40, 1.0))
		"bloom_crown":   # Древо жизни — истинный облик: венок из белых цветов и золотых листьев
			for i in w + 2:
				var hh := 2 + (i * 7) % 3
				im.fill_rect(Rect2i(x0 - 1 + i, y0 - hh, 1, hh + 2), Color(1.0, 0.82, 0.38) if i % 2 == 0 else Color(0.95, 0.72, 0.28))
			for k in 4:
				var fx := x0 + k * 3
				for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
					_px(im, fx + d.x, y0 - 3 + d.y, Color(1.0, 1.0, 0.95))
				_px(im, fx, y0 - 3, Color(1.0, 0.70, 0.20))
			im.fill_rect(Rect2i(x0 - 1, y0 + 2, 2, 5), Color(1.0, 0.82, 0.38))
			_px(im, x0 - 1, y0 + 7, Color(1.0, 1.0, 0.95))
		# ----- Проработанные облики Мортиса -----
		"pyre_hood", "void_cowl", "soul_crown", "rime_hood":   # капюшон облика поверх черепа
			var rc: Color = spec["robe"]
			var acc: Color = {"pyre_hood": Color(1.0, 0.48, 0.12), "void_cowl": Color(0.72, 0.40, 1.0), "soul_crown": Color(1.0, 0.80, 0.32),
					"rime_hood": Color(0.55, 0.86, 1.0)}[spec["hat"]]
			_box(im, x0 - 2, y0 - 3, w + 3, h + 1, rc)
			im.fill_rect(Rect2i(x0 + 3, y0 + 1, w - 3, h - 2), Color(0.04, 0.03, 0.06))
			im.fill_rect(Rect2i(x0 + 2, y0 + 1, 1, h - 2), acc.darkened(0.2))               # кромка капюшона
			match spec["hat"]:
				"pyre_hood":
					for k in range(0, w + 2, 2):                                                   # капюшон горит по краю
						var fh := 2 + (k * 5) % 4
						for j in fh:
							_px(im, x0 - 2 + k, y0 - 4 - j, Color(1.0, 0.86, 0.40) if j == fh - 1 else acc)
				"void_cowl":
					for s in [-1, 1]:                                                             # рога загибаются наружу
						var bx := x0 + 1 if s < 0 else x0 + w - 3
						for k in 7:
							var off: int = [0, 0, 1, 1, 2, 3, 4][k] * s
							im.fill_rect(Rect2i(bx + off, y0 - 4 - k, 2 if k < 4 else 1, 1), acc if k > 4 else rc.lightened(0.25))
					for k in 3:
						im.fill_rect(Rect2i(x0 - 3 - k, y0 + h - 2 + (k % 2), 1, 2), rc)              # рваный край
				"rime_hood":
					im.fill_rect(Rect2i(x0 - 2, y0 - 3, w + 3, 1), Color(0.90, 0.97, 1.0))          # иней по кромке капюшона
					for k in range(0, w + 2, 2):                                                   # корона из ледяных шипов
						var fh2 := 2 + (k * 3) % 5
						for j in fh2:
							_px(im, x0 - 2 + k, y0 - 4 - j, Color(0.92, 0.99, 1.0) if j == fh2 - 1 else acc)
					for k in 3:
						_px(im, x0 + 4 + k * 2, y0 + 1, Color(0.80, 0.94, 1.0, 0.8))                 # сосульки свисают в тень
				"soul_crown":
					im.fill_rect(Rect2i(x0 - 1, y0 - 4, w + 2, 2), acc)                            # корона Короля поверх капюшона
					for i in 4:
						var cx := x0 + i * (w - 1) / 3
						im.fill_rect(Rect2i(cx, y0 - 7, 2, 3), acc)
						_px(im, cx, y0 - 8, Color(1.0, 0.98, 0.85))
			_px(im, ex, ey, acc.lightened(0.3))
		# ----- Проработанные облики Солдата -----
		"inferno_helm":  # Штурмовик пекла: обугленный шлем, раскалённое забрало, огненная полоса и фильтр
			var hc := Color(0.16, 0.13, 0.12)
			var lava := Color(1.0, 0.48, 0.12)
			_box(im, x0 - 1, y0 - 3, w + 2, h + 3, hc)
			im.fill_rect(Rect2i(x0, y0 - 2, w, 1), Color(0.85, 0.28, 0.06))                # огненная полоса по гребню
			for k in range(1, w - 3, 3):
				_px(im, x0 + k, y0 + 1 + (k % 2), lava)                                     # языки огня на боку
				_px(im, x0 + k, y0 + 2 + (k % 2), Color(1.0, 0.86, 0.40))
			_box(im, x0 + w / 2 - 1, ey - 2, w / 2 + 2, 4, Color(0.10, 0.05, 0.03), false)
			im.fill_rect(Rect2i(x0 + w / 2, ey - 1, w / 2, 2), lava)                         # раскалённое забрало
			_px(im, x0 + w - 1, ey - 1, Color(1.0, 0.90, 0.55))
			_box(im, x0 + w - 3, y0 + h - 4, 4, 4, Color(0.22, 0.12, 0.10), false)
			_px(im, x0 + w, y0 + h - 2, Color(1.0, 0.40, 0.10))                              # фильтр тлеет
		"void_helm":     # Рейдер Бездны: чёрно-лиловый шлем, сплошная прорезь-свет, осколки-антенны
			var hc := Color(0.11, 0.08, 0.16)
			var vio := Color(0.72, 0.40, 1.0)
			_box(im, x0 - 1, y0 - 3, w + 2, h + 3, hc)
			im.fill_rect(Rect2i(x0 + 2, ey, w - 1, 1), vio)                                  # прорезь через всё лицо
			_px(im, ex, ey, Color(0.95, 0.85, 1.0))
			im.fill_rect(Rect2i(x0, y0 + h / 2 + 2, w, 1), hc.lightened(0.12))
			_px(im, x0 + 3, y0 + 2, vio.darkened(0.3))                                       # трещины
			_px(im, x0 + 4, y0 + 3, vio.darkened(0.3))
			for k in 4:
				_px(im, x0 + 2 + k / 2, y0 - 4 - k, vio if k > 1 else hc.lightened(0.2))       # осколки-антенны
				_px(im, x0 + w - 2 - k / 3, y0 - 4 - k, vio if k > 2 else hc.lightened(0.2))
		"parade_helm":   # Маршал — истинный облик: белый парадный шлем, золотой обод, высокий султан
			var wh := Color(0.95, 0.93, 0.88)
			var gold := Color(1.0, 0.80, 0.32)
			_box(im, x0 - 1, y0 - 3, w + 2, h / 2 + 4, wh)
			im.fill_rect(Rect2i(x0 - 1, y0 + h / 2, w + 2, 1), gold)                          # обод
			im.fill_rect(Rect2i(x0 + 2, y0 - 1, 2, 2), gold)                                   # кокарда
			_px(im, x0 + 2, y0 - 1, Color(1.0, 0.98, 0.85))
			for k in 9:                                                                         # султан
				var c := Color(0.85, 0.15, 0.15) if k < 6 else Color(1.0, 0.82, 0.35)
				im.fill_rect(Rect2i(x0 + w / 2 - k / 3, y0 - 4 - k, 2, 1), c)
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 1), Color(0.40, 0.30, 0.20))
			_px(im, ex, ey, DARK)
		# ----- Проработанные облики Самурая -----
		"ember_kabuto":  # Пламенный ронин: чёрно-алый кабуто, огненный гребень-маэдатэ, тлеющие наушники
			var kb := Color(0.22, 0.08, 0.06)
			var lava := Color(1.0, 0.48, 0.12)
			_box(im, x0 - 1, y0 - 3, w + 2, 5, kb)
			im.fill_rect(Rect2i(x0 - 3, y0 + 1, 4, 3), kb)                                     # нашейник сзади
			im.fill_rect(Rect2i(x0 - 3, y0 + 3, 4, 1), lava)
			im.fill_rect(Rect2i(x0 - 1, y0 + 1, w + 2, 1), Color(0.85, 0.55, 0.15))            # золотой край
			for j in 7:                                                                         # пламя-гребень
				var hw := 2 - j / 3
				im.fill_rect(Rect2i(x0 + w / 2 - hw, y0 - 4 - j, hw * 2 + 1, 1), Color(1.0, 0.86, 0.40) if j > 3 else lava)
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 1), Color(0.08, 0.06, 0.06))
		"void_kabuto":   # Ронин Бездны: чёрный кабуто, лиловые рога-полумесяцы, маска демона с клыками
			var kb := Color(0.09, 0.06, 0.12)
			var vio := Color(0.72, 0.40, 1.0)
			_box(im, x0 - 1, y0 - 3, w + 2, 5, kb)
			im.fill_rect(Rect2i(x0 - 3, y0 + 1, 4, 3), kb)
			for s in [-1, 1]:                                                                   # рога-кувагата
				var bx: Variant = x0 + w / 2 + s * 2
				for k in 6:
					_px(im, bx + s * (k / 2 + (1 if k > 3 else 0)), y0 - 4 - k + (1 if k > 4 else 0), vio if k > 2 else vio.darkened(0.3))
			_box(im, x0 + w / 2, ey + 1, w / 2 + 1, h - (ey - y0) - 1, Color(0.14, 0.08, 0.20), false)  # маска-мэмпо
			for k in range(x0 + w / 2 + 1, x0 + w, 2):
				_px(im, k, ey + 3, vio)                                                         # клыки
			im.fill_rect(Rect2i(ex, ey, 1, 1), Color(0.92, 0.70, 1.0))
		"sun_kabuto":    # Сёгун солнца — истинный облик: бело-золотой кабуто с диском солнца, белый хвост волос
			var kb := Color(0.96, 0.93, 0.86)
			var gold := Color(1.0, 0.80, 0.32)
			_box(im, x0 - 1, y0 - 3, w + 2, 5, kb)
			im.fill_rect(Rect2i(x0 - 1, y0 + 1, w + 2, 1), gold)
			for k in 6:
				im.fill_rect(Rect2i(x0 - 3 - k / 2, y0 + 2 + k, 2, 1), Color(0.97, 0.96, 0.92))    # белый хвост волос
			for y in range(-5, 0):                                                              # диск солнца
				for x in range(-3, 4):
					if x * x + (y + 3) * (y + 3) <= 7:
						_px(im, x0 + w / 2 + x, y0 - 4 + y, Color(1.0, 0.60, 0.15) if x * x + (y + 3) * (y + 3) <= 2 else gold)
			for a in [[-5, -6], [5, -6], [0, -10], [-4, -10], [4, -10]]:
				_px(im, x0 + w / 2 + a[0], y0 + a[1], Color(1.0, 0.95, 0.70))                   # лучи
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 1), Color(0.55, 0.45, 0.30))
		# ----- Ледяная серия -----
		"frost_hood":    # Северная лучница: капюшон с белым мехом по краю, ледяная коса, иней на бровях
			var hb := Color(0.30, 0.48, 0.66)
			var fur := Color(0.94, 0.97, 1.0)
			var ice := Color(0.55, 0.85, 1.0)
			_box(im, x0 - 1, y0 - 2, w + 1, 4, hb)
			_box(im, x0 - 2, y0 - 1, 5, h + 1, hb)
			for k in w + 1:                                                              # меховая опушка
				_px(im, x0 - 1 + k, y0 - 3 + (k % 2), fur)
			for k in h - 1:
				_px(im, x0 + 2 + (k % 2), y0 + k, fur if k % 3 else fur.darkened(0.08))     # мех вдоль лица
			im.fill_rect(Rect2i(x0 + 4, y0 + 1, w - 5, 1), Color(0.88, 0.94, 1.0))        # светлая чёлка
			for k in 8:                                                                  # коса изо льда уходит назад
				var c := fur if k < 3 else (ice if k < 6 else Color(0.35, 0.65, 0.95))
				im.fill_rect(Rect2i(x0 - 3 - k, y0 + 4 - k / 2, 2, 1), c)
			_px(im, x0 - 11, y0, Color(0.85, 0.97, 1.0, 0.85))                           # льдинка на конце косы
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 1), Color(0.85, 0.95, 1.0))            # иней на брови
			_px(im, ex, ey, Color(0.25, 0.55, 0.85))                                      # голубой глаз
		"rime_helm":     # Кузнец вечной мерзлоты: шлем в корке льда, белая борода в сосульках, забрало светится голубым
			var iron := Color(0.45, 0.55, 0.66)
			var ice := Color(0.70, 0.90, 1.0)
			var beard := Color(0.90, 0.94, 0.98)
			im.fill_rect(Rect2i(x0 + 1, y0 + h / 2 + 1, w, h / 2 - 1), beard)
			im.fill_rect(Rect2i(x0 + w, y0 + h / 2 + 2, 2, h / 2 - 3), beard)
			for k in range(1, w + 1, 2):                                                  # сосульки в бороде
				_px(im, x0 + k, y0 + h - 1, ice)
				if k % 4 == 1:
					_px(im, x0 + k, y0 + h - 2, Color(0.55, 0.82, 1.0))
			im.fill_rect(Rect2i(x0 + w - 5, y0 + h / 2 + 2, 4, 1), beard.darkened(0.15))
			_box(im, x0 - 1, y0 - 3, w + 2, h / 2 + 3, iron)
			for k in range(0, w + 2, 2):                                                  # корка льда на гребне
				_px(im, x0 - 1 + k, y0 - 3, ice)
				if k % 4 == 0:
					_px(im, x0 - 1 + k, y0 - 4, Color(0.94, 0.99, 1.0))
			im.fill_rect(Rect2i(x0 + w - 6, ey, 7, 1), Color(0.45, 0.88, 1.0))            # забрало
			_px(im, ex, ey, Color(0.94, 1.0, 1.0))
			for k in [1, w - 2]:
				_px(im, x0 + k, y0 - 1, Color(0.80, 0.86, 0.92))                          # заклёпки в инее
			for k in 3:                                                                   # ледяные рожки
				_px(im, x0 + 1, y0 - 4 - k, ice if k < 2 else Color(0.94, 0.99, 1.0))
				_px(im, x0 + w - 2, y0 - 4 - k, ice if k < 2 else Color(0.94, 0.99, 1.0))
		"frost_kabuto":  # Ронин снегопада: бело-голубой кабуто, ледяной полумесяц-маэдатэ, нашейник в инее
			var kb := Color(0.78, 0.88, 0.96)
			var ice := Color(0.50, 0.82, 1.0)
			_box(im, x0 - 1, y0 - 3, w + 2, 5, kb)
			im.fill_rect(Rect2i(x0 - 3, y0 + 1, 4, 3), kb.darkened(0.15))                 # нашейник
			im.fill_rect(Rect2i(x0 - 3, y0 + 3, 4, 1), ice)
			im.fill_rect(Rect2i(x0 - 1, y0 + 1, w + 2, 1), Color(0.35, 0.55, 0.78))        # синяя кромка
			for s in [-1, 1]:                                                             # полумесяц изо льда
				for k in 5:
					_px(im, x0 + w / 2 + s * (1 + k / 2 + (1 if k > 2 else 0)), y0 - 4 - k, ice if k < 3 else Color(0.94, 0.99, 1.0))
			_px(im, x0 + w / 2, y0 - 4, Color(0.94, 0.99, 1.0))
			_px(im, x0 + w / 2, y0 - 5, ice)
			for k in 3:
				_px(im, x0 + k * 3, y0 - 2, Color(0.94, 0.99, 1.0))                        # снег на шлеме
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 1), Color(0.70, 0.88, 1.0))
		"frost_leaves":  # Морозный терн: листья в инее, ледяные веточки-рожки, сосулька у виска
			for i in w + 2:
				var hh := 2 + (i * 7) % 3
				var c: Color = [Color(0.40, 0.66, 0.82), Color(0.62, 0.84, 0.96), Color(0.30, 0.52, 0.70)][i % 3]
				im.fill_rect(Rect2i(x0 - 1 + i, y0 - hh, 1, hh + 2), c)
				if i % 3 == 1:
					_px(im, x0 - 1 + i, y0 - hh - 1, Color(0.94, 0.99, 1.0))
			im.fill_rect(Rect2i(x0 + 1, y0 - 6, 1, 4), Color(0.70, 0.88, 1.0))
			im.fill_rect(Rect2i(x0 + w - 3, y0 - 7, 1, 5), Color(0.70, 0.88, 1.0))
			_px(im, x0 + 1, y0 - 7, Color(0.94, 0.99, 1.0))
			_px(im, x0 + w - 3, y0 - 8, Color(0.94, 0.99, 1.0))
			_px(im, x0, y0 - 7, Color(0.55, 0.85, 1.0))
			_px(im, x0 + w - 2, y0 - 8, Color(0.55, 0.85, 1.0))
			im.fill_rect(Rect2i(x0 - 1, y0 + 2, 2, 5), Color(0.40, 0.66, 0.82))
			_px(im, x0 - 1, y0 + 7, Color(0.85, 0.97, 1.0))                                 # сосулька
			_px(im, x0 - 1, y0 + 8, Color(0.85, 0.97, 1.0, 0.6))
			_px(im, ex, ey, Color(0.55, 0.88, 1.0))
		"polar_helm":    # Полярный штурмовик: шлем-ушанка с белым мехом, очки с голубым стеклом, шарф в инее
			var hc := Color(0.82, 0.88, 0.94)
			var fur := Color(0.95, 0.97, 1.0)
			_box(im, x0 - 1, y0 - 3, w + 2, h / 2 + 3, hc)
			im.fill_rect(Rect2i(x0 - 1, y0 - 3, w + 2, 1), fur)                          # мех по верху
			for k in range(0, w + 2, 3):
				_px(im, x0 - 1 + k, y0 - 4, fur)
			im.fill_rect(Rect2i(x0 - 2, y0 + 1, 3, h - 2), fur)                          # меховое «ухо»
			_px(im, x0 - 2, y0 + h - 1, fur.darkened(0.1))
			_box(im, x0 + w / 2 - 1, ey - 2, w / 2 + 2, 3, Color(0.20, 0.26, 0.34), false)   # очки-маска
			im.fill_rect(Rect2i(x0 + w / 2, ey - 1, w / 2, 1), Color(0.45, 0.85, 1.0))
			_px(im, x0 + w - 1, ey - 1, Color(0.94, 1.0, 1.0))
			im.fill_rect(Rect2i(x0 + 2, y0 + h - 3, w - 1, 3), Color(0.30, 0.48, 0.66))   # шарф-маска
			for k in range(x0 + 3, x0 + w, 2):
				_px(im, k, y0 + h - 3, Color(0.85, 0.95, 1.0))                             # иней на шарфе
			_px(im, x0 + 2, y0 - 1, Color(0.45, 0.80, 1.0))                               # кокарда-снежинка
		"moto_helm":    # Почти легенда: круглый шлем, голубой визор во всю ширину, оранжевая полоса, гребень
			var hpl: Array = spec.get("helm_pal", [Color(0.94, 0.95, 0.98), Color(1.0, 0.52, 0.14), Color(0.30, 0.90, 1.0), Color(0.18, 0.20, 0.26)])
			_box(im, x0 - 1, y0 - 2, w + 2, h + 1, hpl[0], false)                # оболочка шлема
			im.fill_rect(Rect2i(x0, y0 - 3, w, 1), hpl[0])                       # округлый верх
			_px(im, x0 - 1, y0 - 2, Color(0, 0, 0, 0))
			_px(im, x0 + w, y0 - 2, Color(0, 0, 0, 0))
			im.fill_rect(Rect2i(x0 + 2, y0 - 4, w - 5, 1), hpl[1])               # гребень
			im.fill_rect(Rect2i(x0 + 1, y0 - 3, w - 3, 1), hpl[1])
			im.fill_rect(Rect2i(x0 + 2, ey - 1, w - 1, 3), hpl[3])               # прорезь визора
			im.fill_rect(Rect2i(x0 + 3, ey, w - 3, 1), hpl[2])                   # светящийся визор
			_px(im, ex + 1, ey - 1, hpl[2].lightened(0.5))
			im.fill_rect(Rect2i(x0 - 1, y0 + h - 3, 3, 3), hpl[1])               # оранжевая скула
			im.fill_rect(Rect2i(x0 + w - 3, y0 + h - 2, 4, 2), hpl[0].darkened(0.12))   # подбородник
		"scribe_cap":   # Летописец: мягкий берет писаря с пером за лентой, тёмные волосы, круглые очки
			var cpl: Array = spec.get("cap_pal", [Color(0.24, 0.16, 0.32), Color(1.0, 0.82, 0.38), Color(0.96, 0.95, 0.90),
					Color(0.50, 0.68, 1.0), Color(0.85, 0.72, 0.40), Color(0.30, 0.21, 0.16)])
			var hair: Color = cpl[5]
			im.fill_rect(Rect2i(x0, y0, w, 2), hair)                              # волосы
			im.fill_rect(Rect2i(x0, y0, 2, h - 3), hair)
			_px(im, x0 + w - 1, y0 + 2, hair)
			_px(im, x0 + 2, y0 + 2, hair.darkened(0.1))
			_box(im, x0 - 2, y0 - 3, w + 3, 3, cpl[0], false)                    # берет
			im.fill_rect(Rect2i(x0 - 3, y0 - 2, 3, 3), cpl[0])                     # свисает назад
			_px(im, x0 - 3, y0 + 1, cpl[0].darkened(0.2))
			im.fill_rect(Rect2i(x0 - 1, y0 - 1, w + 1, 1), cpl[1])                 # лента
			_px(im, x0 + w / 2, y0 - 4, cpl[0].lightened(0.2))                     # хвостик берета
			for k in 8:                                                              # перо за лентой: назад и вверх
				var fx := x0 + 1 - k
				var fy := y0 - 2 - k / 2 - (1 if k > 4 else 0)
				_px(im, fx, fy, cpl[2])
				_px(im, fx, fy - 1, cpl[2] if k % 2 else cpl[2].darkened(0.1))
			_px(im, x0 - 6, y0 - 8, cpl[3])                                          # кончик пера
			_px(im, x0 - 5, y0 - 8, cpl[3])
			_box(im, ex - 1, ey - 1, 3, 3, cpl[4], false)                            # круглые очки
			_px(im, ex, ey, Color(0.07, 0.08, 0.12))
			_px(im, ex + 1, ey - 1, Color(1, 1, 1, 0.9))                             # блик на стекле
			im.fill_rect(Rect2i(x0 + 2, ey, ex - x0 - 3, 1), cpl[4].darkened(0.25))  # дужка к уху
			_px(im, ex - 1, ey + 3, Color(0.16, 0.24, 0.55))                         # чернильное пятнышко на щеке
		# ----- Проработанные облики Охотницы -----
		"ember_hood":    # Пепельная лучница: обугленный капюшон с тлеющей кромкой, коса из пламени
			var ash := Color(0.22, 0.17, 0.16)
			var emb := Color(1.0, 0.48, 0.12)
			var hot := Color(1.0, 0.86, 0.40)
			_box(im, x0 - 1, y0 - 2, w + 1, 4, ash)
			_box(im, x0 - 2, y0 - 1, 5, h + 1, ash)
			for k in range(0, w + 1, 2):
				_px(im, x0 - 1 + k, y0 - 3, emb)                                      # тлеющая кромка
				if k % 4 == 0:
					_px(im, x0 - 1 + k, y0 - 4, hot)
			im.fill_rect(Rect2i(x0 + 3, y0 + 1, w - 4, 1), emb)                   # огненная чёлка
			for k in 8:                                                            # коса-пламя уходит назад и вверх
				var c := hot if k < 2 else (emb if k < 5 else Color(0.80, 0.18, 0.06))
				im.fill_rect(Rect2i(x0 - 3 - k, y0 + 4 - k / 2, 2, 1), c)
			_px(im, x0 - 11, y0, Color(1.0, 0.60, 0.15, 0.7))
			_px(im, ex - 2, ey + 2, Color(0.12, 0.09, 0.09))                      # сажа на щеке
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 1), Color(0.14, 0.08, 0.06))
		"void_hood":     # Охотница Бездны: рваный капюшон, полоса-маска, белая коса, разлом на темени
			var vh := Color(0.12, 0.08, 0.18)
			var vio := Color(0.72, 0.40, 1.0)
			_box(im, x0 - 1, y0 - 2, w + 1, 4, vh)
			_box(im, x0 - 2, y0 - 1, 5, h + 2, vh)
			for k in 4:                                                            # клочья капюшона
				im.fill_rect(Rect2i(x0 - 3 - k, y0 + h - 2 + (k % 2), 1, 2), vh)
			im.fill_rect(Rect2i(x0 + w / 2, y0 - 2, 1, 3), vio)                   # разлом
			_px(im, x0 + w / 2, y0 - 3, vio.lightened(0.4))
			var pale := Color(0.84, 0.80, 0.94)
			for k in 6:
				im.fill_rect(Rect2i(x0 - 3 - k / 2, y0 + 3 + k, 2, 1), pale if k % 2 == 0 else pale.darkened(0.2))
			im.fill_rect(Rect2i(x0 + 3, ey - 1, w - 3, 3), Color(0.07, 0.05, 0.10))  # маска через глаза
			im.fill_rect(Rect2i(ex, ey, 1, 1), Color(0.90, 0.65, 1.0))
		"sun_circlet":   # истинный облик Охотницы: длинные светлые волосы, лавровый венец, солнечный камень
			var hair := Color(0.98, 0.90, 0.62)
			var gold := Color(1.0, 0.78, 0.30)
			im.fill_rect(Rect2i(x0, y0 - 1, w, 3), hair)
			im.fill_rect(Rect2i(x0 - 2, y0, 3, h + 2), hair)
			for k in 8:                                                            # хвост волос развевается
				im.fill_rect(Rect2i(x0 - 3 - k, y0 + 2 + k / 2, 2, 1), hair.darkened(0.04 * k))
			im.fill_rect(Rect2i(x0 + 3, y0 + 2, w - 4, 1), hair)
			im.fill_rect(Rect2i(x0 - 1, y0, w + 1, 1), gold)                       # венец
			for k in range(0, w, 2):
				_px(im, x0 + k, y0 - 1 - (k / 2) % 2, Color(0.95, 0.72, 0.25))         # листья лавра
			_px(im, x0 + w - 1, y0 - 2, Color(1.0, 0.98, 0.85))                    # солнечный камень
			_px(im, x0 + w - 1, y0 - 3, Color(1.0, 0.90, 0.55, 0.7))
			im.fill_rect(Rect2i(ex, ey, 1, 1), Color(0.95, 0.80, 0.35))
		# ----- Проработанные облики Кузнеца -----
		"forge_helm":    # Горнило: чугунный полушлем с огненной прорезью, гребень пламени, тлеющая борода
			var iron := Color(0.20, 0.17, 0.17)
			var lava := Color(1.0, 0.48, 0.12)
			var hot := Color(1.0, 0.86, 0.40)
			var beard := Color(0.24, 0.20, 0.19)
			im.fill_rect(Rect2i(x0 + 1, y0 + h / 2 + 1, w, h / 2 - 1), beard)
			im.fill_rect(Rect2i(x0 + w, y0 + h / 2 + 2, 2, h / 2 - 3), beard)
			for k in range(1, w + 1, 2):
				_px(im, x0 + k, y0 + h - 1, lava if k % 4 == 1 else hot)               # борода тлеет снизу
			im.fill_rect(Rect2i(x0 + w - 5, y0 + h / 2 + 2, 4, 1), Color(0.40, 0.30, 0.26))
			_box(im, x0 - 1, y0 - 3, w + 2, h / 2 + 3, iron)
			im.fill_rect(Rect2i(x0 + w - 6, ey, 7, 1), lava)                      # прорезь забрала
			_px(im, ex, ey, hot)
			for k in [1, w - 2]:
				_px(im, x0 + k, y0 - 1, Color(0.55, 0.50, 0.48))                       # заклёпки
			for k in range(1, w, 2):
				var fh := 2 + (k * 5) % 3
				for j in fh:
					_px(im, x0 + k, y0 - 4 - j, hot if j >= fh - 1 else lava)
		"void_smith":    # Кузнец Бездны: обсидиановая полумаска с трещиной, рога, борода из лилового дыма
			var obs := Color(0.10, 0.07, 0.14)
			var vio := Color(0.72, 0.40, 1.0)
			var beard := Color(0.22, 0.12, 0.32)
			im.fill_rect(Rect2i(x0 + 1, y0 + h / 2 + 1, w, h / 2 - 1), beard)
			im.fill_rect(Rect2i(x0 + w, y0 + h / 2 + 2, 2, h / 2 - 3), beard)
			for k in range(2, w, 3):
				im.fill_rect(Rect2i(x0 + k, y0 + h / 2 + 2, 1, h / 2 - 2), Color(0.55, 0.32, 0.80))   # пряди дыма
			_box(im, x0 - 1, y0 - 2, w + 2, h / 2 + 2, obs)
			im.fill_rect(Rect2i(x0 + w - 5, ey - 1, 1, 3), vio)                   # трещина маски
			_px(im, x0 + w - 4, ey + 1, vio)
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(0.92, 0.70, 1.0))
			for s in [-1, 1]:                                                      # рога: толстые у основания, загнуты внутрь
				var bx := x0 + 1 if s < 0 else x0 + w - 3
				for k in 7:
					var off: int = [0, 1, 2, 2, 2, 1, 0][k] * s
					var hw := 2 if k < 4 else 1
					im.fill_rect(Rect2i(bx + off, y0 - 3 - k, hw, 1), obs.lightened(0.15) if k < 5 else vio)
		"titan_crown":   # истинный облик Кузнеца: белая борода в золотых кольцах, венец-наковальня с огнём горна
			var white := Color(0.96, 0.94, 0.88)
			var gold := Color(1.0, 0.80, 0.32)
			im.fill_rect(Rect2i(x0 + 1, y0 + h / 2 + 1, w, h / 2 - 1), white)
			im.fill_rect(Rect2i(x0 + w, y0 + h / 2 + 2, 2, h / 2 - 3), white)
			_px(im, x0 + w - 1, y0 + h - 2, gold)                                  # кольца на бороде
			_px(im, x0 + w - 4, y0 + h - 1, gold)
			im.fill_rect(Rect2i(x0 + w - 5, y0 + h / 2 + 2, 4, 1), white.darkened(0.08))
			im.fill_rect(Rect2i(x0, y0, w, 2), white)
			im.fill_rect(Rect2i(x0, y0, 2, h - 3), white)
			im.fill_rect(Rect2i(x0 - 1, y0 - 1, w + 2, 2), gold)                   # обруч
			for k in range(0, w + 1, 3):
				im.fill_rect(Rect2i(x0 - 1 + k, y0 - 4, 2, 3), gold)                   # зубцы
			im.fill_rect(Rect2i(x0 + w / 2 - 1, y0 - 3, 3, 2), Color(1.0, 0.55, 0.15))  # огонь горна во лбу
			_px(im, x0 + w / 2, y0 - 3, Color(1.0, 0.95, 0.70))
			im.fill_rect(Rect2i(ex - 1, ey - 2, 4, 1), white.darkened(0.15))
		"champ_crown":   # истинный облик: короткие светлые волосы, золотой венец с лучами
			var gold := Color(1.0, 0.82, 0.35)
			var hair2 := Color(0.95, 0.90, 0.78)
			im.fill_rect(Rect2i(x0, y0, w, 2), hair2)
			im.fill_rect(Rect2i(x0, y0, 2, h - 3), hair2)
			im.fill_rect(Rect2i(x0, y0 - 1, w + 1, 1), gold)
			for k in range(1, w, 3):
				_px(im, x0 + k, y0 - 2, gold)
				_px(im, x0 + k, y0 - 3, Color(1.0, 0.95, 0.75))
			_px(im, x0 + w / 2, y0 - 4, Color(1.0, 0.98, 0.85))
			im.fill_rect(Rect2i(ex, ey, 1, 1), Color(1.0, 0.95, 0.7))
		"abyss_crown":   # Лорд Бездны: глухой шлем, над ним парят осколки-короны, глаза горят лиловым
			var hc := Color(0.10, 0.07, 0.14)
			var vio := Color(0.75, 0.42, 1.0)
			_box(im, x0 - 1, y0 - 2, w + 2, h + 1, hc)
			im.fill_rect(Rect2i(x0, y0 + 2, w, 1), vio.darkened(0.3))             # прорезь шлема
			for k in 5:
				var sx := x0 + k * (w / 4)
				var sh := 3 + (k % 2) * 2 + (2 if k == 2 else 0)
				for j in sh:
					_px(im, sx, y0 - 4 - j, vio if j < sh - 1 else vio.lightened(0.4))
			im.fill_rect(Rect2i(ex, ey, 2, 1), Color(0.95, 0.75, 1.0))
		"flame_crown":   # облик огненной серии: короткие тёмные волосы и венец из языков пламени
			var hair := Color(0.16, 0.10, 0.08)
			im.fill_rect(Rect2i(x0, y0, w, 2), hair)
			im.fill_rect(Rect2i(x0, y0, 2, h - 2), hair)
			for k in range(0, w + 1, 2):
				var fh := 2 + (k * 7) % 3
				for j in fh:
					_px(im, x0 + k, y0 - 1 - j, Color(1.0, 0.86, 0.40) if j >= fh - 1 else Color(1.0, 0.45, 0.12))
			im.fill_rect(Rect2i(x0, y0 - 1, w + 1, 1), Color(0.95, 0.55, 0.15))     # обруч
			im.fill_rect(Rect2i(ex, ey, 1, 1), Color(1.0, 0.75, 0.25))
		"abyss_horns":   # облик «Бездна»: тёмный капюшон, лиловые рога-полумесяцы, горящий глаз
			var ah := Color(0.12, 0.08, 0.18)
			var vio := Color(0.72, 0.40, 1.0)
			_box(im, x0 - 1, y0 - 2, w + 2, 3, ah)
			_box(im, x0 - 2, y0 - 1, 4, h + 1, ah)
			im.fill_rect(Rect2i(x0 + 1, y0 - 2, w, 1), vio)
			_px(im, x0 + 1, y0 - 3, vio)
			_px(im, x0, y0 - 4, vio)
			_px(im, x0 - 1, y0 - 4, vio.lightened(0.3))
			_px(im, x0 + w - 2, y0 - 3, vio)
			_px(im, x0 + w - 1, y0 - 4, vio)
			_px(im, x0 + w, y0 - 4, vio.lightened(0.3))
			im.fill_rect(Rect2i(ex, ey, 1, 1), Color(0.92, 0.72, 1.0))
		"echo_hood":     # серый капюшон путника с лиловой каймой, лицо в тени, светится лиловый глаз
			var eh: Color = spec["cape"]
			var vio: Color = spec.get("hood_trim", Color(0.72, 0.48, 1.0))
			_box(im, x0 - 1, y0 - 3, w + 2, 4, eh)
			_box(im, x0 - 2, y0 - 2, 5, h + 2, eh)
			im.fill_rect(Rect2i(x0 + 1, y0 - 3, w, 1), vio)                        # кайма
			im.fill_rect(Rect2i(x0 + w, y0 - 2, 1, 3), vio)
			_px(im, x0 - 1, y0 - 3, eh.lightened(0.15))
			im.fill_rect(Rect2i(x0 + 3, y0 + 1, w - 3, 2), Color(0.16, 0.14, 0.22))  # тень под капюшоном
			im.fill_rect(Rect2i(ex, ey, 1, 1), vio.lightened(0.4))                # глаз
			_px(im, ex, ey + 1, Color(vio, 0.6))
		"seam_hood":     # лоскутный капюшон: заплаты разных земель, золотые стежки, один глаз — золотой
			var sh: Color = spec["cape"]
			var gold: Color = spec.get("stitch", Color(1.0, 0.82, 0.35))
			_box(im, x0 - 1, y0 - 3, w + 2, 4, sh)
			_box(im, x0 - 2, y0 - 2, 5, h + 2, sh)
			im.fill_rect(Rect2i(x0 + 2, y0 - 3, 3, 2), Color(0.36, 0.30, 0.20))        # заплата Энта
			im.fill_rect(Rect2i(x0 + w - 3, y0 - 3, 3, 2), Color(0.25, 0.32, 0.45))    # заплата Бури
			im.fill_rect(Rect2i(x0 - 2, y0 + 2, 2, 3), Color(0.70, 0.66, 0.58))        # кость
			for k in 4:
				_px(im, x0 + k * 2 + 1, y0 - 2 + (k % 2), gold)                       # стежки шва
			_px(im, x0 - 1, y0, gold)
			_px(im, x0 - 1, y0 + 2, gold)
			im.fill_rect(Rect2i(ex - 2, ey + 2, 3, 1), gold)                          # шов через щёку
			im.fill_rect(Rect2i(ex, ey, 1, 1), gold.lightened(0.3))                  # глаз
		"gate_hood":     # капюшон цвета ночного неба с золотой каймой, серебряные пряди, фиолетовый глаз
			var gh: Color = spec["cape"]
			var gold: Color = spec.get("hood_trim", Color(1.0, 0.82, 0.38))
			_box(im, x0 - 1, y0 - 3, w + 2, 4, gh)
			_box(im, x0 - 2, y0 - 2, 5, h + 2, gh)
			im.fill_rect(Rect2i(x0 + 1, y0 - 3, w, 1), gold)                       # кайма по краю капюшона
			im.fill_rect(Rect2i(x0 + w, y0 - 2, 1, 3), gold)
			_px(im, x0 - 1, y0 - 3, gh.lightened(0.15))                             # острый верх
			var silver: Color = spec.get("hair2", Color(0.88, 0.88, 0.96))
			im.fill_rect(Rect2i(x0 + 3, y0 + 1, w - 4, 1), silver)                 # чёлка
			_px(im, x0 + w - 1, y0 + 2, silver)
			for k in 3:
				_px(im, x0 + 3, y0 + 2 + k, silver.darkened(0.06 * k))             # прядь у щеки
			_box(im, x0 - 1, y0 + 3, 2, 2, gold, false)                            # застёжка-скважина
			_px(im, x0, y0 + 4, Color(0.16, 0.12, 0.34))
			im.fill_rect(Rect2i(ex, ey, 1, 1), spec.get("eye2", Color(0.78, 0.52, 1.0)))   # глаз
			_px(im, ex - 1, ey - 1, silver.darkened(0.25))                        # бровь
		"hunter_hood":   # зелёный капюшон, рыжая коса торчит сзади
			var hc: Color = spec["cape"]
			_box(im, x0 - 1, y0 - 2, w + 1, 4, hc)
			_box(im, x0 - 2, y0 - 1, 5, h + 1, hc)
			_px(im, x0 + w - 1, y0 + 1, hc.darkened(0.3))
			var hair := Color(0.78, 0.36, 0.16)
			im.fill_rect(Rect2i(x0 + 3, y0 + 1, w - 4, 1), hair)            # чёлка
			for k in 6:                                                    # коса
				im.fill_rect(Rect2i(x0 - 3 - k / 2, y0 + 3 + k, 2, 1), hair if k % 2 == 0 else hair.darkened(0.2))
			_px(im, x0 - 6, y0 + 9, Color(0.3, 0.5, 0.27))
			im.fill_rect(Rect2i(ex - 1, ey - 1, 3, 1), Color(0.55, 0.28, 0.12))  # бровь
		"smith":         # кузнец: красная бандана, густая борода, мощная бровь
			var beard := Color(0.42, 0.24, 0.12)
			im.fill_rect(Rect2i(x0 + 1, y0 + h / 2 + 1, w, h / 2 - 1), beard)
			im.fill_rect(Rect2i(x0 + w, y0 + h / 2 + 2, 2, h / 2 - 3), beard)
			im.fill_rect(Rect2i(x0 + w - 5, y0 + h / 2 + 2, 4, 1), beard.lightened(0.15))   # усы
			_px(im, x0 + w - 2, y0 + h - 3, Color(0.6, 0.3, 0.25))
			for k in 3:
				_px(im, x0 + 3 + k * 2, y0 + h - 1 - (k % 2), beard.darkened(0.25))
			_box(im, x0 - 1, y0 - 2, w + 2, 4, Color(0.75, 0.18, 0.14), false)
			im.fill_rect(Rect2i(x0 - 4, y0, 3, 2), Color(0.75, 0.18, 0.14))
			_px(im, x0 - 5, y0 + 2, Color(0.75, 0.18, 0.14))
			im.fill_rect(Rect2i(ex - 1, ey - 2, 4, 1), beard.darkened(0.2))
		"rusty_helm":
			_box(im, x0 - 1, y0 - 2, w + 2, 4, Color(0.45, 0.4, 0.36))
			_px(im, x0 + 3, y0 - 1, Color(0.55, 0.3, 0.15))
			_px(im, x0 + 6, y0, Color(0.55, 0.3, 0.15))
		"hood_dark":     # капюшон некроманта
			var rc: Color = spec["robe"]
			_box(im, x0 - 2, y0 - 3, w + 3, h + 1, rc)
			im.fill_rect(Rect2i(x0 + 3, y0 + 1, w - 3, h - 2), Color(0.04, 0.03, 0.06))
			_px(im, x0 + w / 2, y0 - 4, rc)
		"crown":         # корона короля скелетов
			var gold := Color(0.92, 0.75, 0.25)
			im.fill_rect(Rect2i(x0, y0 - 2, w, 3), gold)
			for i in 4:
				var cx := x0 + 1 + i * (w - 2) / 3
				im.fill_rect(Rect2i(cx - 1, y0 - 6, 2, 4), gold)
				_px(im, cx - 1, y0 - 7, Color(0.9, 0.2, 0.2) if i % 2 == 0 else Color(0.3, 0.6, 1.0))
		"mask":
			_box(im, x0 + w / 2, y0 + 1, w / 2 + 1, h - 2, Color(0.92, 0.9, 0.8))
			im.fill_rect(Rect2i(x0 + w / 2 + 1, ey + 2, w / 2 - 1, 1), Color(0.8, 0.2, 0.2))
			im.fill_rect(Rect2i(ex, ey, 2, 1), DARK)
			for k in 3:
				im.fill_rect(Rect2i(x0 + 1 + k * 3, y0 - 6 + k, 2, 6 - k), Color(0.3, 0.8, 0.6))

func _draw_crown() -> Image:
	var im := _img(40, 24)
	var leaf := Color(0.28, 0.58, 0.22)
	var c := [[10, 14, 9], [20, 10, 11], [30, 14, 9], [15, 18, 7], [26, 18, 7]]
	for b in c:
		for y in range(-b[2], b[2] + 1):
			var hw := int(sqrt(maxf(0.0, float(b[2] * b[2] - y * y))))
			im.fill_rect(Rect2i(b[0] - hw, b[1] + y, hw * 2 + 1, 1), leaf)
	for i in 40:
		_px(im, randi() % 40, randi() % 24, leaf.lightened(0.2) if im.get_pixel(0, 0).a == 0.0 else leaf)
	for i in 30:
		var x := randi() % 40
		var y := randi() % 24
		if im.get_pixel(x, y).a > 0.0:
			_px(im, x, y, leaf.lightened(0.25) if i % 2 == 0 else leaf.darkened(0.2))
	return im

func _draw_dead_crown() -> Image:
	var im := _img(48, 32)
	var bark: Color = spec["skin"].darkened(0.15)
	var moss: Color = spec.get("leaf", bark)
	var mossy := moss.g > bark.g + 0.12
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	# толстые ветви от макушки, на концах — тонкие развилки
	var tips := [Vector2(4, 6), Vector2(12, 1), Vector2(22, 0), Vector2(33, 2), Vector2(44, 8), Vector2(40, 18), Vector2(7, 17)]
	var base := Vector2(24, 31)
	for t in tips:
		var mid: Vector2 = base.lerp(t, 0.55) + Vector2(rng.randf_range(-3, 3), rng.randf_range(-2, 1))
		_thick_line(im, base, mid, bark, 2)
		_thick_line(im, mid, t, bark.lightened(0.05), 1)
		var twig: Vector2 = t + Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, -1))
		_thick_line(im, t, Vector2(clampf(twig.x, 0, 47), clampf(twig.y, 0, 31)), bark.lightened(0.12), 1)
		if mossy:
			# свисающие космы тины
			for k in rng.randi_range(1, 2):
				var mx := int(lerpf(mid.x, t.x, rng.randf()))
				var my := int(lerpf(mid.y, t.y, 0.5))
				for dy in rng.randi_range(3, 7):
					_px(im, mx, mini(my + dy, 31), moss.darkened(0.1 * (dy % 2)))
	return im

func _thick_line(im: Image, a: Vector2, b: Vector2, c: Color, w: int) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in n + 1:
		var q := a.lerp(b, float(i) / float(n))
		for dx in w:
			_px(im, int(q.x) + dx, int(q.y), c)

func _draw_round_shield() -> Image:
	var im := _img(10, 14)
	for y in 14:
		var hw := int(5.0 * sin(PI * (y + 0.5) / 14.0)) + 1
		im.fill_rect(Rect2i(5 - hw, y, hw * 2, 1), Color(0.6, 0.15, 0.12))
	im.fill_rect(Rect2i(4, 5, 2, 4), BRONZE)
	for y in 14:
		var hw := int(5.0 * sin(PI * (y + 0.5) / 14.0)) + 1
		_px(im, 5 - hw, y, BRONZE.darkened(0.2))
		_px(im, 4 + hw, y, BRONZE.darkened(0.2))
	return im

func _draw_weapon(w: String) -> Image:
	var im: Image
	match w:
		"rifle":
			im = _img(14, 5)
			_box(im, 0, 1, 4, 4, WOOD)
			_box(im, 3, 1, 7, 3, Color(0.25, 0.25, 0.28))
			im.fill_rect(Rect2i(10, 2, 4, 1), Color(0.2, 0.2, 0.22))
			im.fill_rect(Rect2i(5, 3, 2, 2), Color(0.2, 0.2, 0.22))
		"pistol":
			im = _img(7, 4)
			_box(im, 0, 0, 7, 2, Color(0.25, 0.25, 0.28), false)
			im.fill_rect(Rect2i(1, 2, 2, 2), Color(0.3, 0.22, 0.15))
		"blowpipe":
			im = _img(10, 2)
			im.fill_rect(Rect2i(0, 0, 10, 2), Color(0.55, 0.45, 0.25))
		"bazooka":
			im = _img(17, 6)
			_box(im, 0, 0, 17, 5, Color(0.32, 0.42, 0.30))
			im.fill_rect(Rect2i(15, 0, 2, 5), DARK)
			im.fill_rect(Rect2i(5, 4, 2, 2), Color(0.2, 0.2, 0.2))
		"cannon":
			im = _img(15, 8)
			_box(im, 0, 1, 12, 6, STEEL.darkened(0.3))
			_box(im, 11, 0, 4, 8, STEEL.darkened(0.45))
		"blunderbuss":
			im = _img(13, 6)
			_box(im, 0, 2, 4, 3, WOOD)
			_box(im, 3, 2, 7, 3, Color(0.45, 0.35, 0.2))
			_box(im, 9, 0, 4, 6, Color(0.5, 0.42, 0.25))
		"spear":
			im = _img(20, 5)
			im.fill_rect(Rect2i(0, 2, 16, 1), WOOD)
			im.fill_rect(Rect2i(16, 1, 3, 3), STEEL)
			_px(im, 19, 2, STEEL.lightened(0.3))
			im.fill_rect(Rect2i(1, 1, 2, 3), Color(0.9, 0.3, 0.2))
		"bomb":
			im = _img(7, 7)
			_box(im, 1, 1, 5, 5, Color(0.15, 0.15, 0.17))
			_px(im, 3, 0, Color(1.0, 0.6, 0.2))
		"staff":
			im = _img(18, 5)
			im.fill_rect(Rect2i(0, 2, 15, 1), WOOD)
			_box(im, 14, 0, 4, 5, Color(0.92, 0.9, 0.8))
			_px(im, 16, 2, Color(0.3, 0.9, 0.5))
		"sword":
			im = _img(18, 5)
			im.fill_rect(Rect2i(0, 1, 3, 3), Color(0.4, 0.25, 0.12))
			im.fill_rect(Rect2i(3, 0, 1, 5), BRONZE)
			_box(im, 4, 1, 13, 3, Color(0.82, 0.84, 0.88))
			_px(im, 17, 2, Color(0.9, 0.92, 0.95))
		"dagger":        # кинжал: короткий клинок, гарда, рукоять с навершием
			im = _img(11, 3)
			im.fill_rect(Rect2i(0, 1, 3, 1), Color(0.35, 0.22, 0.12))
			_px(im, 0, 1, BRONZE)
			im.fill_rect(Rect2i(3, 0, 1, 3), STEEL)
			im.fill_rect(Rect2i(4, 0, 6, 2), Color(0.84, 0.86, 0.9))
			im.fill_rect(Rect2i(4, 2, 5, 1), Color(0.6, 0.62, 0.68))
			_px(im, 10, 1, Color(0.9, 0.92, 0.95))
		"mace":          # булава
			im = _img(15, 7)
			im.fill_rect(Rect2i(0, 3, 10, 1), WOOD)
			im.fill_rect(Rect2i(0, 2, 2, 3), Color(0.25, 0.18, 0.12))
			_box(im, 9, 1, 5, 5, Color(0.45, 0.45, 0.5))
			for c in [[11, 0], [11, 6], [14, 3]]:
				_px(im, c[0], c[1], STEEL.lightened(0.2))
		"pickaxe":       # кирка рудокопа
			im = _img(16, 11)
			im.fill_rect(Rect2i(0, 5, 13, 2), WOOD)
			im.fill_rect(Rect2i(0, 5, 2, 2), WOOD.darkened(0.3))
			for i in 5:
				im.fill_rect(Rect2i(12 + (i % 2), i, 2, 1), STEEL.lightened(0.1 * (i % 2)))
				im.fill_rect(Rect2i(12 + (i % 2), 10 - i, 2, 1), STEEL.darkened(0.1))
			im.fill_rect(Rect2i(11, 4, 3, 4), STEEL.darkened(0.2))
		"dynamite":      # шашка динамита с фитилём
			im = _img(9, 5)
			_box(im, 0, 1, 7, 3, Color(0.85, 0.2, 0.15))
			im.fill_rect(Rect2i(2, 1, 1, 3), Color(0.95, 0.85, 0.6))
			im.fill_rect(Rect2i(7, 2, 2, 1), Color(0.3, 0.25, 0.2))
			_px(im, 8, 1, Color(1.0, 0.85, 0.3))
		"gem_staff":     # посох с самоцветом
			im = _img(19, 7)
			im.fill_rect(Rect2i(0, 3, 15, 1), WOOD.lightened(0.1))
			im.fill_rect(Rect2i(13, 1, 1, 5), BRONZE)
			for y in range(1, 6):
				var hw := 2 - absi(y - 3)
				im.fill_rect(Rect2i(16 - hw, y, hw * 2 + 1, 1), Color(0.3, 0.85, 0.5))
			_px(im, 15, 2, Color(1, 1, 1))
		"crystal_sword": # кристальный меч
			im = _img(20, 5)
			im.fill_rect(Rect2i(0, 1, 3, 3), Color(0.3, 0.3, 0.45))
			im.fill_rect(Rect2i(3, 0, 1, 5), Color(0.7, 0.85, 1.0))
			for x in range(4, 19):
				var hw := 1 if x < 17 else 0
				im.fill_rect(Rect2i(x, 2 - hw, 1, hw * 2 + 1), Color(0.6, 0.85, 1.0).lightened(0.15 * float(x % 3 == 0)))
			_px(im, 19, 2, Color(1, 1, 1))
		"echo_lantern":  # посох путника: тёмное древко, на крюке — фонарь с лиловым огнём
			var ep: Array = spec.get("wpal", [Color(0.30, 0.25, 0.22), Color(0.55, 0.50, 0.66), Color(0.22, 0.20, 0.28), Color(0.72, 0.48, 1.0), Color(0.95, 0.88, 1.0)])
			im = _img(26, 13)
			im.fill_rect(Rect2i(0, 6, 19, 1), ep[0])
			im.fill_rect(Rect2i(0, 5, 2, 3), ep[1])
			im.fill_rect(Rect2i(18, 2, 1, 5), ep[0])              # крюк
			im.fill_rect(Rect2i(19, 2, 3, 1), ep[0])
			im.fill_rect(Rect2i(19, 4, 6, 8), ep[2])              # рамка фонаря
			im.fill_rect(Rect2i(20, 5, 4, 6), ep[3])
			im.fill_rect(Rect2i(21, 6, 2, 3), ep[4])
		"needle_spear":  # игла-копьё: длинная серебряная игла, в ушко продета золотая нить
			var np: Array = spec.get("wpal", [Color(0.80, 0.80, 0.88), Color(0.62, 0.52, 0.40), Color(0.95, 0.95, 1.0), Color(1.0, 0.82, 0.35)])
			im = _img(26, 13)
			im.fill_rect(Rect2i(0, 6, 22, 1), np[0])
			im.fill_rect(Rect2i(0, 5, 3, 3), np[1])
			im.fill_rect(Rect2i(22, 6, 3, 1), np[2])                # остриё
			_px(im, 25, 6, Color(1, 1, 1))
			im.fill_rect(Rect2i(3, 4, 3, 1), np[0])                # ушко
			im.fill_rect(Rect2i(3, 8, 3, 1), np[0])
			for k in 9:
				_px(im, 4 + k * 2, 9 + int(k % 3 == 1), np[3])        # нить вьётся вдоль иглы
		"key_staff":     # посох-ключ: тёмное древко, золотое кольцо ключа с фиолетовым камнем, бородка
			var kp: Array = spec.get("wpal", [Color(0.34, 0.26, 0.20), Color(0.86, 0.70, 0.36), Color(1.0, 0.82, 0.38), Color(0.86, 0.66, 0.30), Color(0.70, 0.45, 1.0), Color(0.95, 0.88, 1.0)])
			im = _img(26, 13)
			im.fill_rect(Rect2i(0, 6, 19, 1), kp[0])
			im.fill_rect(Rect2i(0, 5, 2, 3), kp[1])
			im.fill_rect(Rect2i(9, 5, 1, 3), kp[1])              # кольца на древке
			for y in 13:
				for x in range(18, 26):
					var d := Vector2(x - 21.5, y - 6.0).length()
					if d <= 4.6 and d >= 2.6:
						_px(im, x, y, kp[2] if y < 7 else kp[3])
			_box(im, 20, 5, 3, 3, kp[4], false)                  # камень в кольце
			_px(im, 21, 5, kp[5])
			im.fill_rect(Rect2i(13, 7, 4, 1), kp[2])              # бородка ключа
			im.fill_rect(Rect2i(13, 8, 1, 3), kp[2])
			im.fill_rect(Rect2i(15, 8, 1, 2), kp[2])
		"prism_staff":   # посох-призма: серебряное древко и треугольный кристалл
			im = _img(22, 11)
			im.fill_rect(Rect2i(0, 5, 15, 1), Color(0.78, 0.78, 0.86))
			im.fill_rect(Rect2i(0, 4, 2, 3), Color(0.55, 0.5, 0.7))
			im.fill_rect(Rect2i(14, 3, 1, 5), Color(0.75, 0.55, 1.0))
			for y in 11:
				var hw := int(round(3.5 * (1.0 - absf(y - 5) / 5.5)))
				im.fill_rect(Rect2i(18 - hw, y, hw * 2 + 1, 1), Color(0.85, 0.92, 1.0) if y < 5 else Color(0.70, 0.75, 1.0))
			_px(im, 17, 3, Color(1, 1, 1))
		"javelin":
			im = _img(22, 3)
			im.fill_rect(Rect2i(0, 1, 18, 1), Color(0.6, 0.45, 0.25))
			im.fill_rect(Rect2i(18, 0, 4, 3), STEEL.lightened(0.1))
		"trident":
			im = _img(22, 7)
			im.fill_rect(Rect2i(0, 3, 17, 1), Color(0.55, 0.42, 0.25))
			im.fill_rect(Rect2i(17, 0, 1, 7), STEEL)
			for yy in [0, 3, 6]:
				im.fill_rect(Rect2i(17, yy, 5, 1), STEEL.lightened(0.15))
		"sling":
			im = _img(8, 4)
			im.fill_rect(Rect2i(0, 1, 6, 1), Color(0.55, 0.4, 0.22))
			_box(im, 5, 0, 3, 3, Color(0.5, 0.5, 0.5), false)
		"bone":
			im = _img(9, 4)
			im.fill_rect(Rect2i(1, 1, 7, 2), BONE)
			for x in [0, 7]:
				im.fill_rect(Rect2i(x, 0, 2, 4), BONE)
		"greatsword":
			im = _img(30, 7)
			im.fill_rect(Rect2i(0, 2, 5, 3), Color(0.25, 0.18, 0.12))
			im.fill_rect(Rect2i(5, 0, 2, 7), Color(0.85, 0.7, 0.25))
			_box(im, 7, 1, 21, 5, Color(0.55, 0.58, 0.66))
			im.fill_rect(Rect2i(8, 3, 19, 1), Color(0.35, 0.37, 0.45))
			im.fill_rect(Rect2i(28, 2, 2, 3), Color(0.6, 0.63, 0.7))
		"branch":        # посох-ветка с листьями
			im = _img(22, 9)
			im.fill_rect(Rect2i(0, 4, 17, 2), Color(0.45, 0.32, 0.18))
			im.fill_rect(Rect2i(12, 2, 1, 2), Color(0.45, 0.32, 0.18))
			for c in [[17, 2], [19, 5], [16, 6], [20, 1], [14, 0]]:
				_box(im, c[0], c[1], 3, 3, Color(0.35, 0.65, 0.28), false)
		"scythe":        # коса Мортиса
			im = _img(24, 14)
			im.fill_rect(Rect2i(0, 6, 20, 2), Color(0.22, 0.17, 0.2))
			for i in 9:
				im.fill_rect(Rect2i(19 - i, 6 - (i * 2) / 3 - 1 + i / 2, 2, 2), Color(0.78, 0.78, 0.85))
			im.fill_rect(Rect2i(19, 0, 3, 7), Color(0.78, 0.78, 0.85))
			im.fill_rect(Rect2i(21, 0, 1, 5), Color(0.95, 0.95, 1.0))
		"bow":
			im = _img(8, 16)
			for y in 16:
				var bx := int(3.0 * sin(PI * y / 15.0))
				im.set_pixel(bx, y, Color(0.5, 0.35, 0.2))
				im.set_pixel(bx + 1, y, Color(0.45, 0.3, 0.17))
			im.fill_rect(Rect2i(0, 0, 1, 16), Color(0.9, 0.9, 0.85, 0.8))
		"assault":       # автомат с магазином и прицелом
			im = _img(17, 7)
			_box(im, 0, 2, 4, 4, Color(0.18, 0.18, 0.2))
			_box(im, 3, 1, 10, 3, Color(0.22, 0.22, 0.24))
			im.fill_rect(Rect2i(13, 2, 4, 1), Color(0.15, 0.15, 0.17))
			im.fill_rect(Rect2i(7, 4, 2, 3), Color(0.25, 0.22, 0.15))       # магазин
			im.fill_rect(Rect2i(5, 0, 3, 1), Color(0.12, 0.12, 0.14))       # прицел
			im.fill_rect(Rect2i(4, 4, 1, 2), Color(0.15, 0.15, 0.17))
		"knife":         # боевой нож
			im = _img(10, 3)
			im.fill_rect(Rect2i(0, 0, 3, 3), Color(0.15, 0.13, 0.12))
			im.fill_rect(Rect2i(3, 0, 1, 3), Color(0.4, 0.4, 0.42))
			im.fill_rect(Rect2i(4, 1, 6, 1), Color(0.85, 0.87, 0.9))
			im.fill_rect(Rect2i(4, 0, 4, 1), Color(0.6, 0.62, 0.66))
		"radio":         # рация с антенной
			im = _img(4, 9)
			_box(im, 0, 3, 4, 6, Color(0.2, 0.22, 0.2))
			im.fill_rect(Rect2i(1, 0, 1, 3), Color(0.1, 0.1, 0.1))
			im.set_pixel(2, 5, Color(0.3, 1.0, 0.3))
		"katana":        # катана: оплётка рукояти, цуба, длинный клинок
			im = _img(28, 3)
			for x in 7:
				im.fill_rect(Rect2i(x, 0, 1, 3), Color(0.1, 0.08, 0.1) if x % 2 == 0 else Color(0.9, 0.88, 0.85))
			im.fill_rect(Rect2i(7, 0, 1, 3), Color(0.85, 0.7, 0.25))
			im.fill_rect(Rect2i(8, 0, 19, 2), Color(0.85, 0.88, 0.92))
			im.fill_rect(Rect2i(8, 2, 18, 1), Color(0.6, 0.62, 0.68))
			im.set_pixel(27, 0, Color(0.95, 0.97, 1.0))
		"longbow":       # длинный лук Охотницы (тетива рисуется линией)
			im = _img(7, 26)
			for y in 26:
				var bx := 1 + int(4.0 * sin(PI * y / 25.0))
				im.set_pixel(bx, y, Color(0.55, 0.36, 0.18))
				im.set_pixel(bx + 1, y, Color(0.42, 0.27, 0.14))
			im.fill_rect(Rect2i(4, 11, 2, 4), Color(0.25, 0.4, 0.22))          # обмотка рукояти
			im.fill_rect(Rect2i(1, 0, 2, 1), Color(0.9, 0.85, 0.6))
			im.fill_rect(Rect2i(1, 25, 2, 1), Color(0.9, 0.85, 0.6))
		"hammer":        # тяжёлый кузнечный молот
			im = _img(24, 11)
			im.fill_rect(Rect2i(0, 4, 16, 3), WOOD)
			im.fill_rect(Rect2i(0, 4, 3, 3), Color(0.25, 0.18, 0.12))             # оплётка рукояти
			im.fill_rect(Rect2i(5, 4, 1, 3), WOOD.darkened(0.3))
			_box(im, 15, 0, 9, 11, Color(0.38, 0.38, 0.42))
			im.fill_rect(Rect2i(16, 1, 7, 2), Color(0.62, 0.62, 0.68))
			im.fill_rect(Rect2i(22, 2, 1, 7), Color(0.72, 0.72, 0.78))            # боёк
			im.fill_rect(Rect2i(15, 5, 9, 1), Color(0.28, 0.28, 0.3))
		# ----- Оружие обликов Призмы (посох 22x11) -----
		"ember_prism_staff", "void_prism_staff", "sun_prism_staff", "ice_prism_staff":
			var pp: Array = {"ember_prism_staff": [Color(0.20, 0.12, 0.10), Color(1.0, 0.50, 0.12), Color(1.0, 0.86, 0.40)],
					"ice_prism_staff": [Color(0.40, 0.55, 0.72), Color(0.45, 0.80, 1.0), Color(0.92, 0.99, 1.0)],
					"void_prism_staff": [Color(0.12, 0.08, 0.17), Color(0.40, 0.18, 0.62), Color(0.80, 0.55, 1.0)],
					"sun_prism_staff": [Color(1.0, 0.82, 0.38), Color(1.0, 0.92, 0.70), Color(1.0, 1.0, 0.96)]}[w]
			im = _img(22, 11)
			im.fill_rect(Rect2i(0, 5, 15, 1), pp[0])
			im.fill_rect(Rect2i(0, 4, 2, 3), pp[1].darkened(0.3))
			im.fill_rect(Rect2i(14, 3, 1, 5), pp[1])
			for y in 11:
				var hw := int(round(3.5 * (1.0 - absf(y - 5) / 5.5)))
				im.fill_rect(Rect2i(18 - hw, y, hw * 2 + 1, 1), pp[2] if y < 5 else pp[1])
			_px(im, 17, 3, Color(1, 1, 1))
			_px(im, 18, 5, pp[2].lightened(0.3))
		# ----- Оружие обликов Чемпиона (копьё 20x5) -----
		"ember_spear", "void_spear", "sun_spear", "ice_spear":
			var sp2: Array = {"ember_spear": [Color(0.20, 0.12, 0.10), Color(1.0, 0.50, 0.12), Color(1.0, 0.86, 0.40)],
					"ice_spear": [Color(0.66, 0.80, 0.94), Color(0.50, 0.84, 1.0), Color(0.95, 1.0, 1.0)],
					"void_spear": [Color(0.12, 0.08, 0.17), Color(0.72, 0.40, 1.0), Color(0.95, 0.85, 1.0)],
					"sun_spear": [Color(0.96, 0.93, 0.86), Color(1.0, 0.80, 0.32), Color(1.0, 1.0, 0.92)]}[w]
			im = _img(20, 5)
			im.fill_rect(Rect2i(0, 2, 16, 1), sp2[0])
			im.fill_rect(Rect2i(16, 1, 3, 3), sp2[1])
			_px(im, 19, 2, sp2[2])
			_px(im, 17, 0, sp2[1].darkened(0.2))
			_px(im, 17, 4, sp2[1].darkened(0.2))
			im.fill_rect(Rect2i(1, 1, 2, 3), sp2[1])
		# ----- Оружие обликов Осоки (коряга с фонарём 22x9) -----
		"ember_lantern", "void_lantern", "lotus_staff", "frost_lantern":
			var lp: Array = {"ember_lantern": [Color(0.20, 0.12, 0.10), Color(1.0, 0.50, 0.12), Color(1.0, 0.86, 0.40)],
					"frost_lantern": [Color(0.42, 0.55, 0.70), Color(0.45, 0.82, 1.0), Color(0.94, 0.99, 1.0)],
					"void_lantern": [Color(0.12, 0.08, 0.17), Color(0.62, 0.32, 0.92), Color(0.95, 0.85, 1.0)],
					"lotus_staff": [Color(0.96, 0.93, 0.86), Color(1.0, 0.80, 0.32), Color(1.0, 1.0, 0.92)]}[w]
			im = _img(22, 9)
			for x in 18:
				im.set_pixel(x, 4 + int(round(sin(x * 0.55) * 0.8)), lp[0])
			_px(im, 6, 2, lp[0])
			_px(im, 7, 1, lp[1])
			_px(im, 18, 4, lp[0])
			_px(im, 19, 5, lp[0])
			im.fill_rect(Rect2i(19, 6, 3, 1), lp[1].darkened(0.4))
			im.fill_rect(Rect2i(19, 7, 3, 2), lp[1])
			_px(im, 20, 7, lp[2])
		# ----- Оружие обликов Ассасина (кама 17x12) -----
		"ember_kama", "void_kama", "sun_kama", "ice_kama":
			var kp: Array = {"ember_kama": [Color(0.20, 0.10, 0.08), Color(0.24, 0.18, 0.18), Color(1.0, 0.50, 0.12), Color(1.0, 0.86, 0.40)],
					"ice_kama": [Color(0.25, 0.38, 0.55), Color(0.80, 0.92, 1.0), Color(0.45, 0.82, 1.0), Color(0.96, 1.0, 1.0)],
					"void_kama": [Color(0.12, 0.08, 0.17), Color(0.08, 0.06, 0.11), Color(0.72, 0.40, 1.0), Color(0.95, 0.85, 1.0)],
					"sun_kama": [Color(0.96, 0.93, 0.86), Color(1.0, 0.95, 0.85), Color(1.0, 0.80, 0.32), Color(1.0, 1.0, 0.95)]}[w]
			im = _img(17, 12)
			for x in 10:
				im.fill_rect(Rect2i(x, 9, 1, 2), kp[0] if x % 3 != 0 else kp[2].darkened(0.3))
			for i in 10:
				var bx := 9 + int(round(6.0 * sin(PI * 0.5 * i / 9.0)))
				var by := 9 - i
				im.fill_rect(Rect2i(bx, by, 2, 1), kp[1])
				_px(im, bx + 1, by, kp[2])                                                     # кромка светится
			_px(im, 15, 0, kp[3])
			im.fill_rect(Rect2i(9, 8, 2, 4), kp[2].darkened(0.2))
		# ----- Оружие обликов Терновника (ветка 22x9) -----
		"ember_branch", "void_branch", "bloom_branch", "frost_branch":
			var bp: Array = {"ember_branch": [Color(0.18, 0.10, 0.08), Color(1.0, 0.48, 0.12), Color(1.0, 0.86, 0.40)],
					"frost_branch": [Color(0.36, 0.48, 0.62), Color(0.55, 0.86, 1.0), Color(0.95, 1.0, 1.0)],
					"void_branch": [Color(0.12, 0.08, 0.16), Color(0.55, 0.28, 0.85), Color(0.90, 0.70, 1.0)],
					"bloom_branch": [Color(0.94, 0.92, 0.86), Color(1.0, 0.80, 0.32), Color(1.0, 1.0, 0.95)]}[w]
			im = _img(22, 9)
			im.fill_rect(Rect2i(0, 4, 17, 2), bp[0])
			for x in range(2, 16, 4):
				_px(im, x, 4 + (x / 4) % 2, bp[1].darkened(0.2))                               # трещины / жилки / узор коры
			im.fill_rect(Rect2i(12, 2, 1, 2), bp[0])
			for c in [[17, 2], [19, 5], [16, 6], [20, 1], [14, 0]]:
				_box(im, c[0], c[1], 3, 3, bp[1], false)
				_px(im, c[0] + 1, c[1] + 1, bp[2])
		# ----- Оружие обликов Мортиса (коса 24x14) -----
		"pyre_scythe", "void_scythe", "sun_scythe", "frost_scythe":
			var sp: Array = {"pyre_scythe": [Color(0.16, 0.10, 0.08), Color(0.30, 0.20, 0.18), Color(1.0, 0.50, 0.12)],
					"frost_scythe": [Color(0.30, 0.42, 0.56), Color(0.62, 0.86, 1.0), Color(0.95, 1.0, 1.0)],
					"void_scythe": [Color(0.12, 0.08, 0.17), Color(0.10, 0.07, 0.14), Color(0.72, 0.40, 1.0)],
					"sun_scythe": [Color(0.96, 0.93, 0.86), Color(1.0, 0.85, 0.45), Color(1.0, 1.0, 0.92)]}[w]
			im = _img(24, 14)
			im.fill_rect(Rect2i(0, 6, 20, 2), sp[0])
			for x in [3, 9, 15]:
				_px(im, x, 6, sp[2].darkened(0.25))                                               # кольца / руны на древке
			for i in 9:
				im.fill_rect(Rect2i(19 - i, 6 - (i * 2) / 3 - 1 + i / 2, 2, 2), sp[1])
				_px(im, 19 - i, 6 - (i * 2) / 3 + i / 2, sp[2])                                    # светящаяся кромка
			im.fill_rect(Rect2i(19, 0, 3, 7), sp[1])
			im.fill_rect(Rect2i(21, 0, 1, 5), sp[2])
			_px(im, 20, 0, sp[2].lightened(0.3))
		# ----- Оружие обликов Солдата (автомат 17x7) -----
		"flame_rifle":   # закопчённый автомат: раскалённые прорези на стволе, канистра-магазин, огонёк у дула
			im = _img(17, 7)
			_box(im, 0, 2, 4, 4, Color(0.14, 0.11, 0.10))
			_box(im, 3, 1, 10, 3, Color(0.18, 0.13, 0.11))
			for x in [5, 8, 11]:
				im.fill_rect(Rect2i(x, 2, 1, 1), Color(1.0, 0.50, 0.12))
			im.fill_rect(Rect2i(13, 2, 4, 1), Color(0.30, 0.16, 0.10))
			im.fill_rect(Rect2i(16, 2, 1, 1), Color(1.0, 0.86, 0.40))
			im.fill_rect(Rect2i(7, 4, 2, 3), Color(0.75, 0.18, 0.08))
			im.fill_rect(Rect2i(7, 5, 2, 1), Color(1.0, 0.55, 0.15))
			im.fill_rect(Rect2i(5, 0, 3, 1), Color(0.10, 0.08, 0.07))
		"frost_rifle":   # морозный автомат: светлый корпус, голубые трубки охладителя, баллон-магазин в инее
			im = _img(17, 7)
			_box(im, 0, 2, 4, 4, Color(0.70, 0.78, 0.86))
			_box(im, 3, 1, 10, 3, Color(0.78, 0.84, 0.90))
			for x in range(4, 13):
				_px(im, x, 2, Color(0.45, 0.82, 1.0) if x % 2 == 0 else Color(0.30, 0.55, 0.85))
			im.fill_rect(Rect2i(13, 2, 4, 1), Color(0.55, 0.62, 0.70))
			_px(im, 16, 2, Color(0.94, 1.0, 1.0))
			im.fill_rect(Rect2i(7, 4, 3, 3), Color(0.45, 0.80, 1.0))                    # баллон
			_px(im, 8, 5, Color(0.94, 1.0, 1.0))
			_px(im, 9, 6, Color(0.85, 0.95, 1.0))
			im.fill_rect(Rect2i(5, 0, 3, 1), Color(0.40, 0.48, 0.58))
		"void_rifle":    # чёрно-лиловый автомат: спираль энергии по стволу, кристалл-магазин
			im = _img(17, 7)
			_box(im, 0, 2, 4, 4, Color(0.10, 0.07, 0.14))
			_box(im, 3, 1, 10, 3, Color(0.13, 0.09, 0.19))
			for x in range(4, 16):
				_px(im, x, 2 + (x % 2), Color(0.55, 0.28, 0.85) if x < 13 else Color(0.72, 0.40, 1.0))
			_px(im, 16, 2, Color(0.95, 0.85, 1.0))
			im.fill_rect(Rect2i(7, 4, 2, 3), Color(0.72, 0.40, 1.0))
			_px(im, 7, 5, Color(0.95, 0.85, 1.0))
			im.fill_rect(Rect2i(5, 0, 3, 1), Color(0.40, 0.20, 0.60))
		"sun_rifle":     # бело-золотой автомат с гравировкой и солнцем на прикладе
			im = _img(17, 7)
			_box(im, 0, 2, 4, 4, Color(0.94, 0.91, 0.84))
			_px(im, 1, 3, Color(1.0, 0.60, 0.15))
			_box(im, 3, 1, 10, 3, Color(0.96, 0.93, 0.86))
			im.fill_rect(Rect2i(4, 2, 8, 1), Color(1.0, 0.80, 0.32))
			im.fill_rect(Rect2i(13, 2, 4, 1), Color(1.0, 0.80, 0.32))
			_px(im, 16, 2, Color(1.0, 0.98, 0.88))
			im.fill_rect(Rect2i(7, 4, 2, 3), Color(1.0, 0.80, 0.32))
			im.fill_rect(Rect2i(5, 0, 3, 1), Color(0.85, 0.65, 0.25))
		# ----- Оружие обликов Самурая (катана 28x3) -----
		"ember_katana":  # тёмный клинок с раскалённой кромкой, чёрно-алая оплётка
			im = _img(28, 3)
			for x in 7:
				im.fill_rect(Rect2i(x, 0, 1, 3), Color(0.10, 0.06, 0.06) if x % 2 == 0 else Color(0.80, 0.20, 0.08))
			im.fill_rect(Rect2i(7, 0, 1, 3), Color(0.85, 0.55, 0.15))
			im.fill_rect(Rect2i(8, 0, 19, 1), Color(1.0, 0.55, 0.15))
			im.fill_rect(Rect2i(8, 1, 19, 1), Color(0.26, 0.20, 0.20))
			im.fill_rect(Rect2i(8, 2, 18, 1), Color(0.16, 0.12, 0.12))
			im.set_pixel(27, 0, Color(1.0, 0.90, 0.55))
		"ice_katana":    # клинок изо льда: прозрачно-голубой, белая кромка, бело-синяя оплётка, блики внутри
			im = _img(28, 3)
			for x in 7:
				im.fill_rect(Rect2i(x, 0, 1, 3), Color(0.92, 0.96, 1.0) if x % 2 == 0 else Color(0.25, 0.42, 0.65))
			im.fill_rect(Rect2i(7, 0, 1, 3), Color(0.70, 0.90, 1.0))
			im.fill_rect(Rect2i(8, 0, 19, 1), Color(0.96, 1.0, 1.0))
			im.fill_rect(Rect2i(8, 1, 19, 1), Color(0.60, 0.85, 1.0, 0.9))
			im.fill_rect(Rect2i(8, 2, 18, 1), Color(0.40, 0.68, 0.95, 0.85))
			for x in [12, 17, 22]:
				im.set_pixel(x, 1, Color(0.94, 0.99, 1.0))
			im.set_pixel(27, 0, Color(1, 1, 1))
		"void_katana":   # чёрный клинок, по кромке — лиловый свет разлома
			im = _img(28, 3)
			for x in 7:
				im.fill_rect(Rect2i(x, 0, 1, 3), Color(0.08, 0.06, 0.10) if x % 2 == 0 else Color(0.45, 0.24, 0.65))
			im.fill_rect(Rect2i(7, 0, 1, 3), Color(0.72, 0.40, 1.0))
			im.fill_rect(Rect2i(8, 0, 19, 1), Color(0.72, 0.40, 1.0))
			im.fill_rect(Rect2i(8, 1, 19, 1), Color(0.10, 0.07, 0.14))
			im.fill_rect(Rect2i(8, 2, 18, 1), Color(0.06, 0.04, 0.09))
			im.set_pixel(27, 0, Color(0.95, 0.85, 1.0))
		"sun_katana":    # сияющий белый клинок, золотая цуба и обух, бело-золотая оплётка
			im = _img(28, 3)
			for x in 7:
				im.fill_rect(Rect2i(x, 0, 1, 3), Color(0.96, 0.94, 0.88) if x % 2 == 0 else Color(1.0, 0.80, 0.32))
			im.fill_rect(Rect2i(7, 0, 1, 3), Color(1.0, 0.80, 0.32))
			im.fill_rect(Rect2i(8, 0, 19, 2), Color(1.0, 0.99, 0.94))
			im.fill_rect(Rect2i(8, 2, 18, 1), Color(1.0, 0.80, 0.32))
			im.set_pixel(27, 0, Color(1.0, 1.0, 1.0))
		# ----- Оружие обликов Пивозавра (бутылка 13x5) -----
		"molotov":       # янтарная бутылка, в горлышке — тряпка, она горит
			im = _img(13, 5)
			_box(im, 0, 0, 8, 5, Color(0.62, 0.32, 0.10))
			im.fill_rect(Rect2i(8, 1, 3, 3), Color(0.62, 0.32, 0.10))
			im.fill_rect(Rect2i(1, 1, 5, 3), Color(0.90, 0.80, 0.60))
			im.fill_rect(Rect2i(2, 2, 3, 1), Color(0.85, 0.20, 0.10))
			im.fill_rect(Rect2i(11, 1, 2, 3), Color(0.80, 0.75, 0.62))                  # тряпка
			im.fill_rect(Rect2i(7, 0, 3, 1), Color(0.95, 0.65, 0.30))
		"ice_bottle":    # запотевшая бутылка «со льда»: голубое стекло в инее, внутри кубики льда, ярлык-снежинка
			im = _img(13, 5)
			_box(im, 0, 0, 8, 5, Color(0.55, 0.78, 0.92))
			im.fill_rect(Rect2i(8, 1, 4, 3), Color(0.55, 0.78, 0.92))
			im.fill_rect(Rect2i(1, 1, 4, 3), Color(0.94, 0.98, 1.0))                    # ярлык
			_px(im, 2, 2, Color(0.35, 0.65, 0.95))
			_px(im, 3, 1, Color(0.35, 0.65, 0.95))
			_px(im, 3, 3, Color(0.35, 0.65, 0.95))
			_px(im, 4, 2, Color(0.35, 0.65, 0.95))
			for c in [[6, 1], [7, 3], [9, 2]]:
				_px(im, c[0], c[1], Color(0.94, 1.0, 1.0))                             # кубики льда
			im.fill_rect(Rect2i(12, 0, 1, 5), Color(0.80, 0.90, 1.0))                   # крышка
			for c in [[0, 0], [5, 4], [10, 1]]:
				_px(im, c[0], c[1], Color(0.92, 0.98, 1.0, 0.8))                       # иней на стекле
		"void_flask":    # чёрная бутыль, внутри светится лиловое зелье, на ярлыке — руна
			im = _img(13, 5)
			_box(im, 0, 0, 8, 5, Color(0.10, 0.07, 0.14))
			im.fill_rect(Rect2i(1, 2, 6, 2), Color(0.55, 0.28, 0.85))
			im.fill_rect(Rect2i(8, 1, 4, 3), Color(0.10, 0.07, 0.14))
			_px(im, 3, 1, Color(0.95, 0.85, 1.0))
			_px(im, 4, 2, Color(0.95, 0.85, 1.0))
			im.fill_rect(Rect2i(12, 1, 1, 3), Color(0.72, 0.40, 1.0))
		"gold_bottle":   # золотая бутылка с белым ярлыком и крышкой-короной
			im = _img(13, 5)
			_box(im, 0, 0, 8, 5, Color(0.95, 0.75, 0.28))
			im.fill_rect(Rect2i(8, 1, 4, 3), Color(0.95, 0.75, 0.28))
			im.fill_rect(Rect2i(1, 1, 5, 3), Color(0.98, 0.96, 0.90))
			_px(im, 3, 2, Color(0.85, 0.15, 0.15))
			im.fill_rect(Rect2i(12, 0, 1, 5), Color(1.0, 0.92, 0.55))
			im.fill_rect(Rect2i(7, 0, 4, 1), Color(1.0, 0.98, 0.85))
		# ----- Оружие обликов Охотницы (лук 7x26, тетива — линией) -----
		"flame_bow":     # обугленный лук с тлеющими трещинами, на концах — язычки пламени
			im = _img(7, 26)
			for y in 26:
				var bx := 1 + int(4.0 * sin(PI * y / 25.0))
				var crack := y % 4 == 2
				im.set_pixel(bx, y, Color(1.0, 0.50, 0.12) if crack else Color(0.22, 0.13, 0.10))
				im.set_pixel(mini(bx + 1, 6), y, Color(0.14, 0.08, 0.07) if not crack else Color(1.0, 0.80, 0.35))
			im.fill_rect(Rect2i(4, 11, 2, 4), Color(0.85, 0.30, 0.08))
			for t in [[1, 0], [2, 1], [1, 25], [2, 24]]:
				im.set_pixel(t[0], t[1], Color(1.0, 0.86, 0.40))
		"ice_bow":       # лук изо льда: прозрачная голубая дуга, внутри белая жилка, на концах — кристаллы
			im = _img(7, 26)
			for y in 26:
				var bx := 1 + int(4.0 * sin(PI * y / 25.0))
				im.set_pixel(bx, y, Color(0.55, 0.82, 1.0, 0.95))
				im.set_pixel(mini(bx + 1, 6), y, Color(0.94, 0.99, 1.0) if y % 5 == 2 else Color(0.35, 0.62, 0.90, 0.9))
			im.fill_rect(Rect2i(4, 11, 3, 4), Color(0.30, 0.45, 0.62))                 # рукоять обмотана
			im.set_pixel(5, 12, Color(0.85, 0.95, 1.0))
			for t in [[0, 0], [1, 0], [0, 1], [2, 1], [0, 25], [1, 25], [0, 24], [2, 24]]:
				im.set_pixel(t[0], t[1], Color(0.95, 1.0, 1.0))                         # кристаллы на концах
		"void_bow":      # лук из чёрной кости: концы загнуты клинками, в рукояти — лиловый глаз
			im = _img(7, 26)
			for y in 26:
				var bx := 1 + int(4.0 * sin(PI * y / 25.0))
				im.set_pixel(bx, y, Color(0.16, 0.11, 0.22))
				im.set_pixel(mini(bx + 1, 6), y, Color(0.30, 0.18, 0.42) if y % 3 == 0 else Color(0.10, 0.07, 0.14))
			for t in [[0, 0], [0, 1], [2, 2], [0, 25], [0, 24], [2, 23]]:
				im.set_pixel(t[0], t[1], Color(0.72, 0.40, 1.0))
			im.fill_rect(Rect2i(4, 11, 3, 4), Color(0.10, 0.07, 0.14))
			im.fill_rect(Rect2i(5, 12, 1, 2), Color(0.92, 0.70, 1.0))
		"sun_bow":       # бело-золотой лук, на концах — крылышки перьев, в рукояти — солнце
			im = _img(7, 26)
			for y in 26:
				var bx := 1 + int(4.0 * sin(PI * y / 25.0))
				im.set_pixel(bx, y, Color(0.98, 0.94, 0.80))
				im.set_pixel(mini(bx + 1, 6), y, Color(1.0, 0.78, 0.30))
			for t in [[3, 0], [4, 1], [3, 2], [3, 25], [4, 24], [3, 23]]:
				im.set_pixel(t[0], t[1], Color(1.0, 0.98, 0.88))
			im.fill_rect(Rect2i(4, 11, 3, 4), Color(1.0, 0.78, 0.30))
			im.fill_rect(Rect2i(5, 12, 1, 2), Color(1.0, 1.0, 0.92))
		# ----- Оружие обликов Кузнеца (молот 24x11) -----
		"glacier_hammer":  # молот-ледник: глыба голубого льда в стальных обручах, рукоять в инее
			im = _img(24, 11)
			im.fill_rect(Rect2i(0, 4, 16, 3), Color(0.30, 0.40, 0.52))
			im.fill_rect(Rect2i(0, 4, 3, 3), Color(0.55, 0.65, 0.78))
			for x in range(4, 15, 3):
				_px(im, x, 4, Color(0.85, 0.95, 1.0))                                   # иней на рукояти
			_box(im, 15, 0, 9, 11, Color(0.55, 0.80, 0.96))
			for k in 6:
				_px(im, 16 + k, 2 + (k * 3) % 7, Color(0.94, 0.99, 1.0))                # трещинки во льду
			im.fill_rect(Rect2i(17, 0, 1, 11), Color(0.40, 0.48, 0.58))                # стальные обручи
			im.fill_rect(Rect2i(21, 0, 1, 11), Color(0.40, 0.48, 0.58))
			im.fill_rect(Rect2i(18, 4, 3, 3), Color(0.35, 0.75, 1.0))                  # голубое ядро
			_px(im, 19, 5, Color(0.94, 1.0, 1.0))
			im.fill_rect(Rect2i(23, 1, 1, 9), Color(0.92, 0.98, 1.0))                  # боёк
		"lava_hammer":   # базальтовый молот, по нему бегут трещины лавы, боёк раскалён
			im = _img(24, 11)
			im.fill_rect(Rect2i(0, 4, 16, 3), Color(0.20, 0.13, 0.10))
			im.fill_rect(Rect2i(0, 4, 3, 3), Color(0.85, 0.30, 0.08))
			for x in range(5, 15, 4):
				im.fill_rect(Rect2i(x, 4, 1, 3), Color(1.0, 0.50, 0.12))
			_box(im, 15, 0, 9, 11, Color(0.18, 0.15, 0.15))
			for k in 9:
				_px(im, 16 + k % 6, 1 + k, Color(1.0, 0.50, 0.12) if k % 3 else Color(1.0, 0.86, 0.40))
			im.fill_rect(Rect2i(22, 1, 1, 9), Color(1.0, 0.70, 0.25))            # раскалённый боёк
		"void_maul":     # молот из обсидиана: лиловые руны, шипы-полумесяцы, рукоять из чёрной кости
			im = _img(24, 11)
			im.fill_rect(Rect2i(0, 4, 16, 3), Color(0.14, 0.10, 0.20))
			for x in range(2, 15, 3):
				_px(im, x, 5, Color(0.55, 0.30, 0.85))
			_box(im, 15, 1, 9, 9, Color(0.10, 0.07, 0.14))
			for k in 3:
				_px(im, 17 + k * 2, 3 + (k % 2) * 3, Color(0.85, 0.55, 1.0))           # руны
			im.fill_rect(Rect2i(18, 0, 3, 1), Color(0.72, 0.40, 1.0))             # шипы
			im.fill_rect(Rect2i(18, 10, 3, 1), Color(0.72, 0.40, 1.0))
			im.fill_rect(Rect2i(23, 2, 1, 7), Color(0.72, 0.40, 1.0))
		"sun_hammer":    # бело-золотой молот, в голове горит солнце, рукоять в золотых кольцах
			im = _img(24, 11)
			im.fill_rect(Rect2i(0, 4, 16, 3), Color(0.95, 0.92, 0.85))
			for x in [0, 1, 6, 11]:
				im.fill_rect(Rect2i(x, 4, 1, 3), Color(1.0, 0.78, 0.30))
			_box(im, 15, 0, 9, 11, Color(0.98, 0.86, 0.48))
			im.fill_rect(Rect2i(16, 1, 7, 2), Color(1.0, 0.96, 0.80))
			im.fill_rect(Rect2i(18, 4, 3, 3), Color(1.0, 0.60, 0.15))             # солнце-горн
			_px(im, 19, 5, Color(1.0, 1.0, 0.90))
			im.fill_rect(Rect2i(22, 1, 1, 9), Color(1.0, 0.98, 0.88))
		"club":          # дубина с гвоздями
			im = _img(16, 6)
			im.fill_rect(Rect2i(0, 2, 7, 2), WOOD.darkened(0.15))
			_box(im, 6, 1, 10, 5, WOOD)
			for c in [[9, 1], [12, 5], [14, 2]]:
				_px(im, c[0], c[1], STEEL.lightened(0.3))
		"axe":           # огромный двуручный топор атамана
			im = _img(28, 15)
			im.fill_rect(Rect2i(0, 7, 24, 2), WOOD.darkened(0.2))
			im.fill_rect(Rect2i(0, 7, 3, 2), Color(0.2, 0.15, 0.1))
			for y in 15:
				var hw := 7 - absi(y - 7)
				im.fill_rect(Rect2i(20 - hw / 2, y, 4 + hw / 2, 1), Color(0.55, 0.57, 0.62))
			im.fill_rect(Rect2i(23, 0, 1, 15), Color(0.85, 0.87, 0.92))
			im.fill_rect(Rect2i(19, 6, 3, 4), Color(0.3, 0.3, 0.33))
		"kunai":         # кунай в руке
			im = _img(11, 3)
			im.fill_rect(Rect2i(0, 1, 4, 1), Color(0.45, 0.25, 0.15))
			_px(im, 0, 0, Color(0.6, 0.62, 0.68))
			_px(im, 0, 2, Color(0.6, 0.62, 0.68))
			im.fill_rect(Rect2i(4, 0, 5, 3), Color(0.70, 0.72, 0.80))
			_px(im, 9, 1, Color(0.9, 0.92, 1.0))
			_px(im, 10, 1, Color(0.9, 0.92, 1.0))
		"shuriken":      # сюрикен между пальцами
			im = _img(7, 7)
			for i in 7:
				_px(im, i, 3, Color(0.7, 0.72, 0.78))
				_px(im, 3, i, Color(0.7, 0.72, 0.78))
			for c in [[1, 1], [5, 1], [1, 5], [5, 5]]:
				_px(im, c[0], c[1], Color(0.55, 0.57, 0.62))
			_px(im, 3, 3, Color(0.15, 0.15, 0.18))
		"firebottle":    # бутылка с горящей тряпкой
			im = _img(6, 10)
			_box(im, 1, 3, 4, 7, Color(0.45, 0.65, 0.35))
			im.fill_rect(Rect2i(2, 6, 2, 3), Color(0.95, 0.55, 0.15))
			im.fill_rect(Rect2i(2, 1, 2, 2), Color(0.85, 0.8, 0.7))
			_px(im, 2, 0, Color(1.0, 0.6, 0.15))
			_px(im, 3, 0, Color(1.0, 0.9, 0.4))
		"whip":          # кнут укротителя
			im = _img(18, 7)
			im.fill_rect(Rect2i(0, 3, 5, 2), Color(0.3, 0.18, 0.1))
			for x in range(5, 18):
				_px(im, x, 3 + int(round(2.0 * sin(x * 0.7))), Color(0.45, 0.28, 0.15))
		"kama":          # кама Ассасина: рукоять с обмоткой и серповидный клинок
			im = _img(17, 12)
			for x in 10:
				im.fill_rect(Rect2i(x, 9, 1, 2), Color(0.42, 0.25, 0.14) if x % 3 != 0 else Color(0.25, 0.14, 0.08))
			for i in 10:
				var bx := 9 + int(round(6.0 * sin(PI * 0.5 * i / 9.0)))
				var by := 9 - i
				im.fill_rect(Rect2i(bx, by, 2, 1), Color(0.78, 0.80, 0.86))
				_px(im, bx + 1, by, Color(0.95, 0.96, 1.0))
			im.fill_rect(Rect2i(9, 8, 2, 4), Color(0.55, 0.57, 0.62))
		"claws":         # длинные когти
			im = _img(8, 6)
			for k in 3:
				im.fill_rect(Rect2i(0, k * 2, 6 - k, 1), Color(0.85, 0.82, 0.72))
				_px(im, 6 - k, k * 2, Color(0.95, 0.92, 0.85))
		"sickle":        # серп пугала
			im = _img(14, 11)
			im.fill_rect(Rect2i(0, 8, 7, 2), WOOD)
			for i in 8:
				var bx := 6 + int(round(5.0 * sin(PI * 0.55 * i / 7.0)))
				im.fill_rect(Rect2i(bx, 8 - i, 2, 1), Color(0.62, 0.62, 0.66))
			_px(im, 11, 1, Color(0.85, 0.85, 0.9))
		"war_fan":       # боевой веер: синяя бумага, золотая кайма, молния, медные спицы
			var fp: Array = spec.get("wpal", [Color(0.30, 0.42, 0.80), Color(0.96, 0.80, 0.36), Color(0.20, 0.28, 0.56), Color(1.0, 0.92, 0.50), Color(0.78, 0.48, 0.24)])
			im = _img(10, 11)
			var pv := Vector2(1.0, 5.5)
			for y in 11:
				for x in 10:
					var d := Vector2(x + 0.5, y + 0.5) - pv
					var a := d.angle()
					var ln := d.length()
					if ln <= 9.4 and ln >= 2.2 and absf(a) <= 1.05:
						var c: Color = fp[0]
						if ln > 8.3:
							c = fp[1]
						elif fmod(absf(a) + 0.17, 0.35) < 0.08:
							c = fp[2]
						im.set_pixel(x, y, c)
			for pz in [Vector2i(5, 3), Vector2i(6, 4), Vector2i(5, 5), Vector2i(6, 6), Vector2i(7, 7)]:
				im.set_pixel(pz.x, pz.y, fp[3])
			im.fill_rect(Rect2i(0, 5, 3, 1), fp[4])
		"lantern_staff": # коряга, на крючке — фонарик с блуждающим огоньком
			im = _img(22, 9)
			for x in 18:
				im.set_pixel(x, 4 + int(round(sin(x * 0.55) * 0.8)), Color(0.40, 0.30, 0.19))
			_px(im, 6, 2, Color(0.40, 0.30, 0.19))
			_px(im, 7, 1, Color(0.36, 0.56, 0.28))                                 # листок на коряге
			_px(im, 18, 4, Color(0.40, 0.30, 0.19))                                # крючок
			_px(im, 19, 5, Color(0.40, 0.30, 0.19))
			im.fill_rect(Rect2i(19, 6, 3, 1), Color(0.22, 0.20, 0.17))             # крышка фонаря
			im.fill_rect(Rect2i(19, 7, 3, 2), Color(0.70, 1.0, 0.55))              # огонёк
			_px(im, 20, 7, Color(0.95, 1.0, 0.85))
		"witch_staff":   # кривой посох с черепом-фонарём
			im = _img(22, 9)
			for x in 17:
				im.set_pixel(x, 4 + int(round(sin(x * 0.7))), Color(0.30, 0.22, 0.16))
			_box(im, 16, 1, 5, 5, BONE)
			_px(im, 17, 3, Color(0.6, 1.0, 0.3))
			_px(im, 19, 3, Color(0.6, 1.0, 0.3))
		"anchor":        # тяжёлый якорь на цепи
			im = _img(18, 13)
			for x in range(0, 6, 2):
				im.fill_rect(Rect2i(x, 6, 2, 1), Color(0.45, 0.45, 0.48))
			im.fill_rect(Rect2i(6, 5, 9, 3), Color(0.36, 0.38, 0.40))
			im.fill_rect(Rect2i(14, 0, 3, 13), Color(0.36, 0.38, 0.40))
			im.fill_rect(Rect2i(11, 0, 3, 2), Color(0.36, 0.38, 0.40))
			im.fill_rect(Rect2i(11, 11, 3, 2), Color(0.36, 0.38, 0.40))
			_px(im, 15, 6, Color(0.5, 0.55, 0.5))
		"ice_bow":       # лук изо льда
			im = _img(8, 16)
			for y in 16:
				var bx := int(3.0 * sin(PI * y / 15.0))
				im.set_pixel(bx, y, Color(0.70, 0.90, 1.0))
				im.set_pixel(bx + 1, y, Color(0.50, 0.72, 0.92))
			im.set_pixel(3, 8, Color(1, 1, 1))
		"ice_club":      # ледяная дубина великана: глыба на древке
			im = _img(26, 11)
			im.fill_rect(Rect2i(0, 4, 12, 3), Color(0.45, 0.36, 0.28))
			_crystal_box(im, 11, 0, 15, 11, Color(0.66, 0.86, 1.0))
			for c in [[14, 0], [19, 0], [24, 3], [17, 10]]:
				_px(im, c[0], c[1], Color(1, 1, 1))
		"storm_staff":   # посох со сферой-искрой
			im = _img(20, 7)
			im.fill_rect(Rect2i(0, 3, 15, 1), Color(0.40, 0.32, 0.25))
			_box(im, 14, 1, 5, 5, Color(0.55, 0.75, 1.0))
			_px(im, 16, 3, Color(1, 1, 1))
		"glaive":        # алебарда-глефа храмового стража
			im = _img(30, 9)
			im.fill_rect(Rect2i(0, 4, 22, 1), Color(0.40, 0.30, 0.20))
			for i in 8:
				im.fill_rect(Rect2i(21 + i, 4 - i / 2, 1, 2 + i / 3), Color(0.80, 0.82, 0.88))
			im.fill_rect(Rect2i(20, 2, 2, 5), BRONZE)
		"thunder_staff": # посох жреца: золотой знак молнии на конце
			im = _img(22, 11)
			im.fill_rect(Rect2i(0, 5, 16, 1), Color(0.85, 0.85, 0.90))
			for c in [[16, 1], [17, 2], [18, 3], [17, 4], [18, 5], [19, 6], [20, 7], [21, 8]]:
				_px(im, c[0], c[1], Color(0.95, 0.80, 0.25))
		"storm_orb":     # длинный посох с огромной сферой-грозой
			im = _img(30, 11)
			im.fill_rect(Rect2i(0, 5, 22, 1), Color(0.55, 0.60, 0.70))
			for y in 11:
				var hw2 := int(5.0 * sin(PI * (y + 0.5) / 11.0))
				im.fill_rect(Rect2i(24 - hw2, y, hw2 * 2 + 1, 1), Color(0.55, 0.75, 1.0, 0.85))
			_box(im, 22, 3, 5, 5, Color(0.92, 0.97, 1.0), false)
		"fire_staff":    # посох культиста с горящим черепом
			im = _img(22, 9)
			im.fill_rect(Rect2i(0, 4, 16, 1), Color(0.25, 0.15, 0.10))
			_box(im, 15, 2, 5, 5, BONE)
			_px(im, 17, 4, DARK)
			for k in 4:
				_px(im, 16 + k, 1 - (k % 2), Color(1.0, 0.55, 0.15))
		"dark_sword":    # чёрный меч рыцаря с багровой кромкой
			im = _img(24, 6)
			im.fill_rect(Rect2i(0, 2, 4, 2), Color(0.20, 0.16, 0.16))
			im.fill_rect(Rect2i(4, 0, 2, 6), Color(0.45, 0.42, 0.48))
			_box(im, 6, 1, 17, 4, Color(0.14, 0.12, 0.16))
			im.fill_rect(Rect2i(7, 4, 15, 1), Color(0.85, 0.20, 0.10))
			_px(im, 23, 2, Color(0.30, 0.28, 0.32))
		"dark_greatsword": # огромный меч Тёмного лорда: чёрный клинок, лавовая кромка, рогатая гарда
			im = _img(36, 9)
			im.fill_rect(Rect2i(0, 3, 6, 3), Color(0.20, 0.16, 0.16))
			im.fill_rect(Rect2i(6, 0, 2, 9), Color(0.55, 0.52, 0.58))
			_px(im, 8, 0, Color(0.55, 0.52, 0.58))
			_px(im, 8, 8, Color(0.55, 0.52, 0.58))
			_box(im, 8, 2, 26, 5, Color(0.12, 0.10, 0.14))
			im.fill_rect(Rect2i(9, 6, 24, 1), Color(1.0, 0.40, 0.12))
			im.fill_rect(Rect2i(10, 4, 20, 1), Color(0.40, 0.36, 0.44))
			im.fill_rect(Rect2i(34, 3, 2, 3), Color(0.30, 0.28, 0.32))
		"quill":         # Летописец: большое перо-посох — белое опахало, золотое перо-наконечник, капля чернил
			var qpl: Array = spec.get("qpal", [Color(0.96, 0.95, 0.90), Color(0.76, 0.78, 0.86), Color(0.90, 0.86, 0.74),
					Color(1.0, 0.82, 0.38), Color(0.16, 0.24, 0.55)])
			im = _img(22, 9)
			im.fill_rect(Rect2i(3, 4, 19, 1), qpl[2])                             # стержень
			for x in range(6, 22):
				var t := float(x - 6) / 15.0
				var up := clampi(int(round(4.0 * sin(PI * minf(1.0, t * 1.15)))), 0, 4)
				for y in up:
					_px(im, x, 3 - y, qpl[1] if (y == up - 1 and x % 3 == 0) else qpl[0])
				var dn := clampi(int(round(2.5 * sin(PI * t))), 0, 3)
				for y in dn:
					_px(im, x, 5 + y, qpl[1] if (x + y) % 3 == 0 else qpl[0])
			for x in range(9, 21, 3):
				_px(im, x, 3, qpl[1])                                              # бородки пера
			_px(im, 21, 1, qpl[0].lightened(0.3))
			im.fill_rect(Rect2i(0, 3, 3, 3), qpl[3])                              # перо-наконечник
			_px(im, 0, 3, Color(0, 0, 0, 0))
			_px(im, 0, 5, Color(0, 0, 0, 0))
			_px(im, 1, 4, qpl[3].darkened(0.45))                                   # прорезь пера
			_px(im, 0, 4, qpl[4])                                                  # чернила на кончике
			_px(im, 0, 6, qpl[4].lightened(0.2))                                   # капля
		"gauntlet":      # Почти легенда: силовая перчатка — оранжевый кулак, белая манжета, голубые огни на костяшках
			var gp: Array = spec.get("gpal", [Color(1.0, 0.52, 0.14), Color(0.94, 0.95, 0.98), Color(0.30, 0.90, 1.0), Color(0.18, 0.20, 0.26)])
			im = _img(7, 7)
			_box(im, 0, 1, 3, 5, gp[1])                                              # манжета
			_box(im, 2, 0, 5, 7, gp[0])                                              # кулак
			im.fill_rect(Rect2i(6, 1, 1, 5), gp[3])                                  # костяшки
			_px(im, 5, 2, gp[2])
			_px(im, 5, 4, gp[2])
			_px(im, 3, 3, gp[0].lightened(0.3))
		"vinyl":         # DJ Клима: виниловая пластинка — чёрный диск с бороздками, яркая наклейка, дырочка
			var vp: Array = spec.get("vpal", [Color(0.07, 0.07, 0.09), Color(0.22, 0.22, 0.27), Color(1.0, 0.36, 0.80), Color(0.30, 0.90, 1.0)])
			im = _img(7, 7)
			for y in 7:
				for x in 7:
					var d := Vector2(x - 3, y - 3).length()
					if d <= 3.4:
						im.set_pixel(x, y, vp[0] if int(d * 2.0) % 2 == 0 or d < 1.5 else vp[1])
			im.fill_rect(Rect2i(2, 2, 3, 3), vp[2])                               # наклейка
			_px(im, 3, 3, vp[0])                                                   # дырочка
			_px(im, 2, 2, vp[3])
			_px(im, 1, 1, vp[1].lightened(0.4))                                    # блик
		"usb_stick":     # флешка с Arch Linux: тёмно-красный корпус, штекер, синий логотип, огонёк
			im = _img(8, 3)
			im.fill_rect(Rect2i(0, 0, 5, 3), Color(0.50, 0.08, 0.14))
			im.fill_rect(Rect2i(5, 0, 3, 3), Color(0.82, 0.84, 0.88))
			_px(im, 3, 1, Color(0.10, 0.58, 0.85))
			_px(im, 1, 1, Color(0.4, 1.0, 0.45))
		"soda_bottle":   # пластиковая бутылка газировки: прозрачные стенки, жидкость, красная крышка
			im = _img(13, 5)
			_box(im, 0, 0, 8, 5, Color(0.70, 0.84, 0.90))
			im.fill_rect(Rect2i(1, 1, 7, 3), Color(0.45, 0.20, 0.08))
			im.fill_rect(Rect2i(3, 1, 3, 3), Color(0.85, 0.15, 0.15))                  # этикетка
			im.fill_rect(Rect2i(8, 1, 3, 3), Color(0.70, 0.84, 0.90))
			im.fill_rect(Rect2i(11, 1, 2, 3), Color(0.90, 0.20, 0.20))                 # крышка
			im.fill_rect(Rect2i(1, 0, 6, 1), Color(0.90, 0.97, 1.0))                   # блик
		"beer_bottle":   # бутылка пива: зелёное стекло, светлая этикетка без надписей, крышка
			im = _img(13, 5)
			_box(im, 0, 0, 8, 5, Color(0.20, 0.50, 0.24))
			im.fill_rect(Rect2i(8, 1, 4, 3), Color(0.20, 0.50, 0.24))
			im.fill_rect(Rect2i(1, 1, 5, 3), Color(0.90, 0.84, 0.66))                  # этикетка
			im.fill_rect(Rect2i(2, 2, 3, 1), Color(0.75, 0.25, 0.18))
			im.fill_rect(Rect2i(12, 1, 1, 3), Color(0.85, 0.20, 0.15))                  # крышка
			im.fill_rect(Rect2i(7, 0, 4, 1), Color(0.55, 0.85, 0.55))                   # блик стекла
		"dawn_blade":    # обсидиановый двуручник Рассвета: чёрный клинок с золотой кромкой
			var dp: Array = spec.get("wpal", [Color(0.25, 0.18, 0.14), Color(0.85, 0.70, 0.32), Color(0.13, 0.11, 0.16), Color(1.0, 0.84, 0.42), Color(0.42, 0.38, 0.46)])
			im = _img(30, 7)
			im.fill_rect(Rect2i(0, 2, 6, 3), dp[0])
			im.fill_rect(Rect2i(6, 0, 2, 7), dp[1])
			_box(im, 8, 1, 21, 5, dp[2])
			im.fill_rect(Rect2i(9, 5, 19, 1), dp[3])
			im.fill_rect(Rect2i(10, 3, 16, 1), dp[4])
			im.fill_rect(Rect2i(29, 2, 1, 3), dp[3])
		"headsman_axe":  # огромный топор палача: длинное топорище, широкое полукруглое лезвие
			im = _img(34, 20)
			im.fill_rect(Rect2i(0, 9, 28, 2), WOOD.darkened(0.35))
			im.fill_rect(Rect2i(0, 9, 3, 2), Color(0.15, 0.12, 0.10))
			for y in 20:
				var k := absf(y - 9.5) / 10.0
				var bw := int(10.0 * (1.0 - k * k))
				if bw > 0:
					im.fill_rect(Rect2i(24, y, bw, 1), Color(0.42, 0.42, 0.46))
					_px(im, 23 + bw, y, Color(0.82, 0.82, 0.88))
			im.fill_rect(Rect2i(22, 7, 3, 6), Color(0.25, 0.22, 0.22))
			_px(im, 28, 4, Color(0.55, 0.12, 0.10))
			_px(im, 29, 15, Color(0.55, 0.12, 0.10))
		"warlock_staff": # костяной посох с лиловой сферой
			im = _img(22, 7)
			im.fill_rect(Rect2i(0, 3, 16, 1), BONE.darkened(0.2))
			_box(im, 16, 1, 5, 5, Color(0.55, 0.25, 0.85))
			_px(im, 18, 3, Color(0.95, 0.8, 1.0))
		"necro_staff":
			im = _img(22, 7)
			im.fill_rect(Rect2i(0, 3, 17, 1), Color(0.25, 0.18, 0.2))
			_box(im, 16, 1, 5, 5, BONE)
			im.fill_rect(Rect2i(17, 2, 1, 1), DARK)
			im.fill_rect(Rect2i(19, 2, 1, 1), DARK)
		_:
			im = _img(2, 2)
	return im

# ---------- Глубины: кобольды и кристальные существа ----------
# Вагонетка вагонетчика: сидит в ней по пояс
func _add_cart() -> void:
	var img := DeepArt.cart_image()
	var k := 0.78
	var cs := _sprite(_art, img, Vector2(13, 16), Vector2(0, 1))
	cs.scale = Vector2(k, k)
	_art.move_child(cs, _leg_f.get_index() + 1)

# Гранёный полупрозрачный прямоугольник (кристалл)
static func _crystal_box(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var f := ((xx - x) + (yy - y) * 2) % 7
			var k := 0.14 if f < 3 else -0.05
			if xx == x or yy == y:
				k += 0.18
			if xx == x + w - 1 or yy == y + h - 1:
				k = -0.3
			var q := c.lightened(k) if k > 0.0 else c.darkened(-k)
			q.a = 0.92
			_px(im, xx, yy, q)

# Голова кобольда: вытянутая морда, рожки, жёлтый глаз; шлем с фонарём, очки или капюшон
func _kobold_head(im: Image, x0: int, y0: int, w: int, h: int, ex: int, ey: int) -> void:
	var skin: Color = spec["skin"]
	im.fill_rect(Rect2i(x0 + w - 1, y0 + h / 2, 4, h / 2 - 1), skin)            # морда
	im.fill_rect(Rect2i(x0 + w + 1, y0 + h / 2 + 1, 2, 1), skin.darkened(0.4))  # ноздря
	im.fill_rect(Rect2i(x0 + w - 2, y0 + h - 2, 5, 1), skin.darkened(0.3))       # пасть
	_px(im, x0 + w, y0 + h - 1, Color(0.95, 0.92, 0.8))                        # клык
	im.fill_rect(Rect2i(ex, ey, 2, 2), Color(1.0, 0.8, 0.2))
	_px(im, ex + 1, ey, Color(0.1, 0.05, 0.05))
	for k in 3:                                                                 # рожки назад
		_px(im, x0 + 1 - k, y0 - k, Color(0.85, 0.8, 0.65))
	match spec["hat"]:
		"kobold":         # каска рудокопа с фонарём
			var hc := Color(0.85, 0.7, 0.2)
			_box(im, x0 - 1, y0 - 2, w + 1, 4, hc)
			im.fill_rect(Rect2i(x0 + w - 1, y0 - 1, 3, 2), Color(1.0, 0.95, 0.6))
		"kobold_goggles": # очки подрывника
			im.fill_rect(Rect2i(x0, ey - 1, w, 2), Color(0.3, 0.22, 0.15))
			_box(im, ex - 1, ey - 2, 4, 4, Color(0.6, 0.85, 1.0))
		"kobold_hood":    # капюшон шамана с самоцветом
			var rc: Color = spec["shirt"]
			_box(im, x0 - 2, y0 - 2, w + 1, h - 1, rc)
			im.fill_rect(Rect2i(x0 + 2, y0 + 1, w - 2, h - 3), skin)
			im.fill_rect(Rect2i(ex, ey, 2, 2), Color(1.0, 0.8, 0.2))
			_box(im, x0 + 2, y0 - 2, 3, 3, Color(0.3, 0.85, 0.5), false)

# ---------- Герой Истории ----------
# Голова: причёска, борода, шрам/краска и шлем (если надет)
func _story_head(im: Image, x0: int, y0: int, w: int, h: int, ex: int, ey: int) -> void:
	var hc: Color = spec.get("hair_color", Color(0.3, 0.2, 0.12))
	var skin: Color = spec["skin"]
	var helm: String = spec.get("helm", "")
	var mark: String = spec.get("mark", "none")
	if spec.get("female", false):
		_px(im, ex + 1, ey - 1, DARK)                                       # ресницы
		_px(im, ex + 2, ey - 1, DARK)
		_px(im, x0 + w - 3, y0 + h - 3, Color(0.78, 0.38, 0.38))           # губы
		_px(im, x0 + w - 2, y0 + h - 3, Color(0.70, 0.32, 0.32))
	if mark == "scar":
		for k in 3:
			_px(im, ex - 2 + k, ey - 2 + k, Color(0.70, 0.35, 0.32))
	elif mark == "paint":
		im.fill_rect(Rect2i(ex - 2, ey + 2, 4, 1), Color(0.25, 0.40, 0.75))
		im.fill_rect(Rect2i(ex - 3, ey - 1, 1, 4), Color(0.25, 0.40, 0.75))
	match spec.get("beard", "none"):
		"stubble":
			for x in range(x0 + 2, x0 + w - 1, 2):
				_px(im, x, y0 + h - 2, skin.darkened(0.3))
				_px(im, x + 1, y0 + h - 1, skin.darkened(0.3))
		"short":
			im.fill_rect(Rect2i(x0 + 2, y0 + h - 3, w - 2, 3), hc)
			im.fill_rect(Rect2i(x0 + w - 4, y0 + h - 4, 3, 1), hc)          # усы
			_px(im, x0 + w - 2, y0 + h - 3, skin.darkened(0.35))
		"full":
			im.fill_rect(Rect2i(x0 + 1, y0 + h / 2 + 1, w, h / 2 - 1), hc)
			im.fill_rect(Rect2i(x0 + 2, y0 + h, w - 3, 2), hc)
			im.fill_rect(Rect2i(x0 + w - 5, y0 + h / 2 + 2, 4, 1), hc.lightened(0.15))
			_px(im, x0 + w - 2, y0 + h - 3, Color(0.6, 0.3, 0.25))
	if helm == "":
		match spec.get("hair", "short"):
			"short":
				_box(im, x0, y0 - 1, w, 3, hc, false)
				im.fill_rect(Rect2i(x0, y0 - 1, 3, 5), hc)
				_px(im, x0 + w - 1, y0 + 1, hc)
			"long":
				_box(im, x0 - 1, y0 - 2, w + 1, 4, hc, false)
				im.fill_rect(Rect2i(x0 - 2, y0, 4, h + 2), hc)               # волосы до плеч
				im.fill_rect(Rect2i(x0 + w - 3, y0 + 1, 3, 1), hc)           # чёлка
				for y in range(y0 + 1, y0 + h + 2, 2):
					_px(im, x0 - 1, y, hc.darkened(0.2))
			"tail":
				_box(im, x0, y0 - 2, w, 4, hc, false)
				im.fill_rect(Rect2i(x0, y0, 2, 3), hc)
				for k in 7:                                                   # хвост на затылке
					im.fill_rect(Rect2i(x0 - 2 - k / 3, y0 + k, 2, 1), hc if k % 2 == 0 else hc.darkened(0.2))
				_px(im, x0 - 1, y0, Color(0.7, 0.2, 0.15))                    # лента
			"mohawk":
				for x in range(x0 + 1, x0 + w - 2):
					var hh := 3 + int(1.5 * sin(PI * (x - x0) / float(w)))
					im.fill_rect(Rect2i(x, y0 - hh, 1, hh + 1), hc if x % 2 == 0 else hc.lightened(0.15))
				im.fill_rect(Rect2i(x0, y0 + 1, 2, 3), skin.darkened(0.12))  # выбритые виски
			"bald":
				_px(im, x0 + w - 3, y0 + 1, skin.lightened(0.25))            # блик на макушке
		im.fill_rect(Rect2i(ex - 1, ey - 2, 3, 1), hc.darkened(0.15))         # бровь
		return
	var mc: Color = spec.get("helm_color", STEEL)
	match helm:
		"iron":      # железный шлем с наносником и назатыльником
			_box(im, x0 - 1, y0 - 3, w + 2, 6, mc)
			im.fill_rect(Rect2i(x0, y0 - 2, w, 1), mc.lightened(0.25))
			im.fill_rect(Rect2i(x0 + w - 2, y0 + 2, 2, 4), mc.darkened(0.15))      # наносник
			_box(im, x0 - 1, y0 + 2, 3, h - 2, mc.darkened(0.2))                    # назатыльник
			_px(im, x0 + w / 2, y0 - 4, mc.darkened(0.3))
		"cap":       # кожаная шапка
			_box(im, x0, y0 - 2, w, 4, mc)
		"hood":      # капюшон
			_box(im, x0 - 2, y0 - 2, w + 2, h + 1, mc)
			im.fill_rect(Rect2i(x0 + 3, y0 + 1, w - 3, h - 2), skin)
			im.fill_rect(Rect2i(ex, ey, 2, 2), spec.get("eye", DARK))
			im.fill_rect(Rect2i(ex - 1, ey - 2, 3, 1), hc.darkened(0.15))

static func im_sling(img: Image) -> void:
	for y in 9:
		_px(img, 1 + (y % 3) / 2, y, Color(0.55, 0.4, 0.22))
	_box(img, 1, 6, 4, 3, Color(0.45, 0.32, 0.18), false)
	_px(img, 3, 7, Color(0.6, 0.6, 0.62))

# Дальнее оружие героя Истории: висит за спиной, при выстреле — в руке
func _story_alts(hand: Vector2) -> void:
	var b: String = spec.get("back", "")
	if b == "":
		return
	var aimg := _draw_weapon(b)
	var asp := _sprite(_hand(_arm_f), aimg, Vector2(2, aimg.get_height() / 2.0), _hp(_arm_f, hand))
	asp.rotation = PI / 2
	asp.visible = false
	_alts["ranged"] = asp

func _draw_shield(kind_s: String) -> Image:
	var im: Image
	match kind_s:
		"round":         # красный круглый щит с бронзой (Чемпион)
			im = _draw_round_shield()
		"ember_shield", "void_shield", "sun_shield", "frost_shield":   # щиты обликов Чемпиона: свой цвет, обод и герб
			var sc: Array = {"ember_shield": [Color(0.18, 0.10, 0.08), Color(1.0, 0.48, 0.12), Color(1.0, 0.86, 0.40)],
					"frost_shield": [Color(0.30, 0.48, 0.68), Color(0.88, 0.97, 1.0), Color(0.60, 0.90, 1.0)],
					"void_shield": [Color(0.10, 0.07, 0.14), Color(0.72, 0.40, 1.0), Color(0.95, 0.85, 1.0)],
					"sun_shield": [Color(1.0, 0.82, 0.38), Color(0.96, 0.93, 0.86), Color(1.0, 1.0, 0.92)]}[kind_s]
			im = _img(10, 14)
			for y in 14:
				var hw := int(5.0 * sin(PI * (y + 0.5) / 14.0)) + 1
				im.fill_rect(Rect2i(5 - hw, y, hw * 2, 1), sc[0])
				_px(im, 5 - hw, y, sc[1])
				_px(im, 4 + hw, y, sc[1])
			match kind_s:
				"ember_shield":                                       # герб — язык пламени
					for y in range(3, 11):
						var fw := maxi(0, 2 - absi(y - 8) / 2)
						im.fill_rect(Rect2i(5 - fw, y, fw * 2, 1), sc[1] if y > 5 else sc[2])
				"void_shield":                                        # герб — око разлома
					im.fill_rect(Rect2i(3, 6, 4, 2), sc[1])
					im.fill_rect(Rect2i(4, 5, 2, 4), sc[1])
					_px(im, 4, 6, sc[2])
				"frost_shield":                                       # герб — снежинка
					im.fill_rect(Rect2i(4, 3, 2, 8), sc[2])
					im.fill_rect(Rect2i(2, 6, 6, 2), sc[2])
					for d in [Vector2i(2, 4), Vector2i(7, 4), Vector2i(2, 9), Vector2i(7, 9)]:
						_px(im, d.x, d.y, sc[1])
					_px(im, 4, 6, Color(1, 1, 1))
				"sun_shield":                                         # герб — солнце
					im.fill_rect(Rect2i(4, 5, 2, 4), sc[2])
					im.fill_rect(Rect2i(3, 6, 4, 2), sc[2])
					for d in [Vector2i(5, 2), Vector2i(5, 11), Vector2i(1, 7), Vector2i(8, 7)]:
						_px(im, d.x, d.y, Color(1.0, 0.65, 0.20))
		"buckler", "rusty":
			var c := BRONZE if kind_s == "buckler" else Color(0.48, 0.42, 0.36)
			im = _img(8, 9)
			for y in 9:
				var hw := int(4.0 * sin(PI * (y + 0.5) / 9.0)) + 1
				im.fill_rect(Rect2i(4 - hw, y, hw * 2, 1), c)
			im.fill_rect(Rect2i(3, 3, 2, 3), c.lightened(0.3))
		"mirror":        # зеркальный щит стража: отражает снаряды
			im = DeepArt.mirror_image(8, 16)
		"door":          # щит из старой двери
			im = _img(9, 15)
			_box(im, 0, 0, 9, 15, WOOD.darkened(0.1))
			for x in [3, 6]:
				im.fill_rect(Rect2i(x, 1, 1, 13), WOOD.darkened(0.35))
			im.fill_rect(Rect2i(1, 3, 7, 1), Color(0.35, 0.35, 0.38))
			im.fill_rect(Rect2i(1, 11, 7, 1), Color(0.35, 0.35, 0.38))
		"ice":           # ледяной щит-капля
			im = _img(9, 15)
			for y in 15:
				var hw := int(4.5 * (1.0 - maxf(0.0, (y - 6) / 9.0)))
				for x in range(4 - hw, 5 + hw):
					_px(im, x, y, Color(0.70, 0.88, 1.0) if (x + y) % 5 else Color(0.92, 0.98, 1.0))
		"storm":         # круглый бронзовый щит со знаком молнии
			im = _img(11, 13)
			for y in 13:
				var hw := int(5.5 * sin(PI * (y + 0.5) / 13.0)) + 1
				im.fill_rect(Rect2i(5 - hw, y, hw * 2, 1), BRONZE.darkened(0.1))
			for c in [[6, 2], [5, 4], [6, 5], [5, 7], [4, 9]]:
				_px(im, c[0], c[1], Color(0.85, 0.92, 1.0))
		"scutum":        # большой прямоугольный щит мирмиллона
			im = _img(9, 17)
			_box(im, 0, 0, 9, 17, Color(0.70, 0.15, 0.12))
			_box(im, 3, 6, 3, 4, Color(0.92, 0.75, 0.25))
			im.fill_rect(Rect2i(1, 1, 7, 1), Color(0.92, 0.75, 0.25))
			im.fill_rect(Rect2i(1, 15, 7, 1), Color(0.92, 0.75, 0.25))
		_:
			im = _img(2, 2)
	return im

func _draw_item(it: String) -> Image:
	var im := _img(5, 5)
	match it:
		"smoke":
			_box(im, 0, 0, 5, 5, Color(0.55, 0.58, 0.55))
			_px(im, 2, 0, Color(0.9, 0.9, 0.9))
		"seed":
			_box(im, 0, 0, 5, 5, Color(0.5, 0.75, 0.25))
		"bola":
			im = _img(7, 7)
			im.fill_rect(Rect2i(1, 1, 5, 1), Color(0.75, 0.65, 0.45))
			im.fill_rect(Rect2i(3, 1, 1, 5), Color(0.75, 0.65, 0.45))
			for c in [[0, 0], [5, 0], [2, 5]]:
				_box(im, c[0], c[1], 2, 2, Color(0.4, 0.4, 0.42), false)
		"ember_kunai", "void_kunai", "sun_kunai", "ice_kunai":   # кунай облика: своя рукоять и светящееся лезвие
			var kc: Array = {"ember_kunai": [Color(0.20, 0.10, 0.08), Color(1.0, 0.50, 0.12), Color(1.0, 0.86, 0.40)],
					"ice_kunai": [Color(0.25, 0.38, 0.55), Color(0.70, 0.90, 1.0), Color(0.96, 1.0, 1.0)],
					"void_kunai": [Color(0.12, 0.08, 0.17), Color(0.55, 0.28, 0.85), Color(0.95, 0.85, 1.0)],
					"sun_kunai": [Color(0.96, 0.93, 0.86), Color(1.0, 0.80, 0.32), Color(1.0, 1.0, 0.92)]}[it]
			im = _img(3, 9)
			im.fill_rect(Rect2i(1, 0, 1, 4), kc[0])
			_px(im, 1, 0, kc[1])
			im.fill_rect(Rect2i(0, 4, 3, 4), kc[1])
			_px(im, 1, 8, kc[2])
		"kunai":
			im = _img(3, 9)
			im.fill_rect(Rect2i(1, 0, 1, 4), Color(0.45, 0.25, 0.15))
			im.fill_rect(Rect2i(0, 4, 3, 4), Color(0.72, 0.74, 0.82))
			_px(im, 1, 8, Color(0.92, 0.94, 1.0))
		"net":
			im = _img(7, 7)
			for i in range(0, 7, 2):
				im.fill_rect(Rect2i(i, 0, 1, 7), Color(0.85, 0.82, 0.7))
				im.fill_rect(Rect2i(0, i, 7, 1), Color(0.85, 0.82, 0.7))
	return im

# Тотем жизни: резной столб с крыльями, глаза светятся
func _build_totem() -> void:
	var im := _img(16, 30)
	var wood := Color(0.50, 0.36, 0.20)
	_box(im, 2, 4, 12, 26, wood)
	for k in 4:
		im.fill_rect(Rect2i(3, 9 + k * 5, 10, 1), wood.darkened(0.35))
	im.fill_rect(Rect2i(5, 6, 2, 2), Color(0.6, 1.0, 0.35))
	im.fill_rect(Rect2i(9, 6, 2, 2), Color(0.6, 1.0, 0.35))
	_box(im, 6, 11, 4, 3, Color(0.15, 0.1, 0.06), false)
	for k in 5:                        # крылья
		im.fill_rect(Rect2i(0, 14 + k, 2, 1), Color(0.3, 0.6, 0.25))
		im.fill_rect(Rect2i(14, 14 + k, 2, 1), Color(0.3, 0.6, 0.25))
	for x in range(2, 14, 2):          # листья на макушке
		im.fill_rect(Rect2i(x, 1 + (x % 4) / 2, 2, 3), Color(0.3, 0.62, 0.25))
	px = _size().y / 30.0
	_art = Node2D.new()
	_art.scale = Vector2(px, px)
	_art.position = Vector2(0, _size().y / 2)
	add_child(_art)
	_torso = _sprite(_art, im, Vector2(8, 30), Vector2.ZERO)
	_glow = Polygon2D.new()
	_glow.polygon = Util.circle(9.0, 16)
	_glow.color = Color(0.5, 1.0, 0.35, 0.25)
	_glow.position = Vector2(0, -22)
	_art.add_child(_glow)


# ---------- Колосс-остов (вторая фаза): железный каркас без брони ----------
# Позвоночник и ключицы, тёмная полость груди; рёбра — две отдельные половины
# на шарнире у позвоночника (раскрываются, когда ядро открыто); голова-череп
# с пустыми глазницами и горящими зрачками, нижняя челюсть на шарнире;
# поршни, провода, ржавые шестерни. Двигается рывками, как старый механизм.
func _endo_torso(im: Image, w: int, h: int) -> void:
	im.fill_rect(Rect2i(4, 2, w - 6, h - 5), CAVITY)                 # тёмная полость груди
	for y in range(0, h - 2):                                        # позвоночник у спины
		im.fill_rect(Rect2i(1, y, 3, 1), ENDO if y % 2 == 0 else ENDO_D)
		if y % 2 == 0:
			_px(im, 0, y, ENDO_D.darkened(0.2))                      # отростки позвонков
	im.fill_rect(Rect2i(4, 3, 1, h - 7), ENDO_L.darkened(0.15))      # гидравлика вдоль спины
	im.fill_rect(Rect2i(4, 8, 1, 2), ENDO_D)
	for y in range(3, h - 4):                                        # провода в полости
		_px(im, 6 + (y / 3) % 2, y, CABLE.darkened(0.25))
		_px(im, w - 6 - (y / 4) % 2, y, Color(0.14, 0.13, 0.16))
	_box(im, 1, 0, w - 2, 3, ENDO)                                   # ключицы / плечевой пояс
	for x in [3, 8, 13, w - 4]:
		_px(im, x, 1, ENDO_L)                                        # заклёпки
	_px(im, 10, 2, RUST)
	_box(im, 2, h - 4, w - 4, 4, ENDO_D.lightened(0.12))             # таз
	_px(im, 5, h - 2, RUST)
	_px(im, w - 7, h - 3, RUST)
	_px(im, w / 2, h - 2, ENDO_L)

# Рёбра поверх ядра: верхняя или нижняя половина (с грудиной спереди)
func _endo_ribs(w: int, h: int, upper: bool) -> Image:
	var im := _img(w, h)
	for ry in ([3, 6] if upper else [10, 13]):
		for x in range(3, w - 2):
			var yy: int = ry + (1 if x > w / 2 + 2 else 0) + (1 if x > w - 6 else 0)
			_px(im, x, yy, ENDO_L.darkened(0.08) if (x - 3) % 4 != 3 else ENDO)
			_px(im, x, yy + 1, ENDO_D)
	for y in range(3 if upper else 9, (9 if upper else 16)):         # грудина
		_px(im, w - 3, y, ENDO)
		_px(im, w - 2, y, ENDO_L if y % 2 == 0 else ENDO)
	return im

func _endo_head(im: Image, x0: int, y0: int, w: int, h: int) -> void:
	_box(im, x0 + 1, y0, w - 2, 9, ENDO)                             # купол черепа
	_px(im, x0 + 1, y0, Color(0, 0, 0, 0))
	_px(im, x0 + w - 2, y0, Color(0, 0, 0, 0))
	for x in range(x0 + 2, x0 + w - 3):                              # шов между пластинами
		if x % 3 != 0:
			_px(im, x, y0 + 3, ENDO_D)
	for rv in [Vector2i(x0 + 3, y0 + 2), Vector2i(x0 + 7, y0 + 1), Vector2i(x0 + 11, y0 + 2), Vector2i(x0 + 4, y0 + 6)]:
		_px(im, rv.x, rv.y, ENDO_L)                                  # заклёпки
	im.fill_rect(Rect2i(x0 + 5, y0 + 4, 2, 2), CAVITY)               # пробоина: внутри тлеет
	_px(im, x0 + 5, y0 + 5, Color(1.0, 0.5, 0.15))
	im.fill_rect(Rect2i(x0 + w - 11, y0 + 4, 10, 1), ENDO_D)          # надбровная дуга
	im.fill_rect(Rect2i(x0 + w - 5, y0 + 5, 4, 3), Color(0.02, 0.01, 0.02))   # глазницы — пустые
	im.fill_rect(Rect2i(x0 + w - 10, y0 + 5, 3, 3), Color(0.02, 0.01, 0.02))
	_px(im, x0 + w - 1, y0 + 8, Color(0.02, 0.01, 0.02))              # носовая щель
	im.fill_rect(Rect2i(x0 + w - 10, y0 + 10, 10, 3), CAVITY)         # пасть за челюстью
	for x in range(x0 + w - 9, x0 + w):                              # верхние зубы
		_px(im, x, y0 + 9, TEETH if x % 2 == 0 else CAVITY)
	for dy in range(-2, 3):                                          # шестерня на затылке
		for dx in range(-2, 3):
			if dx * dx + dy * dy <= 5:
				_px(im, x0 + 3 + dx, y0 + 8 + dy, ENDO_D.lightened(0.08) if (dx + dy) % 2 else RUST.darkened(0.25))
	for tp in [Vector2i(0, -3), Vector2i(-3, 0), Vector2i(0, 3)]:
		_px(im, x0 + 3 + tp.x, y0 + 8 + tp.y, ENDO_D)
	_px(im, x0 + 3, y0 + 8, ENDO_L)
	im.fill_rect(Rect2i(x0 + 5, y0 + 9, 1, 4), ENDO_L)               # шея: поршни и провод
	im.fill_rect(Rect2i(x0 + 7, y0 + 9, 1, 4), ENDO_D)
	im.fill_rect(Rect2i(x0 + 6, y0 + 10, 1, 3), CABLE)
	for k in 4:                                                      # обломки рогов
		_px(im, x0 + 2 - k / 2, y0 - 1 - k, BONE.darkened(0.12 + 0.04 * k))
		_px(im, x0 + 3 - k / 2, y0 - 1 - k, BONE.darkened(0.3) if k < 3 else Color(0, 0, 0, 0))
	for k in 3:
		_px(im, x0 + w - 4 + k / 2, y0 - 1 - k, BONE.darkened(0.15 + 0.05 * k))
	_px(im, x0 + w - 3, y0 - 2, BONE.darkened(0.35))

# Нижняя челюсть: железная планка с зубами (шарнир слева)
func _endo_jaw(im: Image) -> void:
	_box(im, 0, 1, 10, 3, ENDO)
	im.fill_rect(Rect2i(0, 1, 2, 2), ENDO_D)
	_px(im, 1, 2, ENDO_L)
	for x in range(3, 10):
		if x % 2 == 1:
			_px(im, x, 0, TEETH)
	_px(im, 9, 3, TEETH.darkened(0.2))

func _endo_arm(im: Image, w: int, h: int) -> void:
	_box(im, 0, 0, w, 4, ENDO)                                       # плечевой шарнир
	_px(im, w / 2, 1, ENDO_L)
	_px(im, w / 2 - 1, 2, ENDO_D)
	_box(im, 1, 3, 3, 6, ENDO_L.darkened(0.1))                       # плечевая кость
	im.fill_rect(Rect2i(w - 2, 2, 1, 4), ENDO_L)                     # поршень
	im.fill_rect(Rect2i(w - 2, 6, 1, 3), ENDO_D)
	_box(im, 0, 8, w, 3, ENDO)                                       # локоть
	_px(im, w / 2, 9, RUST)
	im.fill_rect(Rect2i(1, 12, w - 2, h - 13), Color(0.12, 0.10, 0.10))     # пушка-остов: ствол внутри
	for y in range(11, h):
		_px(im, 0, y, ENDO)
		_px(im, w - 1, y, ENDO)
	for y in [11, 14, h - 1]:
		im.fill_rect(Rect2i(0, y, w, 1), ENDO_L.darkened(0.15))
	im.fill_rect(Rect2i(2, h - 3, w - 4, 2), Color(1.0, 0.45, 0.15))  # жар в стволе

func _endo_leg(im: Image, w: int, h: int) -> void:
	_box(im, 1, 0, w - 2, 3, ENDO)                                   # тазобедренный шарнир
	_box(im, 2, 2, 3, 6, ENDO_L.darkened(0.1))                       # бедро
	im.fill_rect(Rect2i(w - 2, 2, 1, 5), ENDO_L)                     # поршень спереди
	_box(im, 1, 7, w - 2, 3, ENDO)                                   # колено
	_px(im, w / 2, 8, RUST)
	_box(im, 2, 9, 2, 5, ENDO_L.darkened(0.1))                       # голень
	im.fill_rect(Rect2i(0, 9, 1, 4), ENDO_L)                         # гидравлика сзади
	_px(im, 0, 11, ENDO_D)
	_box(im, 0, 13, 5, 2, ENDO_D.lightened(0.15))                    # стопа
	im.fill_rect(Rect2i(4, 14, w - 4, 1), ENDO_L)                    # когти
	_px(im, w - 1, 15, TEETH)
	_px(im, w - 3, 15, TEETH)

# Рваный плащ: неровный низ и дыры
static func _tear(im: Image, k := 1.0) -> void:
	var w := im.get_width()
	var h := im.get_height()
	for x in w:
		var cut := int(h * (0.22 + 0.3 * absf(sin(x * 1.9 + 0.7))) * k)
		if x % 3 == 0:
			cut += 3
		im.fill_rect(Rect2i(x, h - cut, 1, cut), Color(0, 0, 0, 0))
	for hole in [Vector2i(2, h / 3), Vector2i(w - 5, h / 2 - 3), Vector2i(w / 2, h / 5)]:
		im.fill_rect(Rect2i(hole.x, hole.y, 2, 2), Color(0, 0, 0, 0))

# Ядро, рёбра, челюсть, зрачки и провода остова
func _build_endo() -> void:
	var tw: int = spec["torso"][0]
	var th: int = spec["torso"][1]
	var hw: int = spec["head"][0]
	var hh: int = spec["head"][1]
	var core := Node2D.new()                                         # ядро — между полостью и рёбрами
	core.position = Vector2((tw + 1) / 2.0 - tw / 2.0, 8.5 - th)
	_torso.add_child(core)
	var halo := Polygon2D.new()                                      # отсвет ядра на стенках полости (светлит, а не закрашивает)
	halo.polygon = Util.circle(3.9, 20)
	halo.color = Color(1.0, 0.45, 0.12, 0.2)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = add
	core.add_child(halo)
	var mounts := Node2D.new()                                       # скобы, что держат ядро
	for k in 4:
		var m := Polygon2D.new()
		var a := PI / 4 + k * PI / 2
		m.polygon = PackedVector2Array([Vector2(-0.7, -0.45), Vector2(0.7, -0.45), Vector2(0.7, 0.45), Vector2(-0.7, 0.45)])
		m.position = Vector2.from_angle(a) * 3.7
		m.rotation = a
		m.color = ENDO_L.darkened(0.25)
		mounts.add_child(m)
	core.add_child(mounts)
	var shell := Polygon2D.new()
	shell.polygon = Util.circle(3.2, 8)
	shell.color = Color(0.80, 0.22, 0.06)
	core.add_child(shell)
	var mid := Polygon2D.new()
	mid.polygon = Util.circle(2.4, 8)
	mid.color = Color(1.0, 0.52, 0.14)
	core.add_child(mid)
	var hot := Polygon2D.new()
	hot.polygon = PackedVector2Array([Vector2(0, -1.5), Vector2(1.2, 0), Vector2(0, 1.5), Vector2(-1.2, 0)])
	hot.color = Color(1.0, 0.88, 0.5)
	core.add_child(hot)
	var dot := Polygon2D.new()
	dot.polygon = Util.circle(0.55, 6)
	dot.color = Color(1, 1, 0.95)
	core.add_child(dot)
	var arc := Line2D.new()
	arc.width = 0.35
	arc.default_color = Color(1.0, 0.85, 0.5, 0.95)
	arc.visible = false
	core.add_child(arc)
	var hinge := Vector2(3, 8.5)                                     # рёбра раскрываются на шарнире у позвоночника
	var up := _sprite(_torso, _endo_ribs(tw, th, true), hinge, hinge - Vector2(tw / 2.0, th))
	var lo := _sprite(_torso, _endo_ribs(tw, th, false), hinge, hinge - Vector2(tw / 2.0, th))
	var pad := _head_pad()
	var x0 := int(pad.x)
	var y0 := int(pad.y)
	var head_pivot := Vector2(pad.x + hw / 2.0, pad.y + hh)
	var jimg := _img(10, 4)
	_endo_jaw(jimg)
	var jaw := _sprite(_head, jimg, Vector2(0.5, 1.0), Vector2(x0 + hw - 10 + 0.5, y0 + 10) - head_pivot)
	var pupils := Node2D.new()                                       # зрачки в пустых глазницах
	for c in [Vector2(x0 + hw - 3.0, y0 + 6.5), Vector2(x0 + hw - 8.5, y0 + 6.5)]:
		var g := Polygon2D.new()
		g.polygon = Util.circle(1.15, 10)
		g.color = Color(1.0, 0.42, 0.12, 0.5)
		g.position = c - head_pivot
		pupils.add_child(g)
		var d := Polygon2D.new()
		d.polygon = Util.circle(0.5, 8)
		d.color = Color(1.0, 0.95, 0.82)
		d.position = c - head_pivot
		pupils.add_child(d)
	_head.add_child(pupils)
	var cables: Array = []                                           # провода свисают с плеч и локтя
	var aw: float = spec["arm"][0]
	for cd in [[_torso, Vector2(-tw / 2.0 + 2.5, -th + 1.5), 9.0, CABLE], [_torso, Vector2(-tw / 2.0 + 5.0, -th + 2.0), 6.5, Color(0.13, 0.12, 0.15)],
			[_arm_f, Vector2(-aw / 2.0, 9.5), 5.0, CABLE.darkened(0.2)], [_head, Vector2(-hw / 2.0 + 1.0, -2.0), 4.0, Color(0.13, 0.12, 0.15)]]:
		var l := Line2D.new()
		l.width = 0.7
		l.default_color = cd[3]
		l.begin_cap_mode = Line2D.LINE_CAP_ROUND
		l.end_cap_mode = Line2D.LINE_CAP_ROUND
		(cd[0] as Node).add_child(l)
		cables.append({"line": l, "from": cd[1], "len": cd[2]})
	_endo = {"core": core, "halo": halo, "shell": shell, "mid": mid, "hot": hot, "dot": dot, "arc": arc,
			"ribs_up": up, "ribs_lo": lo, "ribs_y": up.position.y, "jaw": jaw, "pupils": pupils, "cables": cables}

# Ядро, зрачки, провода — плавно, каждый кадр (сам каркас двигается рывками)
func _endo_tick(delta: float) -> void:
	var core: Node2D = _endo["core"]
	var hp_k := 1.0
	if bot and is_instance_valid(bot) and bot.max_hp > 0:
		hp_k = clampf(float(bot.hp) / bot.max_hp, 0.0, 1.0)
	var ph := fmod(_t * (1.1 + (1.0 - hp_k) * 1.4), 1.0)            # сердцебиение: двойной толчок, чаще — когда изранен
	var beat := exp(-pow((ph - 0.08) * 18.0, 2.0)) + 0.6 * exp(-pow((ph - 0.3) * 18.0, 2.0))
	_core_flash = maxf(0.0, _core_flash - delta * 5.0)
	var sc := 1.0 + 0.12 * beat
	var halo_a := 0.16 + 0.16 * beat
	var shell_c := Color(0.80, 0.22, 0.06)
	var mid_c := Color(1.0, 0.52, 0.14)
	var hot_c := Color(1.0, 0.88, 0.5)
	var ok := core_open
	match core_state:
		"off":
			shell_c = Color(0.24, 0.12, 0.10)
			mid_c = Color(0.30, 0.13, 0.10)
			hot_c = Color(0.38, 0.18, 0.13)
			halo_a = 0.0
			sc = 1.0
		"spent":
			shell_c = Color(0.30, 0.12, 0.10)
			mid_c = Color(0.46, 0.17, 0.10)
			hot_c = Color(0.56, 0.26, 0.15)
			halo_a = 0.04
			sc = 0.9
		"hot":
			var kh := 0.5 + 0.5 * sin(_t * 22.0)
			mid_c = Color(1.0, 0.75, 0.3).lerp(Color(1, 1, 0.9), kh)
			hot_c = Color(1, 1, 0.95)
			halo_a = 0.32 + 0.2 * kh
			sc = 1.15 + 0.15 * kh
		_:
			mid_c = mid_c.lerp(Color(1.0, 0.86, 0.45), ok)
			hot_c = hot_c.lerp(Color(1, 1, 0.95), ok)
			halo_a += 0.14 * ok
			sc += 0.12 * ok
	if _core_flash > 0.0:
		shell_c = shell_c.lerp(Color(1, 1, 1), _core_flash)
		mid_c = mid_c.lerp(Color(1, 1, 1), _core_flash)
	(_endo["shell"] as Polygon2D).color = shell_c
	(_endo["mid"] as Polygon2D).color = mid_c
	(_endo["hot"] as Polygon2D).color = hot_c
	var halo: Polygon2D = _endo["halo"]
	halo.color.a = halo_a
	halo.scale = Vector2.ONE * (1.0 + 0.12 * ok + (0.3 if core_state == "hot" else 0.0))
	core.scale = Vector2.ONE * sc
	(_endo["mid"] as Polygon2D).rotation += delta * (1.5 + 4.0 * ok)
	(_endo["hot"] as Polygon2D).rotation -= delta * 2.5
	(_endo["dot"] as Polygon2D).visible = core_state != "off"
	var arc: Line2D = _endo["arc"]                                  # разряды от ядра к стенкам полости
	_arc_t -= delta
	if _arc_t <= 0.0:
		if arc.visible:
			arc.visible = false
			_arc_t = randf_range(0.25, 0.9) / (1.0 + ok * 2.0)
		elif core_state in ["on", "hot"]:
			var a := randf() * TAU
			var pts := PackedVector2Array([Vector2.from_angle(a) * 3.0])
			for i in 3:
				pts.append(Vector2.from_angle(a + randf_range(-0.5, 0.5)) * (4.2 + i * 1.5))
			arc.points = pts
			arc.visible = true
			_arc_t = 0.07
	var ru: Sprite2D = _endo["ribs_up"]                              # грудная клетка раскрывается
	var rl: Sprite2D = _endo["ribs_lo"]
	var rk := minf(1.0, 14.0 * delta)
	ru.rotation = lerp_angle(ru.rotation, -0.32 * core_open, rk)
	rl.rotation = lerp_angle(rl.rotation, 0.28 * core_open, rk)
	ru.position.y = lerpf(ru.position.y, float(_endo["ribs_y"]) - 1.2 * core_open, rk)
	rl.position.y = lerpf(rl.position.y, float(_endo["ribs_y"]) + 1.2 * core_open, rk)
	var pu: Node2D = _endo["pupils"]                                 # зрачки дрожат и иногда гаснут на миг
	pu.visible = pupils_on and fmod(_t * 0.73, 1.0) > 0.025
	pu.position = Vector2(randf_range(-0.12, 0.12), randf_range(-0.12, 0.12))
	for c in _endo["cables"]:                                       # провода качаются и тянутся за движением
		var l: Line2D = c["line"]
		var f: Vector2 = c["from"]
		var ln: float = c["len"]
		var sway := sin(_t * 2.3 + f.x) * 1.0 - clampf(_vel().x * _facing() / 400.0, -1.5, 1.5)
		var pts2 := PackedVector2Array()
		for i in 6:
			var q := i / 5.0
			pts2.append(f + Vector2(sway * q * q - q * 0.8, ln * q))
		l.points = pts2

# Резкие подёргивания головы и руки, как у сломанного механизма
func _endo_twitch(delta: float) -> float:
	_twitch_t -= delta
	_twitch_left -= delta
	if _twitch_t <= 0.0:
		_twitch_t = randf_range(0.7, 2.2)
		_twitch_left = randf_range(0.12, 0.3)
		_twitch = randf_range(-0.45, 0.35)
		_jaw_twitch = 0.25 if randf() < 0.5 else 0.0
	if _twitch_left <= 0.0:
		_twitch = 0.0
		_jaw_twitch = 0.0
	return _twitch

# Голова дёргается прямо сейчас (сцена пробуждения)
func jerk(a: float, time := 0.25) -> void:
	_twitch = a
	_twitch_left = time
	_twitch_t = maxf(_twitch_t, time + 0.4)

# Попадание в открытое ядро — вспышка
func core_hit() -> void:
	_core_flash = 1.0

func core_point() -> Vector2:
	if _endo.has("core") and is_instance_valid(_endo["core"]):
		return (_endo["core"] as Node2D).global_position
	if _torso:
		return _torso.to_global(Vector2(0, -spec["torso"][1] * 0.55))
	return global_position

# Броня Колосса трескается: огненные трещины на частях тела (уровень 1–3 — всё больше)
func shell_cracks(level: int) -> void:
	var tw: float = spec["torso"][0]
	var th: float = spec["torso"][1]
	var hw: float = spec["head"][0]
	var hh: float = spec["head"][1]
	var aw: float = spec["arm"][0]
	var ah: float = spec["arm"][1]
	var lw: float = spec["leg"][0]
	var lh: float = spec["leg"][1]
	var parts := [[_torso, Rect2(-tw / 2 + 1, -th + 1, tw - 2, th - 2)], [_torso, Rect2(-tw / 2 + 1, -th + 1, tw - 2, th - 2)],
			[_head, Rect2(-hw / 2 + 1, -hh + 1, hw - 2, hh - 2)], [_arm_f, Rect2(-aw / 2 + 1, 0, aw - 2, ah - 3)],
			[_leg_f, Rect2(-lw / 2 + 1, 1, lw - 2, lh - 3)], [_arm_b, Rect2(-aw / 2 + 1, 0, aw - 2, ah - 3)]]
	for k in 2 + level * 2:
		var pr: Array = parts[(k + level) % parts.size()]
		var part: Node2D = pr[0]
		var r: Rect2 = pr[1]
		if part == null:
			continue
		var l := Line2D.new()
		var pts := PackedVector2Array([r.position + Vector2(randf() * r.size.x, randf() * r.size.y * 0.6)])
		for i in 3:
			var q: Vector2 = pts[pts.size() - 1] + Vector2(randf_range(-2.2, 2.2), randf_range(1.0, 2.6))
			pts.append(Vector2(clampf(q.x, r.position.x, r.end.x), clampf(q.y, r.position.y, r.end.y)))
		l.points = pts
		l.width = 0.55
		l.default_color = Color(1.0, 0.62, 0.2, 0.0)
		l.z_index = 1
		part.add_child(l)
		_cracks.append(l)
		l.create_tween().tween_property(l, "default_color:a", 0.95, 0.25).set_delay(k * 0.05)

# Точки на теле (в мире) — откуда сыплются осколки брони
func body_points() -> Array:
	var res := []
	for part in [_torso, _head, _arm_f, _arm_b, _leg_f]:
		if part:
			res.append(part.global_position)
	return res

# ---------- Анимации ----------
func play(n: String, speed := 1.0) -> void:
	if n == "shoot" or n == "shoot_big":
		_recoil = 0.35 if _t - _last_shot < 0.22 else 1.0       # очередь — мелкая дрожь, одиночный — заметный толчок
		_last_shot = _t
	_act = n
	_act_t = 0.0
	_play_len(n)
	_act_len /= speed

func _play_len(n: String) -> void:
	match n:
		"shoot": _act_len = 0.14
		"shoot_big": _act_len = 0.35
		"punch": _act_len = 0.28
		"throw", "throw_smoke", "volley": _act_len = 0.35
		"slam": _act_len = 0.55
		"bash": _act_len = 0.45
		"invoke": _act_len = 0.75
		"transform": _act_len = 0.6
		"cast", "summon", "shield": _act_len = 0.7
		"roar": _act_len = 0.9
		"windup": _act_len = 0.6
		"swing": _act_len = 0.6
		"stomp": _act_len = 0.9
		"roots": _act_len = 1.0
		"spores": _act_len = 0.6
		"roll": _act_len = 0.42
		"trap": _act_len = 0.45
		"hook": _act_len = 0.3
		"kneel_sky": _act_len = 1.1
		"hammer1", "hammer2": _act_len = 0.4
		"hammer3": _act_len = 0.62
		"leap": _act_len = 0.5
		"anvil": _act_len = 0.6
		"forge": _act_len = 1.0
		"big_swing": _act_len = 0.55
		"finisher": _act_len = 0.45
		"pistol": _act_len = 0.22
		"roll_f": _act_len = 0.42
		"knife_run": _act_len = 0.9
		"slash": _act_len = 0.4
		"radio": _act_len = 0.9
		"cut1", "cut2", "cut3": _act_len = 0.36
		"cut4": _act_len = 0.36
		"cut5": _act_len = 0.5
		"flurry": _act_len = 1.0
		"big_cut", "wave_cut": _act_len = 0.5
		"cut_down": _act_len = 0.35
		"dash_up": _act_len = 0.45
		"ignite": _act_len = 0.9
		_: _act_len = 0.3

func hurt() -> void:
	_hurt = 0.12

func _process(delta: float) -> void:
	if bot != null and not is_instance_valid(bot):
		return
	_t += delta
	_hurt = maxf(0.0, _hurt - delta)
	modulate = Color(1.0, 0.55, 0.55) if _hurt > 0.0 else Color.WHITE
	# разворот: обычно быстрый, у Колосса — медленный, видно как он поворачивается
	scale.x = move_toward(scale.x, float(_facing()), delta * _turn_speed)
	if absf(scale.x) < 0.15:
		# тонкую «ребром» фазу проскакиваем сразу на сторону, куда разворачивается.
		# (раньше здесь оставался прежний знак — и медленный Колосс застревал сжатым)
		scale.x = 0.15 * float(_facing())
	if kind == "totem":
		_glow.modulate.a = 0.6 + 0.4 * sin(_t * 4.0)
		_glow.scale = Vector2.ONE * (1.0 + 0.15 * sin(_t * 4.0))
		return
	if _act != "":
		_act_t += delta
		if _act_t >= _act_len:
			_act = ""
	_item_hidden = maxf(0.0, _item_hidden - delta)
	_hold_t = _hold_t + delta if hold != "" else 0.0
	if _weapon:
		_weapon.visible = not weapon_hidden and alt == ""
	for a in _alts:
		_alts[a].visible = alt == a
	if _back:
		_back.visible = alt != "ranged"
	if _item:
		_item.visible = _item_hidden <= 0.0
	if _heat:
		_heat.color.a = core_heat * (0.5 + 0.35 * sin(_t * 9.0))
	if not _endo.is_empty():
		_endo_tick(delta)
		_step_acc += delta                     # остов двигается рывками, как старый механизм
		if _step_acc < 1.0 / 15.0:
			_tremble()
			return
		delta = _step_acc
		_step_acc = 0.0
	# обычные враги пересчитывают позу через кадр (30 раз в секунду): на глаз движение то же,
	# а работы вдвое меньше. Герои и боссы — каждый кадр.
	if bot != null and bot.is_bot and bot.stagger_max <= 0.0 and not instant:
		_pose_acc += delta
		if (Engine.get_process_frames() + _pose_slot) % 2 == 0:
			_tremble()
			return
		delta = _pose_acc
		_pose_acc = 0.0
	_pose(delta)
	_tremble()

func _tremble() -> void:
	if tremble > 0.0 and _art:
		_art.position = Vector2(0, _size().y / 2) + Vector2(randf_range(-1.0, 1.0), randf_range(-0.6, 0.6)) * tremble

# Поворот, место и размер части пишутся, только если заметно изменились: каждая запись
# заставляет движок пометить «устаревшей» всю ветку узлов под этой частью, а у стоящей
# фигуры поза не меняется — писать нечего.
static func _rot(n: Node2D, v: float) -> void:
	if absf(n.rotation - v) > 0.0008:
		n.rotation = v

static func _pos(n: Node2D, v: Vector2) -> void:
	if n.position.distance_squared_to(v) > 0.0001:
		n.position = v

static func _scl(n: Node2D, v: Vector2) -> void:
	if n.scale.distance_squared_to(v) > 0.000001:
		n.scale = v

func _pose(delta: float) -> void:
	var vel := _vel()
	var vx := vel.x
	var on_floor := _floor()
	var spd := absf(vx)
	var moving := spd > 15.0 and on_floor
	var leg_len: float = spec["leg"][1] * px
	# плавные добавки — у обычных фигур; остов и Колосс двигаются по-своему (рывками, тяжело)
	var soft: bool = smooth and _endo.is_empty() and not _colossal() and sit <= 0.0
	if moving:
		_phase += delta * spd / maxf(leg_len * 0.9, 10.0)
	_run_k = move_toward(_run_k, 1.0 if moving else 0.0, delta * (10.0 if moving else 7.0))
	var sw := sin(_phase) if moving else 0.0
	var amp := 0.6
	var lift_f := 0.0              # насколько поднята стопа (нога «сгибается» в колене)
	var lift_b := 0.0
	if soft:
		# шаг: чем быстрее бежит, тем шире; нога, что идёт вперёд, поднимает стопу
		sw = sin(_phase) * _run_k
		amp = lerpf(0.42, 0.72, clampf(spd / 320.0, 0.0, 1.0))
		lift_f = maxf(0.0, -cos(_phase)) * _run_k
		lift_b = maxf(0.0, cos(_phase)) * _run_k
	var lf := sw * amp
	var lb := -sw * amp
	var up_rot := 0.0
	var up_y := -absf(sin(_phase)) * 0.8 if moving else sin(_t * 2.0) * 0.3
	var head_rot := 0.0
	var art_rot := 0.0
	var air_arms := 0.0            # руки в прыжке (у тех, кто не целится из оружия)
	if soft:
		# тело покачивается плавно (без «ступеньки» в нижней точке), на бегу наклоняется вперёд
		var bob := -sin(_phase) * sin(_phase) * 0.9
		up_y = lerpf(sin(_t * 2.0) * 0.3, bob, _run_k)
		up_rot = 0.07 * _run_k * clampf(spd / 260.0, 0.0, 1.0)
		head_rot = -0.03 * _run_k + sin(_t * 1.3) * 0.02 * (1.0 - _run_k)
	if not on_floor:
		lf = -0.6
		lb = 0.35
		if soft:
			# взлёт — ноги поджаты и разведены, вершина — собраны, падение — тянутся к земле
			var rise := clampf(-vel.y / 420.0, -1.0, 1.0)
			if rise >= 0.0:
				lf = lerpf(-0.4, -0.85, rise)
				lb = lerpf(0.25, 0.6, rise)
				lift_b = 0.9 * rise
				lift_f = 0.35 * rise
				up_rot += 0.05 * rise
			else:
				lf = lerpf(-0.4, -0.12, -rise)
				lb = lerpf(0.25, 0.08, -rise)
				up_rot -= 0.04 * -rise
				air_arms = -rise
	# сжатие и растяжение: толчок прыжка вытягивает фигуру, приземление — сплющивает
	if soft and bot != null:
		if _was_floor and not on_floor and vel.y < -150.0:
			_squash = 0.9
			_squash_v = 0.0
		elif not _was_floor and on_floor and _fall_v > 250.0:
			_squash = -clampf(_fall_v / 900.0, 0.35, 1.0)
			_squash_v = 0.0
			if not bot.is_bot and _fall_v > 520.0 and is_instance_valid(bot.get_parent()):     # герой тяжело приземлился — пыль из-под ног
				Fx.dust(bot.get_parent(), bot.global_position + Vector2(0, _size().y / 2), 3, Color(0.62, 0.58, 0.52), 46.0, 9.0)
		if not on_floor:
			_fall_v = vel.y
		var dt := minf(delta, 1.0 / 30.0)
		_squash_v += (-_squash * 260.0 - _squash_v * 20.0) * dt      # пружина с одним мягким отскоком
		_squash = clampf(_squash + _squash_v * dt, -1.2, 1.2)
	else:
		_squash = 0.0
	_was_floor = on_floor
	var w: String = spec["weapon"]
	var aimed: bool = w in AIMED or _colossal()
	var af: float
	var ab: float
	var af_off := Vector2.ZERO
	var ab_off := Vector2.ZERO
	# локти (0 — рука прямая, меньше нуля — согнута): с оружием на изготовку рука чуть согнута,
	# на бегу локти согнуты, как у бегуна, в падении руки раскинуты и почти прямые
	var ef := -0.5 if aimed else -0.2 - 0.85 * _run_k * (1.0 - air_arms)
	var eb := (-0.7 if w in TWO_HANDED else -0.25 - 0.6 * _run_k) if aimed else -0.2 - 0.85 * _run_k * (1.0 - air_arms)
	if aimed:
		af = -PI / 2 + 0.04 * sin(_t * 2.0)
		ab = -1.15 if w in TWO_HANDED else -sw * 0.45
		if _colossal():
			ab = sw * 0.3
		if spec.get("port_arms", false) and hold != "aim" and _act != "shoot":
			# бег с автоматом наперевес: ствол вниз-вперёд, корпус наклонён
			af = -0.55 + sw * 0.08
			ab = -0.95 + sw * 0.08
			if moving:
				up_rot = 0.14
	else:
		af = -sw * 0.5
		ab = sw * 0.5
		if soft:
			af += sin(_t * 2.0 + 1.0) * 0.04 * (1.0 - _run_k) - 0.55 * air_arms
			ab += -sin(_t * 2.0 + 1.0) * 0.04 * (1.0 - _run_k) + 0.45 * air_arms
		if _style() == "gladiator":
			ab = -0.9 + sw * 0.15         # щит держит перед собой
	# --- таран Гладиатора: наклон вперёд, щит впереди, быстрые ноги ---
	if bot and bot._charging > 0.0:
		up_rot = 0.35
		lf = sin(_phase * 1.4) * 1.0
		lb = -lf
		ab = -PI / 2
		af = 0.7
	# --- рывок (очень быстро несётся вперёд): корпус стелется, свободная рука и нога отброшены назад ---
	if soft and bot != null and spd > 520.0 and signf(vx) == float(_facing()) and not bot.is_stunned():
		var dk := clampf((spd - 520.0) / 380.0, 0.0, 1.0)
		up_rot += 0.32 * dk
		head_rot -= 0.2 * dk
		lf = lerpf(lf, -0.95, dk)
		lb = lerpf(lb, 0.85, dk)
		if not aimed:
			af = lerpf(af, 0.9, dk * 0.7)
			ef = lerpf(ef, -0.15, dk)
		ab = lerpf(ab, 1.1, dk * (0.4 if aimed else 0.8))
		eb = lerpf(eb, -0.1, dk)
	# --- получил удар: на миг отшатывается (боссы не дёргаются — им и так достаётся каждую секунду) ---
	if soft and _hurt > 0.0 and bot != null and bot.stagger_max <= 0.0:
		var hk := _hurt / 0.12
		up_rot -= 0.16 * hk
		head_rot += 0.22 * hk
		art_rot -= 0.03 * hk
		if not aimed:
			ef -= 0.5 * hk
		eb -= 0.5 * hk
	# --- оглушение: покачивается, голова свесилась, руки опущены ---
	if bot and bot.is_stunned():
		up_rot = sin(_t * 3.5) * 0.12
		art_rot = sin(_t * 3.5) * 0.03
		head_rot = 0.35 + sin(_t * 3.5 + 1.0) * 0.12
		af = 0.15 + sin(_t * 3.5) * 0.1
		ab = -0.1
		lf = sin(_t * 3.5) * 0.12
		lb = -lf
		up_y = 1.0
	# --- разовые движения (или длительное — hold) ---
	var act := _act
	var p := clampf(_act_t / maxf(_act_len, 0.01), 0.0, 1.0)
	if act == "" and hold != "":
		act = hold
		p = minf(1.0, _hold_t / 0.3)
	var art_pos := Vector2(0, _size().y / 2)
	if act != "":
		match act:
			"shoot":
				af -= 0.35 * (1.0 - p)
				up_rot -= 0.05 * (1.0 - p)
				if soft and aimed:      # отдача: всё тело на миг подаётся назад, локоть сгибается
					ef -= 0.4 * _recoil * (1.0 - p)
					art_pos.x -= 1.1 * _recoil * (1.0 - p) * (1.0 - p)
					head_rot -= 0.06 * _recoil * (1.0 - p)
				if _flash:
					_flash.visible = p < 0.4
				if not aimed:      # посохом — выпад вперёд со вспышкой
					af = -PI / 2
					af_off.x = 2.0 * sin(PI * p)
					if _glow:
						_glow.color.a = 0.8 * (1.0 - p)
			"shoot_big":
				af -= 0.6 * (1.0 - p)
				up_rot -= 0.15 * (1.0 - p)
				if soft:                # тяжёлый выстрел: отбрасывает назад и приседает
					art_pos.x -= 2.2 * (1.0 - p) * (1.0 - p)
					up_y += 1.0 * sin(PI * minf(1.0, p * 2.0))
					lb += 0.25 * (1.0 - p)
				if _flash:
					_flash.visible = p < 0.3
					_flash.scale = Vector2.ONE * 2.0
			"punch":
				var k := sin(PI * p)
				if soft:
					if p < 0.2:
						k = -0.45 * sin(PI * 0.5 * p / 0.2)                 # замах: рука и корпус назад
					elif p < 0.42:
						k = lerpf(-0.45, 1.0, ease((p - 0.2) / 0.22, 2.2))  # выпад — резко
					else:
						k = 1.0 - ease((p - 0.42) / 0.58, 0.55)              # возврат — мягко
					lf -= 0.25 * maxf(k, 0.0)                                # шаг вперёд на ударе
					lb += 0.2 * maxf(k, 0.0)
					var bend := -1.75 * (1.0 - clampf((p - 0.2) / 0.22, 0.0, 1.0)) if p < 0.42 else -0.5 * ease((p - 0.42) / 0.58, 0.6)
					if aimed:
						eb = bend                                           # бьёт свободной рукой: кулак от груди — вперёд
					else:
						ef = bend
				if aimed:
					ab = -PI / 2
					ab_off.x = 4.0 * k
				else:
					af = -PI / 2
					af_off.x = 4.0 * k
				up_rot += 0.15 * k
			"throw", "throw_smoke", "volley":
				var a: float
				if p < 0.35:
					a = 2.5
					up_rot -= 0.12
					if soft:
						var wq := p / 0.35
						a = lerpf(1.9, 2.75, ease(wq, 0.4))       # рука уходит за голову, а не «щёлкает» туда
						ef = -1.5 * wq
						eb = ef
						up_y += 0.8 * wq
						lb += 0.2 * wq
				else:
					var q := (p - 0.35) / 0.65
					a = lerpf(2.5, 5.0, q)
					up_rot += 0.18 * sin(PI * q)
					if soft:
						a = lerpf(2.75, 5.2, ease(q, 0.35))        # мах — быстрый в начале, с доводкой
						ef = -1.5 * (1.0 - ease(q, 0.3))
						eb = ef
						lf -= 0.3 * sin(PI * q)
						art_pos.x += 1.0 * sin(PI * q)
					if _item:
						_item_hidden = 0.6
				if act == "throw_smoke" and _item and spec.has("item"):
					ab = a
				else:
					af = a
				if act == "volley":
					ab = a
			"slam":
				if p < 0.7:
					af = PI
					ab = PI
					up_rot = -0.12
					ef = -1.0 * minf(1.0, p * 4.0)          # руки согнуты над головой — и распрямляются в ударе
					eb = ef
				else:
					var q := (p - 0.7) / 0.3
					af = lerpf(PI, 5.8, q)
					ab = af
					up_rot = 0.3 * q
					up_y += 2.0 * q
			"cast":
				af = lerpf(af, PI, minf(1.0, p * 4.0))
				ef = -0.9 * sin(PI * minf(1.0, p * 1.6))    # рука идёт вверх согнутой и распрямляется
				eb = -1.1 * sin(PI * p)                     # вторая — к груди
				if soft:
					up_y += 1.2 * sin(PI * minf(1.0, p * 5.0)) - 0.8 * sin(PI * p)
					head_rot -= 0.15 * sin(PI * p)
				if _glow:
					_glow.color.a = 0.9 * sin(PI * p)
			"summon":
				af = 3.6
				ab = 2.7
				ef = -0.5 - 0.2 * sin(_t * 6.0)
				eb = -0.7
				up_rot = -0.1
				head_rot = -0.2
			"shield":
				af = -PI / 2
				af_off.x = 3.0 * sin(PI * p)
			"roar":
				af = 3.7
				ab = 2.6
				ef = -0.6
				eb = -0.8
				head_rot = -0.4 + sin(_t * 40.0) * 0.05
				up_rot = -0.15
			"windup":
				up_rot = -0.2
				ab = -PI / 2
				af = 0.9
				lf = 0.5
				lb = -0.3
			"swing":
				if p < 0.55:
					af = lerpf(-0.3, 2.6, minf(1.0, p / 0.3))
					up_rot = -0.12
				else:
					var q := (p - 0.55) / 0.45
					af = lerpf(2.6, 5.5, ease(q, 0.4))
					up_rot = 0.25 * q
			"stomp":
				if p < 0.45:
					lf = -1.1 * minf(1.0, p / 0.25)
					up_rot = -0.12
					af = -PI / 2 - 0.4
				else:
					lf = lerpf(-1.1, 0.1, minf(1.0, (p - 0.45) / 0.1))
					up_y += 2.0
					art_rot = sin(_t * 50.0) * 0.02
			"invoke":        # ульта: оружие поднято к небу, голова запрокинута
				var k2 := minf(1.0, p * 3.0)
				af = lerpf(af, PI + 0.15, k2)
				ab = lerpf(ab, 2.4, k2)
				up_rot = -0.12 * k2
				head_rot = -0.3 * k2
				lf = 0.25 * k2
				lb = -0.25 * k2
				art_rot = sin(_t * 45.0) * 0.015 * k2
				if _glow:
					_glow.color.a = 0.6 + 0.4 * sin(_t * 20.0)
					_glow.scale = Vector2.ONE * (1.0 + 1.5 * k2)
			"transform":     # превращение: сжимается, руки обхватывают тело
				var k3 := sin(PI * p)
				af = 0.9 * k3
				ab = -0.9 * k3 + 0.2
				up_rot = 0.3 * k3
				head_rot = 0.4 * k3
				up_y += 2.0 * k3
				lf = -0.3 * k3
				lb = 0.3 * k3
			"bash":          # таран щитом: наклон вперёд, щит перед собой
				up_rot = 0.35
				ab = -PI / 2
				af = 0.6
				lf = sin(_t * 30.0) * 0.9
				lb = -lf
			"roots":
				up_rot = 0.45 * minf(1.0, p * 4.0)
				af = -0.25
				ab = -0.15
				af_off.y = 2.0
			"spores":
				head_rot = sin(p * 30.0) * 0.15
				if _crown:
					_crown.scale = Vector2.ONE * (1.0 + 0.08 * sin(p * 40.0))
			# ----- Охотница -----
			"draw":          # натягивает тетиву: лук вперёд, правая рука тянет к щеке
				af = -PI / 2 - 0.08
				ab = -PI / 2 + 0.15
				ab_off.x = -3.0 * p
				up_rot = -0.04 * p
				head_rot = 0.08 * p
				lf = 0.35 * p
				lb = -0.3 * p
			"hook":          # выстрел крюком — вверх-вперёд
				af = -PI / 2 - 0.7
				ab = -PI / 2 - 0.55
				ab_off.x = -2.0 * (1.0 - p)
				up_rot = -0.12
			"roll":          # кувырок назад: сжалась в комок и перекатилась
				var rk := sin(PI * p)
				lf = -1.6 * rk
				lb = -1.3 * rk
				af = 1.2 * rk
				ab = 1.0 * rk
				head_rot = 0.5 * rk
				up_rot = 0.4 * rk
				up_y += 3.0 * rk
				art_rot = -TAU * ease(p, -1.6)
			"trap":          # присела и ставит капкан
				var tk := sin(PI * p)
				up_rot = 0.55 * tk
				af = -0.35 * tk
				ab = -0.1
				lf = -1.0 * tk
				lb = 0.5 * tk
				up_y += 2.5 * tk
			"kneel_sky":     # ульта: на колене, лук в небо, тетива до уха
				var kk := minf(1.0, p * 3.0)
				lf = -1.35 * kk
				lb = 1.25 * kk
				up_y += 3.5 * kk
				af = lerpf(af, PI - 0.08, kk)
				ab = lerpf(ab, PI - 0.25, kk)
				ab_off.y = 3.0 * kk
				head_rot = -0.45 * kk
				up_rot = -0.08 * kk
				art_rot = sin(_t * 40.0) * 0.01 * kk
			# ----- Солдат -----
			"aim":           # стрельба на ходу: автомат у плеча
				af = -PI / 2 + 0.03 * sin(_t * 40.0)
				ab = -1.2
				up_rot = 0.03
				head_rot = 0.05
			"pistol":        # выстрел с одной руки, отдача вверх
				af = -PI / 2 - 0.35 * (1.0 - p)
				ab = 0.25
				up_rot = -0.05 * (1.0 - p)
			"roll_f":        # кувырок вперёд
				var rf := sin(PI * p)
				lf = -1.6 * rf
				lb = -1.3 * rf
				af = -1.0 * rf
				ab = -0.8 * rf
				head_rot = 0.5 * rf
				up_rot = 0.4 * rf
				up_y += 3.0 * rf
				art_rot = TAU * ease(p, -1.6)
			"knife_run":     # бег с ножом: быстрые удары перед собой
				af = -PI / 2 + sin(_t * 38.0) * 1.0
				ab = -0.6 + sin(_t * 38.0 + 2.0) * 0.4
				up_rot = 0.3
				lf = sin(_t * 30.0) * 1.0
				lb = -lf
			"slash":         # рассекающий удар ножом
				af = lerpf(2.2, -2.0, ease(p, 0.4))
				ab = -0.5
				up_rot = lerpf(-0.15, 0.3, p)
				lf = -0.6
				lb = 0.5
			"radio":         # рация у уха, свободная рука указывает на цель
				af = 2.75
				ab = -PI / 2 - 0.35
				head_rot = 0.15
				up_rot = -0.04
			# ----- Самурай -----
			"cut1":          # косой удар: клинок за голову — резкий взмах вперёд-вниз — замер
				if p < 0.3:
					af = lerpf(-0.9, 2.6, ease(p / 0.3, 0.5))
					up_rot = -0.15 * (p / 0.3)
					lb = 0.3
				elif p < 0.55:
					var q1 := (p - 0.3) / 0.25
					af = lerpf(2.6, 5.25, ease(q1, 0.4))
					up_rot = lerpf(-0.15, 0.25, q1)
					lf = -0.55 * q1
					lb = 0.45
				else:
					af = 5.25
					up_rot = 0.25
					lf = -0.55
					lb = 0.45
				ab = af - 0.45
			"cut2":          # удар снизу вверх: присел, клинок у земли — взмах к небу
				if p < 0.3:
					af = lerpf(-0.9, 0.9, ease(p / 0.3, 0.5))
					up_rot = 0.25 * (p / 0.3)
					up_y += 2.0 * (p / 0.3)
					lf = -0.5
					lb = 0.5
				elif p < 0.55:
					var q2 := (p - 0.3) / 0.25
					af = lerpf(0.9, -2.5, ease(q2, 0.4))
					up_rot = lerpf(0.25, -0.2, q2)
					up_y += 2.0 * (1.0 - q2)
					lf = lerpf(-0.5, 0.2, q2)
					lb = lerpf(0.5, -0.2, q2)
				else:
					af = -2.5
					up_rot = -0.2
				ab = af + 0.3
			"cut3":          # рубящий: подпрыгнул с клинком над головой — рубит вниз
				if p < 0.35:
					af = lerpf(-0.9, PI - 0.1, ease(p / 0.35, 0.5))
					up_rot = -0.2 * (p / 0.35)
					up_y -= 2.5 * sin(PI * p / 0.35)
					lf = -0.6
					lb = 0.3
				elif p < 0.55:
					var q3 := (p - 0.35) / 0.2
					af = lerpf(PI - 0.1, 5.0, ease(q3, 0.35))
					up_rot = lerpf(-0.2, 0.4, q3)
					up_y += 3.0 * q3
					lf = -0.9
					lb = 0.7
				else:
					af = 5.0
					up_rot = 0.4
					up_y += 3.0
					lf = -0.9
					lb = 0.7
				ab = af - 0.35
			"cut4":          # выпад: отвёл клинок назад — колющий удар с шагом
				if p < 0.3:
					af = -PI / 2 + 0.7 * (p / 0.3)
					af_off.x = -3.0 * (p / 0.3)
					up_rot = -0.12
					lb = 0.4
				elif p < 0.5:
					var q4 := (p - 0.3) / 0.2
					af = -PI / 2
					af_off.x = lerpf(-3.0, 6.0, ease(q4, 0.4))
					up_rot = 0.35 * q4
					lf = -1.0 * q4
					lb = 0.9 * q4
				else:
					af = -PI / 2
					af_off.x = 6.0
					up_rot = 0.35
					lf = -1.0
					lb = 0.9
				ab = -PI / 2 + 0.3
			"cut5":          # удар с разворотом: замах — оборот на месте — клинок вытянут
				if p < 0.25:
					af = lerpf(-0.9, 1.6, p / 0.25)
					up_rot = -0.2
				else:
					af = -PI / 2 - 0.2
					up_rot = 0.15
					lf = -0.5
					lb = 0.5
				ab = -PI / 2 + 0.5
			"flurry":        # серия молниеносных ударов: припал на колено, наклонился, рубит одной рукой
				var kq := minf(1.0, p / FLURRY_SET)
				kq = kq * kq * (3.0 - 2.0 * kq)
				lf = -1.35 * kq
				lb = 1.25 * kq
				up_y += 3.5 * kq
				up_rot = 0.3 * kq
				head_rot = -0.22 * kq
				ab = lerpf(-0.3, -0.75, kq)                # свободная рука — на колене
				ab_off.y = 1.5 * kq
				if p < FLURRY_SET:
					af = lerpf(-0.5, FLURRY_CUTS[0].x, kq)   # клинок отведён для первого удара
				else:
					var e := (p - FLURRY_SET) / FLURRY_STEP
					var si := mini(int(e), FLURRY_CUTS.size() - 1)
					var q := clampf(e - si, 0.0, 1.0)
					q = q * q * (3.0 - 2.0 * q)
					af = lerpf(FLURRY_CUTS[si].x, FLURRY_CUTS[si].y, q)
				up_y += 0.4 * sin(_t * 31.0) * kq          # плечи чуть ходят в такт
			"big_cut", "wave_cut":   # мощный взмах с глубоким замахом
				if p < 0.45:
					af = lerpf(-0.4, 2.0, ease(p / 0.45, 0.6))
					up_rot = -0.3 * (p / 0.45)
					lb = 0.5
				else:
					var qb := (p - 0.45) / 0.55
					af = lerpf(2.0, 4.9, ease(qb, 0.3))
					up_rot = lerpf(-0.3, 0.4, ease(qb, 0.3))
					lf = -0.7
					lb = 0.6
				ab = af - 0.4
			"dash_up":       # рывок вверх: клинок вперёд-вверх
				af = -2.3
				ab = 0.6
				up_rot = -0.25
				lf = -0.8
				lb = 0.6
			"cut_down":      # удар вниз после телепорта
				af = lerpf(PI, 5.6, ease(p, 0.3))
				ab = af - 0.4
				up_rot = 0.4 * p
				lf = -0.9
				lb = 0.5
			"ignite":        # клинок перед лицом, ладонь скользит по нему — он загорается
				af = -2.3
				ab = lerpf(-1.4, -2.6, p)
				ab_off.x = 2.0
				head_rot = -0.1
				up_rot = -0.05
			# ----- Кузнец -----
			"hammer1":       # удар сверху
				if p < 0.4:
					af = lerpf(-0.3, 2.6, p / 0.4)          # замах за голову
					up_rot = -0.15
				else:
					var q1 := (p - 0.4) / 0.6
					af = lerpf(2.6, 5.15, ease(q1, 0.35))   # удар вперёд-вниз
					up_rot = 0.28 * minf(1.0, q1 * 2.0)
					up_y += 1.5 * q1
				ab = af - 0.25
				lf = -0.35
				lb = 0.3
			"hammer2":       # размах снизу вверх
				if p < 0.35:
					af = lerpf(0.0, 1.6, p / 0.35)
					up_rot = -0.2
				else:
					var q2 := (p - 0.35) / 0.65
					af = lerpf(1.6, -2.2, ease(q2, 0.35))
					up_rot = lerpf(-0.2, 0.15, q2)
				ab = af + 0.2
				lf = 0.4
				lb = -0.4
			"hammer3", "big_swing", "finisher":   # тяжёлый удар с полным замахом
				var wind := 0.5 if act == "hammer3" else 0.4
				if p < wind:
					var q0 := p / wind
					af = lerpf(-0.3, 2.1, ease(q0, 0.6))     # глубокий замах за спину
					up_rot = -0.32 * q0
					lb = 0.5 * q0
					lf = -0.2 * q0
				else:
					var q3 := (p - wind) / (1.0 - wind)
					af = lerpf(2.1, 5.3, ease(q3, 0.3))
					up_rot = lerpf(-0.32, 0.45, ease(q3, 0.3))
					up_y += 2.5 * q3
					lf = -0.6
					lb = 0.55
					if q3 > 0.6:
						art_rot = sin(_t * 60.0) * 0.02
				ab = af - 0.3
			"leap":          # прыжок с молотом над головой
				af = PI + 0.3
				ab = PI + 0.1
				up_rot = -0.15
				lf = -0.9
				lb = 0.5
			"anvil":         # призыв наковальни: кулак в небо, потом резко вниз
				if p < 0.5:
					ab = lerpf(0.0, PI, p * 2.0)
					head_rot = -0.35
				else:
					ab = lerpf(PI, -0.4, (p - 0.5) * 2.0)
					up_rot = 0.15
				af = -0.5
			"forge":         # ульта: замах, удар в землю, выпрямляется в полный рост
				if p < 0.35:
					af = lerpf(-0.3, 2.7, p / 0.35)
					ab = af - 0.2
					up_rot = -0.25
					up_y -= 1.0
				elif p < 0.5:
					var qf := (p - 0.35) / 0.15
					af = lerpf(2.7, 5.4, qf)
					ab = af - 0.2
					up_rot = 0.5 * qf
					up_y += 3.0 * qf
					lf = -0.7
					lb = 0.6
				else:
					var qr := (p - 0.5) / 0.5
					af = lerpf(5.4, PI - 0.3, ease(qr, 0.5))
					ab = lerpf(-0.2, 2.4, ease(qr, 0.5))
					up_rot = lerpf(0.5, -0.2, ease(qr, 0.5))
					head_rot = -0.35 * qr
					up_y += 3.0 * (1.0 - qr)
					art_rot = sin(_t * 45.0) * 0.015
	else:
		if _flash:
			_flash.visible = false
		if _crown:
			_crown.scale = Vector2.ONE
	# свечение на оружии гаснет, когда нет колдовства
	if _glow and w == "hammer":
		_glow.color.a = move_toward(_glow.color.a, 0.55 * heat * (0.8 + 0.2 * sin(_t * 12.0)), delta * 4.0)
		_glow.scale = Vector2.ONE * (1.0 + 0.3 * heat)
		if _weapon:
			_weapon.get_node("Skin").modulate = Color(1, 1, 1).lerp(Color(1.6, 0.85, 0.5), heat)   # раскалённый металл
	elif _glow and not (act in ["invoke", "shoot", "cast"]):
		_glow.color.a = move_toward(_glow.color.a, 0.0, delta * 3.0)
		_glow.scale = _glow.scale.move_toward(Vector2.ONE, delta * 4.0)
	# король на троне: сидит, руки на подлокотниках
	if sit > 0.0:
		lf = lerpf(lf, -1.45, sit)
		lb = lerpf(lb, -1.35, sit)
		af = lerpf(af, -0.25, sit)        # руки опущены, меч упирается остриём в пол
		ab = lerpf(ab, -0.15, sit)
		up_rot = lerpf(up_rot, -0.06, sit)
		head_rot = lerpf(head_rot, 0.25, sit)
	if _eye_glow:
		_eye_glow.visible = eyes_lit
		_eye_glow.modulate.a = 0.75 + 0.25 * sin(_t * 6.0)
	if _halo:
		_halo.self_modulate = Color(1, 1, 1).lerp(Color(1.25, 1.2, 1.1), 0.5 + 0.5 * sin(_t * 2.6))   # кольцо чуть «дышит»
	if _cape:
		_rot(_cape, -0.08 - minf(absf(vx) / 600.0, 0.35) + sin(_t * 2.0) * 0.03)
	if not _endo.is_empty():
		var tw2 := _endo_twitch(delta)
		head_rot += tw2
		ab += tw2 * 1.4
	# применяем позу (плавно — без рывков)
	var k := 1.0 if instant else minf(1.0, 22.0 * delta)
	var tl_f := lf
	var tl_b := lb
	if _jointed:
		# колени. Нога вынесена вперёд (прыжок, присед, кувырок) — колено согнуто, стопа под бедром;
		# нога позади — чуть согнута. На бегу сгибается та нога, что идёт вперёд, а на шаге она
		# выпрямляется. Приземление — присед на обе ноги.
		var gen := 1.0 - (_run_k if on_floor else 0.0)
		var kf := (clampf(-lf * 0.95, 0.0, 1.5) + maxf(0.0, lf) * 0.35) * gen
		var kb := (clampf(-lb * 0.95, 0.0, 1.5) + maxf(0.0, lb) * 0.35) * gen
		if soft:
			var crouch := 0.55 * maxf(0.0, -_squash)
			kf = maxf(kf, 1.3 * lift_f) + crouch
			kb = maxf(kb, 1.3 * lift_b) + crouch
			tl_f -= 0.42 * (1.3 * lift_f if on_floor else 0.0) + crouch * 0.5      # колено выносится вперёд
			tl_b -= 0.42 * (1.3 * lift_b if on_floor else 0.0) + crouch * 0.5
		_rot(_shin_f, lerp_angle(_shin_f.rotation, kf, k))
		_rot(_shin_b, lerp_angle(_shin_b.rotation, kb, k))
	_rot(_leg_f, lerp_angle(_leg_f.rotation, tl_f, k))
	_rot(_leg_b, lerp_angle(_leg_b.rotation, tl_b, k))
	for u in [_upper_f, _upper_b]:
		_rot(u, lerp_angle(u.rotation, up_rot, k))
		_pos(u, Vector2(u.position.x, lerpf(u.position.y, _hip + up_y, k)))
	_rot(_head, lerp_angle(_head.rotation, head_rot, k))
	if _crown:
		_crown.rotation = sin(_t * 1.6) * 0.05
	var ua_f := af
	var ua_b := ab
	if _jointed:
		# предплечье отстаёт, когда рука уходит назад и вверх (замах), и распрямляется на ударе
		var dtm := maxf(delta, 0.001)
		var live := soft and not instant
		_dyn_f = lerpf(_dyn_f, clampf(angle_difference(_prev_af, af) / dtm * 0.05, 0.0, 1.2) if live else 0.0, minf(1.0, 16.0 * delta))
		_dyn_b = lerpf(_dyn_b, clampf(angle_difference(_prev_ab, ab) / dtm * 0.05, 0.0, 1.2) if live else 0.0, minf(1.0, 16.0 * delta))
		_prev_af = af
		_prev_ab = ab
		ef = clampf(ef - _dyn_f, -2.3, 0.1)
		eb = clampf(eb - _dyn_b, -2.3, 0.1)
		# с оружием на изготовку ствол смотрит туда же, куда раньше смотрела вся рука: плечо
		# доворачивается на угол локтя; в остальных движениях — наполовину (кисть ближе к прежнему месту)
		ua_f = af - ef * (1.0 if aimed else 0.5)
		ua_b = ab - eb * 0.5
		var eq := 1.0 if instant else minf(1.0, 26.0 * delta)
		_rot(_fore_f, lerp_angle(_fore_f.rotation, ef, eq))
		_rot(_fore_b, lerp_angle(_fore_b.rotation, eb, eq))
	_rot(_arm_f, lerp_angle(_arm_f.rotation, ua_f, 1.0 if instant else minf(1.0, (48.0 if act == "flurry" else 30.0) * delta)))
	_rot(_arm_b, lerp_angle(_arm_b.rotation, ua_b, 1.0 if instant else minf(1.0, 30.0 * delta)))
	var arm_w := _arm_f.rotation + (_fore_f.rotation if _jointed else 0.0)       # куда смотрит кисть с оружием
	_pos(_arm_f, _arm_base_f + af_off)
	if _weapon and (w == "katana" or w == "kama" or w == "dawn_blade"):
		if act in SWORD_ACTS:
			_rot(_weapon, PI / 2)             # катана продолжает руку
		elif act == "ignite":
			_rot(_weapon, (-PI / 2) - arm_w)
		else:
			_rot(_weapon, (-0.95) - arm_w)             # стойка: клинок вперёд-вверх
	if _blade_flame:
		_blade_flame.visible = blade_fire.a > 0.0
		if _blade_flame.visible:
			_blade_flame.default_color = blade_fire
			_blade_flame.modulate = blade_fire
			_blade_flame.width = 3.5 + 1.5 * sin(_t * 30.0)
	if _weapon and w == "hammer":
		if act in HAMMER_ACTS or act in ["leap"]:
			_rot(_weapon, PI / 2)             # молот продолжает руку — бьёт бойком
		else:
			_rot(_weapon, (-PI / 2 - 0.45) - arm_w)             # лежит на плече
	elif _weapon and w in UPRIGHT and w != "katana" and w != "kama":
		var world_a := -PI / 2 + 0.25
		if act in ["throw", "volley"]:
			world_a = -0.2                # при броске копьё смотрит вперёд
		elif act == "invoke":
			world_a = -PI / 2 - 0.05      # ульта: остриём в небо
		elif act == "punch":
			world_a = 0.0                 # удар копьём — остриём вперёд
		_rot(_weapon, world_a - arm_w)
	if _string:
		# тетива: при натяжении середина уходит назад, к руке
		var pull := 0.0
		if act == "draw":
			pull = 5.0 * p
		elif act == "kneel_sky":
			pull = 6.0 * minf(1.0, p * 3.0)
		elif act == "hook":
			pull = 3.0 * (1.0 - p)
		var mid: Vector2 = (_string.points[0] + _string.points[2]) / 2.0
		_string.set_point_position(1, mid - Vector2(pull, 0))
		_nock.visible = act in ["draw", "kneel_sky"] or (act == "hook" and p < 0.3)
		_nock.position = mid + _string.position - Vector2(pull, 0)
	_pos(_arm_b, _arm_base_b + ab_off)
	_rot(_art, art_rot)
	if act == "roll" or act == "roll_f":
		_pos(_art, Vector2(0, _size().y / 2 * 0.7).rotated(art_rot))    # кувырок вокруг центра
	else:
		_pos(_art, art_pos)
	# удар с разворотом: тело поворачивается на месте (сжимается и раскрывается по ширине)
	var flip := cos(TAU * clampf((p - 0.25) / 0.5, 0.0, 1.0)) if act == "cut5" else 1.0
	_scl(_art, Vector2(px * (flip if absf(flip) > 0.12 else 0.12 * signf(flip if flip != 0.0 else 1.0)) * (1.0 - 0.08 * _squash), px * (1.0 + 0.12 * _squash)))
	if not _endo.is_empty():                   # челюсть остова: рёв — пасть настежь, замах — приоткрыта
		var jaw_r := _jaw_twitch
		match act:
			"roar":
				jaw_r = 0.75 + sin(_t * 45.0) * 0.1
			"windup", "stomp", "shoot_big", "throw":
				jaw_r = 0.32
		(_endo["jaw"] as Node2D).rotation = jaw_r
