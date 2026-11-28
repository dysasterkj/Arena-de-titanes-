extends Node3D
## Arena 2D estilo "Swords & Sandals": un gran fondo pintado (cielo, arcos del coliseo,
## gradas llenas de público, muro dorado y arena) más el público de primera fila animado.

const Toon = preload("res://scripts/toon.gd")

const PPM := 80.0                 # píxeles por metro del fondo
const TEX_W := 3200
const WALL_H := 1100              # alto del muro (sobre la línea de la arena)
const SAND_H := 640               # alto de la arena pintada bajo la línea
const BASE_Y := 1.25              # altura del mundo donde está la base del muro
const WALL_Z := -6.0

var env: Environment
var sprite: Sprite3D
var vp: SubViewport
var painter: Node2D
var theme_idx := 0
var theme: Dictionary = {}
var crowd_mm: MultiMeshInstance3D
var crowd_mat: ShaderMaterial
var crowd_count := 0
var flames: Array = []
var rng := RandomNumberGenerator.new()
var t := 0.0

const SKINS := [Color("f1c27d"), Color("c68642"), Color("8d5524"), Color("e0ac69"), Color("ffdbac"), Color("a9743b")]
const HAIRS := [Color("1a1a1a"), Color("3b2314"), Color("6b4423"), Color("d6a85c"), Color("a33b20"), Color("9ca3af")]
const CROWD_PALETTES := [
	[Color("ef4444"), Color("3b82f6"), Color("facc15"), Color("22c55e"), Color("f97316"), Color("e879f9"), Color("f8fafc"), Color("14b8a6")],
	[Color("166534"), Color("4d7c0f"), Color("78716c"), Color("a16207"), Color("57534e"), Color("65a30d"), Color("0f766e")],
	[Color("7c2d12"), Color("b45309"), Color("991b1b"), Color("78350f"), Color("c2410c"), Color("44403c"), Color("ca8a04")],
	[Color("7e22ce"), Color("fbbf24"), Color("1e1b4b"), Color("be123c"), Color("0f172a"), Color("c026d3"), Color("2563eb")],
]


class Painter extends Node2D:
	var owner_arena

	func _draw() -> void:
		if owner_arena:
			owner_arena._paint(self)


func _ready() -> void:
	rng.seed = 77
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("5aa9e6")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# fondo pintado
	vp = SubViewport.new()
	vp.size = Vector2i(TEX_W, WALL_H + SAND_H)
	vp.transparent_bg = false
	vp.disable_3d = true
	vp.msaa_2d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	painter = Painter.new()
	(painter as Painter).owner_arena = self
	vp.add_child(painter)
	sprite = Sprite3D.new()
	sprite.texture = vp.get_texture()
	sprite.pixel_size = 1.0 / PPM
	sprite.shaded = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = Vector3(0, BASE_Y + (WALL_H - (WALL_H + SAND_H) * 0.5) / PPM, WALL_Z)
	add_child(sprite)
	_build_front_crowd()
	_build_torches()
	set_theme(0)


func _process(delta: float) -> void:
	t += delta
	for i in flames.size():
		var f: Node3D = flames[i]
		var s := 1.0 + sin(t * 11.0 + i * 1.7) * 0.14 + sin(t * 17.0 + i) * 0.08
		f.scale = Vector3(1.0 / sqrt(s), s, 1.0) * 0.55


# ======================= Pintura del fondo =======================
func _ymp(y_m: float) -> float:
	# altura en metros sobre la línea del muro -> y de textura
	return float(WALL_H) - y_m * PPM


