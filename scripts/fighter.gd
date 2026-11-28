extends Node3D
## Luchador 2D estilo "Swords & Sandals": figura vectorial de frente con contorno grueso.
## Se dibuja con nodos 2D dentro de un SubViewport y se muestra en un Sprite3D,
## así sigue usando la cámara, las posiciones y los efectos 3D del combate.

signal swung
signal stepped

const Toon = preload("res://scripts/toon.gd")
const BodyArt = preload("res://scripts/body_art.gd")

const PX := 190.0
const VP := Vector2i(1140, 1216)
const FEET := Vector2(570, 1100)
const INK := Color("1c1208")
const OL := 0.016
const STEEL := Color("cbd5e1")
const WOOD := Color("7a4e22")
const GOLD := Color("fbbf24")

const OUTFITS := {
	"romana": {"cloth": "b91c1c", "trim": "fbbf24", "style": "tunic"},
	"toga": {"cloth": "f1f5f9", "trim": "a855f7", "style": "toga"},
	"pieles": {"cloth": "78350f", "trim": "d6c7a1", "style": "fur"},
	"gala": {"cloth": "6d28d9", "trim": "fbbf24", "style": "tunic"},
	"sombras": {"cloth": "111827", "trim": "dc2626", "style": "tunic"},
	"espartano": {"cloth": "7f1d1d", "trim": "cd7f32", "style": "tunic"},
}
const CAPES := {"roja": "dc2626", "azul": "2563eb", "negra": "18181b", "dorada": "fbbf24", "lobo": "78716c"}

# poses (rotación del brazo, rotación del antebrazo)
const REST_R := Vector2(-0.45, -2.2)
const REST_L := Vector2(0.32, 2.4)
const GUARD_L := Vector2(0.0, -1.84)
const FREE_R := Vector2(-0.16, -0.08)
const FREE_L := Vector2(0.16, 0.08)

var look: Dictionary = {}
var kind := "human"
var scl := 1.0
var busy := false
var dead := false
var guard := false
var relaxed := false
var moving := false
var walking := false
var t := 0.0
var phase := 0.0
var dir := 1.0
var expr := 0
var health_ratio := 1.0
var shield_ratio := 1.0
var shield_broken := false
var blood_col := Color("b91c1c")
var orb: Node3D

# partes 2D
var vp: SubViewport
var sprite: Sprite3D
var stage: Node2D
var model: Node2D
var body: Node2D
var head: Node2D
var arm_r: Node2D
var fore_r: Node2D
var arm_l: Node2D
var fore_l: Node2D
var leg_l: Node2D
var leg_r: Node2D
var cape_node: Node2D
var tail: Node2D
var p_head: Node2D
var p_body: Node2D
var p_fore_r: Node2D
var p_fore_l: Node2D
var p_weapon: Node2D
var weapon_id := "espada_corta"
var potion_col := Color(0, 0, 0, 0)
var _step_sign := 1.0
var _dust_t := 0.0
var leg_rest := 0.06

# apariencia
var skin := Color("c68642")
var cloth := Color("1d4ed8")
var trim := Color("fbbf24")
var outfit_style := "tunic"
var ww := 1.0
var hh := 1.0
var wide := 1.0
var thick := 1.0
var bone := false
var monster := false
var leather := Color("6b4423")


class P extends Node2D:
	var fn: Callable

	func _draw() -> void:
		if fn.is_valid():
			fn.call(self)


func _ready() -> void:
	phase = randf() * 6.0


func _col(s: Variant, fallback: String = "ffffff") -> Color:
	return Color(String(s)) if String(s) != "" else Color(fallback)


# ======================= Primitivas de dibujo =======================
func _poly(c: CanvasItem, pts: PackedVector2Array, fill: Color, ol: float = OL) -> void:
	c.draw_colored_polygon(pts, fill)
	if ol <= 0.0:
		return
	var closed := pts.duplicate()
	closed.append(pts[0])
	c.draw_polyline(closed, INK, ol * 2.0, false)
	for v in pts:
		c.draw_circle(v, ol, INK)


func _ell(c: CanvasItem, p: Vector2, rx: float, ry: float, fill: Color, ol: float = OL, rot: float = 0.0) -> void:
	if ol > 0.0:
		c.draw_set_transform(p, rot, Vector2(1, 1))
		c.draw_colored_polygon(_ell_pts(rx + ol, ry + ol), INK)
	c.draw_set_transform(p, rot, Vector2(1, 1))
	c.draw_colored_polygon(_ell_pts(rx, ry), fill)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 1))


