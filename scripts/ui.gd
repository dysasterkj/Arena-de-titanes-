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
signal story_fight(ch: int, lv: int)

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
var vendor: Control
const VendorScript = preload("res://scripts/vendor.gd")
const IconScript = preload("res://scripts/item_icon.gd")
const StoryScript = preload("res://scripts/story.gd")
const NarratorScript = preload("res://scripts/narrator.gd")
var story_box: VBoxContainer
var _reset_armed := false
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
var hud_p
var hud_e
const HudScript = preload("res://scripts/hud.gd")
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
	_build_story()
	_build_shop()
	_build_train()
	_build_battle()
	_build_result()
	_build_char()
	_build_update()
	show_menu()


# ---------- Utilidades ----------
var ink_mode := false


func _ink_map(c: Color) -> Color:
	if c.is_equal_approx(Color.WHITE):
		return Color("2a1608")
	if c.is_equal_approx(C_GOLD):
		return Color("7c2d12")
	if c.is_equal_approx(C_MUTED):
		return Color("5b4636")
	if c.is_equal_approx(C_GREEN) or c.is_equal_approx(Color("86efac")):
		return Color("166534")
	if c.is_equal_approx(C_RED):
		return Color("991b1b")
	if c.is_equal_approx(C_BLUE):
		return Color("1e3a8a")
	if c.is_equal_approx(Color("c4b5fd")):
		return Color("581c87")
	return c.darkened(0.55)


