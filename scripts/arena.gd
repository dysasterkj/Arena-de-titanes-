extends Node3D
## Arena: suelo con textura, muros, gradas con público de muñecos animados, antorchas con llama y cielo.

const Toon = preload("res://scripts/toon.gd")

var env: Environment
var sky_mat: ProceduralSkyMaterial
var sun: DirectionalLight3D
var sand_mat: ShaderMaterial
var wall_mat: ShaderMaterial
var stand_mat: ShaderMaterial
var banner_mat: ShaderMaterial
var crowd_mat: ShaderMaterial
var arm_mat: ShaderMaterial
var mm_body: MultiMeshInstance3D
var mm_head: MultiMeshInstance3D
var mm_hair: MultiMeshInstance3D
var mm_eye_l: MultiMeshInstance3D
var mm_eye_r: MultiMeshInstance3D
var mm_arm_l: MultiMeshInstance3D
var mm_arm_r: MultiMeshInstance3D
var crowd_count := 0
var flames: Array = []
var rng := RandomNumberGenerator.new()
var t := 0.0

const CROWD_PALETTES := [
	[Color("ef4444"), Color("3b82f6"), Color("facc15"), Color("22c55e"), Color("f97316"), Color("e879f9"), Color("f8fafc")],
	[Color("166534"), Color("4d7c0f"), Color("78716c"), Color("a16207"), Color("57534e"), Color("65a30d")],
	[Color("7c2d12"), Color("b45309"), Color("991b1b"), Color("78350f"), Color("c2410c"), Color("44403c")],
	[Color("7e22ce"), Color("fbbf24"), Color("1e1b4b"), Color("be123c"), Color("0f172a"), Color("c026d3")],
]
const HAIRS := [Color("1a1a1a"), Color("3b2314"), Color("6b4423"), Color("d6a85c"), Color("a33b20"), Color("9ca3af"), Color("94a3b8"), Color("cd7f32"), Color("fbbf24")]


func _noise_tex(freq: float, cellular: bool) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_CELLULAR if cellular else FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	if cellular:
		n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	var tex := NoiseTexture2D.new()
	tex.noise = n
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	return tex


