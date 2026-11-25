extends Node3D
## Luchador 3D: cuerpo personalizable (altura, contextura, pelo, barba, piel), monstruos, equipo visible y animaciones.

const Toon = preload("res://scripts/toon.gd")

var look: Dictionary = {}
var model: Node3D
var body: Node3D
var head: Node3D
var arm_r: Node3D
var fore_r: Node3D
var arm_l: Node3D
var fore_l: Node3D
var leg_l: Node3D
var leg_r: Node3D
var tail: Node3D
var cape_node: Node3D
var t := 0.0
var busy := false
var dead := false
var guard := false
var kind := "human"
var scl := 1.0
var phase := 0.0

const POSE_R := Vector2(0.7, 1.6)
const POSE_L := Vector2(1.2, 1.5)

const OUTFITS := {
	"romana": {"cloth": "b91c1c", "trim": "fbbf24", "style": "tunic"},
	"toga": {"cloth": "f1f5f9", "trim": "a855f7", "style": "toga"},
	"pieles": {"cloth": "78350f", "trim": "d6c7a1", "style": "fur"},
	"gala": {"cloth": "6d28d9", "trim": "fbbf24", "style": "tunic"},
	"sombras": {"cloth": "111827", "trim": "dc2626", "style": "tunic"},
	"espartano": {"cloth": "7f1d1d", "trim": "cd7f32", "style": "tunic"},
}
const CAPES := {"roja": "dc2626", "azul": "2563eb", "negra": "18181b", "dorada": "fbbf24", "lobo": "78716c"}


func _ready() -> void:
	phase = randf() * 6.0


func _col(s: Variant, fallback: String = "ffffff") -> Color:
	return Color(String(s)) if String(s) != "" else Color(fallback)


func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	parent.add_child(p)
	return p


func _seg(parent: Node3D, color: Color, length: float, radius: float) -> void:
	Toon.part(parent, Toon.capsule(radius, length), color, Vector3(0, -length * 0.5, 0))


