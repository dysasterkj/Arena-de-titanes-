extends Node
## Datos del juego: equipo, enemigos, estadísticas, progreso y guardado.

const SAVE_PATH := "user://arena_de_titanes.json"

const WEAPONS := [
	{"id": "espada_corta", "name": "Espada corta", "cost": 0, "dmg": 6, "acc": 0.0, "desc": "Ligera y fiable."},
	{"id": "hacha", "name": "Hacha de mano", "cost": 150, "dmg": 9, "acc": -0.03, "desc": "Golpea fuerte y se mueve bien."},
	{"id": "lanza", "name": "Lanza", "cost": 260, "dmg": 10, "acc": 0.06, "desc": "Más precisa que las demás."},
	{"id": "maza", "name": "Maza de guerra", "cost": 380, "dmg": 13, "acc": -0.06, "desc": "Pesada: rompe defensas."},
	{"id": "espada_larga", "name": "Espada larga", "cost": 650, "dmg": 16, "acc": 0.0, "desc": "El arma del campeón."},
	{"id": "hacha_doble", "name": "Hacha doble", "cost": 1100, "dmg": 21, "acc": -0.08, "desc": "Dos filos, doble miedo."},
	{"id": "espada_fuego", "name": "Espada de fuego", "cost": 2000, "dmg": 27, "acc": 0.02, "desc": "Forjada en un volcán."},
	{"id": "martillo", "name": "Martillo del titán", "cost": 3500, "dmg": 35, "acc": -0.1, "desc": "Un golpe y se acaba."},
]

const HELMETS := [
	{"id": "none", "name": "Sin casco", "cost": 0, "def": 0, "desc": "Cabeza al aire."},
	{"id": "cuero", "name": "Casco de cuero", "cost": 60, "def": 2, "desc": "Lo mínimo para sobrevivir."},
	{"id": "bronce", "name": "Casco de bronce", "cost": 160, "def": 4, "desc": "Con cresta roja."},
	{"id": "hierro", "name": "Casco de hierro", "cost": 420, "def": 7, "desc": "Con cuernos."},
	{"id": "oro", "name": "Casco dorado", "cost": 1300, "def": 11, "desc": "Con penacho de campeón."},
]

const ARMORS := [
	{"id": "none", "name": "Sin armadura", "cost": 0, "def": 0, "desc": "Solo tu piel."},
	{"id": "cuero", "name": "Coraza de cuero", "cost": 90, "def": 3, "desc": "Ligera."},
	{"id": "bronce", "name": "Coraza de bronce", "cost": 240, "def": 6, "desc": "Con hombreras."},
	{"id": "hierro", "name": "Coraza de hierro", "cost": 600, "def": 10, "desc": "Pesada y segura."},
	{"id": "oro", "name": "Coraza dorada", "cost": 1800, "def": 15, "desc": "Brilla en la arena."},
]

const SHIELDS := [
	{"id": "none", "name": "Sin escudo", "cost": 0, "def": 0, "desc": "Sin protección."},
	{"id": "madera", "name": "Escudo de madera", "cost": 80, "def": 3, "desc": "Redondo y simple."},
	{"id": "bronce", "name": "Escudo de bronce", "cost": 220, "def": 5, "desc": "Resiste bien."},
	{"id": "hierro", "name": "Escudo de hierro", "cost": 520, "def": 8, "desc": "Casi una muralla."},
	{"id": "oro", "name": "Escudo dorado", "cost": 1500, "def": 12, "desc": "El orgullo del campeón."},
]

const POTIONS := {
	"vida": {"name": "Poción de vida", "cost": 45, "desc": "Recupera el 50% de tu vida."},
	"energia": {"name": "Poción de energía", "cost": 35, "desc": "Recupera el 60% de tu energía."},
}

