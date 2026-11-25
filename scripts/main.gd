extends Node3D
## Director: escena 3D, cámara, combate por turnos, progreso y actualizaciones.

const ArenaScript = preload("res://scripts/arena.gd")
const FighterScript = preload("res://scripts/fighter.gd")
const UiScript = preload("res://scripts/ui.gd")
const Toon = preload("res://scripts/toon.gd")

enum State { MENU, BATTLE, RESULT }

const ACT := {
	"head": {"label": "CABEZA", "cost": 10, "mult": 1.5, "acc": -0.18, "anim": "high", "zone": "head"},
	"body": {"label": "CUERPO", "cost": 6, "mult": 1.0, "acc": 0.0, "anim": "mid", "zone": "body"},
	"legs": {"label": "PIERNAS", "cost": 4, "mult": 0.75, "acc": 0.14, "anim": "low", "zone": "legs"},
}

var state := State.MENU
var arena
var pf
var ef
var ui
var camera: Camera3D
var p: Dictionary = {}
var e: Dictionary = {}
var fight_idx := 0
var busy := false
var cam_mode := "menu"
var cam_pos := Vector3(2, 1.6, 5)
var cam_look := Vector3(0, 1.0, 0)
var view_style := "side"
var shake := 0.0
var enemy_potion := false
var frame_count := 0
var rng := RandomNumberGenerator.new()

# pruebas
var autoplay := false
var shot_path := ""
var shot_frame := 0
var test_view := ""
var test_fight := -1
var test_page := ""
var test_set := ""
var test_level := 0
var test_hurt := false
var test_camz := 0.0
var bot_wait := 0.0
var wins_seen := 0


func _ready() -> void:
	rng.randomize()
	for a in OS.get_cmdline_user_args():
		if a == "--autoplay":
			autoplay = true
		elif a.begins_with("--shot="):
			shot_path = a.substr(7)
		elif a.begins_with("--shotframe="):
			shot_frame = int(a.substr(12))
		elif a.begins_with("--view="):
			test_view = a.substr(7)
		elif a.begins_with("--fight="):
			test_fight = int(a.substr(8))
		elif a.begins_with("--camz="):
			test_camz = float(a.substr(7))
		elif a == "--hurt":
			test_hurt = true
		elif a.begins_with("--level="):
			test_level = int(a.substr(8))
		elif a.begins_with("--set="):
			test_set = a.substr(6)
		elif a.begins_with("--page="):
			test_page = a.substr(7)
	if autoplay:
		Engine.time_scale = 4.0
	if test_view != "":
		view_style = test_view
	if test_level > 0:
		GameState.data.xp = GameState.xp_total_for(test_level)
	for pair in test_set.split(","):
		var kv := pair.split(":")
		if kv.size() != 2:
			continue
		if GameState.data.char.has(kv[0]):
			GameState.data.char[kv[0]] = float(kv[1]) if kv[0] in ["height", "fat"] else kv[1]
		elif GameState.data.equip.has(kv[0]):
			GameState.data.equip[kv[0]] = kv[1]
	arena = ArenaScript.new()
	add_child(arena)
	pf = FighterScript.new()
	add_child(pf)
	ef = FighterScript.new()
	add_child(ef)
	camera = Camera3D.new()
	camera.fov = 56.0
	camera.far = 200.0
	add_child(camera)
	camera.current = true
	ui = UiScript.new()
	add_child(ui)
	ui.camera_ref = camera
	ui.fight_selected.connect(_start_fight)
	ui.action_pressed.connect(_on_action)
	ui.surrender_pressed.connect(func(): if not busy: _end_fight(false, true))
	ui.continue_pressed.connect(_to_menu)
	ui.retry_pressed.connect(_after_result)
	ui.preview_changed.connect(_refresh_preview)
	ui.update_pressed.connect(_open_update)
	ui.page_changed.connect(_on_page)
	_to_menu()
	if test_page == "char":
		ui.open_char()
	elif test_page == "ach":
		ui.open_ach()
	elif test_page == "shop":
		ui.open_shop()
	elif test_page == "train":
		ui.open_train()
	elif test_page == "fights":
		ui.open_fights()
	if test_fight >= 0:
		_start_fight(test_fight)
	_cleanup_update_file()
	_check_update()


# ---------- Escena ----------
func _yaw(from: Vector3, to: Vector3) -> float:
	var d := to - from
	return atan2(-d.x, -d.z)


func _refresh_preview() -> void:
	if state != State.MENU:
		return
	pf.setup(GameState.player_fighter().look)
	pf.position = Vector3.ZERO
	pf.rotation.y = PI * 0.82
	ef.visible = false


func _on_page(page: String) -> void:
	if state != State.MENU:
		return
	cam_mode = "menu" if page in ["menu", "update", "fights", "ach"] else "shop"


func _to_menu() -> void:
	state = State.MENU
	busy = false
	ui.hide_actions()
	arena.set_theme(0)
	arena.set_cheer(0.5)
	Sfx.play_music("menu")
	ef.visible = false
	_refresh_preview()
	cam_mode = "menu"
	ui.show_menu()


