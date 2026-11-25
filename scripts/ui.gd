extends CanvasLayer
## Interfaz: menú, combates, forja, entrenamiento, resultados y barra de batalla.

signal fight_selected(index: int)
signal action_pressed(id: String)
signal surrender_pressed
signal continue_pressed
signal retry_pressed
signal preview_changed
signal update_pressed
signal page_changed(page: String)

var W := 540.0
var H := 960.0

const C_GOLD := Color("fbbf24")
const C_RED := Color("ef4444")
const C_BLUE := Color("38bdf8")
const C_PANEL := Color(0.09, 0.06, 0.05, 0.93)
const C_MUTED := Color("c9b8a6")
const C_GREEN := Color("4ade80")
const C_BTN := Color("b45309")
const C_DARK := Color("57534e")

var root: Control
var pages: Dictionary = {}
var menu_gold: Label
var menu_level: Label
var menu_xp: ProgressBar
var music_btn: Button
var sfx_btn: Button
var fights_box: VBoxContainer
var shop_box: VBoxContainer
var shop_tab := "weapon"
var train_box: VBoxContainer
var result_box: VBoxContainer
var update_box: VBoxContainer
var upd_status: Label
var update_banner: Control
var update_lbl: Label

# batalla
var e_name: Label
var e_hp: ProgressBar
var e_en: ProgressBar
var p_name: Label
var p_hp: ProgressBar
var p_en: ProgressBar
var p_hp_lbl: Label
var p_en_lbl: Label
var e_hp_lbl: Label
var log_lbl: Label
var act_box: VBoxContainer
var act_panel: Control
var float_layer: Control
var camera_ref: Camera3D
var sub_mode := "main"
var cur_actions: Dictionary = {}


func _ready() -> void:
	layer = 10
	var vs := get_viewport().get_visible_rect().size
	W = vs.x
	H = vs.y
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_menu()
	_build_fights()
	_build_shop()
	_build_train()
	_build_battle()
	_build_result()
	_build_char()
	_build_update()
	show_menu()


# ---------- Utilidades ----------
func _lbl(text: String, size: int = 22, color: Color = Color.WHITE, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.04, 0.02, 0.95))
	l.add_theme_constant_override("outline_size", maxi(2, int(size * 0.14)))
	l.horizontal_alignment = align as HorizontalAlignment
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _place(c: Control, x: float, y: float, w: float, h: float) -> void:
	c.position = Vector2(x, y)
	c.size = Vector2(w, h)


func _sb(bg: Color, radius: int = 16, border: Color = Color(0, 0, 0, 0), bw: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(bw)
	return s


func _btn(text: String, color: Color, size: int = 24, w: float = 300.0, h: float = 60.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = true
	b.add_theme_font_size_override("font_size", size)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var c := color
		if st == "hover":
			c = color.lightened(0.1)
		elif st == "pressed":
			c = color.darkened(0.22)
		elif st == "disabled":
			c = Color(0.25, 0.22, 0.2)
		var s := _sb(c, 16, c.lightened(0.35) if st != "disabled" else Color(0.38, 0.34, 0.3), 3)
		s.shadow_size = 5
		s.shadow_color = Color(0, 0, 0, 0.4)
		s.shadow_offset = Vector2(0, 3)
		b.add_theme_stylebox_override(st, s)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.65, 0.6, 0.55))
	b.pressed.connect(func(): Sfx.play("click"))
	return b


func _page(id: String) -> Control:
	var p := Control.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(p)
	pages[id] = p
	return p


func _dim(p: Control, a: float = 0.55) -> void:
	var d := ColorRect.new()
	d.color = Color(0.05, 0.02, 0.01, a)
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(d)


func _panel(parent: Control, rect: Rect2) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(C_PANEL, 24, Color("a16207"), 3))
	parent.add_child(pc)
	_place(pc, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 18)
	pc.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	return v


func _clear(box: Control) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _center(parent: Control, c: Control) -> void:
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(c)
	parent.add_child(hb)


func _bar(color: Color, w: float = 240.0, h: float = 16.0) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(w, h)
	pb.add_theme_stylebox_override("background", _sb(Color(0, 0, 0, 0.55), 8, Color(1, 1, 1, 0.25), 1))
	pb.add_theme_stylebox_override("fill", _sb(color, 8))
	return pb


func _show(id: String) -> void:
	for k in pages:
		(pages[k] as Control).visible = (k == id)
	page_changed.emit(id)


func _back_row(parent: Control, text: String = "VOLVER") -> void:
	var back := _btn(text, Color("78350f"), 22, 200, 52)
	back.pressed.connect(show_menu)
	_center(parent, back)