func setup(l: Dictionary) -> void:
	look = l
	for c in get_children():
		c.queue_free()
	kind = String(l.get("kind", "human"))
	scl = float(l.get("scale", 1.0))
	var hh := float(l.get("height", 1.0))
	var ww := float(l.get("fat", 1.0))
	model = Node3D.new()
	model.scale = Vector3(scl * ww, scl * hh, scl * ww)
	add_child(model)
	var skin := _col(l.get("skin", "c68642"))
	var cloth := _col(l.get("cloth", "1d4ed8"))
	var trim := Color("fbbf24")
	var outfit_style := "tunic"
	var oid := String(l.get("outfit", "none"))
	if OUTFITS.has(oid) and kind == "human":
		cloth = _col(OUTFITS[oid].cloth)
		trim = _col(OUTFITS[oid].trim)
		outfit_style = String(OUTFITS[oid].style)
	var bone := kind == "skeleton"
	var monster := kind in ["orc", "troll", "lizard", "minotaur", "demon", "titan"]
	var wide := 1.0
	var thick := 1.0
	var arm_len := 0.38
	match kind:
		"troll":
			wide = 1.28
			thick = 1.25
			arm_len = 0.5
		"skeleton":
			thick = 0.62
		"orc", "minotaur", "demon", "titan":
			wide = 1.12
			thick = 1.1
	var pants := cloth.darkened(0.3)
	var leather := Color("6b4423")

	# piernas
	leg_l = _pivot(model, Vector3(-0.16 * wide, 0.88, 0))
	leg_r = _pivot(model, Vector3(0.16 * wide, 0.88, 0))
	for lg in [leg_l, leg_r]:
		_seg(lg, skin, 0.5, 0.135 * thick)
		var shin := _pivot(lg, Vector3(0, -0.46, 0))
		_seg(shin, skin, 0.42, 0.11 * thick)
		Toon.part(shin, Toon.sphere(0.12 * thick), skin, Vector3(0, 0.02, 0), Vector3.ZERO, false)
		if not bone:
			Toon.part(shin, Toon.cyl(0.115 * thick, 0.1 * thick, 0.24), leather, Vector3(0, -0.2, 0), Vector3.ZERO, false)
		Toon.part(shin, Toon.box(Vector3(0.22 * thick, 0.1, 0.42)), Color("3f2a14") if not bone else skin.darkened(0.1), Vector3(0, -0.4, -0.08))
		Toon.part(shin, Toon.box(Vector3(0.2 * thick, 0.03, 0.05)), leather.lightened(0.2), Vector3(0, -0.32, -0.02), Vector3.ZERO, false)

	# tronco
	body = _pivot(model, Vector3(0, 0.88, 0))
	if bone:
		Toon.part(body, Toon.capsule(0.12, 0.8), skin, Vector3(0, 0.4, 0))
		for y in [0.2, 0.38, 0.56]:
			Toon.part(body, Toon.box(Vector3(0.5, 0.06, 0.3)), skin, Vector3(0, y, 0), Vector3.ZERO, false)
	else:
		var chest_col := skin if (monster or oid == "none" and false) else cloth
		if kind == "human":
			chest_col = skin
			Toon.part(body, Toon.capsule(0.27 * wide, 0.94), skin, Vector3(0, 0.42, 0))
			for sx in [-1.0, 1.0]:
				Toon.part(body, Toon.sphere(0.13 * wide), skin.lightened(0.06), Vector3(sx * 0.13, 0.62, -0.17), Vector3.ZERO, false)
			Toon.part(body, Toon.box(Vector3(0.05, 0.26, 0.03)), skin.darkened(0.12), Vector3(0, 0.42, -0.27), Vector3.ZERO, false)
		else:
			Toon.part(body, Toon.capsule(0.27 * wide, 0.94), chest_col if kind == "knight" or kind == "demon" and false else (skin if monster else cloth), Vector3(0, 0.42, 0))
		# cinturón y falda
		Toon.part(body, Toon.cyl(0.285 * wide, 0.285 * wide, 0.11), leather.darkened(0.2), Vector3(0, 0.08, 0), Vector3.ZERO, false)
		Toon.part(body, Toon.box(Vector3(0.12, 0.12, 0.04)), trim, Vector3(0, 0.08, -0.29 * wide), Vector3.ZERO, false)
		var skirt_len := 0.42
		var skirt_bot := 0.42
		if outfit_style == "toga":
			skirt_len = 0.9
			skirt_bot = 0.34
		Toon.part(body, Toon.cyl(0.285 * wide, skirt_bot * wide, skirt_len), cloth, Vector3(0, 0.0 - skirt_len * 0.5 + 0.02, 0))
		Toon.part(body, Toon.cyl(skirt_bot * wide + 0.005, skirt_bot * wide + 0.005, 0.05), trim, Vector3(0, -skirt_len + 0.04, 0), Vector3.ZERO, false)
		if outfit_style == "tunic" and kind == "human":
			Toon.part(body, Toon.cyl(0.275 * wide, 0.29 * wide, 0.36), cloth, Vector3(0, 0.62, 0), Vector3.ZERO, false)
		# correas en el pecho
		if kind == "human" and outfit_style != "toga":
			for s in [-1.0, 1.0]:
				Toon.part(body, Toon.box(Vector3(0.06, 0.95, 0.03)), leather, Vector3(0, 0.42, -0.255 * wide), Vector3(0, 0, s * 0.62), false)
		if outfit_style == "fur":
			for i in 9:
				var a := i * TAU / 9.0
				Toon.part(body, Toon.cyl(0.0, 0.07, 0.2), trim, Vector3(sin(a) * 0.28 * wide, 0.82, cos(a) * 0.2), Vector3(cos(a) * 0.8, 0, -sin(a) * 0.8), false)
	_armor_visual(String(l.get("armor", "none")), wide)

	# brazos
	arm_r = _pivot(body, Vector3(0.38 * wide, 0.74, 0))
	arm_l = _pivot(body, Vector3(-0.38 * wide, 0.74, 0))
	for ar in [arm_r, arm_l]:
		Toon.part(ar, Toon.sphere(0.15 * thick), skin if (bone or monster or kind == "human") else cloth, Vector3.ZERO, Vector3.ZERO, false)
		_seg(ar, skin if (bone or monster or kind == "human") else cloth, arm_len, 0.105 * thick)
		if kind == "human":
			Toon.part(ar, Toon.sphere(0.115), skin.lightened(0.05), Vector3(0, -0.14, -0.03), Vector3.ZERO, false)
	fore_r = _pivot(arm_r, Vector3(0, -arm_len + 0.02, 0))
	fore_l = _pivot(arm_l, Vector3(0, -arm_len + 0.02, 0))
	for fr in [fore_r, fore_l]:
		_seg(fr, skin, 0.34, 0.088 * thick)
		Toon.part(fr, Toon.sphere(0.105 * thick), skin, Vector3(0, -0.34, 0), Vector3.ZERO, false)
		if kind in ["human", "orc", "minotaur", "lizard"]:
			Toon.part(fr, Toon.cyl(0.098 * thick, 0.092 * thick, 0.14), leather, Vector3(0, -0.24, 0), Vector3.ZERO, false)
			Toon.part(fr, Toon.box(Vector3(0.03, 0.1, 0.08)), skin, Vector3(0.05, -0.38, -0.05), Vector3.ZERO, false)
	if kind in ["knight", "titan"]:
		for fr in [fore_r, fore_l]:
			Toon.part(fr, Toon.cyl(0.11, 0.11, 0.3), Color("94a3b8") if kind == "knight" else Color("fbbf24"), Vector3(0, -0.2, 0), Vector3.ZERO, false)

	# cabeza
	head = _pivot(body, Vector3(0, 0.9, 0))
	head.scale = Vector3(1.0 / sqrt(ww), 1.0 / sqrt(hh), 1.0 / sqrt(ww))
	Toon.part(body, Toon.cyl(0.1, 0.12, 0.14), skin, Vector3(0, 0.86, 0), Vector3.ZERO, false)
	_head_visual(skin, cloth)
	_helmet_visual(String(l.get("helmet", "none")))
	_paint_visual(String(l.get("paint", "none")))
	_kind_extras(skin, cloth)
	_cape_visual(String(l.get("cape", "none")))

	# arma y escudo
	var holder := _pivot(fore_r, Vector3(0, -0.34, 0))
	holder.rotation.x = PI
	holder.add_child(_make_weapon(String(l.get("weapon", "espada_corta"))))
	_shield_visual(String(l.get("shield", "none")))
	arm_r.rotation.x = POSE_R.x
	fore_r.rotation.x = POSE_R.y
	arm_l.rotation.x = POSE_L.x
	fore_l.rotation.x = POSE_L.y
	arm_l.rotation.z = 0.15
	arm_r.rotation.z = -0.15
	leg_l.rotation.x = -0.25
	leg_r.rotation.x = 0.3
	dead = false
	busy = false
	guard = false