func _update_camera(delta: float) -> void:
	var pos := cam_pos
	var look := cam_look
	match cam_mode:
		"menu":
			pos = Vector3(2.6, 1.9, 6.4)
			look = Vector3(0, 0.95, 0)
		"shop":
			pos = Vector3(2.2, 2.0, 8.4)
			look = Vector3(0, 0.35, 0)
		"battle":
			if view_style == "side":
				pos = Vector3((pf.position.x + ef.position.x) * 0.5, 2.1, test_camz if test_camz > 0.0 else 9.0)
				camera.fov = lerpf(camera.fov, 58.0, 0.1)
				look = Vector3((pf.position.x + ef.position.x) * 0.5, 0.62, 0)
			else:
				pos = Vector3(-4.4, 3.3, 8.6)
				camera.fov = lerpf(camera.fov, 58.0, 0.1)
				look = Vector3(0.7, 0.0, -0.8)
	var vo := -1.75 if cam_mode == "shop" else (-0.5 if cam_mode == "battle" else 0.0)
	camera.v_offset = lerpf(camera.v_offset, vo, 1.0 - exp(-5.0 * delta))
	var k := 1.0 - exp(-4.0 * delta)
	cam_pos = cam_pos.lerp(pos, k)
	cam_look = cam_look.lerp(look, k)
	var off := Vector3.ZERO
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 2.5)
		off = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), 0) * shake * 0.25
	camera.position = cam_pos + off
	camera.look_at(cam_look)


func _process(delta: float) -> void:
	frame_count += 1
	_update_camera(delta)
	if state == State.MENU and cam_mode == "menu" and ui.pages["menu"].visible:
		pf.rotation.y += delta * 0.25
	if autoplay:
		_bot(delta)
	if shot_path != "" and frame_count == shot_frame:
		_take_shot()


func _take_shot() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shot_path)
	print("[test] screenshot saved: ", shot_path)
	get_tree().quit()


# ---------- Combate ----------
const FAR_GAP := 3.8
const NEAR_GAP := 1.5

var near := false
var debris: Array = []
var base_scale := 1.0


func _clear_debris() -> void:
	for n in debris:
		if is_instance_valid(n):
			(n as Node).queue_free()
	debris.clear()


func _gap() -> float:
	return absf(ef.position.x - pf.position.x)


func _dir_to(from: Node3D, to: Node3D) -> float:
	return signf(to.position.x - from.position.x)


func _start_fight(i: int) -> void:
	fight_idx = i
	state = State.BATTLE
	busy = true
	_clear_debris()
	near = false
	p = GameState.player_fighter()
	p.hp = float(p.max_hp)
	p.en = float(p.max_en)
	p.guard = false
	p.stun = 0
	p.limp = 0
	p.weak = 0
	p.shield_hp = float(p.shield_max)
	e = GameState.enemy_fighter(i)
	e.hp = float(e.max_hp)
	e.en = float(e.max_en)
	e.guard = false
	e.stun = 0
	e.limp = 0
	e.weak = 0
	e.shield_hp = float(e.shield_max)
	enemy_potion = false
	arena.set_theme(int(GameState.ENEMIES[i].arena))
	arena.set_cheer(1.0)
	Sfx.play_music("battle")
	pf.setup(p.look)
	ef.setup(e.look)
	ef.visible = true
	_layout()
	cam_mode = "battle"
	ui.show_battle()
	ui.hide_actions()
	_refresh()
	ui.set_log("¡%s te desafía!" % e.name)
	Sfx.play("zone")
	await get_tree().create_timer(1.3).timeout
	if test_hurt:
		pf.position = Vector3(-0.85, 0, 0)
		ef.position = Vector3(0.85, 0, 0)
		pf.set_health(0.2)
		pf.set_shield(0.3)
		ef.set_health(0.4)
		for k in 4:
			_blood(ef, 1.0, 20, true, "body")
			_blood(pf, -1.0, 12, false, "head")
		p.guard = true
		pf.guard = true
	busy = false
	_player_turn()


func _layout() -> void:
	var pp := Vector3(-FAR_GAP * 0.5, 0, 0)
	var ep := Vector3(FAR_GAP * 0.5, 0, 0)
	pf.position = pp
	ef.position = ep
	pf.rotation.y = _yaw(pp, ep)
	ef.rotation.y = _yaw(ep, pp)


func _refresh() -> void:
	ui.set_bars(p, e)


func _chance(att: Dictionary, defn: Dictionary, acc: float, anim: String = "") -> float:
	var extra := 0.0
	if anim == "high":
		extra = float(att.get("acc_high", 0.0))
	elif anim == "low":
		extra = float(att.get("acc_low", 0.0))
	if int(att.get("limp", 0)) > 0:
		extra -= 0.08
	var c := 0.72 + acc + extra + float(att.wacc) + (float(att.agi) - float(defn.agi)) * 0.02 + float(defn.get("evade", 0.0))
	return clampf(c, 0.12, 0.95)


func _raw_damage(att: Dictionary, mult: float) -> float:
	return (float(att.wdmg) + float(att.fue) * 1.5) * mult * rng.randf_range(0.9, 1.1)


func _crit_chance(att: Dictionary, near_melee: bool, zone: String) -> float:
	return 0.06 + (0.14 if near_melee else 0.0) + (0.06 if zone == "head" else 0.0) + float(att.fue) * 0.003


