class_name Skins
# ---------- Облики (скины) легенд ----------
# Облик — это другая модель: свои цвета одежды и брони, свой головной убор, светящиеся
# глаза и жилы, светится оружие, вокруг вьются частицы серии. И другой вид способностей:
# снаряды горят (или сочатся бездной), каждый приём и ульта вспыхивают в цветах серии.
# Механика легенды не меняется.
#
# Серии:
#   «Огненная» — выпадает из Огненного сундука в Лавке: случайный облик, которого ещё
#                нет; когда собраны все — сундук больше не открыть;
#   «Ледяная»  — выпадает из Ледяного сундука в Лавке (так же, без повторов): у каждой
#                легенды своя ледяная модель — оружие, головной убор, снаряды и приёмы;
#   «Бездна»   — открывается за прохождение Арены (100 волн) этой легендой.

const SERIES := {
	"fire": {"name": "Огненная серия", "color": Color(1.0, 0.55, 0.20), "price": 400},
	"ice": {"name": "Ледяная серия", "color": Color(0.55, 0.85, 1.0), "price": 400},
	"abyss": {"name": "Серия «Бездна»", "color": Color(0.75, 0.45, 1.0)},
	"champion": {"name": "Чемпионский облик", "color": Color(1.0, 0.86, 0.45)},
}

const THEME := {
	"fire": {"main": Color(1.0, 0.45, 0.12), "hot": Color(1.0, 0.86, 0.40), "dark": Color(0.28, 0.08, 0.04)},
	"ice": {"main": Color(0.45, 0.80, 1.0), "hot": Color(0.90, 0.98, 1.0), "dark": Color(0.06, 0.13, 0.26)},
	"abyss": {"main": Color(0.72, 0.40, 1.0), "hot": Color(0.95, 0.86, 1.0), "dark": Color(0.08, 0.04, 0.12)},
	"champion": {"main": Color(1.0, 0.84, 0.40), "hot": Color(1.0, 0.98, 0.88), "dark": Color(0.30, 0.20, 0.05)},
}

# Огненная серия: облик -> [набор легенды (kit), название, правки модели]
const FIRE := {
	"fire_hunter": ["hunter", "Пепельная лучница", {"shirt": Color(0.22, 0.14, 0.12), "pants": Color(0.16, 0.11, 0.10),
			"cape": Color(0.30, 0.12, 0.08), "cape_trim": Color(1.0, 0.50, 0.12), "cape_torn": true, "armor_plate": Color(0.45, 0.20, 0.10),
			"hat": "ember_hood", "weapon_look": "flame_bow", "back_look": "quiver_flame", "string": Color(1.0, 0.72, 0.30),
			"nock": [Color(0.22, 0.13, 0.10), Color(1.0, 0.75, 0.30), Color(1.0, 0.45, 0.12)], "eye_glow": Color(1.0, 0.6, 0.15)}],
	"fire_smith": ["smith", "Горнило", {"skin": Color(0.62, 0.38, 0.30), "shirt": Color(0.20, 0.14, 0.12), "pants": Color(0.18, 0.12, 0.10),
			"apron": Color(0.30, 0.16, 0.10), "eye_glow": Color(1.0, 0.75, 0.2), "hat": "forge_helm", "eyes_off": false,
			"weapon_look": "lava_hammer", "arm_mark": Color(1.0, 0.50, 0.12)}],
	"fire_samurai": ["samurai", "Пламенный ронин", {"shirt": Color(0.18, 0.10, 0.10), "pants": Color(0.10, 0.08, 0.08),
			"armor_plate": Color(0.55, 0.14, 0.06), "sode": Color(0.30, 0.08, 0.06), "hat": "ember_kabuto", "eye_glow": Color(1.0, 0.6, 0.15),
			"weapon_look": "ember_katana", "cape": Color(0.24, 0.08, 0.06), "cape_trim": Color(1.0, 0.50, 0.12), "cape_torn": true}],
	"fire_ternovnik": ["ternovnik", "Пепельный терн", {"skin": Color(0.40, 0.26, 0.18), "shirt": Color(0.42, 0.16, 0.07),
			"pants": Color(0.22, 0.12, 0.08), "hat": "ember_leaves", "weapon_look": "ember_branch", "eye_glow": Color(1.0, 0.6, 0.15)}],
	"fire_mortis": ["mortis", "Пепельный жнец", {"skin": Color(0.80, 0.68, 0.58), "shirt": Color(0.80, 0.68, 0.58), "pants": Color(0.80, 0.68, 0.58),
			"robe": Color(0.26, 0.08, 0.05), "hat": "pyre_hood", "weapon_look": "pyre_scythe", "eye_glow": Color(1.0, 0.6, 0.15)}],
	"fire_prism": ["prism", "Призма пламени", {"shirt": Color(0.30, 0.14, 0.10), "pants": Color(0.55, 0.20, 0.08),
			"cape": Color(0.60, 0.18, 0.06), "cape_trim": Color(1.0, 0.70, 0.25), "armor_plate": Color(0.85, 0.40, 0.12),
			"hat": "ember_circlet", "weapon_look": "ember_prism_staff", "eye_glow": Color(1.0, 0.6, 0.15)}],
	"fire_osoka": ["osoka", "Болотный огонь", {"skin": Color(0.72, 0.62, 0.56), "shirt": Color(0.30, 0.16, 0.10),
			"pants": Color(0.72, 0.62, 0.56), "boots": Color(0.18, 0.10, 0.08), "cape": Color(0.30, 0.12, 0.07),
			"cape_trim": Color(1.0, 0.50, 0.12), "armor_plate": Color(0.50, 0.20, 0.08), "hat": "ember_tina",
			"weapon_look": "ember_lantern", "frog_col": Color(0.85, 0.30, 0.10), "cape_torn": true}],
	"fire_zarnitsa": ["zarnitsa", "Зарница пожара", {"_base": true, "hair_pal": [Color(0.80, 0.22, 0.08), Color(1.0, 0.75, 0.25), Color(0.20, 0.12, 0.10), Color(1.0, 0.86, 0.40), Color(1.0, 0.60, 0.15)],
			"weapon_look": "war_fan", "wpal": [Color(0.20, 0.10, 0.08), Color(1.0, 0.50, 0.12), Color(0.45, 0.14, 0.06), Color(1.0, 0.86, 0.40), Color(0.30, 0.16, 0.10)],
			"ornament": "flames", "cape_torn": true}],
	"fire_rassvet": ["rassvet", "Рассвет пожарища", {"_base": true, "helm": Color(0.16, 0.10, 0.09), "helm_glow": Color(1.0, 0.50, 0.12), "horn": Color(0.85, 0.30, 0.08),
			"weapon_look": "dawn_blade", "wpal": [Color(0.20, 0.10, 0.08), Color(1.0, 0.50, 0.12), Color(0.16, 0.10, 0.09), Color(1.0, 0.60, 0.15), Color(0.85, 0.30, 0.08)],
			"ornament": "flames", "cape_torn": true}],
	"fire_gatekeeper": ["gatekeeper", "Привратница пламени", {"_base": true, "hood_trim": Color(1.0, 0.50, 0.12), "hair2": Color(0.60, 0.52, 0.48), "eye2": Color(1.0, 0.60, 0.15),
			"weapon_look": "key_staff", "wpal": [Color(0.20, 0.12, 0.10), Color(1.0, 0.50, 0.12), Color(1.0, 0.70, 0.25), Color(0.85, 0.40, 0.10), Color(1.0, 0.40, 0.10), Color(1.0, 0.90, 0.55)],
			"ornament": "flames"}],
	"fire_echo": ["echo", "Отголосок пепла", {"_base": true, "hood_trim": Color(1.0, 0.50, 0.12),
			"weapon_look": "echo_lantern", "wpal": [Color(0.20, 0.12, 0.10), Color(0.85, 0.40, 0.10), Color(0.18, 0.10, 0.08), Color(1.0, 0.50, 0.12), Color(1.0, 0.90, 0.55)],
			"ornament": "flames", "cape_torn": true}],
	"fire_seam": ["seam", "Шов пепла", {"_base": true, "stitch": Color(1.0, 0.55, 0.15),
			"weapon_look": "needle_spear", "wpal": [Color(0.25, 0.18, 0.16), Color(1.0, 0.50, 0.12), Color(1.0, 0.86, 0.40), Color(1.0, 0.50, 0.12)],
			"ornament": "flames", "cape_torn": true}],
	"fire_soldier": ["soldier", "Штурмовик пекла", {"shirt": Color(0.22, 0.15, 0.12), "pants": Color(0.17, 0.12, 0.10),
			"armor_plate": Color(0.45, 0.18, 0.08), "hat": "inferno_helm", "weapon_look": "flame_rifle"}],
	"fire_genius": ["genius", "Гений в огне", {"_base": true, "photo_frame": "ember", "photo_tint": Color(1.08, 0.88, 0.78), "eye_glow": null,
			"gi_trim": Color(1.0, 0.48, 0.12), "sode": Color(0.45, 0.14, 0.06), "cable": Color(1.0, 0.70, 0.25)}],
	"fire_glav": ["glav", "Главный на взводе", {"_base": true, "photo_frame": "ember", "photo_tint": Color(1.08, 0.88, 0.78), "eye_glow": null}],
	"fire_almost": ["almost", "Почти легенда: пекло", {"_base": true, "hat": "moto_helm", "ornament": "flames",
			"suit_pal": [Color(0.24, 0.16, 0.14), Color(1.0, 0.50, 0.12), Color(0.14, 0.09, 0.08), Color(1.0, 0.86, 0.40), Color(1.0, 0.72, 0.30)],
			"helm_pal": [Color(0.26, 0.17, 0.14), Color(1.0, 0.50, 0.12), Color(1.0, 0.86, 0.40), Color(0.12, 0.07, 0.06)],
			"gpal": [Color(1.0, 0.45, 0.10), Color(0.30, 0.18, 0.14), Color(1.0, 0.86, 0.40), Color(0.14, 0.08, 0.06)]}],
	"fire_dj": ["dj", "DJ Клима: огненный сет", {"_base": true, "photo_frame": "dj_ember", "photo_tint": Color(1.08, 0.88, 0.78), "eye_glow": null,
			"note": Color(1.0, 0.62, 0.20), "note_glow": Color(1.0, 0.86, 0.40), "sole": Color(1.0, 0.45, 0.12), "chain": Color(1.0, 0.78, 0.30),
			"vpal": [Color(0.16, 0.06, 0.04), Color(0.62, 0.22, 0.06), Color(1.0, 0.50, 0.12), Color(1.0, 0.86, 0.40)]}],
	"fire_pivozavr": ["pivozavr", "Пивозавр пекла", {"shirt": Color(0.30, 0.18, 0.12), "pants": Color(0.24, 0.14, 0.10),
			"armor_plate": Color(0.50, 0.20, 0.08), "tail": Color(0.62, 0.20, 0.08), "weapon_look": "molotov",
			"photo_frame": "ember", "photo_tint": Color(1.08, 0.88, 0.78)}],
	"fire_assassin": ["assassin", "Тлеющий клинок", {"shirt": Color(0.16, 0.12, 0.11), "pants": Color(0.12, 0.09, 0.08),
			"wrap": Color(0.95, 0.42, 0.10), "rope": Color(1.0, 0.70, 0.25), "tattoo": Color(1.0, 0.55, 0.15), "eye_glow": Color(1.0, 0.6, 0.15),
			"hat": "ember_tail", "weapon_look": "ember_kama", "item_look": "ember_kunai", "cape": Color(0.24, 0.10, 0.07), "cape_trim": Color(1.0, 0.50, 0.12), "cape_torn": true}],
	"fire_scribe": ["scribe", "Летописец пепла", {"_base": true, "weapon_look": "quill", "ornament": "flames",
			"cap_pal": [Color(0.20, 0.10, 0.08), Color(1.0, 0.48, 0.12), Color(1.0, 0.70, 0.28), Color(1.0, 0.92, 0.55), Color(1.0, 0.60, 0.20), Color(0.20, 0.10, 0.08)],
			"qpal": [Color(1.0, 0.58, 0.16), Color(0.85, 0.26, 0.06), Color(1.0, 0.86, 0.40), Color(0.30, 0.16, 0.10), Color(1.0, 0.45, 0.10)],
			"bpal": [Color(0.22, 0.10, 0.07), Color(0.95, 0.74, 0.45), Color(1.0, 0.50, 0.12), Color(0.12, 0.06, 0.04)],
			"scarf": Color(0.92, 0.74, 0.50), "scarf_ink": Color(0.85, 0.25, 0.06), "cape_torn": true}],
	"fire_champion": ["champion", "Чемпион пекла", {"shirt": Color(0.36, 0.16, 0.10), "pants": Color(0.20, 0.10, 0.08),
			"armor_plate": Color(0.40, 0.18, 0.10), "cape": Color(0.30, 0.10, 0.06), "cape_trim": Color(1.0, 0.50, 0.12), "cape_torn": true,
			"hat": "ember_helm", "weapon_look": "ember_spear", "shield_look": "ember_shield", "eye_glow": Color(1.0, 0.6, 0.15)}],
}