func _ell_pts(rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 44:
		var a := TAU * float(i) / 44.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _cap(c: CanvasItem, a: Vector2, b: Vector2, r: float, fill: Color, ol: float = OL, shade: bool = true) -> void:
	if ol > 0.0:
		c.draw_line(a, b, INK, (r + ol) * 2.0, false)
		c.draw_circle(a, r + ol, INK)
		c.draw_circle(b, r + ol, INK)
	c.draw_line(a, b, fill, r * 2.0, false)
	c.draw_circle(a, r, fill)
	c.draw_circle(b, r, fill)
	if shade:
		var off := Vector2(r * 0.38, 0)
		c.draw_line(a + off, b + off, fill.darkened(0.2), r * 0.8, false)


## Extremidad afilada con músculo (bíceps / pantorrilla) en vez de cápsula.
func _limb(c: CanvasItem, a: Vector2, b: Vector2, r0: float, r1: float, fill: Color, bulge: float = 0.3, at: float = 0.4) -> void:
	var ax := (b - a)
	var n := Vector2(-ax.y, ax.x).normalized()
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var N := 8
	for i in N + 1:
		var t := float(i) / N
		var r := lerpf(r0, r1, t) * (1.0 + bulge * exp(-pow((t - at) / 0.28, 2.0)))
		var p := a + ax * t
		left.append(p + n * r)
		right.append(p - n * r)
	right.reverse()
	left.append_array(right)
	_poly(c, left, fill, OL)
	# sombra y brillo del músculo
	var sh := PackedVector2Array()
	for i in N + 1:
		var t := float(i) / N
		var r := lerpf(r0, r1, t) * (1.0 + bulge * exp(-pow((t - at) / 0.28, 2.0)))
		sh.append(a + ax * t - n * r * 0.98)
	for i in range(N, -1, -1):
		var t := float(i) / N
		var r := lerpf(r0, r1, t) * (1.0 + bulge * exp(-pow((t - at) / 0.28, 2.0)))
		sh.append(a + ax * t - n * r * 0.45)
	c.draw_colored_polygon(sh, Color(0, 0, 0, 0.15))
	var mid := a + ax * at
	c.draw_line(mid + n * r0 * 0.5, mid + ax * 0.22 + n * r0 * 0.45, fill.lightened(0.22), r0 * 0.22, false)


func _line(c: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	c.draw_line(a, b, col, w, false)


func _mk(parent: Node2D, pos: Vector2, fn: Callable) -> P:
	var n := P.new()
	n.position = pos
	n.fn = fn
	parent.add_child(n)
	return n


func _piv(parent: Node2D, pos: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	parent.add_child(n)
	return n


# ======================= Construcción =======================
func setup(l: Dictionary) -> void:
	look = l
	for ch in get_children():
		ch.queue_free()
	orb = null
	kind = String(l.get("kind", "human"))
	scl = float(l.get("scale", 1.0))
	hh = float(l.get("height", 1.0))
	ww = float(l.get("fat", 1.0))
	weapon_id = String(l.get("weapon", "espada_corta"))
	skin = _col(l.get("skin", "c68642"))
	cloth = _col(l.get("cloth", "1d4ed8"))
	trim = GOLD
	outfit_style = "tunic"
	var oid := String(l.get("outfit", "none"))
	if OUTFITS.has(oid) and kind in ["human", "elf", "dwarf"]:
		cloth = _col(OUTFITS[oid].cloth)
		trim = _col(OUTFITS[oid].trim)
		outfit_style = String(OUTFITS[oid].style)
	bone = kind == "skeleton"
	monster = kind in ["orc", "troll", "lizard", "minotaur", "demon", "titan"]
	wide = 0.88
	thick = 0.9
	match kind:
		"troll":
			wide = 1.1
			thick = 1.15
		"elf":
			wide = 0.8
			thick = 0.82
		"dwarf":
			wide = 1.0
			thick = 1.08
		"skeleton":
			thick = 0.6
		"orc", "minotaur", "demon", "titan":
			wide = 0.97
			thick = 1.0
		"knight":
			wide = 0.95
	leg_rest = 0.06 if not _anat() else -0.04
	blood_col = Color("b91c1c")
	match kind:
		"demon": blood_col = Color("581c87")
		"lizard": blood_col = Color("15803d")
		"skeleton": blood_col = Color("4b5563")
		"knight", "titan": blood_col = Color("1f2937")
	dead = false
	busy = false
	guard = false
	shield_broken = false
	health_ratio = 1.0
	shield_ratio = 1.0
	expr = 0
	potion_col = Color(0, 0, 0, 0)
	# viewport + sprite
	vp = SubViewport.new()
	vp.size = VP
	vp.transparent_bg = true
	vp.disable_3d = true
	
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	stage = Node2D.new()
	stage.position = FEET
	stage.scale = Vector2(PX, PX) * scl * 1.12
	vp.add_child(stage)
	sprite = Sprite3D.new()
	sprite.texture = vp.get_texture()
	sprite.pixel_size = 1.0 / PX
	sprite.offset = Vector2(0, FEET.y - VP.y * 0.5)
	sprite.shaded = false
	sprite.transparent = true
	sprite.double_sided = true
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.top_level = true
	add_child(sprite)
	busy_weapon_hidden = false
	sprite.global_position = global_position
	_build_rig()
	_pose_now()


func _hip() -> float:
	return -0.92 * hh


func _build_rig() -> void:
	_mk(stage, Vector2.ZERO, _p_shadow)
	model = _piv(stage, Vector2.ZERO)
	var hip := _hip()
	# capa (detrás de todo)
	cape_node = null
	var cid := String(look.get("cape", "none"))
	if CAPES.has(cid):
		cape_node = _piv(model, Vector2(0, hip - 0.5 * hh))
		_mk(cape_node, Vector2.ZERO, _p_cape.bind(_col(CAPES[cid]), cid))
	# cola y alas
	tail = null
	if kind in ["lizard", "demon"]:
		tail = _piv(model, Vector2(0, hip))
		_mk(tail, Vector2.ZERO, _p_tail)
	if kind == "demon":
		_mk(model, Vector2(0, hip - 0.4 * hh), _p_wings)
	# piernas
	leg_l = _piv(model, Vector2(-0.15 * ww * wide, hip))
	leg_r = _piv(model, Vector2(0.15 * ww * wide, hip))
	_mk(leg_l, Vector2.ZERO, _p_leg.bind(-1.0))
	_mk(leg_r, Vector2.ZERO, _p_leg.bind(1.0))
	# tronco
	body = _piv(model, Vector2(0, hip))
	p_body = _mk(body, Vector2.ZERO, _p_torso)
	# brazo del escudo (izquierda local), detrás de la cabeza
	var sh_x := (0.385 if _anat() else 0.41) * ww * wide
	arm_l = _piv(body, Vector2(-sh_x, -0.56 * hh))
	_mk(arm_l, Vector2.ZERO, _p_arm.bind(-1.0))
	fore_l = _piv(arm_l, Vector2(0, 0.36))
	p_fore_l = _mk(fore_l, Vector2.ZERO, _p_fore.bind(-1.0))
	# cabeza
	head = _piv(body, Vector2(0, -0.68 * hh))
	head.scale = Vector2(0.9, 0.9)
	p_head = _mk(head, Vector2(0, -0.2), _p_head)
	# brazo del arma (derecha local = hacia el rival)
	arm_r = _piv(body, Vector2(sh_x, -0.56 * hh))
	_mk(arm_r, Vector2.ZERO, _p_arm.bind(1.0))
	fore_r = _piv(arm_r, Vector2(0, 0.36))
	p_fore_r = _mk(fore_r, Vector2.ZERO, _p_fore.bind(1.0))
	var holder := _piv(fore_r, Vector2(0, 0.34))
	holder.rotation = PI
	p_weapon = _mk(holder, Vector2.ZERO, _p_weapon_held)


func _pose_now() -> void:
	arm_r.rotation = REST_R.x
	fore_r.rotation = REST_R.y
	arm_l.rotation = REST_L.x
	fore_l.rotation = REST_L.y
	leg_l.rotation = -leg_rest
	leg_r.rotation = leg_rest
	model.scale.x = dir


# ======================= Dibujo: partes =======================
func _p_shadow(c: CanvasItem) -> void:
	c.draw_set_transform(Vector2(0, 0.02), 0.0, Vector2(1, 1))
	c.draw_colored_polygon(_ell_pts(0.62 * ww * wide, 0.11), Color(0.1, 0.05, 0.0, 0.34))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 1))


func _p_leg(c: CanvasItem, side: float) -> void:
	if _anat():
		BodyArt.leg(c, skin, side, _fxl(), hh)
		BodyArt.foot(c, Color("5b4630"), side, _fxl(), hh)
		return
	var L := -_hip()
	var r := 0.135 * thick * (0.9 + 0.1 * ww)
	var boot_c := Color("3f2a14")
	var cloth_c := skin
	if kind == "knight":
		cloth_c = Color("475569")
		boot_c = Color("334155")
	var knee := Vector2(0.0, L * 0.52)
	var ank := Vector2(0.0, L - 0.1)
	if bone:
		_cap(c, Vector2.ZERO, knee, r, cloth_c)
		_cap(c, knee, ank, r * 0.82, cloth_c)
	else:
		_limb(c, Vector2.ZERO, knee, r * 1.35, r * 0.95, cloth_c, 0.18, 0.3)
		_limb(c, knee - Vector2(0, 0.02), ank, r * 1.0, r * 0.62, cloth_c, 0.5, 0.25)
		_ell(c, knee, r * 0.95, r * 0.8, cloth_c.lightened(0.04), 0.0)
	if bone:
		for i in 3:
			_line(c, Vector2(-0.06, L * 0.3 + i * 0.12), Vector2(0.06, L * 0.3 + i * 0.12), 0.025, INK)
	# bota
	if not bone:
		var by := L - 0.34
		var pts := PackedVector2Array([Vector2(-side * 0.12, by), Vector2(side * 0.12, by), Vector2(side * 0.13, L - 0.12), Vector2(side * 0.27, L - 0.07), Vector2(side * 0.28, L), Vector2(-side * 0.12, L), Vector2(-side * 0.12, L - 0.12)])
		_poly(c, pts, boot_c)
		_line(c, Vector2(-0.11, by + 0.1), Vector2(0.11, by + 0.1), 0.035, boot_c.lightened(0.25))
	else:
		_ell(c, Vector2(0.1 * side, L - 0.04), 0.17, 0.06, skin)


func _p_torso(c: CanvasItem) -> void:
	var w := ww * wide
	var wst := 0.25 * w
	var chw := 0.35 * w
	var shw := 0.41 * w
	var top := -0.64 * hh
	if bone:
		_p_ribcage(c)
		_p_skirt(c)
		return
	if _anat():
		_torso_anat(c, w)
	else:
		_torso_old(c, w, wst, chw, shw, top)
	# heridas
	_p_wounds_body(c, w)
	# prendas
	if kind == "human" and not _anat() and outfit_style != "toga" and outfit_style != "fur":
		for s in [-1.0, 1.0]:
			_line(c, Vector2(s * shw * 0.62, -0.58 * hh), Vector2(-s * wst * 0.8, -0.03), 0.075, leather)
			_line(c, Vector2(s * shw * 0.62, -0.58 * hh), Vector2(-s * wst * 0.8, -0.03), 0.02, leather.lightened(0.25))
		if outfit_style == "tunic" and String(look.get("outfit", "none")) != "none":
			var tp := PackedVector2Array([Vector2(-wst * 1.04, 0.02), Vector2(-chw * 0.96, -0.46 * hh), Vector2(-shw * 0.74, -0.56 * hh), Vector2(-0.16, top + 0.03), Vector2(0.16, top + 0.03), Vector2(shw * 0.74, -0.56 * hh), Vector2(chw * 0.96, -0.46 * hh), Vector2(wst * 1.04, 0.02)])
			_poly(c, tp, cloth)
			_line(c, Vector2(-0.16, top + 0.05), Vector2(0.16, top + 0.05), 0.04, trim)
			_line(c, Vector2(-wst, -0.01), Vector2(wst, -0.01), 0.04, trim)
	_p_armor(c, w, wst, chw, shw)
	_p_skirt(c)


func _torso_old(c: CanvasItem, w: float, wst: float, chw: float, shw: float, top: float) -> void:
	var sk := skin
	if kind == "knight":
		sk = Color("4b5563")
	var pts := PackedVector2Array([Vector2(-wst, 0.03), Vector2(-wst * 1.05, -0.22 * hh), Vector2(-chw, -0.48 * hh), Vector2(-shw, -0.58 * hh), Vector2(-0.14, top), Vector2(0.14, top), Vector2(shw, -0.58 * hh), Vector2(chw, -0.48 * hh), Vector2(wst * 1.05, -0.22 * hh), Vector2(wst, 0.03)])
	_poly(c, pts, sk)
	# sombra del lado derecho
	c.draw_colored_polygon(PackedVector2Array([Vector2(chw * 0.7, -0.5 * hh), Vector2(chw, -0.48 * hh), Vector2(wst * 1.05, -0.22 * hh), Vector2(wst, 0.03), Vector2(wst * 0.72, 0.03), Vector2(wst * 0.78, -0.24 * hh)]), Color(0, 0, 0, 0.16))
	# cuello
	_ell(c, Vector2(0, top + 0.02), 0.11 * w, 0.08, sk.darkened(0.05), 0.0)
	var human_like := kind in ["human", "orc", "troll", "minotaur", "lizard", "demon", "titan"]
	if human_like:
		# trapecios y pectorales
		for sx in [-1.0, 1.0]:
			_ell(c, Vector2(sx * 0.2 * w, -0.6 * hh), 0.13 * w, 0.06, sk.lightened(0.04), 0.0)
			_ell(c, Vector2(sx * 0.15 * w, -0.43 * hh), 0.15 * w, 0.1, sk.lightened(0.07), 0.016)
			for k in 3:
				_ell(c, Vector2(sx * 0.07 * w, (-0.32 + k * 0.1) * hh), 0.07 * w, 0.042, sk.lightened(0.04), 0.012)
		var belly := clampf((ww - 1.0) / 0.5, 0.0, 1.0)
		if belly > 0.05:
			_ell(c, Vector2(0, -0.12 * hh), wst * (1.08 + 0.3 * belly), 0.17 + 0.13 * belly, sk, OL)
			_ell(c, Vector2(0, -0.1 * hh), 0.025, 0.02, sk.darkened(0.3), 0.0)
		if kind == "troll":
			for pp in [Vector2(0.12, -0.45), Vector2(-0.18, -0.3), Vector2(0.05, -0.15)]:
				_ell(c, pp * Vector2(w, hh), 0.07, 0.06, sk.darkened(0.2), 0.016)
		if kind == "lizard":
			for k in 4:
				_ell(c, Vector2(0, (-0.5 + k * 0.12) * hh), 0.1 * w, 0.04, sk.lightened(0.18), 0.012)
		if kind == "demon":
			_line(c, Vector2(-0.12, -0.45 * hh), Vector2(0.1, -0.2 * hh), 0.02, Color("7f1d1d"))
		if kind == "titan":
			for sx in [-1.0, 1.0]:
				c.draw_circle(Vector2(sx * 0.4 * w, -0.58 * hh), 0.12, Color("38bdf8"))
				c.draw_circle(Vector2(sx * 0.4 * w, -0.58 * hh), 0.07, Color("e0f2fe"))
	if kind == "knight":
		_line(c, Vector2(0, -0.6 * hh), Vector2(0, -0.05), 0.03, INK)
		for k in 3:
			_line(c, Vector2(-chw * 0.8, (-0.45 + k * 0.14) * hh), Vector2(chw * 0.8, (-0.45 + k * 0.14) * hh), 0.025, INK)
		for sx in [-1.0, 1.0]:
			_ell(c, Vector2(sx * shw, -0.58 * hh), 0.17, 0.14, Color("64748b"))
	var lean := clampf((1.0 - ww) / 0.3, 0.0, 1.0)
	if lean > 0.2 and kind == "human":
		for k in 4:
			_line(c, Vector2(-chw * 0.7, (-0.5 + k * 0.05) * hh), Vector2(chw * 0.7, (-0.5 + k * 0.05) * hh), 0.014, sk.darkened(0.3))


## ¿Usa la anatomía nueva (curvas suaves)? Todos menos esqueleto y caballero.
func _anat() -> bool:
	return not bone and kind != "knight"


func _fxl() -> float:
	return 1.2 * thick / 0.9 * (0.9 + 0.1 * ww)


func _torso_anat(c: CanvasItem, w: float) -> void:
	var fx := 1.15 * w / 0.88
	BodyArt.torso(c, skin, fx, hh)
	var sk := skin
	var belly := clampf((ww - 1.0) / 0.5, 0.0, 1.0)
	if belly > 0.05:
		_ell(c, Vector2(0, -0.12 * hh), 0.25 * w * (1.08 + 0.3 * belly), 0.17 + 0.13 * belly, sk, OL)
		_ell(c, Vector2(0, -0.1 * hh), 0.025, 0.02, sk.darkened(0.3), 0.0)
	if kind == "troll":
		for pp in [Vector2(0.12, -0.45), Vector2(-0.18, -0.3), Vector2(0.05, -0.15)]:
			_ell(c, pp * Vector2(w, hh), 0.07, 0.06, sk.darkened(0.2), 0.016)
	if kind == "lizard":
		for k in 4:
			_ell(c, Vector2(0, (-0.5 + k * 0.12) * hh), 0.1 * w, 0.04, sk.lightened(0.18), 0.012)
	if kind == "demon":
		_line(c, Vector2(-0.12, -0.45 * hh), Vector2(0.1, -0.2 * hh), 0.02, Color("7f1d1d"))
	if kind == "titan":
		for sx in [-1.0, 1.0]:
			c.draw_circle(Vector2(sx * 0.4 * w, -0.58 * hh), 0.12, Color("38bdf8"))
			c.draw_circle(Vector2(sx * 0.4 * w, -0.58 * hh), 0.07, Color("e0f2fe"))


func _p_wounds_body(c: CanvasItem, w: float) -> void:
	if health_ratio < 0.75:
		_line(c, Vector2(0.08 * w, -0.52 * hh), Vector2(0.24 * w, -0.4 * hh), 0.03, blood_col)
		_line(c, Vector2(0.12 * w, -0.5 * hh), Vector2(0.2 * w, -0.43 * hh), 0.012, Color("fecaca"))
	if health_ratio < 0.5:
		_line(c, Vector2(-0.22 * w, -0.46 * hh), Vector2(-0.05 * w, -0.3 * hh), 0.034, blood_col)
		_line(c, Vector2(-0.12 * w, -0.38 * hh), Vector2(-0.12 * w, -0.2 * hh), 0.03, blood_col)
		_ell(c, Vector2(0.08 * w, -0.18 * hh), 0.07, 0.05, Color("7c3aed").darkened(0.2), 0.0)
	if health_ratio < 0.25:
		_line(c, Vector2(-0.28 * w, -0.5 * hh), Vector2(0.3 * w, -0.32 * hh), 0.04, blood_col)
		_ell(c, Vector2(0.0, -0.1 * hh), 0.1, 0.08, blood_col, 0.0)
		for k in 3:
			_line(c, Vector2((-0.1 + k * 0.1) * w, -0.1 * hh), Vector2((-0.1 + k * 0.1) * w, 0.0), 0.022, blood_col)


func _p_ribcage(c: CanvasItem) -> void:
	_line(c, Vector2(0, -0.62 * hh), Vector2(0, 0.02), 0.09, INK)
	_line(c, Vector2(0, -0.62 * hh), Vector2(0, 0.02), 0.06, Color("e2e8f0"))
	for k in 5:
		var y := (-0.55 + k * 0.1) * hh
		var wd := 0.27 - absf(k - 1.0) * 0.03
		for sx in [-1.0, 1.0]:
			c.draw_arc(Vector2(sx * 0.02, y), wd, PI * (0.1 if sx > 0 else 0.9), PI * (0.1 if sx > 0 else 0.9) + (-1.0 if sx > 0 else 1.0) * PI * 0.5, 10, INK, 0.07, false)
			c.draw_arc(Vector2(sx * 0.02, y), wd, PI * (0.1 if sx > 0 else 0.9), PI * (0.1 if sx > 0 else 0.9) + (-1.0 if sx > 0 else 1.0) * PI * 0.5, 10, Color("e2e8f0"), 0.04, false)
	_ell(c, Vector2(0, 0.0), 0.2, 0.08, Color("e2e8f0"))
	for sx in [-1.0, 1.0]:
		_ell(c, Vector2(sx * 0.26, -0.58 * hh), 0.09, 0.08, Color("e2e8f0"))


func _p_skirt(c: CanvasItem) -> void:
	var w := ww * wide
	var wst := 0.26 * w
	var len := 0.3 if _anat() else 0.4
	var bot := 0.34 * w
	var col := cloth
	if outfit_style == "toga":
		len = 0.9
		bot = 0.33 * w
	if kind == "knight":
		col = Color("1f2937")
	if bone:
		col = cloth
	var pts := PackedVector2Array([Vector2(-wst, -0.02), Vector2(wst, -0.02), Vector2(bot, len), Vector2(bot * 0.5, len + 0.04), Vector2(0, len), Vector2(-bot * 0.5, len + 0.04), Vector2(-bot, len)])
	_poly(c, pts, col)
	c.draw_colored_polygon(PackedVector2Array([Vector2(wst * 0.3, 0.0), Vector2(wst, 0.0), Vector2(bot, len), Vector2(bot * 0.5, len + 0.03)]), Color(0, 0, 0, 0.15))
	for k in 3:
		_line(c, Vector2((-0.1 + k * 0.1) * w, 0.04), Vector2((-0.16 + k * 0.16) * w, len - 0.02), 0.014, col.darkened(0.3))
	_line(c, Vector2(-bot + 0.02, len - 0.03), Vector2(bot - 0.02, len - 0.03), 0.04, trim)
	if outfit_style == "fur":
		for k in 7:
			var x := -bot + (k + 0.5) * bot * 2.0 / 7.0
			_poly(c, PackedVector2Array([Vector2(x - 0.07, len - 0.02), Vector2(x + 0.07, len - 0.02), Vector2(x, len + 0.12)]), trim, 0.016)
	# cinturón
	_poly(c, PackedVector2Array([Vector2(-wst * 1.05, -0.09), Vector2(wst * 1.05, -0.09), Vector2(wst * 1.05, 0.05), Vector2(-wst * 1.05, 0.05)]), leather.darkened(0.15))
	_poly(c, PackedVector2Array([Vector2(-0.07, -0.08), Vector2(0.07, -0.08), Vector2(0.07, 0.04), Vector2(-0.07, 0.04)]), trim, 0.02)
	if outfit_style == "toga":
		_poly(c, PackedVector2Array([Vector2(0.3 * w, -0.58 * hh), Vector2(0.4 * w, -0.5 * hh), Vector2(-0.2 * w, 0.0), Vector2(-0.34 * w, -0.02)]), cloth.lightened(0.05))
		_line(c, Vector2(0.32 * w, -0.55 * hh), Vector2(-0.26 * w, -0.0), 0.04, trim)
	if outfit_style == "fur":
		for k in 9:
			var a := PI + 0.2 + (PI - 0.4) * k / 8.0
			var base := Vector2(cos(a) * 0.3 * w, -0.62 * hh + sin(a) * 0.08 + 0.1)
			_poly(c, PackedVector2Array([base + Vector2(-0.06, 0), base + Vector2(0.06, 0), base + Vector2(0, 0.18)]), trim, 0.016)


func _p_armor(c: CanvasItem, w: float, wst: float, chw: float, shw: float) -> void:
	var id := String(look.get("armor", "none"))
	if id == "none":
		return
	var col := Color("92602d")
	match id:
		"bronce": col = Color("cd7f32")
		"hierro": col = Color("94a3b8")
		"oro": col = GOLD
	var pts := PackedVector2Array([Vector2(-shw * 0.92, -0.57 * hh), Vector2(-0.14, -0.63 * hh), Vector2(0.14, -0.63 * hh), Vector2(shw * 0.92, -0.57 * hh), Vector2(chw * 1.02, -0.3 * hh), Vector2(wst * 1.08, -0.06), Vector2(-wst * 1.08, -0.06), Vector2(-chw * 1.02, -0.3 * hh)])
	_poly(c, pts, col)
	c.draw_colored_polygon(PackedVector2Array([Vector2(chw * 0.5, -0.58 * hh), Vector2(chw * 1.02, -0.3 * hh), Vector2(wst * 1.08, -0.06), Vector2(wst * 0.5, -0.06)]), Color(0, 0, 0, 0.17))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-chw * 0.9, -0.55 * hh), Vector2(-chw * 0.5, -0.55 * hh), Vector2(-chw * 0.55, -0.3 * hh)]), Color(1, 1, 1, 0.16))
	for k in 3:
		_line(c, Vector2(-chw * 0.9, (-0.46 + k * 0.13) * hh), Vector2(chw * 0.9, (-0.46 + k * 0.13) * hh), 0.022, col.darkened(0.35))
	_ell(c, Vector2(0, -0.4 * hh), 0.07, 0.07, col.lightened(0.3), 0.02)
	if id != "cuero":
		for sx in [-1.0, 1.0]:
			_ell(c, Vector2(sx * shw * 0.98, -0.56 * hh), 0.19 * ww, 0.14, col)
			_ell(c, Vector2(sx * shw * 0.98, -0.6 * hh), 0.08, 0.04, col.lightened(0.35), 0.0)
	else:
		for k in 4:
			c.draw_circle(Vector2(-chw * 0.7 + k * chw * 0.47, -0.58 * hh), 0.022, col.lightened(0.3))