func _player_actions() -> Dictionary:
	var main: Array = []
	var far := _gap() > NEAR_GAP + 0.6
	for id in ["head", "body", "legs"]:
		var a: Dictionary = ACT[id]
		var ch := int(round(_chance(p, e, float(a.acc) - (0.1 if far else 0.0), String(a.anim)) * 100.0))
		var cr := int(round(_crit_chance(p, not far, String(a.zone)) * 100.0))
		main.append({"id": id, "label": a.label, "sub": "%d EN · %d%% · crít %d%%" % [int(a.cost), ch, cr], "enabled": float(p.en) >= float(a.cost), "icon": id})
	main.append({"id": "guard", "label": "DEFENDER", "sub": "+8 EN · escudo %d%%" % int(100.0 * float(p.shield_hp) / maxf(1.0, float(p.shield_max))) if float(p.shield_max) > 0.0 else "+8 EN · sin escudo", "enabled": true, "icon": "guard"})
	main.append({"id": "push", "label": "EMPUJAR", "sub": "6 EN · solo cerca", "enabled": not far and float(p.en) >= 6.0, "icon": "push"})
	if far:
		main.append({"id": "move", "label": "ACERCARSE", "sub": "3 EN · más críticos", "enabled": float(p.en) >= 3.0, "icon": "approach"})
	else:
		main.append({"id": "move", "label": "ALEJARSE", "sub": "2 EN · tiro a distancia", "enabled": float(p.en) >= 2.0, "icon": "retreat"})
	main.append({"id": "throw", "label": "LANZAR ARMA", "sub": "8 EN · pierdes el arma" if bool(p.armed) else "sin arma", "enabled": bool(p.armed) and float(p.en) >= 8.0, "icon": "throw"})
	var skills: Array = []
	for s in GameState.unlocked_skills():
		var sub := "%d EN" % int(s.en)
		if s.has("mult") or s.has("mag"):
			sub += " · %d%%" % int(round(_chance(p, e, float(s.acc)) * 100.0))
		if bool(s.get("ranged", false)):
			sub += " · a distancia"
		skills.append({"id": "skill:" + String(s.id), "label": String(s.name), "sub": sub, "enabled": float(p.en) >= float(s.en), "icon": "spell" if bool(s.get("ranged", false)) else ("heal" if s.has("heal") else "power")})
	var pots: Array = [
		{"id": "potion:vida", "label": "Poción de vida (x%d)" % GameState.potion_count("vida"), "sub": "+50% vida", "enabled": GameState.potion_count("vida") > 0, "icon": "potion_hp"},
		{"id": "potion:energia", "label": "Poción de energía (x%d)" % GameState.potion_count("energia"), "sub": "+60% energía", "enabled": GameState.potion_count("energia") > 0, "icon": "potion_en"},
	]
	return {"main": main, "skills": skills, "potions": pots, "near": not far}


func _player_turn() -> void:
	if state != State.BATTLE:
		return
	p.en = minf(float(p.max_en), float(p.en) + maxf(1.0, 3.0 + float(p.regen)))
	p.guard = false
	pf.guard = false
	p.limp = maxi(0, int(p.limp) - 1)
	_refresh()
	if int(p.stun) > 0:
		p.stun = int(p.stun) - 1
		ui.set_log("¡Estás aturdido! Pierdes el turno", Color("fca5a5"))
		busy = true
		await get_tree().create_timer(1.0).timeout
		await _enemy_turn()
		return
	busy = false
	ui.set_log("Tu turno" + (" · estás cerca" if _gap() <= NEAR_GAP + 0.6 else " · estás lejos"))
	ui.show_actions(_player_actions())


func _on_action(id: String) -> void:
	if busy or state != State.BATTLE:
		return
	busy = true
	ui.hide_actions()
	var ko := false
	if id == "guard":
		p.guard = true
		pf.guard = true
		p.en = minf(float(p.max_en), float(p.en) + 8.0)
		ui.set_log("Te cubres con el escudo")
		Sfx.play("shield")
		_refresh()
		await get_tree().create_timer(0.7).timeout
	elif id == "move":
		await _move(p, pf, ef)
	elif id == "push":
		ko = await _push(p, e, pf, ef)
	elif id == "throw":
		ko = await _throw(p, e, pf, ef)
	elif id.begins_with("potion:"):
		await _potion(id.substr(7))
	elif id.begins_with("skill:"):
		ko = await _skill(id.substr(6))
	else:
		ko = await _melee(p, e, pf, ef, ACT[id])
	if ko or state != State.BATTLE:
		return
	await _enemy_turn()


func _move(who: Dictionary, wf: Node3D, of: Node3D) -> void:
	var far := _gap() > NEAR_GAP + 0.6
	if far:
		who.en = float(who.en) - 3.0
		ui.set_log("%s se acerca" % ("Te acercas" if bool(who.is_player) else String(who.name)))
		var tx := of.position.x - _dir_to(wf, of) * NEAR_GAP
		await wf.walk(Vector3(tx, 0, 0), 0.6)
	else:
		who.en = float(who.en) - 2.0
		ui.set_log("%s retrocede" % ("Retrocedes" if bool(who.is_player) else String(who.name)))
		var tx := clampf(of.position.x - _dir_to(wf, of) * FAR_GAP, -5.5, 5.5)
		await wf.walk(Vector3(tx, 0, 0), 0.5)
	_refresh()
	await get_tree().create_timer(0.2).timeout