# ---------- Piezas ----------
func _hair_visual(style: String, hc: Color) -> void:
	match style:
		"bald", "":
			return
		"mohawk":
			for i in 8:
				var a := lerpf(-0.9, 0.9, i / 7.0)
				Toon.part(head, Toon.box(Vector3(0.07, 0.18 - absf(a) * 0.05, 0.1)), hc, Vector3(0, 0.46 + cos(a) * 0.04, sin(a) * 0.26), Vector3(-a * 0.5, 0, 0), false)
			return
		"afro":
			Toon.part(head, Toon.sphere(0.42), hc, Vector3(0, 0.33, 0.08))
			return
	Toon.part(head, Toon.sphere(0.285), hc, Vector3(0, 0.27, 0.05))
	match style:
		"long":
			Toon.part(head, Toon.capsule(0.16, 0.8), hc, Vector3(0, -0.1, 0.19))
			for sx in [-1.0, 1.0]:
				Toon.part(head, Toon.capsule(0.06, 0.4), hc, Vector3(sx * 0.25, 0.05, -0.04), Vector3.ZERO, false)
		"topknot":
			Toon.part(head, Toon.sphere(0.14), hc, Vector3(0, 0.56, 0.08))
		"braids":
			for sx in [-1.0, 1.0]:
				Toon.part(head, Toon.capsule(0.06, 0.6), hc, Vector3(sx * 0.27, -0.02, -0.02))
		"spiky":
			for i in 7:
				var a := i * TAU / 7.0
				Toon.part(head, Toon.cyl(0.0, 0.07, 0.22), hc, Vector3(sin(a) * 0.17, 0.5, cos(a) * 0.17), Vector3(cos(a) * 0.5, 0, -sin(a) * 0.5), false)


func _beard_visual(style: String, bc: Color) -> void:
	match style:
		"stubble":
			Toon.part(head, Toon.sphere(0.262), bc.lerp(Color("2a1a10"), 0.2), Vector3(0, 0.185, -0.012), Vector3.ZERO, false).scale = Vector3(1.0, 0.8, 1.0)
		"mustache":
			Toon.part(head, Toon.capsule(0.035, 0.26), bc, Vector3(0, 0.125, -0.245), Vector3(0, 0, PI / 2), false)
		"short":
			Toon.part(head, Toon.sphere(0.22, 0.28), bc, Vector3(0, 0.07, -0.1))
			Toon.part(head, Toon.capsule(0.035, 0.26), bc, Vector3(0, 0.125, -0.245), Vector3(0, 0, PI / 2), false)
		"full":
			Toon.part(head, Toon.sphere(0.27, 0.42), bc, Vector3(0, 0.03, -0.08))
			Toon.part(head, Toon.capsule(0.04, 0.3), bc, Vector3(0, 0.125, -0.25), Vector3(0, 0, PI / 2), false)
		"long":
			Toon.part(head, Toon.sphere(0.27, 0.4), bc, Vector3(0, 0.04, -0.08))
			Toon.part(head, Toon.capsule(0.13, 0.62), bc, Vector3(0, -0.28, -0.12))
			Toon.part(head, Toon.capsule(0.04, 0.3), bc, Vector3(0, 0.125, -0.25), Vector3(0, 0, PI / 2), false)
		"goatee":
			Toon.part(head, Toon.sphere(0.08, 0.2), bc, Vector3(0, 0.0, -0.22))
			Toon.part(head, Toon.capsule(0.035, 0.22), bc, Vector3(0, 0.125, -0.245), Vector3(0, 0, PI / 2), false)