const TABS := ["weapon", "helmet", "armor", "shield", "outfit", "cape", "paint", "potion"]
const TAB_NAMES := {"weapon": "Armas", "helmet": "Cascos", "armor": "Armaduras", "shield": "Escudos", "outfit": "Trajes", "cape": "Capas", "paint": "Pinturas", "potion": "Pociones"}

const STATS := ["vit", "fue", "agi", "def", "ene"]
const STAT_NAMES := {"vit": "Vida", "fue": "Ataque", "agi": "Puntería", "def": "Defensa", "ene": "Energía"}
const STAT_DESC := {
	"vit": "Más vida para aguantar más golpes.",
	"fue": "Más daño con cada golpe y más críticos.",
	"agi": "Aciertas más y esquivas mejor.",
	"def": "Reduce el daño recibido.",
	"ene": "Más energía y más poder mágico.",
}

# Poderes que se desbloquean con el nivel
const SKILLS := [
	{"id": "torbellino", "name": "Torbellino", "lvl": 2, "en": 16, "mult": 1.9, "acc": -0.05, "desc": "Giro devastador."},
	{"id": "bola", "name": "Bola de fuego", "lvl": 3, "en": 16, "mag": 1.0, "acc": 0.0, "ranged": true, "color": "f97316", "desc": "Magia a distancia."},
	{"id": "escudazo", "name": "Escudazo", "lvl": 4, "en": 14, "mult": 0.9, "acc": 0.1, "stun": 1, "desc": "Aturde al rival 1 turno."},
	{"id": "rayo", "name": "Rayo", "lvl": 5, "en": 22, "mag": 1.6, "acc": 0.12, "ranged": true, "color": "60a5fa", "desc": "Casi nunca falla."},
	{"id": "furia", "name": "Furia titán", "lvl": 6, "en": 26, "mult": 2.9, "acc": -0.1, "desc": "El golpe más fuerte."},
	{"id": "plegaria", "name": "Plegaria", "lvl": 8, "en": 22, "heal": 0.45, "desc": "Recupera el 45% de vida."},
]

const ARENAS := [
	{"name": "Arena del Polvo", "sand": "d9b36a", "wall": "a8794a", "sky_top": "5aa9e6", "sky_hor": "ffd9a0", "banner": "b91c1c", "crowd": 0},
	{"name": "Arena del Colmillo", "sand": "9c8f6e", "wall": "6b6a5e", "sky_top": "3d4f6b", "sky_hor": "e8a96b", "banner": "166534", "crowd": 1},
	{"name": "Laberinto del Minotauro", "sand": "b08968", "wall": "7f5539", "sky_top": "7b4a8a", "sky_hor": "f4a261", "banner": "7c2d12", "crowd": 2},
	{"name": "Coliseo de los Titanes", "sand": "6b5b73", "wall": "3b2f4a", "sky_top": "1c1033", "sky_hor": "c2410c", "banner": "fbbf24", "crowd": 3},
]