func _potion(kind: String) -> void:
	GameState.bump("potions", 1 if GameState.potion_count(kind) > 0 else 0)
	if not GameState.use_potion(kind):
		return
	pf.drink()
	Sfx.play("power")
	await get_tree().create_timer(0.5).timeout
	if kind == "vida":
		var h := float(p.max_hp) * 0.5
		p.hp = minf(float(p.max_hp), float(p.hp) + h)
		pf.set_health(float(p.hp) / float(p.max_hp))
		ui.float_text(pf.global_position + Vector3(0, 2.4, 0), "+%d" % int(h), Color("4ade80"))
		ui.set_log("¡Bebes una poción de vida!", Color("86efac"))
	else:
		var g := float(p.max_en) * 0.6
		p.en = minf(float(p.max_en), float(p.en) + g)
		ui.float_text(pf.global_position + Vector3(0, 2.4, 0), "+%d EN" % int(g), Color("7dd3fc"))
		ui.set_log("¡Bebes una poción de energía!", Color("7dd3fc"))
	_refresh()
	await get_tree().create_timer(0.6).timeout


func _skill(id: String) -> bool:
	var s: Dictionary = {}
	for k in GameState.SKILLS:
		if k.id == id:
			s = k
	if s.is_empty():
		return false
	GameState.bump("skills")
	if s.has("heal"):
		p.en = float(p.en) - float(s.en)
		pf.pray()
		Sfx.play("power")
		await get_tree().create_timer(0.5).timeout
		var h := float(p.max_hp) * float(s.heal)
		p.hp = minf(float(p.max_hp), float(p.hp) + h)
		pf.set_health(float(p.hp) / float(p.max_hp))
		ui.float_text(pf.global_position + Vector3(0, 2.4, 0), "+%d" % int(h), Color("4ade80"))
		ui.set_log("¡%s!" % s.name, Color("86efac"))
		_refresh()
		await get_tree().create_timer(0.6).timeout
		return false
	if bool(s.get("ranged", false)):
		return await _cast(p, e, pf, ef, s)
	var spec := {"label": s.name, "cost": s.en, "mult": s.mult, "acc": s.acc, "anim": "spin" if id == "torbellino" else ("mid" if id == "escudazo" else "power"), "zone": "body", "stun": int(s.get("stun", 0))}
	return await _melee(p, e, pf, ef, spec)


# --- daño, sangre y efectos ---
func _apply_damage(att: Dictionary, defn: Dictionary, af: Node3D, df: Node3D, dmg_in: float, o: Dictionary) -> void:
	var near_melee: bool = bool(o.get("near_melee", false))
	var zone := String(o.get("zone", ""))
	var crit := not bool(o.get("no_crit", false)) and rng.randf() < _crit_chance(att, near_melee, zone)
	var dmg := dmg_in
	if crit:
		dmg *= 1.5 + (0.3 if near_melee else 0.0)
		if bool(att.is_player):
			GameState.bump("crits")
		base_scale = Engine.time_scale
		Engine.time_scale = base_scale * 0.25
		get_tree().create_timer(0.16, true, false, true).timeout.connect(func(): Engine.time_scale = base_scale)
	var d := maxi(1, int(round(dmg)))
	if int(att.get("weak", 0)) > 0:
		d = maxi(1, int(d * 0.65))
		att.weak = 0
	var blocked := false
	var shield_ok := false
	var hit_pos := df.global_position + Vector3(0, 2.4, 0)
	if bool(defn.guard) and not bool(o.get("unblockable", false)):
		blocked = true
		if float(defn.shield_hp) > 0.0:
			shield_ok = true
			d = maxi(1, int(d * 0.35))
			defn.shield_hp = maxf(0.0, float(defn.shield_hp) - float(d) * 1.6 - 4.0)
			df.set_shield(float(defn.shield_hp) / float(defn.shield_max))
			if float(defn.shield_hp) <= 0.0:
				if bool(defn.is_player):
					defn.def = maxf(0.0, float(defn.def) - float(defn.shield_def))
				var piece = df.break_shield()
				if piece:
					debris.append(piece)
				ui.float_text(hit_pos + Vector3(0, 0.6, 0), "¡ESCUDO ROTO!", Color("fbbf24"), 30)
				Sfx.play("over", 1.6, -6.0)
		else:
			d = maxi(1, int(d * 0.7))
		defn.guard = false
		df.guard = false
		if not bool(o.get("no_react", false)):
			df.block_react()
		Sfx.play("shield", 0.9 + rng.randf() * 0.2)
	else:
		if not bool(o.get("no_react", false)):
			df.hit_react(bool(o.get("strong", false)) or crit)
		Sfx.play("hit", 0.9 + rng.randf() * 0.2)
	defn.hp = float(defn.hp) - d
	df.set_health(maxf(0.0, float(defn.hp)) / float(defn.max_hp))
	if not shield_ok:
		_blood(df, _dir_to(af, df), d, crit, zone)
	shake = 0.5 + (0.5 if crit else 0.0) + (0.3 if bool(o.get("strong", false)) else 0.0)
	var txt := "-%d" % d
	if crit:
		txt = "¡CRÍTICO! -%d" % d
	elif blocked:
		txt = "Bloqueado -%d" % d
	ui.float_text(hit_pos, txt, Color("fbbf24") if crit else (Color("93c5fd") if blocked else Color("ef4444")), 42 if crit else 34)
	if int(o.get("stun", 0)) > 0:
		defn.stun = int(o.stun)
	if String(o.get("zone", "")) == "legs" and not blocked:
		defn.limp = 2
		ui.float_text(hit_pos + Vector3(0, -0.7, 0), "¡Cojea!", Color("fca5a5"), 24)
	_refresh()


