extends SceneTree
# Kalite kapısı otomatik pilotu (oyun kodu değil). Çalıştır:
#   godot --path oyun --fixed-fps 60 -s res://kalite/senaryo.gd -- --senaryo=<ad>
# Kullanıcının kaydına dokunmaz: ayarlar user://test_ayar.cfg'de. Sonda "SENARYO OK" ya da "SENARYO HATA" yazar.

const Secim := preload("res://secim.gd")
const Main := preload("res://main.gd")
const Ses := preload("res://ses.gd")
const Dolap := preload("res://dolap.gd")
const M := preload("res://modeller.gd")
const DOLAP_MENU := ["dolap_al", "dolap_yetersiz", "bozuk_dolap_cfg"]  # menüde kalır, koşu başlatmaz
const END_FRAME := 690
const SOFRA_END_FRAME := 1000  # kazan_sofra: giriş + en çok 10 sn şölen kendiliğinden bitmeli
const NAMES := {isim_bos = "", isim_uzun = "Çok-uzun-bir-isim-123", isim_turkce = "Şeker Ğığİ"}

var ad := "menu"
var f := 0
var end_frame := END_FRAME
var reloaded := false  # tekrar_enter / esc_menu: sahne bir kez yenilendi mi
var saw_dog := false
var saw_goose := false
var last_us := 0       # kare süresi ölçümü (pencereli çalıştırmada çizim dahil)
var frame_ms := []
var rng := {}          # animasyon: eklem -> [en küçük, en büyük] x dönüşü


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--senaryo="):
			ad = a.trim_prefix("--senaryo=")
	Secim.ayar_path = "user://test_ayar.cfg"
	if ad == "carpma_ses":
		Main.force_audio = true  # ekransızda da (Dummy sürücü) ses kurulumunu sına
	if ad == "kazan_sofra":
		end_frame = SOFRA_END_FRAME
	match ad:  # senaryo kendi koşulunu kurar, dışarıdaki betiğe güvenmez
		"bozuk_cfg": write_cfg("[secim\nskin = = ][[[ çöp")
		"skor_bos", "ayar_paneli": write_cfg("")  # ayar_paneli ayarları değiştirir: temiz başlar, sonunda temizler
		"dolap_al": write_cfg("[cuzdan]\nhavuc=100\n")
		"dolap_yetersiz": write_cfg("[cuzdan]\nhavuc=0\n")
		"bozuk_dolap_cfg": write_cfg('[cuzdan]\nhavuc="çok"\n[dolap]\nalinan=[1, "yok", "t_tac", "t_tac"]\ngiyili_tavsan={"bas": "h_kovboy", "yuz": 3}\ngiyili_halil=5\n')
		"kiyafetle_kos": wear_all()
		"skor_dolu": write_cfg('[skor]\nliste=[%s]\n' % ", ".join(range(5).map(func(i): return '{"isim": "K%d", "puan": %d}' % [i, 900 - i * 10])))
	change_scene_to_file("res://main.tscn")


# Her karakterin her yuvasına bir kıyafet giydirilmiş kayıt (tüm kıyafetler alınmış).
func wear_all() -> void:
	write_cfg("")
	var st := Dolap.empty_state(0)
	for id in M.OUTFITS:
		st.alinan.append(String(id))
		st = Dolap.equip(st, id, M.OUTFITS)
	Dolap.save_state(st)


func write_cfg(text: String) -> void:
	var fa := FileAccess.open(Secim.ayar_path, FileAccess.WRITE)
	fa.store_string(text)