# Ледяная серия: облик -> [набор легенды (kit), название, правки модели].
# Сначала вся модель перекрашивается в цвета льда (_recolor), поверх — свои детали облика.
const ICE := {
	"ice_hunter": ["hunter", "Северная лучница", {"hat": "frost_hood", "weapon_look": "ice_bow", "back_look": "quiver_ice",
			"string": Color(0.85, 0.97, 1.0), "nock": [Color(0.70, 0.88, 1.0), Color(0.95, 1.0, 1.0), Color(0.45, 0.78, 1.0)]}],
	"ice_smith": ["smith", "Кузнец вечной мерзлоты", {"hat": "rime_helm", "weapon_look": "glacier_hammer", "eyes_off": false,
			"arm_mark": Color(0.45, 0.82, 1.0), "apron": Color(0.30, 0.42, 0.56)}],
	"ice_samurai": ["samurai", "Ронин снегопада", {"hat": "frost_kabuto", "weapon_look": "ice_katana",
			"sode": Color(0.72, 0.86, 0.98), "armor_plate": Color(0.84, 0.92, 1.0), "shirt": Color(0.86, 0.92, 0.98), "pants": Color(0.22, 0.32, 0.48)}],
	"ice_ternovnik": ["ternovnik", "Морозный терн", {"hat": "frost_leaves", "weapon_look": "frost_branch", "skin": Color(0.62, 0.70, 0.78)}],
	"ice_mortis": ["mortis", "Ледяной жнец", {"hat": "rime_hood", "weapon_look": "frost_scythe", "robe": Color(0.18, 0.30, 0.46)}],
	"ice_prism": ["prism", "Ледяная призма", {"hat": "ice_circlet", "weapon_look": "ice_prism_staff", "shirt": Color(0.86, 0.94, 1.0)}],
	"ice_osoka": ["osoka", "Мёрзлая топь", {"hat": "frost_tina", "weapon_look": "frost_lantern", "frog_col": Color(0.70, 0.90, 1.0),
			"skin": Color(0.82, 0.90, 0.96), "pants": Color(0.82, 0.90, 0.96)}],
	"ice_zarnitsa": ["zarnitsa", "Зарница стужи", {"ornament": "frost",
			"hair_pal": [Color(0.92, 0.96, 1.0), Color(0.45, 0.78, 1.0), Color(0.62, 0.80, 0.95), Color(0.85, 0.97, 1.0), Color(0.55, 0.90, 1.0)],
			"weapon_look": "war_fan", "wpal": [Color(0.80, 0.92, 1.0), Color(0.45, 0.78, 1.0), Color(0.55, 0.72, 0.90), Color(0.95, 1.0, 1.0), Color(0.36, 0.52, 0.70)]}],
	"ice_rassvet": ["rassvet", "Полярный рассвет", {"ornament": "frost", "helm": Color(0.80, 0.88, 0.96), "helm_glow": Color(0.45, 0.85, 1.0),
			"horn": Color(0.92, 0.98, 1.0), "horn_whole": true, "cape": Color(0.90, 0.95, 1.0),
			"weapon_look": "dawn_blade", "wpal": [Color(0.25, 0.36, 0.50), Color(0.60, 0.82, 1.0), Color(0.55, 0.78, 0.95), Color(0.94, 0.99, 1.0), Color(0.80, 0.92, 1.0)]}],
	"ice_gatekeeper": ["gatekeeper", "Привратница стужи", {"ornament": "frost", "hood_trim": Color(0.70, 0.92, 1.0),
			"hair2": Color(0.94, 0.97, 1.0), "eye2": Color(0.50, 0.88, 1.0),
			"weapon_look": "key_staff", "wpal": [Color(0.30, 0.42, 0.56), Color(0.70, 0.86, 0.98), Color(0.85, 0.95, 1.0), Color(0.55, 0.78, 0.95), Color(0.40, 0.80, 1.0), Color(0.95, 1.0, 1.0)]}],
	"ice_echo": ["echo", "Отголосок вьюги", {"ornament": "frost", "hood_trim": Color(0.88, 0.97, 1.0),
			"weapon_look": "echo_lantern", "wpal": [Color(0.30, 0.40, 0.52), Color(0.60, 0.75, 0.88), Color(0.22, 0.32, 0.46), Color(0.45, 0.82, 1.0), Color(0.94, 0.99, 1.0)]}],
	"ice_seam": ["seam", "Шов инея", {"ornament": "frost", "stitch": Color(0.60, 0.90, 1.0),
			"weapon_look": "needle_spear", "wpal": [Color(0.80, 0.92, 1.0), Color(0.40, 0.55, 0.72), Color(0.95, 1.0, 1.0), Color(0.55, 0.88, 1.0)]}],
	"ice_soldier": ["soldier", "Полярный штурмовик", {"hat": "polar_helm", "weapon_look": "frost_rifle",
			"shirt": Color(0.84, 0.88, 0.92), "pants": Color(0.74, 0.80, 0.86), "armor_plate": Color(0.40, 0.56, 0.72)}],
	"ice_genius": ["genius", "Гений на морозе", {"photo_frame": "frost", "photo_tint": Color(0.92, 0.98, 1.08), "eye_glow": null,
			"gi_trim": Color(0.55, 0.85, 1.0), "sode": Color(0.30, 0.45, 0.62), "cable": Color(0.90, 0.98, 1.0)}],
	"ice_glav": ["glav", "Главный со льдом", {"photo_frame": "frost", "photo_tint": Color(0.92, 0.98, 1.08), "eye_glow": null}],
	"ice_almost": ["almost", "Почти легенда: вечная мерзлота", {"hat": "moto_helm", "ornament": "frost",
			"suit_pal": [Color(0.88, 0.95, 1.0), Color(0.45, 0.80, 1.0), Color(0.24, 0.38, 0.56), Color(0.90, 0.98, 1.0), Color(0.80, 0.92, 1.0)],
			"helm_pal": [Color(0.90, 0.96, 1.0), Color(0.45, 0.80, 1.0), Color(0.80, 0.97, 1.0), Color(0.22, 0.36, 0.55)],
			"gpal": [Color(0.55, 0.85, 1.0), Color(0.90, 0.96, 1.0), Color(1.0, 1.0, 1.0), Color(0.30, 0.50, 0.75)]}],
	"ice_dj": ["dj", "DJ Клима: ледяной бит", {"photo_frame": "dj_frost", "photo_tint": Color(0.92, 0.98, 1.08), "eye_glow": null,
			"note": Color(0.90, 0.97, 1.0), "note_glow": Color(0.55, 0.85, 1.0), "sole": Color(0.55, 0.85, 1.0), "chain": Color(0.86, 0.92, 1.0),
			"vpal": [Color(0.50, 0.74, 0.92), Color(0.80, 0.94, 1.0), Color(0.94, 0.99, 1.0), Color(0.35, 0.60, 0.95)]}],
	"ice_pivozavr": ["pivozavr", "Пивозавр со льда", {"tail": Color(0.55, 0.78, 0.92), "weapon_look": "ice_bottle",
			"photo_frame": "frost", "photo_tint": Color(0.92, 0.98, 1.08), "eye_glow": null, "cape": null}],
	"ice_assassin": ["assassin", "Тень метели", {"hat": "frost_tail", "weapon_look": "ice_kama", "item_look": "ice_kunai",
			"wrap": Color(0.75, 0.90, 1.0), "rope": Color(0.45, 0.70, 0.92), "tattoo": Color(0.70, 0.95, 1.0), "cape_torn": true}],
	"ice_champion": ["champion", "Чемпион Севера", {"hat": "frost_crest_helm", "weapon_look": "ice_spear", "shield_look": "frost_shield"}],
	"ice_scribe": ["scribe", "Летописец стужи", {"weapon_look": "quill", "ornament": "frost",
			"cap_pal": [Color(0.86, 0.92, 0.98), Color(0.45, 0.80, 1.0), Color(0.92, 0.98, 1.0), Color(0.55, 0.85, 1.0), Color(0.70, 0.90, 1.0), Color(0.88, 0.92, 0.98)],
			"qpal": [Color(0.82, 0.94, 1.0), Color(0.50, 0.76, 0.96), Color(0.92, 0.98, 1.0), Color(0.60, 0.86, 1.0), Color(0.30, 0.60, 0.95)],
			"bpal": [Color(0.30, 0.45, 0.62), Color(0.92, 0.96, 1.0), Color(0.70, 0.92, 1.0), Color(0.16, 0.26, 0.40)],
			"scarf": Color(0.92, 0.96, 1.0), "scarf_ink": Color(0.35, 0.65, 0.95)}],
}