func _paint(c: CanvasItem) -> void:
	if theme.is_empty():
		return
	var r := RandomNumberGenerator.new()
	r.seed = 1234 + theme_idx
	var sky_top := Color(String(theme.sky_top))
	var sky_hor := Color(String(theme.sky_hor))
	var wall := Color(String(theme.wall))
	var sand := Color(String(theme.sand))
	var ban := Color(String(theme.banner))
	var pal: Array = CROWD_PALETTES[int(theme.crowd)]
	var W := float(TEX_W)
	var gold := Color("e0a82e")
	# cielo
	var sky_h := _ymp(2.0)
	for i in 40:
		var f := float(i) / 39.0
		c.draw_rect(Rect2(0, f * sky_h, W, sky_h / 40.0 + 2.0), sky_top.lerp(sky_hor, f * f))
	# nubes
	for k in 14:
		var cx := r.randf() * W
		var cy := r.randf_range(10.0, 220.0)
		for j in 5:
			c.draw_circle(Vector2(cx + j * 26.0 - 52.0, cy + sin(j * 1.7) * 7.0), r.randf_range(18.0, 30.0), Color(1, 1, 1, 0.55))
	# arcada del coliseo
	var bay := 3.2 * PPM
	var a_bot := _ymp(2.5)
	var a_top := _ymp(5.7)
	c.draw_rect(Rect2(0, a_top, W, a_bot - a_top), wall.lightened(0.18))
	var n_bay := int(W / bay) + 1
	for i in n_bay:
		var x0 := i * bay
		var ow := 2.1 * PPM
		var ox := x0 + (bay - ow) * 0.5
		var ob := a_bot - 0.45 * PPM
		var oh := 1.9 * PPM
		var rad := ow * 0.5
		var top_y := ob - oh
		var col_in := sky_hor.lerp(sky_top, 0.25)
		# apertura con arco
		var pts := PackedVector2Array()
		pts.append(Vector2(ox, ob))
		pts.append(Vector2(ox, top_y))
		for k in 13:
			var a := PI + PI * float(k) / 12.0
			pts.append(Vector2(ox + rad + cos(a) * rad, top_y + sin(a) * rad))
		pts.append(Vector2(ox + ow, ob))
		c.draw_colored_polygon(pts, col_in)
		# interior oscuro de las gradas visto por el arco
		c.draw_colored_polygon(PackedVector2Array([Vector2(ox, ob), Vector2(ox, ob - 0.7 * PPM), Vector2(ox + ow, ob - 0.7 * PPM), Vector2(ox + ow, ob)]), wall.darkened(0.45))
		var line := PackedVector2Array(pts)
		line.append(pts[0])
		c.draw_polyline(line, Color("2a1a0c"), 5.0, true)
		c.draw_polyline(PackedVector2Array([Vector2(ox - 6, ob + 4), Vector2(ox + ow + 6, ob + 4)]), wall.darkened(0.35), 8.0)
		# estandarte en cada pilar
		var px_c := x0 + bay - 0.0
		if i % 2 == 0:
			var bw := 0.62 * PPM
			var bt := a_top + 0.6 * PPM
			c.draw_rect(Rect2(px_c - bw * 0.5, bt, bw, 1.7 * PPM), ban)
			c.draw_colored_polygon(PackedVector2Array([Vector2(px_c - bw * 0.5, bt + 1.7 * PPM), Vector2(px_c + bw * 0.5, bt + 1.7 * PPM), Vector2(px_c, bt + 2.0 * PPM)]), ban)
			c.draw_circle(Vector2(px_c, bt + 0.7 * PPM), 0.16 * PPM, gold)
			c.draw_rect(Rect2(px_c - bw * 0.5, bt, bw, 5.0), gold)
	# cornisa
	c.draw_rect(Rect2(0, a_top - 0.3 * PPM, W, 0.3 * PPM), wall.lightened(0.3))
	c.draw_rect(Rect2(0, a_top - 0.08 * PPM, W, 0.08 * PPM), gold)
	c.draw_rect(Rect2(0, a_top - 0.34 * PPM, W, 5.0), Color("2a1a0c"))
	# gradas con el público
	var st_top := _ymp(2.5)
	var st_bot := _ymp(1.0)
	c.draw_rect(Rect2(0, st_top, W, st_bot - st_top), wall.darkened(0.55))
	var rows := 5
	for row in rows:
		var f := float(row) / float(rows - 1)
		var ry := lerpf(st_top + 0.25 * PPM, st_bot - 0.1 * PPM, f)
		var sc := lerpf(0.82, 1.15, f)
		var x := -10.0
		while x < W + 10.0:
			var px := x + r.randf_range(-3.0, 3.0)
			var shirt: Color = pal[r.randi() % pal.size()]
			var skin: Color = SKINS[r.randi() % SKINS.size()]
			var hair: Color = HAIRS[r.randi() % HAIRS.size()]
			var hs := 7.5 * sc
			var up := r.randf() < 0.18
			# brazos levantados
			if up:
				c.draw_line(Vector2(px - 8 * sc, ry + 14 * sc), Vector2(px - 12 * sc, ry - 2 * sc), skin, 4.0 * sc)
				c.draw_line(Vector2(px + 8 * sc, ry + 14 * sc), Vector2(px + 12 * sc, ry - 2 * sc), skin, 4.0 * sc)
			c.draw_rect(Rect2(px - 9 * sc, ry + 9 * sc, 18 * sc, 20 * sc), Color("1c1208"))
			c.draw_rect(Rect2(px - 8 * sc, ry + 10 * sc, 16 * sc, 19 * sc), shirt)
			c.draw_circle(Vector2(px, ry + 2 * sc), hs + 1.6, Color("1c1208"))
			c.draw_circle(Vector2(px, ry + 2 * sc), hs, skin)
			c.draw_circle(Vector2(px, ry - 1 * sc), hs * 0.95, hair)
			c.draw_circle(Vector2(px, ry + 3 * sc), hs * 0.88, skin)
			c.draw_circle(Vector2(px - 2.6 * sc, ry + 2.6 * sc), 1.0 * sc, Color("1c1208"))
			c.draw_circle(Vector2(px + 2.6 * sc, ry + 2.6 * sc), 1.0 * sc, Color("1c1208"))
			x += r.randf_range(21.0, 29.0) * sc
	# muro / barrera
	var b_top := _ymp(1.0)
	var b_bot := float(WALL_H)
	c.draw_rect(Rect2(0, b_top, W, b_bot - b_top), wall)
	for k in 6:
		c.draw_rect(Rect2(0, b_top + k * (b_bot - b_top) / 6.0, W, 3.0), wall.darkened(0.15))
	c.draw_rect(Rect2(0, b_top, W, 0.16 * PPM), gold)
	c.draw_rect(Rect2(0, b_top + 0.16 * PPM, W, 0.05 * PPM), Color("8a5a12"))
	c.draw_rect(Rect2(0, b_top - 5.0, W, 5.0), Color("2a1a0c"))
	var pil := 4.0 * PPM
	for i in int(W / pil) + 1:
		var x := i * pil
		c.draw_rect(Rect2(x - 0.28 * PPM, b_top + 0.2 * PPM, 0.56 * PPM, b_bot - b_top - 0.2 * PPM), wall.darkened(0.22))
		c.draw_rect(Rect2(x - 0.28 * PPM, b_top + 0.2 * PPM, 0.56 * PPM, 4.0), wall.lightened(0.2))
		# ventana oscura entre pilares
		c.draw_rect(Rect2(x + 0.7 * PPM, b_top + 0.35 * PPM, 2.5 * PPM, 0.55 * PPM), Color("1a1410"))
		c.draw_rect(Rect2(x + 0.7 * PPM, b_top + 0.35 * PPM, 2.5 * PPM, 4.0), gold.darkened(0.2))
	# línea de sombra en la base
	for k in 8:
		c.draw_rect(Rect2(0, b_bot - 10.0 + k * 1.4, W, 2.0), Color(0.1, 0.05, 0.0, 0.05 * (k + 1)))
	# arena
	var s0 := float(WALL_H)
	for i in 24:
		var f := float(i) / 23.0
		c.draw_rect(Rect2(0, s0 + f * SAND_H, W, SAND_H / 24.0 + 2.0), sand.darkened(0.12 * (1.0 - f)).lightened(0.06 * f))
	for k in 900:
		var sx := r.randf() * W
		var sy := s0 + r.randf() * SAND_H
		var f2 := (sy - s0) / float(SAND_H)
		var dc := sand.darkened(r.randf_range(0.08, 0.2)) if r.randf() < 0.6 else sand.lightened(r.randf_range(0.06, 0.15))
		c.draw_circle(Vector2(sx, sy), r.randf_range(1.5, 3.0) * (0.7 + f2), dc)
	# huellas y manchas largas
	for k in 24:
		var sx := r.randf() * W
		var sy := s0 + r.randf_range(40.0, SAND_H - 20.0)
		c.draw_line(Vector2(sx, sy), Vector2(sx + r.randf_range(40.0, 160.0), sy + r.randf_range(-3.0, 3.0)), sand.darkened(0.1), 3.0)
	# piedras y huesos
	for k in 30:
		var sx := r.randf() * W
		var sy := s0 + r.randf_range(30.0, SAND_H - 20.0)
		if k % 3 == 0:
			c.draw_circle(Vector2(sx, sy), 9.0, Color("1c1208"))
			c.draw_circle(Vector2(sx, sy), 7.5, Color("a8a29e"))
		else:
			c.draw_line(Vector2(sx - 12, sy), Vector2(sx + 12, sy - 3), Color("1c1208"), 7.0, true)
			c.draw_line(Vector2(sx - 12, sy), Vector2(sx + 12, sy - 3), Color("f5f5f4"), 4.0, true)


