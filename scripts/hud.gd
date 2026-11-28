extends Control
## HUD de combate estilo "Swords & Sandals": dos pociones (vida y energía) con su número
## y una placa de madera con el nombre del luchador.

var title := ""
var hp := 1.0
var hp_max := 1.0
var en := 1.0
var en_max := 1.0
var mirror := false          # true = enemigo (vida a la izquierda)
var _hp_s := 1.0
var _en_s := 1.0
var _flash := 0.0
var _last_hp := -1.0

const INK := Color("1c1208")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(260, 130)


func setv(name_text: String, h: float, hm: float, e: float, em: float) -> void:
	title = name_text
	if _last_hp >= 0.0 and h < _last_hp:
		_flash = 1.0
	_last_hp = h
	hp = h
	hp_max = maxf(1.0, hm)
	en = e
	en_max = maxf(1.0, em)
	queue_redraw()


func _process(delta: float) -> void:
	var th := hp / hp_max
	var te := en / en_max
	_hp_s = move_toward(_hp_s, th, delta * 0.9)
	_en_s = move_toward(_en_s, te, delta * 0.9)
	_flash = maxf(0.0, _flash - delta * 3.0)
	queue_redraw()


func _flask(ctr: Vector2, r: float, ratio: float, col: Color, label: String, value: String, glow: float) -> void:
	# cuerpo del frasco como círculo + cuello
	var neck_w := r * 0.34
	var neck_top := ctr.y - r * 1.5
	var font := ThemeDB.fallback_font
	# sombra
	draw_circle(ctr + Vector2(3, 5), r + 3, Color(0, 0, 0, 0.3))
	# vidrio
	draw_circle(ctr, r + 3.5, INK)
	draw_rect(Rect2(ctr.x - neck_w - 3.5, neck_top - 3.5, (neck_w + 3.5) * 2.0, r * 0.9 + 3.5), INK)
	draw_rect(Rect2(ctr.x - neck_w - 8, neck_top - 3.5, (neck_w + 8) * 2.0, 8), INK)
	draw_circle(ctr, r, Color(0.86, 0.9, 0.96, 0.9))
	draw_rect(Rect2(ctr.x - neck_w, neck_top, neck_w * 2.0, r * 0.9), Color(0.86, 0.9, 0.96, 0.9))
	# líquido
	var bottom := ctr.y + r
	var level := bottom - ratio * (bottom - (neck_top + 6.0))
	var pts := PackedVector2Array()
	var n := 40
	for i in n + 1:
		var a := PI * float(i) / n
		var p := Vector2(ctr.x + cos(a) * (r - 2.0), ctr.y + sin(a) * (r - 2.0))
		if p.y < level:
			p.y = level
		pts.append(p)
	if ratio > 0.0:
		if level < ctr.y - r * 0.8:
			pts.append(Vector2(ctr.x - neck_w + 2, level))
		draw_colored_polygon(pts, col)
		if level < ctr.y:
			var xe := sqrt(maxf(0.0, (r - 2.0) * (r - 2.0) - (ctr.y - level) * (ctr.y - level)))
			draw_rect(Rect2(ctr.x - xe, level, xe * 2.0, 3), col.lightened(0.35))
		else:
			draw_rect(Rect2(ctr.x - neck_w + 2, level, neck_w * 2.0 - 4, 3), col.lightened(0.35))
		if level < ctr.y - r * 0.8:
			draw_rect(Rect2(ctr.x - neck_w + 2, level, neck_w * 2.0 - 4, ctr.y - r * 0.8 - level + 4), col)
	# brillo
	draw_arc(ctr, r * 0.72, PI * 1.05, PI * 1.45, 10, Color(1, 1, 1, 0.55), 4.0, true)
	# corcho
	draw_rect(Rect2(ctr.x - neck_w - 6, neck_top - 12, (neck_w + 6) * 2.0, 12), INK)
	draw_rect(Rect2(ctr.x - neck_w - 4, neck_top - 10, (neck_w + 4) * 2.0, 8), Color("b9803d"))
	if glow > 0.0:
		draw_circle(ctr, r, Color(1, 1, 1, glow * 0.6))
	# número
	var fs := 18
	var sz := font.get_string_size(value, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var tp := Vector2(ctr.x - sz.x * 0.5, ctr.y + r * 0.25 + fs * 0.3)
	draw_string_outline(font, tp, value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, INK)
	draw_string(font, tp, value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	# etiqueta
	var ls := 11
	var lz := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, ls)
	draw_string_outline(font, Vector2(ctr.x - lz.x * 0.5, ctr.y + r + 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, ls, 5, INK)
	draw_string(font, Vector2(ctr.x - lz.x * 0.5, ctr.y + r + 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, ls, Color("fcd34d"))


var ar := 0.0
var ar_max := 0.0


func set_armour(a: float, am: float) -> void:
	ar = a
	ar_max = am
	queue_redraw()


func _shield_gauge(ctr: Vector2, r: float, ratio: float, value: String) -> void:
	var font := ThemeDB.fallback_font
	var pts := PackedVector2Array([ctr + Vector2(-r, -r * 0.85), ctr + Vector2(r, -r * 0.85), ctr + Vector2(r, 0), ctr + Vector2(r * 0.6, r * 0.7), ctr + Vector2(0, r * 1.15), ctr + Vector2(-r * 0.6, r * 0.7), ctr + Vector2(-r, 0)])
	var back := pts.duplicate()
	for i in back.size():
		back[i] = ctr + (back[i] - ctr) * 1.12
	draw_colored_polygon(back, INK)
	draw_colored_polygon(pts, Color("4b5563"))
	# relleno según el estado de la armadura (de abajo hacia arriba)
	var top := ctr.y - r * 0.85
	var bot := ctr.y + r * 1.15
	var lvl := bot - clampf(ratio, 0.0, 1.0) * (bot - top)
	var fill := PackedVector2Array()
	for p in pts:
		fill.append(Vector2(p.x, maxf(p.y, lvl)))
	var cl := Geometry2D.clip_polygons(pts, PackedVector2Array([Vector2(ctr.x - r * 2, lvl), Vector2(ctr.x + r * 2, lvl), Vector2(ctr.x + r * 2, bot + 4), Vector2(ctr.x - r * 2, bot + 4)]))
	for poly in cl:
		draw_colored_polygon(poly, Color("38bdf8") if ratio > 0.35 else Color("f97316"))
	var q := pts.duplicate()
	q.append(pts[0])
	draw_polyline(q, Color("e5e7eb"), 2.0)
	var fs := 15
	var sz := font.get_string_size(value, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var tp := Vector2(ctr.x - sz.x * 0.5, ctr.y + 6)
	draw_string_outline(font, tp, value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, INK)
	draw_string(font, tp, value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	var ls := 11
	var lz := font.get_string_size("ARMADURA", HORIZONTAL_ALIGNMENT_CENTER, -1, ls)
	draw_string_outline(font, Vector2(ctr.x - lz.x * 0.5, ctr.y + r + 14), "ARMADURA", HORIZONTAL_ALIGNMENT_LEFT, -1, ls, 5, INK)
	draw_string(font, Vector2(ctr.x - lz.x * 0.5, ctr.y + r + 14), "ARMADURA", HORIZONTAL_ALIGNMENT_LEFT, -1, ls, Color("fcd34d"))


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var r := 27.0
	var base_y := 60.0
	var has_ar := ar_max > 0.0
	var x_en := 46.0 if has_ar else 74.0
	var x_hp := 124.0 if has_ar else 164.0
	var x_ar := 204.0
	if mirror:
		x_ar = 56.0
		x_hp = 136.0 if has_ar else 74.0
		x_en = 214.0 if has_ar else 164.0
	if has_ar:
		_shield_gauge(Vector2(x_ar, base_y + 4), 24.0, ar / ar_max, str(int(ceil(ar))))
	var hp_txt := "%d/%d" % [int(ceil(hp)), int(hp_max)]
	var en_txt := "%d/%d" % [int(en), int(en_max)]
	_flask(Vector2(x_hp, base_y), r, _hp_s, Color("dc2626"), "VIDA", hp_txt, _flash)
	_flask(Vector2(x_en, base_y), r, _en_s, Color("2563eb"), "ENERGÍA", en_txt, 0.0)
	# placa de madera con el nombre
	var pr := Rect2(8, 104, 244, 26)
	draw_rect(Rect2(pr.position + Vector2(3, 4), pr.size), Color(0, 0, 0, 0.35))
	draw_rect(pr.grow(3), INK)
	draw_rect(pr, Color("a87433"))
	draw_rect(Rect2(pr.position, Vector2(pr.size.x, 5)), Color("d19a52"))
	draw_rect(Rect2(pr.position + Vector2(0, pr.size.y - 5), Vector2(pr.size.x, 5)), Color("7a4e22"))
	for k in 5:
		draw_line(pr.position + Vector2(20 + k * 50, 6), pr.position + Vector2(10 + k * 50, pr.size.y - 6), Color(0.35, 0.2, 0.07, 0.35), 1.5)
	var fs := 17
	var tz := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	while tz.x > pr.size.x - 14.0 and fs > 11:
		fs -= 1
		tz = font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var tp := Vector2(pr.position.x + (pr.size.x - tz.x) * 0.5, pr.position.y + pr.size.y * 0.5 + fs * 0.35)
	draw_string_outline(font, tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, INK)
	draw_string(font, tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("fff3c4"))
