extends CanvasLayer
# Seçim ekranı: tavşanın rengi ve adı (PLAN-karakter-secimi.md). main.gd "menu" durumunda kurar.
# Görünüm Tasarımcı'nın (T-b); mantık ve kayıt burada.

signal renk(skin: int)                # tavşanı yeniden boya
signal basla(isim: String)  # renk zaten renk sinyaliyle uygulandı

const M := preload("res://modeller.gd")
const NAME_MAX := 12
const TOP := 5  # skor tablosunda tutulan kayıt
const TITLE_C := Color(1.0, 0.86, 0.45)       # başlık: sıcak sarı, koyu kahve kenar (Tasarımcı)
const TITLE_EDGE := Color(0.33, 0.22, 0.14)

const HELP_TEXT := "Kontroller\n← →  şerit değiştir\n↑ / Space  zıpla\n↓  havuçla atıl (3 havuç)\nTelefon: dokun sol / orta / sağ\n(sola, zıpla, sağa), aşağı kaydır = atıl"

static var ayar_path := "user://ayar.cfg"  # senaryo testleri kendi dosyasını verir, kullanıcının kaydı bozulmaz

var skin := 0
var skin_label: Label
var name_box: LineEdit


# Denetim karakterleri (sekme, satır sonu, sağdan sola geçersiz kılma vb.) isme girmez.
static func is_control(c: int) -> bool:
	return c < 32 or (c >= 127 and c < 160) or (c >= 0x200B and c <= 0x200F) or (c >= 0x202A and c <= 0x202E) or (c >= 0x2066 and c <= 0x2069)


static func clean_name(s: String, fallback: String) -> String:
	var n := ""
	for ch in s.replace("\n", " "):  # satır sonu kelimeler arasında boşluk olur
		if not is_control(ch.unicode_at(0)):
			n += ch
	n = n.strip_edges().left(NAME_MAX).strip_edges()
	return n if n != "" else fallback


# RABBIT'in kürk, kulak içi ve kuyruk renklerini seçilen setle değiştirir; parça sayısı ve konumlar aynı kalır.
static func skin_parts(parts: Array, s: Dictionary) -> Array:
	var swap := {M.FUR: s.fur, M.EAR_PINK: s.ear, M.TAIL: s.tail}
	var out := []
	for pt in parts:
		var p: Array = pt.duplicate()
		p[1] = swap.get(p[1], p[1])
		out.append(p)
	return out


# Yeni kaydı ekler, puana göre sıralar, en iyi TOP kaydı döner. Kaynak liste değişmez.
static func insert_score(list: Array, entry: Dictionary) -> Array:
	var out := list.duplicate()
	out.append(entry)
	out.sort_custom(func(a, b): return a.puan > b.puan)
	return out.slice(0, TOP)


# Dosya yoksa ya da bozuksa boş bir ConfigFile kalır; okuyanlar varsayılana düşer.
static func config() -> ConfigFile:
	var cf := ConfigFile.new()
	cf.load(ayar_path)
	return cf


static func load_choice() -> Dictionary:
	var cf := config()
	var s = cf.get_value("secim", "skin", 0)
	var n = cf.get_value("secim", "isim", "")
	return {skin = clampi(s, 0, M.RABBIT_SKINS.size() - 1) if s is int else 0, isim = clean_name(n, "") if n is String else ""}


static func load_scores() -> Array:
	var v = config().get_value("skor", "liste", [])
	if not v is Array:
		return []
	var ok: Array = v.filter(func(e): return e is Dictionary and e.get("puan") is int and e.get("isim") is String)
	var clean: Array = ok.map(func(e): return {isim = clean_name(e.isim, "?"), puan = e.puan})
	clean.sort_custom(func(a, b): return a.puan > b.puan)
	return clean.slice(0, TOP)  # elle bozulmuş dosya da tabloyu taşırmasın


static func save(section: String, values: Dictionary) -> void:
	var cf := config()  # diğer bölümler korunsun
	for k in values:
		cf.set_value(section, k, values[k])
	if cf.save(ayar_path) != OK:
		push_warning("ayar dosyası yazılamadı: " + ayar_path)


func _ready() -> void:
	var c := load_choice()
	skin = c.skin
	var panel := PanelContainer.new()
	add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	var row := HBoxContainer.new()
	col.add_child(row)
	row.add_child(button("◀", pick.bind(-1)))
	skin_label = Label.new()
	skin_label.custom_minimum_size.x = 220
	skin_label.add_theme_font_size_override("font_size", 34)
	skin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(skin_label)
	row.add_child(button("▶", pick.bind(1)))
	name_box = LineEdit.new()
	name_box.max_length = NAME_MAX
	name_box.placeholder_text = "Tavşanın adı"
	name_box.text = c.isim
	name_box.text_submitted.connect(func(_t): start())
	col.add_child(name_box)
	col.add_child(button("Koş! (Enter)", start))
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 40)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var best_box := PanelContainer.new()  # en iyiler: sağ üstte
	var best := Label.new()
	best.text = "En iyiler\n" + score_lines(load_scores(), -1)
	best_box.add_child(best)
	best_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	best_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(best_box)
	var help_box := PanelContainer.new()  # kontroller: sol altta küçük bilgi alanı
	var help := Label.new()
	help.text = HELP_TEXT
	help.add_theme_font_size_override("font_size", 16)
	help_box.add_child(help)
	help_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 24)
	help_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(help_box)
	var title := Label.new()  # oyunun adı: üstte ortada, kenar çizgili
	title.text = "Tavşan Kaçışı"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", TITLE_C)
	title.add_theme_color_override("font_outline_color", TITLE_EDGE)
	title.add_theme_constant_override("outline_size", 16)
	title.rotation_degrees = -3
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 28)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(title)
	skin_label.text = M.RABBIT_SKINS[skin].ad
	name_box.grab_focus.call_deferred()


func button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE  # odak hep isim kutusunda kalsın
	b.pressed.connect(on_press)
	return b


# ↑↓ isim kutusuna ulaşmadan renk değiştirir (←→ kutuda imleci oynatır).
# Fareyle boş yere tıklanıp kutu odağı kaybetse de Enter koşuyu başlatır.
func _input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_up") or e.is_action_pressed("ui_down"):
		pick(-1 if e.is_action_pressed("ui_up") else 1)
		get_viewport().set_input_as_handled()
	elif (e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_ENTER, KEY_KP_ENTER] and not name_box.has_focus()) \
			or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A):  # gamepad A da başlatır
		get_viewport().set_input_as_handled()
		start()


func pick(d: int) -> void:
	skin = wrapi(skin + d, 0, M.RABBIT_SKINS.size())
	skin_label.text = M.RABBIT_SKINS[skin].ad
	renk.emit(skin)


# Skor tablosu satırları; mark sıradaki kayıt "◀" ile işaretlenir.
static func score_lines(list: Array, mark: int) -> String:
	if list.is_empty():
		return "henüz yok"
	var lines := []
	for i in list.size():
		lines.append("%d. %s  %d%s" % [i + 1, list[i].isim, list[i].puan, "  ◀" if i == mark else ""])
	return "\n".join(lines)


func start() -> void:
	var typed := clean_name(name_box.text, "")
	save("secim", {skin = skin, isim = typed})  # boş isim boş kaydedilir; renk değişince varsayılan ad ona uyar
	basla.emit(typed if typed != "" else M.RABBIT_SKINS[skin].ad)
	queue_free()