# Rivales: 4 arenas x 3 combates (el último de cada arena es jefe)
const ENEMIES := [
	{"name": "Aprendiz", "kind": "human", "skin": "e0ac69", "cloth": "6b7280", "weapon": "espada_corta", "helmet": "none", "shield": "none", "arena": 0},
	{"name": "Bandido", "kind": "human", "skin": "c68642", "cloth": "7c2d12", "weapon": "hacha", "helmet": "cuero", "shield": "none", "arena": 0},
	{"name": "Gladiador Rojo", "kind": "human", "skin": "8d5524", "cloth": "b91c1c", "weapon": "lanza", "helmet": "bronce", "shield": "madera", "arena": 0, "boss": true},
	{"name": "Esqueleto", "kind": "skeleton", "skin": "e5e7eb", "cloth": "374151", "weapon": "espada_corta", "helmet": "none", "shield": "madera", "arena": 1},
	{"name": "Orco", "kind": "orc", "skin": "65a30d", "cloth": "57534e", "weapon": "hacha", "helmet": "cuero", "shield": "none", "arena": 1},
	{"name": "Capitán Colmillo", "kind": "orc", "skin": "4d7c0f", "cloth": "44403c", "weapon": "maza", "helmet": "hierro", "shield": "bronce", "arena": 1, "boss": true},
	{"name": "Troll de Roca", "kind": "troll", "skin": "78716c", "cloth": "44403c", "weapon": "maza", "helmet": "none", "shield": "none", "arena": 2},
	{"name": "Hombre Lagarto", "kind": "lizard", "skin": "0d9488", "cloth": "134e4a", "weapon": "lanza", "helmet": "bronce", "shield": "bronce", "arena": 2},
	{"name": "Minotauro", "kind": "minotaur", "skin": "7c4a21", "cloth": "3f2a14", "weapon": "hacha_doble", "helmet": "none", "shield": "none", "arena": 2, "boss": true},
	{"name": "Demonio Menor", "kind": "demon", "skin": "dc2626", "cloth": "450a0a", "weapon": "espada_larga", "helmet": "none", "shield": "none", "arena": 3},
	{"name": "Caballero Oscuro", "kind": "knight", "skin": "1f2937", "cloth": "111827", "weapon": "espada_fuego", "helmet": "hierro", "shield": "hierro", "arena": 3},
	{"name": "Titán Supremo", "kind": "titan", "skin": "fbbf24", "cloth": "7c2d12", "weapon": "martillo", "helmet": "oro", "shield": "oro", "arena": 3, "boss": true},
]

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func default_data() -> Dictionary:
	return {
		"gold": 60, "xp": 0, "points": 0,
		"stats": {"vit": 5, "fue": 5, "agi": 5, "def": 5, "ene": 5},
		"owned": ["weapon:espada_corta"],
		"equip": {"weapon": "espada_corta", "helmet": "none", "armor": "none", "shield": "none", "outfit": "none", "cape": "none", "paint": "none"},
		"char": {"height": 1.0, "fat": 1.0, "skin": "c68642", "hair": "short", "hair_c": "3b2314", "beard": "none", "cloth": "1d4ed8"},
		"counters": {}, "ach_claimed": [], "ach_seen": [],
		"potions": {"vida": 2, "energia": 1},
		"wins": {}, "fights": 0, "victories": 0,
		"music": true, "sfx": true,
	}


func load_game() -> void:
	data = default_data()
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				for k in parsed:
					data[k] = parsed[k]
	for k in ["outfit", "cape", "paint"]:
		if not data.equip.has(k):
			data.equip[k] = "none"
	for k in default_data().char:
		if not data.char.has(k):
			data.char[k] = default_data().char[k]
	Sfx.set_options(bool(data.music), bool(data.sfx))


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


# ---------- Equipo ----------
func items(tab: String) -> Array:
	match tab:
		"weapon": return WEAPONS
		"helmet": return HELMETS
		"armor": return ARMORS
		"shield": return SHIELDS
		"outfit": return OUTFITS
		"cape": return CAPES
		"paint": return PAINTS
	return []


func item_def(tab: String, id: String) -> Dictionary:
	for it in items(tab):
		if it.id == id:
			return it
	return items(tab)[0]


func owns(tab: String, id: String) -> bool:
	return id == "none" or data.owned.has("%s:%s" % [tab, id])


func equipped(tab: String) -> String:
	return String(data.equip[tab])


func buy_item(tab: String, id: String) -> bool:
	if owns(tab, id):
		return false
	var c := int(item_def(tab, id).cost)
	if int(data.gold) < c:
		return false
	data.gold = int(data.gold) - c
	bump("spent", c)
	data.owned.append("%s:%s" % [tab, id])
	data.equip[tab] = id
	save_game()
	return true


func equip(tab: String, id: String) -> void:
	if owns(tab, id):
		data.equip[tab] = id
		save_game()