func _mat(tex: Texture2D = null, mix_amt: float = 0.0, scale: float = 0.25) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/toon.gdshader")
	m.set_shader_parameter("shine", 0.0)
	m.set_shader_parameter("rim", 0.0)
	if tex:
		m.set_shader_parameter("tex", tex)
		m.set_shader_parameter("tex_mix", mix_amt)
		m.set_shader_parameter("tex_scale", scale)
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = rot_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _ready() -> void:
	rng.seed = 77
	_build_environment()
	sand_mat = _mat(_noise_tex(0.035, false), 0.55, 0.12)
	wall_mat = _mat(_noise_tex(0.05, true), 0.65, 0.3)
	stand_mat = _mat(_noise_tex(0.06, true), 0.5, 0.3)
	banner_mat = _mat()

	var floor_mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 15.0
	cyl.bottom_radius = 15.0
	cyl.height = 0.4
	cyl.radial_segments = 48
	floor_mi.mesh = cyl
	floor_mi.material_override = sand_mat
	floor_mi.position.y = -0.2
	add_child(floor_mi)
	for r in [4.2, 8.0]:
		var ring := Toon.glow(self, Toon.torus(r - 0.06, r + 0.06), Color(1, 1, 1), Vector3(0, 0.012, 0), Vector3.ZERO, 0.16)
		ring.scale = Vector3(1, 0.05, 1)

	var segs := 36
	var wall_r := 14.0
	for i in segs:
		var a := TAU * i / segs
		var dir := Vector3(sin(a), 0, cos(a))
		var p := dir * wall_r
		_box(self, Vector3(2.7, 3.2, 1.0), Vector3(p.x, 1.6, p.z), wall_mat, a)
		_box(self, Vector3(2.8, 0.25, 1.1), Vector3(p.x, 3.3, p.z), stand_mat, a)
		if i % 3 == 0:
			var q := dir * (wall_r - 0.52)
			_box(self, Vector3(0.7, 3.3, 0.5), Vector3(q.x, 1.65, q.z), stand_mat, a)
	for tier in 4:
		var tr := wall_r + 1.6 + tier * 2.6
		var th := 3.2 + tier * 1.5
		for i in segs:
			var a := TAU * (i + 0.5) / segs
			var p := Vector3(sin(a), 0, cos(a)) * tr
			_box(self, Vector3(3.6 + tier * 0.4, th, 2.7), Vector3(p.x, th * 0.5, p.z), stand_mat, a)
	_build_crowd(wall_r)

	# antorchas, estandartes y luces cálidas
	for i in 12:
		var a := TAU * i / 12.0 + 0.26
		var dir := Vector3(sin(a), 0, cos(a))
		var p := dir * (wall_r - 0.9)
		Toon.part(self, Toon.cyl(0.08, 0.1, 2.0), Color("3f2a14"), p + Vector3(0, 1.0, 0), Vector3.ZERO, false)
		Toon.part(self, Toon.cyl(0.16, 0.1, 0.3), Color("57534e"), p + Vector3(0, 2.1, 0), Vector3.ZERO, false)
		var fl := Node3D.new()
		fl.position = p + Vector3(0, 2.3, 0)
		add_child(fl)
		Toon.glow(fl, Toon.cyl(0.0, 0.2, 0.6), Color("f97316"), Vector3(0, 0.3, 0), Vector3.ZERO, 0.9)
		Toon.glow(fl, Toon.cyl(0.0, 0.12, 0.42), Color("fde047"), Vector3(0, 0.22, 0))
		Toon.glow(fl, Toon.sphere(0.07), Color("ffffff"), Vector3(0, 0.12, 0))
		flames.append(fl)
		var b := dir * (wall_r - 0.6)
		var bm := _box(self, Vector3(1.0, 2.4, 0.06), Vector3(b.x, 4.6, b.z) - dir * 0.6, banner_mat, a)
		Toon.glow(self, Toon.sphere(0.22), Color("fde047"), bm.position - dir * 0.07 + Vector3(0, 0.4, 0))
		Toon.part(self, Toon.box(Vector3(1.05, 0.08, 0.1)), Color("fbbf24"), bm.position - dir * 0.05 + Vector3(0, 1.22, 0), Vector3(0, a, 0), false)
		if i == 2 or i == 8:
			var ol := OmniLight3D.new()
			ol.position = fl.position + Vector3(0, 0.2, 0) - dir * 1.0
			ol.light_color = Color("ff9a3d")
			ol.light_energy = 1.4
			ol.omni_range = 11.0
			add_child(ol)

	var gate := Node3D.new()
	gate.position = Vector3(0, 0, -wall_r + 0.9)
	add_child(gate)
	for sx in [-1.7, 1.7]:
		Toon.part(gate, Toon.box(Vector3(0.9, 3.8, 1.2)), Color("6b6a5e"), Vector3(sx, 1.9, 0), Vector3.ZERO, false)
		Toon.part(gate, Toon.cyl(0.3, 0.3, 0.2), Color("b45309"), Vector3(sx, 3.2, 0.65), Vector3(PI / 2, 0, 0), false)
	Toon.part(gate, Toon.box(Vector3(4.6, 0.9, 1.2)), Color("6b6a5e"), Vector3(0, 3.9, 0), Vector3.ZERO, false)
	Toon.part(gate, Toon.box(Vector3(2.5, 3.6, 0.3)), Color("0c0a09"), Vector3(0, 1.8, 0.35), Vector3.ZERO, false)
	for i in 5:
		Toon.part(gate, Toon.box(Vector3(0.08, 3.6, 0.1)), Color("44403c"), Vector3(-1.0 + i * 0.5, 1.8, 0.5), Vector3.ZERO, false)

	for i in 14:
		var a := rng.randf() * TAU
		var r := rng.randf_range(9.5, 13.0)
		var p := Vector3(sin(a) * r, 0, cos(a) * r)
		if i % 3 == 0:
			Toon.part(self, Toon.sphere(0.5, 0.5), Color("a8a29e"), p + Vector3(0, 0.15, 0), Vector3.ZERO, false)
		else:
			Toon.part(self, Toon.capsule(0.05, 0.55), Color("f5f5f4"), p + Vector3(0, 0.06, 0), Vector3(0, a, PI / 2), false)
	set_theme(0)


func _process(delta: float) -> void:
	t += delta
	for i in flames.size():
		var f: Node3D = flames[i]
		var s := 1.0 + sin(t * 11.0 + i * 1.7) * 0.12 + sin(t * 17.0 + i) * 0.07
		f.scale = Vector3(1.0 / sqrt(s), s, 1.0 / sqrt(s))


func _build_environment() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky_mat = ProceduralSkyMaterial.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.85, 0.8)
	env.ambient_light_energy = 0.62
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 40.0
	env.fog_depth_end = 120.0
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.0
	sun.light_color = Color("fff1d6")
	add_child(sun)


# ---------- Público: muñecos como los luchadores ----------
func _multi(mesh: Mesh, count: int, mat: Material) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mmi