func _head_visual(skin: Color, cloth: Color) -> void:
	var dark := Color("111111")
	match kind:
		"skeleton":
			Toon.part(head, Toon.sphere(0.26), Color("f1f5f9"), Vector3(0, 0.2, 0))
			Toon.part(head, Toon.sphere(0.075), dark, Vector3(-0.09, 0.24, -0.2), Vector3.ZERO, false)
			Toon.part(head, Toon.sphere(0.075), dark, Vector3(0.09, 0.24, -0.2), Vector3.ZERO, false)
			Toon.glow(head, Toon.sphere(0.025), Color("ef4444"), Vector3(-0.09, 0.24, -0.255))
			Toon.glow(head, Toon.sphere(0.025), Color("ef4444"), Vector3(0.09, 0.24, -0.255))
			Toon.part(head, Toon.box(Vector3(0.2, 0.09, 0.12)), Color("e2e8f0"), Vector3(0, 0.03, -0.17))
			for i in 5:
				Toon.part(head, Toon.box(Vector3(0.025, 0.05, 0.02)), dark, Vector3(-0.08 + i * 0.04, 0.03, -0.235), Vector3.ZERO, false)
		"minotaur":
			Toon.part(head, Toon.sphere(0.28), skin, Vector3(0, 0.2, 0))
			Toon.part(head, Toon.box(Vector3(0.24, 0.22, 0.26)), skin.lightened(0.15), Vector3(0, 0.08, -0.3))
			Toon.part(head, Toon.sphere(0.07), Color("1f1f1f"), Vector3(-0.07, 0.08, -0.44), Vector3.ZERO, false)
			Toon.part(head, Toon.sphere(0.07), Color("1f1f1f"), Vector3(0.07, 0.08, -0.44), Vector3.ZERO, false)
			Toon.glow(head, Toon.torus(0.05, 0.09), Color("fbbf24"), Vector3(0, 0.0, -0.44), Vector3(PI / 2, 0, 0))
			Toon.glow(head, Toon.sphere(0.045), Color("ef4444"), Vector3(-0.12, 0.28, -0.25))
			Toon.glow(head, Toon.sphere(0.045), Color("ef4444"), Vector3(0.12, 0.28, -0.25))
			for sx in [-1.0, 1.0]:
				Toon.part(head, Toon.box(Vector3(0.3, 0.08, 0.08)), Color("f1e3c8"), Vector3(sx * 0.3, 0.42, 0), Vector3(0, 0, sx * 0.5))
				Toon.part(head, Toon.cyl(0.0, 0.05, 0.28), Color("f1e3c8"), Vector3(sx * 0.46, 0.6, 0), Vector3(0, 0, -sx * 0.15))
		"lizard":
			Toon.part(head, Toon.sphere(0.25), skin, Vector3(0, 0.2, 0))
			Toon.part(head, Toon.box(Vector3(0.22, 0.15, 0.34)), skin.lightened(0.1), Vector3(0, 0.12, -0.3))
			Toon.glow(head, Toon.sphere(0.055), Color("fde047"), Vector3(-0.12, 0.3, -0.19))
			Toon.glow(head, Toon.sphere(0.055), Color("fde047"), Vector3(0.12, 0.3, -0.19))
			Toon.part(head, Toon.box(Vector3(0.02, 0.1, 0.02)), dark, Vector3(-0.12, 0.3, -0.24), Vector3.ZERO, false)
			Toon.part(head, Toon.box(Vector3(0.02, 0.1, 0.02)), dark, Vector3(0.12, 0.3, -0.24), Vector3.ZERO, false)
			for i in 4:
				Toon.part(head, Toon.cyl(0.0, 0.05, 0.16), skin.darkened(0.25), Vector3(0, 0.46 - i * 0.04, 0.0 + i * 0.1), Vector3.ZERO, false)
		"demon":
			Toon.part(head, Toon.sphere(0.27), skin, Vector3(0, 0.2, 0))
			Toon.glow(head, Toon.sphere(0.055), Color("fde047"), Vector3(-0.09, 0.24, -0.22))
			Toon.glow(head, Toon.sphere(0.055), Color("fde047"), Vector3(0.09, 0.24, -0.22))
			Toon.part(head, Toon.box(Vector3(0.18, 0.035, 0.02)), Color("450a0a"), Vector3(0, 0.1, -0.255), Vector3.ZERO, false)
			for sx in [-1.0, 1.0]:
				Toon.part(head, Toon.cyl(0.0, 0.08, 0.38), Color("1c1917"), Vector3(sx * 0.18, 0.5, 0), Vector3(0, 0, -sx * 0.35))
				Toon.part(head, Toon.box(Vector3(0.1, 0.03, 0.03)), Color("1c1917"), Vector3(sx * 0.09, 0.32, -0.23), Vector3(0, 0, sx * 0.4), false)
		"knight":
			Toon.part(head, Toon.sphere(0.285), Color("374151"), Vector3(0, 0.2, 0))
			Toon.glow(head, Toon.box(Vector3(0.32, 0.05, 0.03)), Color("ef4444"), Vector3(0, 0.22, -0.26))
			Toon.part(head, Toon.box(Vector3(0.05, 0.22, 0.34)), Color("dc2626"), Vector3(0, 0.5, 0.05), Vector3.ZERO, false)
		"titan":
			Toon.part(head, Toon.sphere(0.28), skin, Vector3(0, 0.2, 0))
			Toon.glow(head, Toon.sphere(0.05), Color("38bdf8"), Vector3(-0.09, 0.24, -0.24))
			Toon.glow(head, Toon.sphere(0.05), Color("38bdf8"), Vector3(0.09, 0.24, -0.24))
			Toon.glow(head, Toon.torus(0.36, 0.42), Color("fde047"), Vector3(0, 0.66, 0), Vector3.ZERO, 0.85)
		_:
			var big := 1.0 if kind != "troll" else 0.85
			var hs := 0.27 * big
			Toon.part(head, Toon.sphere(hs), skin, Vector3(0, 0.2, 0))
			# ojos con blanco, pupila y cejas
			for sx in [-1.0, 1.0]:
				var eye := Toon.part(head, Toon.sphere(0.058), Color("fafafa"), Vector3(sx * 0.1, 0.235, -0.232 * big), Vector3.ZERO, false)
				eye.scale = Vector3(1.0, 1.0, 0.55)
				Toon.part(head, Toon.sphere(0.03), Color("2a1608"), Vector3(sx * 0.1, 0.235, -0.262 * big), Vector3.ZERO, false)
				Toon.part(head, Toon.sphere(0.012), Color("ffffff"), Vector3(sx * 0.1 + 0.01, 0.245, -0.285 * big), Vector3.ZERO, false)
				Toon.part(head, Toon.box(Vector3(0.12, 0.028, 0.03)), Color("1f1008") if kind != "orc" else Color("0f1a05"), Vector3(sx * 0.1, 0.31, -0.235 * big), Vector3(0, 0, sx * 0.3), false)
				Toon.part(head, Toon.sphere(0.06), skin, Vector3(sx * 0.265 * big, 0.2, 0.0), Vector3.ZERO, false)
			Toon.part(head, Toon.sphere(0.05), skin.darkened(0.08), Vector3(0, 0.17, -0.265 * big), Vector3.ZERO, false)
			Toon.part(head, Toon.box(Vector3(0.1, 0.022, 0.02)), Color("6b2f24"), Vector3(0, 0.1, -0.25 * big), Vector3.ZERO, false)
			if kind == "orc":
				for sx in [-1.0, 1.0]:
					Toon.part(head, Toon.cyl(0.0, 0.04, 0.14), Color("f8fafc"), Vector3(sx * 0.09, 0.115, -0.255), Vector3(0.25, 0, 0), false)
				Toon.part(head, Toon.cyl(0.0, 0.05, 0.12), skin, Vector3(0.27, 0.28, 0.0), Vector3(0, 0, -1.2), false)
				Toon.part(head, Toon.cyl(0.0, 0.05, 0.12), skin, Vector3(-0.27, 0.28, 0.0), Vector3(0, 0, 1.2), false)
			else:
				_hair_visual(String(look.get("hair", "short")), _col(look.get("hair_c", "2b1b0e")))
				_beard_visual(String(look.get("beard", "none")), _col(look.get("beard_c", look.get("hair_c", "2b1b0e"))))