# Проработанные облики «Бездны» и Чемпиона: своя модель поверх общей перекраски серии
const LOOKS := {
	"abyss_scribe": {"hat": "scribe_cap", "weapon_look": "quill", "ornament": "shards", "cape_torn": true,
			"cap_pal": [Color(0.10, 0.07, 0.15), Color(0.72, 0.40, 1.0), Color(0.20, 0.13, 0.28), Color(0.85, 0.55, 1.0), Color(0.72, 0.40, 1.0), Color(0.80, 0.76, 0.90)],
			"qpal": [Color(0.18, 0.11, 0.26), Color(0.32, 0.17, 0.48), Color(0.45, 0.24, 0.70), Color(0.72, 0.40, 1.0), Color(0.85, 0.55, 1.0)],
			"bpal": [Color(0.12, 0.08, 0.17), Color(0.30, 0.22, 0.40), Color(0.72, 0.40, 1.0), Color(0.06, 0.04, 0.09)],
			"scarf": Color(0.24, 0.16, 0.32), "scarf_ink": Color(0.85, 0.55, 1.0)},
	"champ_scribe": {"hat": "scribe_cap", "weapon_look": "quill",
			"cap_pal": [Color(0.96, 0.93, 0.86), Color(1.0, 0.80, 0.32), Color(1.0, 1.0, 0.95), Color(1.0, 0.85, 0.40), Color(1.0, 0.80, 0.32), Color(0.98, 0.92, 0.70)],
			"qpal": [Color(1.0, 1.0, 0.96), Color(1.0, 0.88, 0.55), Color(1.0, 0.85, 0.45), Color(1.0, 0.80, 0.32), Color(1.0, 0.70, 0.20)],
			"bpal": [Color(0.96, 0.93, 0.86), Color(1.0, 0.97, 0.88), Color(1.0, 0.80, 0.32), Color(1.0, 0.80, 0.32)],
			"scarf": Color(1.0, 0.97, 0.88), "scarf_ink": Color(1.0, 0.72, 0.22)},
	"abyss_hunter": {"hat": "void_hood", "weapon_look": "void_bow", "back_look": "quiver_void", "cape_torn": true,
			"string": Color(0.80, 0.55, 1.0), "nock": [Color(0.14, 0.09, 0.20), Color(0.85, 0.55, 1.0), Color(0.50, 0.24, 0.80)]},
	"champ_hunter": {"hat": "sun_circlet", "weapon_look": "sun_bow", "back_look": "quiver_sun",
			"string": Color(1.0, 0.97, 0.80), "nock": [Color(0.98, 0.94, 0.80), Color(1.0, 1.0, 0.92), Color(1.0, 0.82, 0.35)]},
	"abyss_smith": {"cape": null, "hat": "void_smith", "weapon_look": "void_maul", "eyes_off": false, "arm_mark": Color(0.72, 0.40, 1.0)},
	"abyss_assassin": {"hat": "void_tail", "weapon_look": "void_kama", "item_look": "void_kunai", "cape_torn": true},
	"champ_assassin": {"hat": "sun_tail", "weapon_look": "sun_kama", "item_look": "sun_kunai"},
	"abyss_ternovnik": {"hat": "void_thorns", "weapon_look": "void_branch", "cape_torn": true},
	"champ_ternovnik": {"hat": "bloom_crown", "weapon_look": "bloom_branch"},
	"abyss_mortis": {"hat": "void_cowl", "weapon_look": "void_scythe", "cape_torn": true},
	"champ_mortis": {"hat": "soul_crown", "weapon_look": "sun_scythe"},
	"abyss_prism": {"hat": "void_circlet", "weapon_look": "void_prism_staff", "cape_torn": true},
	"champ_prism": {"hat": "radiant_circlet", "weapon_look": "sun_prism_staff"},
	"abyss_champion": {"hat": "void_crest_helm", "weapon_look": "void_spear", "shield_look": "void_shield", "cape_torn": true},
	"champ_champion": {"hat": "laurel_helm", "weapon_look": "sun_spear", "shield_look": "sun_shield"},
	"abyss_osoka": {"hat": "void_tina", "weapon_look": "void_lantern", "frog_col": Color(0.32, 0.18, 0.48), "cape_torn": true},
	"champ_osoka": {"hat": "lotus_crown", "weapon_look": "lotus_staff", "frog_col": Color(0.95, 0.78, 0.30)},
	"abyss_zarnitsa": {"hair_pal": [Color(0.12, 0.08, 0.17), Color(0.72, 0.40, 1.0), Color(0.40, 0.20, 0.60), Color(0.95, 0.85, 1.0), Color(0.85, 0.55, 1.0)],
			"weapon_look": "war_fan", "wpal": [Color(0.10, 0.07, 0.15), Color(0.72, 0.40, 1.0), Color(0.30, 0.15, 0.45), Color(0.95, 0.85, 1.0), Color(0.18, 0.10, 0.26)],
			"hat": "zarnitsa_hair", "ornament": "shards", "cape_torn": true},
	"champ_zarnitsa": {"hair_pal": [Color(0.98, 0.95, 0.86), Color(1.0, 0.80, 0.32), Color(1.0, 0.80, 0.32), Color(1.0, 1.0, 0.95), Color(1.0, 0.85, 0.40)],
			"weapon_look": "war_fan", "wpal": [Color(0.96, 0.94, 0.88), Color(1.0, 0.80, 0.32), Color(0.90, 0.82, 0.62), Color(1.0, 0.65, 0.20), Color(1.0, 0.80, 0.32)],
			"hat": "zarnitsa_hair"},
	"abyss_rassvet": {"helm": Color(0.10, 0.07, 0.14), "helm_glow": Color(0.72, 0.40, 1.0), "horn": Color(0.55, 0.28, 0.85), "horn_whole": true,
			"weapon_look": "dawn_blade", "wpal": [Color(0.12, 0.08, 0.16), Color(0.72, 0.40, 1.0), Color(0.08, 0.06, 0.11), Color(0.80, 0.50, 1.0), Color(0.35, 0.18, 0.52)],
			"hat": "rassvet_helm", "ornament": "shards", "cape_torn": true},
	"champ_rassvet": {"helm": Color(0.96, 0.93, 0.86), "helm_glow": Color(1.0, 0.80, 0.32), "horn": Color(1.0, 0.82, 0.38), "horn_whole": true,
			"weapon_look": "dawn_blade", "wpal": [Color(0.96, 0.93, 0.86), Color(1.0, 0.80, 0.32), Color(0.98, 0.97, 0.92), Color(1.0, 0.82, 0.35), Color(0.90, 0.86, 0.75)],
			"hat": "rassvet_helm"},
	"abyss_gatekeeper": {"hood_trim": Color(0.72, 0.40, 1.0), "hair2": Color(0.80, 0.76, 0.90), "eye2": Color(0.95, 0.85, 1.0),
			"weapon_look": "key_staff", "wpal": [Color(0.12, 0.08, 0.16), Color(0.55, 0.28, 0.85), Color(0.72, 0.40, 1.0), Color(0.45, 0.22, 0.70), Color(0.10, 0.05, 0.15), Color(0.85, 0.55, 1.0)],
			"hat": "gate_hood", "ornament": "shards", "cape_torn": true},
	"champ_gatekeeper": {"cape": Color(0.95, 0.92, 0.84), "hood_trim": Color(1.0, 0.80, 0.32), "hair2": Color(0.98, 0.97, 0.92), "eye2": Color(1.0, 0.85, 0.40),
			"weapon_look": "key_staff", "wpal": [Color(0.96, 0.93, 0.86), Color(1.0, 0.80, 0.32), Color(1.0, 0.90, 0.55), Color(1.0, 0.78, 0.30), Color(1.0, 1.0, 0.95), Color(1.0, 1.0, 1.0)],
			"hat": "gate_hood"},
	"abyss_echo": {"hood_trim": Color(0.95, 0.85, 1.0), "cape": Color(0.08, 0.06, 0.11),
			"weapon_look": "echo_lantern", "wpal": [Color(0.10, 0.07, 0.14), Color(0.40, 0.20, 0.60), Color(0.06, 0.04, 0.09), Color(0.20, 0.06, 0.30), Color(0.85, 0.55, 1.0)],
			"hat": "echo_hood", "ornament": "shards", "cape_torn": true},
	"champ_echo": {"cape": Color(0.95, 0.92, 0.84), "hood_trim": Color(1.0, 0.80, 0.32),
			"weapon_look": "echo_lantern", "wpal": [Color(0.96, 0.93, 0.86), Color(1.0, 0.80, 0.32), Color(1.0, 0.82, 0.38), Color(1.0, 0.92, 0.60), Color(1.0, 1.0, 0.95)],
			"hat": "echo_hood"},
	"abyss_seam": {"stitch": Color(0.80, 0.50, 1.0),
			"weapon_look": "needle_spear", "wpal": [Color(0.15, 0.10, 0.22), Color(0.72, 0.40, 1.0), Color(0.95, 0.85, 1.0), Color(0.72, 0.40, 1.0)],
			"hat": "seam_hood", "ornament": "shards", "cape_torn": true},
	"champ_seam": {"cape": Color(0.95, 0.92, 0.84), "stitch": Color(1.0, 0.95, 0.70),
			"weapon_look": "needle_spear", "wpal": [Color(1.0, 0.82, 0.38), Color(0.98, 0.96, 0.90), Color(1.0, 1.0, 0.95), Color(1.0, 1.0, 0.95)],
			"hat": "seam_hood"},
	"abyss_soldier": {"hat": "void_helm", "weapon_look": "void_rifle", "cape_torn": true},
	"champ_soldier": {"hat": "parade_helm", "weapon_look": "sun_rifle"},
	"abyss_samurai": {"hat": "void_kabuto", "weapon_look": "void_katana", "cape_torn": true},
	"champ_samurai": {"hat": "sun_kabuto", "weapon_look": "sun_katana", "sode": Color(1.0, 0.82, 0.38)},
	"abyss_pivozavr": {"eye_glow": null, "tail": Color(0.26, 0.12, 0.40), "weapon_look": "void_flask", "photo_frame": "void",
			"photo_tint": Color(0.82, 0.74, 1.0), "cape": null},
	"champ_pivozavr": {"eye_glow": null, "tail": Color(0.95, 0.78, 0.35), "weapon_look": "gold_bottle", "photo_frame": "sun",
			"photo_tint": Color(1.08, 1.04, 0.92), "cape": null},
	"abyss_genius": {"eye_glow": null, "photo_frame": "void", "photo_tint": Color(0.85, 0.78, 1.0), "gi_trim": Color(0.72, 0.40, 1.0),
			"sode": Color(0.18, 0.08, 0.28), "cable": Color(0.85, 0.55, 1.0)},
	"champ_genius": {"eye_glow": null, "photo_frame": "sun", "photo_tint": Color(1.08, 1.04, 0.92), "gi_trim": Color(1.0, 0.80, 0.32),
			"sode": Color(0.98, 0.86, 0.48), "cable": Color(1.0, 0.95, 0.70)},
	"abyss_glav": {"eye_glow": null, "photo_frame": "void", "photo_tint": Color(0.85, 0.78, 1.0)},
	"champ_glav": {"eye_glow": null, "photo_frame": "sun", "photo_tint": Color(1.08, 1.04, 0.92)},
	"abyss_almost": {"hat": "moto_helm", "ornament": "shards", "cape": null,
			"suit_pal": [Color(0.20, 0.14, 0.28), Color(0.72, 0.40, 1.0), Color(0.08, 0.05, 0.12), Color(0.95, 0.85, 1.0), Color(0.60, 0.50, 0.75)],
			"helm_pal": [Color(0.22, 0.15, 0.30), Color(0.72, 0.40, 1.0), Color(0.90, 0.70, 1.0), Color(0.06, 0.04, 0.09)],
			"gpal": [Color(0.55, 0.28, 0.85), Color(0.22, 0.15, 0.30), Color(0.95, 0.85, 1.0), Color(0.08, 0.05, 0.12)]},
	"champ_almost": {"hat": "moto_helm", "cape": null,
			"suit_pal": [Color(1.0, 0.97, 0.88), Color(1.0, 0.80, 0.32), Color(0.30, 0.24, 0.14), Color(1.0, 1.0, 0.92), Color(1.0, 0.84, 0.36)],
			"helm_pal": [Color(1.0, 0.97, 0.88), Color(1.0, 0.80, 0.32), Color(1.0, 0.95, 0.70), Color(0.30, 0.24, 0.14)],
			"gpal": [Color(1.0, 0.80, 0.32), Color(1.0, 0.97, 0.88), Color(1.0, 1.0, 0.92), Color(0.55, 0.40, 0.12)]},
	"abyss_dj": {"eye_glow": null, "cape": null, "photo_frame": "dj_void", "photo_tint": Color(0.85, 0.78, 1.0), "note": Color(0.85, 0.55, 1.0),
			"note_glow": Color(0.95, 0.80, 1.0), "sole": Color(0.72, 0.40, 1.0), "chain": Color(0.80, 0.70, 0.95),
			"vpal": [Color(0.08, 0.05, 0.12), Color(0.36, 0.18, 0.55), Color(0.72, 0.40, 1.0), Color(0.95, 0.85, 1.0)]},
	"champ_dj": {"eye_glow": null, "cape": null, "shirt": Color(0.12, 0.11, 0.10), "photo_frame": "dj_sun", "photo_tint": Color(1.08, 1.04, 0.92), "note": Color(1.0, 0.86, 0.42),
			"note_glow": Color(1.0, 0.97, 0.85), "sole": Color(1.0, 0.80, 0.32), "chain": Color(1.0, 0.86, 0.42),
			"vpal": [Color(1.0, 0.80, 0.32), Color(1.0, 0.92, 0.60), Color(1.0, 1.0, 0.95), Color(0.80, 0.55, 0.12)]},
	"champ_smith": {"cape": null, "hat": "titan_crown", "weapon_look": "sun_hammer", "eyes_off": false, "arm_mark": Color(1.0, 0.82, 0.35),
			"skin": Color(0.90, 0.72, 0.58)},
}

# Свои имена проработанных обликов
const NAMES := {
	"abyss_hunter": "Ловчая Бездны", "champ_hunter": "Солнечная лучница — истинный облик",
	"abyss_smith": "Кузнец Бездны", "champ_smith": "Титан горна — истинный облик",
	"abyss_assassin": "Тень Бездны", "champ_assassin": "Рассветная тень — истинный облик",
	"abyss_ternovnik": "Терн Бездны", "champ_ternovnik": "Древо жизни — истинный облик",
	"abyss_mortis": "Жнец Бездны", "champ_mortis": "Король душ — истинный облик",
	"abyss_prism": "Чёрная призма", "champ_prism": "Солнечная призма — истинный облик",
	"abyss_champion": "Чемпион Бездны", "champ_champion": "Непобедимый — истинный облик",
	"abyss_osoka": "Топь Бездны", "champ_osoka": "Владычица лотосов — истинный облик",
	"abyss_zarnitsa": "Гроза Бездны", "champ_zarnitsa": "Небесная гроза — истинный облик",
	"abyss_rassvet": "Закат Бездны", "champ_rassvet": "Полдень — истинный облик",
	"abyss_gatekeeper": "Привратница Бездны", "champ_gatekeeper": "Хранительница Врат — истинный облик",
	"abyss_echo": "Отголосок Бездны", "champ_echo": "Путеводный свет — истинный облик",
	"abyss_seam": "Шов Бездны", "champ_seam": "Сшитая заново — истинный облик",
	"abyss_soldier": "Рейдер Бездны", "champ_soldier": "Маршал — истинный облик",
	"abyss_samurai": "Ронин Бездны", "champ_samurai": "Сёгун солнца — истинный облик",
	"abyss_pivozavr": "Пивозавр Бездны", "champ_pivozavr": "Пивной король — истинный облик",
	"abyss_scribe": "Летописец Бездны", "champ_scribe": "Хранитель Книги — истинный облик",
	"abyss_dj": "DJ Клима: сет из Бездны", "champ_dj": "Золотой диск — истинный облик",
	"abyss_almost": "Почти легенда из Бездны", "champ_almost": "Золотая медаль — истинный облик",
}

