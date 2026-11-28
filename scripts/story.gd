extends RefCounted
## Modo historia "Cenizas del Coliseo": linajes, 6 capítulos de 5 niveles y textos del Cronista.

const LEVELS := 5

const ORDER := ["humano", "elfo", "orco", "enano"]

const LINEAGES := {
	"humano": {
		"name": "HUMANO", "kind": "human", "skin": "e0ac69", "hair": "short", "hair_c": "3b2314", "beard": "none", "height": 1.0, "fat": 1.0,
		"desc": "Hijo del pueblo. Los nobles te vendieron por deudas.", "bonus": "Equilibrado",
		"traitor": "Lord Valerio", "traitor_ch": 4,
		"origin": "Fuiste un hijo del pueblo, y por deudas te vendió el noble Lord Valerio a las Minas de Ceniza.",
		"confess": "«Te vendí por oro... y por el favor del Emperador. Búscalo en el Trono de Cuernos.»",
	},
	"elfo": {
		"name": "ELFO", "kind": "elf", "skin": "f6dcc8", "hair": "long", "hair_c": "e5e7eb", "beard": "none", "height": 1.1, "fat": 0.85,
		"desc": "Desterrado del bosque. Conoces un secreto del Coliseo.", "bonus": "+ Energía y magia · − Vida",
		"traitor": "Lady Sylara", "traitor_ch": 1,
		"origin": "Fuiste elfo del Bosque Roto, y tu mentora Sylara entregó tu secreto al Coliseo. Por eso acabaste en las Minas de Ceniza.",
		"confess": "«Te entregué por miedo... el Emperador sabía lo que guardabas. Búscalo en el Trono de Cuernos.»",
	},
	"orco": {
		"name": "ORCO", "kind": "orc", "skin": "65a30d", "hair": "bald", "hair_c": "1f1307", "beard": "none", "height": 1.0, "fat": 1.1,
		"desc": "Guerrero sin clan. Tus verdugos fueron tu propia gente.", "bonus": "+ Fuerza · − Puntería",
		"traitor": "Gromash", "traitor_ch": 0,
		"origin": "Fuiste orco guerrero, y tu hermano de clan Gromash te cambió por el mando del clan. Te arrojó a las Minas de Ceniza.",
		"confess": "«Quise el mando del clan... pero el Emperador me lo ordenó. Búscalo en el Trono de Cuernos.»",
	},
	"enano": {
		"name": "ENANO", "kind": "dwarf", "skin": "e7a67c", "hair": "bald", "hair_c": "c2410c", "beard": "full", "beard_c": "c2410c", "height": 0.84, "fat": 1.25,
		"desc": "Herrero traicionado. Cada arma guarda una pista.", "bonus": "+ Defensa · − Puntería",
		"traitor": "Borgrim", "traitor_ch": 2,
		"origin": "Fuiste enano herrero, y tu maestro Borgrim forjó la jaula que te encerró. Te mandó a las Minas de Ceniza.",
		"confess": "«Forjé tu jaula... el Emperador pagó mi deuda. Búscalo en el Trono de Cuernos.»",
	},
}