func buy_potion(id: String) -> bool:
	var c := int(POTIONS[id].cost)
	if int(data.gold) < c:
		return false
	data.gold = int(data.gold) - c
	bump("spent", c)
	data.potions[id] = potion_count(id) + 1
	save_game()
	return true


func potion_count(id: String) -> int:
	return int((data.potions as Dictionary).get(id, 0))


func use_potion(id: String) -> bool:
	if potion_count(id) <= 0:
		return false
	data.potions[id] = potion_count(id) - 1
	save_game()
	return true


# ---------- Estadísticas ----------
func stat(id: String) -> int:
	return int(data.stats[id])


func train_cost(id: String) -> int:
	return 20 + stat(id) * 12


func train_with_gold(id: String) -> bool:
	var c := train_cost(id)
	if int(data.gold) < c:
		return false
	data.gold = int(data.gold) - c
	bump("spent", c)
	data.stats[id] = stat(id) + 1
	save_game()
	return true


func train_with_point(id: String) -> bool:
	if int(data.points) <= 0:
		return false
	data.points = int(data.points) - 1
	data.stats[id] = stat(id) + 1
	save_game()
	return true


# ---------- Nivel ----------
func xp_total_for(level: int) -> int:
	return 60 * level * (level - 1)


func level() -> int:
	var l := 1
	while int(data.xp) >= xp_total_for(l + 1):
		l += 1
	return l


func xp_progress() -> Array:
	var l := level()
	var base := xp_total_for(l)
	return [int(data.xp) - base, xp_total_for(l + 1) - base]


## Suma XP y devuelve los mensajes de subida de nivel.
func add_xp(n: int) -> Array:
	var msgs: Array = []
	var before := level()
	data.xp = int(data.xp) + n
	var after := level()
	for l in range(before + 1, after + 1):
		data.points = int(data.points) + 3
		msgs.append("¡NIVEL %d! +3 puntos de estadística" % l)
		for s in SKILLS:
			if int(s.lvl) == l:
				msgs.append("Nuevo poder: %s" % s.name)
	save_game()
	return msgs


func unlocked_skills() -> Array:
	var out: Array = []
	for s in SKILLS:
		if level() >= int(s.lvl):
			out.append(s)
	return out


# ---------- Cálculos de combate ----------
## Devuelve un diccionario de combate para el jugador o un rival.
func player_fighter() -> Dictionary:
	var w := item_def("weapon", equipped("weapon"))
	var h := item_def("helmet", equipped("helmet"))
	var a := item_def("armor", equipped("armor"))
	var s := item_def("shield", equipped("shield"))
	var fx := body_effects()
	var ch: Dictionary = data.char
	return {
		"name": "Tú", "is_player": true, "level": level(),
		"max_hp": (40 + stat("vit") * 10) * float(fx.hp), "max_en": (20 + stat("ene") * 6) * float(fx.en),
		"fue": stat("fue") + float(fx.fue), "agi": stat("agi") + float(fx.agi),
		"def": stat("def") * 1.2 + int(h.def) + int(a.def) + int(s.def) + float(fx.def),
		"wdmg": int(w.dmg), "wacc": float(w.acc),
		"magic": 10.0 + stat("ene") * 1.4 + level() * 1.5, "weapon_id": w.id, "armed": true, "shield_def": int(s.def), "shield_max": int(s.def) * 14,
		"acc_high": float(fx.acc_high), "acc_low": float(fx.acc_low), "evade": float(fx.evade), "regen": float(fx.regen),
		"look": {"kind": "human", "skin": ch.skin, "cloth": ch.cloth, "hair": ch.hair, "hair_c": ch.hair_c, "beard": ch.beard,
			"height": float(ch.height), "fat": float(ch.fat),
			"weapon": w.id, "helmet": h.id, "armor": a.id, "shield": s.id,
			"outfit": equipped("outfit"), "cape": equipped("cape"), "paint": equipped("paint")},
	}