# ---------- Каталог ----------
# Все облики легенды: [{id, name, series}]
static func for_hero(i: int) -> Array:
	var ch: Dictionary = Characters.LIST[i]
	var res: Array = []
	if not ch.has("kit") or ch["name"] in Characters.TEST_NAMES:
		return res
	for id in FIRE:
		if FIRE[id][0] == ch["kit"]:
			res.append({"id": id, "name": FIRE[id][1], "series": "fire"})
	for id in ICE:
		if ICE[id][0] == ch["kit"]:
			res.append({"id": id, "name": ICE[id][1], "series": "ice"})
	var ab := "abyss_" + String(ch["kit"])
	var cp := "champ_" + String(ch["kit"])
	res.append({"id": ab, "name": NAMES.get(ab, "%s Бездны" % String(ch["name"]).capitalize()), "series": "abyss"})
	res.append({"id": cp, "name": NAMES.get(cp, "%s — истинный облик" % String(ch["name"]).capitalize()), "series": "champion"})
	return res

static func info(id: String) -> Dictionary:
	if FIRE.has(id):
		return {"id": id, "kit": FIRE[id][0], "name": FIRE[id][1], "series": "fire"}
	if ICE.has(id):
		return {"id": id, "kit": ICE[id][0], "name": ICE[id][1], "series": "ice"}
	if NAMES.has(id):
		return {"id": id, "kit": id.substr(6), "name": NAMES[id], "series": "abyss" if id.begins_with("abyss_") else "champion"}
	if id.begins_with("abyss_"):
		var kit := id.substr(6)
		for ch in Characters.LIST:
			if ch.get("kit", "") == kit:
				return {"id": id, "kit": kit, "name": "%s Бездны" % String(ch["name"]).capitalize(), "series": "abyss"}
	if id.begins_with("champ_"):
		var kit2 := id.substr(6)
		for ch in Characters.LIST:
			if ch.get("kit", "") == kit2:
				return {"id": id, "kit": kit2, "name": "%s — истинный облик" % String(ch["name"]).capitalize(), "series": "champion"}
	return {}

static func how_to_get(id: String) -> String:
	if FIRE.has(id):
		return "Огненный сундук в Лавке"
	if ICE.has(id):
		return "Ледяной сундук в Лавке"
	if id.begins_with("champ_"):
		return "Пройди сложную Арену (103 волны) этой легендой"
	return "Пройди Арену этой легендой"

# Чемпионский облик — за прохождение сложной Арены легендой i
static func give_champion(i: int) -> bool:
	var ch: Dictionary = Characters.LIST[i]
	if not ch.has("kit") or ch["name"] in Characters.TEST_NAMES:
		return false
	return give("champ_" + String(ch["kit"]))

# ---------- Сохранение ----------
static func owned(id: String) -> bool:
	return id in Save.data.get("skins", [])

static func give(id: String) -> bool:
	var a: Array = Save.data.get("skins", [])
	if id in a:
		return false
	a.append(id)
	Save.data["skins"] = a
	Save.save_game()
	return true

static func selected(i: int) -> String:
	var id: String = (Save.data.get("skin_sel", {}) as Dictionary).get(Characters.LIST[i]["name"], "")
	return id if id != "" and owned(id) else ""

static func select(i: int, id: String) -> void:
	var d: Dictionary = Save.data.get("skin_sel", {})
	d[Characters.LIST[i]["name"]] = id
	Save.data["skin_sel"] = d
	Save.save_game()

# Облик «Бездна» — за прохождение Арены легендой i
static func give_abyss(i: int) -> bool:
	var ch: Dictionary = Characters.LIST[i]
	if not ch.has("kit") or ch["name"] in Characters.TEST_NAMES:
		return false
	return give("abyss_" + String(ch["kit"]))

# Сундуки Лавки (огненный, ледяной): случайный облик серии, которого ещё нет ("" — всё собрано)
static func chest_series(ser: String) -> Dictionary:
	return ICE if ser == "ice" else FIRE

static func chest_left(ser: String) -> Array:
	return chest_series(ser).keys().filter(func(id): return not owned(id))

static func open_chest(ser: String) -> String:
	var left := chest_left(ser)
	if left.is_empty():
		return ""
	var id: String = left[randi() % left.size()]
	give(id)
	return id

static func fire_left() -> Array:
	return chest_left("fire")

static func open_fire_chest() -> String:
	return open_chest("fire")

# ---------- Модель ----------
# Описание модели с обликом (для BotRig.custom_spec)
static func spec(rig_kind: String, id: String) -> Dictionary:
	var base: Dictionary = BotRig.SPECS.get(rig_kind, {}).duplicate(true)
	if base.is_empty() or id == "":
		return base
	var ser := series_of(id)
	if ser != "":
		base["spell_glow"] = THEME[ser]["main"]          # свечение колдовства и фонаря — в цвете серии
	if FIRE.has(id):
		if FIRE[id][2].get("_base", false):
			_recolor(base, "fire")                      # общая огненная перекраска, поверх — детали облика
		base.merge(FIRE[id][2], true)
		base.erase("_base")
		for k in base.keys():
			if base[k] == null:
				base.erase(k)                           # облик убирает деталь
		return base
	if ICE.has(id):
		_recolor(base, "ice")                           # вся модель в цветах льда, поверх — детали облика
		base.merge(ICE[id][2], true)
		for k in base.keys():
			if base[k] == null:
				base.erase(k)
		return base
	if ser == "abyss" or ser == "champion":
		_recolor(base, ser)
		if base.has("hat") and not base.get("photo", false):
			base["hat"] = "abyss_horns" if ser == "abyss" else "champ_crown"
	if LOOKS.has(id):
		for k in LOOKS[id]:
			if LOOKS[id][k] == null:
				base.erase(k)                         # облик убирает деталь (Кузнецу плащ не нужен)
			else:
				base[k] = LOOKS[id][k]
	return base

# Перекраска «картой градиента»: тёмное -> тёмный цвет серии, среднее -> главный, светлое -> жаркий.
# Так любой приём, у которого нет своей проработки, всё равно выглядит в цветах облика.
static var _mats := {}

static func grad_material(ser: String) -> ShaderMaterial:
	if _mats.has(ser):
		return _mats[ser]
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nuniform vec4 c_dark : source_color;\nuniform vec4 c_mid : source_color;\nuniform vec4 c_hot : source_color;\nuniform float amount = 0.85;\nvoid fragment() {\n\tvec4 col = COLOR;\n\tfloat l = dot(col.rgb, vec3(0.299, 0.587, 0.114));\n\tvec3 g = l < 0.5 ? mix(c_dark.rgb, c_mid.rgb, l * 2.0) : mix(c_mid.rgb, c_hot.rgb, (l - 0.5) * 2.0);\n\tCOLOR = vec4(mix(col.rgb, g, amount), col.a);\n}\n"
	var m := ShaderMaterial.new()
	m.shader = sh
	var th: Dictionary = THEME[ser]
	m.set_shader_parameter("c_dark", th["dark"])
	m.set_shader_parameter("c_mid", th["main"])
	m.set_shader_parameter("c_hot", th["hot"])
	_mats[ser] = m
	return m

static func paint(n: Node, ser: String) -> void:
	if n is CanvasItem:
		(n as CanvasItem).material = grad_material(ser)
	for c in n.get_children():
		_paint_child(c)

static func _paint_child(n: Node) -> void:
	if n is CanvasItem and not ((n as CanvasItem).material in _mats.values()):
		(n as CanvasItem).material = null                 # свой шейдер части уступает перекраске облика
		(n as CanvasItem).use_parent_material = true
	for c in n.get_children():
		_paint_child(c)

# Кости скелетов и кора древесных моделей в каждой серии
const BONE := {"fire": Color(0.80, 0.68, 0.58), "abyss": Color(0.80, 0.76, 0.90), "champion": Color(0.98, 0.95, 0.86), "ice": Color(0.84, 0.92, 1.0)}
const BARK := {"fire": Color(0.24, 0.14, 0.10), "abyss": Color(0.15, 0.10, 0.20), "champion": Color(0.92, 0.88, 0.80), "ice": Color(0.32, 0.42, 0.55)}

# Общая перекраска модели в цвета серии (облик героя, его питомцы и его другие формы)
static func _recolor(base: Dictionary, ser: String) -> void:
	var th: Dictionary = THEME[ser]
	match ser:
		"fire":
			for k in ["shirt", "pants", "boots"]:
				if base.has(k) and base[k] is Color:
					base[k] = (base[k] as Color).lerp(Color(0.22, 0.11, 0.08), 0.6)
			for k in ["cape", "robe"]:
				if base.has(k) and base[k] is Color:
					base[k] = Color(0.28, 0.11, 0.07)
			base["cape_trim"] = th["main"]
			if base.has("armor_plate"):
				base["armor_plate"] = Color(0.50, 0.20, 0.08)
			for k in ["sode", "wrap", "apron"]:
				if base.has(k) and base[k] is Color:
					base[k] = (base[k] as Color).lerp(th["main"], 0.6)
			for k in ["vein", "gem", "trim", "tattoo", "rope"]:
				if base.has(k):
					base[k] = th["main"]
			base["eye_glow"] = Color(1.0, 0.6, 0.15)
		"abyss":
			var sk: Color = base.get("skin", Color(0.9, 0.75, 0.6))
			if base.get("style", "") != "skeleton" and not base.get("photo", false):
				base["skin"] = sk.lerp(Color(0.72, 0.68, 0.86), 0.45)
			for k in ["shirt", "pants", "boots"]:
				if base.has(k) and base[k] is Color:
					base[k] = (base[k] as Color).lerp(Color(0.09, 0.07, 0.13), 0.75)
			base["cape"] = Color(0.14, 0.08, 0.22)
			base["cape_trim"] = Color(0.72, 0.40, 1.0)
			if base.has("armor_plate"):
				base["armor_plate"] = Color(0.24, 0.17, 0.32)
			if base.has("robe") and base["robe"] is Color:
				base["robe"] = Color(0.12, 0.07, 0.18)
			for k in ["sode", "wrap", "apron"]:
				if base.has(k) and base[k] is Color:
					base[k] = (base[k] as Color).lerp(Color(0.30, 0.14, 0.45), 0.7)
			for k in ["vein", "gem", "trim", "tattoo", "rope"]:
				if base.has(k):
					base[k] = Color(0.80, 0.50, 1.0)
			base["eye_glow"] = Color(0.85, 0.55, 1.0)
		"champion":
			# истинный облик: белое с золотом, свой цвет легенды — в отделке
			var own: Color = base.get("cape", base.get("shirt", Color(0.8, 0.6, 0.3)))
			for k in ["shirt", "pants", "boots"]:
				if base.has(k) and base[k] is Color:
					base[k] = (base[k] as Color).lerp(Color(0.92, 0.90, 0.84), 0.6)
			base["cape"] = own.lerp(Color(1.0, 0.95, 0.85), 0.35)
			base["cape_trim"] = Color(1.0, 0.82, 0.35)
			base["armor_plate"] = Color(0.95, 0.78, 0.32)
			for k in ["sode", "wrap", "apron", "robe"]:
				if base.has(k) and base[k] is Color:
					base[k] = (base[k] as Color).lerp(Color(1.0, 0.85, 0.45), 0.6)
			for k in ["vein", "gem", "trim", "tattoo", "rope"]:
				if base.has(k):
					base[k] = Color(1.0, 0.92, 0.55)
			base["eye_glow"] = Color(1.0, 0.95, 0.70)
		"ice":
			# лёд: одежда — в синеву и иней, кайма — белая, броня — ледяные пластины, глаза светятся голубым
			var sk2: Color = base.get("skin", Color(0.9, 0.75, 0.6))
			if base.get("style", "") != "skeleton" and not base.get("photo", false):
				base["skin"] = sk2.lerp(Color(0.86, 0.92, 1.0), 0.22)
			for k in ["shirt", "pants", "boots"]:
				if base.has(k) and base[k] is Color:
					base[k] = (base[k] as Color).lerp(Color(0.22, 0.34, 0.50), 0.6)
			for k in ["cape", "robe"]:
				if base.has(k) and base[k] is Color:
					base[k] = Color(0.24, 0.40, 0.58)
			base["cape_trim"] = Color(0.88, 0.97, 1.0)
			if base.has("armor_plate"):
				base["armor_plate"] = Color(0.70, 0.84, 0.96)
			for k in ["sode", "wrap", "apron"]:
				if base.has(k) and base[k] is Color:
					base[k] = (base[k] as Color).lerp(Color(0.70, 0.86, 1.0), 0.6)
			for k in ["vein", "gem", "trim", "tattoo", "rope"]:
				if base.has(k):
					base[k] = Color(0.55, 0.88, 1.0)
			base["eye_glow"] = Color(0.60, 0.92, 1.0)
	if base.has("coat"):                         # пальто Главного и его светящийся контур
		base["coat"] = {"fire": Color(0.14, 0.07, 0.05), "abyss": Color(0.06, 0.03, 0.09), "champion": Color(0.95, 0.92, 0.85), "ice": Color(0.12, 0.20, 0.30)}[ser]
		base["coat_glow"] = th["main"] if ser != "champion" else Color(1.0, 0.80, 0.32)
		base["cape"] = base["coat"]
	match base.get("style", ""):
		"skeleton":
			for k in ["skin", "shirt", "pants"]:
				base[k] = BONE[ser]
		"treant":
			for k in ["skin", "shirt", "pants"]:
				base[k] = BARK[ser]
			base["eye_col"] = th["main"] if ser != "champion" else Color(1.0, 0.80, 0.32)