func _lbl(text: String, size: int = 22, color: Color = Color.WHITE, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	if ink_mode:
		l.add_theme_color_override("font_color", _ink_map(color))
		l.add_theme_constant_override("outline_size", 0)
	else:
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


var preview_ov := {}
var char_focus := "body"


func _show(id: String) -> void:
	ink_mode = false
	if id != "char":
		char_focus = "body"
	if id != "shop" and not preview_ov.is_empty():
		preview_ov.clear()
		preview_changed.emit()
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
	var plq := Panel.new()
	plq.add_theme_stylebox_override("panel", _sb(Color(0.12, 0.06, 0.03, 0.9), 14, Color("d4a72c"), 4))
	m.add_child(plq)
	_place(plq, 10, 8, W - 20, 240)
	var t1 := _lbl("ARENA DE", 40, Color("fde68a"), HORIZONTAL_ALIGNMENT_CENTER)
	m.add_child(t1)
	_place(t1, 0, 22, W, 52)
	var t2 := _lbl("TITANES", 84, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	t2.add_theme_color_override("font_outline_color", Color("7c2d12"))
	t2.add_theme_constant_override("outline_size", 14)
	m.add_child(t2)
	_place(t2, 0, 66, W, 104)
	menu_gold = _lbl("", 26, C_GOLD)
	m.add_child(menu_gold)
	_place(menu_gold, 28, 190, 250, 36)
	menu_level = _lbl("", 22, Color("fde68a"), HORIZONTAL_ALIGNMENT_RIGHT)
	m.add_child(menu_level)
	_place(menu_level, W - 278, 192, 250, 32)
	menu_xp = _bar(Color("a78bfa"), 250, 12)
	m.add_child(menu_xp)
	_place(menu_xp, W - 278, 226, 250, 12)

	music_btn = _btn("", Color("57534e"), 15, 130, 38)
	m.add_child(music_btn)
	_place(music_btn, 24, H - 68, 130, 34)
	music_btn.pressed.connect(func():
		GameState.data.music = not GameState.data.music
		Sfx.set_options(bool(GameState.data.music), bool(GameState.data.sfx))
		GameState.save_game()
		_refresh_toggles())
	sfx_btn = _btn("", Color("57534e"), 15, 130, 38)
	m.add_child(sfx_btn)
	_place(sfx_btn, 162, H - 68, 130, 34)
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

	var vl := _lbl("v" + String(ProjectSettings.get_setting("application/config/version", "0.0.0")), 14, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_RIGHT)
	m.add_child(vl)
	_place(vl, W - 160, H - 58, 150, 20)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(vb)
	_place(vb, 40, H - 404, W - 80, 326)
	var hist := _btn("HISTORIA", Color("a16207"), 36, 440, 80)
	hist.pressed.connect(open_story)
	vb.add_child(hist)
	var fight := _btn("ARENA LIBRE", Color("b91c1c"), 28, 440, 66)
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
	fights_box = _parch(p, Rect2(16, 30, W - 32, H - 60), 11)


func open_fights() -> void:
	ink_mode = true
	_clear(fights_box)
	fights_box.add_child(_lbl("ELIGE TU COMBATE", 34, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	fights_box.add_child(_lbl("Tu rival puede ser más fuerte de lo esperado. Perder también da experiencia.", 13, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
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
			v.add_child(_lbl(String(GameState.ARENAS[last_arena].name) + ("" if GameState.arena_unlocked(last_arena) else "   (nivel %d)" % int(GameState.ARENA_LVL[last_arena])), 20, C_GOLD if GameState.arena_unlocked(last_arena) else C_MUTED))
		var open := GameState.fight_unlocked(i)
		var won := GameState.fight_won(i)
		var r := GameState.reward_for(i, not won)
		var label := "%d. %s%s" % [i + 1, e.name, "   ★ JEFE" if bool(e.get("boss", false)) else ""]
		var sub := "Premio: ● %d · %d XP%s" % [int(r.gold), int(r.xp), "   (ganado)" if won else ""]
		var b := _btn("%s\n%s" % [label, sub] if open else ("%d. ???  (requiere nivel %d)" % [i + 1, int(GameState.ARENA_LVL[int(e.arena)])] if not GameState.arena_unlocked(int(e.arena)) else "%d. ???  (gana el combate anterior)" % (i + 1)), Color("15803d") if won else (Color("b91c1c") if bool(e.get("boss", false)) else C_BTN), 17, 440, 66)
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
	shop_box = _parch(p, Rect2(10, H - 560, W - 20, 548), 12)
	vendor = VendorScript.new()
	vendor.position = Vector2(10, 14)
	vendor.size = Vector2(W - 20, 200)
	p.add_child(vendor)


func open_shop(tab: String = "") -> void:
	ink_mode = true
	if tab != "":
		shop_tab = tab
	_clear(shop_box)
	if vendor:
		vendor.set_tab(shop_tab)
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
	var tab := shop_tab
	var id: String = it.id
	var owned := GameState.owns(tab, id)
	var lvl := GameState.item_level(tab, id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(IconScript.new().setup(tab, id))
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stat_txt := "Estilo"
	if it.has("dmg"):
		stat_txt = "Daño %d" % GameState.eff_dmg(tab, it)
	elif it.has("def"):
		stat_txt = "Defensa +%d" % GameState.eff_def(tab, it)
	elif it.has("perk"):
		var tot := int(it.pv) * (1 + lvl)
		stat_txt = "+%d %s" % [tot, GameState.PERK_NAMES[it.perk]]
	var nm := "%s   (%s)" % [it.name, stat_txt]
	if lvl > 0:
		nm += "  Nv %d" % lvl
	tv.add_child(_lbl(nm, 17, Color.WHITE))
	tv.add_child(_lbl(String(it.desc), 13, C_MUTED))
	if id != "none" and GameState.can_upgrade(tab, id) or (owned and lvl >= GameState.MAX_UP):
		var up_txt := "Cada mejora: " + GameState.gain_text(tab, it) if lvl < GameState.MAX_UP else "Mejora al máximo"
		tv.add_child(_lbl(up_txt, 13, Color("86efac")))
	row.add_child(tv)
	var rc := VBoxContainer.new()
	rc.add_theme_constant_override("separation", 4)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	var b: Button
	if owned:
		if GameState.equipped(tab) == id:
			b = _btn("EQUIPADO", Color("166534"), 14, 120, 44)
			b.disabled = true
		else:
			b = _btn("EQUIPAR", Color("0d9488"), 16, 120, 44)
			b.pressed.connect(func():
				GameState.equip(tab, id)
				preview_ov.erase(tab)
				preview_changed.emit()
				open_shop())
	else:
		var need := GameState.req_level(tab, id)
		if GameState.level() < need:
			b = _btn("NIVEL %d" % need, Color("44403c"), 15, 120, 44)
			b.disabled = true
		else:
			b = _btn("● %d" % int(it.cost), C_BTN, 16, 120, 44)
			b.disabled = int(GameState.data.gold) < int(it.cost)
			b.pressed.connect(func():
				if GameState.buy_item(tab, id):
					preview_ov.erase(tab)
					Sfx.play("buy")
					preview_changed.emit()
					open_shop())
	var eq_now := owned and GameState.equipped(tab) == id
	if not eq_now:
		var vb := _btn("VER", Color("1d4ed8") if preview_ov.get(tab, "") != id else Color("166534"), 15, 56, 44)
		vb.pressed.connect(func():
			preview_ov[tab] = id
			preview_changed.emit()
			open_shop())
		top.add_child(vb)
	top.add_child(b)
	rc.add_child(top)
	if owned and GameState.can_upgrade(tab, id):
		var cost := GameState.upgrade_cost(tab, id)
		var ub := _btn("MEJORAR ● %d" % cost, Color("a16207"), 14, 180, 36)
		ub.disabled = int(GameState.data.gold) < cost
		ub.pressed.connect(func():
			if GameState.upgrade_item(tab, id):
				Sfx.play("levelup")
				preview_changed.emit()
				open_shop())
		rc.add_child(ub)
	row.add_child(rc)
	return row


func _potion_row(id: String, pd: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var need := int(pd.get("lvl", 1))
	tv.add_child(_lbl("%s   x%d" % [pd.name, GameState.potion_count(id)], 17, Color.WHITE))
	tv.add_child(_lbl(String(pd.desc) + ("" if GameState.level() >= need else "  (se desbloquea en nivel %d)" % need), 13, C_MUTED))
	row.add_child(tv)
	var b: Button
	if GameState.level() < need:
		b = _btn("NIVEL %d" % need, Color("44403c"), 15, 120, 48)
		b.disabled = true
	else:
		b = _btn("● %d" % int(pd.cost), C_BTN, 16, 120, 48)
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
	train_box = _parch(p, Rect2(10, H - 640, W - 20, 628), 13)


func open_train() -> void:
	ink_mode = true
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
	# HUD estilo S&S: pociones de vida y energía + placa con el nombre
	e_name = Label.new()
	e_hp = ProgressBar.new()
	e_en = ProgressBar.new()
	e_hp_lbl = Label.new()
	p_name = Label.new()
	p_hp = ProgressBar.new()
	p_en = ProgressBar.new()
	p_hp_lbl = Label.new()
	p_en_lbl = Label.new()
	hud_p = HudScript.new()
	b.add_child(hud_p)
	_place(hud_p, 4, H - 396 - 140, 260, 136)
	hud_e = HudScript.new()
	hud_e.mirror = true
	b.add_child(hud_e)
	_place(hud_e, W - 264, H - 396 - 140, 260, 136)

	# mensaje
	log_lbl = _lbl("", 22, Color("fde68a"), HORIZONTAL_ALIGNMENT_CENTER)
	log_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_child(log_lbl)
	_place(log_lbl, 20, 66, W - 40, 60)
	_build_tabs(b)

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
	b.move_child(tab_pop, -1)


func show_battle() -> void:
	if tab_pop:
		tab_pop.visible = false
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
	hud_e.setv(String(e.name) + "  Nv " + str(int(e.level)) + (" ★" if bool(e.get("boss", false)) else ""), maxf(0.0, float(e.hp)), float(e.max_hp), float(e.en), float(e.max_en))
	hud_e.set_armour(float(e.get("shield_hp", 0.0)), float(e.get("shield_max", 0.0)))
	hud_p.set_armour(float(p.get("shield_hp", 0.0)), float(p.get("shield_max", 0.0)))
	hud_p.setv(String(p.get("name", "Tú")) + "  Nv " + str(int(p.get("level", 1))), maxf(0.0, float(p.hp)), float(p.max_hp), float(p.en), float(p.max_en))



func hide_actions() -> void:
	act_panel.visible = false


## acts: {"main": [ {id,label,sub,enabled} ], "skills": [...], "potions": [...]}
func show_actions(acts: Dictionary) -> void:
	cur_actions = acts
	sub_mode = "main"
	act_panel.visible = true
	_build_actions()


func _round_action(a: Dictionary, color: Color, w: float, h: float) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.disabled = not bool(a.enabled)
	var d := w - 14.0
	var ic := Control.new()
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)
	_place(ic, (w - d) * 0.5, 2, d, d)
	var icon := String(a.get("icon", "power"))
	ic.draw.connect(func():
		var dim: bool = b.disabled
		var pr: bool = b.button_pressed or b.get_draw_mode() == BaseButton.DRAW_PRESSED
		var cc := d * 0.5
		var ctr := Vector2(cc, cc + (2.0 if pr else 0.0))
		ic.draw_circle(ctr + Vector2(0, 4), cc, Color(0, 0, 0, 0.45))
		var base := color.darkened(0.45) if dim else color
		ic.draw_circle(ctr, cc, Color("1a0e05"))
		ic.draw_circle(ctr, cc - 3.0, Color("d4a72c") if not dim else Color("6b5a2a"))
		ic.draw_circle(ctr, cc - 6.0, base.darkened(0.35))
		ic.draw_circle(ctr - Vector2(0, 3), cc - 8.0, base)
		ic.draw_arc(ctr, cc - 9.0, PI * 1.1, PI * 1.9, 18, Color(1, 1, 1, 0.22), 3.0, true)
		var g := d * 0.7
		_glyph_at(ic, icon, g, dim, Vector2(cc - g * 0.5, cc - g * 0.5 + (2.0 if pr else 0.0))))
	var l1 := _lbl(String(a.label), 12, Color("fff3c4") if not b.disabled else Color("8a7f68"), HORIZONTAL_ALIGNMENT_CENTER)
	l1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l1)
	_place(l1, 0, d + 2, w, 18)
	var l2 := _lbl(String(a.sub), 10, Color("d6c9a6") if not b.disabled else Color("6f6757"), HORIZONTAL_ALIGNMENT_CENTER)
	l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l2)
	_place(l2, 0, d + 18, w, 26)
	var aid: String = a.id
	b.pressed.connect(func(): action_pressed.emit(aid))
	return b


func _glyph_at(c: Control, id: String, sz: float, dim: bool, off: Vector2) -> void:
	c.draw_set_transform(off, 0.0, Vector2.ONE)
	_glyph(c, id, sz, dim)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _action_btn(a: Dictionary, color: Color, w: float, h: float, wide: bool = false) -> Button:
	if not wide:
		return _round_action(a, color, 96.0, 128.0)
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
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 2)
		grid.add_theme_constant_override("v_separation", 4)
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


# ======================= Modo historia =======================
func _build_story() -> void:
	var p := _page("story")
	_dim(p)
	story_box = _parch(p, Rect2(14, 24, W - 28, H - 48), 21)


func open_story() -> void:
	ink_mode = true
	_reset_armed = false
	_clear(story_box)
	var st: Dictionary = GameState.data.story
	if String(st.lineage) == "":
		_story_lineage()
	else:
		var ch := int(st.ch)
		if ch >= StoryScript.CHAPTERS.size():
			_story_end()
		elif not bool(st.outro_seen):
			_story_outro(ch - 1)
		elif not bool(st.intro_seen):
			_story_intro(ch)
		else:
			_story_map(ch)
	_show("story")


func _narr_block(text: String) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	var np := Control.new()
	np.set_script(NarratorScript)
	np.custom_minimum_size = Vector2(88, 88)
	hb.add_child(np)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_ink("EL CRONISTA", 15, HORIZONTAL_ALIGNMENT_LEFT, Color("9a3412")))
	var l := _ink(text, 18)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(300, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(l)
	hb.add_child(v)
	return hb


func _story_scroll(content: Control) -> void:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	story_box.add_child(sc)


func _story_header(top: String, title: String) -> void:
	story_box.add_child(_ink(top, 17, HORIZONTAL_ALIGNMENT_CENTER, Color("9a3412")))
	var t := _ink(title, 30, HORIZONTAL_ALIGNMENT_CENTER, Color("7c2d12"))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_box.add_child(t)


func _story_lineage() -> void:
	_story_header("TU HISTORIA", "¿QUIÉN FUISTE?")
	var l := _ink("Tu linaje cambia la historia: quién te traicionó, tus puntos fuertes y tu aspecto.", 15, HORIZONTAL_ALIGNMENT_CENTER, Color("5b4636"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_box.add_child(l)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	for id in StoryScript.ORDER:
		var lin: Dictionary = StoryScript.lineage(id)
		var b := _btn("%s
%s
%s" % [lin.name, lin.desc, lin.bonus], Color("78350f"), 16, 430, 100)
		var lid: String = id
		b.pressed.connect(func():
			GameState.story_set_lineage(lid)
			preview_changed.emit()
			open_story())
		v.add_child(b)
	_story_scroll(v)
	_back_row(story_box)


func _story_intro(ch: int) -> void:
	var c: Dictionary = StoryScript.CHAPTERS[ch]
	_story_header("CAPÍTULO %d" % (ch + 1), String(c.name))
	var v := VBoxContainer.new()
	v.add_child(_narr_block(StoryScript.chapter_intro(ch, GameState.story_lineage())))
	_story_scroll(v)
	var go := _btn("ADELANTE", Color("b91c1c"), 26, 280, 60)
	go.pressed.connect(func():
		GameState.data.story.intro_seen = true
		GameState.save_game()
		open_story())
	_center(story_box, go)


func _story_outro(ch: int) -> void:
	var c: Dictionary = StoryScript.CHAPTERS[ch]
	_story_header("CAPÍTULO %d COMPLETADO" % (ch + 1), String(c.name))
	var v := VBoxContainer.new()
	v.add_child(_narr_block(StoryScript.chapter_outro(ch, GameState.story_lineage())))
	_story_scroll(v)
	var go := _btn("SIGUIENTE", Color("b91c1c"), 26, 280, 60)
	go.pressed.connect(func():
		GameState.data.story.outro_seen = true
		GameState.save_game()
		open_story())
	_center(story_box, go)


func _story_end() -> void:
	_story_header("FIN", "CENIZAS DEL COLISEO")
	var v := VBoxContainer.new()
	v.add_child(_narr_block("Así termina la leyenda del gladiador que volvió de las Minas de Ceniza. Venciste a los guardias, a los traidores y al Emperador. La arena guardará tu nombre. Puedes volver a empezar con otro linaje para ver otra versión de la historia."))
	_story_scroll(v)
	var again := _btn("EMPEZAR OTRA HISTORIA", Color("7e22ce"), 20, 340, 56)
	again.pressed.connect(func():
		GameState.story_reset()
		preview_changed.emit()
		open_story())
	_center(story_box, again)
	_back_row(story_box)


func _story_map(ch: int) -> void:
	var st: Dictionary = GameState.data.story
	var lin_id := GameState.story_lineage()
	var c: Dictionary = StoryScript.CHAPTERS[ch]
	var cur := int(st.lv)
	_story_header("CAPÍTULO %d · %s" % [ch + 1, StoryScript.lineage(lin_id).name], String(c.name))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(_narr_block(StoryScript.level_line(ch, cur, lin_id)))
	v.add_child(_ink("Cada nivel es más difícil. Al final espera el jefe.", 14, HORIZONTAL_ALIGNMENT_CENTER, Color("5b4636")))
	for i in StoryScript.LEVELS:
		var open := i <= cur
		var done := GameState.story_done(ch, i)
		var boss := i == StoryScript.LEVELS - 1
		var nm := String(c.names[i])
		if boss and StoryScript.is_traitor(ch, lin_id):
			nm = String(StoryScript.lineage(lin_id).traitor)
		var r: Dictionary = StoryScript.reward(ch, i, not done)
		var label := "Nivel %d · %s%s" % [i + 1, nm, "   ★ JEFE" if boss else ""]
		var sub := "Premio: ● %d · %d XP%s" % [int(r.gold), int(r.xp), "   (ganado)" if done else ""]
		var b := _btn("%s
%s" % [label, sub] if open else "Nivel %d · ???" % (i + 1), Color("15803d") if done else (Color("b91c1c") if i == cur else Color("78350f")), 17, 430, 62)
		b.disabled = not open
		var li := i
		b.pressed.connect(func(): story_fight.emit(ch, li))
		v.add_child(b)
	_story_scroll(v)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var back := _btn("VOLVER", Color("78350f"), 20, 170, 50)
	back.pressed.connect(show_menu)
	row.add_child(back)
	var rst := _btn("REINICIAR", Color("57534e"), 16, 170, 50)
	rst.pressed.connect(func():
		if not _reset_armed:
			_reset_armed = true
			rst.text = "¿SEGURO?"
		else:
			GameState.story_reset()
			preview_changed.emit()
			open_story())
	row.add_child(rst)
	story_box.add_child(row)


# ---------- Resultado ----------
func _build_result() -> void:
	var p := _page("result")
	_dim(p, 0.35)
	result_box = _parch(p, Rect2(20, H - 470, W - 40, 450), 9)


func show_result(win: bool, title: String, lines: Array, can_continue: bool = true) -> void:
	_clear(result_box)
	result_box.add_child(_ink(title, 38, HORIZONTAL_ALIGNMENT_CENTER, Color("166534") if win else Color("991b1b")))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	sc.add_child(v)
	for ln in lines:
		var s := String(ln)
		var l := _ink(s, 19, HORIZONTAL_ALIGNMENT_CENTER, Color("7c2d12") if s.begins_with("¡") else INK_C)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(440, 0)
		v.add_child(l)
	result_box.add_child(sc)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 30)
	var menu := _round_ok(false, 72)
	menu.pressed.connect(func(): continue_pressed.emit())
	hb.add_child(menu)
	if can_continue:
		var again := _round_ok(true, 84)
		again.pressed.connect(func(): retry_pressed.emit())
		hb.add_child(again)
	var cap := HBoxContainer.new()
	cap.alignment = BoxContainer.ALIGNMENT_CENTER
	cap.add_theme_constant_override("separation", 70)
	cap.add_child(_ink("MENÚ", 14, HORIZONTAL_ALIGNMENT_CENTER))
	if can_continue:
		cap.add_child(_ink("SEGUIR" if win else "REINTENTAR", 14, HORIZONTAL_ALIGNMENT_CENTER))
	result_box.add_child(hb)
	result_box.add_child(cap)
	_show("result")


# ======================= Personaje y logros =======================
var char_box: VBoxContainer
var ach_box: VBoxContainer
var ach_btn: Button


func _build_char() -> void:
	var p := _page("char")
	char_box = _parch(p, Rect2(10, H - 600, W - 20, 588), 3)
	var pa := _page("ach")
	_dim(pa)
	ach_box = _parch(pa, Rect2(16, 30, W - 32, H - 60), 14)


func open_char() -> void:
	_clear(char_box)
	char_box.add_theme_constant_override("separation", 4)
	char_box.add_child(_ink("escribe tu nombre", 20))
	var le := LineEdit.new()
	le.text = String(GameState.data.get("name", "Gladiador"))
	le.max_length = 14
	le.add_theme_font_size_override("font_size", 22)
	le.add_theme_color_override("font_color", INK_C)
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color("ffe9b8")
	lsb.border_color = INK_C
	lsb.set_border_width_all(2)
	lsb.content_margin_left = 8
	le.add_theme_stylebox_override("normal", lsb)
	le.add_theme_stylebox_override("focus", lsb)
	le.custom_minimum_size = Vector2(0, 40)
	le.text_changed.connect(func(t: String):
		GameState.data["name"] = t.strip_edges() if t.strip_edges() != "" else "Gladiador"
		GameState.save_game())
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", 6)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nrow.add_child(le)
	var rb := _btn("ALEATORIO", Color("b45309"), 14, 120, 40)
	rb.pressed.connect(func():
		GameState.randomize_char()
		preview_changed.emit()
		open_char())
	nrow.add_child(rb)
	char_box.add_child(nrow)
	for row in GameState.CHAR_ROWS:
		var key := String(row.key)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		var l := _ink(String(row.label), 20)
		l.custom_minimum_size = Vector2(150, 0)
		hb.add_child(l)
		var left := _round_sign("<", 38)
		left.pressed.connect(func():
			GameState.cycle_char(key, -1)
			char_focus = key
			preview_changed.emit()
			open_char())
		hb.add_child(left)
		var right := _round_sign(">", 38)
		right.pressed.connect(func():
			GameState.cycle_char(key, 1)
			char_focus = key
			preview_changed.emit()
			open_char())
		hb.add_child(right)
		var val := str(GameState.char_list(key)[GameState.char_index(key)].value)
		if key in ["skin", "hair_c", "cloth"]:
			var sw := ColorRect.new()
			sw.color = Color(val)
			sw.custom_minimum_size = Vector2(26, 26)
			hb.add_child(sw)
		var vl := _ink(GameState.char_value_name(key), 18, HORIZONTAL_ALIGNMENT_LEFT, Color("7c2d12"))
		hb.add_child(vl)
		char_box.add_child(hb)
	char_box.add_child(_ink("puntos de habilidad: %d" % int(GameState.data.points), 18, HORIZONTAL_ALIGNMENT_LEFT, Color("7c2d12")))
	var sg := GridContainer.new()
	sg.columns = 2
	sg.add_theme_constant_override("h_separation", 24)
	sg.add_theme_constant_override("v_separation", 2)
	for s in GameState.STATS:
		var sh := HBoxContainer.new()
		sh.add_theme_constant_override("separation", 6)
		var sn := _ink("%s %d" % [GameState.STAT_NAMES[s], GameState.stat(s)], 17)
		sn.custom_minimum_size = Vector2(150, 0)
		sh.add_child(sn)
		var sid: String = s
		var plus := _round_sign("+", 32)
		plus.disabled = int(GameState.data.points) <= 0
		plus.pressed.connect(func():
			GameState.train_with_point(sid)
			open_char())
		sh.add_child(plus)
		sg.add_child(sh)
	char_box.add_child(sg)
	var fx: Array = GameState.body_effects_text()
	for g in fx[0]:
		var gl := _ink("+ " + String(g), 14, HORIZONTAL_ALIGNMENT_LEFT, Color("166534"))
		gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		gl.custom_minimum_size = Vector2(440, 0)
		char_box.add_child(gl)
	for b in fx[1]:
		var bl := _ink("- " + String(b), 14, HORIZONTAL_ALIGNMENT_LEFT, Color("991b1b"))
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bl.custom_minimum_size = Vector2(440, 0)
		char_box.add_child(bl)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	char_box.add_child(sp)
	var okb := _round_ok(true, 72)
	okb.pressed.connect(show_menu)
	var hb2 := HBoxContainer.new()
	hb2.alignment = BoxContainer.ALIGNMENT_END
	hb2.add_child(okb)
	char_box.add_child(hb2)
	_show("char")


func open_ach() -> void:
	ink_mode = true
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


## Cartel grande que aparece con efecto de rebote (¡PELEA!, ¡K.O.!).
func banner(text: String, color: Color = C_GOLD, size: int = 76) -> void:
	var l := _lbl(text, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_constant_override("outline_size", 14)
	l.add_theme_color_override("font_outline_color", Color("2a0f05"))
	float_layer.add_child(l)
	_place(l, 0, H * 0.28, W, 100)
	l.pivot_offset = Vector2(W * 0.5, 50)
	l.scale = Vector2(2.6, 2.6)
	l.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.08)
	tw.parallel().tween_property(l, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.35)
	tw.tween_callback(l.queue_free)
const ParchScript = preload("res://scripts/parchment.gd")
const INK_C := Color("2a1608")


func _parch(parent: Control, rect: Rect2, seed_v: int = 1) -> VBoxContainer:
	var pc := Control.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pc)
	_place(pc, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	var bg := Control.new()
	bg.set_script(ParchScript)
	bg.seed_v = seed_v
	pc.add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 16)
	pc.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)
	return v


func _ink(text: String, size: int = 20, align: int = HORIZONTAL_ALIGNMENT_LEFT, color: Color = INK_C) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align as HorizontalAlignment
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Botón redondo con flecha o signo, estilo S&S.
func _round_sign(sign: String, d: float = 40.0) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(d, d)
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var ic := Control.new()
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)
	_place(ic, 0, 0, d, d)
	ic.draw.connect(func():
		var c := Vector2(d, d) * 0.5
		var dim: bool = b.disabled
		var ink := Color(0.1, 0.05, 0.02, 0.35 if dim else 1.0)
		ic.draw_circle(c, d * 0.46, ink)
		ic.draw_circle(c, d * 0.40, Color("f5d9a0") if not b.button_pressed else Color("d9a85c"))
		var r := d * 0.17
		match sign:
			"<":
				ic.draw_colored_polygon(PackedVector2Array([c + Vector2(-r, 0), c + Vector2(r * 0.7, -r), c + Vector2(r * 0.7, r)]), ink)
			">":
				ic.draw_colored_polygon(PackedVector2Array([c + Vector2(r, 0), c + Vector2(-r * 0.7, -r), c + Vector2(-r * 0.7, r)]), ink)
			"+":
				ic.draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), ink, 3.0)
				ic.draw_line(c + Vector2(0, -r), c + Vector2(0, r), ink, 3.0)
			"-":
				ic.draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), ink, 3.0)
	)
	b.pressed.connect(func(): Sfx.play("click"))
	return b