func _paint_visual(id: String) -> void:
	if kind != "human":
		return
	match id:
		"guerra":
			for sx in [-1.0, 1.0]:
				for i in 2:
					Toon.part(head, Toon.box(Vector3(0.1, 0.025, 0.02)), Color("dc2626"), Vector3(sx * 0.14, 0.15 - i * 0.04, -0.245), Vector3(0, 0, sx * 0.25), false)
		"tigre":
			for sx in [-1.0, 1.0]:
				for i in 3:
					Toon.part(head, Toon.box(Vector3(0.06, 0.022, 0.02)), Color("f97316"), Vector3(sx * (0.17 - i * 0.015), 0.28 - i * 0.05, -0.215), Vector3(0, sx * 0.5, sx * 0.6), false)
		"calavera":
			Toon.part(head, Toon.box(Vector3(0.28, 0.1, 0.02)), Color("f8fafc"), Vector3(0, 0.235, -0.245), Vector3.ZERO, false)
			Toon.part(head, Toon.box(Vector3(0.2, 0.04, 0.02)), Color("f8fafc"), Vector3(0, 0.09, -0.25), Vector3.ZERO, false)
		"rayo":
			Toon.glow(head, Toon.box(Vector3(0.05, 0.16, 0.02)), Color("fde047"), Vector3(0.1, 0.2, -0.255), Vector3(0, 0, 0.4))
			Toon.glow(head, Toon.box(Vector3(0.05, 0.12, 0.02)), Color("fde047"), Vector3(0.14, 0.13, -0.25), Vector3(0, 0, -0.5))


func _cape_visual(id: String) -> void:
	cape_node = null
	if not CAPES.has(id):
		return
	var c := _col(CAPES[id])
	cape_node = _pivot(body, Vector3(0, 0.78, 0.26))
	Toon.part(cape_node, Toon.box(Vector3(0.72, 1.15, 0.05)), c, Vector3(0, -0.57, 0.03))
	Toon.part(cape_node, Toon.box(Vector3(0.74, 0.07, 0.07)), c.lightened(0.3), Vector3(0, -1.12, 0.03), Vector3.ZERO, false)
	if id == "lobo":
		for i in 8:
			Toon.part(cape_node, Toon.cyl(0.0, 0.06, 0.16), c.lightened(0.25), Vector3(-0.3 + i * 0.085, 0.0, -0.01), Vector3(PI, 0, 0), false)


func _helmet_visual(id: String) -> void:
	if kind in ["knight", "skeleton", "minotaur", "demon", "titan"] and id == "none":
		return
	match id:
		"cuero":
			Toon.part(head, Toon.sphere(0.29, 0.42), Color("92602d"), Vector3(0, 0.36, 0))
			Toon.part(head, Toon.box(Vector3(0.62, 0.04, 0.06)), Color("5b3a1a"), Vector3(0, 0.3, -0.05), Vector3.ZERO, false)
		"bronce":
			Toon.part(head, Toon.sphere(0.3, 0.46), Color("cd7f32"), Vector3(0, 0.36, 0))
			Toon.part(head, Toon.box(Vector3(0.06, 0.2, 0.44)), Color("dc2626"), Vector3(0, 0.6, 0), Vector3.ZERO, false)
			for sx in [-1.0, 1.0]:
				Toon.part(head, Toon.box(Vector3(0.05, 0.22, 0.1)), Color("cd7f32"), Vector3(sx * 0.27, 0.16, -0.12), Vector3.ZERO, false)
		"hierro":
			Toon.part(head, Toon.sphere(0.31, 0.48), Color("94a3b8"), Vector3(0, 0.36, 0))
			Toon.part(head, Toon.box(Vector3(0.08, 0.17, 0.06)), Color("475569"), Vector3(0, 0.25, -0.31), Vector3.ZERO, false)
			for sx in [-1.0, 1.0]:
				Toon.part(head, Toon.cyl(0.0, 0.065, 0.32), Color("f1f5f9"), Vector3(sx * 0.31, 0.52, 0), Vector3(0, 0, -sx * 0.6), false)
				Toon.part(head, Toon.box(Vector3(0.05, 0.24, 0.12)), Color("94a3b8"), Vector3(sx * 0.28, 0.14, -0.1), Vector3.ZERO, false)
		"oro":
			Toon.part(head, Toon.sphere(0.31, 0.48), Color("fbbf24"), Vector3(0, 0.36, 0))
			Toon.part(head, Toon.box(Vector3(0.05, 0.32, 0.42)), Color("dc2626"), Vector3(0, 0.64, 0.02), Vector3(0.2, 0, 0), false)
			Toon.glow(head, Toon.sphere(0.045), Color("fde047"), Vector3(0, 0.3, -0.31))
			for sx in [-1.0, 1.0]:
				Toon.part(head, Toon.box(Vector3(0.05, 0.26, 0.12)), Color("fbbf24"), Vector3(sx * 0.28, 0.14, -0.1), Vector3.ZERO, false)


func _armor_visual(id: String, wide: float) -> void:
	var c := Color("92602d")
	match id:
		"none": return
		"bronce": c = Color("cd7f32")
		"hierro": c = Color("94a3b8")
		"oro": c = Color("fbbf24")
	Toon.part(body, Toon.cyl(0.29 * wide, 0.285 * wide, 0.52), c, Vector3(0, 0.45, 0))
	Toon.part(body, Toon.cyl(0.292 * wide, 0.292 * wide, 0.05), c.darkened(0.25), Vector3(0, 0.66, 0), Vector3.ZERO, false)
	Toon.part(body, Toon.cyl(0.292 * wide, 0.292 * wide, 0.05), c.darkened(0.25), Vector3(0, 0.3, 0), Vector3.ZERO, false)
	if id != "cuero":
		for sx in [-1.0, 1.0]:
			Toon.part(body, Toon.sphere(0.18), c, Vector3(sx * 0.38 * wide, 0.76, 0))
			Toon.part(body, Toon.sphere(0.07), c.lightened(0.35), Vector3(sx * 0.38 * wide, 0.84, 0), Vector3.ZERO, false)
	Toon.part(body, Toon.sphere(0.07), c.lightened(0.35), Vector3(0, 0.58, -0.29 * wide), Vector3.ZERO, false)