func _p_cape(c: CanvasItem, col: Color, id: String) -> void:
	var w := ww * wide
	var pts := PackedVector2Array([Vector2(-0.3 * w, 0), Vector2(0.3 * w, 0), Vector2(0.62 * w, 0.95 * hh), Vector2(0.3 * w, 1.05 * hh), Vector2(0, 0.98 * hh), Vector2(-0.3 * w, 1.05 * hh), Vector2(-0.62 * w, 0.95 * hh)])
	_poly(c, pts, col)
	c.draw_colored_polygon(PackedVector2Array([Vector2(0.2 * w, 0), Vector2(0.3 * w, 0), Vector2(0.62 * w, 0.95 * hh), Vector2(0.3 * w, 1.05 * hh)]), Color(0, 0, 0, 0.2))
	_line(c, Vector2(-0.6 * w, 0.93 * hh), Vector2(-0.3 * w, 1.02 * hh), 0.05, col.lightened(0.3))
	_line(c, Vector2(0.6 * w, 0.93 * hh), Vector2(0.3 * w, 1.02 * hh), 0.05, col.lightened(0.3))
	if id == "lobo":
		for k in 9:
			var x := -0.34 * w + k * 0.085 * w
			_poly(c, PackedVector2Array([Vector2(x - 0.06, 0), Vector2(x + 0.06, 0), Vector2(x, 0.16)]), col.lightened(0.28), 0.014)


func _p_tail(c: CanvasItem) -> void:
	var tc := skin.darkened(0.12)
	var pts := PackedVector2Array([Vector2(-0.08, 0), Vector2(0.08, 0), Vector2(0.4, 0.25), Vector2(0.62, 0.55), Vector2(0.9, 0.6), Vector2(0.6, 0.72), Vector2(0.28, 0.4)])
	_poly(c, pts, tc)
	if kind == "demon":
		_poly(c, PackedVector2Array([Vector2(0.86, 0.5), Vector2(1.08, 0.62), Vector2(0.88, 0.7)]), Color("1c1917"), 0.02)


func _p_wings(c: CanvasItem) -> void:
	for sx in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2(sx * 0.2, 0.0), Vector2(sx * 0.9, -0.55), Vector2(sx * 1.25, -0.2), Vector2(sx * 1.05, 0.0), Vector2(sx * 1.0, 0.35), Vector2(sx * 0.7, 0.15), Vector2(sx * 0.5, 0.4)])
		_poly(c, pts, Color("7f1d1d"))
		_line(c, Vector2(sx * 0.25, 0), Vector2(sx * 0.9, -0.5), 0.025, Color("450a0a"))
		_line(c, Vector2(sx * 0.25, 0), Vector2(sx * 1.0, 0.3), 0.025, Color("450a0a"))


func _arm_col() -> Color:
	if kind == "knight":
		return Color("64748b")
	return skin


func _p_arm(c: CanvasItem, side: float) -> void:
	var r := 0.105 * thick * (0.92 + 0.08 * ww)
	var col := _arm_col()
	if _anat():
		BodyArt.upper_arm(c, col, side, _fxl())
		var aid := String(look.get("armor", "none"))
		if aid in ["bronce", "hierro", "oro"]:
			var ac := Color("cd7f32") if aid == "bronce" else (Color("94a3b8") if aid == "hierro" else GOLD)
			_ell(c, Vector2(0, 0.02), r * 1.9, 0.13, ac)
		return
	if bone:
		_ell(c, Vector2(0, 0), r * 1.55, r * 1.45, col)
		_cap(c, Vector2.ZERO, Vector2(0, 0.36), r, col)
	else:
		_limb(c, Vector2.ZERO, Vector2(0, 0.38), r * 1.5, r * 0.95, col, 0.34, 0.3)
		_ell(c, Vector2(0, 0.0), r * 1.1, r * 1.0, col.lightened(0.05), OL * 0.8)
	if bone:
		_line(c, Vector2(0, 0.04), Vector2(0, 0.34), 0.02, INK)
	var id := String(look.get("armor", "none"))
	if id in ["bronce", "hierro", "oro"]:
		var ac := Color("cd7f32") if id == "bronce" else (Color("94a3b8") if id == "hierro" else GOLD)
		_ell(c, Vector2(0, 0.02), r * 1.9, 0.13, ac)


