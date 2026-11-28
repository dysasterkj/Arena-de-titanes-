extends RefCounted
## Anatomía musculosa dibujada con curvas suaves (Catmull-Rom) y sombreado cel.
## Las coordenadas de los datos vienen del boceto aprobado (px); K las pasa a unidades del rig.

const INK := Color("1c1208")
const K := 0.003
const LW := 0.03
const SEG := 7


static func shade_of(c: Color) -> Color:
	return Color(c.r * 0.94, c.g * 0.80, c.b * 0.78, c.a)


static func _v(a: Array, ox: float, oy: float, fx: float, fy: float, mirror: bool = false) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in a:
		var x: float = (float(p[0]) - ox) * K * fx
		if mirror:
			x = -x
		out.append(Vector2(x, (float(p[1]) - oy) * K * fy))
	return out


static func smooth(pts: PackedVector2Array, closed: bool = true) -> PackedVector2Array:
	var out := PackedVector2Array()
	var m := pts.size()
	if m < 3:
		return pts
	var segs := m if closed else m - 1
	for i in segs:
		var p1 := pts[i]
		var p2 := pts[(i + 1) % m]
		var p0 := pts[(i - 1 + m) % m] if (closed or i > 0) else p1
		var p3 := pts[(i + 2) % m] if (closed or i + 2 < m) else p2
		for s in SEG:
			var t := float(s) / SEG
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	if not closed:
		out.append(pts[m - 1])
	return out


static func _fill(c: CanvasItem, poly: PackedVector2Array, col: Color) -> void:
	if poly.size() < 3:
		return
	if Geometry2D.triangulate_polygon(poly).is_empty():
		return
	c.draw_colored_polygon(poly, col)


## Pieza con contorno fino, color base y sombra por desplazamiento. `skip` = tramos finales sin contorno.
static func blob(c: CanvasItem, pts: PackedVector2Array, fill: Color, shade: Color, off: Vector2, skip: int = 0) -> void:
	var poly := smooth(pts, true)
	_fill(c, poly, shade)
	var moved := PackedVector2Array()
	for p in poly:
		moved.append(p + off)
	for part in Geometry2D.intersect_polygons(poly, moved):
		_fill(c, part, fill)
	var line := PackedVector2Array()
	var upto := poly.size() - skip * SEG
	for i in upto:
		line.append(poly[i])
	if skip == 0:
		line.append(poly[0])
	c.draw_polyline(line, INK, LW, false)
	c.draw_circle(line[0], LW * 0.5, INK)
	c.draw_circle(line[line.size() - 1], LW * 0.5, INK)


static func ln(c: CanvasItem, pts: PackedVector2Array, w: float = 0.014) -> void:
	var s := smooth(pts, false)
	if s.size() < 2:
		return
	c.draw_polyline(s, INK, w, false)
	c.draw_circle(s[0], w * 0.5, INK)
	c.draw_circle(s[s.size() - 1], w * 0.5, INK)


static func _mir(a: Array) -> Array:
	var out := []
	for p in a:
		out.append([552.0 - float(p[0]), p[1]])
	return out


# ---------------------------------------------------------------- tronco
static func torso(c: CanvasItem, skin: Color, fx: float, fy: float) -> void:
	var sh := shade_of(skin)
	var half := [[246, 242], [218, 252], [198, 266], [194, 296], [200, 336], [212, 380], [228, 420]]
	var pts := []
	pts.append_array(half)
	pts.append([276, 438])
	var rev := _mir(half)
	rev.reverse()
	pts.append_array(rev)
	blob(c, _v(pts, 276, 455, fx, fy), skin, sh, Vector2(-14.0 * K * fx, -8.0 * K * fy))
	# pectorales, esternón, clavículas, abdominales
	var L := [
		[[204, 334], [226, 364], [252, 364], [276, 352]],
		[[222, 278], [246, 262], [276, 268]],
		[[214, 372], [228, 392], [232, 414]],
	]
	for l in L:
		ln(c, _v(l, 276, 455, fx, fy), 0.014)
		ln(c, _v(_mir(l), 276, 455, fx, fy), 0.014)
	ln(c, _v([[276, 292], [276, 352]], 276, 455, fx, fy), 0.016)
	ln(c, _v([[238, 376], [276, 384], [314, 376]], 276, 455, fx, fy), 0.012)
	ln(c, _v([[240, 398], [276, 405], [312, 398]], 276, 455, fx, fy), 0.012)
	ln(c, _v([[246, 420], [276, 424], [306, 420]], 276, 455, fx, fy), 0.012)
	ln(c, _v([[276, 384], [276, 436]], 276, 455, fx, fy), 0.01)
	# cuello corto con trapecio
	blob(c, _v([[250, 232], [302, 232], [312, 250], [276, 262], [240, 250]], 276, 455, fx, fy), skin, sh.darkened(0.06), Vector2(-6.0 * K * fx, -6.0 * K * fy))