func enemy_fighter(i: int) -> Dictionary:
	var e: Dictionary = ENEMIES[i]
	var w := item_def("weapon", String(e.weapon))
	var boss: bool = bool(e.get("boss", false))
	var big := 1.0
	match String(e.kind):
		"orc": big = 1.12
		"troll": big = 1.3
		"minotaur": big = 1.35
		"titan": big = 1.5
		"demon": big = 1.15
	return {
		"name": e.name, "is_player": false, "boss": boss, "index": i, "level": 1 + i,
		"max_hp": 46 + i * 17 + (30 if boss else 0), "max_en": 36 + i * 6 + (14 if boss else 0),
		"fue": 3.5 + i * 1.5 + (2 if boss else 0), "agi": 4 + i * 1.1,
		"def": 1.5 + i * 1.3 + (3 if boss else 0),
		"wdmg": int(w.dmg) + (3 if boss else 0), "wacc": float(w.acc),
		"magic": 8.0 + i * 2.4, "weapon_id": w.id, "armed": true, "shield_def": int(item_def("shield", String(e.shield)).def), "shield_max": int(item_def("shield", String(e.shield)).def) * 14,
		"acc_high": 0.06 if big > 1.2 else 0.0, "acc_low": 0.0, "evade": -0.04 if big > 1.2 else 0.0, "regen": 0.0,
		"look": {"kind": e.kind, "skin": e.skin, "cloth": e.cloth, "weapon": e.weapon, "helmet": e.helmet, "armor": "none", "shield": e.shield, "scale": big},
	}


func reward_for(i: int, first_time: bool) -> Dictionary:
	var gold := 40 + i * 24
	var xp := 40 + i * 16
	if not first_time:
		gold = int(gold * 0.55)
		xp = int(xp * 0.5)
	return {"gold": gold, "xp": xp}


func fight_unlocked(i: int) -> bool:
	return i == 0 or (data.wins as Dictionary).has(str(i - 1))


func fight_won(i: int) -> bool:
	return (data.wins as Dictionary).has(str(i))


## Registra la victoria y devuelve [recompensa, mensajes].
func register_win(i: int) -> Array:
	var first := not fight_won(i)
	var r := reward_for(i, first)
	data.gold = int(data.gold) + int(r.gold)
	data.wins[str(i)] = 1
	data.victories = int(data.victories) + 1
	var msgs: Array = add_xp(int(r.xp))
	save_game()
	return [r, msgs]


func register_loss() -> void:
	data.fights = int(data.fights) + 1
	# consuelo: un poco de oro para no quedarse atascado
	data.gold = int(data.gold) + 12
	save_game()