func _p_fore(c: CanvasItem, side: float) -> void:
	var r := 0.085 * thick * (0.92 + 0.08 * ww)
	var col := _arm_col()
	if _anat():
		BodyArt.fore(c, col, side, _fxl())
		if kind == "titan":
			_poly(c, PackedVector2Array([Vector2(-r - 0.03, 0.08), Vector2(r + 0.03, 0.08), Vector2(r + 0.02, 0.29), Vector2(-r - 0.02, 0.29)]), GOLD, 0.02)
		if side < 0.0:
			_p_shield(c)
		elif potion_col.a > 0.0:
			_ell(c, Vector2(0.04, 0.36), 0.075, 0.1, potion_col, 0.02)
			_poly(c, PackedVector2Array([Vector2(-0.02, 0.24), Vector2(0.1, 0.24), Vector2(0.08, 0.3), Vector2(0.0, 0.3)]), Color("e5e7eb"), 0.016)
		return
	if bone:
		_cap(c, Vector2.ZERO, Vector2(0, 0.31), r, col)
	else:
		_limb(c, Vector2.ZERO, Vector2(0, 0.33), r * 1.25, r * 0.78, col, 0.3, 0.25)
	if kind in ["human", "orc", "minotaur", "lizard", "troll"]:
		# muñequera de cuero
		_poly(c, PackedVector2Array([Vector2(-r - 0.02, 0.15), Vector2(r + 0.02, 0.15), Vector2(r + 0.015, 0.28), Vector2(-r - 0.015, 0.28)]), leather, 0.02)
	if kind == "knight" or kind == "titan":
		_poly(c, PackedVector2Array([Vector2(-r - 0.03, 0.08), Vector2(r + 0.03, 0.08), Vector2(r + 0.02, 0.29), Vector2(-r - 0.02, 0.29)]), Color("94a3b8") if kind == "knight" else GOLD, 0.02)
	_ell(c, Vector2(0, 0.37), 0.1 * thick, 0.095 * thick, col)
	if side < 0.0:
		_p_shield(c)
	else:
		if potion_col.a > 0.0:
			_ell(c, Vector2(0.04, 0.36), 0.075, 0.1, potion_col, 0.02)
			_poly(c, PackedVector2Array([Vector2(-0.02, 0.24), Vector2(0.1, 0.24), Vector2(0.08, 0.3), Vector2(0.0, 0.3)]), Color("e5e7eb"), 0.016)


func _p_shield(c: CanvasItem) -> void:
	var id := String(look.get("shield", "none"))
	if id == "none" or shield_broken:
		return
	var col := Color("8b5a2b")
	var rim := Color("5b3a1a")
	match id:
		"bronce":
			col = Color("cd7f32")
			rim = Color("92602d")
		"hierro":
			col = Color("94a3b8")
			rim = Color("475569")
		"oro":
			col = GOLD
			rim = Color("b45309")
	var sc := lerpf(0.82, 1.0, clampf(shield_ratio, 0.0, 1.0))
	var ctr := Vector2(-0.06, 0.34)
	var R := 0.4 * sc
	_ell(c, ctr, R, R, rim)
	_ell(c, ctr, R * 0.82, R * 0.82, col, 0.02)
	c.draw_colored_polygon(PackedVector2Array([ctr + Vector2(R * 0.1, -R * 0.78), ctr + Vector2(R * 0.78, -R * 0.1), ctr + Vector2(R * 0.7, R * 0.4), ctr + Vector2(R * 0.3, R * 0.7), ctr + Vector2(R * 0.3, R * 0.1)]), Color(0, 0, 0, 0.14))
	for k in 10:
		var a := TAU * k / 10.0
		c.draw_circle(ctr + Vector2(cos(a), sin(a)) * R * 0.9, 0.018, rim.lightened(0.45))
	if id == "madera":
		for k in 3:
			_line(c, ctr + Vector2(-R * 0.7, -R * 0.4 + k * R * 0.4), ctr + Vector2(R * 0.7, -R * 0.4 + k * R * 0.4), 0.015, rim)
	_ell(c, ctr, R * 0.28, R * 0.28, rim.lightened(0.15), 0.025)
	c.draw_circle(ctr + Vector2(-R * 0.06, -R * 0.07), R * 0.07, Color(1, 1, 1, 0.45))
	if shield_ratio < 0.7:
		_line(c, ctr + Vector2(-R * 0.1, -R * 0.78), ctr + Vector2(R * 0.12, -R * 0.2), 0.025, INK)
		_line(c, ctr + Vector2(R * 0.12, -R * 0.2), ctr + Vector2(-R * 0.1, R * 0.15), 0.025, INK)
	if shield_ratio < 0.35:
		_line(c, ctr + Vector2(R * 0.72, R * 0.1), ctr + Vector2(R * 0.2, R * 0.2), 0.025, INK)
		_line(c, ctr + Vector2(-R * 0.6, R * 0.5), ctr + Vector2(-R * 0.15, R * 0.15), 0.025, INK)


# ======================= Cabeza =======================
func _p_head(c: CanvasItem) -> void:
	var hair_c := _col(look.get("hair_c", "3b2314"))
	var helmet := String(look.get("helmet", "none"))
	match kind:
		"skeleton":
			_head_skull(c)
		"orc":
			_head_orc(c)
		"troll":
			_head_troll(c)
		"lizard":
			_head_lizard(c)
		"minotaur":
			_head_minotaur(c)
		"demon":
			_head_demon(c)
		"knight":
			_head_knight(c)
		"titan":
			_head_titan(c)
		_:
			_head_human(c, hair_c, helmet)
			return
	if helmet != "none" and kind != "knight":
		_p_helmet(c, helmet)


func _eyes(c: CanvasItem, y: float, sep: float, rx: float, ry: float, iris: Color, angry: float, brow_c: Color) -> void:
	# banda blanca de ojos con pupilas pequeñas y cejas gruesas
	var hw := sep + rx * 1.5
	if expr == 3:
		for sx in [-1.0, 1.0]:
			var p := Vector2(sx * sep * 0.6, y)
			_line(c, p + Vector2(-0.04, -0.04), p + Vector2(0.04, 0.04), 0.03, INK)
			_line(c, p + Vector2(0.04, -0.04), p + Vector2(-0.04, 0.04), 0.03, INK)
		return
	var sq := 0.55 if expr == 1 else 1.0
	var top := y - ry * 1.55 * sq
	var bot := y + ry * 1.45 * sq
	var band := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		band.append(Vector2(lerpf(-hw, hw, t), top - 0.02 * sin(PI * t)))
	for i in 9:
		var t := 1.0 - float(i) / 8.0
		band.append(Vector2(lerpf(-hw, hw, t), bot + 0.012 * sin(PI * t)))
	c.draw_colored_polygon(band, Color("fafafa"))
	var closed := band.duplicate()
	closed.append(band[0])
	c.draw_polyline(closed, INK, 0.026, false)
	var pr := ry * 0.64 * sq
	for sx in [-1.0, 1.0]:
		var p := Vector2(sx * sep * 0.62, y + ry * 0.12)
		if iris.get_luminance() > 0.35:
			c.draw_circle(p, pr * 1.25, iris)
			c.draw_circle(p, pr * 0.7, INK)
		else:
			c.draw_circle(p, pr, INK)
		c.draw_circle(p + Vector2(0.008, -0.01), 0.008, Color.WHITE)
		var inner := Vector2(sx * sep * 0.25, y - ry * 0.7 + angry * 0.02)
		var outer := Vector2(sx * (hw + 0.01), y - ry * 2.0 - angry * 0.01)
		_line(c, inner, outer, 0.05, INK)


func _mouth(c: CanvasItem, y: float, w: float, teeth: bool = false) -> void:
	match expr:
		1:
			_poly(c, PackedVector2Array([Vector2(-w, y - 0.02), Vector2(w, y - 0.02), Vector2(w * 0.8, y + 0.04), Vector2(-w * 0.8, y + 0.04)]), Color("fafafa"), 0.02)
			_line(c, Vector2(-w, y + 0.01), Vector2(w, y + 0.01), 0.012, INK)
			for k in 3:
				_line(c, Vector2(-w * 0.5 + k * w * 0.5, y - 0.02), Vector2(-w * 0.5 + k * w * 0.5, y + 0.04), 0.01, INK)
		2:
			_ell(c, Vector2(0, y + 0.02), w * 0.8, 0.06, Color("450a0a"), 0.02)
			_ell(c, Vector2(0, y + 0.05), w * 0.45, 0.027, Color("f87171"), 0.0)
			_line(c, Vector2(-w * 0.6, y - 0.02), Vector2(w * 0.6, y - 0.02), 0.025, Color("fafafa"))
		3:
			_ell(c, Vector2(0, y + 0.02), w * 0.6, 0.045, Color("450a0a"), 0.02)
			_ell(c, Vector2(0.03, y + 0.07), 0.03, 0.05, Color("f87171"), 0.014)
		_:
			if teeth:
				_poly(c, PackedVector2Array([Vector2(-w, y - 0.02), Vector2(w, y - 0.02), Vector2(w * 0.7, y + 0.045), Vector2(-w * 0.7, y + 0.045)]), Color("fafafa"), 0.02)
			else:
				c.draw_arc(Vector2(0, y - 0.03), w, 0.25, PI - 0.25, 10, INK, 0.036, false)
				c.draw_arc(Vector2(0, y - 0.03), w, 0.25, PI - 0.25, 10, Color("9f3b30"), 0.02, false)


func _hair_back(c: CanvasItem, style: String, hc: Color) -> void:
	match style:
		"long":
			_poly(c, PackedVector2Array([Vector2(-0.29, -0.15), Vector2(-0.33, 0.2), Vector2(-0.4, 0.6), Vector2(-0.12, 0.66), Vector2(0.12, 0.66), Vector2(0.4, 0.6), Vector2(0.33, 0.2), Vector2(0.29, -0.15)]), hc)
		"afro":
			_ell(c, Vector2(0, -0.14), 0.47, 0.44, hc)
		"braids":
			for sx in [-1.0, 1.0]:
				for k in 4:
					_ell(c, Vector2(sx * 0.3, 0.05 + k * 0.13), 0.062, 0.075, hc, 0.02)
		"topknot":
			_ell(c, Vector2(0, -0.45), 0.1, 0.1, hc)


func _hair_front(c: CanvasItem, style: String, hc: Color) -> void:
	var cap := func(top_y: float, line_y: float, rx: float) -> void:
		var pts := PackedVector2Array()
		for i in 12:
			var a := PI + 0.1 + (PI - 0.2) * float(i) / 11.0
			pts.append(Vector2(cos(a) * rx, sin(a) * 0.3 + top_y))
		pts.append(Vector2(rx * 0.85, line_y))
		pts.append(Vector2(0.12, line_y - 0.07))
		pts.append(Vector2(0.0, line_y - 0.02))
		pts.append(Vector2(-0.12, line_y - 0.07))
		pts.append(Vector2(-rx * 0.85, line_y))
		_poly(c, pts, hc)
	match style:
		"short", "long", "braids", "topknot":
			cap.call(-0.02, -0.12, 0.262)
		"mohawk":
			for k in 7:
				var x := -0.18 + k * 0.06
				_poly(c, PackedVector2Array([Vector2(x - 0.045, -0.24), Vector2(x + 0.045, -0.24), Vector2(x + 0.01, -0.44 - (3.0 - absf(k - 3.0)) * 0.05)]), hc, 0.02)
			_poly(c, PackedVector2Array([Vector2(-0.14, -0.2), Vector2(0.14, -0.2), Vector2(0.1, -0.3), Vector2(-0.1, -0.3)]), hc, 0.02)
		"spiky":
			cap.call(-0.03, -0.12, 0.255)
			for k in 6:
				var x := -0.2 + k * 0.08
				_poly(c, PackedVector2Array([Vector2(x - 0.05, -0.25), Vector2(x + 0.05, -0.25), Vector2(x + (k - 2.5) * 0.02, -0.42 - (k % 2) * 0.05)]), hc, 0.02)
		"afro":
			var pts := PackedVector2Array()
			for i in 12:
				var a := PI + 0.25 + (PI - 0.5) * float(i) / 11.0
				pts.append(Vector2(cos(a) * 0.27, sin(a) * 0.3 - 0.02))
			pts.append(Vector2(0.2, -0.13))
			pts.append(Vector2(0.0, -0.1))
			pts.append(Vector2(-0.2, -0.13))
			_poly(c, pts, hc)