# ======================= Público animado y antorchas =======================
func _build_front_crowd() -> void:
	var slots: Array = []
	for row in 2:
		var x := -22.0
		while x < 22.0:
			slots.append(Vector3(x + rng.randf_range(-0.12, 0.12), BASE_Y + 1.0 + row * 0.5 + rng.randf_range(-0.04, 0.04), WALL_Z + 0.3 + row * 0.05))
			x += 0.62 + rng.randf_range(-0.05, 0.08)
	crowd_count = slots.size()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(0.8, 0.8)
	q.center_offset = Vector3(0, 0.4, 0)
	mm.mesh = q
	mm.instance_count = crowd_count
	crowd_mat = ShaderMaterial.new()
	crowd_mat.shader = load("res://shaders/crowd.gdshader")
	crowd_mat.set_shader_parameter("cheer", 0.5)
	for i in crowd_count:
		var p: Vector3 = slots[i]
		var sc := rng.randf_range(0.9, 1.12)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * sc), p))
		mm.set_instance_custom_data(i, Color(rng.randf(), rng.randf(), rng.randf(), rng.randf()))
	crowd_mm = MultiMeshInstance3D.new()
	crowd_mm.multimesh = mm
	crowd_mm.material_override = crowd_mat
	crowd_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(crowd_mm)