# Питомцы и другие формы героя в облике (скелеты Мортиса, форма Энта у Терновника):
# та же модель, перекрашенная в цвета серии
static func form_spec(kind: String, id: String) -> Dictionary:
	var base: Dictionary = BotRig.SPECS.get(kind, {}).duplicate(true)
	var ser := series_of(id)
	if base.is_empty() or ser == "":
		return base
	_recolor(base, ser)
	return base

# Цвет эффекта героя в облике: светлое (порезы, вспышки) — в «жаркий» цвет серии,
# цветное (пламя, искры) — в главный. Без облика — как было.
static func col(p: Node, c: Color) -> Color:
	if p == null or not is_instance_valid(p) or not p.has_meta("skin"):
		return c
	var s := series_of(String(p.get_meta("skin")))
	if s == "":
		return c
	var lum := c.get_luminance()
	var t: Color = THEME[s]["hot"] if lum > 0.75 else (THEME[s]["dark"] if lum < 0.25 else THEME[s]["main"])
	return Color(t.r, t.g, t.b, c.a)

static func series_of(id: String) -> String:
	if FIRE.has(id):
		return "fire"
	if ICE.has(id):
		return "ice"
	if id.begins_with("abyss_"):
		return "abyss"
	return "champion" if id.begins_with("champ_") else ""

# Оживить модель: светящееся оружие и частицы серии вокруг
static func decorate(rig: Node2D, id: String) -> void:
	var s := series_of(id)
	if s == "" or rig == null:
		return
	if not rig.is_node_ready():
		rig.ready.connect(func(): decorate(rig, id), CONNECT_ONE_SHOT)     # модель ещё не собрана
		return
	if rig.get("kind") in ["totem", "mini_ent"]:
		paint(rig, s)                       # тотем и форма Энта Терновника — целиком в цветах серии
	var w: Variant = rig.get("_weapon")
	var sp: Variant = rig.get("spec")
	var look: String = (sp as Dictionary).get("weapon_look", "") if sp is Dictionary else ""
	if w is Node2D and look != "":
		# проработанное оружие: своя рисовка, на нём живой огонь / тьма / свет
		var wf := WeaponFx.new()
		wf.theme = s
		wf.points = WEAPON_TIPS.get(look, [])
		wf.size = 1.5 if look.ends_with("bow") or look.ends_with("scythe") else (2.2 if look.ends_with("hammer") or look == "void_maul" else 1.2)
		(w as Node2D).add_child(wf)
	elif w is CanvasItem:
		(w as CanvasItem).modulate = {"fire": Color(1.35, 0.85, 0.55), "abyss": Color(0.85, 0.65, 1.3), "champion": Color(1.4, 1.25, 0.8), "ice": Color(0.80, 1.05, 1.35)}[s]
	if s == "champion":
		var ca := ChampionAura.new()
		ca.rig = rig
		rig.add_child(ca)
		return
	var aura := Aura.new()
	aura.theme = s
	aura.rig = rig
	rig.add_child(aura)

# Истинный облик: за спиной — крылья света, над головой медленно вращается ореол,
# модель чуть парит над землёй; на бегу за ней тянется золотой след
class ChampionAura extends Node2D:
	var rig: Node2D
	var _t := 0.0
	var _wings: Array = []
	var _halo: Line2D
	var _trail_t := 0.0
	var _base_y := 0.0

	func _ready() -> void:
		show_behind_parent = true                 # крылья — за моделью, но не за карточкой каталога
		var sz: Vector2 = rig.get("size") if rig.get("size") is Vector2 else Vector2(40, 60)
		_base_y = rig.position.y
		for s in [-1.0, 1.0]:
			var w := Node2D.new()
			w.position = Vector2(0, -sz.y * 0.15)
			add_child(w)
			for k in 4:
				var f := Polygon2D.new()
				var a: Variant = s * (0.6 + k * 0.28)
				var d := Vector2(sin(a), -cos(a))
				var pp := Vector2(-d.y, d.x)
				var ln := sz.y * (0.55 - k * 0.07)
				f.polygon = PackedVector2Array([pp * 2.0, d * ln * 0.6 + pp * 3.0, d * ln, d * ln * 0.6 - pp * 3.0, -pp * 2.0])
				f.color = Color(1.0, 0.92, 0.60, 0.45 - k * 0.07)
				w.add_child(f)
			_wings.append([w, s])
		_halo = Line2D.new()
		var pts := PackedVector2Array()
		for k in 25:
			var a2 := TAU * k / 24.0
			pts.append(Vector2(cos(a2) * sz.x * 0.32, sin(a2) * sz.x * 0.09))
		_halo.points = pts
		_halo.width = 2.0
		_halo.default_color = Color(1.0, 0.90, 0.50, 0.9)
		_halo.position = Vector2(0, -sz.y * 0.56)
		add_child(_halo)

	func _process(delta: float) -> void:
		_t += delta
		for e in _wings:
			(e[0] as Node2D).rotation = float(e[1]) * sin(_t * 2.6) * 0.18
		_halo.rotation = sin(_t * 1.2) * 0.12
		_halo.position.y += sin(_t * 2.0) * 0.05
		rig.position.y = _base_y - 3.0 - sin(_t * 2.2) * 2.0           # парит над землёй
		var bot: Variant = rig.get("bot")
		if bot is Player and absf((bot as Player).velocity.x) > 120.0:
			_trail_t -= delta
			if _trail_t <= 0.0:
				_trail_t = 0.07
				var g := Polygon2D.new()
				var sz2: Vector2 = rig.get("size")
				g.polygon = PackedVector2Array([Vector2(-sz2.x * 0.3, sz2.y * 0.5), Vector2(-sz2.x * 0.25, -sz2.y * 0.4), Vector2(sz2.x * 0.25, -sz2.y * 0.4), Vector2(sz2.x * 0.3, sz2.y * 0.5)])
				g.color = Color(1.0, 0.88, 0.45, 0.35)
				g.global_position = rig.global_position
				g.z_index = -2
				var world: Node = (bot as Player).get_parent()
				world.add_child(g)
				var tw := g.create_tween()
				tw.tween_property(g, "modulate:a", 0.0, 0.35)
				tw.tween_callback(g.queue_free)

# Частицы вокруг модели: угольки (огонь) или клочья тьмы (бездна)
class Aura extends Node2D:
	var theme := "fire"
	var rig: Node2D
	var _t := 0.0
	var _bits: Array = []

	func _ready() -> void:
		z_index = 2
		for k in 7:
			var b := Polygon2D.new()
			b.polygon = Util.circle(1.2 if theme == "fire" else 1.6, 5)
			if theme == "ice":
				# снежинка: маленький крестик со звёздочкой
				b.polygon = PackedVector2Array([Vector2(0, -2.2), Vector2(0.5, -0.5), Vector2(2.2, 0), Vector2(0.5, 0.5),
						Vector2(0, 2.2), Vector2(-0.5, 0.5), Vector2(-2.2, 0), Vector2(-0.5, -0.5)])
			b.color = (Skins.THEME[theme]["hot"] if k % 2 else Skins.THEME[theme]["main"]) as Color
			add_child(b)
			_bits.append([b, randf() * TAU, randf_range(0.6, 1.4)])

	func _process(delta: float) -> void:
		_t += delta
		var sz: Vector2 = rig.get("size") if rig.get("size") is Vector2 else Vector2(40, 60)
		for e in _bits:
			var b: Polygon2D = e[0]
			var ph: float = fmod(_t * float(e[2]) * 0.5 + float(e[1]), 1.0)
			if theme == "fire":
				b.position = Vector2(sin(float(e[1]) * 3.0 + _t) * sz.x * 0.35, sz.y * 0.35 - ph * sz.y * 1.0)
			elif theme == "ice":
				# снег медленно падает вокруг, кружась
				b.position = Vector2(sin(_t * 1.3 + float(e[1]) * 5.0) * sz.x * 0.5, -sz.y * 0.75 + ph * sz.y * 1.2)
				b.rotation = _t * float(e[2])
			else:
				b.position = Vector2(cos(_t * float(e[2]) + float(e[1])) * sz.x * 0.55, sin(_t * float(e[2]) * 1.3 + float(e[1])) * sz.y * 0.4)
			b.modulate.a = 1.0 - ph if theme == "fire" else (minf(1.0, (1.0 - ph) * 3.0) if theme == "ice" else 0.5 + 0.5 * sin(_t * 3.0 + float(e[1])))

# ---------- Вид способностей ----------
# Где на проработанном оружии горит огонь / клубится тьма / мерцает свет (от точки хвата)
const WEAPON_TIPS := {
	"flame_bow": [Vector2(-1, -13), Vector2(-1, 12)], "void_bow": [Vector2(-2, -13), Vector2(-2, 12)],
	"sun_bow": [Vector2(1, -13), Vector2(1, 12)],
	"lava_hammer": [Vector2(16, -5), Vector2(19.5, 0), Vector2(16, 5)], "void_maul": [Vector2(16, -5.5), Vector2(16, 5.5)],
	"sun_hammer": [Vector2(16, 0)],
	"ember_kama": [Vector2(12, -10), Vector2(11, -4)], "void_kama": [Vector2(12, -10)], "sun_kama": [Vector2(12, -10)],
	"ember_branch": [Vector2(8, -2), Vector2(11, 1), Vector2(5, -4)], "void_branch": [Vector2(11, -3), Vector2(8, 1)],
	"bloom_branch": [Vector2(8, -2), Vector2(11, 1)],
	"pyre_scythe": [Vector2(9, -7), Vector2(5, -3), Vector2(1, 0)], "void_scythe": [Vector2(9, -7), Vector2(4, -3)],
	"sun_scythe": [Vector2(9, -7)],
	"ember_prism_staff": [Vector2(16, -3), Vector2(16, 1)], "void_prism_staff": [Vector2(16, -1)], "sun_prism_staff": [Vector2(16, -1)],
	"ember_spear": [Vector2(9, 0), Vector2(-8, 0)], "void_spear": [Vector2(9, 0)], "sun_spear": [Vector2(9, 0)],
	"ember_lantern": [Vector2(10, 3)], "void_lantern": [Vector2(10, 3)], "lotus_staff": [Vector2(10, 3)],
	"war_fan": [Vector2(7.5, 0), Vector2(6, -4), Vector2(6, 4)], "dawn_blade": [Vector2(15, 1.5), Vector2(26, 0)],
	"key_staff": [Vector2(10, -0.5)], "echo_lantern": [Vector2(10.3, 1)], "needle_spear": [Vector2(23, 0), Vector2(12, 3)],
	"flame_rifle": [Vector2(14, -1)], "void_rifle": [Vector2(9, -1)], "sun_rifle": [Vector2(14, -1)],
	"ember_katana": [Vector2(9, -1.5), Vector2(17, -1.5), Vector2(24, -1.5)], "void_katana": [Vector2(14, -1), Vector2(23, -1)],
	"sun_katana": [Vector2(24, -1.5)],
	"molotov": [Vector2(10, -1)], "void_flask": [Vector2(10, -0.5)], "gold_bottle": [Vector2(10, -0.5)],
	"quill": [Vector2(11, -3), Vector2(-10, 0)],
	# ледяная серия
	"ice_bow": [Vector2(-1, -13), Vector2(-1, 12), Vector2(2, 0)], "glacier_hammer": [Vector2(16, -5), Vector2(19.5, 0), Vector2(16, 5)],
	"ice_katana": [Vector2(12, -1), Vector2(19, -1), Vector2(25, -1)], "frost_branch": [Vector2(8, -2), Vector2(11, 1), Vector2(5, -4)],
	"frost_scythe": [Vector2(9, -7), Vector2(5, -3)], "ice_prism_staff": [Vector2(16, -3), Vector2(16, 1)],
	"frost_lantern": [Vector2(10, 3)], "frost_rifle": [Vector2(14, -1), Vector2(5, 2)], "ice_bottle": [Vector2(10, -0.5), Vector2(4, -1)],
	"ice_kama": [Vector2(12, -10), Vector2(11, -4)], "ice_spear": [Vector2(9, 0), Vector2(-8, 0)],
}