func _beard(c: CanvasItem, style: String, bc: Color) -> void:
	match style:
		"stubble":
			c.draw_colored_polygon(PackedVector2Array([Vector2(-0.22, 0.0), Vector2(-0.18, 0.2), Vector2(0, 0.29), Vector2(0.18, 0.2), Vector2(0.22, 0.0), Vector2(0.12, 0.1), Vector2(0, 0.13), Vector2(-0.12, 0.1)]), Color(bc.r, bc.g, bc.b, 0.4))
		"mustache":
			_poly(c, PackedVector2Array([Vector2(-0.14, 0.09), Vector2(0, 0.075), Vector2(0.14, 0.09), Vector2(0.11, 0.14), Vector2(0, 0.105), Vector2(-0.11, 0.14)]), bc, 0.018)
		"short":
			_poly(c, PackedVector2Array([Vector2(-0.235, -0.03), Vector2(-0.2, 0.2), Vector2(0, 0.3), Vector2(0.2, 0.2), Vector2(0.235, -0.03), Vector2(0.17, 0.08), Vector2(0.1, 0.1), Vector2(-0.1, 0.1), Vector2(-0.17, 0.08)]), bc, 0.02)
		"full":
			_poly(c, PackedVector2Array([Vector2(-0.245, -0.05), Vector2(-0.24, 0.24), Vector2(-0.1, 0.4), Vector2(0.1, 0.4), Vector2(0.24, 0.24), Vector2(0.245, -0.05), Vector2(0.18, 0.07), Vector2(0.1, 0.09), Vector2(-0.1, 0.09), Vector2(-0.18, 0.07)]), bc, 0.02)
		"long":
			_poly(c, PackedVector2Array([Vector2(-0.245, -0.05), Vector2(-0.25, 0.25), Vector2(-0.14, 0.52), Vector2(0, 0.72), Vector2(0.14, 0.52), Vector2(0.25, 0.25), Vector2(0.245, -0.05), Vector2(0.18, 0.07), Vector2(0.1, 0.09), Vector2(-0.1, 0.09), Vector2(-0.18, 0.07)]), bc, 0.02)
		"goatee":
			_poly(c, PackedVector2Array([Vector2(-0.11, 0.17), Vector2(0.11, 0.17), Vector2(0.08, 0.36), Vector2(0, 0.42), Vector2(-0.08, 0.36)]), bc, 0.02)
			_poly(c, PackedVector2Array([Vector2(-0.14, 0.09), Vector2(0, 0.075), Vector2(0.14, 0.09), Vector2(0.11, 0.14), Vector2(0, 0.105), Vector2(-0.11, 0.14)]), bc, 0.018)


func _head_human(c: CanvasItem, hair_c: Color, helmet: String) -> void:
	var style := String(look.get("hair", "short"))
	var beard := String(look.get("beard", "none"))
	var bc := _col(look.get("beard_c", look.get("hair_c", "3b2314")))
	_hair_back(c, style, hair_c)
	# orejas y cráneo (curvas suaves)
	for sx in [-1.0, 1.0]:
		if kind == "elf":
			_poly(c, PackedVector2Array([Vector2(sx * 0.2, -0.02), Vector2(sx * 0.46, -0.2), Vector2(sx * 0.24, 0.07)]), skin.darkened(0.03))
		else:
			_ell(c, Vector2(sx * 0.22, 0.0), 0.045, 0.07, skin.darkened(0.03))
	BodyArt.head(c, skin, 0.225, 0.285, -0.02)
	# mejillas, nariz
	for sx in [-1.0, 1.0]:
		_ell(c, Vector2(sx * 0.15, 0.07), 0.06, 0.04, Color("e0725a").lerp(skin, 0.55), 0.0)
	_poly(c, PackedVector2Array([Vector2(-0.025, -0.01), Vector2(0.025, -0.01), Vector2(0.05, 0.085), Vector2(0.0, 0.1), Vector2(-0.05, 0.085)]), skin.darkened(0.1), 0.014)
	if helmet == "none":
		_hair_front(c, style, hair_c)
	_eyes(c, -0.04, 0.1, 0.062, 0.05, Color("3b2a18"), 0.5 if expr != 0 else 0.1, hair_c if style != "bald" else skin.darkened(0.45))
	_p_paint(c)
	_beard(c, beard, bc)
	_mouth(c, 0.17, 0.065)
	_p_wounds_head(c)
	if helmet != "none":
		_p_helmet(c, helmet)


func _p_paint(c: CanvasItem) -> void:
	match String(look.get("paint", "none")):
		"guerra":
			for sx in [-1.0, 1.0]:
				for k in 2:
					_line(c, Vector2(sx * 0.12, 0.05 + k * 0.05), Vector2(sx * 0.22, 0.09 + k * 0.05), 0.03, Color("dc2626"))
			_line(c, Vector2(0, -0.2), Vector2(0, 0.0), 0.03, Color("dc2626"))
		"tigre":
			for sx in [-1.0, 1.0]:
				for k in 3:
					_line(c, Vector2(sx * 0.09, -0.15 + k * 0.045), Vector2(sx * 0.2, -0.13 + k * 0.05), 0.026, Color("f97316"))
					_line(c, Vector2(sx * 0.13, 0.08 + k * 0.04), Vector2(sx * 0.22, 0.1 + k * 0.04), 0.022, Color("f97316"))
		"calavera":
			_poly(c, PackedVector2Array([Vector2(-0.2, -0.1), Vector2(0.2, -0.1), Vector2(0.2, 0.0), Vector2(-0.2, 0.0)]), Color("f8fafc"), 0.0)
			_eyes(c, -0.04, 0.1, 0.05, 0.04, Color("111111"), 0.4, INK)
			_ell(c, Vector2(-0.1, -0.04), 0.055, 0.05, INK, 0.0)
			_ell(c, Vector2(0.1, -0.04), 0.055, 0.05, INK, 0.0)
			for k in 5:
				_line(c, Vector2(-0.1 + k * 0.05, 0.14), Vector2(-0.1 + k * 0.05, 0.22), 0.02, Color("f8fafc"))
		"rayo":
			var pts := PackedVector2Array([Vector2(0.08, -0.14), Vector2(0.17, -0.14), Vector2(0.13, -0.03), Vector2(0.2, -0.03), Vector2(0.08, 0.14), Vector2(0.11, 0.0), Vector2(0.05, 0.0)])
			_poly(c, pts, Color("fde047"), 0.016)


func _p_wounds_head(c: CanvasItem) -> void:
	if health_ratio < 0.75:
		_line(c, Vector2(-0.14, -0.14), Vector2(-0.06, -0.03), 0.026, blood_col)
		_line(c, Vector2(-0.12, -0.06), Vector2(-0.12, 0.05), 0.02, blood_col)
	if health_ratio < 0.5:
		_ell(c, Vector2(0.1, -0.03), 0.075, 0.06, Color("6d28d9").darkened(0.25), 0.0)
		_line(c, Vector2(0.13, 0.08), Vector2(0.17, 0.24), 0.022, blood_col)
	if health_ratio < 0.25:
		_line(c, Vector2(0.0, -0.26), Vector2(0.06, -0.1), 0.03, blood_col)
		_ell(c, Vector2(0.0, 0.2), 0.04, 0.03, blood_col, 0.0)


func _dome(c: CanvasItem, col: Color, edge_y: float, rx: float, ry: float) -> void:
	var pts := PackedVector2Array()
	var steps := 14
	for i in steps + 1:
		var a := PI + 0.2 + (PI - 0.4) * float(i) / steps
		pts.append(Vector2(cos(a) * rx, sin(a) * ry - 0.02))
	pts.append(Vector2(rx * 0.95, edge_y))
	pts.append(Vector2(-rx * 0.95, edge_y))
	_poly(c, pts, col)
	c.draw_colored_polygon(PackedVector2Array([Vector2(rx * 0.35, -ry + 0.0), Vector2(rx * 0.9, -ry * 0.45), Vector2(rx * 0.95, edge_y), Vector2(rx * 0.5, edge_y)]), Color(0, 0, 0, 0.16))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-rx * 0.6, -ry * 0.8), Vector2(-rx * 0.25, -ry * 0.9), Vector2(-rx * 0.5, edge_y + 0.04)]), Color(1, 1, 1, 0.2))
	_poly(c, PackedVector2Array([Vector2(-rx * 1.02, edge_y - 0.025), Vector2(rx * 1.02, edge_y - 0.025), Vector2(rx * 1.02, edge_y + 0.03), Vector2(-rx * 1.02, edge_y + 0.03)]), col.darkened(0.2), 0.022)


func _p_helmet(c: CanvasItem, id: String) -> void:
	var yb := -0.1
	match id:
		"cuero":
			_dome(c, Color("92602d"), yb, 0.27, 0.32)
			_line(c, Vector2(-0.25, yb - 0.08), Vector2(0.25, yb - 0.08), 0.03, Color("5b3a1a"))
			for k in 5:
				c.draw_circle(Vector2(-0.2 + k * 0.1, yb - 0.08), 0.014, Color("e7c999"))
		"bronce":
			_poly(c, PackedVector2Array([Vector2(-0.06, -0.3), Vector2(0.06, -0.3), Vector2(0.09, -0.52), Vector2(0.0, -0.64), Vector2(-0.09, -0.52)]), Color("dc2626"), 0.026)
			_dome(c, Color("cd7f32"), yb, 0.28, 0.33)
			for sx in [-1.0, 1.0]:
				_poly(c, PackedVector2Array([Vector2(sx * 0.27, yb), Vector2(sx * 0.2, yb), Vector2(sx * 0.2, 0.14), Vector2(sx * 0.27, 0.12)]), Color("cd7f32"), 0.024)
			_poly(c, PackedVector2Array([Vector2(-0.025, yb), Vector2(0.025, yb), Vector2(0.03, 0.06), Vector2(-0.03, 0.06)]), Color("b8722c"), 0.018)
		"hierro":
			for sx in [-1.0, 1.0]:
				_poly(c, PackedVector2Array([Vector2(sx * 0.22, -0.14), Vector2(sx * 0.4, -0.2), Vector2(sx * 0.5, -0.42), Vector2(sx * 0.58, -0.58), Vector2(sx * 0.38, -0.46), Vector2(sx * 0.28, -0.3)]), Color("f1f5f9"), 0.026)
			_dome(c, Color("94a3b8"), yb, 0.285, 0.33)
			for sx in [-1.0, 1.0]:
				_poly(c, PackedVector2Array([Vector2(sx * 0.28, yb), Vector2(sx * 0.2, yb), Vector2(sx * 0.2, 0.18), Vector2(sx * 0.28, 0.14)]), Color("94a3b8"), 0.024)
			_poly(c, PackedVector2Array([Vector2(-0.03, yb), Vector2(0.03, yb), Vector2(0.04, 0.09), Vector2(-0.04, 0.09)]), Color("64748b"), 0.02)
		"oro":
			for k in 7:
				var a := -2.3 + k * 0.38
				_poly(c, PackedVector2Array([Vector2(sin(a) * 0.12, -0.28), Vector2(sin(a) * 0.12 + 0.06, -0.28), Vector2(sin(a) * 0.46 + 0.02, -0.62 + absf(a) * 0.05)]), Color("dc2626"), 0.02)
			_dome(c, GOLD, yb, 0.285, 0.34)
			for sx in [-1.0, 1.0]:
				_poly(c, PackedVector2Array([Vector2(sx * 0.28, yb), Vector2(sx * 0.2, yb), Vector2(sx * 0.2, 0.16), Vector2(sx * 0.28, 0.12)]), GOLD, 0.024)
			_ell(c, Vector2(0, yb - 0.1), 0.04, 0.04, Color("ef4444"), 0.02)