## Cada capítulo: raza, arena (tema 0-3), nombres/armas/cascos/escudos de los 5 niveles y textos.
const CHAPTERS := [
	{
		"name": "LAS MINAS DE CENIZA", "kind": "orc", "arena": 1, "skin": "65a30d", "cloth": "57534e",
		"names": ["Capataz Dugra", "Látigo Brokk", "Guardia Zurk", "Teniente Hargash", "Gromash"],
		"weapons": ["espada_corta", "hacha", "hacha", "lanza", "maza"],
		"helmets": ["none", "cuero", "cuero", "hierro", "hierro"],
		"shields": ["none", "none", "madera", "madera", "bronce"],
		"intro": "Las cadenas ceden por fin. Para huir de las Minas de Ceniza tendrás que abrirte paso entre los guardias orcos, uno a uno.",
		"lines": ["El primer capataz te ha visto. Nadie escapa de las minas... hasta hoy.", "Los látigos suenan en la oscuridad. Aguanta.", "Un guardia con escudo bloquea el túnel. No hay otra salida.", "El teniente manda a su gente. Si cae, el túnel es tuyo.", "Al final del túnel espera el carcelero mayor. Esta es la puerta de la libertad."],
		"outro": "Cruzas la última reja y respiras aire libre. En tu muñeca, la marca del Coliseo arde: alguien pagó por tu captura. El primer eslabón de la cadena está a la vista.",
	},
	{
		"name": "EL BOSQUE ROTO", "kind": "elf", "arena": 0, "skin": "f6dcc8", "cloth": "3f9c6e",
		"names": ["Arquero Ilvan", "Centinela Eryn", "Hechicera Thalia", "Capitán Faelar", "Sylara"],
		"weapons": ["lanza", "lanza", "espada_larga", "espada_larga", "espada_larga"],
		"helmets": ["none", "none", "bronce", "bronce", "bronce"],
		"shields": ["none", "madera", "none", "madera", "bronce"],
		"intro": "El bosque que cruzas está herido: los elfos custodian un sello robado al Coliseo. Quien lo vea, no sale con vida.",
		"lines": ["Una flecha pasa rozándote. Los elfos no perdonan a los intrusos.", "El centinela es veloz. No pierdas la calma.", "Su hechicera domina el viento. Cuidado con el acero que gira.", "El capitán de los guardabosques cierra el último claro.", "Entre los árboles aguarda la señora del bosque."],
		"outro": "El sello que protegían lleva grabado el escudo del Coliseo. Detrás de los combates hay una mano más alta que la de cualquier noble.",
	},
	{
		"name": "LA FORJA HUNDIDA", "kind": "dwarf", "arena": 2, "skin": "e7a67c", "cloth": "7c4a22",
		"names": ["Minero Durin", "Martillero Brom", "Herrero Thrain", "Capataz Gimrik", "Borgrim"],
		"weapons": ["maza", "maza", "espada_larga", "espada_larga", "espada_larga"],
		"helmets": ["cuero", "bronce", "bronce", "hierro", "hierro"],
		"shields": ["madera", "madera", "bronce", "bronce", "hierro"],
		"intro": "Bajo la montaña los enanos forjan las armas del Coliseo. Entre yunques y fuego encontrarás acero mejor... si lo ganas.",
		"lines": ["Los mineros defienden la entrada a golpe de pico.", "El martillero no se rinde mientras le quede aliento.", "El herrero conoce cada arma que llevas. Es su obra.", "El capataz custodia las galerías más profundas.", "Al fondo, en la forja mayor, espera el maestro herrero."],
		"outro": "En el yunque encuentras una hoja con tu nombre grabado: la mandaron forjar mucho antes de tu captura. Te estaban esperando.",
	},
	{
		"name": "LOS PANTANOS DE SAL", "kind": "lizard", "arena": 1, "skin": "0d9488", "cloth": "134e4a",
		"names": ["Cazador Ssik", "Acechador Szura", "Chamán Ssol", "Lancero Ssarr", "Ssarek"],
		"weapons": ["lanza", "espada_larga", "espada_larga", "hacha_doble", "hacha_doble"],
		"helmets": ["none", "bronce", "none", "bronce", "hierro"],
		"shields": ["none", "bronce", "bronce", "bronce", "hierro"],
		"intro": "La niebla salada oculta a los reptilianos. Guardan los archivos del Coliseo, y con ellos, la verdad sobre quién pagó por ti.",
		"lines": ["Algo se mueve entre las cañas. Te cazan.", "El acechador ataca desde el agua. No te quedes quieto.", "El chamán murmura y el barro se agita bajo tus pies.", "El lancero guarda el último puente de raíces.", "El anciano Ssarek custodia los archivos. Dicen que nunca ha perdido."],
		"outro": "En los archivos hallas un nombre y un sello: el pago por tu captura salió del Trono de Cuernos. Ya sabes adónde ir, pero antes tendrás que cruzar la capital.",
	},
	{
		"name": "LAS PUERTAS DEL COLISEO", "kind": "human", "arena": 0, "skin": "c68642", "cloth": "b91c1c",
		"names": ["Gladiador Marco", "Pretoriano Casio", "Centurión Lucio", "Capitán Rufo", "Lord Valerio"],
		"weapons": ["espada_larga", "hacha_doble", "hacha_doble", "espada_fuego", "espada_fuego"],
		"helmets": ["bronce", "bronce", "hierro", "hierro", "oro"],
		"shields": ["bronce", "bronce", "hierro", "hierro", "hierro"],
		"intro": "La capital se alza ante ti y el pueblo ya te conoce: el gladiador que escapó de las minas. La guardia del Coliseo bloquea las puertas.",
		"lines": ["Los gladiadores de la ciudad te reciben con sonrisas de acero.", "Un pretoriano te corta el paso. El pueblo mira desde las gradas.", "El centurión es veterano de cien arenas.", "El capitán de la guardia es la última barrera antes del palacio.", "El noble de la ciudad sale a tu encuentro. Su mirada lo dice todo."],
		"outro": "Las puertas del palacio se abren. Lo que viene no es una arena: es un trono. Y en él, el Emperador te espera.",
	},
	{
		"name": "EL TRONO DE CUERNOS", "kind": "minotaur", "arena": 3, "skin": "7c4a21", "cloth": "3f2a14",
		"names": ["Guardia Real", "Toro de Hierro", "Carnicero Astor", "Capitán Taurus", "Korvax"],
		"weapons": ["hacha_doble", "espada_fuego", "espada_fuego", "martillo", "martillo"],
		"helmets": ["hierro", "hierro", "oro", "oro", "oro"],
		"shields": ["hierro", "hierro", "oro", "oro", "oro"],
		"intro": "El último tramo: los salones de cuernos del Emperador Korvax. Aquí nadie ha entrado sin ser invitado... y salido de pie.",
		"lines": ["La guardia real marcha con paso de toro.", "El Toro de Hierro embiste contra todo lo que se mueve.", "El carnicero real no deja nada en pie.", "El capitán Taurus es la mano derecha del Emperador.", "Korvax, el campeón que te condenó, se levanta del trono."],
		"outro": "Korvax cae. El Coliseo guarda silencio, y por primera vez el pueblo no aplaude ni abuchea: te mira. Tu venganza está cumplida... pero la arena ya nunca será la misma.",
	},
]


