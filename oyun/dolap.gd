extends CanvasLayer
# Kıyafet dolabı (PLAN-canlilik-dolap.md K1/K3). Şimdilik ekonomi: havuç cüzdanı, satın alma, giyme ve kayıt.
# Fonksiyonlar katalogu parametre alır (oyunda M.OUTFITS, testte küçük bir sözlük): {id: {ad, kime, fiyat, yuva, ...}}.
# Durum: {havuc: int, alinan: [id], giyili: {"tavsan": {yuva: id}, "halil": {yuva: id}}}.
# Panel: main.gd menüdeki "Dolap" düğmesiyle kurar (setup); değişince changed(kime), kapanınca closed yayar.

signal changed(who: String)
signal closed

const Secim := preload("res://secim.gd")
const START_GIFT := 10  # ilk açılışta hediye
const WIN_HAVUC := 10   # yuvaya varınca ek
const WHO := ["tavsan", "halil"]
const WHO_AD := {tavsan = "Tavşan", halil = "Halil"}


static func empty_state(havuc: int) -> Dictionary:
	return {havuc = havuc, alinan = [], giyili = {tavsan = {}, halil = {}}}


# Koşudan sonra cüzdan: kazanç eksi olamaz, cüzdan eksiye düşmez.
static func wallet_after(cuzdan: int, kazanc: int) -> int:
	return maxi(cuzdan + maxi(kazanc, 0), 0)


static func earned(carrots_total: int, won: bool) -> int:
	return maxi(carrots_total, 0) + (WIN_HAVUC if won else 0)


static func can_buy(st: Dictionary, id: String, cat: Dictionary) -> bool:
	return cat.has(id) and not id in st.alinan and st.havuc >= cat[id].fiyat


# Para yetiyorsa alır (giymez); yetmiyorsa durumu aynen döner. Kaynak durum değişmez.
static func buy(st: Dictionary, id: String, cat: Dictionary) -> Dictionary:
	if not can_buy(st, id, cat):
		return st
	var out := st.duplicate(true)
	out.havuc -= cat[id].fiyat
	out.alinan.append(id)
	return out


# Alınmış ürünü sahibinin yuvasına giyer; aynı yuvadaki eskisini çıkarır.
static func equip(st: Dictionary, id: String, cat: Dictionary) -> Dictionary:
	if not (cat.has(id) and id in st.alinan):
		return st
	var out := st.duplicate(true)
	out.giyili[cat[id].kime][cat[id].yuva] = id
	return out


static func unequip(st: Dictionary, id: String, cat: Dictionary) -> Dictionary:
	if not (cat.has(id) and st.giyili[cat[id].kime].get(cat[id].yuva) == id):
		return st
	var out := st.duplicate(true)
	out.giyili[cat[id].kime].erase(cat[id].yuva)
	return out


# Kayıttan gelen ham değerleri doğrular: tür hatası, bilinmeyen id, eksi para, alınmamış ya da yanlış yuvadaki giysi atılır.
static func clean_dolap(havuc: Variant, alinan: Variant, giyili: Dictionary, cat: Dictionary) -> Dictionary:
	var st := empty_state(maxi(havuc, 0) if havuc is int else START_GIFT)
	if alinan is Array:
		for id in alinan:
			if (id is String or id is StringName) and cat.has(id) and not String(id) in st.alinan:  # katalog anahtarları StringName
				st.alinan.append(String(id))
	for who in WHO:
		var g = giyili.get(who)
		if not g is Dictionary:
			continue
		for yuva in g:
			var id = g[yuva]
			if (id is String or id is StringName) and String(id) in st.alinan and cat[id].kime == who and cat[id].yuva == yuva:
				st.giyili[who][String(yuva)] = String(id)
	return st


static func load_state(cat: Dictionary) -> Dictionary:
	var cf := Secim.config()
	return clean_dolap(cf.get_value("cuzdan", "havuc", START_GIFT), cf.get_value("dolap", "alinan", []),
			{tavsan = cf.get_value("dolap", "giyili_tavsan", {}), halil = cf.get_value("dolap", "giyili_halil", {})}, cat)


static func save_state(st: Dictionary) -> void:
	Secim.save("cuzdan", {havuc = st.havuc})
	Secim.save("dolap", {alinan = st.alinan, giyili_tavsan = st.giyili.tavsan, giyili_halil = st.giyili.halil})


# Koşu sonu (finish): kazancı cüzdana ekle ve hemen kaydet. Dolap kısmına dokunmaz.
static func bank_run(carrots_total: int, won: bool) -> int:
	var cf := Secim.config()
	var cur = cf.get_value("cuzdan", "havuc", START_GIFT)
	var after := wallet_after(maxi(cur, 0) if cur is int else START_GIFT, earned(carrots_total, won))
	Secim.save("cuzdan", {havuc = after})
	return after