func _head_skull(c: CanvasItem) -> void:
	var bn := Color("f1f5f9")
	_ell(c, Vector2(0, -0.04), 0.245, 0.27, bn)
	_poly(c, PackedVector2Array([Vector2(-0.16, 0.08), Vector2(0.16, 0.08), Vector2(0.14, 0.25), Vector2(-0.14, 0.25)]), bn.darkened(0.04))
	for sx in [-1.0, 1.0]:
		_ell(c, Vector2(sx * 0.1, -0.04), 0.075, 0.08, INK, 0.0)
		c.draw_circle(Vector2(sx * 0.1, -0.04), 0.028, Color("ef4444"))
		c.draw_circle(Vector2(sx * 0.1, -0.04), 0.012, Color("fecaca"))
	_poly(c, PackedVector2Array([Vector2(0, 0.03), Vector2(0.045, 0.1), Vector2(-0.045, 0.1)]), INK, 0.0)
	for k in 5:
		_line(c, Vector2(-0.1 + k * 0.05, 0.12), Vector2(-0.1 + k * 0.05, 0.24), 0.018, INK)
	_line(c, Vector2(-0.14, 0.17), Vector2(0.14, 0.17), 0.018, INK)
	if expr == 2:
		_ell(c, Vector2(0, 0.2), 0.1, 0.07, INK, 0.0)
	_p_wounds_head(c)


func _head_orc(c: CanvasItem) -> void:
	for sx in [-1.0, 1.0]:
		_poly(c, PackedVector2Array([Vector2(sx * 0.22, -0.08), Vector2(sx * 0.4, -0.2), Vector2(sx * 0.3, 0.05)]), skin)
	_ell(c, Vector2(0, -0.02), 0.26, 0.27, skin)
	_poly(c, PackedVector2Array([Vector2(-0.25, 0.04), Vector2(-0.2, 0.22), Vector2(0, 0.3), Vector2(0.2, 0.22), Vector2(0.25, 0.04)]), skin, 0.0)
	c.draw_arc(Vector2(0, 0.02), 0.26, 0.1, PI - 0.1, 14, INK, 0.036, false)
	_poly(c, PackedVector2Array([Vector2(-0.07, -0.02), Vector2(0.07, -0.02), Vector2(0.09, 0.09), Vector2(-0.09, 0.09)]), skin.darkened(0.12), 0.016)
	_eyes(c, -0.05, 0.1, 0.05, 0.04, Color("fde047"), 0.9, Color("0f1a05"))
	_mouth(c, 0.2, 0.13, true)
	for sx in [-1.0, 1.0]:
		_poly(c, PackedVector2Array([Vector2(sx * 0.12, 0.2), Vector2(sx * 0.17, 0.2), Vector2(sx * 0.15, 0.05)]), Color("f8fafc"), 0.016)
	_p_wounds_head(c)


func _head_troll(c: CanvasItem) -> void:
	_ell(c, Vector2(0, 0.0), 0.28, 0.24, skin)
	for pp in [Vector2(-0.16, -0.14), Vector2(0.12, -0.17), Vector2(0.2, 0.08)]:
		_ell(c, pp, 0.05, 0.04, skin.darkened(0.18), 0.014)
	_poly(c, PackedVector2Array([Vector2(-0.25, -0.12), Vector2(0.25, -0.12), Vector2(0.22, -0.02), Vector2(-0.22, -0.02)]), skin.darkened(0.15), 0.02)
	_eyes(c, -0.01, 0.1, 0.045, 0.035, Color("fca5a5"), 1.0, INK)
	_ell(c, Vector2(0, 0.07), 0.07, 0.05, skin.darkened(0.12), 0.02)
	_mouth(c, 0.17, 0.15, true)
	_p_wounds_head(c)


func _head_lizard(c: CanvasItem) -> void:
	for k in 4:
		_poly(c, PackedVector2Array([Vector2(-0.04 + (k - 1.5) * 0.09, -0.24), Vector2(0.04 + (k - 1.5) * 0.09, -0.24), Vector2((k - 1.5) * 0.09, -0.42 + absf(k - 1.5) * 0.04)]), skin.darkened(0.25), 0.018)
	_ell(c, Vector2(0, -0.04), 0.23, 0.26, skin)
	_ell(c, Vector2(0, 0.12), 0.15, 0.13, skin.lightened(0.1))
	for sx in [-1.0, 1.0]:
		_ell(c, Vector2(sx * 0.12, -0.1), 0.06, 0.055, Color("fde047"), 0.022)
		_ell(c, Vector2(sx * 0.12, -0.1), 0.012, 0.045, INK, 0.0)
		c.draw_circle(Vector2(sx * 0.05, 0.1), 0.013, INK)
	_mouth(c, 0.2, 0.1, false)
	_line(c, Vector2(-0.07, 0.24), Vector2(0.07, 0.24), 0.02, Color("f87171"))
	_p_wounds_head(c)


func _head_minotaur(c: CanvasItem) -> void:
	for sx in [-1.0, 1.0]:
		_poly(c, PackedVector2Array([Vector2(sx * 0.2, -0.2), Vector2(sx * 0.42, -0.34), Vector2(sx * 0.56, -0.62), Vector2(sx * 0.46, -0.6), Vector2(sx * 0.36, -0.46), Vector2(sx * 0.15, -0.28)]), Color("f1e3c8"), 0.024)
		_poly(c, PackedVector2Array([Vector2(sx * 0.22, -0.05), Vector2(sx * 0.46, 0.0), Vector2(sx * 0.3, 0.1)]), skin.darkened(0.1))
	_ell(c, Vector2(0, -0.04), 0.255, 0.27, skin)
	_ell(c, Vector2(0, 0.15), 0.17, 0.14, skin.lightened(0.16))
	for sx in [-1.0, 1.0]:
		_ell(c, Vector2(sx * 0.07, 0.15), 0.025, 0.035, INK, 0.0)
	_eyes(c, -0.08, 0.11, 0.05, 0.04, Color("ef4444"), 1.0, INK)
	c.draw_arc(Vector2(0, 0.26), 0.06, 0.0, PI, 10, Color("fbbf24"), 0.03, false)
	_line(c, Vector2(0, 0.22), Vector2(0, 0.26), 0.02, Color("fbbf24"))
	_p_wounds_head(c)


func _head_demon(c: CanvasItem) -> void:
	for sx in [-1.0, 1.0]:
		_poly(c, PackedVector2Array([Vector2(sx * 0.12, -0.22), Vector2(sx * 0.24, -0.3), Vector2(sx * 0.34, -0.56), Vector2(sx * 0.16, -0.38)]), Color("1c1917"), 0.022)
	for sx in [-1.0, 1.0]:
		_poly(c, PackedVector2Array([Vector2(sx * 0.23, -0.06), Vector2(sx * 0.42, -0.2), Vector2(sx * 0.3, 0.04)]), skin)
	_ell(c, Vector2(0, -0.02), 0.25, 0.27, skin)
	_poly(c, PackedVector2Array([Vector2(-0.23, 0.04), Vector2(-0.17, 0.22), Vector2(0, 0.3), Vector2(0.17, 0.22), Vector2(0.23, 0.04)]), skin, 0.0)
	c.draw_arc(Vector2(0, 0.02), 0.25, 0.1, PI - 0.1, 14, INK, 0.036, false)
	_eyes(c, -0.04, 0.1, 0.055, 0.042, Color("fde047"), 1.0, INK)
	_mouth(c, 0.18, 0.12, true)
	for sx in [-1.0, 1.0]:
		_poly(c, PackedVector2Array([Vector2(sx * 0.07, 0.17), Vector2(sx * 0.11, 0.17), Vector2(sx * 0.09, 0.25)]), Color("fafafa"), 0.012)
	_p_wounds_head(c)


func _head_knight(c: CanvasItem) -> void:
	_poly(c, PackedVector2Array([Vector2(-0.04, -0.28), Vector2(0.04, -0.28), Vector2(0.1, -0.56), Vector2(0.0, -0.66), Vector2(-0.1, -0.56)]), Color("dc2626"), 0.024)
	_ell(c, Vector2(0, -0.02), 0.265, 0.295, Color("475569"))
	_poly(c, PackedVector2Array([Vector2(-0.225, -0.1), Vector2(0.225, -0.1), Vector2(0.2, 0.04), Vector2(-0.2, 0.04)]), Color("1e293b"), 0.02)
	_line(c, Vector2(-0.19, -0.03), Vector2(0.19, -0.03), 0.035, Color("ef4444"))
	_line(c, Vector2(-0.19, -0.03), Vector2(0.19, -0.03), 0.014, Color("fecaca"))
	for k in 5:
		_line(c, Vector2(-0.1 + k * 0.05, 0.1), Vector2(-0.1 + k * 0.05, 0.22), 0.02, Color("1e293b"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-0.18, -0.24), Vector2(-0.06, -0.26), Vector2(-0.14, -0.12)]), Color(1, 1, 1, 0.2))


func _head_titan(c: CanvasItem) -> void:
	c.draw_arc(Vector2(0, -0.5), 0.34, 0.0, TAU, 28, Color("fde047"), 0.05, false)
	_ell(c, Vector2(0, -0.02), 0.255, 0.28, skin)
	_poly(c, PackedVector2Array([Vector2(-0.23, 0.05), Vector2(-0.17, 0.22), Vector2(0, 0.3), Vector2(0.17, 0.22), Vector2(0.23, 0.05)]), skin, 0.0)
	c.draw_arc(Vector2(0, 0.02), 0.255, 0.1, PI - 0.1, 14, INK, 0.036, false)
	for sx in [-1.0, 1.0]:
		_ell(c, Vector2(sx * 0.1, -0.04), 0.062, 0.045, Color("e0f2fe"), 0.02)
		c.draw_circle(Vector2(sx * 0.1, -0.04), 0.03, Color("38bdf8"))
		_line(c, Vector2(sx * 0.04, -0.12), Vector2(sx * 0.17, -0.1 - 0.02 * sx), 0.034, Color("92400e"))
	_beard(c, "full", Color("fef3c7"))
	_mouth(c, 0.14, 0.06)


# ======================= Armas =======================
func _p_weapon_held(c: CanvasItem) -> void:
	if String(look.get("weapon", "none")) == "none" or busy_weapon_hidden:
		return
	_weapon_art(c, weapon_id)


var busy_weapon_hidden := false