static func lineage(id: String) -> Dictionary:
	return LINEAGES.get(id, LINEAGES["humano"])


static func global_index(ch: int, lv: int) -> int:
	return ch * LEVELS + lv


## ¿El jefe de este capítulo es el traidor del linaje elegido?
static func is_traitor(ch: int, lin_id: String) -> bool:
	return lin_id != "" and int(lineage(lin_id).traitor_ch) == ch


static func chapter_intro(ch: int, lin_id: String) -> String:
	var t := String(CHAPTERS[ch].intro)
	if ch == 0 and lin_id != "":
		t = String(lineage(lin_id).origin) + " " + t
	return t


static func level_line(ch: int, lv: int, lin_id: String) -> String:
	if lv == LEVELS - 1 and is_traitor(ch, lin_id):
		return "Reconoces ese rostro: es %s, el que te traicionó. Esta pelea es personal." % String(lineage(lin_id).traitor)
	return String(CHAPTERS[ch].lines[lv])


static func chapter_outro(ch: int, lin_id: String) -> String:
	var t := String(CHAPTERS[ch].outro)
	if is_traitor(ch, lin_id):
		t = "Antes de caer, %s susurra: %s\n\n" % [String(lineage(lin_id).traitor), String(lineage(lin_id).confess)] + t
	return t


static func reward(ch: int, lv: int, first: bool) -> Dictionary:
	var g := global_index(ch, lv)
	var gold := 34 + g * 12
	var xp := 38 + g * 10
	if lv == LEVELS - 1:
		gold = int(gold * 1.6)
		xp = int(xp * 1.5)
	if not first:
		gold = int(gold * 0.5)
		xp = int(xp * 0.5)
	return {"gold": gold, "xp": xp}


## Rival de un nivel de la historia (mismo formato que GameState._enemy_base).
static func enemy_fighter(ch: int, lv: int, lin_id: String) -> Dictionary:
	var c: Dictionary = CHAPTERS[ch]
	var g := global_index(ch, lv)
	var i := g * 0.4
	var boss := lv == LEVELS - 1
	var lieut := lv == LEVELS - 2
	var wid := String(c.weapons[lv])
	var w: Dictionary = GameState.item_def("weapon", wid)
	var shid := String(c.shields[lv])
	var kind := String(c.kind)
	var big := 1.0
	var height := 1.0
	var fat := 1.0
	match kind:
		"orc": big = 1.1
		"minotaur": big = 1.3
		"elf":
			height = 1.08
			fat = 0.88
		"dwarf":
			height = 0.84
			fat = 1.25
	var ename := String(c.names[lv])
	if boss and is_traitor(ch, lin_id):
		ename = String(lineage(lin_id).traitor)
	var sdef := int(GameState.item_def("shield", shid).def)
	var bonus_hp := 30 if boss else (12 if lieut else 0)
	var look := {"kind": kind, "skin": c.skin, "cloth": c.cloth, "weapon": wid, "helmet": c.helmets[lv], "armor": "none", "shield": shid, "scale": big, "height": height, "fat": fat}
	if kind == "elf":
		look["hair"] = "long"
		look["hair_c"] = "e5e7eb"
	elif kind == "dwarf":
		look["hair"] = "bald"
		look["beard"] = "full"
		look["beard_c"] = ["c2410c", "92400e", "e5e7eb", "b45309", "ea580c"][lv]
	elif kind == "human":
		look["hair"] = ["short", "spiky", "short", "long", "short"][lv]
		look["hair_c"] = ["3b2314", "111827", "78350f", "9ca3af", "e5e7eb"][lv]
		look["beard"] = ["stubble", "none", "short", "mustache", "goatee"][lv]
		look["skin"] = ["e0ac69", "c68642", "8d5524", "e0ac69", "f1c27d"][lv]
	return {
		"name": ename, "is_player": false, "boss": boss, "index": g, "level": 1 + int(i * 1.2),
		"max_hp": 46 + i * 17 + bonus_hp, "max_en": 36 + i * 6 + (14 if boss else 0),
		"fue": 3.5 + i * 1.5 + (2 if boss else 0) + (1 if lieut else 0), "agi": 4 + i * 1.1 + (1.5 if kind == "elf" else 0.0),
		"def": 1.5 + i * 1.3 + (3 if boss else 0) + (1 if lieut else 0),
		"wdmg": int(w.dmg) + (3 if boss else 0), "wacc": float(w.acc),
		"magic": 8.0 + i * 2.4, "weapon_id": w.id, "armed": true, "shield_def": sdef, "shield_max": sdef * 14,
		"acc_high": 0.06 if big > 1.2 else 0.0, "acc_low": 0.0, "evade": -0.04 if big > 1.2 else 0.0, "regen": 0.0,
		"look": look,
	}
