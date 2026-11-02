extends SceneTree
# Çalıştır: godot --headless --path . -s test.gd

const Main = preload("res://main.gd")
const Secim = preload("res://secim.gd")
const Mod = preload("res://modeller.gd")


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
	]
	var failed := 0
	for c in cases:
		if c[0] != c[1]:
			failed += 1
			print("HATA: ", c[2])
	print("ok" if failed == 0 else "%d test başarısız" % failed)
	quit(failed)


func scores(n: int) -> Array:  # puanları 50, 40, 30, ... olan sıralı tablo
	return range(n).map(func(i): return {isim = str(i), puan = 50 - i * 10})


func skin_ok() -> bool:
	var s := {fur = Color.RED, ear = Color.GREEN, tail = Color.BLUE}
	var out := Secim.skin_parts(Mod.RABBIT, s)
	return out.size() == Mod.RABBIT.size() and out[0][1] == Color.RED and out[0][2] == Mod.RABBIT[0][2] \
			and not out.any(func(p): return p[1] == Mod.FUR) and Mod.RABBIT[0][1] == Mod.FUR  # kaynak dizi bozulmadı