# dibuja el arma con la empuñadura en el origen y la hoja hacia -y
func _weapon_art(c: CanvasItem, id: String) -> void:
	var gold := GOLD
	match id:
		"espada_corta", "espada_larga", "espada_fuego":
			var bl := 0.62
			var bw := 0.07
			var bc := STEEL
			var hc := WOOD
			if id == "espada_larga":
				bl = 1.0
				bw = 0.085
				bc = Color("e5e7eb")
			elif id == "espada_fuego":
				bl = 1.05
				bw = 0.09
				bc = Color("fb923c")
				hc = Color("431407")
				gold = Color("7c2d12")
			if id == "espada_fuego":
				c.draw_colored_polygon(_blade_pts(bl + 0.1, bw * 2.2), Color(0.98, 0.45, 0.09, 0.3))
			_cap(c, Vector2(0, 0.14), Vector2(0, -0.08), 0.032, hc, 0.026, false)
			_ell(c, Vector2(0, 0.17), 0.05, 0.05, gold)
			_poly(c, PackedVector2Array([Vector2(-0.16, -0.08), Vector2(0.16, -0.08), Vector2(0.16, -0.14), Vector2(-0.16, -0.14)]), gold, 0.024)
			_poly(c, _blade_pts(bl, bw), bc)
			_line(c, Vector2(0, -0.17), Vector2(0, -bl - 0.1), 0.014, Color(1, 1, 1, 0.8))
			c.draw_colored_polygon(PackedVector2Array([Vector2(bw * 0.2, -0.16), Vector2(bw, -0.16), Vector2(0, -bl - 0.14)]), Color(0, 0, 0, 0.14))
		"hacha":
			_cap(c, Vector2(0, 0.18), Vector2(0, -0.78), 0.036, WOOD, 0.026, false)
			_poly(c, PackedVector2Array([Vector2(0.02, -0.5), Vector2(0.32, -0.62), Vector2(0.36, -0.36), Vector2(0.3, -0.2), Vector2(0.02, -0.3)]), STEEL)
			_line(c, Vector2(0.33, -0.58), Vector2(0.33, -0.28), 0.018, Color.WHITE)
		"hacha_doble":
			_cap(c, Vector2(0, 0.2), Vector2(0, -1.0), 0.042, WOOD, 0.026, false)
			for sx in [-1.0, 1.0]:
				_poly(c, PackedVector2Array([Vector2(sx * 0.03, -0.66), Vector2(sx * 0.38, -0.8), Vector2(sx * 0.44, -0.5), Vector2(sx * 0.36, -0.32), Vector2(sx * 0.03, -0.44)]), Color("9ca3af"))
				_line(c, Vector2(sx * 0.4, -0.74), Vector2(sx * 0.4, -0.4), 0.018, Color.WHITE)
			_ell(c, Vector2(0, -0.55), 0.07, 0.07, gold)
		"maza":
			_cap(c, Vector2(0, 0.18), Vector2(0, -0.72), 0.042, WOOD, 0.026, false)
			_ell(c, Vector2(0, -0.82), 0.2, 0.2, Color("6b7280"))
			for k in 6:
				var a := TAU * k / 6.0
				_poly(c, PackedVector2Array([Vector2(cos(a) * 0.17 - sin(a) * 0.05, -0.82 + sin(a) * 0.17 + cos(a) * 0.05), Vector2(cos(a) * 0.17 + sin(a) * 0.05, -0.82 + sin(a) * 0.17 - cos(a) * 0.05), Vector2(cos(a) * 0.3, -0.82 + sin(a) * 0.3)]), Color("e5e7eb"), 0.018)
			c.draw_circle(Vector2(-0.06, -0.88), 0.05, Color(1, 1, 1, 0.3))
		"lanza":
			_cap(c, Vector2(0, 0.45), Vector2(0, -1.3), 0.03, WOOD, 0.024, false)
			_poly(c, PackedVector2Array([Vector2(-0.075, -1.28), Vector2(0.075, -1.28), Vector2(0, -1.68)]), STEEL)
			_line(c, Vector2(0, -1.3), Vector2(0, -1.6), 0.014, Color.WHITE)
			_poly(c, PackedVector2Array([Vector2(-0.04, -1.1), Vector2(0.04, -1.1), Vector2(0.09, -0.92), Vector2(-0.09, -0.92)]), Color("dc2626"), 0.018)
		"martillo":
			_cap(c, Vector2(0, 0.2), Vector2(0, -0.95), 0.046, WOOD, 0.028, false)
			_poly(c, PackedVector2Array([Vector2(-0.3, -1.12), Vector2(0.3, -1.12), Vector2(0.3, -0.78), Vector2(-0.3, -0.78)]), Color("4b5563"))
			_poly(c, PackedVector2Array([Vector2(-0.3, -0.84), Vector2(0.3, -0.84), Vector2(0.3, -0.78), Vector2(-0.3, -0.78)]), Color("38bdf8"), 0.0)
			c.draw_colored_polygon(PackedVector2Array([Vector2(-0.26, -1.08), Vector2(-0.08, -1.08), Vector2(-0.26, -0.9)]), Color(1, 1, 1, 0.22))
		_:
			_poly(c, _blade_pts(0.62, 0.07), STEEL)


func _blade_pts(len: float, w: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-w, -0.14), Vector2(w, -0.14), Vector2(w * 0.9, -len), Vector2(0, -len - 0.1), Vector2(-w * 0.9, -len)])


## Arma suelta para lanzarla (sprite con la empuñadura en el origen)
func _make_weapon(id: String) -> Node3D:
	return _sprite_node(func(c: CanvasItem) -> void: _weapon_art(c, id), Vector2i(560, 760), Vector2(280, 600), 1.0)


func _sprite_node(painter: Callable, size: Vector2i, origin: Vector2, sc: float, shift: Vector2 = Vector2.ZERO) -> Node3D:
	var root := Node3D.new()
	var v := SubViewport.new()
	v.size = size
	v.transparent_bg = true
	v.disable_3d = true
	
	v.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(v)
	var st := Node2D.new()
	st.position = origin
	st.scale = Vector2(PX, PX) * sc
	v.add_child(st)
	var p := P.new()
	p.fn = painter
	p.position = shift
	st.add_child(p)
	var s := Sprite3D.new()
	s.texture = v.get_texture()
	s.pixel_size = 1.0 / PX
	s.offset = Vector2(0, origin.y - size.y * 0.5)
	s.shaded = false
	s.transparent = true
	s.double_sided = true
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	root.add_child(s)
	return root


# ======================= Animación =======================
func _process(delta: float) -> void:
	if model == null:
		return
	t += delta
	# dirección según el giro del nodo 3D
	var fx := -global_transform.basis.z.x
	if absf(fx) > 0.3:
		dir = signf(fx)
	model.scale.x = lerpf(model.scale.x, dir, 0.4)
	sprite.global_position = global_position
	sprite.global_rotation = Vector3.ZERO
	sprite.render_priority = 1 if busy else 0
	if cape_node:
		cape_node.rotation = sin(t * 2.4 + phase) * 0.025 + (0.06 if busy else 0.0)
	if tail:
		tail.rotation = sin(t * 3.0 + phase) * 0.15
	if dead:
		return
	var slouch := (1.0 - health_ratio) * 0.2
	if moving:
		var s := sin(t * 15.0)
		leg_l.rotation = s * 0.32 - leg_rest
		leg_r.rotation = -s * 0.32 + leg_rest
		model.position.y = -absf(s) * 0.07
		if walking:
			arm_r.rotation = REST_R.x + s * 0.25
			arm_l.rotation = REST_L.x - s * 0.25
		if s * _step_sign < 0.0:
			_step_sign = -_step_sign
			stepped.emit()
		_dust_t -= delta
		if _dust_t <= 0.0:
			_dust_t = 0.11
			_spawn_dust()
	else:
		leg_l.rotation = lerpf(leg_l.rotation, -leg_rest, 0.2)
		leg_r.rotation = lerpf(leg_r.rotation, leg_rest, 0.2)
	if not busy:
		var br := sin(t * 2.2 + phase)
		model.position.y = lerpf(model.position.y, -0.012 - br * 0.016, 0.3)
		body.rotation = lerpf(body.rotation, br * 0.015 + slouch * 0.6, 0.2)
		var tr := REST_R
		var tl := GUARD_L if guard else REST_L
		if relaxed:
			tr = FREE_R
			tl = FREE_L
		arm_r.rotation = lerpf(arm_r.rotation, tr.x + sin(t * 2.0 + phase) * 0.03, 0.15)
		fore_r.rotation = lerpf(fore_r.rotation, tr.y + sin(t * 2.0 + phase + 1.0) * 0.04, 0.15)
		arm_l.rotation = lerpf(arm_l.rotation, tl.x + sin(t * 2.0 + phase + 2.0) * 0.03, 0.15)
		fore_l.rotation = lerpf(fore_l.rotation, tl.y, 0.15)
		head.rotation = lerpf(head.rotation, sin(t * 1.3 + phase) * 0.03 + slouch * 0.3, 0.2)
		model.rotation = lerpf(model.rotation, 0.0, 0.2)
		if expr != 0:
			_expr_timer -= delta
			if _expr_timer <= 0.0:
				_set_expr(0)


var _expr_timer := 0.0


func _set_expr(v: int, dur: float = 0.5) -> void:
	if expr == v:
		return
	expr = v
	_expr_timer = dur
	if p_head:
		p_head.queue_redraw()


func _tw() -> Tween:
	return create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _twb() -> Tween:
	return create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _twe() -> Tween:
	return create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func _wait(tw: Tween) -> void:
	if tw != null and tw.is_running():
		await tw.finished


func _rest_pose(d: float) -> void:
	var tw := _tw()
	tw.tween_property(arm_r, "rotation", REST_R.x, d)
	tw.tween_property(fore_r, "rotation", REST_R.y, d)
	tw.tween_property(body, "rotation", 0.0, d)
	tw.tween_property(model, "rotation", 0.0, d)
	tw.tween_property(model, "position:y", 0.0, d)
	await tw.finished


func attack(style: String, reach: float, on_strike: Callable) -> void:
	busy = true
	_set_expr(2, 0.7)
	var start := position
	var fwd := Vector3(dir, 0, 0)
	var lunge := start + fwd * reach
	var tw := _twb()
	match style:
		"high":
			tw.tween_property(arm_r, "rotation", -2.7, 0.28)
			tw.tween_property(fore_r, "rotation", -0.4, 0.28)
			tw.tween_property(body, "rotation", -0.22, 0.28)
		"mid":
			tw.tween_property(arm_r, "rotation", 0.5, 0.22)
			tw.tween_property(fore_r, "rotation", 0.8, 0.22)
			tw.tween_property(body, "rotation", -0.2, 0.22)
		"low":
			tw.tween_property(arm_r, "rotation", -1.2, 0.16)
			tw.tween_property(fore_r, "rotation", -2.2, 0.16)
			tw.tween_property(body, "rotation", -0.1, 0.16)
		"spin":
			tw.tween_property(arm_r, "rotation", -1.5, 0.2)
			tw.tween_property(fore_r, "rotation", -0.1, 0.2)
			tw.tween_property(model, "position:y", -0.2, 0.2)
		_:
			tw.tween_property(arm_r, "rotation", -3.0, 0.3)
			tw.tween_property(fore_r, "rotation", -0.3, 0.3)
			tw.tween_property(model, "position:y", -0.45, 0.3)
			tw.tween_property(body, "rotation", -0.25, 0.3)
	await tw.finished
	swung.emit()
	moving = reach > 0.2
	var tw2 := _twe()
	tw2.tween_property(self, "position", lunge, 0.2 if reach > 0.2 else 0.13)
	match style:
		"high":
			tw2.tween_property(arm_r, "rotation", -0.35, 0.13)
			tw2.tween_property(fore_r, "rotation", -0.5, 0.13)
			tw2.tween_property(body, "rotation", 0.32, 0.13)
		"mid":
			tw2.tween_property(arm_r, "rotation", -1.55, 0.13)
			tw2.tween_property(fore_r, "rotation", -0.05, 0.13)
			tw2.tween_property(body, "rotation", 0.28, 0.13)
		"low":
			tw2.tween_property(arm_r, "rotation", -0.8, 0.11)
			tw2.tween_property(fore_r, "rotation", -0.1, 0.11)
			tw2.tween_property(body, "rotation", 0.35, 0.11)
		"spin":
			tw2.tween_method(func(v: float): model.scale.x = dir * cos(v), 0.0, TAU * 2.0, 0.3)
		_:
			tw2.tween_property(arm_r, "rotation", -0.2, 0.14)
			tw2.tween_property(fore_r, "rotation", -0.3, 0.14)
			tw2.tween_property(model, "position:y", 0.0, 0.14)
			tw2.tween_property(body, "rotation", 0.42, 0.14)
	await get_tree().create_timer(0.1 if reach <= 0.2 else 0.2).timeout
	on_strike.call()
	await _wait(tw2)
	moving = false
	await get_tree().create_timer(0.12).timeout
	model.scale.x = dir
	moving = reach > 0.2
	var tw3 := _tw()
	tw3.tween_property(self, "position", start, 0.3 if reach > 0.2 else 0.2)
	await tw3.finished
	moving = false
	await _rest_pose(0.18)
	busy = false