func _shield_visual(id: String) -> void:
	if id == "none":
		return
	var c := Color("8b5a2b")
	var rim := Color("5b3a1a")
	match id:
		"bronce":
			c = Color("cd7f32")
			rim = Color("92602d")
		"hierro":
			c = Color("94a3b8")
			rim = Color("475569")
		"oro":
			c = Color("fbbf24")
			rim = Color("b45309")
	var s := _pivot(fore_l, Vector3(-0.05, -0.18, -0.12))
	s.rotation = Vector3(0, PI / 2, 0)
	Toon.part(s, Toon.cyl(0.4, 0.4, 0.06), c, Vector3.ZERO, Vector3(PI / 2, 0, 0))
	Toon.part(s, Toon.torus(0.36, 0.43), rim, Vector3(0, 0, 0.03), Vector3(PI / 2, 0, 0), false)
	Toon.part(s, Toon.sphere(0.12), rim, Vector3(0, 0, -0.07), Vector3.ZERO, false)
	for i in 8:
		var a := i * TAU / 8.0
		Toon.part(s, Toon.sphere(0.03), rim.lightened(0.4), Vector3(cos(a) * 0.3, sin(a) * 0.3, -0.04), Vector3.ZERO, false)


func _kind_extras(skin: Color, cloth: Color) -> void:
	tail = null
	match kind:
		"lizard", "demon":
			tail = _pivot(body, Vector3(0, 0.05, 0.2))
			var tc := skin.darkened(0.15)
			Toon.part(tail, Toon.capsule(0.09, 0.5), tc, Vector3(0, -0.1, 0.25), Vector3(1.2, 0, 0))
			var t2 := _pivot(tail, Vector3(0, -0.2, 0.5))
			Toon.part(t2, Toon.capsule(0.06, 0.45), tc, Vector3(0, -0.05, 0.2), Vector3(1.0, 0, 0))
			if kind == "demon":
				Toon.part(t2, Toon.cyl(0.0, 0.08, 0.2), Color("1c1917"), Vector3(0, -0.1, 0.45), Vector3(PI / 2 + 0.8, 0, 0), false)
				for sx in [-1.0, 1.0]:
					Toon.part(body, Toon.box(Vector3(0.8, 0.55, 0.04)), Color("7f1d1d"), Vector3(sx * 0.6, 0.8, 0.3), Vector3(0, sx * 0.4, sx * 0.5))
		"troll":
			for p in [Vector3(0.15, 0.7, 0.28), Vector3(-0.2, 0.5, 0.27), Vector3(0.0, 0.3, 0.3)]:
				Toon.part(body, Toon.sphere(0.11), skin.darkened(0.2), p, Vector3.ZERO, false)
		"titan":
			for sx in [-1.0, 1.0]:
				Toon.glow(body, Toon.sphere(0.13), Color("38bdf8"), Vector3(sx * 0.38, 0.74, -0.1))