## Botón redondo rojo con ✔ o ✘ (aceptar / cancelar).
func _round_ok(ok: bool, d: float = 76.0) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(d, d)
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var ic := Control.new()
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)
	_place(ic, 0, 0, d, d)
	ic.draw.connect(func():
		var c := Vector2(d, d) * 0.5 + (Vector2(0, 2) if b.button_pressed else Vector2.ZERO)
		ic.draw_circle(c + Vector2(0, 4), d * 0.46, Color(0, 0, 0, 0.4))
		ic.draw_circle(c, d * 0.46, Color("5a0f0f"))
		ic.draw_circle(c, d * 0.42, Color("c0482f"))
		ic.draw_circle(c - Vector2(0, d * 0.05), d * 0.36, Color("d95a3c"))
		var s := d * 0.2
		if ok:
			ic.draw_polyline(PackedVector2Array([c + Vector2(-s, 0), c + Vector2(-s * 0.3, s * 0.8), c + Vector2(s * 1.1, -s * 0.9)]), Color("22c55e"), 7.0, true)
		else:
			ic.draw_line(c + Vector2(-s, -s), c + Vector2(s, s), Color("fb923c"), 7.0, true)
			ic.draw_line(c + Vector2(s, -s), c + Vector2(-s, s), Color("fb923c"), 7.0, true)
	)
	b.pressed.connect(func(): Sfx.play("click"))
	return b


