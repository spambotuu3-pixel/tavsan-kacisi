extends SceneTree
# Çalıştır: godot --headless --path . -s test.gd

const Main = preload("res://main.gd")
const Secim = preload("res://secim.gd")
const Mod = preload("res://modeller.gd")
const Ses = preload("res://ses.gd")
const Dolap = preload("res://dolap.gd")
const CAT := {sapka = {kime = "tavsan", yuva = "kafa", fiyat = 25}, tac = {kime = "tavsan", yuva = "kafa", fiyat = 40},
		fular = {kime = "tavsan", yuva = "boyun", fiyat = 60}, kovboy = {kime = "halil", yuva = "kafa", fiyat = 25}}


func _init() -> void:
	var cases := [
		[Main.hits(Vector3(0, 0, 0), 0, 0.3, 0.6), true, "aynı şeritte çite çarpar"],
		[Main.hits(Vector3(0, 1, 0), 0, 0, 0.6), false, "zıplayınca çitin üstünden geçer"],
		[Main.hits(Vector3(0, 1, 0), 0, 0, 1.6), true, "varilin üstünden atlanamaz"],
		[Main.hits(Vector3(2, 0, 0), 0, 0, 1.6), false, "yan şeritteki engel çarpmaz"],
		[range(50).all(func(_i): return Main.pick_free(0) != 2), true, "boş şerit soldan sağa atlamaz"],
		[range(50).all(func(_i): return Main.pick_free(2) != 0), true, "boş şerit sağdan sola atlamaz"],
		[Main.can_dash(3, 0.0), true, "3 havuçla atılır"],
		[Main.can_dash(2, 0.0) or Main.can_dash(5, 1.0), false, "havuç azken ya da atılım sürerken atılamaz"],
		[Main.near_miss(1, 0.1, 1, false), true, "hedef şeridi son anda terk etmek kıl payı"],
		[Main.near_miss(1, 0.5, 1, false), false, "erken kaçış kıl payı değil"],
		[Main.near_miss(-1, 9.0, 1, true), true, "hedefin üstünden atlamak kıl payı"],
		[Secim.clean_name("  ", "Pamuk"), "Pamuk", "boş isim rengin adını alır"],
		[Secim.clean_name(" Şeker İğne ", "x"), "Şeker İğne", "Türkçe harfler korunur, boşluk silinir"],
		[Secim.clean_name("abcdefghijklmn", "x"), "abcdefghijkl", "isim 12 karaktere kısalır"],
		[Main.ZONES.all(func(z): return Mod.ZONE_DECO.has(z[1])), true, "her bölgenin kenar dekoru tanımlı"],
		[Secim.clean_name("a\tb\r\u202eç", "x"), "abç", "denetim karakterleri isme girmez"],
		[skin_ok(), true, "renk seti kürkü boyar, parça sayısı ve konumlar aynı kalır"],
		[[Main.zone(0), Main.zone(250), Main.zone(400), Main.zone(560)], ["tarla", "kopek", "kumes", "son"], "bölgeler mesafeye göre"],
		[Main.crossed([200.0, 350.0], 190, 210), [200.0], "200 m eşiği bir kez geçilir"],
		[Main.crossed([200.0, 350.0], 210, 220), [], "eşik yoksa olay yok"],
		[[Main.score(600, 5, true), Main.score(123.9, 0, false)], [850, 123], "puan = m + havuç×10 + yuva bonusu"],
		[Secim.insert_score([], {isim = "a", puan = 5}), [{isim = "a", puan = 5}], "boş tabloya eklenir"],
		[Secim.insert_score(scores(5), {isim = "z", puan = 0}).size(), 5, "6. kayıt kesilir"],
		[Secim.insert_score(scores(5), {isim = "z", puan = 25})[3].isim, "z", "tablo puana göre sıralı"],
		[Secim.score_lines([], -1), "henüz yok", "boş tablo yazısı"],
		[[Main.near_lanes(0), Main.near_lanes(1), Main.near_lanes(2)], [[1], [0, 2], [1]], "kenar şeridin tek komşusu var"],
		[Secim.clean_name("a\nb", "x"), "a b", "isimdeki satır sonu boşluk olur"],
		[[Main.feast_piles(0), Main.feast_piles(9), Main.feast_piles(1000), Main.feast_piles(-5)], [4, 7, 12, 4], "şölen yığın sayısı havuca bağlı, 4..12"],
		[[Main.touch_action(10, 300), Main.touch_action(150, 300), Main.touch_action(290, 300), Main.touch_action(150, 300, Vector2(5, 80))], ["left", "jump", "right", "dash"], "dokunma: bölgeler ve aşağı kaydırma"],
		[[Main.touch_action(10, 300, Vector2(0, 30)), Main.touch_action(10, 300, Vector2(90, 80)), Main.touch_action(150, 300, Vector2(0, 50), 40.0)], ["left", "left", "dash"], "kısa ya da yatay kaydırma atıl değil, eşik ekrana bağlı"],
		[[Main.swipe_min(200), Main.swipe_min(844), Main.swipe_min(2000)], [40.0, 67.52, 90.0], "kaydırma eşiği ekran yüksekliğinin %8'i, 40..90"],
		[[Main.near_miss(1, 0.28, 1, false), Main.near_miss(1, 0.28, 1, false, Main.NEAR_TIME_TOUCH)], [false, true], "telefonda kıl payı penceresi geniş"],
		[[Ses.parse_on(true), Ses.parse_on(false), Ses.parse_on("x"), Ses.parse_on(null), Ses.parse_on(0)], [true, false, true, true, true], "ses ayarı: yalnız bool geçerli, değilse açık"],
		[Ses.make_all().keys().filter(func(k): return Ses.check(Ses.make_all()[k]) != ""), [], "tüm sesler: süre, tepe <= 0,8, kırpma ve sessizlik yok"],
		[Ses.make_all().music.loop_mode == AudioStreamWAV.LOOP_FORWARD and Ses.make_all().music.loop_end == Ses.make_all().music.data.size() / 2, true, "müzik döngülü, döngü sonu örnek sayısı"],
		[[Main.flag(true, false), Main.flag(false, true), Main.flag("x", true), Main.flag(null, false), Main.flag(1, false)], [true, false, true, false, false], "ayar bayrağı: yalnız bool geçerli, değilse varsayılan"],
		[[Main.speed_mult(false), Main.speed_mult(true)], [1.0, 0.85], "yavaş mod yalnız hız çarpanı (%85)"],
		[[Main.shake_amount(Main.SHAKE_TIME, true), Main.shake_amount(0.0, true), Main.shake_amount(Main.SHAKE_TIME, false), Main.shake_amount(-1.0, true)], [Main.SHAKE_AMP, 0.0, 0.0, 0.0], "sarsıntı: süreyle söner, kapalıyken sıfır"],
		[[Main.gap_text(0.1).contains("YAKIN!"), Main.gap_text(0.5).contains("YAKIN!"), Main.gap_text(0.5) != Main.gap_text(0.9)], [true, false, true], "Halil çubuğu yazısı renksiz de okunur"],
		[Main.SHAKE_TIME <= 0.25 and Main.FLASH_TIME <= 0.2 and Main.HITSTOP <= 0.06, true, "vurulma efektleri süre sınırlarında"],
		[[Dolap.wallet_after(5, 7), Dolap.wallet_after(0, -9), Dolap.wallet_after(-3, 0), Dolap.earned(4, true), Dolap.earned(4, false)], [12, 0, 0, 14, 4], "cüzdan eksiye düşmez, yuva +10"],
		[[Dolap.can_buy(Dolap.empty_state(24), "sapka", CAT), Dolap.buy(Dolap.empty_state(24), "sapka", CAT).havuc], [false, 24], "para yetmiyorsa alınmaz"],
		[Dolap.buy(Dolap.buy(Dolap.empty_state(100), "sapka", CAT), "sapka", CAT).havuc, 75, "aynı ürün iki kez alınmaz"],
		[Dolap.can_buy(Dolap.empty_state(100), "yok", CAT), false, "bilinmeyen ürün alınmaz"],
		[dolap_slot(), ["tac", "kovboy", ""], "yuvada tek kıyafet; çıkar çalışır; alınmamış giyilmez"],
		[Dolap.clean_dolap(-5, ["sapka", "yok", 3, "sapka"], {tavsan = {kafa = "kovboy", boyun = "fular"}, halil = "x"}, CAT),
				{havuc = 0, alinan = ["sapka"], giyili = {tavsan = {}, halil = {}}}, "bozuk dolap kaydı temizlenir"],
		[Dolap.clean_dolap("x", null, {}, CAT).havuc, Dolap.START_GIFT, "kayıt yoksa ilk hediye"],
		[Dolap.clean_dolap(5, [&"sapka"], {tavsan = {&"kafa": &"sapka"}}, CAT), {havuc = 5, alinan = ["sapka"], giyili = {tavsan = {kafa = "sapka"}, halil = {}}}, "StringName kimlikli kayıt da okunur"],
		[Mod.OUTFITS.keys().filter(func(id): var o: Dictionary = Mod.OUTFITS[id]; return not (o.get("kime") in Dolap.WHO and o.get("fiyat") is int and o.fiyat > 0 and o.get("yuva") is String and o.get("parts") is Array)), [],
				"kıyafet verisi dolap sözleşmesine uyuyor (kime, fiyat > 0, yuva, parts)"],
		[Mod.OUTFITS.keys().all(func(id): return Dolap.equip(Dolap.buy(Dolap.empty_state(1000), id, Mod.OUTFITS), id, Mod.OUTFITS).giyili[Mod.OUTFITS[id].kime].get(Mod.OUTFITS[id].yuva) == id), true,
				"her gerçek kıyafet alınıp giyilebiliyor"],
		[dress_ok(), true, "kıyafet: gizlenen parça çıkar, eklem indeksleri kayar, kafa kıyafeti eklemle oynar"],
		[dolap_act(), ["Al (25)", "Çıkar", "Giy", "Yetmiyor (60)", 75], "dolap düğmesi: al+giy, çıkar, yeniden giy; para yetmiyor"],
		[Main.INTRO_TIME <= 2.5 and Main.INTRO_CUES.keys().all(func(k): return k < Main.INTRO_TIME) and Main.INTRO_CUES.values().count(Main.INTRO_GO) == 1, true, "Çabuk Giriş: açılış ≤ 2,5 sn, geri sayım yok, KAÇ! bir kez"],
		[[Secim.best_text([]), Secim.best_text([{isim = "Pamuk", puan = 850}, {isim = "x", puan = 1}])], ["En iyi: henüz yok", "En iyi: Pamuk  850"], "menü çipi en iyi skoru gösterir"],
		[dolap_kayit(), true, "dolap kaydı gidip gelir, koşu kazancı cüzdana eklenir (test dosyası)"],
		[Main.HIT_SND.keys().map(func(k): return Main.hit_snd(k)), Main.HIT_SND.values(), "engel türü ses anahtarına eşlenir"],
		[[Main.hit_snd(""), Main.hit_snd("bilinmez")], ["bonk", "bonk"], "bilinmeyen engel türü eski çarpma sesini çalar"],
		[Main.HIT_SND.values().all(func(k): return Ses.make_all().has(k)) and Main.HIT_SND.values().size() == Main.HIT_SND.values().filter(func(k): return k != "bonk").size(), true, "her çarpma sesinin üretilmiş yedeği var"],
		[Ses.FILES.keys().all(func(k): return Main.HIT_SND.values().has(k)), true, "dosya anahtarları çarpma anahtarlarından"],
		[rigs_ok(), true, "iskelet grupları: indeksler geçerli ve tekil, varlık başına <= 6 mesh, poz anahtarları eklem"],
		[pose_bounded(), true, "poz açıları sınırlı (|açı| <= ANIM_MAX), değerler sonlu"],
	]
	var failed := 0
	for c in cases:
		if c[0] != c[1]:
			failed += 1
			print("HATA: ", c[2])
	print("ok" if failed == 0 else "%d test başarısız" % failed)
	quit(failed)