func _blood(df: Node3D, dirx: float, d: int, crit: bool, zone: String) -> void:
	var spark := String(df.kind) in ["knight", "titan"]
	var col: Color = Color("fde68a") if spark else df.blood_col
	var h := 1.15
	if zone == "head":
		h = 1.85
	elif zone == "legs":
		h = 0.5
	var origin := df.global_position + Vector3(0, h * df.scl * float(df.look.get("height", 1.0)), 0)
	var n := clampi(int(d / 3.0) + (7 if crit else 3), 4, 20)
	var mesh := Toon.sphere(0.055)
	for i in n:
		var drop := MeshInstance3D.new()
		drop.mesh = mesh
		drop.material_override = Toon.glow_mat(col)
		drop.position = origin
		add_child(drop)
		var vx := dirx * rng.randf_range(0.8, 4.2)
		var vy := rng.randf_range(1.5, 4.8)
		var vz := rng.randf_range(-1.6, 1.6)
		var tw := create_tween()
		tw.tween_method(func(tt: float): drop.position = origin + Vector3(vx * tt, vy * tt - 4.9 * tt * tt * 2.0, vz * tt), 0.0, 0.55, 0.55)
		tw.tween_callback(func():
			var land := drop.position
			drop.queue_free()
			if not spark:
				_stain(Vector3(land.x, 0.015, land.z), col))


func _stain(pos: Vector3, col: Color) -> void:
	var st := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var r := rng.randf_range(0.07, 0.24)
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = 0.012
	cyl.radial_segments = 10
	st.mesh = cyl
	st.material_override = Toon.glow_mat(col.darkened(0.15))
	st.position = Vector3(pos.x, 0.012 + rng.randf() * 0.004, pos.z)
	add_child(st)
	debris.append(st)
	if debris.size() > 140:
		var old = debris.pop_front()
		if is_instance_valid(old):
			(old as Node).queue_free()


# --- ataques ---
func _melee(att: Dictionary, defn: Dictionary, af: Node3D, df: Node3D, spec: Dictionary) -> bool:
	att.en = float(att.en) - float(spec.cost)
	_refresh()
	var far := _gap() > NEAR_GAP + 0.6
	ui.set_log("%s usa %s" % ["Tú" if bool(att.is_player) else String(att.name), String(spec.label)])
	var reach := maxf(0.0, _gap() - NEAR_GAP)
	var acc := float(spec.acc) - (0.1 if far else 0.0)
	var zone := String(spec.get("zone", "body"))
	await af.attack(String(spec.anim), reach, func():
		if rng.randf() < _chance(att, defn, acc, String(spec.anim)):
			_apply_damage(att, defn, af, df, _raw_damage(att, float(spec.mult)), {"near_melee": not far, "zone": zone, "strong": float(spec.mult) >= 1.5, "stun": int(spec.get("stun", 0))})
		else:
			df.dodge_react()
			Sfx.play("jump", 1.3, -4.0)
			ui.float_text(df.global_position + Vector3(0, 2.2, 0), "¡Falló!", Color("e5e7eb"), 30))
	return await _check_ko(att, defn, df)


func _check_ko(att: Dictionary, defn: Dictionary, df: Node3D) -> bool:
	if float(defn.hp) <= 0.0:
		await _end_fight(bool(att.is_player))
		return true
	await get_tree().create_timer(0.35).timeout
	return false


func _push(att: Dictionary, defn: Dictionary, af: Node3D, df: Node3D) -> bool:
	att.en = float(att.en) - 6.0
	_refresh()
	ui.set_log("%s empuja" % ("Empujas" if bool(att.is_player) else String(att.name)))
	await af.attack("mid", 0.0, func():
		_apply_damage(att, defn, af, df, _raw_damage(att, 0.25), {"no_crit": true, "no_react": true, "unblockable": true})
		defn.weak = 1
		defn.en = maxf(0.0, float(defn.en) - 5.0)
		var tx := clampf(af.position.x + _dir_to(af, df) * FAR_GAP, -5.5, 5.5)
		df.push_back(Vector3(tx, 0, 0))
		ui.float_text(df.global_position + Vector3(0, 3.0, 0), "¡Empujado! (golpea menos)", Color("93c5fd"), 22))
	return await _check_ko(att, defn, df)


