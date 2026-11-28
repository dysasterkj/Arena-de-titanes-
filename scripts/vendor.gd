extends Control
## Vendedor de la forja con globo de diálogo (cambia de aspecto según la sección).

var tab := "weapon"
var line := ""

const LOOKS := {
	"weapon": {"hat": "casco", "skin": "e0a370", "beard": "5b3a1e", "cloth": "7c2d12", "name": "HERRERO"},
	"helmet": {"hat": "casco", "skin": "e0a370", "beard": "5b3a1e", "cloth": "7c2d12", "name": "HERRERO"},
	"armor": {"hat": "casco", "skin": "e0a370", "beard": "5b3a1e", "cloth": "7c2d12", "name": "ARMERO"},
	"shield": {"hat": "casco", "skin": "e0a370", "beard": "5b3a1e", "cloth": "7c2d12", "name": "ARMERO"},
	"outfit": {"hat": "turbante", "skin": "c98a5b", "beard": "1f1307", "cloth": "6d28d9", "name": "SASTRE"},
	"cape": {"hat": "turbante", "skin": "c98a5b", "beard": "1f1307", "cloth": "6d28d9", "name": "SASTRE"},
	"paint": {"hat": "turbante", "skin": "c98a5b", "beard": "1f1307", "cloth": "6d28d9", "name": "SASTRE"},
	"potion": {"hat": "capucha", "skin": "d9b48a", "beard": "e5e7eb", "cloth": "166534", "name": "ALQUIMISTA"},
}

const LINES := {
	"weapon": ["¡Acero de la mejor forja!", "Un buen arma gana la mitad del combate."],
	"helmet": ["Un casco te salva la cabeza.", "¡Resistente y elegante!"],
	"armor": ["Esta armadura aguanta de todo.", "Pesada, pero vale cada moneda."],
	"shield": ["Un escudo es tu mejor amigo.", "¡Ya vi romperse peores!"],
	"outfit": ["Luce bien ante el público.", "Telas de las mejores."],
	"cape": ["Una capa da presencia.", "Hasta los reyes la usan."],
	"paint": ["Pinta tu piel de guerra.", "¡Que te teman!"],
	"potion": ["Vida y energía en frasco.", "Cuidado, ¡no las bebas todas!"],
}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_tab(t: String, msg: String = "") -> void:
	tab = t
	if msg != "":
		line = msg
	else:
		var arr: Array = LINES.get(t, LINES["weapon"])
		line = String(arr[randi() % arr.size()])
	queue_redraw()


func _draw() -> void:
	var lk: Dictionary = LOOKS.get(tab, LOOKS["weapon"])
	var ol := Color("1a0e05")
	var skin := Color(String(lk.skin))
	var beard := Color(String(lk.beard))
	var cloth := Color(String(lk.cloth))
	# mostrador
	draw_rect(Rect2(6, 156, 150, 40), Color("5a3a1c"))
	draw_rect(Rect2(6, 156, 150, 40), ol, false, 3.0)
	draw_rect(Rect2(6, 156, 150, 10), Color("8a5a2b"))
	# torso
	draw_colored_polygon(PackedVector2Array([Vector2(26, 160), Vector2(40, 118), Vector2(112, 118), Vector2(128, 160)]), cloth)
	draw_polyline(PackedVector2Array([Vector2(26, 160), Vector2(40, 118), Vector2(112, 118), Vector2(128, 160)]), ol, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(56, 128), Vector2(96, 128), Vector2(100, 160), Vector2(52, 160)]), Color("e7d3a4"))
	# cuello y cabeza
	draw_rect(Rect2(66, 100, 20, 22), skin.darkened(0.15))
	_ellipse(Vector2(76, 76), Vector2(30, 34), skin, ol)
	# barba
	var bp := PackedVector2Array([Vector2(47, 82), Vector2(60, 108), Vector2(76, 118), Vector2(92, 108), Vector2(105, 82), Vector2(96, 92), Vector2(76, 98), Vector2(56, 92)])
	draw_colored_polygon(bp, beard)
	draw_polyline(bp, ol, 2.5)
	# bigote
	draw_colored_polygon(PackedVector2Array([Vector2(60, 86), Vector2(76, 82), Vector2(92, 86), Vector2(86, 94), Vector2(76, 90), Vector2(66, 94)]), beard)
	# ojos
	for ex in [64.0, 88.0]:
		_ellipse(Vector2(ex, 70), Vector2(7, 6), Color.WHITE, ol)
		draw_circle(Vector2(ex + 1, 71), 2.6, ol)
		draw_line(Vector2(ex - 8, 60), Vector2(ex + 7, 63), ol, 3.5)
	# nariz
	draw_colored_polygon(PackedVector2Array([Vector2(73, 72), Vector2(80, 72), Vector2(84, 84), Vector2(70, 84)]), skin.darkened(0.12))
	# sombrero según tipo
	match String(lk.hat):
		"casco":
			var hp := PackedVector2Array([Vector2(44, 62), Vector2(48, 38), Vector2(76, 26), Vector2(104, 38), Vector2(108, 62), Vector2(76, 54)])
			draw_colored_polygon(hp, Color("9ca3af"))
			draw_polyline(hp, ol, 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(70, 26), Vector2(82, 26), Vector2(82, 54), Vector2(70, 54)]), Color("d1d5db"))
		"turbante":
			_ellipse(Vector2(76, 44), Vector2(38, 22), Color("f3e8ff"), ol)
			draw_circle(Vector2(76, 40), 6.0, Color("facc15"))
			draw_arc(Vector2(76, 46), 26, 0.2, 2.9, 12, Color("c4b5fd"), 3.0)
		_:
			var cp := PackedVector2Array([Vector2(40, 74), Vector2(46, 40), Vector2(76, 18), Vector2(106, 40), Vector2(112, 74), Vector2(100, 56), Vector2(76, 48), Vector2(52, 56)])
			draw_colored_polygon(cp, cloth.darkened(0.1))
			draw_polyline(cp, ol, 3.0)
	# globo de diálogo
	var br := Rect2(170, 22, 158, 112)
	var tail := PackedVector2Array([Vector2(172, 70), Vector2(146, 84), Vector2(172, 96)])
	draw_rect(br, Color("fff4d6"))
	draw_rect(br, ol, false, 3.0)
	draw_colored_polygon(tail, Color("fff4d6"))
	draw_polyline(PackedVector2Array([Vector2(172, 68), Vector2(146, 84), Vector2(172, 98)]), ol, 3.0)
	draw_line(Vector2(171, 71), Vector2(171, 95), Color("fff4d6"), 4.0)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(br.position.x + 12, br.position.y + 28), String(lk.name), HORIZONTAL_ALIGNMENT_LEFT, br.size.x - 24, 15, Color("9a3412"))
	draw_multiline_string(f, Vector2(br.position.x + 12, br.position.y + 54), line, HORIZONTAL_ALIGNMENT_LEFT, br.size.x - 24, 16, 4, Color("2a1608"))


func _ellipse(c: Vector2, r: Vector2, fill: Color, line_c: Color) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, line_c, 3.0)