func dolap_slot() -> Array:
	var st := Dolap.buy(Dolap.buy(Dolap.empty_state(200), "sapka", CAT), "tac", CAT)
	st = Dolap.equip(Dolap.equip(st, "sapka", CAT), "tac", CAT)
	var halil := Dolap.equip(Dolap.buy(st, "kovboy", CAT), "kovboy", CAT)
	var off := Dolap.unequip(halil, "tac", CAT)
	return [halil.giyili.tavsan.kafa, halil.giyili.halil.kafa, off.giyili.tavsan.get("kafa", "") + Dolap.equip(off, "fular", CAT).giyili.tavsan.get("boyun", "")]


func dress_ok() -> bool:
	var red := Color.RED
	var parts := [[Vector3.ONE, Color.BLUE, Vector3.ZERO], [Vector3.ONE, red, Vector3.ZERO], [Vector3.ONE, Color.GREEN, Vector3.ZERO]]
	var rig := {hat = [Vector3.UP, [1]], leg = [Vector3.ZERO, [2]]}
	var cat := {s = {kime = "halil", yuva = "bas", fiyat = 1, gizle = [red], eklem = "hat", parts = [[Vector3.ONE, Color.WHITE, Vector3.ZERO]]}}
	var d := Dolap.dress(parts, rig, ["s"], cat)
	var bare := Dolap.dress(parts, rig, [], cat)
	return d[0].size() == 3 and d[0][2][1] == Color.WHITE and d[1].leg[1] == [1] and d[1].hat[1] == [2] \
			and bare[0] == parts and bare[1] == rig and rig.hat[1] == [1] and parts.size() == 3  # kaynak bozulmadı