func _make_weapon(id: String) -> Node3D:
	var w := Node3D.new()
	var steel := Color("d1d5db")
	var wood := Color("6b4423")
	var gold := Color("fbbf24")
	match id:
		"espada_corta":
			Toon.part(w, Toon.cyl(0.032, 0.032, 0.2), wood, Vector3.ZERO, Vector3.ZERO, false)
			Toon.part(w, Toon.sphere(0.045), gold, Vector3(0, -0.11, 0), Vector3.ZERO, false)
			Toon.part(w, Toon.box(Vector3(0.28, 0.05, 0.07)), gold, Vector3(0, 0.11, 0), Vector3.ZERO, false)
			Toon.part(w, Toon.box(Vector3(0.1, 0.62, 0.028)), steel, Vector3(0, 0.45, 0))
			Toon.part(w, Toon.box(Vector3(0.02, 0.58, 0.03)), Color("f8fafc"), Vector3(0, 0.45, 0), Vector3.ZERO, false)
		"espada_larga":
			Toon.part(w, Toon.cyl(0.033, 0.033, 0.24), wood, Vector3.ZERO, Vector3.ZERO, false)
			Toon.part(w, Toon.sphere(0.05), gold, Vector3(0, -0.13, 0), Vector3.ZERO, false)
			Toon.part(w, Toon.box(Vector3(0.38, 0.06, 0.08)), gold, Vector3(0, 0.13, 0), Vector3.ZERO, false)
			Toon.part(w, Toon.box(Vector3(0.12, 1.0, 0.032)), Color("e5e7eb"), Vector3(0, 0.66, 0))
			Toon.part(w, Toon.box(Vector3(0.024, 0.96, 0.034)), Color("ffffff"), Vector3(0, 0.66, 0), Vector3.ZERO, false)
		"espada_fuego":
			Toon.part(w, Toon.cyl(0.033, 0.033, 0.24), Color("431407"), Vector3.ZERO, Vector3.ZERO, false)
			Toon.part(w, Toon.box(Vector3(0.4, 0.06, 0.08)), Color("7c2d12"), Vector3(0, 0.13, 0), Vector3.ZERO, false)
			Toon.part(w, Toon.box(Vector3(0.13, 1.05, 0.032)), Color("fb923c"), Vector3(0, 0.68, 0), Vector3.ZERO, false)
			Toon.glow(w, Toon.box(Vector3(0.22, 1.12, 0.07)), Color("f97316"), Vector3(0, 0.68, 0), Vector3.ZERO, 0.4)
		"hacha":
			Toon.part(w, Toon.cyl(0.036, 0.036, 0.72), wood, Vector3(0, 0.25, 0), Vector3.ZERO, false)
			Toon.part(w, Toon.box(Vector3(0.3, 0.32, 0.06)), steel, Vector3(0.13, 0.52, 0))
			Toon.part(w, Toon.box(Vector3(0.04, 0.34, 0.07)), Color("f8fafc"), Vector3(0.27, 0.52, 0), Vector3.ZERO, false)
		"hacha_doble":
			Toon.part(w, Toon.cyl(0.042, 0.042, 0.95), wood, Vector3(0, 0.35, 0), Vector3.ZERO, false)
			Toon.part(w, Toon.box(Vector3(0.32, 0.4, 0.06)), Color("9ca3af"), Vector3(0.18, 0.72, 0))
			Toon.part(w, Toon.box(Vector3(0.32, 0.4, 0.06)), Color("9ca3af"), Vector3(-0.18, 0.72, 0))
			Toon.part(w, Toon.sphere(0.07), gold, Vector3(0, 0.72, 0), Vector3.ZERO, false)
		"maza":
			Toon.part(w, Toon.cyl(0.042, 0.042, 0.7), wood, Vector3(0, 0.25, 0), Vector3.ZERO, false)
			Toon.part(w, Toon.sphere(0.2), Color("6b7280"), Vector3(0, 0.68, 0))
			for p in [Vector3(0.2, 0.68, 0), Vector3(-0.2, 0.68, 0), Vector3(0, 0.88, 0), Vector3(0, 0.68, 0.2), Vector3(0, 0.68, -0.2)]:
				Toon.part(w, Toon.cyl(0.0, 0.05, 0.12), Color("e5e7eb"), p, Vector3.ZERO, false)
		"lanza":
			Toon.part(w, Toon.cyl(0.03, 0.03, 1.5), wood, Vector3(0, 0.5, 0), Vector3.ZERO, false)
			Toon.part(w, Toon.cyl(0.0, 0.07, 0.32), steel, Vector3(0, 1.38, 0))
			Toon.part(w, Toon.cyl(0.05, 0.05, 0.05), Color("dc2626"), Vector3(0, 1.2, 0), Vector3.ZERO, false)
		"martillo":
			Toon.part(w, Toon.cyl(0.046, 0.046, 1.0), wood, Vector3(0, 0.38, 0), Vector3.ZERO, false)
			Toon.part(w, Toon.box(Vector3(0.52, 0.34, 0.32)), Color("4b5563"), Vector3(0, 0.95, 0))
			Toon.glow(w, Toon.box(Vector3(0.54, 0.06, 0.34)), Color("38bdf8"), Vector3(0, 0.95, 0), Vector3.ZERO, 0.7)
		_:
			Toon.part(w, Toon.box(Vector3(0.09, 0.62, 0.025)), steel, Vector3(0, 0.45, 0))
	return w


# ---------- Animación ----------
func _process(delta: float) -> void:
	if model == null:
		return
	t += delta
	if cape_node:
		cape_node.rotation.x = 0.12 + sin(t * 3.0 + phase) * 0.08 + (0.0 if not busy else 0.45)
	if dead:
		return
	if not busy:
		model.position.y = sin(t * 2.2 + phase) * 0.03
		body.rotation.x = lerpf(body.rotation.x, sin(t * 2.2 + phase) * 0.03, 0.2)
		var tgt_l := Vector2(1.55, 1.55) if guard else POSE_L
		arm_l.rotation.x = lerpf(arm_l.rotation.x, tgt_l.x + sin(t * 2.0 + phase) * 0.05, 0.15)
		fore_l.rotation.x = lerpf(fore_l.rotation.x, tgt_l.y, 0.15)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, POSE_R.x + sin(t * 2.0 + phase + 1.0) * 0.05, 0.15)
		fore_r.rotation.x = lerpf(fore_r.rotation.x, POSE_R.y, 0.15)
		model.rotation.y = lerpf(model.rotation.y, 0.0, 0.2)
		body.rotation.y = lerpf(body.rotation.y, 0.0, 0.2)
		head.rotation.x = lerpf(head.rotation.x, 0.0, 0.2)
	if tail:
		tail.rotation.y = sin(t * 3.0 + phase) * 0.3


func _tw() -> Tween:
	return create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _rest_pose(d: float) -> void:
	var tw := _tw()
	tw.tween_property(arm_r, "rotation:x", POSE_R.x, d)
	tw.tween_property(fore_r, "rotation:x", POSE_R.y, d)
	tw.tween_property(body, "rotation:x", 0.0, d)
	tw.tween_property(body, "rotation:y", 0.0, d)
	tw.tween_property(model, "rotation:y", 0.0, d)
	await tw.finished