func _build_crowd(wall_r: float) -> void:
	var slots: Array = []
	for tier in 4:
		var tr := wall_r + 1.9 + tier * 2.6
		var th := 3.2 + tier * 1.5
		var n := 52 + tier * 9
		for i in n:
			var a := TAU * (float(i) + rng.randf() * 0.6) / n
			var r := tr + rng.randf_range(-0.55, 0.55)
			slots.append(Vector3(sin(a) * r, th, cos(a) * r))
	crowd_count = slots.size()
	crowd_mat = ShaderMaterial.new()
	crowd_mat.shader = load("res://shaders/crowd.gdshader")
	arm_mat = ShaderMaterial.new()
	arm_mat.shader = load("res://shaders/crowd.gdshader")
	arm_mat.set_shader_parameter("mode", 1)
	mm_body = _multi(Toon.capsule(0.25, 0.85), crowd_count, crowd_mat)
	mm_head = _multi(Toon.sphere(0.25), crowd_count, crowd_mat)
	mm_hair = _multi(Toon.sphere(0.27, 0.34), crowd_count, crowd_mat)
	mm_eye_l = _multi(Toon.sphere(0.04), crowd_count, crowd_mat)
	mm_eye_r = _multi(Toon.sphere(0.04), crowd_count, crowd_mat)
	var arm_mesh := Toon.capsule(0.085, 0.5)
	mm_arm_l = _multi(arm_mesh, crowd_count, arm_mat)
	mm_arm_r = _multi(arm_mesh, crowd_count, arm_mat)
	for i in crowd_count:
		var p: Vector3 = slots[i]
		var yaw := atan2(p.x, p.z) + PI   # mirar hacia el centro
		var s := rng.randf_range(0.88, 1.15)
		var b := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s)
		mm_body.multimesh.set_instance_transform(i, Transform3D(b, p + b * Vector3(0, 0.48, 0)))
		mm_head.multimesh.set_instance_transform(i, Transform3D(b, p + b * Vector3(0, 1.17, 0)))
		mm_hair.multimesh.set_instance_transform(i, Transform3D(b, p + b * Vector3(0, 1.26, 0.03)))
		mm_eye_l.multimesh.set_instance_transform(i, Transform3D(b, p + b * Vector3(-0.09, 1.2, -0.215)))
		mm_eye_r.multimesh.set_instance_transform(i, Transform3D(b, p + b * Vector3(0.09, 1.2, -0.215)))
		mm_arm_l.multimesh.set_instance_transform(i, Transform3D(b, p + b * Vector3(-0.3, 0.88, 0)))
		mm_arm_r.multimesh.set_instance_transform(i, Transform3D(b, p + b * Vector3(0.3, 0.88, 0)))
	arm_mat.set_shader_parameter("side", 1.0)
	# el brazo izquierdo necesita lado negativo: usa su propio material
	var arm_mat_l := ShaderMaterial.new()
	arm_mat_l.shader = load("res://shaders/crowd.gdshader")
	arm_mat_l.set_shader_parameter("mode", 1)
	arm_mat_l.set_shader_parameter("side", -1.0)
	mm_arm_l.material_override = arm_mat_l
	arm_mat.set_meta("left", arm_mat_l)


func set_theme(i: int) -> void:
	var a: Dictionary = GameState.ARENAS[i % GameState.ARENAS.size()]
	sand_mat.set_shader_parameter("albedo", Color(String(a.sand)))
	wall_mat.set_shader_parameter("albedo", Color(String(a.wall)))
	stand_mat.set_shader_parameter("albedo", Color(String(a.wall)).darkened(0.25))
	banner_mat.set_shader_parameter("albedo", Color(String(a.banner)))
	sky_mat.sky_top_color = Color(String(a.sky_top))
	sky_mat.sky_horizon_color = Color(String(a.sky_hor))
	sky_mat.ground_horizon_color = Color(String(a.sky_hor))
	sky_mat.ground_bottom_color = Color(String(a.sky_hor)).darkened(0.2)
	env.fog_light_color = Color(String(a.sky_hor))
	sun.light_color = Color(String(a.sky_hor)).lightened(0.5)
	var pal: Array = CROWD_PALETTES[int(a.crowd)]
	var skins := [Color("f1c27d"), Color("c68642"), Color("8d5524"), Color("e0ac69"), Color("ffdbac"), Color("a9743b")]
	var dark := Color("1a1008")
	for k in crowd_count:
		var skin: Color = skins[rng.randi() % skins.size()]
		mm_body.multimesh.set_instance_color(k, pal[rng.randi() % pal.size()])
		mm_head.multimesh.set_instance_color(k, skin)
		mm_hair.multimesh.set_instance_color(k, HAIRS[rng.randi() % HAIRS.size()])
		mm_eye_l.multimesh.set_instance_color(k, dark)
		mm_eye_r.multimesh.set_instance_color(k, dark)
		mm_arm_l.multimesh.set_instance_color(k, skin)
		mm_arm_r.multimesh.set_instance_color(k, skin)


func set_cheer(v: float) -> void:
	crowd_mat.set_shader_parameter("cheer", v)
	arm_mat.set_shader_parameter("cheer", v)
	var l: ShaderMaterial = arm_mat.get_meta("left")
	l.set_shader_parameter("cheer", v)