# ======================= Personaje editable =======================
const HEIGHTS := [
	{"name": "Muy bajo", "value": 0.84}, {"name": "Bajo", "value": 0.92}, {"name": "Normal", "value": 1.0},
	{"name": "Alto", "value": 1.08}, {"name": "Muy alto", "value": 1.17},
]
const FATS := [
	{"name": "Muy flaco", "value": 0.84}, {"name": "Delgado", "value": 0.93}, {"name": "Normal", "value": 1.0},
	{"name": "Robusto", "value": 1.12}, {"name": "Gordo", "value": 1.26},
]
const SKINS := [
	{"name": "Claro", "value": "f1c27d"}, {"name": "Trigueño", "value": "e0ac69"}, {"name": "Canela", "value": "c68642"},
	{"name": "Moreno", "value": "a9743b"}, {"name": "Oscuro", "value": "8d5524"}, {"name": "Ébano", "value": "5c3a1e"},
	{"name": "Verdoso", "value": "8aa86b"}, {"name": "Pálido", "value": "ffdbac"},
]
const HAIRS := [
	{"name": "Corto", "value": "short"}, {"name": "Calvo", "value": "bald"}, {"name": "Cresta", "value": "mohawk"},
	{"name": "Largo", "value": "long"}, {"name": "Afro", "value": "afro"}, {"name": "Moño", "value": "topknot"},
	{"name": "Trenzas", "value": "braids"}, {"name": "De punta", "value": "spiky"},
]
const HAIR_COLORS := [
	{"name": "Negro", "value": "1a1a1a"}, {"name": "Castaño", "value": "3b2314"}, {"name": "Marrón", "value": "6b4423"},
	{"name": "Rubio", "value": "d6a85c"}, {"name": "Pelirrojo", "value": "a33b20"}, {"name": "Canoso", "value": "9ca3af"},
	{"name": "Azul", "value": "2563eb"}, {"name": "Violeta", "value": "9333ea"},
]
const BEARDS := [
	{"name": "Sin barba", "value": "none"}, {"name": "Sombra", "value": "stubble"}, {"name": "Bigote", "value": "mustache"},
	{"name": "Corta", "value": "short"}, {"name": "Completa", "value": "full"}, {"name": "Larga", "value": "long"},
	{"name": "Perilla", "value": "goatee"},
]
const CLOTHS := [
	{"name": "Azul", "value": "1d4ed8"}, {"name": "Rojo", "value": "b91c1c"}, {"name": "Verde", "value": "15803d"},
	{"name": "Morado", "value": "7e22ce"}, {"name": "Naranja", "value": "ea580c"}, {"name": "Negro", "value": "1f2937"},
	{"name": "Blanco", "value": "e5e7eb"}, {"name": "Dorado", "value": "ca8a04"},
]
const CHAR_ROWS := [
	{"key": "height", "label": "Altura"},
	{"key": "fat", "label": "Contextura"},
	{"key": "skin", "label": "Piel"},
	{"key": "hair", "label": "Pelo"},
	{"key": "hair_c", "label": "Color de pelo"},
	{"key": "beard", "label": "Barba"},
	{"key": "cloth", "label": "Color de túnica"},
]


func char_list(key: String) -> Array:
	match key:
		"height": return HEIGHTS
		"fat": return FATS
		"skin": return SKINS
		"hair": return HAIRS
		"hair_c": return HAIR_COLORS
		"beard": return BEARDS
		"cloth": return CLOTHS
	return []


func char_index(key: String) -> int:
	var list := char_list(key)
	var cur = data.char.get(key)
	for i in list.size():
		if str(list[i].value) == str(cur):
			return i
	return 2 if key in ["height", "fat"] else 0


func char_value_name(key: String) -> String:
	return String(char_list(key)[char_index(key)].name)


func cycle_char(key: String, dir: int) -> void:
	var list := char_list(key)
	var i := wrapi(char_index(key) + dir, 0, list.size())
	data.char[key] = list[i].value
	save_game()


## x: -1 (muy bajo) .. 1 (muy alto); y: -1 (muy flaco) .. 1 (muy gordo)
func body_axes() -> Vector2:
	var t := clampf((float(data.char.height) - 1.0) / 0.17, -1.0, 1.0)
	var f := clampf((float(data.char.fat) - 1.0) / 0.26, -1.0, 1.0)
	return Vector2(t, f)


func body_effects() -> Dictionary:
	var ax := body_axes()
	var t := ax.x
	var f := ax.y
	var tp := maxf(t, 0.0)
	var tn := maxf(-t, 0.0)
	var fp := maxf(f, 0.0)
	var fn := maxf(-f, 0.0)
	return {
		"hp": 1.0 + 0.18 * fp - 0.14 * fn,
		"en": 1.0 + 0.1 * fn - 0.1 * fp,
		"agi": -2.5 * fp + 2.0 * fn - 2.0 * tp + 1.5 * tn,
		"fue": 2.0 * tp + 1.5 * fp - 1.0 * tn - 1.0 * fn,
		"def": 2.0 * fp - 1.0 * fn,
		"acc_high": 0.06 * tp - 0.3 * tn,
		"acc_low": 0.12 * tn - 0.04 * tp,
		"evade": 0.07 * tp + 0.05 * fp - 0.08 * tn - 0.06 * fn,
		"regen": -1.0 * tp + 1.0 * tn,
	}