func _throw(att: Dictionary, defn: Dictionary, af: Node3D, df: Node3D) -> bool:
	att.en = float(att.en) - 8.0
	_refresh()
	ui.set_log("¡%s lanza su arma!" % ("Lanzas" if bool(att.is_player) else String(att.name)))
	var wid := String(att.weapon_id)
	var raw := (float(att.wdmg) * 1.7 + float(att.fue) * 1.2) * rng.randf_range(0.9, 1.1)
	var hit := rng.randf() < _chance(att, defn, -0.04)
	var flight: Array = []
	await af.throw_anim(func():
		af.drop_weapon()
		att.armed = false
		var w: Node3D = af._make_weapon(wid)
		add_child(w)
		var from := af.global_position + Vector3(0, 1.7 * af.scl, 0) + (-af.global_transform.basis.z) * 0.5
		w.global_position = from
		var target := df.global_position + Vector3(0, 1.2 * df.scl, 0)
		if not hit:
			target += Vector3(_dir_to(af, df) * 1.6, -0.9, 0.5)
		var dur := clampf(from.distance_to(target) / 13.0, 0.25, 0.6)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(w, "global_position", target, dur)
		tw.tween_property(w, "rotation:z", -_dir_to(af, df) * TAU * 2.5, dur)
		debris.append(w)
		flight.append(tw)
		Sfx.play("jump", 0.7))
	if flight.size() > 0:
		await (flight[0] as Tween).finished
	att.wdmg = 3
	att.wacc = -0.06
	if hit:
		_apply_damage(att, defn, af, df, raw, {"zone": "body", "strong": true, "near_melee": false})
	else:
		df.dodge_react()
		ui.float_text(df.global_position + Vector3(0, 2.2, 0), "¡Falló!", Color("e5e7eb"), 30)
	return await _check_ko(att, defn, df)


func _cast(att: Dictionary, defn: Dictionary, af: Node3D, df: Node3D, spec: Dictionary) -> bool:
	att.en = float(att.en) - float(spec.en)
	_refresh()
	ui.set_log("¡%s lanza %s!" % ["Tú" if bool(att.is_player) else String(att.name), String(spec.name)])
	var col := Color(String(spec.get("color", "f97316")))
	var from: Vector3 = await af.cast_start(col)
	Sfx.play("power", 1.3)
	var ball := Node3D.new()
	Toon.glow(ball, Toon.sphere(0.22), col.lightened(0.5))
	Toon.glow(ball, Toon.sphere(0.42), col, Vector3.ZERO, Vector3.ZERO, 0.45)
	add_child(ball)
	ball.global_position = from
	if af.orb:
		af.orb.visible = false
	var target := df.global_position + Vector3(0, 1.2 * df.scl, 0)
	var dur := clampf(from.distance_to(target) / 12.0, 0.3, 0.7)
	var tw := create_tween()
	tw.tween_property(ball, "global_position", target, dur)
	await tw.finished
	ball.queue_free()
	for i in 10:
		var sp := MeshInstance3D.new()
		sp.mesh = BoxMesh.new()
		(sp.mesh as BoxMesh).size = Vector3(0.12, 0.12, 0.12)
		sp.material_override = Toon.glow_mat(col)
		sp.position = target
		add_child(sp)
		var tw2 := create_tween().set_parallel(true)
		tw2.tween_property(sp, "position", target + Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.2, 1.2), rng.randf_range(-1, 1)), 0.35)
		tw2.tween_property(sp, "scale", Vector3.ZERO, 0.35)
		tw2.chain().tween_callback(sp.queue_free)
	if rng.randf() < _chance(att, defn, float(spec.acc)):
		var raw := float(att.magic) * float(spec.mag) * rng.randf_range(0.9, 1.1) + 4.0
		_apply_damage(att, defn, af, df, raw - float(defn.def) * 0.2, {"zone": "body", "strong": true, "near_melee": false})
	else:
		df.dodge_react()
		ui.float_text(df.global_position + Vector3(0, 2.2, 0), "¡Falló!", Color("e5e7eb"), 30)
	await af.cast_end()
	return await _check_ko(att, defn, df)


# --- turno del rival ---
func _enemy_turn() -> void:
	if state != State.BATTLE:
		return
	busy = true
	e.en = minf(float(e.max_en), float(e.en) + 3.0)
	e.guard = false
	ef.guard = false
	e.limp = maxi(0, int(e.limp) - 1)
	_refresh()
	if int(e.stun) > 0:
		e.stun = int(e.stun) - 1
		ui.set_log("%s está aturdido" % e.name, Color("86efac"))
		await get_tree().create_timer(1.0).timeout
		_player_turn()
		return
	var ko := false
	var en_now := float(e.en)
	var hp_ratio := float(e.hp) / float(e.max_hp)
	var far := _gap() > NEAR_GAP + 0.6
	var boss: bool = bool(e.get("boss", false))
	var kindn := String(e.look.kind)
	var r := rng.randf()
	if boss and hp_ratio < 0.3 and not enemy_potion:
		enemy_potion = true
		ef.drink()
		Sfx.play("power")
		await get_tree().create_timer(0.6).timeout
		var h := float(e.max_hp) * 0.35
		e.hp = minf(float(e.max_hp), float(e.hp) + h)
		ef.set_health(float(e.hp) / float(e.max_hp))
		ui.float_text(ef.global_position + Vector3(0, 2.4, 0), "+%d" % int(h), Color("4ade80"))
		ui.set_log("¡%s bebe una poción!" % e.name, Color("fca5a5"))
		_refresh()
		await get_tree().create_timer(0.7).timeout
	elif en_now < 5.0:
		e.guard = true
		ef.guard = true
		e.en = minf(float(e.max_en), en_now + 8.0)
		ui.set_log("%s se cubre" % e.name)
		_refresh()
		await get_tree().create_timer(0.8).timeout
	elif far:
		if kindn in ["demon", "titan", "knight"] and en_now >= 16.0 and r < 0.45:
			var sp := {"name": "Bola de fuego", "en": 16, "mag": 1.0, "acc": 0.0, "color": "ef4444" if kindn != "titan" else "38bdf8"}
			ko = await _cast(e, p, ef, pf, sp)
		elif bool(e.armed) and kindn in ["human", "orc", "skeleton", "lizard"] and r < 0.14 and en_now >= 8.0:
			ko = await _throw(e, p, ef, pf)
		elif r < 0.55 and en_now >= 3.0:
			await _move(e, ef, pf)
		else:
			ko = await _melee(e, p, ef, pf, ACT["body"])
	else:
		var spec: Dictionary = ACT["body"]
		if boss and en_now >= 24.0 and r < 0.28:
			spec = {"label": "Golpe devastador", "cost": 24, "mult": 2.5, "acc": -0.1, "anim": "power", "zone": "body"}
		elif r < 0.12 and en_now >= 6.0:
			ko = await _push(e, p, ef, pf)
			spec = {}
		elif r < 0.3:
			spec = ACT["legs"]
		elif r < 0.52 and en_now >= 10.0:
			spec = ACT["head"]
		elif r > 0.93:
			spec = {"label": "Guardia"}
		if spec.has("cost"):
			ko = await _melee(e, p, ef, pf, spec)
		elif spec.has("label"):
			e.guard = true
			ef.guard = true
			e.en = minf(float(e.max_en), en_now + 8.0)
			ui.set_log("%s se cubre" % e.name)
			_refresh()
			await get_tree().create_timer(0.8).timeout
	if ko or state != State.BATTLE:
		return
	_player_turn()