# ---------------------------------------------------------------- piernas
static func leg(c: CanvasItem, skin: Color, side: float, fx: float, fy: float) -> void:
	var sh := shade_of(skin)
	var m := side > 0.0
	var pts := [[210, 452], [203, 498], [192, 538], [184, 582], [190, 612], [186, 646], [192, 684], [202, 722], [205, 738], [240, 738], [243, 716], [250, 684], [260, 656], [258, 626], [266, 586], [273, 528], [262, 480], [252, 452]]
	blob(c, _v(pts, 230, 455, fx, fy, m), skin, sh, Vector2(side * 13.0 * K * fx, -9.0 * K * fy))
	ln(c, _v([[206, 596], [224, 618], [240, 612]], 230, 455, fx, fy, m), 0.014)
	ln(c, _v([[218, 544], [232, 570], [236, 594]], 230, 455, fx, fy, m), 0.012)
	ln(c, _v([[212, 668], [222, 700]], 230, 455, fx, fy, m), 0.013)


static func foot(c: CanvasItem, col: Color, side: float, fx: float, fy: float) -> void:
	var pts := [[158, 746], [202, 736], [238, 736], [246, 752], [206, 764], [160, 761]]
	blob(c, _v(pts, 230, 455, fx, fy, side > 0.0), col, col.darkened(0.25), Vector2(0, -5.0 * K * fy))


# ---------------------------------------------------------------- brazos
static func upper_arm(c: CanvasItem, skin: Color, side: float, fx: float) -> void:
	var sh := shade_of(skin)
	var m := side > 0.0
	var pts := [[200, 268], [172, 262], [150, 282], [139, 318], [139, 354], [146, 390], [160, 412], [184, 414], [202, 404], [206, 388], [210, 350], [208, 312], [206, 286]]
	blob(c, _v(pts, 182, 268, fx, 1.0, m), skin, sh, Vector2(side * 12.0 * K * fx, -8.0 * K))
	ln(c, _v([[160, 296], [182, 316], [178, 352], [170, 384]], 182, 268, fx, 1.0, m), 0.014)


static func fore(c: CanvasItem, skin: Color, side: float, fx: float) -> void:
	var sh := shade_of(skin)
	var m := side > 0.0
	var pts := [[152, 386], [154, 418], [150, 448], [149, 484], [156, 518], [152, 538], [168, 556], [188, 548], [194, 520], [196, 486], [200, 452], [204, 420], [205, 394], [180, 380]]
	var loc := PackedVector2Array()
	for p in pts:
		var x: float = (float(p[0]) - 180.0) * K * fx
		if m:
			x = -x
		loc.append(Vector2(x, (float(p[1]) - 388.0) * 0.0025))
	blob(c, loc, skin, sh, Vector2(side * 12.0 * K * fx, -8.0 * 0.0025), 2)
	var L := [
		[[154, 404], [172, 424], [192, 420]],
		[[166, 468], [176, 500]],
		[[158, 542], [168, 550], [182, 544]],
	]
	for l in L:
		var q := PackedVector2Array()
		for p in l:
			var x: float = (float(p[0]) - 180.0) * K * fx
			if m:
				x = -x
			q.append(Vector2(x, (float(p[1]) - 388.0) * 0.0025))
		ln(c, q, 0.012)


# ---------------------------------------------------------------- cabeza
static func head(c: CanvasItem, skin: Color, rx: float, ry: float, cy: float) -> void:
	var pts := PackedVector2Array()
	var n := 22
	for i in n:
		var a := TAU * float(i) / n
		var s := sin(a)
		pts.append(Vector2(cos(a) * rx * (1.0 - 0.13 * maxf(0.0, s)), cy + s * ry))
	blob(c, pts, skin, shade_of(skin), Vector2(-0.045, -0.028))