func _build_torches() -> void:
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	var gr := Gradient.new()
	gr.set_color(0, Color(1.0, 0.85, 0.35, 1.0))
	gr.set_color(1, Color(1.0, 0.35, 0.05, 0.0))
	gt.gradient = gr
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_texture = gt
	for i in 7:
		var x := -12.0 + i * 4.0
		var tm := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1.0, 1.6)
		tm.mesh = qm
		tm.material_override = m
		tm.position = Vector3(x, BASE_Y + 0.55, WALL_Z + 0.45)
		add_child(tm)
		flames.append(tm)
		# soporte de la antorcha
		var br := MeshInstance3D.new()
		var bm := QuadMesh.new()
		bm.size = Vector2(0.1, 0.45)
		br.mesh = bm
		var bmat := StandardMaterial3D.new()
		bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bmat.albedo_color = Color("3b2410")
		br.material_override = bmat
		br.position = Vector3(x, BASE_Y + 0.12, WALL_Z + 0.44)
		add_child(br)


func set_theme(i: int) -> void:
	theme_idx = i % GameState.ARENAS.size()
	theme = GameState.ARENAS[theme_idx]
	env.background_color = Color(String(theme.sky_top))
	painter.queue_redraw()
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var pal: Array = CROWD_PALETTES[int(theme.crowd)]
	if crowd_mm:
		var mm := crowd_mm.multimesh
		for k in crowd_count:
			var col: Color = pal[rng.randi() % pal.size()]
			mm.set_instance_color(k, col)


func set_cheer(v: float) -> void:
	if crowd_mat:
		crowd_mat.set_shader_parameter("cheer", v)