func _process(_d: float) -> bool:
	f += 1
	var now := Time.get_ticks_usec()
	if f > 10:
		frame_ms.append((now - last_us) / 1000.0)
	last_us = now
	if ad == "dokunma" and f == 2:
		root.size = Vector2i(1280, 720)  # ekransızda pencere 64x64 çıkıyor; HUD paneli ekranı kaplamasın
	var m = current_scene
	if m == null:
		return false
	if ad in DOLAP_MENU:
		dolap_test(m)
	elif ad != "menu" and f == 30:  # menüden başla (isim senaryolarında önce ismi yaz)
		var menu = m.get_children().filter(func(c): return c is Secim)
		if menu.is_empty():
			return fail("menü açılmadı")
		if NAMES.has(ad):
			menu[0].name_box.text = NAMES[ad]
		if ad == "fare_bos":  # boş yere tıkla: isim kutusu odağı kaybetse de Enter çalışmalı
			click(Vector2(40, 400))
		key(KEY_ENTER, true)
	if f == 2 and "focus_pause" in m and ad != "duraklat":
		m.focus_pause = false  # pencere odağı oynak: kendiliğinden duraksatma testleri bozmasın
	if ad == "ses":
		ses_test(m)
	if ad == "animasyon":
		anim_test(m)
	if ad == "carpma_ses":
		carpma_test(m)
	if ad == "duraklat":
		duraklat_test(m)
	if ad == "ayar_paneli":
		ayar_test(m)
	if f == 32:
		key(KEY_ENTER, false)
	if f == 60 and ad != "menu" and not ad in DOLAP_MENU:
		key(KEY_SPACE, true)  # açılışı atla
	if f == 62:
		key(KEY_SPACE, false)
	if f == 120 and m.state == "run":
		if ad in ["kazan", "kazan_sofra"]:
			m.rabbit.position.z = -590.0
		elif ad in ["yakalan", "tekrar_enter", "esc_menu", "skor_dolu", "skor_bos", "bozuk_cfg"]:
			m.gap = -1.0
	if ad == "dokunma" and m.state == "run":
		m.gap = m.GAP_MAX
		touch_test(m)
	if f == 300 and ad == "kazan":  # şölen sürerken Esc: Geç gibi paneli hemen açar
		if m.state != "feast":
			return fail("şölen başlamadı (durum %s)" % m.state)
		key(KEY_ESCAPE, true)
	if ad == "animasyon" and f == 120:
		m.rabbit.position.z = -210.0  # köpek bölgesi: Karabaş çıksın
		m.prev_dist = 210.0
		m.next_row_z = -220.0
	if ad in ["animasyon", "carpma_ses"] and m.state == "run":
		m.gap = m.GAP_MAX
	if ad == "bolgeler" and m.state == "run":  # 190 m'den 520 m'yi geçecek hızla: köpek, kaz ve tüm olaylar
		if f == 120:
			m.rabbit.position.z = -190.0
			m.prev_dist = 190.0
			m.next_row_z = -200.0
		m.rabbit.position.z -= 0.45  # oyunun hızına ek ~27 m/s (vurulma duraksamaları koşuyu kısalttığı için 0,4 değil)
		m.gap = m.GAP_MAX           # yakalanmasın
		saw_dog = saw_dog or not m.dog.is_empty()
		saw_goose = saw_goose or m.items.any(func(it): return it.kind == "goose")
	if f == 300 and ad in ["tekrar_enter", "esc_menu"] and m.state in ["over", "win"]:
		key(KEY_ENTER if ad == "tekrar_enter" else KEY_ESCAPE, true)
		reloaded = true
	if f == 302:
		key(KEY_ENTER, false)
		key(KEY_ESCAPE, false)
	if f == end_frame:
		check(m)
	return false


