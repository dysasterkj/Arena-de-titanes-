extends Control
## Retrato de "El Cronista", el anciano narrador de la historia.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(96, 96)


func _draw() -> void:
	var s := minf(size.x, size.y) / 96.0
	var ink := Color("1a0e05")
	var ctr := Vector2(48, 48) * s
	draw_circle(ctr, 46.0 * s, Color("fbbf24"))
	draw_circle(ctr, 42.0 * s, Color("2a1810"))
	# capucha y cabello
	draw_colored_polygon(PackedVector2Array([Vector2(14, 88) * s, Vector2(18, 40) * s, Vector2(48, 10) * s, Vector2(78, 40) * s, Vector2(82, 88) * s]), Color("6b4a8a"))
	# cara
	_ell(Vector2(48, 50) * s, Vector2(23, 28) * s, Color("e0b48a"), ink, s)
	# barba
	var beard := PackedVector2Array([Vector2(26, 56), Vector2(30, 76), Vector2(48, 90), Vector2(66, 76), Vector2(70, 56), Vector2(62, 66), Vector2(48, 70), Vector2(34, 66)])
	for i in beard.size():
		beard[i] *= s
	draw_colored_polygon(beard, Color("f1f1f4"))
	var bl := beard.duplicate()
	bl.append(beard[0])
	draw_polyline(bl, ink, 1.6 * s)
	# cejas y ojos
	draw_line(Vector2(32, 38) * s, Vector2(44, 40) * s, Color("f1f1f4"), 4.0 * s)
	draw_line(Vector2(64, 38) * s, Vector2(52, 40) * s, Color("f1f1f4"), 4.0 * s)
	for ex in [38.0, 58.0]:
		draw_circle(Vector2(ex, 46) * s, 4.0 * s, Color.WHITE)
		draw_circle(Vector2(ex, 46) * s, 2.0 * s, ink)
	# nariz
	draw_colored_polygon(PackedVector2Array([Vector2(46, 48) * s, Vector2(52, 48) * s, Vector2(55, 60) * s, Vector2(43, 60) * s]), Color("cf9e74"))
	draw_arc(ctr, 44.0 * s, 0.0, TAU, 40, Color("fbbf24"), 3.0 * s)


func _ell(c: Vector2, r: Vector2, fill: Color, line: Color, s: float) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, line, 2.0 * s)