func dolap_act() -> Array:
	var st := Dolap.empty_state(100)
	var a := Dolap.label_for(st, "sapka", CAT)
	st = Dolap.act(st, "sapka", CAT)
	var b := Dolap.label_for(st, "sapka", CAT)
	var off := Dolap.act(st, "sapka", CAT)
	return [a, b, Dolap.label_for(off, "sapka", CAT), Dolap.label_for(Dolap.empty_state(10), "fular", CAT), off.havuc]


func dolap_kayit() -> bool:  # kullanıcının ayar.cfg'si değil, geçici dosya
	var real := Secim.ayar_path
	Secim.ayar_path = "user://test_dolap.cfg"
	DirAccess.remove_absolute(Secim.ayar_path)
	var gift: int = Dolap.load_state(CAT).havuc
	var st := Dolap.equip(Dolap.buy(Dolap.empty_state(50), "sapka", CAT), "sapka", CAT)
	Dolap.save_state(st)
	var back := Dolap.load_state(CAT)
	var after := Dolap.bank_run(3, true)
	var ok: bool = gift == Dolap.START_GIFT and back == st and after == 50 - 25 + 13 and Dolap.load_state(CAT).alinan == ["sapka"]
	DirAccess.remove_absolute(Secim.ayar_path)
	Secim.ayar_path = real
	return ok