func _end_fight(win: bool, surrender: bool = false) -> void:
	if state != State.BATTLE:
		return
	state = State.RESULT
	busy = true
	ui.hide_actions()
	arena.set_cheer(2.0 if win else 0.4)
	var lines: Array = []
	if win:
		ef.die()
		pf.victory()
		Sfx.play("win")
		ui.set_log("¡VICTORIA!", Color("4ade80"))
		var first_time := not GameState.fight_won(fight_idx)
		if bool(e.get("boss", false)) and first_time:
			GameState.bump("bosses")
		if float(p.hp) >= float(p.max_hp):
			GameState.bump("flawless")
		var res: Array = GameState.register_win(fight_idx)
		var r: Dictionary = res[0]
		lines.append("Ganaste ● %d de oro" % int(r.gold))
		lines.append("Ganaste %d XP" % int(r.xp))
		for m in res[1]:
			lines.append(String(m))
		if fight_idx + 1 < GameState.ENEMIES.size() and int(GameState.ENEMIES[fight_idx + 1].arena) != int(GameState.ENEMIES[fight_idx].arena):
			lines.append("¡Nueva arena desbloqueada!")
		elif fight_idx + 1 >= GameState.ENEMIES.size():
			lines.append("¡Eres el campeón de la arena!")
	else:
		if not surrender:
			pf.die()
		Sfx.play("over")
		ui.set_log("Has caído..." if not surrender else "Te rindes", Color("f87171"))
		GameState.register_loss()
		lines.append("Perdiste contra %s" % e.name)
		lines.append("Consuelo: +12 de oro")
		lines.append("Entrena, compra mejor equipo y vuelve.")
	lines.append_array(GameState.new_achievements())
	await get_tree().create_timer(1.8).timeout
	ui.show_result(win, "¡VICTORIA!" if win else "DERROTA", lines, not (win and fight_idx + 1 >= GameState.ENEMIES.size()))


func _after_result() -> void:
	if state != State.RESULT:
		return
	var next := fight_idx
	if float(e.hp) <= 0.0 and fight_idx + 1 < GameState.ENEMIES.size():
		next = fight_idx + 1
	_start_fight(next)


# ---------- Bot de pruebas ----------
func _bot(delta: float) -> void:
	bot_wait -= delta
	if bot_wait > 0.0:
		return
	bot_wait = 0.25
	match state:
		State.MENU:
			if frame_count > 20 and test_fight < 0:
				_start_fight(0)
		State.BATTLE:
			if busy or not ui.act_panel.visible:
				return
			var far := _gap() > NEAR_GAP + 0.6
			var pick := "body"
			var r := rng.randf()
			var ranged := ""
			for s in GameState.unlocked_skills():
				if bool(s.get("ranged", false)) and float(p.en) >= float(s.en) + 4.0:
					ranged = "skill:" + String(s.id)
			if float(p.hp) < float(p.max_hp) * 0.35 and GameState.potion_count("vida") > 0:
				pick = "potion:vida"
			elif float(p.en) < 6.0:
				pick = "guard"
			elif far:
				if ranged != "" and r < 0.35:
					pick = ranged
				elif bool(p.armed) and r < 0.45 and float(p.en) >= 12.0:
					pick = "throw"
				elif r < 0.8:
					pick = "move"
				else:
					pick = "body"
			else:
				if r < 0.1 and float(p.en) >= 8.0:
					pick = "push"
				elif r < 0.4 and float(p.en) >= 12.0:
					pick = "head"
				elif r < 0.55:
					pick = "legs"
				elif GameState.unlocked_skills().size() > 0 and float(p.en) >= 22.0 and r < 0.7:
					var us: Array = GameState.unlocked_skills()
					pick = "skill:" + String(us[0].id)
			_on_action(pick)
		State.RESULT:
			if ui.pages["result"].visible:
				wins_seen += 1
				print("[test] fight %d result: hp_p=%d hp_e=%d gold=%d level=%d" % [fight_idx, int(p.hp), int(e.hp), int(GameState.data.gold), GameState.level()])
				if wins_seen > 3:
					get_tree().quit()
				else:
					_after_result()