func hit_react(strong: bool = false) -> void:
	if dead:
		return
	busy = true
	_set_expr(1, 0.6)
	var back := Vector3(-dir * (0.5 if strong else 0.3), 0, 0)
	flash(Color("ffffff"), 0.08)
	var start := position
	var tw := _tw()
	tw.tween_property(self, "position", start + back, 0.1)
	tw.tween_property(body, "rotation", -0.5, 0.1)
	tw.tween_property(head, "rotation", -0.35, 0.1)
	tw.tween_property(arm_r, "rotation", -0.9, 0.1)
	tw.tween_property(arm_l, "rotation", 0.9, 0.1)
	await tw.finished
	var tw2 := _tw()
	tw2.tween_property(self, "position", start, 0.28)
	tw2.tween_property(body, "rotation", 0.0, 0.28)
	await tw2.finished
	busy = false


func block_react() -> void:
	if dead:
		return
	busy = true
	var tw := _tw()
	tw.tween_property(arm_l, "rotation", GUARD_L.x, 0.1)
	tw.tween_property(fore_l, "rotation", GUARD_L.y, 0.1)
	tw.tween_property(body, "rotation", -0.14, 0.1)
	await tw.finished
	await get_tree().create_timer(0.22).timeout
	var tw2 := _tw()
	tw2.tween_property(body, "rotation", 0.0, 0.2)
	await tw2.finished
	busy = false


func dodge_react() -> void:
	if dead:
		return
	busy = true
	var start := position
	var tw := _tw()
	tw.tween_property(self, "position", start + Vector3(-dir * 0.7, 0, 0), 0.14)
	tw.tween_property(body, "rotation", -0.35, 0.14)
	tw.tween_property(model, "position:y", -0.3, 0.14)
	await tw.finished
	var tw2 := _tw()
	tw2.tween_property(self, "position", start, 0.25)
	tw2.tween_property(body, "rotation", 0.0, 0.25)
	tw2.tween_property(model, "position:y", 0.0, 0.25)
	await tw2.finished
	busy = false


func die() -> void:
	dead = true
	_set_expr(3, 99.0)
	var tw := _tw()
	tw.tween_property(model, "rotation", -1.5, 0.6).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_property(model, "position:y", -0.16, 0.6)
	tw.tween_property(arm_r, "rotation", -2.4, 0.4)
	tw.tween_property(arm_l, "rotation", 2.2, 0.4)
	tw.tween_property(fore_r, "rotation", -0.5, 0.4)
	tw.tween_property(fore_l, "rotation", 0.5, 0.4)
	await tw.finished


func victory() -> void:
	busy = true
	_set_expr(2, 3.0)
	for i in 3:
		var tw := _tw()
		tw.tween_property(arm_r, "rotation", -2.9, 0.2)
		tw.tween_property(fore_r, "rotation", -0.2, 0.2)
		tw.tween_property(arm_l, "rotation", 2.9, 0.2)
		tw.tween_property(fore_l, "rotation", 0.2, 0.2)
		tw.tween_property(model, "position:y", -0.35, 0.2)
		await tw.finished
		var tw2 := _tw()
		tw2.tween_property(model, "position:y", 0.0, 0.2)
		await tw2.finished


func drink() -> void:
	busy = true
	potion_col = Color("ef4444")
	p_fore_r.queue_redraw()
	var tw := _tw()
	tw.tween_property(arm_r, "rotation", -2.3, 0.25)
	tw.tween_property(fore_r, "rotation", -2.0, 0.25)
	tw.tween_property(head, "rotation", -0.4, 0.25)
	await tw.finished
	await get_tree().create_timer(0.45).timeout
	potion_col = Color(0, 0, 0, 0)
	p_fore_r.queue_redraw()
	await _rest_pose(0.2)
	busy = false


func pray() -> void:
	busy = true
	var tw := _tw()
	tw.tween_property(arm_r, "rotation", -2.9, 0.3)
	tw.tween_property(arm_l, "rotation", 2.9, 0.3)
	tw.tween_property(fore_r, "rotation", -0.3, 0.3)
	tw.tween_property(fore_l, "rotation", 0.3, 0.3)
	tw.tween_property(model, "position:y", -0.2, 0.3)
	await tw.finished
	await get_tree().create_timer(0.4).timeout
	var tw2 := _tw()
	tw2.tween_property(model, "position:y", 0.0, 0.2)
	await tw2.finished
	await _rest_pose(0.2)
	busy = false


# ======================= Heridas, escudo y lanzamientos =======================
func set_health(r: float) -> void:
	var changed := false
	for th in [0.75, 0.5, 0.25]:
		if (r < th) != (health_ratio < th):
			changed = true
	health_ratio = r
	if changed:
		if p_body:
			p_body.queue_redraw()
		if p_head:
			p_head.queue_redraw()


func set_shield(r: float) -> void:
	shield_ratio = r
	if p_fore_l:
		p_fore_l.queue_redraw()


func break_shield() -> Node3D:
	if shield_broken or String(look.get("shield", "none")) == "none":
		return null
	shield_broken = true
	p_fore_l.queue_redraw()
	var sid := String(look.get("shield", "madera"))
	var piece := _sprite_node(func(c: CanvasItem) -> void: _shield_art(c, sid), Vector2i(560, 560), Vector2(280, 280), 1.0, Vector2(0.06, -0.34))
	get_parent().add_child(piece)
	var gp := global_position + Vector3(-dir * 0.45, 1.2 * scl, 0.1)
	piece.global_position = gp
	var tw := create_tween().set_parallel(true)
	tw.tween_property(piece, "global_position", Vector3(gp.x + randf_range(-0.9, 0.9) - dir * 0.4, 0.4, gp.z + 0.3), 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(piece, "rotation:z", randf_range(-1.2, 1.2), 0.55)
	return piece


func _shield_art(c: CanvasItem, id: String) -> void:
	var saved := look
	var l2 := look.duplicate()
	l2.shield = id
	look = l2
	var sr := shield_ratio
	shield_ratio = 0.2
	var tmp := shield_broken
	shield_broken = false
	_p_shield(c)
	shield_broken = tmp
	shield_ratio = sr
	look = saved


func drop_weapon() -> void:
	busy_weapon_hidden = true
	if p_weapon:
		p_weapon.queue_redraw()


func push_back(to: Vector3) -> void:
	busy = true
	moving = true
	var tw := _tw()
	tw.tween_property(self, "position", to, 0.4)
	tw.tween_property(body, "rotation", -0.45, 0.2)
	tw.tween_property(head, "rotation", -0.3, 0.2)
	await tw.finished
	moving = false
	var tw2 := _tw()
	tw2.tween_property(body, "rotation", 0.0, 0.25)
	await _wait(tw2)
	busy = false


func cast_start(color: Color) -> Vector3:
	busy = true
	var tw := _tw()
	tw.tween_property(arm_r, "rotation", -2.4, 0.3)
	tw.tween_property(fore_r, "rotation", -0.5, 0.3)
	tw.tween_property(arm_l, "rotation", 2.4, 0.3)
	tw.tween_property(fore_l, "rotation", 0.5, 0.3)
	tw.tween_property(body, "rotation", -0.15, 0.3)
	if orb == null:
		orb = Node3D.new()
		add_child(orb)
		Toon.glow(orb, Toon.sphere(0.2), Color.WHITE)
		Toon.glow(orb, Toon.sphere(0.34), Color.WHITE, Vector3.ZERO, Vector3.ZERO, 0.4)
	orb.top_level = true
	orb.global_position = global_position + Vector3(dir * 0.55, 1.95 * scl * hh, 0.3)
	orb.scale = Vector3.ONE * 0.2
	orb.visible = true
	for ch in orb.get_children():
		(ch as MeshInstance3D).material_override = Toon.glow_mat(color, 1.0 if (ch as MeshInstance3D).mesh.get_aabb().size.x < 0.5 else 0.4)
	tw.tween_property(orb, "scale", Vector3.ONE, 0.3)
	await tw.finished
	return orb.global_position


func cast_end() -> void:
	if orb:
		orb.visible = false
	var tw := _tw()
	tw.tween_property(arm_r, "rotation", -0.7, 0.12)
	tw.tween_property(arm_l, "rotation", 0.7, 0.12)
	tw.tween_property(body, "rotation", 0.25, 0.12)
	await tw.finished
	await get_tree().create_timer(0.15).timeout
	await _rest_pose(0.2)
	busy = false


func throw_anim(on_release: Callable) -> void:
	busy = true
	var tw := _tw()
	tw.tween_property(arm_r, "rotation", -2.9, 0.3)
	tw.tween_property(fore_r, "rotation", -0.3, 0.3)
	tw.tween_property(body, "rotation", -0.3, 0.3)
	await tw.finished
	var tw2 := _tw()
	tw2.tween_property(arm_r, "rotation", -1.2, 0.12)
	tw2.tween_property(fore_r, "rotation", -0.1, 0.12)
	tw2.tween_property(body, "rotation", 0.4, 0.12)
	await get_tree().create_timer(0.07).timeout
	on_release.call()
	await _wait(tw2)
	await get_tree().create_timer(0.2).timeout
	await _rest_pose(0.2)
	busy = false


func flash(color: Color = Color("ffffff"), dur: float = 0.09) -> void:
	if stage == null:
		return
	stage.modulate = Color(2.6, 2.6, 2.6) if color.v > 0.8 else color.lightened(0.4) * 1.6
	await get_tree().create_timer(dur).timeout
	if is_instance_valid(stage):
		stage.modulate = Color.WHITE


func _spawn_dust() -> void:
	var par := get_parent()
	if par == null:
		return
	var d := MeshInstance3D.new()
	d.mesh = Toon.sphere(0.12)
	d.material_override = Toon.glow_mat(Color(0.88, 0.78, 0.6), 0.55)
	par.add_child(d)
	d.global_position = global_position + Vector3(randf_range(-0.3, 0.3), 0.08, 0.3)
	d.scale = Vector3.ONE * 0.5
	var tw := create_tween()
	tw.tween_property(d, "scale", Vector3.ONE * 1.8, 0.3)
	tw.parallel().tween_property(d, "position:y", d.position.y + 0.35, 0.3)
	tw.tween_property(d, "scale", Vector3.ZERO, 0.15)
	tw.tween_callback(d.queue_free)


func walk(to: Vector3, dur: float) -> void:
	busy = true
	moving = true
	walking = true
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position", to, dur)
	await tw.finished
	moving = false
	walking = false
	busy = false