func body_effects_text() -> Array:
	var e := body_effects()
	var good: Array = []
	var bad: Array = []
	if float(e.acc_high) < -0.05:
		bad.append("Bajo: el golpe FUERTE (alto) falla mucho, no llegas a la cabeza")
	if float(e.acc_low) > 0.03:
		good.append("Bajo: el golpe RÁPIDO (bajo) es más preciso")
	if float(e.evade) < -0.03:
		good.append("Pequeño: los rivales te aciertan menos")
	if float(e.regen) > 0.5:
		good.append("Liviano: recuperas más energía por turno")
	if float(e.fue) > 0.8:
		good.append("Fuerza extra por tamaño y peso")
	if float(e.evade) > 0.03:
		bad.append("Grande: los rivales te aciertan más")
	if float(e.regen) < -0.5:
		bad.append("Alto: recuperas menos energía por turno")
	if float(e.agi) < -1.0:
		bad.append("Agilidad reducida (menos precisión)")
	if float(e.agi) > 1.0:
		good.append("Agilidad extra (más precisión)")
	if float(e.hp) > 1.05:
		good.append("Más vida máxima")
	if float(e.hp) < 0.95:
		bad.append("Menos vida máxima")
	if float(e.def) > 0.8:
		good.append("Piel gruesa: algo más de defensa")
	if float(e.fue) < -0.8:
		bad.append("Menos daño con cada golpe")
	return [good, bad]


# ======================= Cosméticos =======================
const OUTFITS := [
	{"id": "none", "name": "Túnica básica", "cost": 0, "desc": "Del color que elijas."},
	{"id": "romana", "name": "Túnica romana", "cost": 120, "desc": "Roja con bordes dorados."},
	{"id": "toga", "name": "Toga imperial", "cost": 160, "desc": "Blanca y larga."},
	{"id": "pieles", "name": "Pieles de bárbaro", "cost": 220, "desc": "Con cuello de pelo."},
	{"id": "espartano", "name": "Traje espartano", "cost": 320, "desc": "Granate y bronce."},
	{"id": "sombras", "name": "Traje de las sombras", "cost": 450, "desc": "Negro con detalles rojos."},
	{"id": "gala", "name": "Gala del campeón", "cost": 700, "desc": "Púrpura y oro."},
]
const CAPES := [
	{"id": "none", "name": "Sin capa", "cost": 0, "desc": "Ligero."},
	{"id": "roja", "name": "Capa roja", "cost": 100, "desc": "Clásica."},
	{"id": "azul", "name": "Capa azul", "cost": 100, "desc": "Fresca."},
	{"id": "negra", "name": "Capa negra", "cost": 160, "desc": "Misteriosa."},
	{"id": "lobo", "name": "Capa de lobo", "cost": 260, "desc": "Con pelaje gris."},
	{"id": "dorada", "name": "Capa dorada", "cost": 900, "desc": "Solo para campeones."},
]
const PAINTS := [
	{"id": "none", "name": "Sin pintura", "cost": 0, "desc": "Cara limpia."},
	{"id": "guerra", "name": "Pintura de guerra", "cost": 60, "desc": "Rayas rojas."},
	{"id": "tigre", "name": "Rayas de tigre", "cost": 90, "desc": "Naranja salvaje."},
	{"id": "calavera", "name": "Calavera", "cost": 140, "desc": "Da miedo."},
	{"id": "rayo", "name": "Rayo", "cost": 200, "desc": "Brillante."},
]