func scores(n: int) -> Array:  # puanları 50, 40, 30, ... olan sıralı tablo
	return range(n).map(func(i): return {isim = str(i), puan = 50 - i * 10})


func skin_ok() -> bool:
	var s := {fur = Color.RED, ear = Color.GREEN, tail = Color.BLUE}
	var out := Secim.skin_parts(Mod.RABBIT, s)
	return out.size() == Mod.RABBIT.size() and out[0][1] == Color.RED and out[0][2] == Mod.RABBIT[0][2] \
			and not out.any(func(p): return p[1] == Mod.FUR) and Mod.RABBIT[0][1] == Mod.FUR  # kaynak dizi bozulmadı


func rigs_ok() -> bool:
	var rigs := {halil = [Mod.RIG_HALIL, Mod.HALIL], dog = [Mod.RIG_DOG, Mod.DOG], chicken = [Mod.RIG_CHICKEN, Mod.CHICKEN], goose = [Mod.RIG_GOOSE, Mod.GOOSE], rabbit = [Mod.RIG_RABBIT, Mod.RABBIT]}
	for k in rigs:
		var rig: Dictionary = rigs[k][0]
		var seen := []
		for g in rig:
			for i in rig[g][1]:
				if i < 0 or i >= rigs[k][1].size() or i in seen:
					return false
				seen.append(i)
		if rig.size() + 1 > 6:
			return false
		var pose := Main.anim_pose(k, 1.0, 0.0, 0.5)
		for g in pose:
			if g != "body" and not rig.has(g):
				return false
	return true


func pose_bounded() -> bool:
	for k in ["halil", "dog", "chicken", "goose", "rabbit"]:
		for i in 60:
			for a in [0.0, 0.5, 1.0]:
				for v in Main.anim_pose(k, i * 0.37, i * 0.1, a).values():
					if not (is_finite(v.x) and is_finite(v.y) and is_finite(v.z)) or maxf(absf(v.x), maxf(absf(v.y), absf(v.z))) > Main.ANIM_MAX:
						return false
	return true