# ---------- Actualizaciones desde GitHub ----------
const REPO := "dysasterkj/Arena-de-titanes-"
var update_url := ""
var _dl_id := -1
var _dl_started := false
var _dl_timer: Timer
var _dl_ticks := 0
var _dl_dm
var _dl_ctx


func _version_newer(remote: String, local: String) -> bool:
	var r := remote.trim_prefix("v").split(".")
	var l := local.trim_prefix("v").split(".")
	for i in 3:
		var a := int(r[i]) if i < r.size() else 0
		var b := int(l[i]) if i < l.size() else 0
		if a != b:
			return a > b
	return false


func _check_update() -> void:
	if autoplay or shot_path != "":
		return
	var http := HTTPRequest.new()
	http.timeout = 8.0
	add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			return
		var json = JSON.parse_string(body.get_string_from_utf8())
		if not (json is Dictionary):
			return
		var tag := String(json.get("tag_name", ""))
		var local := String(ProjectSettings.get_setting("application/config/version", "0.0.0"))
		if tag == "" or not _version_newer(tag, local):
			return
		update_url = String(json.get("html_url", "https://github.com/%s/releases/latest" % REPO))
		for a in json.get("assets", []):
			if String(a.get("name", "")).ends_with(".apk"):
				update_url = String(a.get("browser_download_url", update_url))
		ui.set_update(tag, String(json.get("body", ""))))
	http.request("https://api.github.com/repos/%s/releases/latest" % REPO, ["User-Agent: arena-de-titanes"])


func _android_ok() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton("AndroidRuntime")


func _update_apk_path() -> String:
	var rt = Engine.get_singleton("AndroidRuntime")
	var dir = rt.getApplicationContext().getExternalFilesDir("")
	if dir == null:
		return ""
	return String(dir.getAbsolutePath()) + "/update.apk"


func _cleanup_update_file() -> void:
	if not _android_ok():
		return
	var path := _update_apk_path()
	if path != "" and FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _fallback_update() -> void:
	_dl_id = -1
	if _dl_timer:
		_dl_timer.queue_free()
		_dl_timer = null
	ui.set_update_status("Abriendo descarga en el navegador…")
	OS.shell_open(update_url)


func _open_update() -> void:
	if update_url == "":
		return
	if not _android_ok():
		OS.shell_open(update_url)
		return
	if _dl_id >= 0:
		return
	_dl_started = false
	get_tree().create_timer(4.0).timeout.connect(func():
		if not _dl_started and _dl_id < 0:
			_fallback_update())
	var rt = Engine.get_singleton("AndroidRuntime")
	_dl_ctx = rt.getApplicationContext()
	_dl_dm = _dl_ctx.getSystemService("download") if _dl_ctx else null
	ui.set_update_status("Preparando descarga (1/3)…")
	if _dl_dm == null:
		_fallback_update()
		return
	_cleanup_update_file()
	var Uri = JavaClassWrapper.wrap("android.net.Uri")
	var Req = JavaClassWrapper.wrap("android.app.DownloadManager$Request")
	var req = Req.call("DownloadManager$Request", Uri.parse(update_url)) if Req and Uri else null
	if req == null:
		_fallback_update()
		return
	req.setTitle("Arena de Titanes")
	req.setDescription("Descargando actualización")
	req.setNotificationVisibility(1)
	req.setMimeType("application/vnd.android.package-archive")
	var apk_path := _update_apk_path()
	var JFile = JavaClassWrapper.wrap("java.io.File")
	var dest = Uri.fromFile(JFile.File(apk_path)) if apk_path != "" and JFile else null
	if dest == null:
		_fallback_update()
		return
	req.setDestinationUri(dest)
	_dl_id = int(_dl_dm.enqueue(req))
	_dl_started = true
	_dl_ticks = 0
	ui.set_update_status("Descargando (2/3)…")
	_dl_timer = Timer.new()
	_dl_timer.wait_time = 1.0
	add_child(_dl_timer)
	_dl_timer.timeout.connect(_poll_download)
	_dl_timer.start()


func _poll_download() -> void:
	_dl_ticks += 1
	var uri = _dl_dm.getUriForDownloadedFile(_dl_id)
	if uri != null:
		_dl_timer.queue_free()
		_dl_timer = null
		_dl_id = -1
		_install_uri(uri)
		return
	ui.set_update_status("Descargando actualización" + ".".repeat(_dl_ticks % 4))
	if _dl_ticks > 300:
		_fallback_update()


func _install_uri(uri) -> void:
	var rt = Engine.get_singleton("AndroidRuntime")
	var activity = rt.getActivity()
	var Intent = JavaClassWrapper.wrap("android.content.Intent")
	var intent = Intent.Intent(Intent.ACTION_VIEW) if Intent else null
	if intent == null or activity == null:
		_fallback_update()
		return
	ui.set_update_status("Abriendo instalador (3/3)…")
	intent.setDataAndType(uri, "application/vnd.android.package-archive")
	intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK)
	activity.startActivity(intent)
	ui.set_update_status("Listo: confirma la instalación")