# ---------- Menú ----------
func _build_menu() -> void:
	var m := _page("menu")
	var t1 := _lbl("ARENA DE", 40, Color("fde68a"), HORIZONTAL_ALIGNMENT_CENTER)
	m.add_child(t1)
	_place(t1, 0, 50, W, 52)
	var t2 := _lbl("TITANES", 84, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	t2.add_theme_color_override("font_outline_color", Color("7c2d12"))
	t2.add_theme_constant_override("outline_size", 14)
	m.add_child(t2)
	_place(t2, 0, 96, W, 104)
	menu_gold = _lbl("", 26, C_GOLD)
	m.add_child(menu_gold)
	_place(menu_gold, 24, 214, 250, 36)
	menu_level = _lbl("", 22, Color("fde68a"), HORIZONTAL_ALIGNMENT_RIGHT)
	m.add_child(menu_level)
	_place(menu_level, W - 274, 216, 250, 32)
	menu_xp = _bar(Color("a78bfa"), 250, 12)
	m.add_child(menu_xp)
	_place(menu_xp, W - 274, 250, 250, 12)

	music_btn = _btn("", Color("57534e"), 15, 130, 38)
	m.add_child(music_btn)
	_place(music_btn, 24, 262, 130, 38)
	music_btn.pressed.connect(func():
		GameState.data.music = not GameState.data.music
		Sfx.set_options(bool(GameState.data.music), bool(GameState.data.sfx))
		GameState.save_game()
		_refresh_toggles())
	sfx_btn = _btn("", Color("57534e"), 15, 130, 38)
	m.add_child(sfx_btn)
	_place(sfx_btn, 162, 262, 130, 38)
	sfx_btn.pressed.connect(func():
		GameState.data.sfx = not GameState.data.sfx
		Sfx.set_options(bool(GameState.data.music), bool(GameState.data.sfx))
		GameState.save_game()
		_refresh_toggles())

	update_banner = Control.new()
	update_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(update_banner)
	_place(update_banner, 24, 312, W - 48, 60)
	var ub := Panel.new()
	ub.add_theme_stylebox_override("panel", _sb(Color(0.9, 0.4, 0.1, 0.92), 16, Color(1, 1, 1, 0.5), 2))
	update_banner.add_child(ub)
	_place(ub, 0, 0, W - 48, 60)
	update_lbl = _lbl("", 17, Color.WHITE)
	update_banner.add_child(update_lbl)
	_place(update_lbl, 14, 16, 280, 30)
	var upb := _btn("ACTUALIZAR", Color("0d9488"), 15, 140, 42)
	update_banner.add_child(upb)
	_place(upb, W - 48 - 154, 9, 140, 42)
	upb.pressed.connect(func(): update_pressed.emit())
	update_banner.visible = false

	var vl := _lbl("v" + String(ProjectSettings.get_setting("application/config/version", "0.0.0")), 14, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
	m.add_child(vl)
	_place(vl, 0, H - 26, W, 20)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(vb)
	_place(vb, 40, H - 340, W - 80, 310)
	var fight := _btn("COMBATIR", Color("b91c1c"), 36, 440, 84)
	fight.pressed.connect(open_fights)
	vb.add_child(fight)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	var forge := _btn("FORJA", C_BTN, 22, 215, 58)
	forge.pressed.connect(func(): open_shop())
	g.add_child(forge)
	var train := _btn("ENTRENAR", Color("1d4ed8"), 22, 215, 58)
	train.pressed.connect(open_train)
	g.add_child(train)
	var chb := _btn("PERSONAJE", Color("7e22ce"), 22, 215, 58)
	chb.pressed.connect(open_char)
	g.add_child(chb)
	ach_btn = _btn("LOGROS", Color("15803d"), 22, 215, 58)
	ach_btn.pressed.connect(open_ach)
	g.add_child(ach_btn)
	vb.add_child(g)


func _refresh_toggles() -> void:
	music_btn.text = "Música: " + ("sí" if GameState.data.music else "no")
	sfx_btn.text = "Sonidos: " + ("sí" if GameState.data.sfx else "no")


func show_menu() -> void:
	menu_gold.text = "● %d" % int(GameState.data.gold)
	var pr: Array = GameState.xp_progress()
	menu_level.text = "Nivel %d" % GameState.level()
	var nready := GameState.ach_ready()
	ach_btn.text = "LOGROS" + (" (%d)" % nready if nready > 0 else "")
	menu_xp.max_value = float(pr[1])
	menu_xp.value = float(pr[0])
	_refresh_toggles()
	_show("menu")
	preview_changed.emit()


func set_update(version: String, notes: String) -> void:
	update_lbl.text = "Nueva versión %s" % version
	update_banner.visible = true
	_clear(update_box)
	update_box.add_child(_lbl("¡NUEVA VERSIÓN!", 34, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	update_box.add_child(_lbl("Ya está disponible %s" % version, 21, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var nl := _lbl(notes if notes != "" else "Mejoras y novedades.", 16, C_MUTED)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.custom_minimum_size = Vector2(400, 0)
	sc.add_child(nl)
	update_box.add_child(sc)
	upd_status = _lbl("", 17, C_GREEN, HORIZONTAL_ALIGNMENT_CENTER)
	update_box.add_child(upd_status)
	var up := _btn("ACTUALIZAR AHORA", Color("0d9488"), 24, 340, 64)
	up.pressed.connect(func(): update_pressed.emit())
	_center(update_box, up)
	var later := _btn("MÁS TARDE", C_DARK, 20, 340, 50)
	later.pressed.connect(show_menu)
	_center(update_box, later)
	if pages["menu"].visible:
		_show("update")


func set_update_status(text: String) -> void:
	update_lbl.text = text
	if upd_status:
		upd_status.text = text


func _build_update() -> void:
	var p := _page("update")
	_dim(p, 0.7)
	update_box = _panel(p, Rect2(30, (H - 520) * 0.5, W - 60, 520))


# ---------- Lista de combates ----------
func _build_fights() -> void:
	var p := _page("fights")
	_dim(p)
	fights_box = _panel(p, Rect2(16, 30, W - 32, H - 60))


func open_fights() -> void:
	_clear(fights_box)
	fights_box.add_child(_lbl("ELIGE TU COMBATE", 34, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	sc.add_child(v)
	var last_arena := -1
	for i in GameState.ENEMIES.size():
		var e: Dictionary = GameState.ENEMIES[i]
		if int(e.arena) != last_arena:
			last_arena = int(e.arena)
			v.add_child(_lbl(String(GameState.ARENAS[last_arena].name), 20, C_GOLD))
		var open := GameState.fight_unlocked(i)
		var won := GameState.fight_won(i)
		var r := GameState.reward_for(i, not won)
		var label := "%d. %s%s" % [i + 1, e.name, "   ★ JEFE" if bool(e.get("boss", false)) else ""]
		var sub := "Premio: ● %d · %d XP%s" % [int(r.gold), int(r.xp), "   (ganado)" if won else ""]
		var b := _btn("%s\n%s" % [label, sub] if open else "%d. ???  (bloqueado)" % (i + 1), Color("15803d") if won else (Color("b91c1c") if bool(e.get("boss", false)) else C_BTN), 17, 440, 66)
		b.disabled = not open
		var idx := i
		b.pressed.connect(func(): fight_selected.emit(idx))
		v.add_child(b)
	fights_box.add_child(sc)
	_back_row(fights_box)
	_show("fights")


# ---------- Forja ----------
func _build_shop() -> void:
	var p := _page("shop")
	shop_box = _panel(p, Rect2(10, H - 560, W - 20, 548))


func open_shop(tab: String = "") -> void:
	if tab != "":
		shop_tab = tab
	_clear(shop_box)
	var top := GridContainer.new()
	top.columns = 4
	top.add_theme_constant_override("h_separation", 5)
	top.add_theme_constant_override("v_separation", 5)
	for t in GameState.TABS:
		var tb := _btn(String(GameState.TAB_NAMES[t]), Color("b91c1c") if t == shop_tab else C_DARK, 14, 116, 36)
		var tt: String = t
		tb.pressed.connect(func(): open_shop(tt))
		top.add_child(tb)
	var topc := HBoxContainer.new()
	topc.alignment = BoxContainer.ALIGNMENT_CENTER
	topc.add_child(top)
	shop_box.add_child(topc)
	shop_box.add_child(_lbl("● %d" % int(GameState.data.gold), 24, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	sc.add_child(v)
	if shop_tab == "potion":
		for id in GameState.POTIONS:
			var pd: Dictionary = GameState.POTIONS[id]
			v.add_child(_potion_row(id, pd))
	else:
		for it in GameState.items(shop_tab):
			v.add_child(_item_row(it))
	shop_box.add_child(sc)
	_back_row(shop_box)
	_show("shop")


func _item_row(it: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stat_txt := ("Daño %d" % int(it.dmg)) if it.has("dmg") else (("Defensa +%d" % int(it.def)) if it.has("def") else "Estilo")
	tv.add_child(_lbl("%s   (%s)" % [it.name, stat_txt], 17, Color.WHITE))
	var dl := _lbl(String(it.desc), 13, C_MUTED)
	tv.add_child(dl)
	row.add_child(tv)
	var tab := shop_tab
	var id: String = it.id
	var owned := GameState.owns(tab, id)
	var b: Button
	if owned:
		if GameState.equipped(tab) == id:
			b = _btn("EQUIPADO", Color("166534"), 14, 120, 48)
			b.disabled = true
		else:
			b = _btn("EQUIPAR", Color("0d9488"), 16, 120, 48)
			b.pressed.connect(func():
				GameState.equip(tab, id)
				preview_changed.emit()
				open_shop())
	else:
		b = _btn("● %d" % int(it.cost), C_BTN, 16, 120, 48)
		b.disabled = int(GameState.data.gold) < int(it.cost)
		b.pressed.connect(func():
			if GameState.buy_item(tab, id):
				Sfx.play("buy")
				preview_changed.emit()
				open_shop())
	row.add_child(b)
	return row


func _potion_row(id: String, pd: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(_lbl("%s   x%d" % [pd.name, GameState.potion_count(id)], 17, Color.WHITE))
	tv.add_child(_lbl(String(pd.desc), 13, C_MUTED))
	row.add_child(tv)
	var b := _btn("● %d" % int(pd.cost), C_BTN, 16, 120, 48)
	b.disabled = int(GameState.data.gold) < int(pd.cost)
	b.pressed.connect(func():
		if GameState.buy_potion(id):
			Sfx.play("buy")
			open_shop("potion"))
	row.add_child(b)
	return row


# ---------- Entrenamiento ----------
func _build_train() -> void:
	var p := _page("train")
	train_box = _panel(p, Rect2(10, H - 640, W - 20, 628))


func open_train() -> void:
	_clear(train_box)
	train_box.add_child(_lbl("ENTRENAMIENTO", 32, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var pr: Array = GameState.xp_progress()
	train_box.add_child(_lbl("Nivel %d   ·   XP %d/%d   ·   ● %d   ·   Puntos: %d" % [GameState.level(), int(pr[0]), int(pr[1]), int(GameState.data.gold), int(GameState.data.points)], 17, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var pf := GameState.player_fighter()
	var dmg := int(pf.wdmg + pf.fue * 1.5)
	train_box.add_child(_lbl("Vida %d · Energía %d · Daño %d · Defensa %d" % [int(pf.max_hp), int(pf.max_en), dmg, int(pf.def)], 16, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	for s in GameState.STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(_lbl("%s   %d" % [GameState.STAT_NAMES[s], GameState.stat(s)], 20, Color.WHITE))
		tv.add_child(_lbl(String(GameState.STAT_DESC[s]), 13, C_MUTED))
		row.add_child(tv)
		var sid: String = s
		var bp := _btn("+1 PUNTO", Color("7e22ce"), 13, 100, 46)
		bp.disabled = int(GameState.data.points) <= 0
		bp.pressed.connect(func():
			if GameState.train_with_point(sid):
				Sfx.play("buy")
			open_train())
		row.add_child(bp)
		var bg := _btn("+1  ● %d" % GameState.train_cost(s), C_BTN, 14, 112, 46)
		bg.disabled = int(GameState.data.gold) < GameState.train_cost(s)
		bg.pressed.connect(func():
			if GameState.train_with_gold(sid):
				Sfx.play("buy")
			open_train())
		row.add_child(bg)
		train_box.add_child(row)
	var sk := "Poderes: "
	var names: Array = []
	for s in GameState.SKILLS:
		names.append(("%s (nv %d)" % [s.name, int(s.lvl)]) if GameState.level() >= int(s.lvl) else "??? (nv %d)" % int(s.lvl))
	var sl := _lbl(sk + ", ".join(names), 14, Color("c4b5fd"), HORIZONTAL_ALIGNMENT_CENTER)
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sl.custom_minimum_size = Vector2(440, 0)
	train_box.add_child(sl)
	_back_row(train_box)
	_show("train")


# ---------- Batalla ----------
func _build_battle() -> void:
	var b := _page("battle")
	# panel del rival (arriba izquierda)
	var ep := Panel.new()
	ep.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.04, 0.03, 0.82), 16, Color("a16207"), 2))
	b.add_child(ep)
	_place(ep, 12, 14, 290, 84)
	e_name = _lbl("", 20, Color.WHITE)
	b.add_child(e_name)
	_place(e_name, 24, 18, 266, 28)
	e_hp = _bar(C_RED, 262, 14)
	b.add_child(e_hp)
	_place(e_hp, 24, 50, 262, 14)
	e_en = _bar(C_BLUE, 262, 8)
	b.add_child(e_en)
	_place(e_en, 24, 70, 262, 8)
	e_hp_lbl = _lbl("", 11, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	b.add_child(e_hp_lbl)
	_place(e_hp_lbl, 24, 49, 262, 16)

	# panel del jugador (derecha, sobre el menú)
	var pp := Panel.new()
	pp.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.04, 0.03, 0.82), 16, Color("a16207"), 2))
	b.add_child(pp)
	_place(pp, W - 302, H - 496, 290, 92)
	p_name = _lbl("Tú", 20, Color.WHITE)
	b.add_child(p_name)
	_place(p_name, W - 290, H - 492, 266, 28)
	p_hp = _bar(C_RED, 262, 16)
	b.add_child(p_hp)
	_place(p_hp, W - 290, H - 462, 262, 16)
	p_hp_lbl = _lbl("", 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	b.add_child(p_hp_lbl)
	_place(p_hp_lbl, W - 290, H - 462, 262, 16)
	p_en = _bar(C_BLUE, 262, 14)
	b.add_child(p_en)
	_place(p_en, W - 290, H - 438, 262, 14)
	p_en_lbl = _lbl("", 11, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	b.add_child(p_en_lbl)
	_place(p_en_lbl, W - 290, H - 438, 262, 14)

	# mensaje
	log_lbl = _lbl("", 22, Color("fde68a"), HORIZONTAL_ALIGNMENT_CENTER)
	log_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_child(log_lbl)
	_place(log_lbl, 20, 112, W - 40, 70)

	# menú de acciones
	act_panel = Control.new()
	act_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(act_panel)
	var bg := Panel.new()
	bg.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.04, 0.03, 0.92), 22, Color("a16207"), 3))
	act_panel.add_child(bg)
	_place(bg, 8, H - 396, W - 16, 388)
	act_box = VBoxContainer.new()
	act_box.add_theme_constant_override("separation", 7)
	act_panel.add_child(act_box)
	_place(act_box, 18, H - 388, W - 36, 372)

	float_layer = Control.new()
	float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	float_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(float_layer)


func show_battle() -> void:
	_show("battle")


func set_log(text: String, color: Color = Color("fde68a")) -> void:
	log_lbl.text = text
	log_lbl.add_theme_color_override("font_color", color)


func set_bars(p: Dictionary, e: Dictionary) -> void:
	e_name.text = "%s   Nv %d%s" % [e.name, int(e.level), "  ★" if bool(e.get("boss", false)) else ""]
	e_hp.max_value = float(e.max_hp)
	e_hp.value = float(e.hp)
	e_en.max_value = float(e.max_en)
	e_en.value = float(e.en)
	e_hp_lbl.text = "%d / %d" % [int(ceil(float(e.hp))), int(e.max_hp)]
	p_hp.max_value = float(p.max_hp)
	p_hp.value = float(p.hp)
	p_en.max_value = float(p.max_en)
	p_en.value = float(p.en)
	p_hp_lbl.text = "VIDA %d / %d" % [int(ceil(float(p.hp))), int(p.max_hp)]
	p_en_lbl.text = "ENERGÍA %d / %d" % [int(p.en), int(p.max_en)]


func hide_actions() -> void:
	act_panel.visible = false


## acts: {"main": [ {id,label,sub,enabled} ], "skills": [...], "potions": [...]}
func show_actions(acts: Dictionary) -> void:
	cur_actions = acts
	sub_mode = "main"
	act_panel.visible = true
	_build_actions()


func _action_btn(a: Dictionary, color: Color, w: float, h: float, wide: bool = false) -> Button:
	var text := ""
	if wide:
		text = "        %s  ·  %s" % [a.label, a.sub]
	else:
		text = "\n\n\n%s\n%s" % [a.label, a.sub]
	var b := _btn(text, color, 13 if not wide else 16, w, h)
	b.disabled = not bool(a.enabled)
	if wide:
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var ic := Control.new()
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)
	var isz := 38.0 if not wide else 36.0
	_place(ic, (w - isz) * 0.5 if not wide else 10.0, 3.0 if not wide else (h - isz) * 0.5, isz, isz)
	var icon := String(a.get("icon", "power"))
	ic.draw.connect(func(): _glyph(ic, icon, isz, b.disabled))
	var aid: String = a.id
	b.pressed.connect(func(): action_pressed.emit(aid))
	return b


func _glyph(c: Control, id: String, sz: float, dim: bool) -> void:
	var h := sz * 0.5
	var al := 0.45 if dim else 1.0
	var skin := Color("f1c27d", al)
	var white := Color(1, 1, 1, al)
	var red := Color("ef4444", al)
	var dark := Color("2a1608", al)
	match id:
		"head":
			c.draw_circle(Vector2(h, h * 1.05), sz * 0.3, skin)
			c.draw_circle(Vector2(h - sz * 0.1, h), sz * 0.04, dark)
			c.draw_circle(Vector2(h + sz * 0.1, h), sz * 0.04, dark)
			c.draw_arc(Vector2(h, h * 1.2), sz * 0.1, 0.2, PI - 0.2, 8, dark, 2.0)
			c.draw_line(Vector2(sz * 0.05, sz * 0.12), Vector2(sz * 0.95, sz * 0.5), white, 5.0)
			c.draw_line(Vector2(sz * 0.05, sz * 0.12), Vector2(sz * 0.95, sz * 0.5), red, 2.0)
			c.draw_circle(Vector2(sz * 0.8, sz * 0.43), sz * 0.07, red)
		"body":
			c.draw_circle(Vector2(h, sz * 0.2), sz * 0.14, skin)
			c.draw_rect(Rect2(h - sz * 0.26, sz * 0.33, sz * 0.52, sz * 0.5), Color("b91c1c", al))
			c.draw_line(Vector2(sz * 0.05, sz * 0.3), Vector2(sz * 0.95, sz * 0.75), white, 5.0)
			c.draw_line(Vector2(sz * 0.05, sz * 0.3), Vector2(sz * 0.95, sz * 0.75), red, 2.0)
		"legs":
			c.draw_rect(Rect2(h - sz * 0.22, sz * 0.12, sz * 0.18, sz * 0.7), skin)
			c.draw_rect(Rect2(h + sz * 0.04, sz * 0.12, sz * 0.18, sz * 0.7), skin)
			c.draw_rect(Rect2(h - sz * 0.26, sz * 0.8, sz * 0.24, sz * 0.12), Color("6b4423", al))
			c.draw_rect(Rect2(h + sz * 0.02, sz * 0.8, sz * 0.24, sz * 0.12), Color("6b4423", al))
			c.draw_line(Vector2(sz * 0.05, sz * 0.5), Vector2(sz * 0.95, sz * 0.82), white, 5.0)
			c.draw_line(Vector2(sz * 0.05, sz * 0.5), Vector2(sz * 0.95, sz * 0.82), red, 2.0)
		"guard":
			c.draw_colored_polygon(PackedVector2Array([Vector2(sz * 0.14, sz * 0.14), Vector2(sz * 0.86, sz * 0.14), Vector2(sz * 0.8, sz * 0.58), Vector2(h, sz * 0.92), Vector2(sz * 0.2, sz * 0.58)]), Color("60a5fa", al))
			c.draw_colored_polygon(PackedVector2Array([Vector2(sz * 0.26, sz * 0.24), Vector2(sz * 0.74, sz * 0.24), Vector2(sz * 0.7, sz * 0.54), Vector2(h, sz * 0.78), Vector2(sz * 0.3, sz * 0.54)]), Color("1d4ed8", al))
			c.draw_circle(Vector2(h, sz * 0.45), sz * 0.09, Color("fbbf24", al))
		"push":
			c.draw_rect(Rect2(sz * 0.1, sz * 0.3, sz * 0.3, sz * 0.4), skin)
			for i in 3:
				var y := sz * (0.3 + i * 0.2)
				c.draw_line(Vector2(sz * 0.45, y), Vector2(sz * 0.9, y), white, 4.0)
				c.draw_line(Vector2(sz * 0.8, y - sz * 0.07), Vector2(sz * 0.9, y), white, 4.0)
				c.draw_line(Vector2(sz * 0.8, y + sz * 0.07), Vector2(sz * 0.9, y), white, 4.0)
		"approach", "retreat":
			var dir := 1.0 if id == "approach" else -1.0
			var col := Color("fbbf24", al) if id == "approach" else Color("93c5fd", al)
			for i in 2:
				var x := h + dir * (sz * 0.12 - sz * 0.22 + i * sz * 0.3) - dir * sz * 0.05
				c.draw_polyline(PackedVector2Array([Vector2(x - dir * sz * 0.16, sz * 0.2), Vector2(x + dir * sz * 0.1, h), Vector2(x - dir * sz * 0.16, sz * 0.8)]), col, 7.0)
		"throw":
			c.draw_line(Vector2(sz * 0.2, sz * 0.8), Vector2(sz * 0.8, sz * 0.2), Color("e5e7eb", al), 7.0)
			c.draw_line(Vector2(sz * 0.14, sz * 0.86), Vector2(sz * 0.3, sz * 0.7), Color("a16207", al), 7.0)
			for i in 3:
				c.draw_line(Vector2(sz * 0.1, sz * (0.25 + i * 0.12)), Vector2(sz * 0.38, sz * (0.25 + i * 0.12)), white, 3.0)
		"spell":
			c.draw_circle(Vector2(h, h), sz * 0.26, Color("f97316", al))
			c.draw_circle(Vector2(h, h), sz * 0.14, Color("fde047", al))
			for i in 8:
				var a := i * TAU / 8.0
				c.draw_line(Vector2(h + cos(a) * sz * 0.3, h + sin(a) * sz * 0.3), Vector2(h + cos(a) * sz * 0.46, h + sin(a) * sz * 0.46), Color("fde047", al), 3.0)
		"power":
			var pts := PackedVector2Array()
			for i in 10:
				var ang := -PI / 2.0 + i * PI / 5.0
				var rr := sz * 0.46 if i % 2 == 0 else sz * 0.2
				pts.append(Vector2(h + cos(ang) * rr, sz * 0.54 + sin(ang) * rr))
			c.draw_colored_polygon(pts, Color("fde047", al))
		"heal":
			c.draw_rect(Rect2(h - sz * 0.09, sz * 0.15, sz * 0.18, sz * 0.7), Color("4ade80", al))
			c.draw_rect(Rect2(sz * 0.15, h - sz * 0.09, sz * 0.7, sz * 0.18), Color("4ade80", al))
		"potion_hp", "potion_en":
			var liq := Color("ef4444", al) if id == "potion_hp" else Color("38bdf8", al)
			c.draw_circle(Vector2(h, sz * 0.62), sz * 0.26, liq)
			c.draw_rect(Rect2(h - sz * 0.08, sz * 0.14, sz * 0.16, sz * 0.26), Color("e5e7eb", al))
			c.draw_rect(Rect2(h - sz * 0.12, sz * 0.1, sz * 0.24, sz * 0.07), Color("a16207", al))
		_:
			c.draw_circle(Vector2(h, h), sz * 0.3, white)


func _build_actions() -> void:
	_clear(act_box)
	if sub_mode == "main":
		var head := HBoxContainer.new()
		var near: bool = bool(cur_actions.get("near", false))
		var dl := _lbl("CERCA: más críticos y empujar" if near else "LEJOS: acércate o usa magia/lanza", 16, C_GREEN if near else C_BLUE)
		dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(dl)
		var sr := _btn("RENDIRSE", Color("44403c"), 12, 96, 28)
		sr.pressed.connect(func(): surrender_pressed.emit())
		head.add_child(sr)
		act_box.add_child(head)
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 7)
		grid.add_theme_constant_override("v_separation", 7)
		var cols := {"head": Color("b91c1c"), "body": Color("b45309"), "legs": Color("a16207"), "guard": Color("1d4ed8"), "push": Color("0d9488"), "move": Color("475569"), "throw": Color("92400e")}
		for a in cur_actions.main:
			grid.add_child(_action_btn(a, cols.get(String(a.id), Color("475569")), 158, 94))
		var bs := _action_btn({"id": "menu_skills", "label": "PODERES", "sub": "%d disponibles" % cur_actions.skills.size(), "enabled": not cur_actions.skills.is_empty(), "icon": "spell"}, Color("7e22ce"), 158, 94)
		for c in bs.pressed.get_connections():
			bs.pressed.disconnect(c.callable)
		bs.pressed.connect(func():
			sub_mode = "skills"
			_build_actions())
		grid.add_child(bs)
		var bp := _action_btn({"id": "menu_potions", "label": "POCIONES", "sub": "Vida %d · En %d" % [GameState.potion_count("vida"), GameState.potion_count("energia")], "enabled": true, "icon": "potion_hp"}, Color("15803d"), 158, 94)
		for c in bp.pressed.get_connections():
			bp.pressed.disconnect(c.callable)
		bp.pressed.connect(func():
			sub_mode = "potions"
			_build_actions())
		grid.add_child(bp)
		act_box.add_child(grid)
	else:
		var list: Array = cur_actions.skills if sub_mode == "skills" else cur_actions.potions
		act_box.add_child(_lbl("PODERES Y MAGIA" if sub_mode == "skills" else "POCIONES", 22, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
		for a in list:
			act_box.add_child(_action_btn(a, Color("7e22ce") if sub_mode == "skills" else Color("15803d"), 488, 52, true))
		var back := _btn("VOLVER", Color("57534e"), 20, 488, 46)
		back.pressed.connect(func():
			sub_mode = "main"
			_build_actions())
		act_box.add_child(back)


## Texto flotante sobre una posición 3D.
func float_text(world_pos: Vector3, text: String, color: Color = Color.WHITE, size: int = 34) -> void:
	if camera_ref == null:
		return
	var pos := camera_ref.unproject_position(world_pos)
	var l := _lbl(text, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_constant_override("outline_size", 8)
	float_layer.add_child(l)
	_place(l, pos.x - 120, pos.y - 20, 240, 50)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 90, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)


# ---------- Resultado ----------
func _build_result() -> void:
	var p := _page("result")
	_dim(p, 0.6)
	result_box = _panel(p, Rect2(26, (H - 640) * 0.5, W - 52, 640))


func show_result(win: bool, title: String, lines: Array, can_continue: bool = true) -> void:
	_clear(result_box)
	result_box.add_child(_lbl(title, 40, C_GREEN if win else C_RED, HORIZONTAL_ALIGNMENT_CENTER))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	sc.add_child(v)
	for ln in lines:
		var l := _lbl(String(ln), 20, Color.WHITE if not String(ln).begins_with("¡") else C_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(420, 0)
		v.add_child(l)
	result_box.add_child(sc)
	var again := _btn("REINTENTAR" if not win else "SIGUIENTE COMBATE", Color("15803d") if win else Color("b91c1c"), 24, 340, 66)
	again.pressed.connect(func(): retry_pressed.emit())
	again.visible = can_continue
	_center(result_box, again)
	var menu := _btn("MENÚ", C_DARK, 22, 340, 54)
	menu.pressed.connect(func(): continue_pressed.emit())
	_center(result_box, menu)
	_show("result")


# ======================= Personaje y logros =======================
var char_box: VBoxContainer
var ach_box: VBoxContainer
var ach_btn: Button


func _build_char() -> void:
	var p := _page("char")
	char_box = _panel(p, Rect2(10, H - 600, W - 20, 588))
	var pa := _page("ach")
	_dim(pa)
	ach_box = _panel(pa, Rect2(16, 30, W - 32, H - 60))


func open_char() -> void:
	_clear(char_box)
	char_box.add_theme_constant_override("separation", 5)
	char_box.add_child(_lbl("TU GLADIADOR", 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	for row in GameState.CHAR_ROWS:
		var key := String(row.key)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		var l := _lbl(String(row.label), 17, Color.WHITE)
		l.custom_minimum_size = Vector2(150, 0)
		hb.add_child(l)
		var left := _btn("<", C_BTN, 22, 48, 38)
		left.pressed.connect(func():
			GameState.cycle_char(key, -1)
			preview_changed.emit()
			open_char())
		hb.add_child(left)
		var val := str(GameState.char_list(key)[GameState.char_index(key)].value)
		if key in ["skin", "hair_c", "cloth"]:
			var sw := ColorRect.new()
			sw.color = Color(val)
			sw.custom_minimum_size = Vector2(26, 26)
			hb.add_child(sw)
		var vl := _lbl(GameState.char_value_name(key), 18, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		vl.custom_minimum_size = Vector2(120, 0)
		hb.add_child(vl)
		var right := _btn(">", C_BTN, 22, 48, 38)
		right.pressed.connect(func():
			GameState.cycle_char(key, 1)
			preview_changed.emit()
			open_char())
		hb.add_child(right)
		char_box.add_child(hb)
	var fx: Array = GameState.body_effects_text()
	for g in fx[0]:
		var gl := _lbl("+ " + String(g), 14, C_GREEN)
		gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		gl.custom_minimum_size = Vector2(440, 0)
		char_box.add_child(gl)
	for b in fx[1]:
		var bl := _lbl("- " + String(b), 14, Color("fca5a5"))
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bl.custom_minimum_size = Vector2(440, 0)
		char_box.add_child(bl)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	char_box.add_child(sp)
	_back_row(char_box)
	_show("char")


func open_ach() -> void:
	_clear(ach_box)
	ach_box.add_child(_lbl("LOGROS", 34, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	ach_box.add_child(_lbl("Completa retos y reclama oro y premios de estilo", 14, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	sc.add_child(v)
	for a in GameState.ACHIEVEMENTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var done := GameState.ach_done(a)
		var claimed := GameState.ach_claimed(a)
		tv.add_child(_lbl(String(a.name), 18, C_GREEN if claimed else Color.WHITE))
		tv.add_child(_lbl(String(a.desc), 13, C_MUTED))
		var val := mini(GameState.ach_stat(String(a.stat)), int(a.target))
		var pb := _bar(C_GREEN if done else C_BLUE, 280, 10)
		pb.max_value = float(a.target)
		pb.value = float(val)
		tv.add_child(pb)
		row.add_child(tv)
		var aid := String(a.id)
		var b: Button
		if claimed:
			b = _btn("RECLAMADO", Color("166534"), 13, 118, 50)
			b.disabled = true
		elif done:
			b = _btn("RECLAMAR\n● %d" % int(a.gold) + ("+★" if a.has("grant") else ""), Color("ca8a04"), 14, 118, 56)
			b.pressed.connect(func():
				GameState.claim_ach(aid)
				Sfx.play("coin")
				open_ach())
		else:
			b = _btn("%d/%d\n● %d" % [val, int(a.target), int(a.gold)], C_DARK, 14, 118, 50)
			b.disabled = true
		row.add_child(b)
		v.add_child(row)
	ach_box.add_child(sc)
	_back_row(ach_box)
	_show("ach")
