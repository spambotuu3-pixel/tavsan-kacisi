extends CanvasLayer
# Kıyafet dolabı (PLAN-canlilik-dolap.md K1/K3). Şimdilik ekonomi: havuç cüzdanı, satın alma, giyme ve kayıt.
# Fonksiyonlar katalogu parametre alır (oyunda M.OUTFITS, testte küçük bir sözlük): {id: {ad, kime, fiyat, yuva, ...}}.
# Durum: {havuc: int, alinan: [id], giyili: {"tavsan": {yuva: id}, "halil": {yuva: id}}}. Panel K3'te gelecek.

const Secim := preload("res://secim.gd")
const START_GIFT := 10  # ilk açılışta hediye
const WIN_HAVUC := 10   # yuvaya varınca ek
const WHO := ["tavsan", "halil"]


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
			if id is String and cat.has(id) and not id in st.alinan:
				st.alinan.append(id)
	for who in WHO:
		var g = giyili.get(who)
		if not g is Dictionary:
			continue
		for yuva in g:
			var id = g[yuva]
			if id is String and id in st.alinan and cat[id].kime == who and cat[id].yuva == yuva:
				st.giyili[who][yuva] = id
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
