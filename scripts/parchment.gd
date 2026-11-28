extends Control
## Fondo de pergamino con borde rasgado y degradado (estilo Swords & Sandals).

var seed_v := 1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _edge() -> PackedVector2Array:
	var w := size.x
	var h := size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v + int(w) * 7 + int(h)
	var pts := PackedVector2Array()
	var step := 16.0
	var j := 4.0
	var n := maxi(2, int(w / step))
	for i in n + 1:
		pts.append(Vector2(w * i / n, rng.randf_range(0, j)))
	n = maxi(2, int(h / step))
	for i in range(1, n + 1):
		pts.append(Vector2(w - rng.randf_range(0, j), h * i / n))
	n = maxi(2, int(w / step))
	for i in range(n - 1, -1, -1):
		pts.append(Vector2(w * i / n, h - rng.randf_range(0, j)))
	n = maxi(2, int(h / step))
	for i in range(n - 1, 0, -1):
		pts.append(Vector2(rng.randf_range(0, j), h * i / n))
	return pts


func _draw() -> void:
	var pts := _edge()
	var cols := PackedColorArray()
	for p in pts:
		var t := clampf((p.x / maxf(size.x, 1.0) * 0.45 + p.y / maxf(size.y, 1.0) * 0.8) / 1.25, 0.0, 1.0)
		cols.append(Color("ffe2a8").lerp(Color("d98a4a"), pow(t, 1.4)))
	draw_polygon(pts.duplicate(), cols)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color("1a0e05"), 3.0, false)
	# quemado en los bordes
	draw_polyline(closed, Color(0.45, 0.2, 0.05, 0.35), 8.0, false)