# Стрелы обликов: [древко, наконечник, оперение, обмотка]
const ARROW := {
	"fire": [Color(0.22, 0.13, 0.10), Color(1.0, 0.78, 0.32), Color(1.0, 0.42, 0.10), Color(1.0, 0.50, 0.12)],
	"abyss": [Color(0.13, 0.09, 0.18), Color(0.85, 0.55, 1.0), Color(0.45, 0.20, 0.72), Color(0.72, 0.40, 1.0)],
	"champion": [Color(0.98, 0.94, 0.82), Color(1.0, 1.0, 0.92), Color(1.0, 0.82, 0.35), Color(1.0, 0.78, 0.30)],
	"ice": [Color(0.70, 0.84, 0.96), Color(0.95, 1.0, 1.0), Color(0.45, 0.80, 1.0), Color(0.30, 0.55, 0.85)],
}

# Узел у героя с обликом: перерисовывает его снаряды, капканы, наковальни, молоты,
# даёт вспышки приёмов и ульты в цветах серии
class SkinFx extends Node:
	var p: Player
	var theme := "fire"
	var _seen := {}
	var _t := 0.0
	var _ghost_t := 0.0
	var _was_leap := false
	var _sky: Variant = null
	var _sky_n := 0
	var _anvils: Array = []
	var _painted: Array = []
	var _paint_t := 0.0

	func _physics_process(delta: float) -> void:
		if not is_instance_valid(p) or not p.is_alive() or not p.is_inside_tree():
			return
		_t += delta
		var world := p.get_parent()
		var th: Dictionary = Skins.THEME[theme]
		for n in world.get_children():
			if not (n is Node2D or n is FallingAnvil) or n is Player or _seen.has(n.get_instance_id()):
				continue
			var own: Variant = null
			for k in ["shooter", "owner_p", "attacker", "p"]:
				if k in n:
					own = n.get(k)
					break
			if own != p:
				continue
			_seen[n.get_instance_id()] = true
			if n is Arrow:
				_dress_arrow(n, th)
			elif n is BearTrap:
				_dress_trap(n, th)
			elif n is FallingAnvil:
				_dress_anvil(n, th)
			elif n is ThrownHammer:
				_dress_hammer(n, th)
			elif n is FireZone:
				(n as Node2D).modulate = {"fire": Color(1.2, 1.0, 1.0), "abyss": Color(0.75, 0.45, 1.4), "champion": Color(1.3, 1.15, 0.7), "ice": Color(0.55, 0.95, 1.5)}[theme]
			elif n is RootSpike:
				_dress_spike(n, th)
			elif n is GhostSword:
				_dress_sword(n, th)
			elif n is BigShuriken:
				_dress(n, th)
			elif n is SlashWave:
				_dress_wave(n, th)
			elif n is AirStrike:
				_dress_strike(n, th)
			elif n is PivozavrKit.BeerBottle or n is PivozavrKit.BeerPuddle or n is PivozavrKit.BurpCloud or n is PivozavrKit.CellarKid:
				_dress_pivo(n, th)
			elif n is Spear:
				adopt(n)                                  # копья, колючки, кунаи, комья тины — целиком в цвета серии
			elif n is Grenade or n is FallingBomb or n is Shuriken:
				_dress(n, th)
			elif "shooter" in n:
				_dress(n, th, p.kit is PivozavrKit)       # крышки Пивозавра свой цвет не теряют: цвет — это их эффект
			else:
				adopt(n)                                  # прочие приёмы — целиком в цвета серии
		if _seen.size() > 400:
			_seen.clear()
		_anvils = _anvils.filter(func(d): return is_instance_valid(d))
		_painted = _painted.filter(func(d): return is_instance_valid(d))
		_paint_t -= delta
		if _paint_t <= 0.0:
			_paint_t = 0.25
			for d in _painted:
				Skins._paint_child(d)                     # новые части приёма тоже перекрашиваем
				(d as CanvasItem).material = Skins.grad_material(theme)
		var tint: Color = {"fire": Color(1.5, 0.75, 0.45), "abyss": Color(0.62, 0.45, 1.05), "champion": Color(1.45, 1.25, 0.70), "ice": Color(0.85, 1.15, 1.45)}[theme]
		for d in _anvils:
			(d as Node2D).modulate = Color(tint, (d as Node2D).modulate.a)
		_hero_tick(delta, world, th)
		# на бегу — угольки (огонь), клочья тьмы (бездна) или искры света из-под ног
		if absf(p.velocity.x) > 80.0 and randf() < 0.25:
			Fx.sparks(world, p.global_position + Vector2(0, p.body_size.y * 0.4), th["main"], 1, 70.0, 3.0, true)

	# Приметы приёмов конкретной легенды
	func _hero_tick(delta: float, world: Node, th: Dictionary) -> void:
		var kit: Variant = p.kit
		if kit == null:
			return
		# рывки (перекат Охотницы, прыжок Кузнеца) оставляют след-силуэты
		if p._forced_time > 0.0 and absf(p.velocity.x) > 200.0:
			_ghost_t -= delta
			if _ghost_t <= 0.0:
				_ghost_t = 0.04
				_afterimage(world, th)
		var hl: Variant = kit.get("_hook_line")
		if is_instance_valid(hl) and hl is Line2D:
			(hl as Line2D).default_color = th["main"]
			(hl as Line2D).width = 3.0 + sin(_t * 30.0)
			if randf() < 0.4 and (hl as Line2D).points.size() > 1:
				var pts := (hl as Line2D).points
				Fx.sparks(world, pts[0].lerp(pts[pts.size() - 1], randf()), th["hot"], 1, 60.0, 3.0)
		for key in ["_vine", "_arrow", "_tongue"]:      # лиана и прицел Терновника, язык Квака
			var v: Variant = kit.get(key)
			if is_instance_valid(v) and v is Line2D:
				(v as Line2D).default_color = Color(th["main"] if theme != "champion" else Color(1.0, 0.80, 0.32), 1.0)
			elif is_instance_valid(v) and v is Polygon2D:
				(v as Polygon2D).color = Color(th["main"], (v as Polygon2D).color.a)
		var ef: Variant = kit.get("_ench_fx")
		if is_instance_valid(ef) and ef is Polygon2D:
			(ef as Polygon2D).color = Color(th["main"], (ef as Polygon2D).color.a)
		var au: Variant = kit.get("_aura")
		if theme != "fire" and is_instance_valid(au) and au is CanvasItem:
			# жар «Кузни» в цветах облика: лиловый (бездна) или золотисто-белый (чемпион)
			(au as CanvasItem).modulate = Color(0.55, 0.40, 1.3) if theme == "abyss" else Color(1.2, 1.15, 0.85)
		var leap: Variant = kit.get("_leap_t")
		var in_leap: bool = leap is float and float(leap) > 0.0
		if _was_leap and not in_leap:
			_burst(world, th, p.global_position + Vector2(0, p.body_size.y / 2), 120.0)   # приземление Кузнеца
		_was_leap = in_leap

	func _afterimage(world: Node, th: Dictionary) -> void:
		var g := Polygon2D.new()
		var bs := p.body_size
		g.polygon = PackedVector2Array([Vector2(-bs.x * 0.3, bs.y * 0.5), Vector2(-bs.x * 0.35, -bs.y * 0.2), Vector2(0, -bs.y * 0.5),
				Vector2(bs.x * 0.35, -bs.y * 0.2), Vector2(bs.x * 0.3, bs.y * 0.5)])
		g.color = Color(th["main"], 0.35)
		g.global_position = p.global_position
		g.z_index = -1
		world.add_child(g)
		var tw := g.create_tween()
		tw.tween_property(g, "modulate:a", 0.0, 0.25)
		tw.tween_callback(g.queue_free)

	# Удар о землю в цветах серии
	func _burst(world: Node, th: Dictionary, at: Vector2, r: float) -> void:
		Fx.ring(world, at, r, Color(th["main"], 0.9), 0.4, 6.0, 0.3)
		Fx.sparks(world, at, th["hot"], 14, 260.0, 4.0, true)
		if theme == "abyss":
			Fx.cracks(world, at, Color(0.45, 0.20, 0.70), r)
		elif theme == "fire":
			Fx.cracks(world, at, Color(1.0, 0.45, 0.12), r)
		elif theme == "ice":
			Fx.cracks(world, at, Color(0.70, 0.92, 1.0), r)        # лёд трескается
			Skins.icicles(world, at, r, 5)
		else:
			for k in 5:
				var beam := Polygon2D.new()
				var x := (k - 2) * r * 0.35
				beam.polygon = PackedVector2Array([Vector2(x - 4, 0), Vector2(x - 1, -r * 1.6), Vector2(x + 1, -r * 1.6), Vector2(x + 4, 0)])
				beam.color = Color(th["hot"], 0.5)
				beam.position = at
				world.add_child(beam)
				var tw := beam.create_tween()
				tw.tween_property(beam, "modulate:a", 0.0, 0.45)
				tw.tween_callback(beam.queue_free)

	func _dress(n: Node2D, th: Dictionary, keep_color := false) -> void:
		var glow := Polygon2D.new()
		glow.polygon = Util.circle(9.0, 10)
		glow.color = Color(th["main"], 0.55 if not keep_color else 0.35)
		glow.z_index = -1
		n.add_child(glow)
		var tr: Variant = n.get("_trail")
		if tr is Line2D:
			(tr as Line2D).default_color = Color(th["main"], 0.55)
		if not keep_color:
			var core := Polygon2D.new()
			core.polygon = Util.circle(3.5, 8)
			core.color = th["hot"] if theme == "fire" else th["dark"]
			n.add_child(core)
			var cr: Variant = n.get("color")
			if cr is Color:
				n.set("color", (cr as Color).lerp(th["main"], 0.6))
			var vis: Variant = n.get("_vis")
			if vis is Polygon2D:
				(vis as Polygon2D).color = (vis as Polygon2D).color.lerp(th["main"], 0.6)
			Skins.paint(n, theme)                         # и весь снаряд — в цвета серии
		var em := Emitter.new()
		em.col = th["main"]
		em.hot = th["hot"]
		n.add_child(em)

	# Стрела облика: своё древко, наконечник и оперение, на острие — огонь, осколок бездны или свет
	func _dress_arrow(a: Arrow, th: Dictionary) -> void:
		var vis: Variant = a.get("_vis")
		if not (vis is Node2D) or a.mode in ["knife", "knife_bomb"]:
			_dress(a, th)
			return
		var big := 2.6 if a.mode == "giant" else 1.0
		var pal: Array = Skins.ARROW[theme]
		var polys: Array = (vis as Node2D).get_children().filter(func(c): return c is Polygon2D)
		if polys.size() >= 7:
			var cols := [pal[0], pal[1], pal[2], (pal[0] as Color).lightened(0.25), (pal[2] as Color).darkened(0.3), (pal[1] as Color).lightened(0.25), pal[3]]
			for k in 7:
				(polys[k] as Polygon2D).color = cols[k]
		match theme:
			"fire":
				var wf := WeaponFx.new()
				wf.theme = "fire"
				wf.size = 3.0 * big
				wf.points = [Vector2(10, 0) * big, Vector2(-16, 0) * big]
				(vis as Node2D).add_child(wf)
			"ice":
				# наконечник — ледяной кристалл, за стрелой тянется иней
				var cr := Polygon2D.new()
				cr.polygon = PackedVector2Array([Vector2(8, 0), Vector2(13, -3.5), Vector2(21, 0), Vector2(13, 3.5)])
				for i in cr.polygon.size():
					cr.polygon[i] *= big
				cr.color = Color(0.80, 0.95, 1.0, 0.95)
				(vis as Node2D).add_child(cr)
				var gl2 := Polygon2D.new()
				gl2.polygon = PackedVector2Array([Vector2(13, -1.5), Vector2(19, 0), Vector2(13, 1.5)])
				for i in gl2.polygon.size():
					gl2.polygon[i] *= big
				gl2.color = Color(1, 1, 1)
				(vis as Node2D).add_child(gl2)
				var wf2 := WeaponFx.new()
				wf2.theme = "ice"
				wf2.size = 2.4 * big
				wf2.points = [Vector2(-14, 0) * big]
				(vis as Node2D).add_child(wf2)
			"abyss":
				var sh := Polygon2D.new()
				sh.polygon = PackedVector2Array([Vector2(7, 0), Vector2(13, -5), Vector2(22, 0), Vector2(13, 5)])
				for i in sh.polygon.size():
					sh.polygon[i] *= big
				sh.color = Color(0.85, 0.55, 1.0)
				(vis as Node2D).add_child(sh)
				var dk := Polygon2D.new()
				dk.polygon = Util.circle(7.0 * big, 10)
				dk.color = Color(0.10, 0.04, 0.16, 0.55)
				dk.position = Vector2(-14, 0) * big
				dk.z_index = -1
				(vis as Node2D).add_child(dk)
			"champion":
				var streak := Polygon2D.new()
				streak.polygon = PackedVector2Array([Vector2(-60, -1.5), Vector2(12, -3.5), Vector2(18, 0), Vector2(12, 3.5), Vector2(-60, 1.5)])
				for i in streak.polygon.size():
					streak.polygon[i] *= big
				streak.color = Color(1.0, 0.92, 0.55, 0.35)
				streak.z_index = -1
				(vis as Node2D).add_child(streak)
				var gl := Polygon2D.new()
				gl.polygon = Util.circle(7.0 * big, 12)
				gl.color = Color(1.0, 0.95, 0.70, 0.55)
				gl.position = Vector2(14, 0) * big
				(vis as Node2D).add_child(gl)
		var tr: Variant = a.get("_trail")
		if tr is Line2D:
			(tr as Line2D).default_color = Color(th["main"], 0.55)
		var em := Emitter.new()
		em.col = th["main"]
		em.hot = th["hot"]
		a.add_child(em)
		# ливень ульты: в небе над целью раскрывается знак серии
		if a.mode == "rain" and not a.has_meta("sky") and is_instance_valid(_sky):
			_sky_n += 1                                   # знак плывёт к середине ливня
			(_sky as Node2D).position.x = lerpf((_sky as Node2D).position.x, a.global_position.x + 60.0, 1.0 / _sky_n)
		elif a.mode == "rain" and not a.has_meta("sky"):
			_sky_n = 1
			var sg := Sigil.new()
			sg.theme = theme
			sg.radius = 120.0
			sg.life = 1.8
			sg.position = a.global_position + Vector2(60, -30)
			p.get_parent().add_child(sg)
			_sky = sg

	# Капкан облика: раскалённые челюсти в огне / обсидиан над разломом / золото в круге света
	func _dress_trap(tr: BearTrap, th: Dictionary) -> void:
		var polys: Array = tr.get_children().filter(func(c): return c is Polygon2D)
		var look: Array = {"fire": [Color(0.20, 0.12, 0.10), Color(1.0, 0.75, 0.30), Color(0.95, 0.45, 0.18)],
				"abyss": [Color(0.10, 0.07, 0.14), Color(0.85, 0.55, 1.0), Color(0.42, 0.24, 0.62)],
				"champion": [Color(0.95, 0.92, 0.85), Color(1.0, 1.0, 0.90), Color(1.0, 0.82, 0.40)],
				"ice": [Color(0.40, 0.55, 0.72), Color(0.92, 0.99, 1.0), Color(0.60, 0.86, 1.0)]}[theme]
		if polys.size() >= 2:
			(polys[0] as Polygon2D).color = look[0]
			(polys[1] as Polygon2D).color = look[1]
		for j in [tr.get("_jaw_l"), tr.get("_jaw_r")]:
			if j is Polygon2D:
				(j as Polygon2D).color = look[2]
		var under := Polygon2D.new()
		under.polygon = Util.circle(26.0, 16)
		under.scale = Vector2(1.0, 0.3)
		under.color = Color(th["main"], 0.35) if theme != "abyss" else Color(0.06, 0.02, 0.10, 0.85)
		under.z_index = -1
		tr.add_child(under)
		var wf := WeaponFx.new()
		wf.theme = theme
		wf.size = 4.0
		wf.points = [Vector2(-12, -6), Vector2(12, -6)] if theme != "abyss" else [Vector2(-18, 0), Vector2(18, 0)]
		tr.add_child(wf)

	# Наковальня облика: раскалённая, обсидиановая или золотая, с хвостом серии
	func _dress_anvil(fa: FallingAnvil, th: Dictionary) -> void:
		var d: Variant = fa.get("d")
		if not is_instance_valid(d) or not (d is Node2D):
			return
		_anvils.append(d)                                 # оттенок держим каждый кадр (стена сбрасывает его при приземлении)
		var em := Emitter.new()
		em.col = th["main"]
		em.hot = th["hot"]
		(d as Node2D).add_child(em)
		var wf := WeaponFx.new()
		wf.theme = theme
		wf.size = 7.0
		var dw: float = float(d.get("cols")) * float(d.get("cell")) / 2.0
		var dh: float = float(d.get("rows")) * float(d.get("cell")) / 2.0
		wf.points = [Vector2(-dw, -dh), Vector2(dw, -dh), Vector2(0, -dh)]
		(d as Node2D).add_child(wf)

	# Приём без своей проработки (или узел, который отдал кит): карта градиента серии и искры
	func adopt(n: Node) -> void:
		if not (n is CanvasItem) or n in _painted:
			return
		Skins.paint(n, theme)
		_painted.append(n)
		var th: Dictionary = Skins.THEME[theme]
		var em := Emitter.new()
		em.col = th["main"]
		em.hot = th["hot"]
		n.add_child(em)

	# Корни / шипы из земли: в цветах облика, с хвостом искр
	func _dress_spike(r: RootSpike, th: Dictionary) -> void:
		var sp: Variant = r.get("_spikes")
		if sp is Polygon2D:
			(sp as Polygon2D).color = {"fire": Color(0.34, 0.14, 0.08), "abyss": Color(0.22, 0.10, 0.32), "champion": Color(0.98, 0.88, 0.58), "ice": Color(0.70, 0.90, 1.0)}[theme]
		var wr: Variant = r.get("_warn")
		if wr is ColorRect:
			(wr as ColorRect).color = Color(th["main"], (wr as ColorRect).color.a)
		var em := Emitter.new()
		em.col = th["main"]
		em.hot = th["hot"]
		r.add_child(em)

	# Меч Короля (ульта Мортиса): клинок в цветах облика
	func _dress_sword(g: GhostSword, th: Dictionary) -> void:
		var polys: Array = g.get_children().filter(func(c): return c is Polygon2D)
		for k in polys.size():
			var c: Polygon2D = polys[k]
			c.color = Color(th["main"] if k == 0 else th["hot"], c.color.a)
		var em := Emitter.new()
		em.col = th["main"]
		em.hot = th["hot"]
		g.add_child(em)

	# Волна клинка Самурая: в цвете серии и с хвостом искр
	func _dress_wave(w: SlashWave, th: Dictionary) -> void:
		var poly: Variant = w.get("_poly")
		if poly is Polygon2D:
			(poly as Polygon2D).color = Color(th["hot"] if theme != "abyss" else th["main"], (poly as Polygon2D).color.a)
		var em := Emitter.new()
		em.col = th["main"]
		em.hot = th["hot"]
		w.add_child(em)

	# Авиаудар Солдата: метка и самолёт в цветах облика, за самолётом — огонь / тьма / свет
	func _dress_strike(st: AirStrike, th: Dictionary) -> void:
		var mk: Variant = st.get("_mark")
		if mk is Node2D:
			for c in (mk as Node2D).get_children():
				if c is Line2D:
					(c as Line2D).default_color = Color(th["main"], (c as Line2D).default_color.a)
				elif c is Polygon2D:
					(c as Polygon2D).color = Color(th["main"], (c as Polygon2D).color.a)
		var pl: Variant = st.get("_plane")
		if pl is Node2D:
			var look: Array = {"fire": [Color(0.22, 0.12, 0.10), Color(0.42, 0.13, 0.06), Color(1.0, 0.60, 0.20), Color(1.0, 0.80, 0.30)],
					"abyss": [Color(0.12, 0.08, 0.17), Color(0.22, 0.11, 0.32), Color(0.85, 0.55, 1.0), Color(0.72, 0.40, 1.0)],
					"champion": [Color(0.96, 0.93, 0.86), Color(1.0, 0.82, 0.38), Color(1.0, 1.0, 0.90), Color(1.0, 0.70, 0.20)],
					"ice": [Color(0.80, 0.86, 0.92), Color(0.40, 0.58, 0.76), Color(0.85, 0.97, 1.0), Color(0.45, 0.82, 1.0)]}[theme]
			var polys: Array = (pl as Node2D).get_children().filter(func(c): return c is Polygon2D)
			for k in polys.size():
				(polys[k] as Polygon2D).color = look[0] if k == 0 else (look[2] if k == 4 else (look[3] if k == 5 else look[1]))
			var em := Emitter.new()
			em.col = th["main"]
			em.hot = th["hot"]
			(pl as Node2D).add_child(em)

	# Пивозавр: бутылка, лужа, облако и дети из подвала — в цветах облика
	func _dress_pivo(n: Node2D, th: Dictionary) -> void:
		if n is PivozavrKit.BeerBottle:
			var polys: Array = n.get_children().filter(func(c): return c is Polygon2D)
			var glass: Color = {"fire": Color(0.62, 0.32, 0.10), "abyss": Color(0.10, 0.07, 0.14), "champion": Color(0.95, 0.75, 0.28), "ice": Color(0.55, 0.78, 0.92)}[theme]
			if polys.size() >= 3:
				(polys[0] as Polygon2D).color = glass
				(polys[2] as Polygon2D).color = th["main"]
			var wf := WeaponFx.new()
			wf.theme = theme
			wf.size = 4.0
			wf.points = [Vector2(0, -13)]
			n.add_child(wf)
		elif n is PivozavrKit.BeerPuddle:
			var polys2: Array = n.get_children().filter(func(c): return c is Polygon2D)
			var pool: Color = {"fire": Color(1.0, 0.42, 0.10, 0.85), "abyss": Color(0.22, 0.10, 0.34, 0.9), "champion": Color(1.0, 0.85, 0.40, 0.9), "ice": Color(0.70, 0.90, 1.0, 0.9)}[theme]
			if polys2.size() >= 2:
				(polys2[0] as Polygon2D).color = pool
				(polys2[1] as Polygon2D).color = Color(th["hot"], 0.8)
			var hw: float = float(n.get("width")) / 2.0
			var wf2 := WeaponFx.new()
			wf2.theme = theme
			wf2.size = 5.0
			wf2.points = [Vector2(-hw * 0.5, -4), Vector2(0, -6), Vector2(hw * 0.5, -4)]
			n.add_child(wf2)
		elif n is PivozavrKit.BurpCloud:
			var gas: Color = {"fire": Color(0.85, 0.42, 0.16), "abyss": Color(0.42, 0.20, 0.68), "champion": Color(1.0, 0.86, 0.48), "ice": Color(0.78, 0.92, 1.0)}[theme]
			for c in n.get_children():
				if c is Polygon2D:
					(c as Polygon2D).color = Color(gas, (c as Polygon2D).color.a)
			var em3 := Emitter.new()
			em3.col = th["main"]
			em3.hot = th["hot"]
			n.add_child(em3)
		else:
			var glow := Polygon2D.new()
			glow.polygon = Util.circle(16.0, 12)
			glow.scale = Vector2(1.0, 0.35)
			glow.position = Vector2(0, 14)
			glow.color = Color(th["main"], 0.5)
			glow.z_index = -1
			n.add_child(glow)
			var em2 := Emitter.new()
			em2.col = th["main"]
			em2.hot = th["hot"]
			n.add_child(em2)

	# Брошенный молот облика: своя рисовка головы и хвост серии
	func _dress_hammer(h: ThrownHammer, th: Dictionary) -> void:
		var vis: Variant = h.get("_vis")
		if vis is Node2D:
			var polys: Array = (vis as Node2D).get_children().filter(func(c): return c is Polygon2D)
			var look: Array = {"fire": [Color(0.20, 0.13, 0.10), Color(0.18, 0.15, 0.15), Color(1.0, 0.60, 0.20)],
					"abyss": [Color(0.14, 0.10, 0.20), Color(0.12, 0.08, 0.17), Color(0.75, 0.45, 1.0)],
					"champion": [Color(0.95, 0.92, 0.85), Color(0.98, 0.86, 0.48), Color(1.0, 0.98, 0.85)],
					"ice": [Color(0.30, 0.40, 0.52), Color(0.55, 0.80, 0.96), Color(0.92, 0.99, 1.0)]}[theme]
			for k in mini(3, polys.size()):
				(polys[k] as Polygon2D).color = look[k]
			var wf := WeaponFx.new()
			wf.theme = theme
			wf.size = 5.0
			wf.points = [Vector2(12, -11), Vector2(20, 0), Vector2(12, 11)]
			(vis as Node2D).add_child(wf)
		var em := Emitter.new()
		em.col = th["main"]
		em.hot = th["hot"]
		h.add_child(em)

	# Приём сработал: вспышка в цветах серии
	func cast() -> void:
		var world := p.get_parent()
		var th: Dictionary = Skins.THEME[theme]
		var c := p.hurt_center()
		Fx.ring(world, c, 70.0, Color(th["main"], 0.9), 0.35, 5.0)
		Fx.sparks(world, c, th["main"], 10, 220.0, 4.0)
		if theme == "abyss":
			var s := RiftAbilities.Slit.new()
			s.position = c + Vector2(-p.facing * 30.0, p.body_size.y * 0.5)
			s.height = 70.0
			s.wide = 0.8
			s.life = 0.6
			world.add_child(s)
		elif theme == "fire":
			Fx.flame_ring(p, 46.0, 0.5)
		elif theme == "ice":
			Skins.icicles(world, p.global_position + Vector2(0, p.body_size.y / 2), 46.0, 3)
			Fx.sparks(world, c, th["hot"], 6, 120.0, 3.0, true)

	func ult() -> void:
		var world := p.get_parent()
		var th: Dictionary = Skins.THEME[theme]
		var c := p.hurt_center()
		Util.flash(world, c, 220.0, Color(th["main"], 0.8))
		Fx.ring(world, c, 260.0, Color(th["hot"], 0.95), 0.6, 9.0)
		Fx.sparks(world, c, th["main"], 30, 360.0, 5.0)
		if p.kit is PivozavrKit:
			# «Хранитель подвала»: вокруг люка за спиной — знак серии
			var sg2 := Sigil.new()
			sg2.theme = theme
			sg2.radius = 90.0
			sg2.flat = 0.3
			sg2.life = 3.0
			sg2.position = p.global_position + Vector2(-p.facing * 50.0, p.body_size.y / 2)
			world.add_child(sg2)
		if p.kit and p.kit.hero == "smith":
			# «Кузня»: под Кузнецом раскрывается знак серии и держится, пока он куёт
			var sg := Sigil.new()
			sg.theme = theme
			sg.radius = 150.0
			sg.flat = 0.3
			sg.life = 3.2
			sg.follow = p
			sg.position = p.global_position + Vector2(0, p.body_size.y / 2)
			world.add_child(sg)
		if theme == "abyss":
			var s := RiftAbilities.Slit.new()
			s.position = c + Vector2(0, p.body_size.y * 0.5)
			s.height = 200.0
			s.wide = 2.0
			s.life = 1.4
			world.add_child(s)
			Fx.bolt(world, c + Vector2(-120, -260), c, th["main"])
			Fx.bolt(world, c + Vector2(130, -240), c, th["main"])
		elif theme == "fire":
			Fx.flame_ring(p, 90.0, 1.2)
			for k in 8:
				Fx.sparks(world, c + Vector2.from_angle(TAU * k / 8.0) * 80.0, th["hot"], 3, 200.0, 4.0, true)
		elif theme == "ice":
			# морозный взрыв: кольцо ледяных шипов из земли и снежинка-знак под ногами
			Skins.icicles(world, p.global_position + Vector2(0, p.body_size.y / 2), 140.0, 9)
			var sg3 := Sigil.new()
			sg3.theme = "ice"
			sg3.radius = 120.0
			sg3.flat = 0.3
			sg3.life = 1.6
			sg3.position = p.global_position + Vector2(0, p.body_size.y / 2)
			world.add_child(sg3)
		else:
			for k in 8:
				Fx.sparks(world, c + Vector2.from_angle(TAU * k / 8.0) * 90.0, th["hot"], 3, 160.0, 4.0)

