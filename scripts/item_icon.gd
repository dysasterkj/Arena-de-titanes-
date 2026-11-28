extends Control
## Dibujo pequeño del objeto en la tienda (arma, casco, coraza, escudo...).

var tab := "weapon"
var id := ""

const MAT := {
	"cuero": "92613a", "bronce": "c2763a", "hierro": "9ca3af", "oro": "facc15", "madera": "8a5a2b", "none": "6b7280",
}
const OL := Color("1a0e05")


func setup(t: String, i: String) -> Control:
	tab = t
	id = i
	custom_minimum_size = Vector2(60, 60)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func _col() -> Color:
	return Color(String(MAT.get(id, "9ca3af")))


func _poly(p: PackedVector2Array, f: Color, w: float = 2.0) -> void:
	draw_colored_polygon(p, f)
	var q := p.duplicate()
	q.append(p[0])
	draw_polyline(q, OL, w)


func _draw() -> void:
	# fondo redondo
	draw_circle(Vector2(30, 30), 29, Color(0.25, 0.14, 0.05, 0.16))
	draw_arc(Vector2(30, 30), 29, 0, TAU, 32, Color(0.35, 0.2, 0.08, 0.7), 2.0)
	match tab:
		"weapon":
			_weapon()
		"helmet":
			_helmet()
		"armor":
			_armor()
		"shield":
			_shield()
		"cape":
			_poly(PackedVector2Array([Vector2(18, 8), Vector2(42, 8), Vector2(50, 52), Vector2(30, 46), Vector2(10, 52)]), Color("b91c1c"))
			draw_circle(Vector2(30, 10), 4, Color("facc15"))
		"outfit":
			_poly(PackedVector2Array([Vector2(14, 10), Vector2(24, 10), Vector2(30, 18), Vector2(36, 10), Vector2(46, 10), Vector2(52, 24), Vector2(44, 28), Vector2(44, 52), Vector2(16, 52), Vector2(16, 28), Vector2(8, 24)]), Color("2563eb"))
		"paint":
			draw_circle(Vector2(30, 30), 17, Color("dc2626"))
			draw_arc(Vector2(30, 30), 17, 0, TAU, 24, OL, 2.0)
			draw_line(Vector2(20, 24), Vector2(40, 24), Color("fef3c7"), 4.0)
			draw_line(Vector2(20, 34), Vector2(40, 34), Color("fef3c7"), 4.0)
		_:
			draw_circle(Vector2(30, 30), 8, Color("a855f7"))


func _helmet() -> void:
	var c := _col()
	_poly(PackedVector2Array([Vector2(12, 40), Vector2(12, 26), Vector2(20, 14), Vector2(30, 10), Vector2(40, 14), Vector2(48, 26), Vector2(48, 40), Vector2(40, 40), Vector2(40, 30), Vector2(20, 30), Vector2(20, 40)]), c)
	draw_rect(Rect2(27, 12, 6, 18), c.lightened(0.3))
	if id == "bronce":
		_poly(PackedVector2Array([Vector2(24, 12), Vector2(36, 12), Vector2(34, 2), Vector2(26, 2)]), Color("dc2626"))
	elif id == "hierro":
		_poly(PackedVector2Array([Vector2(12, 24), Vector2(4, 8), Vector2(18, 18)]), Color("f5f5f4"))
		_poly(PackedVector2Array([Vector2(48, 24), Vector2(56, 8), Vector2(42, 18)]), Color("f5f5f4"))
	elif id == "oro":
		_poly(PackedVector2Array([Vector2(22, 12), Vector2(38, 12), Vector2(42, 2), Vector2(30, 6), Vector2(18, 2)]), Color("ef4444"))


func _armor() -> void:
	var c := _col()
	_poly(PackedVector2Array([Vector2(12, 12), Vector2(24, 10), Vector2(30, 16), Vector2(36, 10), Vector2(48, 12), Vector2(46, 30), Vector2(42, 52), Vector2(18, 52), Vector2(14, 30)]), c)
	draw_line(Vector2(30, 18), Vector2(30, 50), OL, 2.0)
	draw_line(Vector2(18, 32), Vector2(42, 32), c.darkened(0.35), 2.0)
	if id == "bronce" or id == "hierro" or id == "oro":
		draw_circle(Vector2(12, 14), 6, c.lightened(0.2))
		draw_circle(Vector2(48, 14), 6, c.lightened(0.2))


func _shield() -> void:
	var c := _col()
	draw_circle(Vector2(30, 30), 22, c)
	draw_arc(Vector2(30, 30), 22, 0, TAU, 28, OL, 3.0)
	draw_arc(Vector2(30, 30), 15, 0, TAU, 24, c.darkened(0.3), 2.0)
	draw_circle(Vector2(30, 30), 6, c.lightened(0.35))
	draw_arc(Vector2(30, 30), 6, 0, TAU, 12, OL, 2.0)


func _weapon() -> void:
	# todas dibujadas en diagonal (empuñadura abajo-izquierda)
	draw_set_transform(Vector2(30, 30), deg_to_rad(40), Vector2.ONE)
	var steel := Color("cbd5e1")
	var wood := Color("8a5a2b")
	match id:
		"espada_corta", "espada_larga", "espada_fuego":
			var bl := 22.0 if id == "espada_corta" else 30.0
			var bc := steel
			if id == "espada_fuego":
				bc = Color("fb923c")
			_poly(PackedVector2Array([Vector2(-3, 8), Vector2(3, 8), Vector2(3, -bl), Vector2(0, -bl - 5), Vector2(-3, -bl)]), bc)
			draw_rect(Rect2(-9, 7, 18, 4), Color("facc15"))
			draw_rect(Rect2(-2, 11, 4, 10), wood)
			draw_circle(Vector2(0, 23), 3, Color("facc15"))
		"hacha", "hacha_doble":
			draw_rect(Rect2(-2, -26, 4, 52), wood)
			_poly(PackedVector2Array([Vector2(2, -24), Vector2(16, -28), Vector2(18, -10), Vector2(2, -12)]), steel)
			if id == "hacha_doble":
				_poly(PackedVector2Array([Vector2(-2, -24), Vector2(-16, -28), Vector2(-18, -10), Vector2(-2, -12)]), steel)
		"maza":
			draw_rect(Rect2(-2, -14, 4, 40), wood)
			draw_circle(Vector2(0, -20), 11, Color("6b7280"))
			draw_arc(Vector2(0, -20), 11, 0, TAU, 16, OL, 2.0)
			for k in 6:
				var a := TAU * k / 6.0
				draw_line(Vector2(cos(a) * 11, -20 + sin(a) * 11), Vector2(cos(a) * 16, -20 + sin(a) * 16), Color("e5e7eb"), 3.0)
		"lanza":
			draw_rect(Rect2(-1.5, -22, 3, 50), wood)
			_poly(PackedVector2Array([Vector2(-5, -22), Vector2(5, -22), Vector2(0, -36)]), steel)
		"martillo":
			draw_rect(Rect2(-2, -18, 4, 46), wood)
			_poly(PackedVector2Array([Vector2(-14, -28), Vector2(14, -28), Vector2(14, -14), Vector2(-14, -14)]), Color("4b5563"))
			draw_rect(Rect2(-14, -17, 28, 3), Color("38bdf8"))
		_:
			draw_rect(Rect2(-3, -20, 6, 30), steel)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