# Giyili kıyafetleri modele ekler: gizle renkli temel parçalar çıkar, kıyafet parçaları sona eklenir.
# rig ({grup: [eklem, [indeks]]}) yeni indekslere taşınır; eklem adı rig'de varsa kıyafet o eklemle oynar. Kaynaklar değişmez.
static func dress(parts: Array, rig: Dictionary, ids: Array, cat: Dictionary) -> Array:
	var hide := []
	for id in ids:
		hide.append_array(cat[id].get("gizle", []))
	var out := []
	var moved := {}  # eski indeks -> yeni
	for i in parts.size():
		if not parts[i][1] in hide:
			moved[i] = out.size()
			out.append(parts[i])
	var r := {}
	for g in rig:
		r[g] = [rig[g][0], rig[g][1].filter(func(i): return moved.has(i)).map(func(i): return moved[i])]
	for id in ids:
		var g = cat[id].get("eklem")
		for pt in cat[id].parts:
			if r.has(g):
				r[g][1].append(out.size())
			out.append(pt)
	for g in r.keys():
		if r[g][1].is_empty():  # tüm parçaları gizlenen grup eklem olmasın
			r.erase(g)
	return [out, r]


static func worn(st: Dictionary, who: String) -> Array:
	return st.giyili[who].values()


# Liste satırındaki düğme yazısı.
static func label_for(st: Dictionary, id: String, cat: Dictionary) -> String:
	if st.giyili[cat[id].kime].get(cat[id].yuva) == id:
		return "Çıkar"
	if id in st.alinan:
		return "Giy"
	return ("Al (%d)" if can_buy(st, id, cat) else "Yetmiyor (%d)") % cat[id].fiyat


# Tek tık: giyiliyse çıkar, alınmışsa giy, alınabiliyorsa al ve giy; yetmiyorsa değişmez.
static func act(st: Dictionary, id: String, cat: Dictionary) -> Dictionary:
	if st.giyili[cat[id].kime].get(cat[id].yuva) == id:
		return unequip(st, id, cat)
	return equip(buy(st, id, cat), id, cat)


# --- Panel ---

var st: Dictionary
var cat: Dictionary
const PANEL_LEFT := 0.45  # panel ekranın sağ yarısında (Tasarımcı ayarlar)
const PANEL_GAP := 16.0
var who := "tavsan"
var sel := 0
var rows: VBoxContainer
var money: Label
var tab_btns := {}


func setup(state: Dictionary, catalog: Dictionary, th: Theme) -> void:
	st = state
	cat = catalog
	var pc := PanelContainer.new()  # sağ yarıda: önizlenen karakter solda açık kalsın
	pc.theme = th
	pc.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	pc.anchor_left = PANEL_LEFT
	pc.offset_left = PANEL_GAP
	pc.offset_top = PANEL_GAP
	pc.offset_right = -PANEL_GAP
	pc.offset_bottom = -PANEL_GAP
	add_child(pc)
	var col := VBoxContainer.new()
	pc.add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	for w in WHO:
		tab_btns[w] = button(WHO_AD[w], show_tab.bind(w))
		top.add_child(tab_btns[w])
	money = Label.new()
	money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(money)
	var scroll := ScrollContainer.new()  # telefonda (390 px) 6 satır sığmaz: liste kayar
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var hint := Label.new()
	hint.text = "↑ ↓ seç · Enter al/giy · Tab karakter · Esc kapat"
	hint.add_theme_font_size_override("font_size", 16)
	col.add_child(hint)
	col.add_child(button("Kapat", close))
	refresh()


func button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 52)  # parmak hedefi
	b.pressed.connect(on_press)
	return b


func ids() -> Array:
	var out := cat.keys().filter(func(id): return cat[id].kime == who)
	out.sort_custom(func(a, b): return cat[a].fiyat < cat[b].fiyat)
	return out


func show_tab(w: String) -> void:
	who = w
	sel = 0
	changed.emit(w)  # önizleme kamerası bu karaktere geçsin
	refresh()


func refresh() -> void:
	money.text = "Havuç: %d" % st.havuc
	for w in tab_btns:
		tab_btns[w].modulate.a = 1.0 if w == who else 0.55
	for r in rows.get_children():
		r.free()
	var list := ids()
	for i in list.size():
		var id: String = list[i]
		var row := HBoxContainer.new()
		rows.add_child(row)
		var name := Label.new()
		name.text = ("▶ " if i == sel else "   ") + cat[id].get("ad", id)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name)
		var b := button(label_for(st, id, cat), pick.bind(i))
		b.modulate.a = 0.5 if label_for(st, id, cat).begins_with("Yetmiyor") else 1.0
		row.add_child(b)


func pick(i: int) -> void:
	sel = i
	var id: String = ids()[i]
	var after := act(st, id, cat)
	if after != st:
		st = after
		save_state(st)
		changed.emit(who)
	refresh()


func close() -> void:
	closed.emit()
	queue_free()


func _input(e: InputEvent) -> void:
	if not e.is_pressed() or e.is_echo():
		return
	var n := ids().size()
	if e.is_action_pressed("ui_up") or e.is_action_pressed("ui_down"):
		sel = wrapi(sel + (-1 if e.is_action_pressed("ui_up") else 1), 0, n)
		refresh()
	elif e.is_action_pressed("ui_accept") and n > 0:
		pick(sel)
	elif e.is_action_pressed("ui_focus_next"):  # Tab
		show_tab(WHO[(WHO.find(who) + 1) % WHO.size()])
	elif e.is_action_pressed("ui_cancel"):
		close()
	else:
		return
	get_viewport().set_input_as_handled()