func attack(style: String, reach: float, on_strike: Callable) -> void:
	busy = true
	var start := position
	var fwd := -global_transform.basis.z
	var lunge := start + fwd * reach
	var tw := _tw()
	match style:
		"high":
			tw.tween_property(arm_r, "rotation:x", 3.1, 0.28)
			tw.tween_property(fore_r, "rotation:x", 0.5, 0.28)
			tw.tween_property(body, "rotation:x", -0.3, 0.28)
		"mid":
			tw.tween_property(arm_r, "rotation:x", 1.5, 0.22)
			tw.tween_property(fore_r, "rotation:x", 0.4, 0.22)
			tw.tween_property(body, "rotation:y", 1.0, 0.22)
		"low":
			tw.tween_property(arm_r, "rotation:x", 0.9, 0.16)
			tw.tween_property(fore_r, "rotation:x", 2.2, 0.16)
			tw.tween_property(body, "rotation:x", -0.12, 0.16)
		"spin":
			tw.tween_property(arm_r, "rotation:x", 1.5, 0.2)
			tw.tween_property(fore_r, "rotation:x", 0.3, 0.2)
			tw.tween_property(model, "position:y", 0.2, 0.2)
		_:
			tw.tween_property(arm_r, "rotation:x", 3.0, 0.3)
			tw.tween_property(fore_r, "rotation:x", 0.4, 0.3)
			tw.tween_property(model, "position:y", 0.45, 0.3)
	await tw.finished
	var tw2 := _tw()
	tw2.tween_property(self, "position", lunge, 0.13)
	match style:
		"high":
			tw2.tween_property(arm_r, "rotation:x", 0.3, 0.13)
			tw2.tween_property(fore_r, "rotation:x", 0.1, 0.13)
			tw2.tween_property(body, "rotation:x", 0.4, 0.13)
		"mid":
			tw2.tween_property(arm_r, "rotation:x", 1.5, 0.13)
			tw2.tween_property(body, "rotation:y", -1.0, 0.13)
		"low":
			tw2.tween_property(arm_r, "rotation:x", 1.4, 0.11)
			tw2.tween_property(fore_r, "rotation:x", 0.15, 0.11)
		"spin":
			tw2.tween_property(model, "rotation:y", -TAU, 0.3)
		_:
			tw2.tween_property(arm_r, "rotation:x", 0.2, 0.14)
			tw2.tween_property(fore_r, "rotation:x", 0.1, 0.14)
			tw2.tween_property(model, "position:y", 0.0, 0.14)
			tw2.tween_property(body, "rotation:x", 0.5, 0.14)
	await get_tree().create_timer(0.1).timeout
	on_strike.call()
	await tw2.finished
	await get_tree().create_timer(0.12).timeout
	model.rotation.y = 0.0
	var tw3 := _tw()
	tw3.tween_property(self, "position", start, 0.3)
	await tw3.finished
	await _rest_pose(0.18)
	busy = false


func hit_react(strong: bool = false) -> void:
	if dead:
		return
	busy = true
	var back := global_transform.basis.z * (0.5 if strong else 0.3)
	var start := position
	var tw := _tw()
	tw.tween_property(self, "position", start + back, 0.1)
	tw.tween_property(body, "rotation:x", -0.5, 0.1)
	tw.tween_property(head, "rotation:x", -0.4, 0.1)
	await tw.finished
	var tw2 := _tw()
	tw2.tween_property(self, "position", start, 0.28)
	tw2.tween_property(body, "rotation:x", 0.0, 0.28)
	await tw2.finished
	busy = false


func block_react() -> void:
	if dead:
		return
	busy = true
	var tw := _tw()
	tw.tween_property(arm_l, "rotation:x", 1.6, 0.1)
	tw.tween_property(fore_l, "rotation:x", 1.6, 0.1)
	tw.tween_property(body, "rotation:x", -0.18, 0.1)
	await tw.finished
	await get_tree().create_timer(0.22).timeout
	var tw2 := _tw()
	tw2.tween_property(body, "rotation:x", 0.0, 0.2)
	await tw2.finished
	busy = false


func dodge_react() -> void:
	if dead:
		return
	busy = true
	var start := position
	var side := global_transform.basis.x * 0.7
	var tw := _tw()
	tw.tween_property(self, "position", start + side, 0.14)
	tw.tween_property(body, "rotation:z", -0.4, 0.14)
	await tw.finished
	var tw2 := _tw()
	tw2.tween_property(self, "position", start, 0.25)
	tw2.tween_property(body, "rotation:z", 0.0, 0.25)
	await tw2.finished
	busy = false


func die() -> void:
	dead = true
	var tw := _tw()
	tw.tween_property(model, "rotation:x", -1.5, 0.6).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_property(model, "position:y", 0.25, 0.6)
	tw.tween_property(arm_r, "rotation:x", 2.6, 0.4)
	tw.tween_property(arm_l, "rotation:x", 2.2, 0.4)
	await tw.finished


func victory() -> void:
	busy = true
	for i in 3:
		var tw := _tw()
		tw.tween_property(arm_r, "rotation:x", 3.1, 0.2)
		tw.tween_property(fore_r, "rotation:x", 0.2, 0.2)
		tw.tween_property(arm_l, "rotation:x", 3.1, 0.2)
		tw.tween_property(fore_l, "rotation:x", 0.2, 0.2)
		tw.tween_property(model, "position:y", 0.35, 0.2)
		await tw.finished
		var tw2 := _tw()
		tw2.tween_property(model, "position:y", 0.0, 0.2)
		await tw2.finished


func drink() -> void:
	busy = true
	var tw := _tw()
	tw.tween_property(arm_r, "rotation:x", 2.6, 0.25)
	tw.tween_property(fore_r, "rotation:x", 2.0, 0.25)
	tw.tween_property(head, "rotation:x", -0.5, 0.25)
	await tw.finished
	await get_tree().create_timer(0.45).timeout
	await _rest_pose(0.2)
	busy = false


func pray() -> void:
	busy = true
	var tw := _tw()
	tw.tween_property(arm_r, "rotation:x", 3.0, 0.3)
	tw.tween_property(arm_l, "rotation:x", 3.0, 0.3)
	tw.tween_property(fore_r, "rotation:x", 0.3, 0.3)
	tw.tween_property(fore_l, "rotation:x", 0.3, 0.3)
	tw.tween_property(model, "position:y", 0.2, 0.3)
	await tw.finished
	await get_tree().create_timer(0.4).timeout
	var tw2 := _tw()
	tw2.tween_property(model, "position:y", 0.0, 0.2)
	await tw2.finished
	await _rest_pose(0.2)
	busy = false