func touch(at: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = at
	e.pressed = down
	Input.parse_input_event(e)


func drag(at: Vector2, from: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = at
	e.relative = at - from
	Input.parse_input_event(e)


# Yapay dokunmalar: basınca hemen eylem (bırakmayı beklemez), kaydırma basılıyken atılır, bırakınca ek eylem yok.
func touch_test(m) -> void:
	var sz: Vector2 = m.get_viewport().get_visible_rect().size
	var mid := Vector2(sz.x * 0.5, sz.y * 0.5)
	match f:
		125: touch(mid, true)
		128:
			if m.ry <= 0.0:
				fail("orta dokunuş basınca zıplatmadı")
		130: touch(mid, false)
		135: touch(Vector2(sz.x * 0.1, 40.0), true)  # HUD paneli altında
		138:
			if m.lane != 0:
				fail("sol dokunuş basınca şeridi değiştirmedi (şerit %d)" % m.lane)
		140: touch(Vector2(sz.x * 0.1, 40.0), false)
		145: touch(Vector2(sz.x * 0.9, mid.y), true)
		148:
			if m.lane != 1:
				fail("sağ dokunuş basınca şeridi değiştirmedi (şerit %d)" % m.lane)
		150: touch(Vector2(sz.x * 0.9, mid.y), false)
		155:
			m.carrots = 3
			touch(Vector2(sz.x * 0.9, mid.y), true)  # sağ üçte birde basar, şerit 2'ye geçer; sonra aşağı kayar
		156: drag(Vector2(sz.x * 0.9, mid.y + sz.y * 0.3), Vector2(sz.x * 0.9, mid.y))
		158:
			if m.dash_t <= 0.0 or m.carrots != 0:
				fail("aşağı kaydırma basılıyken atılmadı (dash_t %.2f, havuç %d)" % [m.dash_t, m.carrots])
		160: touch(Vector2(sz.x * 0.9, mid.y + sz.y * 0.3), false)
		163:
			if m.lane != 2:
				fail("bırakma ek eylem yaptı (şerit %d)" % m.lane)


# Ses: ayar mantığı ekransızda da çalışır (oynatıcı yok, düğme ve kayıt var). Menüde düğme, oyunda M tuşu.
func ses_test(m) -> void:
	match f:
		12:
			if m.snd_btn == null or m.snd_btn.custom_minimum_size.y < 56.0 or m.snd_btn.custom_minimum_size.x < 56.0:
				fail("ses düğmesi yok ya da küçük")
			elif not m.snd_on or Secim.config().get_value("ayar", "ses", true) != true:
				fail("ses varsayılanı açık olmalı")
		14: m.snd_btn.pressed.emit()
		16:
			if m.snd_on or Secim.config().get_value("ayar", "ses", true) != false or m.snd_btn.text != "Ses: Kapalı":
				fail("menü düğmesi sesi kapatmadı")
		18: m.snd_btn.pressed.emit()
		20:
			if not m.snd_on or Secim.config().get_value("ayar", "ses", false) != true:
				fail("menü düğmesi sesi açmadı")
		22: key(KEY_M, true)  # menüde M isim kutusuna yazar, ses değişmez
		24:
			key(KEY_M, false)
			if not m.snd_on:
				fail("menüde M sesi değiştirdi")
		100: key(KEY_M, true)
		102: key(KEY_M, false)
		104:
			if m.snd_on or Secim.config().get_value("ayar", "ses", true) != false:
				fail("M tuşu sesi kapatmadı (durum %s)" % m.state)
		110: key(KEY_M, true)
		112: key(KEY_M, false)
		114:
			if not m.snd_on or Secim.config().get_value("ayar", "ses", false) != true:
				fail("M tuşu sesi açmadı")


# Duraksat: odak kaybı donurur, P devam ettirir, Esc/P değişir; donukken konum ve saat değişmez.
func duraklat_test(m) -> void:
	if f < 120:
		return
	match f:
		125: m.set_meta("z0", m.rabbit.position.z)
		126: m.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		128:
			if not m.paused or not m.pause_box.visible:
				fail("odak kaybı oyunu duraklatmadı (durum %s)" % m.state)
			m.set_meta("z1", m.rabbit.position.z)
			m.set_meta("c1", m.clock)
		160:
			if m.rabbit.position.z != m.get_meta("z1") or m.clock != m.get_meta("c1"):
				fail("duraklatılmışken oyun ilerledi")
			key(KEY_P, true)
		162: key(KEY_P, false)
		164:
			if m.paused or m.pause_box.visible:
				fail("P devam ettirmedi")
		200:
			if m.rabbit.position.z >= m.get_meta("z1") - 1.0:
				fail("devam edince koşu sürmedi")
			key(KEY_ESCAPE, true)
		202: key(KEY_ESCAPE, false)
		210:
			if not m.paused:
				fail("Esc koşuda duraklatmadı")
			m.open_settings()
		212:
			key(KEY_ESCAPE, true)  # ayar panelini kapatır, duraklatma sürer
		214:
			key(KEY_ESCAPE, false)
			if not m.paused or m.set_open:
				fail("Esc ayar panelini kapatmadı ya da oyunu sürdürdü")
		230: key(KEY_ENTER, true)  # herhangi tuş devam ettirir
		232:
			key(KEY_ENTER, false)
			if m.paused:
				fail("tuş devam ettirmedi")
			m.gap = m.GAP_MAX


# Ayar paneli: menüde açılır, anahtarlar ayar.cfg'ye yazılır, oyun başlayınca kapanır; sarsıntı kapalıyken sarsmaz, yavaş mod hızı çarpar.
func ayar_test(m) -> void:
	match f:
		12: m.set_btn.pressed.emit()
		14:
			if not m.set_panel.visible or m.set_btn.custom_minimum_size.y < 56.0 or m.set_btns.yavas.custom_minimum_size.y < 56.0:
				fail("ayar paneli açılmadı ya da düğmeler küçük")
			for k in ["titresim", "sarsinti", "yavas"]:
				m.set_btns[k].pressed.emit()
		16:
			var cf := Secim.config()
			if cf.get_value("ayar", "titresim", true) != false or cf.get_value("ayar", "sarsinti", true) != false or cf.get_value("ayar", "yavas", false) != true:
				fail("ayarlar ayar.cfg'ye yazılmadı")
			if m.speed_mult(m.slow_on) != 0.85:
				fail("yavaş mod hız çarpanı 0,85 değil")
		124:
			m.gap = m.GAP_MAX
			if m.pause_box.visible or m.state != "run":
				fail("oyun başlayınca ayar paneli kapanmadı (durum %s)" % m.state)
			m.hurt("deneme")
		125:
			if m.shake_t > 0.0 or m.hitstop_t <= 0.0 or m.flash.modulate.a <= 0.0:
				fail("sarsıntı kapalıyken sarsmamalı, duraksama ve flaş olmalı (sarsıntı %.2f)" % m.shake_t)
			m.set_btns.sarsinti.pressed.emit()
		140:
			m.gap = m.GAP_MAX
			m.hurt("deneme")
		141:
			if m.shake_t <= 0.0:
				fail("sarsıntı açıkken sarsmadı")
		150: write_cfg("")  # yavaş mod / titreşim kapalı kalmasın: sonraki senaryolar etkilenmesin


func click(at: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = at
		e.global_position = at
		e.pressed = down
		Input.parse_input_event(e)


func key(k: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = down
	Input.parse_input_event(e)


# Menüde dolabı aç, sırayla: Enter (en ucuz tavşan kıyafeti), Tab (Halil), Enter, Esc. Tuşlar gerçek girdi yolundan.
func dolap_test(m) -> void:
	match f:
		30: m.open_dolap()
		40: key(KEY_ENTER, true)
		50: key(KEY_TAB, true)
		60: key(KEY_ENTER, true)
		70: key(KEY_ESCAPE, true)
	if f in [42, 52, 62, 72]:
		for k in [KEY_ENTER, KEY_TAB, KEY_ESCAPE]:
			key(k, false)


func dolap_check(m) -> String:
	var st: Dictionary = Dolap.load_state(M.OUTFITS)
	if m.dolap_st != st:
		return "oyundaki dolap durumu kayıtla aynı değil"
	if not m.menu_node.visible or m.get_children().any(func(c): return c is Dolap):
		return "Esc dolabı kapatıp menüye dönmedi"
	match ad:
		"dolap_al":  # 100 → en ucuz tavşan + en ucuz Halil kıyafeti alınıp giyildi
			var t := String(ids_by_price("tavsan")[0])
			var h := String(ids_by_price("halil")[0])
			if st.alinan != [t, h] or st.havuc != 100 - M.OUTFITS[t].fiyat - M.OUTFITS[h].fiyat or Dolap.worn(st, "tavsan") != [t] or Dolap.worn(st, "halil") != [h]:
				return "alım/giyim yanlış: %s" % st
		"dolap_yetersiz":
			if st.havuc != 0 or not st.alinan.is_empty():
				return "para yokken alım oldu: %s" % st
		"bozuk_dolap_cfg":
			if st.havuc != Dolap.START_GIFT or st.alinan != ["t_tac"] or not Dolap.worn(st, "tavsan").is_empty() or not Dolap.worn(st, "halil").is_empty():
				return "bozuk kayıt temizlenmedi: %s" % st
	return ""


func ids_by_price(who: String) -> Array:
	var out := M.OUTFITS.keys().filter(func(id): return M.OUTFITS[id].kime == who)
	out.sort_custom(func(a, b): return M.OUTFITS[a].fiyat < M.OUTFITS[b].fiyat)
	return out


func check(m) -> bool:
	if ad in DOLAP_MENU:
		var why := dolap_check(m)
		if why != "":
			return fail(why)
	if ad == "kiyafetle_kos" and (Dolap.worn(m.dolap_st, "tavsan").size() < 2 or Dolap.worn(m.dolap_st, "halil").size() < 2):
		return fail("kıyafetler giyili değil")
	if ad in DOLAP_MENU or ad == "kiyafetle_kos":
		write_cfg("")  # sonraki senaryolar kıyafetsiz başlasın (ör. animasyon şapka eklemine bakıyor)
	var want := {dolap_al = "menu", dolap_yetersiz = "menu", bozuk_dolap_cfg = "menu", kiyafetle_kos = "run", menu = "menu", duraklat = "run", ayar_paneli = "run", kazan_sofra = "win", dokunma = "run", menu_enter = "run", ses = "run", kazan = "win", yakalan = "over", tekrar_enter = "run", esc_menu = "menu",
			animasyon = "run", carpma_ses = "run", isim_bos = "run", isim_uzun = "run", isim_turkce = "run", bolgeler = "run", fare_bos = "run", bozuk_cfg = "over", skor_bos = "over", skor_dolu = "over"}
	if not want.has(ad):
		return fail("bilinmeyen senaryo")
	var ok_states := [want[ad]] + (["over", "win"] if want[ad] == "run" else [])  # koşu 10 sn'de bitmiş olabilir
	if not m.state in ok_states:
		return fail("durum %s, beklenen %s" % [m.state, want[ad]])
	if ad in ["tekrar_enter", "esc_menu"] and not reloaded:
		return fail("bitiş paneline ulaşılamadı")
	var names := {isim_bos = m.M.RABBIT_SKINS[m.skin].ad, isim_uzun = "Çok-uzun-bir", isim_turkce = "Şeker Ğığİ"}
	if names.has(ad) and m.rabbit_name != names[ad]:
		return fail("isim '%s', beklenen '%s'" % [m.rabbit_name, names[ad]])
	if ad == "bolgeler" and not (saw_dog and saw_goose and m.prev_dist >= 520.0):
		return fail("bölgeler eksik: köpek %s, kaz %s, mesafe %d" % [saw_dog, saw_goose, m.prev_dist])
	if ad == "kazan_sofra" and (m.feast_bites < 1 or m.feast_piles_list.size() != m.feast_piles(m.carrots_total)):
		return fail("şölen yenmedi: ısırık %d, yığın %d" % [m.feast_bites, m.feast_piles_list.size()])
	if ad in ["kazan", "kazan_sofra", "yakalan", "skor_bos", "skor_dolu", "bozuk_cfg"] and Secim.load_scores().is_empty():
		return fail("skor kaydedilmedi")
	if ad == "skor_bos" and Secim.load_scores().size() != 1:
		return fail("boş tabloya tek kayıt eklenmeliydi")
	if ad == "skor_dolu" and (Secim.load_scores().size() != Secim.TOP or Secim.load_scores()[0].isim != "K0"):
		return fail("dolu tablo 5'te kesilmeli ve sıralı kalmalı")
	if ad == "animasyon":
		for j in ["halil_leg_l", "halil_arm_r", "halil_hat", "rabbit_hind", "rabbit_ears", "dog_front", "dog_tail"]:
			if not rng.has(j) or rng[j][1] - rng[j][0] < (0.05 if j == "halil_hat" else 0.2) or maxf(absf(rng[j][0]), absf(rng[j][1])) > Main.ANIM_MAX:
				return fail("eklem %s hareket etmedi ya da sınır dışı: %s" % [j, rng.get(j)])
	print("YOKLAMA mesh=%d düğüm=%d" % [count(root, true), count(root, false)])
	frame_ms.sort()
	print("KARE ms: ortanca %.2f, %%99 %.2f, en kötü %.2f (%d kare)" % [frame_ms[frame_ms.size() / 2], frame_ms[int(frame_ms.size() * 0.99)], frame_ms[-1], frame_ms.size()])
	print("SENARYO OK ", ad)
	quit(0)
	return true


func count(n: Node, meshes: bool) -> int:
	var c := 1 if (not meshes or n is MeshInstance3D) else 0
	for ch in n.get_children():
		c += count(ch, meshes)
	return c


# Animasyon: parça/mesh sayıları, eklemler gövdede ve yerinde, eklem açıları hareket eder ve sınırlı kalır (ekransız; görsel doğrulanmaz).
func anim_test(m) -> void:
	if f == 14:
		var kinds := {halil = [m.M.HALIL, m.M.RIG_HALIL], dog = [m.M.DOG, m.M.RIG_DOG], chicken = [m.M.CHICKEN, m.M.RIG_CHICKEN], goose = [m.M.GOOSE, m.M.RIG_GOOSE], rabbit = [m.M.RABBIT, m.M.RIG_RABBIT]}
		for k in kinds:
			var n: Node3D = m.model(kinds[k][0], Vector3(0, 0, 500), null, kinds[k][1])
			var joints: Dictionary = n.get_meta("rig", {})
			var meshes := count(n, true)
			print("  ", k, ": mesh ", meshes, ", eklem ", joints.size())
			if joints.size() != kinds[k][1].size() or meshes != joints.size() + 1 or meshes > 6:
				fail("%s: eklem %d, mesh %d (beklenen %d, <= 6)" % [k, joints.size(), meshes, kinds[k][1].size() + 1])
			for g in joints:
				if joints[g].get_parent() != m.body(n) or not joints[g].position.is_equal_approx(kinds[k][1][g][0]) or joints[g].get_child_count() != 1:
					fail("%s.%s eklemi gövdeye/yerine bağlı değil" % [k, g])
			n.queue_free()
	if f < 125 or m.state != "run":
		return
	var rec := {halil_leg_l = [m.halil, "leg_l"], halil_arm_r = [m.halil, "arm_r"], halil_hat = [m.halil, "hat"], rabbit_hind = [m.rabbit, "hind"], rabbit_ears = [m.rabbit, "ears"]}
	if not m.dog.is_empty():
		rec.dog_front = [m.dog.node, "front"]
		rec.dog_tail = [m.dog.node, "tail"]
	for j in rec:
		var r: Vector3 = rec[j][0].get_meta("rig")[rec[j][1]].rotation
		var v := r.y if j == "dog_tail" else (r.z if j == "halil_hat" else r.x)
		var e: Array = rng.get(j, [v, v])
		rng[j] = [minf(e[0], v), maxf(e[1], v)]


# Çarpma sesi: Dummy sürücüyle ses kurulur, dosyalar yüklenir, her engel türü kendi sesini çalar, eksik dosya sessizce atlanır.
func carpma_test(m) -> void:
	if f == 12:
		if m.snd_pool.size() != m.POOL or m.snd_bank.is_empty():
			fail("ses kurulmadı (oynatıcı %d)" % m.snd_pool.size())
		for k in m.HIT_SND.values():
			if not m.snd_bank.has(k):
				fail("ses bankasında %s yok" % k)
		var loaded := Ses.load_files()
		print("  dosyadan yüklenen: ", loaded.keys())
		if loaded.size() != Ses.FILES.size() or not loaded.values().all(func(s): return s is AudioStream):
			fail("ses dosyaları yüklenemedi: %d/%d" % [loaded.size(), Ses.FILES.size()])
		if not Ses.load_files({yok = "res://ses/yok.ogg"}).is_empty():
			fail("olmayan dosya sessizce atlanmadı")
	if f == end_frame - 20:
		m.release_audio()  # çıkıştan önce oynatıcılar bırakılır
		OS.delay_msec(500)  # kareler çok hızlı: ses iş parçacığı çalmaları bitirsin diye gerçek süre ver
	if f == 130 and m.state == "run":
		for what in m.HIT_SND:
			m.gap = m.GAP_MAX
			m.hurt("deneme", what)
			var pl = m.snd_pool[(m.snd_next + m.POOL - 1) % m.POOL]
			if pl.stream != m.snd_bank[m.HIT_SND[what]] or pl.volume_db >= -8.0:
				fail("%s yanlış sesi çaldı ya da seviyesi düşük değil" % what)
		m.gap = m.GAP_MAX
		m.hurt("deneme", "")
		if m.snd_pool[(m.snd_next + m.POOL - 1) % m.POOL].stream != m.snd_bank.bonk:
			fail("türsüz çarpma bonk çalmadı")


func fail(why: String) -> bool:
	print("SENARYO HATA: ", ad, ": ", why)
	quit(1)
	return false