# Знак серии (в небе над ливнем стрел, на земле под «Кузней»): огненное кольцо в языках
# пламени, разлом бездны с осколками или солнечный диск с лучами
class Sigil extends Node2D:
	var theme := "fire"
	var radius := 120.0
	var flat := 0.45
	var life := 2.0
	var follow: Variant = null
	var _t := 0.0
	var _spokes: Array = []
	var _rim: Line2D

	func _ready() -> void:
		z_index = 5
		var th: Dictionary = Skins.THEME[theme]
		var fill := Polygon2D.new()
		fill.polygon = Util.circle(radius, 28)
		fill.scale = Vector2(1.0, flat)
		fill.color = {"fire": Color(1.0, 0.45, 0.12, 0.22), "abyss": Color(0.05, 0.02, 0.08, 0.85), "champion": Color(1.0, 0.90, 0.55, 0.30), "ice": Color(0.70, 0.90, 1.0, 0.25)}[theme]
		add_child(fill)
		_rim = Line2D.new()
		var pts := PackedVector2Array()
		for k in 33:
			var a := TAU * k / 32.0
			pts.append(Vector2(cos(a) * radius, sin(a) * radius * flat))
		_rim.points = pts
		_rim.width = 5.0
		_rim.default_color = th["main"]
		add_child(_rim)
		for k in 10:
			var sp := Polygon2D.new()
			match theme:
				"fire":
					sp.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(0, -26), Vector2(7, 0)])
					sp.color = Color(1.0, 0.55 + 0.3 * (k % 2), 0.15)
				"abyss":
					sp.polygon = PackedVector2Array([Vector2(0, -12), Vector2(5, 0), Vector2(0, 12), Vector2(-5, 0)])
					sp.color = Color(0.80, 0.50, 1.0)
				"ice":
					# луч снежинки: длинный кристалл с двумя веточками
					sp.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(-2, -14), Vector2(-7, -20), Vector2(-5, -22), Vector2(0, -17),
							Vector2(5, -22), Vector2(7, -20), Vector2(2, -14), Vector2(2, 0)])
					sp.color = Color(0.85, 0.97, 1.0, 0.9) if k % 2 == 0 else Color(0.55, 0.85, 1.0, 0.9)
				_:
					sp.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(0, -38), Vector2(3, 0)])
					sp.color = Color(1.0, 0.95, 0.70, 0.8)
			add_child(sp)
			_spokes.append(sp)
		modulate.a = 0.0

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		if follow is Player and is_instance_valid(follow):
			position = (follow as Player).global_position + Vector2(0, (follow as Player).body_size.y / 2)
		modulate.a = minf(1.0, minf(_t * 4.0, life * 2.5))
		for k in _spokes.size():
			var a := TAU * k / _spokes.size() + _t * (0.8 if theme != "abyss" else -1.4)
			var sp: Polygon2D = _spokes[k]
			var r := radius * (1.0 if theme != "abyss" else 0.8 + 0.1 * sin(_t * 5.0 + k))
			sp.position = Vector2(cos(a) * r, sin(a) * r * flat)
			match theme:
				"fire":
					sp.scale = Vector2(1.0, 0.7 + 0.4 * sin(_t * 14.0 + k * 1.7))
				"abyss":
					sp.rotation = _t * 3.0 + k
				"ice":
					sp.rotation = a + PI / 2
					sp.scale = Vector2.ONE * (0.85 + 0.15 * sin(_t * 4.0 + k))
				_:
					sp.rotation = a + PI / 2
		_rim.width = 5.0 + 2.0 * sin(_t * 8.0)
		if life <= 0.0:
			queue_free()