# ---------- Pestañas de combate (stats / armadura / items / info) ----------
var crowd_v := 0.5
var crowd_ctl: Control
var tab_pop: Control


func set_crowd(v: float) -> void:
	crowd_v = lerpf(crowd_v, clampf(v, 0.0, 1.0), 0.15)
	if crowd_ctl:
		crowd_ctl.queue_redraw()


func _build_tabs(b: Control) -> void:
	var names := {"stats": "stats", "armour": "equipo", "items": "items", "info": "info"}
	var x := W - 4.0 - 4 * 66.0
	for k in names:
		var t := Button.new()
		t.focus_mode = Control.FOCUS_NONE
		t.text = names[k]
		t.add_theme_font_size_override("font_size", 14)
		for st in ["normal", "hover", "pressed", "focus"]:
			var s := _sb(Color("e8a317") if st != "pressed" else Color("b8790f"), 3, INK_C, 2)
			t.add_theme_stylebox_override(st, s)
		for cn in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			t.add_theme_color_override(cn, INK_C)
		b.add_child(t)
		_place(t, x, 6, 64, 28)
		x += 66.0
		var key: String = k
		t.pressed.connect(func(): _open_tab(key))
	crowd_ctl = Control.new()
	crowd_ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(crowd_ctl)
	_place(crowd_ctl, W - 4.0 - 264.0, 38, 264, 20)
	crowd_ctl.draw.connect(func():
		crowd_ctl.draw_rect(Rect2(0, 0, 264, 20), Color("1a0e05"))
		crowd_ctl.draw_rect(Rect2(2, 2, 260, 16), Color("7f1d1d"))
		crowd_ctl.draw_rect(Rect2(2, 2, 260.0 * crowd_v, 16), Color("22c55e"))
		var f := ThemeDB.fallback_font
		var txt := "público: " + ("¡enloquecido!" if crowd_v > 0.8 else ("animado" if crowd_v > 0.45 else "aburrido"))
		crowd_ctl.draw_string(f, Vector2(0, 15), txt, HORIZONTAL_ALIGNMENT_CENTER, 264, 13, Color.WHITE)
	)
	tab_pop = Control.new()
	tab_pop.visible = false
	b.add_child(tab_pop)
	tab_pop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _open_tab(k: String) -> void:
	for c in tab_pop.get_children():
		tab_pop.remove_child(c)
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tab_pop.add_child(dim)
	var v := _parch(tab_pop, Rect2(24, 90, W - 48, 560), 5)
	var titles := {"stats": "ESTADÍSTICAS", "armour": "EQUIPO", "items": "OBJETOS", "info": "CÓMO SE JUEGA"}
	v.add_child(_ink(titles[k], 30, HORIZONTAL_ALIGNMENT_CENTER))
	var lines: Array = []
	match k:
		"stats":
			var pr: Array = GameState.xp_progress()
			lines.append("%s · Nivel %d · XP %d/%d" % [String(GameState.data.get("name", "")), GameState.level(), int(pr[0]), int(pr[1])])
			for s in GameState.STATS:
				lines.append("%s: %d" % [GameState.STAT_NAMES[s], GameState.stat(s)])
			var pf := GameState.player_fighter()
			lines.append("Vida %d · Energía %d" % [int(pf.max_hp), int(pf.max_en)])
		"armour":
			var tn := {"weapon": "Arma", "helmet": "Casco", "armor": "Armadura", "shield": "Escudo", "outfit": "Traje", "cape": "Capa", "paint": "Pintura"}
			for s in tn:
				lines.append("%s: %s" % [tn[s], String(GameState.item_def(s, String(GameState.data.equip.get(s, "none"))).name)])
		"items":
			for pid in GameState.POTIONS:
				lines.append("%s: x%d" % [String(GameState.POTIONS[pid].name), GameState.potion_count(String(pid))])
			lines.append("Oro: %d" % int(GameState.data.gold))
		"info":
			lines = ["Elige dónde golpear: cabeza, cuerpo o piernas.", "Cerca los golpes son más críticos; lejos usa magia o lanza el arma.", "Defender recupera energía y reduce el daño.", "Empujar aparta al rival si estás cerca.", "El público se emociona con golpes críticos y combos.", "Perder también da experiencia."]
	for ln in lines:
		var l := _ink(String(ln), 19)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(430, 0)
		v.add_child(l)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var cl := _round_ok(false, 64)
	cl.pressed.connect(func(): tab_pop.visible = false)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_END
	hb.add_child(cl)
	v.add_child(hb)
	tab_pop.visible = true