# ======================= Logros =======================
const ACHIEVEMENTS := [
	{"id": "w1", "name": "Primera sangre", "desc": "Gana tu primer combate", "stat": "victories", "target": 1, "gold": 60},
	{"id": "w5", "name": "Gladiador", "desc": "Gana 5 combates", "stat": "victories", "target": 5, "gold": 150},
	{"id": "w12", "name": "Veterano", "desc": "Gana 12 combates", "stat": "victories", "target": 12, "gold": 300},
	{"id": "w30", "name": "Leyenda de la arena", "desc": "Gana 30 combates", "stat": "victories", "target": 30, "gold": 800},
	{"id": "b1", "name": "Cazador de jefes", "desc": "Derrota a un jefe", "stat": "bosses", "target": 1, "gold": 120},
	{"id": "b4", "name": "Rey de las arenas", "desc": "Derrota a los 4 jefes", "stat": "bosses", "target": 4, "gold": 600, "grant": "cape:dorada"},
	{"id": "c10", "name": "Golpe certero", "desc": "Da 10 golpes críticos", "stat": "crits", "target": 10, "gold": 120},
	{"id": "p10", "name": "Alquimista", "desc": "Usa 10 pociones", "stat": "potions", "target": 10, "gold": 100},
	{"id": "f1", "name": "Intocable", "desc": "Gana sin perder nada de vida", "stat": "flawless", "target": 1, "gold": 200, "grant": "paint:rayo"},
	{"id": "s10", "name": "Maestro de poderes", "desc": "Usa 10 poderes", "stat": "skills", "target": 10, "gold": 120},
	{"id": "l5", "name": "Ascenso", "desc": "Llega al nivel 5", "stat": "level", "target": 5, "gold": 150},
	{"id": "l10", "name": "Gran maestro", "desc": "Llega al nivel 10", "stat": "level", "target": 10, "gold": 500},
	{"id": "i6", "name": "Coleccionista", "desc": "Ten 6 objetos comprados", "stat": "items", "target": 6, "gold": 150},
	{"id": "g1000", "name": "Derrochador", "desc": "Gasta 1.000 de oro", "stat": "spent", "target": 1000, "gold": 200, "grant": "outfit:romana"},
]


func bump(key: String, n: int = 1) -> void:
	data.counters[key] = int((data.counters as Dictionary).get(key, 0)) + n


func ach_stat(key: String) -> int:
	match key:
		"victories": return int(data.victories)
		"level": return level()
		"items":
			var c := 0
			for o in data.owned:
				if not String(o).ends_with(":espada_corta"):
					c += 1
			return c
	return int((data.counters as Dictionary).get(key, 0))


func ach_done(a: Dictionary) -> bool:
	return ach_stat(String(a.stat)) >= int(a.target)


func ach_claimed(a: Dictionary) -> bool:
	return (data.ach_claimed as Array).has(a.id)


func ach_ready() -> int:
	var n := 0
	for a in ACHIEVEMENTS:
		if ach_done(a) and not ach_claimed(a):
			n += 1
	return n


func claim_ach(id: String) -> String:
	for a in ACHIEVEMENTS:
		if a.id == id and ach_done(a) and not ach_claimed(a):
			data.ach_claimed.append(id)
			data.gold = int(data.gold) + int(a.gold)
			var msg := "+%d de oro" % int(a.gold)
			if a.has("grant"):
				var key := String(a.grant)
				if not (data.owned as Array).has(key):
					data.owned.append(key)
				msg += " y un premio de estilo"
			save_game()
			return msg
	return ""


## Logros completados desde la última vez (para avisar en pantalla).
func new_achievements() -> Array:
	var out: Array = []
	for a in ACHIEVEMENTS:
		if ach_done(a) and not (data.ach_seen as Array).has(a.id):
			data.ach_seen.append(a.id)
			out.append("¡Logro: %s! Reclámalo en LOGROS" % a.name)
	save_game()
	return out