# Живой огонь / клубы тьмы / мерцание света на оружии и предметах облика
class WeaponFx extends Node2D:
	var theme := "fire"
	var points: Array = []
	var size := 2.0
	var _bits: Array = []
	var _t := 0.0

	func _ready() -> void:
		for i in points.size():
			var pt: Vector2 = points[i]
			match theme:
				"fire":
					var outer := Polygon2D.new()
					outer.polygon = PackedVector2Array([Vector2(-1, 0), Vector2(-0.6, -1.4), Vector2(0, -2.6), Vector2(0.6, -1.4), Vector2(1, 0), Vector2(0, 0.6)])
					outer.color = Color(1.0, 0.45, 0.12, 0.9)
					var inner := Polygon2D.new()
					inner.polygon = PackedVector2Array([Vector2(-0.5, 0), Vector2(0, -1.4), Vector2(0.5, 0), Vector2(0, 0.3)])
					inner.color = Color(1.0, 0.88, 0.45)
					outer.add_child(inner)
					outer.position = pt
					outer.scale = Vector2.ONE * size
					add_child(outer)
					_bits.append(outer)
				"ice":
					# кристалл льда и искорка инея рядом
					var cr := Polygon2D.new()
					cr.polygon = PackedVector2Array([Vector2(0, -1.6), Vector2(0.7, 0), Vector2(0, 1.6), Vector2(-0.7, 0)])
					cr.color = Color(0.80, 0.95, 1.0, 0.9)
					var core := Polygon2D.new()
					core.polygon = PackedVector2Array([Vector2(0, -0.8), Vector2(0.3, 0), Vector2(0, 0.8), Vector2(-0.3, 0)])
					core.color = Color(1, 1, 1)
					cr.add_child(core)
					cr.position = pt
					cr.scale = Vector2.ONE * size
					add_child(cr)
					_bits.append(cr)
				"abyss":
					for k in 2:
						var w := Polygon2D.new()
						w.polygon = Util.circle(0.8 + k * 0.3, 6)
						w.color = Color(0.55, 0.25, 0.85, 0.75) if k == 0 else Color(0.08, 0.03, 0.12, 0.8)
						w.position = pt
						w.scale = Vector2.ONE * size
						add_child(w)
						_bits.append(w)
				_:
					var st := Polygon2D.new()
					st.polygon = PackedVector2Array([Vector2(0, -1.6), Vector2(0.35, -0.35), Vector2(1.6, 0), Vector2(0.35, 0.35),
							Vector2(0, 1.6), Vector2(-0.35, 0.35), Vector2(-1.6, 0), Vector2(-0.35, -0.35)])
					st.color = Color(1.0, 0.97, 0.80)
					st.position = pt
					st.scale = Vector2.ONE * size
					add_child(st)
					_bits.append(st)

	func _process(delta: float) -> void:
		_t += delta
		for i in _bits.size():
			var b: Polygon2D = _bits[i]
			match theme:
				"fire":
					b.global_rotation = 0.0                    # пламя всегда тянется вверх
					b.scale = Vector2(size * (0.9 + 0.15 * sin(_t * 17.0 + i)), size * (0.8 + 0.35 * sin(_t * 11.0 + i * 2.1)))
				"abyss":
					var base: Vector2 = points[i / 2]
					b.position = base + Vector2(cos(_t * 3.0 + i * 2.4), sin(_t * 2.3 + i * 1.7)) * size * 0.8
					b.modulate.a = 0.6 + 0.4 * sin(_t * 4.0 + i)
				"ice":
					# кристалл мерцает, а с него сыплется иней
					b.global_rotation = 0.0
					var k2 := 0.75 + 0.35 * absf(sin(_t * 2.2 + i * 1.9))
					b.scale = Vector2(size * k2, size * (0.9 + 0.25 * sin(_t * 3.1 + i)))
					b.modulate.a = 0.75 + 0.25 * sin(_t * 5.0 + i * 2.0)
				_:
					b.rotation = _t * 2.0
					var k := 0.6 + 0.5 * absf(sin(_t * 3.0 + i * 1.3))
					b.scale = Vector2.ONE * size * k

# Ледяные шипы, на миг встающие из земли кольцом (приём, ульта, удар о землю в ледяном облике)
static func icicles(world: Node, at: Vector2, r: float, n: int) -> void:
	for k in n:
		var x := (k - (n - 1) / 2.0) * (2.0 * r / maxf(1.0, n - 1.0))
		var h := randf_range(18.0, 34.0) * (1.0 - absf(x) / (r * 1.6))
		var ic := Polygon2D.new()
		ic.polygon = PackedVector2Array([Vector2(-5, 0), Vector2(-1.5, -h * 0.7), Vector2(0, -h), Vector2(1.5, -h * 0.7), Vector2(5, 0)])
		ic.color = Color(0.70, 0.90, 1.0, 0.92) if k % 2 == 0 else Color(0.88, 0.97, 1.0, 0.92)
		ic.position = at + Vector2(x, 2)
		ic.scale = Vector2(1.0, 0.1)
		ic.z_index = 3
		world.add_child(ic)
		var tw := ic.create_tween()
		tw.tween_property(ic, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(0.35)
		tw.tween_property(ic, "modulate:a", 0.0, 0.3)
		tw.tween_callback(ic.queue_free)

# Хвост искр за снарядом
class Emitter extends Node2D:
	var col := Color.WHITE
	var hot := Color.WHITE

	func _physics_process(_delta: float) -> void:
		if randf() < 0.5:
			Fx.sparks(get_tree().current_scene if get_parent() == null else get_parent().get_parent(), global_position, col if randf() < 0.6 else hot, 1, 50.0, 3.0)
