extends Node3D
# Küp prototip: tavşan 3 şeritte ileri koşar, Halil arkadan kovalar ve eşya fırlatır.

const LANES := [-2.0, 0.0, 2.0]
const GOAL := 600.0     # yuvaya mesafe (m)
const GAP_MAX := 10.0   # Halil'in ne kadar geride olabileceği
const HIT_COST := 4.0   # her çarpmada Halil'in yaklaştığı mesafe

const M := preload("res://modeller.gd")  # model verisi (Tasarımcı)
const THROWN := [["kova", M.METAL, Vector3(0.5, 0.5, 0.5), "y"], ["tırmık", M.WOOD, Vector3(0.12, 0.12, 1.3), "b"],
		["yumurta", M.EGG_WHITE, Vector3(0.3, 0.4, 0.3), "s"], ["lahana", M.CABBAGE_LIGHT, Vector3(0.55, 0.5, 0.55), "s"]]  # [ad, renk, boyut, şekil]; etki ada göre
const Secim := preload("res://secim.gd")
const Dolap := preload("res://dolap.gd")  # kıyafet dolabı ve havuç cüzdanı
const MENU_HALIL_CAM := Vector3(1.6, 0.7, -4.0)  # dolapta Halil önizlemesi, Halil'e göre (Tasarımcı ayarlar)
const MENU_HALIL_LOOK := Vector3(-1.6, 0.25, 0)  # Halil solda, dolap paneli sağda (ekransız ölçüm: örtüşme %0, boy %45)
const Ses := preload("res://ses.gd")  # kodla üretilen sesler

# Menü ve Bölüm 1 (PLAN-karakter-secimi.md, PLAN-bolum1.md)
const MENU_CAM := Vector3(1.9, 1.0, -3.0)  # menü kamerası, tavşana göre (Tasarımcı ayarlar)
const MENU_LOOK := Vector3(-1.5, 0.05, 0)  # tavşan ekranın solunda: panel ortada, liste sağda kalsın
const FARM_CHANCE := 0.3                    # her sırada yol kenarına bina çıkma olasılığı
# Tarayıcı (OpenGL/Compatibility): HDR yok, ışık aynı değerlerle patlıyor ve renkler solup parlıyor; ışığı kısıp efektleri kapatır.
const COMPAT_SUN := 0.3
const COMPAT_AMBIENT := 0.1
const COMPAT_LIGHT_SCALE := 0.3
const SWIPE_MIN := 60.0                    # kaydırma eşiği yedeği (px); gerçekte ekran yüksekliğinin %8'i, 40..90
const JUMP_BUFFER_TOUCH := 0.18            # telefonda parmak gecikmesi için daha cömert
const NEAR_TIME_TOUCH := 0.3
const COMPAT_SCALE_TOUCH := 0.65           # tarayıcı + dokunmatik: pil/ısınma (telefonda ölçülmedi)
const HINT_TIME := 3.0                     # ilk koşuda dokunma bölgesi ipucu süresi
const FARM_FREE_Z := 45.0                  # tavşan bu kadar ilerleyince menü çiftliği silinir (m)
const COMPAT_AHEAD := 60.0                 # tarayıcıda sıra ve dekor bu kadar ileriye kurulur (masaüstü 80)
const COMPAT_SHADOW_DIST := 28.0
const COMPAT_SCALE := 0.8                  # tarayıcıda 3B çizim çözünürlük ölçeği (arayüz tam çözünürlükte kalır)
const MENU_SPIN := 0.6                     # tavşanın menüde dönüşü (rad/sn)
const INTRO_GO := "KAÇ!"
const INTRO_CUES := {0.05: "HEY! Havuçlarım!", 1.3: INTRO_GO}  # Çabuk Giriş (PLAN-giris.md): ~2 sn, geri sayım yok
const INTRO_TIME := 1.9
const INTRO_X := -5.5          # tavşan yolun dışında, çimde başlar
const INTRO_DASH := Vector2(0.7, 1.3)  # yola koştuğu aralık (sn)
const INTRO_FACE := 2.4        # kemirirken yüzü kameraya doğru döner (rad)
const ZONES := [[0.0, "tarla"], [200.0, "kopek"], [350.0, "kumes"], [520.0, "son"]]  # [başlangıç m, bölge]
const EVENTS := {200.0: "Halil: Karabaş, tut şunu!", 350.0: "Kümes!", 520.0: "Yuva göründü!"}
const DOG_EVERY := Vector2(2.5, 4.5)  # köpek bölgesinde iki köpek arası (sn)
const DOG_START := 10.0    # köpek tavşanın bu kadar arkasından başlar (m)
const DOG_WARN := 1.2      # uyarıdan tavşana yetişmesine kadar (sn)
const GOOSE_CHANCE := 0.5  # kümes bölgesinde sıra başına kaz olasılığı
const GOOSE_X := 3.6       # kazlar yol kenarında durur, çarpmaz
const WIN_BONUS := 200
const END_LOCK := 0.6      # bitişte tuşlar bu kadar kilitli: zıplarken yakalanan oyuncu puanı görmeden geçmesin

# Yuvada şölen (PLAN-yuva-finali.md): kazanınca yuvaya girilir, ısırık = dokunma/tuş, işlem yoksa otomatik
const FEAST_POS := Vector3(300, 0, 0)  # yuva içi oda, yoldan uzakta
const FEAST_MAX := 10.0     # girişten panele en çok bu kadar sn
const FEAST_ENTER := 1.0    # yuvaya sıçrayış; sonunda ekran kararır ve oda açılır
const FEAST_EAT_AT := 1.4   # yeme başlangıcı
const FEAST_AUTO := 0.7     # dokunma yoksa otomatik ısırık aralığı
const FEAST_BITE_GAP := 0.12  # dokunma + emüle fare çift ısırık saymasın
const FEAST_BITES := 3      # bir yığın kaç ısırıkta biter
const FEAST_END_WAIT := 0.5 # "Mmm!" süresi (FEAST_MAX içinde)
const FEAST_BG := Color(0.3, 0.2, 0.14)  # odanın dışı: koyu toprak (gökyüzü görünmesin)
const SND_BTN := Vector2(150, 60)  # ses düğmesi (parmak hedefi >= 56 px)
const PAUSE_BTN := Vector2(64, 60)  # duraklat düğmesi, ses düğmesinin solunda (aynı üst sağ köşe bandı: dokunma bölgeleri aynı kalır)

# Kamera (PLAN-sonraki-tur A1): koşuda tavşana yakın ve alçak; açılış kamerası eski değerlerde kalır, koşuya geçerken yumuşakça kayar.
const CAM_BACK := 7.0                    # kamera tavşanın bu kadar arkasında (m)
const CAM_HEIGHT := 3.6                  # yerden yükseklik (m)
const CAM_LOOK := Vector3(0, 0.6, -9.0)  # bakılan nokta, tavşana göre
const CAM_FOV := 65.0
const CAM_INTRO_POS := Vector3(0, 6, 11)   # açılış: eski kamera (Halil kadrajda, tavşan yolun yanında)
const CAM_INTRO_LOOK := Vector3(0, 0, -8)
const THROW_FROM_Z := 3.0                # atış görsel olarak en çok tavşanın bu kadar arkasından başlar
const HALIL_SIDE := 1.7                  # Halil tavşanın yanında koşar: yaklaşınca tavşanı örtmesin
const CAM_BLEND := 0.8                   # açılıştan koşu kamerasına geçiş (sn)
# Vurulma geri bildirimi
const SHAKE_TIME := 0.25   # kamera sarsıntısı süresi (sn)
const SHAKE_AMP := 0.16    # en büyük sapma (m)
const FLASH_TIME := 0.2    # kırmızı kenar flaşı (sn)
const FLASH_ALPHA := 0.5
const HITSTOP := 0.05      # vurulunca oyun bu kadar donar (sn)
const SLOW_MULT := 0.85    # yavaş mod: yalnız koşu hızı çarpanı
const RESUME_GUARD := 6    # kare; devam eden dokunma/tuş oyuna eylem olarak geçmesin (ms)
const HIT_SND := {"çit": "hit_fence", "varil": "hit_barrel", "tavuk": "hit_chicken", "köpek": "hit_dog", "kova": "hit_bucket",
		"yumurta": "hit_egg", "lahana": "hit_cabbage", "tırmık": "hit_rake"}  # engel türü -> ses anahtarı (bilinmeyen: bonk)
const HIT_TRIM := -3.0     # çarpma sesleri efekt seviyesinin biraz altında
const ANIM_DIST := 35.0    # hayvan animasyonu yalnız bu kadar yakındakilerde çalışır (m)
const ANIM_MAX := 2.7      # hiçbir eklem bu açıyı (rad) aşmaz: test.gd
const POOL := 6  # eşzamanlı efekt oynatıcı sayısı (sabit)

static var go_menu := true  # sahne yenilense de korunur: bitişte Enter menüyü atlar, Esc menüye döner

# Animasyon miktarları (Tasarımcı ayarlar)
const JUMP_STRETCH := Vector3(0.9, 1.2, 0.9)   # kalkışta tavşanın ölçeği
const LAND_SQUASH := Vector3(1.15, 0.8, 1.15)  # inişte
const SQUASH_BACK := 10.0  # normale dönüş hızı
const BOB := 0.05          # koşarken gövde sallanması (m)
const BOB_SPEED := 14.0
const POP_TIME := 0.2      # nesne belirme ve havuç toplama süresi
const BLINK_TIME := 0.3    # vurulunca yanıp sönme

# Oynanış (PLAN-mekanikler.md)
const JUMP_VY := 7.0       # zıplama hızı (tepe ~1,2 m)
const GRAVITY := 20.0
const LANE_SPEED := 12.0   # şerit değiştirme hızı (m/s)
const ACCEL := 0.15        # koşu hızının artışı (m/s²)
const SPEED_MAX := 20.0
const GAP_REGEN := 0.5     # Halil'le mesafe saniyede bu kadar açılır
const CULL_BEHIND := 15.0  # tavşanın bu kadar arkasında kalan nesne silinir
const THROW_EVERY := Vector2(1.5, 3.5)  # iki atış arası (sn)
const THROW_RAMP := 0.6    # yuvaya varınca atış aralığı bu orana iner
const THROW_ARC := 4.0     # atışın yay yüksekliği (m)
const RAKE_AHEAD := 1.6    # tırmık, tavşanın 1 sn sonraki yerinin bu katı ileriye saplanır
const BOUNCE_AHEAD := 0.6  # ıskalanan yumurta/lahana hız × bu kadar ileri seker
const DOG_H := 0.6         # köpeğin üstünden atlanabilir (çit gibi)
const THROW_H := 0.5       # atılan eşyanın isabet yüksekliği: zıplayan tavşanı ıskalar
const MAX_DT := 1.0 / 30.0  # düşük FPS'te bir karede engelin içinden geçilmesin
const JUMP_BUFFER := 0.12  # inişten hemen önce basılan zıplama da sayılır
const DASH_COST := 3       # atılım kaç havuç harcar
const DASH_TIME := 2.0
const DASH_SPEED := 6.0    # atılımda geçici ek hız
const DASH_GAP := 2.5      # atılımda gap'e saniyede eklenen
const DASH_FOV := 8.0      # atılımda kamera açısı artışı (Tasarımcı ayarlar)
const NEAR_TIME := 0.25    # hedef şeridi bu kadar yeni terk ettiysen kıl payı
const NEAR_BONUS := 1.0
const ROLL_SPEED := 6.0    # lahananın tavşana doğru yuvarlanma hızı
const BLIND_TIME := 1.5    # kova kafadayken
const BLIND_COLOR := Color(0.42, 0.44, 0.5, 0.94)  # kova içi: koyu metal gri (Tasarımcı ayarlar)

# Grafik (PLAN-grafik.md, Tasarımcı ayarlar)
const TOON := preload("res://toon.gdshader")
const SWAY_COLORS := [M.TREE_DARK, M.TREE_LIGHT]  # rüzgarda sallanan taç ve çalılar
const CLOUD_PARALLAX := 0.92  # bulutlar tavşanın bu kadarıyla kayar: yavaşça geride kalırlar
const STAR_C := Color(1.0, 0.85, 0.3)

var lane := 1
var speed := 10.0
var ry := 0.0           # tavşanın yerden yüksekliği
var vy := 0.0
var gap := GAP_MAX
var carrots := 0
var state := "menu"     # menu → intro → run → over/win
var rabbit_name := ""
var skin := 0           # M.RABBIT_SKINS indeksi
var intro_t := 0.0
var prev_dist := 0.0
var carrots_total := 0  # atılımda harcananlar dahil; puan bundan hesaplanır
var dog := {}           # {node, warn, lane, rel}; boşsa köpek yok
var dog_t := 0.0
var hud_panel: Control
var next_row_z := -20.0
var throw_timer := 3.0
var msg := ""
var msg_t := 0.0
var blink_t := 0.0
var jump_t := 0.0       # zıplama tamponu
var last_free := 1      # önceki sıranın boş şeridi
var gap_shown := GAP_MAX  # Halil'in ekrandaki mesafesi; gap'e yumuşakça yaklaşır
var dash_t := 0.0
var halil_throw := 0.0  # 1: kol havada, 0'a iner
var focus_pause := true  # senaryo kapatır (pencere odağı oynak)
var clock := 0.0
var lane_left := -1     # en son terk edilen şerit (kıl payı için)
var lane_left_t := -9.0
var blind_t := 0.0
var bucket: Node3D
var blind_rect: Control
var dash_pips := []     # atılım göstergesindeki 3 havuç
var dash_hint: Label
var pop_label: Label    # "Kıl payı!" gibi büyük yazılar
var pop_tw: Tween
var dash_hinted := false
var shadow: Node3D      # tavşanın temas gölgesi
var run_dust: GPUParticles3D
var clouds: Node3D
var items := []   # {node, kind, h, ...}: kind deco/hit/chicken/carrot/goose/slick/roll; türe göre phase, home, lane
var throws := []  # {node, marker, from, to, t, item, lane, spd}

const SHAPE_FIX := {"c": Vector3(2, 1, 2), "t": Vector3(1, 10, 1)}  # mesh'i 1 birimlik kutuya oturtur
var meshes := {}
var fx_mats := {}  # parçacık malzemeleri [renk, alan, hız] anahtarıyla; her patlamada yeniden üretilmesin
var fx_mesh: SphereMesh
var mats := {}
var burst_pools := {}
var vmeshes := {}  # [şekil, renk] -> köşe rengi pişmiş mesh (model() birleştirmesi için)
var merged_mat: ShaderMaterial

var rabbit: Node3D
var halil: Node3D
var compat := RenderingServer.get_current_rendering_method() == "gl_compatibility"  # tarayıcı sürümü
var farm_nodes: Array[Node3D] = []  # menü çiftliği: koşuda geride kalınca silinir
var touch_from := {}   # parmak indeksi → dokunma başlangıcı (telefon)
var touch_done := {}   # parmak indeksi → bu dokunma kaydırma olarak harcandı mı
var touch := DisplayServer.is_touchscreen_available()  # ilk dokunuşta da true olur
var jump_buf := JUMP_BUFFER
var near_win := NEAR_TIME
var vibrate_on := true
static var hint_shown := false  # sahne yenilense de ipucu oturumda bir kez
var hint_box: Control
var end_text := ""
var feast_root: Node3D
var feast_t := 0.0
var feast_bites := 0
var feast_last := -9.0
var feast_swapped := false
var feast_done_t := -1.0   # >= 0: yeme bitti, "Mmm!" sayacı
var feast_idx := 0
var feast_piles_list := []  # {node, left}
var feast_goal := Vector3.ZERO
var feast_from := Vector3.ZERO  # giriş sıçrayışının başlangıcı (rabbit/cam)
var feast_cam_from := Vector3.ZERO
var feast_fade: ColorRect
var skip_btn: Button
var snd_on := true     # ayar.cfg [ayar] ses
var snd_btn: Button
var shake_on := true   # ayar.cfg [ayar] sarsinti
var slow_on := false   # ayar.cfg [ayar] yavas
var shake_t := 0.0
var hitstop_t := 0.0
var cam_mix := 0.0     # 0 açılış kamerası, 1 koşu kamerası
var flash: TextureRect
var paused := false
var set_open := false
var pause_btn: Button
var set_btn: Button
var pause_box: Control
var pause_panel: Control
var set_panel: Control
var set_btns := {}     # ad -> Button
var ignore_until := 0  # kare sayısı
var vis_cb  # JavaScriptObject; web: sekme gizlenince duraksat
var snd_bank := {}      # ad -> AudioStreamWAV (ekransızda boş)
var snd_pool: Array[AudioStreamPlayer] = []
var snd_next := 0
var music: AudioStreamPlayer
var scenery: Node3D  # zemin, yol ve tepeler: tavşanla birlikte kayar
var cam: Camera3D
var hud: Label
var dist_bar: ProgressBar
var gap_bar: ProgressBar
var gap_fill: StyleBoxFlat
var gap_label: Label
var msg_label: Label
var end_box: CenterContainer
var end_label: Label
var end_menu_btn: Button
var dolap_btn: Button
var dolap_st: Dictionary  # cüzdan + alınan/giyili kıyafetler (Dolap.load_state)
var menu_node: CanvasLayer

# Arayüz renkleri (Tasarımcı ayarlar)
const HUD_BG := Color(1.0, 0.97, 0.9, 0.82)
const HUD_TEXT := Color(0.33, 0.22, 0.14)
const HUD_BAR_BG := Color(0.33, 0.22, 0.14, 0.15)
const HUD_SAFE := Color(0.45, 0.72, 0.3)
const HUD_DANGER := Color(0.87, 0.3, 0.25)
const HUD_WARN := Color(0.96, 0.75, 0.25)


# ayar.cfg değeri bool değilse varsayılana düşer.
static var force_audio := false  # senaryo: ekransızda da (Dummy sürücüyle) ses kurulumunu sına


static func hit_snd(what: String) -> String:
	return HIT_SND.get(what, "bonk")


# Eklem dönüşleri (rad, Euler): x>0 sarkan uzvu ileri (-z) savurur. a: 0..1 ek durum (Halil fırlatıyor, tavuk ürküyor, kaz öter, tavşan havada).
static func anim_pose(kind: String, t: float, ph: float, a := 0.0) -> Dictionary:
	match kind:
		"halil":
			var w := t * 10.0 + ph
			return {leg_l = Vector3(sin(w) * 0.7, 0, 0), leg_r = Vector3(-sin(w) * 0.7, 0, 0), arm_l = Vector3(-sin(w) * 0.6, 0, 0),
					arm_r = Vector3(lerpf(sin(w) * 0.6, 2.6, a), 0, 0), hat = Vector3(sin(w * 2.0) * 0.06, 0, sin(w) * 0.05), body = Vector3(0, 0, sin(w) * 0.05)}
		"dog":
			var w := t * 16.0 + ph
			return {front = Vector3(sin(w) * 0.9, 0, 0), back = Vector3(sin(w + 0.9) * 0.9, 0, 0), tail = Vector3(0, sin(t * 20.0 + ph) * 0.7, 0),
					ears = Vector3(0.3 + sin(w) * 0.3, 0, 0), body = Vector3(sin(w) * 0.05, 0, 0)}
		"chicken":
			var w := t * 9.0 + ph
			var flap := a * (0.5 + 0.5 * sin(t * 30.0 + ph)) * 0.9
			return {leg_l = Vector3(sin(w) * (0.6 + a * 0.3), 0, 0), leg_r = Vector3(-sin(w) * (0.6 + a * 0.3), 0, 0),
					head = Vector3(-pow(maxf(sin(t * 2.6 + ph), 0.0), 6.0) * 0.8, 0, 0),
					wing_l = Vector3(0, 0, -(0.1 + flap)), wing_r = Vector3(0, 0, 0.1 + flap), body = Vector3(0, 0, sin(w) * 0.06)}
		"goose":
			var w := t * 2.0 + ph
			var flap := a * (0.6 + 0.6 * sin(t * 26.0 + ph))
			return {neck = Vector3(sin(w) * 0.1 - a * 0.4, 0, 0), wing_l = Vector3(0, 0, -(0.05 + flap)), wing_r = Vector3(0, 0, 0.05 + flap)}
		"rabbit":
			var w := t * BOB_SPEED + ph
			return {ears = Vector3(0.2 + sin(w) * 0.25 + a * 0.4, 0, 0), hind = Vector3(sin(w) * 0.6 - a * 0.5, 0, 0)}
	return {}


static func flag(v: Variant, def: bool) -> bool:
	return v if v is bool else def


# Yavaş modda yalnız koşu hızı çarpılır; çarpışma, puan ve sabitler aynı.
static func speed_mult(slow: bool) -> float:
	return SLOW_MULT if slow else 1.0


# Kamera sapması: sarsıntı süresi azaldıkça küçülür; kapalıysa ya da süre bittiyse sıfır.
static func shake_amount(left: float, on: bool) -> float:
	return SHAKE_AMP * clampf(left / SHAKE_TIME, 0.0, 1.0) if on else 0.0


# Tavşan (ayak noktası r) bir şeye çarptı mı? h: engelin yüksekliği, üstünden atlanabilir.
static func hits(r: Vector3, x: float, z: float, h: float) -> bool:
	return absf(r.x - x) < 0.8 and absf(r.z - z) < 0.6 and r.y < h


# Yeni sıranın boş şeridi öncekine en fazla 1 şerit uzak olsun, oyuncu hep yetişebilsin.
static func pick_free(last: int) -> int:
	return clampi(last + randi_range(-1, 1), 0, LANES.size() - 1)


static func can_dash(carrot_count: int, dash_left: float) -> bool:
	return carrot_count >= DASH_COST and dash_left <= 0.0


# Iskalanan atış kıl payı mı? Hedef şeridi az önce terk ettin ya da tam üstünden atladın.
static func near_miss(left_lane: int, left_age: float, target_lane: int, airborne_over: bool, window := NEAR_TIME) -> bool:
	return airborne_over or (left_lane == target_lane and left_age <= window)


# Yuvadaki sofra: toplanan havuç kadar yığın (4..12). Puan formülüne girmez, yalnız görsel bolluk.
static func feast_piles(carrots_total: int) -> int:
	return clampi(4 + carrots_total / 3, 4, 12)


# Dokunuşun eylemi: "dash" (aşağı kaydırma), "left" / "jump" / "right" (ekranın üç bölgesi).
static func touch_action(x: float, width: float, swipe := Vector2.ZERO, min_swipe := SWIPE_MIN) -> String:
	if swipe.y > min_swipe and swipe.y > absf(swipe.x):
		return "dash"
	return ["left", "jump", "right"][clampi(int(3.0 * x / maxf(width, 1.0)), 0, 2)]


# Kaydırma eşiği ekran yüksekliğine bağlı (yüksek DPI'da 60 px çok kolay, küçük ekranda zor).
static func swipe_min(height: float) -> float:
	return clampf(height * 0.08, 40.0, 90.0)


# Bir şeridin yoldaki komşu şeritleri.
static func near_lanes(l: int) -> Array:
	return [l - 1, l + 1].filter(func(o): return o >= 0 and o < LANES.size())


static func zone(dist: float) -> String:
	var z := "tarla"
	for e in ZONES:
		if dist >= e[0]:
			z = e[1]
	return z


# prev'den now'a geçerken aşılan işaretler (bir olay her eşikte bir kez çıksın).
static func crossed(marks: Array, prev: float, now: float) -> Array:
	return marks.filter(func(m): return prev < m and m <= now)


static func score(dist: float, carrot_total: int, won: bool) -> int:
	return int(dist) + carrot_total * 10 + (WIN_BONUS if won else 0)


# Her şekil 1 birimlik kutuya sığan tek bir paylaşılan mesh; parça boyutu scale olarak uygulanır.
# Şekiller: b kutu, s küre, c kapsül, y silindir, k koni (uç +y), t simit (xz düzleminde)
func shape_mesh(shape: String) -> Mesh:
	if not meshes.has(shape):
		var m: Mesh
		match shape:
			"s": m = SphereMesh.new()
			"c":
				m = CapsuleMesh.new()
				m.radius = 0.25  # height >= 2*radius şart; genişlik SHAPE_FIX ile 1'e çekilir
				m.height = 1.0
			"y", "k":
				m = CylinderMesh.new()
				m.height = 1.0
				if shape == "k":
					m.top_radius = 0.0
			"t":
				m = TorusMesh.new()
				m.inner_radius = 0.4
				m.outer_radius = 0.5
			_: m = BoxMesh.new()
		if compat:  # tarayıcı: varsayılan segmentler yüzlerce bin üçgen ediyor (küre 4224); düşük segment yeter
			match shape:
				"s":
					m.radial_segments = 16
					m.rings = 8
				"c":
					m.radial_segments = 12
					m.rings = 4
				"y", "k":
					m.radial_segments = 12
				"t":
					m.rings = 16
					m.ring_segments = 8
		meshes[shape] = m
	return meshes[shape]


func soft_mat(color: Color) -> Material:
	if not mats.has(color):
		if color.a >= 1.0:  # opak: iki bantlı toon shader
			var sm := ShaderMaterial.new()
			sm.shader = TOON
			sm.set_shader_parameter("albedo", color)
			sm.set_shader_parameter("sway", color in SWAY_COLORS)
			if compat:
				sm.set_shader_parameter("light_scale", COMPAT_LIGHT_SCALE)
			mats[color] = sm
		else:  # saydam (hedef diski, gölge): standart malzeme
			var mat := StandardMaterial3D.new()
			mat.albedo_color = color
			mat.roughness = 0.85
			mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
			mat.rim_enabled = true
			mat.rim = 0.3
			mat.rim_tint = 0.5
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mats[color] = mat
	return mats[color]


func box(size: Vector3, color: Color, pos: Vector3, parent: Node = null, shape := "b", rot := Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = shape_mesh(shape)
	m.material_override = soft_mat(color)
	m.position = pos
	m.rotation_degrees = rot
	m.scale = size * SHAPE_FIX.get(shape, Vector3.ONE)
	(parent if parent else self).add_child(m)
	return m


# model()'in sallanan ara düğümü (kök çarpışma noktası olduğu için hareket etmez).
func body(n: Node3D) -> Node3D:
	return n.get_child(0)


# Köşe renkli şekil kopyası (renk sRGB, shader doğrusala çevirir).
# Pozu eklem düğümlerine uygular (yeni düğüm yok). Rigsiz düğümde hiçbir şey yapmaz.
func apply_pose(n: Node3D, kind: String, t: float, ph: float, a := 0.0) -> void:
	var joints: Dictionary = n.get_meta("rig", {})
	if joints.is_empty():
		return
	var pose := anim_pose(kind, t, ph, a)
	for g in pose:
		if g == "body":
			body(n).rotation = pose[g]
		elif joints.has(g):  # kıyafet bir grubun bütün parçalarını gizlemiş olabilir (ör. hasır şapka)
			joints[g].rotation = pose[g]
	if kind == "halil" and joints.has("hat"):  # kıyafet şapkayı gizleyip eklem bırakmamış olabilir
		joints.hat.position.y = M.RIG_HALIL.hat[0].y + absf(sin(t * 10.0 + ph)) * 0.04  # şapka hafif zıplar


func color_mesh(shape: String, color: Color) -> Mesh:
	var key := [shape, color]
	if not vmeshes.has(key):
		var arr := shape_mesh(shape).surface_get_arrays(0)
		var cols := PackedColorArray()
		cols.resize(arr[Mesh.ARRAY_VERTEX].size())
		cols.fill(color)
		arr[Mesh.ARRAY_COLOR] = cols
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		vmeshes[key] = am
	return vmeshes[key]


# Parça: [boyut, renk, konum, şekil?, dönüş(derece)?]
# Opak ve sallanmayan parçalar tek mesh'e birleşir (çizim çağrısı); saydam ve rüzgarda sallanan parçalar ayrı kalır.
# rig (isteğe bağlı) = {grup: [eklem, [parça indeksleri]]}: grup kendi tek mesh'i ve eklem Node3D'si olur (root meta "rig": ad -> Node3D).
func model(parts: Array, pos: Vector3, parent: Node = null, rig := {}) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	(parent if parent else self).add_child(root)
	var body := Node3D.new()  # sallanma bunu oynatır; kök çarpışma noktası olduğu için yerinde kalır
	root.add_child(body)
	var st := SurfaceTool.new()
	var merged := 0
	var owner_of := {}  # parça indeksi -> grup adı
	var sts := {}       # grup adı -> SurfaceTool
	for g in rig:
		sts[g] = SurfaceTool.new()
		for i in rig[g][1]:
			owner_of[i] = g
	for idx in parts.size():
		var pt: Array = parts[idx]
		var shape: String = pt[3] if pt.size() > 3 else "b"
		var rot: Vector3 = pt[4] if pt.size() > 4 else Vector3.ZERO
		var color: Color = pt[1]
		if color.a < 1.0 or color in SWAY_COLORS:
			box(pt[0], color, pt[2], body, shape, rot)
			continue
		var basis := Basis.from_euler(rot * (PI / 180.0), EULER_ORDER_YXZ) * Basis.from_scale(pt[0] * SHAPE_FIX.get(shape, Vector3.ONE))
		var g: String = owner_of.get(idx, "")
		if g != "":
			sts[g].append_from(color_mesh(shape, color), 0, Transform3D(basis, pt[2] - rig[g][0]))
		else:
			st.append_from(color_mesh(shape, color), 0, Transform3D(basis, pt[2]))
			merged += 1
	if merged > 0:
		if not merged_mat:
			merged_mat = ShaderMaterial.new()
			merged_mat.shader = TOON
			merged_mat.set_shader_parameter("vcol", true)
			merged_mat.set_shader_parameter("vcol_srgb", not compat)
			if compat:
				merged_mat.set_shader_parameter("light_scale", COMPAT_LIGHT_SCALE)
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = merged_mat
		body.add_child(mi)
	if not rig.is_empty():
		var joints := {}
		for g in rig:
			var j := Node3D.new()  # eklem: dönüş buradan, mesh eklem merkezine göre
			j.position = rig[g][0]
			body.add_child(j)
			var gm := MeshInstance3D.new()
			gm.mesh = sts[g].commit()
			gm.material_override = merged_mat
			j.add_child(gm)
			joints[g] = j
		root.set_meta("rig", joints)
	return root


# Telefon ayarları (ayar.cfg [ayar] bölümü: titresim = true/false, ses = true/false, fps = 30/60). Okuma hatası varsayılana düşer.
func load_settings() -> void:
	var cf := Secim.config()
	vibrate_on = flag(cf.get_value("ayar", "titresim", true), true)
	shake_on = flag(cf.get_value("ayar", "sarsinti", true), true)
	slow_on = flag(cf.get_value("ayar", "yavas", false), false)
	snd_on = Ses.parse_on(cf.get_value("ayar", "ses", true))
	var fps = cf.get_value("ayar", "fps", 0)
	if fps is int and fps in [30, 60]:
		Engine.max_fps = fps


# Parmak gecikmesi masaüstü tuşundan fazla: telefonda tampon ve kıl payı penceresi biraz cömert (masaüstü sayıları aynı).
func apply_touch() -> void:
	touch = true
	jump_buf = JUMP_BUFFER_TOUCH
	near_win = NEAR_TIME_TOUCH


func _ready() -> void:
	load_settings()
	if touch:
		apply_touch()
	var horizon := Color(1.0, 0.72, 0.48)
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.42, 0.55, 0.85)
	sky_mat.sky_horizon_color = horizon
	sky_mat.ground_horizon_color = horizon
	sky_mat.ground_bottom_color = Color(0.4, 0.55, 0.3)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = COMPAT_AMBIENT if compat else 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC  # AgX sahneyi soluk gösterdi
	env.glow_enabled = not compat
	env.glow_intensity = 0.3
	env.fog_enabled = true
	env.fog_light_color = horizon
	env.fog_density = 0.007
	env.fog_sky_affect = 0.15 # varsayılan 1.0 gökyüzünü tamamen sise boğuyor
	env.ssao_enabled = not compat
	env.adjustment_enabled = not compat  # FILMIC'in soldurduğu rengi geri getir
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.05
	get_viewport().msaa_3d = Viewport.MSAA_2X if compat else Viewport.MSAA_4X
	if compat:
		get_viewport().scaling_3d_scale = COMPAT_SCALE_TOUCH if touch else COMPAT_SCALE
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-25, -40, 0)
	sun.light_color = Color(1.0, 0.85, 0.68)
	sun.light_energy = COMPAT_SUN if compat else 1.2
	sun.light_angular_distance = 2.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = COMPAT_SHADOW_DIST if compat else 40.0  # gölge çözünürlüğü kameranın yakınında toplansın
	if compat:
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL  # tek bölme: gölge geçişi 4 kez çizilmesin
		RenderingServer.directional_shadow_atlas_set_size(2048, false)
	add_child(sun)

	burst_pool(STAR_C, 10, Vector2(1.0, 2.5))  # patlama havuzu önceden hazır (ilk vuruşta düğüm/gölgelendirici üretimi takılmasın)
	burst_pool(M.DUST_C, 8, Vector2(0.8, 1.6))
	burst_pool(M.CARROT_C, 12, Vector2(1.0, 2.5))
	make_world()
	var choice := Secim.load_choice()
	dolap_st = Dolap.load_state(M.OUTFITS)
	make_rabbit(choice.skin)
	rabbit_name = Secim.clean_name(choice.isim, M.RABBIT_SKINS[choice.skin].ad)
	make_halil()
	cam = Camera3D.new()
	var cam_fx := CameraAttributesPractical.new()  # minyatür oyuncak dünya: uzak tepeler hafif bulanık
	cam_fx.dof_blur_far_enabled = true
	cam_fx.dof_blur_far_distance = 40.0
	cam_fx.dof_blur_amount = 0.05
	cam.attributes = cam_fx
	add_child(cam)

	make_hud()
	make_audio()
	if OS.has_feature("web"):  # sekme gizlenince duraksat (odak bildirimi tarayıcıda her zaman gelmeyebilir)
		vis_cb = JavaScriptBridge.create_callback(func(_a): if JavaScriptBridge.eval("document.hidden"): pause_game())
		JavaScriptBridge.get_interface("document").addEventListener("visibilitychange", vis_cb)

	model(M.FENCE, Vector3(-3.4, 0.3, 0.6)).rotation.y = 0.5  # başlangıç süsü (menü + açılış): yol kenarında çit ve havuç yığını
	model(M.BURROW.slice(2), Vector3(-0.9, 0, -1.5))
	if go_menu:
		hud_panel.visible = false
		cam.position = rabbit.position + MENU_CAM
		cam.look_at(rabbit.position + MENU_LOOK)
		var menu := Secim.new()
		menu_node = menu
		add_child(menu)
		var t := ui_theme()
		for c in menu.get_children():
			c.theme = t
		menu.renk.connect(make_rabbit)
		menu.renk.connect(func(_s): play("click"))
		menu.basla.connect(on_start)
		menu.basla.connect(func(_n): play("click"))
		place_snd(true)
	else:
		on_start(rabbit_name)


# Zemin, çiftlik, bulutlar, yuva, kümes ve tabelalar.
func make_world() -> void:
	scenery = model(M.GROUND, Vector3.ZERO)
	for f in M.FARM_SET:  # menünün arkası ve kenarları çiftlik
		var fm := model(f[0], f[1])
		farm_nodes.append(fm)  # scenery'nin çocuğu değil: o tavşanla kayar, evler sabit kalmalı
		fm.rotation_degrees.y = f[2]
		fm.scale = Vector3.ONE * f[3]
	clouds = Node3D.new()
	add_child(clouds)
	for c in [Vector3(-30, 28, -90), Vector3(18, 34, -130), Vector3(42, 26, -70), Vector3(-12, 38, -170), Vector3(-48, 30, -140)]:
		model(M.CLOUD, c, clouds)
	for mi in clouds.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # gökteki bulut gölge atlasını boşuna doldurmasın
	shadow = model(M.SHADOW_BLOB, Vector3(0, 0.02, 0))
	model(M.BURROW, Vector3(0, 0, -GOAL - 2))
	model(M.COOP, Vector3(-6.5, 0, -ZONES[2][0] - 4))  # kümes bölgesinin başında, yol kenarında
	for k in EVENTS:
		model(M.SIGN, Vector3(4.2, 0, -k))  # bölge tabelası


# HUD, bitiş paneli, kova karartması ve ortadaki yazı.
func make_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2  # menü (katman 1) ve ayar paneli üst üste gelince panel üstte kalsın
	add_child(layer)
	hud_panel = PanelContainer.new()
	hud_panel.position = Vector2(16, 16)
	hud_panel.add_theme_stylebox_override("panel", rounded(HUD_BG, 16))
	layer.add_child(hud_panel)
	var col := VBoxContainer.new()
	hud_panel.add_child(col)
	hud = hud_label(col, 24)
	var dash_row := HBoxContainer.new()  # atılım göstergesi: 3 havuç dolunca "↓ ATIL"
	dash_row.add_theme_constant_override("separation", 6)
	col.add_child(dash_row)
	hud_label(dash_row, 18).text = "Atılım"
	for i in DASH_COST:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(14, 24)
		pip.add_theme_stylebox_override("panel", rounded(M.CARROT_C, 7))
		dash_row.add_child(pip)
		dash_pips.append(pip)
	dash_hint = hud_label(dash_row, 18)
	dash_hint.text = "  ↓ ATIL"
	dash_hint.add_theme_color_override("font_color", HUD_DANGER)
	dist_bar = hud_bar(col, M.CARROT_C)
	gap_label = hud_label(col, 18)
	gap_bar = hud_bar(col, HUD_SAFE)
	gap_fill = gap_bar.get_theme_stylebox("fill")
	gap_fill.border_color = HUD_TEXT
	msg_label = hud_label(col, 20)
	end_box = CenterContainer.new()
	end_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_box.visible = false
	layer.add_child(end_box)
	var end_panel := PanelContainer.new()
	end_panel.add_theme_stylebox_override("panel", rounded(HUD_BG, 24))
	end_box.add_child(end_panel)
	var end_col := VBoxContainer.new()
	end_panel.add_child(end_col)
	end_label = hud_label(end_col, 28)  # tablo da sığsın
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_menu_btn = ui_button("Menü", Vector2(200, 60), to_menu, 28)  # telefonda Esc yok
	end_menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	end_col.add_child(end_menu_btn)
	blind_rect = Panel.new()  # kova karartması: ekranın üst yarısı, alt kenarı kova ağzı gibi yay
	var bsb := rounded(BLIND_COLOR, 0)
	bsb.corner_radius_bottom_left = 600
	bsb.corner_radius_bottom_right = 600
	bsb.border_width_bottom = 14
	bsb.border_color = M.METAL
	blind_rect.add_theme_stylebox_override("panel", bsb)
	blind_rect.set_anchors_preset(Control.PRESET_TOP_WIDE)
	blind_rect.anchor_bottom = 0.55
	blind_rect.visible = false
	layer.add_child(blind_rect)
	layer.move_child(blind_rect, 0)  # HUD panelinin altında kalsın
	pop_label = Label.new()  # "Kıl payı!" ve ilk ipucu: büyük, eğik, ortada
	pop_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	pop_label.offset_top = 170
	pop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pop_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # uzun mesaj dar telefon ekranında taşmasın
	pop_label.add_theme_font_size_override("font_size", 56)
	pop_label.add_theme_color_override("font_outline_color", HUD_TEXT)
	pop_label.add_theme_constant_override("outline_size", 12)
	pop_label.rotation_degrees = -6
	pop_label.modulate.a = 0.0
	layer.add_child(pop_label)
	hint_box = HBoxContainer.new()  # ilk koşuda dokunma bölgeleri (soluk)
	hint_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_box.add_theme_constant_override("separation", 0)
	hint_box.modulate.a = 0.0
	for t in ["◀", "▲\nZIPLA", "▶"]:
		var cell := Label.new()
		cell.text = t
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell.add_theme_font_size_override("font_size", 64)
		cell.add_theme_color_override("font_color", Color.WHITE)
		cell.add_theme_color_override("font_outline_color", HUD_TEXT)
		cell.add_theme_constant_override("outline_size", 10)
		hint_box.add_child(cell)
	layer.add_child(hint_box)
	feast_fade = ColorRect.new()  # yuvaya girerken kararma
	feast_fade.color = Color(0.08, 0.05, 0.03, 0.0)
	feast_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	feast_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feast_fade.visible = false
	layer.add_child(feast_fade)
	skip_btn = Button.new()  # sağ altta büyük "Geç" (parmak hedefi >= 56 px)
	skip_btn.text = "Geç ▶"
	skip_btn.theme = ui_theme()
	skip_btn.add_theme_font_size_override("font_size", 32)
	skip_btn.focus_mode = Control.FOCUS_NONE  # Enter/Space odaklı düğmeyi basmasın
	skip_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	skip_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_btn.offset_left = -200
	skip_btn.offset_top = -96
	skip_btn.offset_right = -24
	skip_btn.offset_bottom = -24
	skip_btn.visible = false
	skip_btn.pressed.connect(feast_finish)
	layer.add_child(skip_btn)
	snd_btn = Button.new()  # ses aç/kapat: menüde sağ altta, oyunda sağ üstte (telefonda büyük hedef)
	snd_btn.theme = ui_theme()
	snd_btn.add_theme_font_size_override("font_size", 24)
	snd_btn.focus_mode = Control.FOCUS_NONE  # menüde odak isim kutusunda kalsın
	snd_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	snd_btn.custom_minimum_size = SND_BTN
	snd_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	snd_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	snd_btn.pressed.connect(toggle_snd)
	layer.add_child(snd_btn)
	make_pause_ui(layer)
	snd_label()
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # HUD dokunmayı yutmasın: telefonda sol üst bölge de oyuna gitsin
	for c in hud_panel.find_children("*", "Control", true, false):
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		release_audio()
	if focus_pause and (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT):
		pause_game()  # telefonda uygulama arka plana gidince / masaüstünde pencere odağı kaybolunca


func pause_game() -> void:
	if paused or not (state == "intro" or state == "run"):
		return
	paused = true
	set_open = false
	pause_box.visible = true
	pause_panel.visible = true
	set_panel.visible = false
	if music:
		music.stream_paused = true


func resume_game() -> void:
	if not paused:
		return
	paused = false
	set_open = false
	pause_box.visible = false
	ignore_until = Engine.get_process_frames() + RESUME_GUARD  # devam ettiren dokunuş/tuş oyuna eylem olarak geçmesin
	if music:
		music.stream_paused = false


func open_settings() -> void:
	set_open = true
	pause_box.visible = true
	pause_panel.visible = false
	set_panel.visible = true


func close_settings() -> void:
	set_open = false
	set_panel.visible = false
	pause_panel.visible = paused
	pause_box.visible = paused


func close_panels() -> void:  # oyun başlarken menüden açık kalan ayar paneli
	paused = false
	set_open = false
	pause_box.visible = false


func toggle_setting(key: String) -> void:
	match key:
		"ses": toggle_snd()
		"titresim":
			vibrate_on = not vibrate_on
			Secim.save("ayar", {titresim = vibrate_on})
		"sarsinti":
			shake_on = not shake_on
			Secim.save("ayar", {sarsinti = shake_on})
		"yavas":
			slow_on = not slow_on
			Secim.save("ayar", {yavas = slow_on})
	set_labels()
	play("click")


func set_labels() -> void:
	snd_label()
	var on := {ses = snd_on, titresim = vibrate_on, sarsinti = shake_on, yavas = slow_on}
	var names := {ses = "Ses", titresim = "Titreşim", sarsinti = "Sarsıntı", yavas = "Yavaş mod"}
	for k in set_btns:
		set_btns[k].text = "%s: %s" % [names[k], "Açık" if on[k] else "Kapalı"]


func ui_button(text: String, size: Vector2, on_press: Callable, font := 24) -> Button:
	var b := Button.new()
	b.text = text
	b.theme = ui_theme()
	b.add_theme_font_size_override("font_size", font)
	b.focus_mode = Control.FOCUS_NONE
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.custom_minimum_size = size
	b.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	b.grow_vertical = Control.GROW_DIRECTION_BEGIN
	b.pressed.connect(on_press)
	return b


# Vurulma flaşı, duraklat düğmesi, duraklat ekranı ve ayar paneli.
func make_pause_ui(layer: CanvasLayer) -> void:
	var g := Gradient.new()  # kenarlara doğru koyulaşan kırmızı, orta saydam
	g.offsets = PackedFloat32Array([0.7, 1.0])
	g.colors = PackedColorArray([Color(0.9, 0.1, 0.1, 0.0), Color(0.9, 0.1, 0.1, FLASH_ALPHA)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	flash = TextureRect.new()
	flash.texture = gt
	flash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flash.stretch_mode = TextureRect.STRETCH_SCALE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.modulate.a = 0.0
	layer.add_child(flash)
	pause_btn = ui_button("II", PAUSE_BTN, pause_game, 28)
	pause_btn.visible = false
	layer.add_child(pause_btn)
	set_btn = ui_button("Ayarlar", SND_BTN, open_settings)
	set_btn.visible = false
	layer.add_child(set_btn)
	dolap_btn = ui_button("Dolap", SND_BTN, open_dolap)
	dolap_btn.visible = false
	layer.add_child(dolap_btn)
	pause_box = Control.new()
	pause_box.theme = ui_theme()
	pause_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_box.visible = false
	pause_box.gui_input.connect(func(ev): if paused and not set_open and ev is InputEventMouseButton and ev.pressed: resume_game())
	layer.add_child(pause_box)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_box.add_child(dim)
	pause_panel = centered(pause_box)
	var pcol := pause_panel.get_child(0).get_child(0)
	var title := hud_label(pcol, 32)
	title.text = "Duraklatıldı\nDevam için dokun / tuşa bas"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var prow := HBoxContainer.new()
	prow.alignment = BoxContainer.ALIGNMENT_CENTER
	prow.add_child(ui_button("Devam", Vector2(180, 60), resume_game, 28))
	prow.add_child(ui_button("Ayarlar", Vector2(180, 60), open_settings, 28))
	prow.add_child(ui_button("Menü", Vector2(180, 60), to_menu, 28))
	pcol.add_child(prow)
	set_panel = centered(pause_box)
	set_panel.visible = false
	var scol := set_panel.get_child(0).get_child(0)
	hud_label(scol, 28).text = "Ayarlar"
	var how := hud_label(scol, 16)  # "Nasıl oynanır": menüden buraya taşındı (PLAN-giris)
	how.text = Secim.HELP_TEXT
	var grid := GridContainer.new()
	grid.columns = 2
	scol.add_child(grid)
	for k in ["ses", "titresim", "sarsinti", "yavas"]:
		var b := ui_button("", Vector2(250, 60), toggle_setting.bind(k))
		set_btns[k] = b
		grid.add_child(b)
	scol.add_child(ui_button("Kapat", Vector2(250, 60), close_settings, 28))
	set_labels()


# Ortalanmış panel + dikey kutu; dokunmayı arkasına geçirir (arka plan "devam" dokunuşunu alsın).
func centered(parent: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	pc.add_child(VBoxContainer.new())
	return c


# Menünün görünümü: HUD ile aynı yuvarlak krem paneller, turuncu düğme.
func ui_theme() -> Theme:
	var t := Theme.new()
	t.set_stylebox("panel", "PanelContainer", rounded(HUD_BG, 16))
	t.set_color("font_color", "Label", HUD_TEXT)
	t.set_font_size("font_size", "Label", 22)
	t.set_stylebox("normal", "LineEdit", rounded(Color(1, 1, 1, 0.9), 10))
	t.set_stylebox("focus", "LineEdit", StyleBoxEmpty.new())
	t.set_color("font_color", "LineEdit", HUD_TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Color(HUD_TEXT, 0.45))
	t.set_color("caret_color", "LineEdit", HUD_TEXT)
	t.set_font_size("font_size", "LineEdit", 24)
	for st in ["normal", "hover", "pressed"]:
		t.set_stylebox(st, "Button", rounded(M.CARROT_C.lightened(0.15 if st == "hover" else 0.0).darkened(0.15 if st == "pressed" else 0.0), 12))
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_font_size("font_size", "Button", 24)
	return t


# Tavşanı seçilen renkle kurar; menüde renk değişince eskisinin yerine geçer.
func make_rabbit(s: int) -> void:
	var turn := 0.0
	if rabbit:
		turn = rabbit.rotation.y
		rabbit.free()
	skin = s
	var dressed := Dolap.dress(Secim.skin_parts(M.RABBIT, M.RABBIT_SKINS[s]), M.RIG_RABBIT, Dolap.worn(dolap_st, "tavsan"), M.OUTFITS)
	rabbit = model(dressed[0], Vector3(0, 0.3, 0), null, dressed[1])
	rabbit.rotation.y = turn
	bucket = model(M.BUCKET_HAT, Vector3.ZERO, body(rabbit))  # body altında: sallanmayla oynar
	bucket.visible = false
	run_dust = particles(M.DUST_C, 24, 0.5, Vector3(0.2, 0.02, 0.1), Vector2(0.3, 0.9), false)
	run_dust.position = Vector3(0, -0.28, 0.3)
	rabbit.add_child(run_dust)


# Halil'i giyili kıyafetleriyle kurar; dolapta değişince eskisinin yerine geçer (yeri ve dönüşü korunur).
func make_halil() -> void:
	var at := Vector3(0, 1, 7)
	if halil:
		at = halil.position
		halil.free()
	var dressed := Dolap.dress(M.HALIL, M.RIG_HALIL, Dolap.worn(dolap_st, "halil"), M.OUTFITS)
	halil = model(dressed[0], at, null, dressed[1])
	model(M.SHADOW_BLOB, Vector3(0, -0.98, 0), halil).scale = Vector3.ONE * 1.3


func open_dolap() -> void:
	play("click")
	menu_node.visible = false
	menu_node.set_process_input(false)  # menünün Enter/↑↓ kısayolları dolapta çalışmasın
	dolap_btn.visible = false
	var d := Dolap.new()
	add_child(d)
	d.setup(dolap_st, M.OUTFITS, ui_theme())
	d.changed.connect(func(who):
		dolap_st = d.st
		if who == "tavsan":
			make_rabbit(skin)
		else:
			make_halil()
		menu_cam(who))
	d.closed.connect(func():
		dolap_st = d.st
		menu_node.visible = true
		menu_node.set_process_input(true)
		menu_node.name_box.grab_focus()  # gizlenince kaybolan odak geri gelsin, isim yazılabilsin
		dolap_btn.visible = true
		menu_cam("tavsan"))


func menu_cam(who: String) -> void:
	var target := halil if who == "halil" else rabbit
	cam.position = target.position + (MENU_HALIL_CAM if who == "halil" else MENU_CAM)
	cam.look_at(target.position + (MENU_HALIL_LOOK if who == "halil" else MENU_LOOK))


func to_menu() -> void:
	go_menu = true
	get_tree().reload_current_scene()


func on_start(isim: String) -> void:
	rabbit_name = isim
	rabbit.position.x = INTRO_X
	rabbit.rotation.y = INTRO_FACE
	hud_panel.visible = true
	place_snd(false)
	dolap_btn.visible = false
	follow_cam(0.0)
	close_panels()
	state = "intro"
	update_hud(0.0)  # açılışta önceki/varsayılan değerler görünmesin
	if not go_menu:  # tekrar koşu (bitişte Enter/dokunma): açılış oynamaz, kovalama kamerasıyla hemen başlar
		cam_mix = 1.0
		follow_cam(0.0)
		begin_run()


func begin_run() -> void:
	body(rabbit).rotation.x = 0.0
	rabbit.position = Vector3(LANES[1], 0.3, 0.0)  # açılış atlansa da yolda başlar
	rabbit.rotation.y = 0.0
	halil.position.y = 1.0
	state = "run"
	show_hint()


func follow_cam(z: float) -> void:
	var pos := CAM_INTRO_POS.lerp(Vector3(0, CAM_HEIGHT, CAM_BACK), cam_mix)
	var look := CAM_INTRO_LOOK.lerp(CAM_LOOK, cam_mix)
	var a := shake_amount(shake_t, shake_on)
	if a > 0.0:
		pos += Vector3(randf_range(-a, a), randf_range(-a, a), 0)
	cam.position = pos + Vector3(0, 0, z)
	cam.look_at(look + Vector3(0, 0, z))


func fill_rows(z: float) -> void:
	while next_row_z > z - (COMPAT_AHEAD if compat else 80.0) and next_row_z > -GOAL + 10:
		spawn_row(next_row_z)
		next_row_z -= randf_range(9.0, 15.0)


# Açılışta herhangi bir tuş ya da tıklama açılışı atlar. Bitişte Enter tekrar koşturur, Esc menüye döner
# (Space yok; Enter da zıplattığı için bitişte END_LOCK kadar kilit var, bkz. finish()).
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch and not touch:
		apply_touch()  # masaüstü sanılan ama dokunmatik cihaz
	if Engine.get_process_frames() < ignore_until:
		return
	var toggle: bool = (e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_P, KEY_ESCAPE]) or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_START)
	if toggle and (set_open or paused or state == "intro" or state == "run"):  # Esc bitişte/şölende eskisi gibi (menü / Geç)
		if set_open:
			close_settings()
		elif paused:
			resume_game()
		else:
			pause_game()
		return
	if set_open or paused:
		if paused and not set_open and (e is InputEventKey or e is InputEventJoypadButton) and e.is_pressed() and not e.is_echo():
			resume_game()  # dokunma/fare devamı pause_box'tan gelir
		return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_M and state != "menu":  # menüde isim kutusuna "m" yazılır: orada yalnız düğme
		toggle_snd()
		return
	if state == "feast":
		feast_input(e)
		return
	if state == "run" and (e is InputEventScreenTouch or e is InputEventScreenDrag):
		touch_run(e)
		return
	if not e.is_pressed() or e.is_echo():
		return
	if state == "intro" and (e is InputEventKey or e is InputEventScreenTouch or e is InputEventJoypadButton or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT)):
		if intro_t < INTRO_CUES.find_key(INTRO_GO):
			pop(INTRO_GO, HUD_WARN)  # atlanınca da görünsün (henüz çıkmadıysa)
		intro_t = INTRO_TIME
	elif state == "over" or state == "win":
		var again: bool = (e is InputEventKey and e.keycode in [KEY_ENTER, KEY_KP_ENTER]) or (e is InputEventJoypadButton and e.button_index == JOY_BUTTON_A) \
				or (e is InputEventScreenTouch and not end_menu_btn.get_global_rect().has_point(e.position))  # Menü düğmesine dokunuş tekrar koşturmasın
		var menu: bool = (e is InputEventKey and e.keycode == KEY_ESCAPE) or (e is InputEventJoypadButton and e.button_index == JOY_BUTTON_B)
		if again or menu:
			go_menu = menu
			get_tree().reload_current_scene()


# Telefon: basınca hemen eylem (sol/orta/sağ üçte bir = sola / zıpla / sağa). Aşağı kaydırma parmak basılıyken eşiği geçince atılır
# ve o dokunma bir daha eylem yapmaz. Bedeli: kaydırma bir bölgede başlarsa o bölgenin eylemi basma anında zaten olmuştur.
func touch_run(e: InputEvent) -> void:
	var size := get_viewport().get_visible_rect().size
	if e is InputEventScreenTouch:
		if e.pressed:
			touch_from[e.index] = e.position
			touch_done[e.index] = false
			match touch_action(e.position.x, size.x):
				"left": set_lane(maxi(lane - 1, 0))
				"jump": jump_t = jump_buf
				_: set_lane(mini(lane + 1, LANES.size() - 1))
		else:
			touch_from.erase(e.index)
			touch_done.erase(e.index)
	elif touch_from.has(e.index) and touch_done.get(e.index) == false \
			and touch_action(e.position.x, size.x, e.position - touch_from[e.index], swipe_min(size.y)) == "dash":
		touch_done[e.index] = true
		try_dash()


func vibrate(ms: int) -> void:
	if vibrate_on and touch and OS.has_feature("web"):
		JavaScriptBridge.eval("try{navigator.vibrate&&navigator.vibrate(%d)}catch(e){}" % ms)  # iOS'ta yok: sessiz geçer


# Dokunmatik cihazda ilk koşuda üç bölge 3 sn soluk görünür (ayar.cfg [ayar] ipucu_hep = true ile her koşuda).
func show_hint() -> void:
	if not touch or (hint_shown and Secim.config().get_value("ayar", "ipucu_hep", false) != true):
		return
	hint_shown = true
	var tw := hint_box.create_tween()
	tw.tween_property(hint_box, "modulate:a", 0.3, 0.3)
	tw.tween_interval(HINT_TIME)
	tw.tween_property(hint_box, "modulate:a", 0.0, 0.5)


func try_dash() -> void:
	if can_dash(carrots, dash_t):
		carrots -= DASH_COST
		dash_t = DASH_TIME
		say("Atıl!")
		play("dash")
		vibrate(40)


func pop(text: String, color: Color) -> void:
	pop_label.text = text
	pop_label.add_theme_color_override("font_color", color)
	pop_label.pivot_offset = pop_label.size / 2.0
	pop_label.scale = Vector2.ONE * 0.3
	pop_label.modulate.a = 1.0
	if pop_tw:
		pop_tw.kill()  # önceki yazının söndürmesi yenisini erken söndürmesin
	pop_tw = pop_label.create_tween()
	pop_tw.tween_property(pop_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tw.tween_interval(0.6)
	pop_tw.tween_property(pop_label, "modulate:a", 0.0, 0.3)


# Küçük küre parçacıklar (G4). one_shot = tek patlama; değilse sürekli akar.
func particles(color: Color, amount: int, life: float, area: Vector3, vel: Vector2, one_shot: bool) -> GPUParticles3D:
	var key := [color, area, vel]
	if not fx_mats.has(key):
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = area
		pm.direction = Vector3(0, 1, 0.3)
		pm.spread = 50.0
		pm.initial_velocity_min = vel.x
		pm.initial_velocity_max = vel.y
		pm.gravity = Vector3(0, -3, 0)
		pm.scale_min = 0.6
		pm.scale_max = 1.3
		var grad := Gradient.new()  # zamanla şeffaflaşsın
		grad.set_color(0, color)
		grad.set_color(1, Color(color, 0.0))
		var ramp := GradientTexture1D.new()
		ramp.gradient = grad
		pm.color_ramp = ramp
		fx_mats[key] = pm
	if not fx_mesh:  # renk tepe rengiyle gelir, küre tek kopya
		fx_mesh = SphereMesh.new()
		fx_mesh.radius = 0.07
		fx_mesh.height = 0.14
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fx_mesh.material = mat
	var g := GPUParticles3D.new()
	g.process_material = fx_mats[key]
	g.draw_pass_1 = fx_mesh
	g.amount = amount
	g.lifetime = life
	g.one_shot = one_shot
	g.explosiveness = 1.0 if one_shot else 0.0
	g.emitting = false  # menüde ve açılışta duran tavşanın altından toz akmasın; çağıran açar
	return g


# Patlama parçacıkları havuzdan: [renk, miktar, hız] başına 2 hazır düğüm sırayla yeniden başlatılır (düğüm üretimi/silme yok).
func burst_pool(color: Color, amount: int, vel: Vector2) -> Array:
	var key := [color, amount, vel]
	if not burst_pools.has(key):
		var list := []
		for i in 2:
			var g := particles(color, amount, 0.6, Vector3(0.15, 0.05, 0.15), vel, true)
			add_child(g)
			list.append(g)
		burst_pools[key] = list
	return burst_pools[key]


func burst(pos: Vector3, color: Color, amount: int, vel := Vector2(1.0, 2.5)) -> void:
	var list := burst_pool(color, amount, vel)
	var g: GPUParticles3D = list.pop_front()
	list.append(g)
	g.position = pos
	g.restart()


func rounded(color: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(radius * 0.9)
	return sb


func hud_label(parent: Node, size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", HUD_TEXT)
	parent.add_child(l)
	return l


func hud_bar(parent: Node, color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(300, 16)
	b.add_theme_stylebox_override("background", rounded(HUD_BAR_BG, 8))
	var fill := rounded(color, 8)
	fill.set_content_margin_all(0)  # kenar boşluğu dolu çubuğu kalınlaştırmasın
	b.add_theme_stylebox_override("fill", fill)
	parent.add_child(b)
	return b


func spawn_row(z: float) -> void:
	var first := items.size()
	for side in [-1, 1]:  # kenar dekoru: hız hissi için
		var d: Array = M.ZONE_DECO[zone(-z)].pick_random()  # bölgeye göre kenar dekoru
		var x: float = side *(randf_range(5.5, 9.0) if d == M.TREE else randf_range(4.2, 7.0))  # ağaçlar yolu kapatmasın
		var n := model(d, Vector3(x, 0, z + randf_range(-2.0, 2.0)))
		n.rotation.y = randf() * TAU
		items.append({node = n, kind = "deco"})
	if randf() < FARM_CHANCE:  # yol kenarında uzakta çiftlik binası
		var fs: int = [-1, 1].pick_random()
		var b := model(M.FARM.pick_random(), Vector3(fs * randf_range(11.0, 14.0), 0, z + randf_range(-3.0, 3.0)))
		b.rotation_degrees.y = -90.0 * fs
		items.append({node = b, kind = "deco"})
	var keep := pick_free(last_free)  # en az bir şerit hep boş kalır
	last_free = keep
	var used := range(LANES.size())
	used.erase(keep)
	used.shuffle()
	for i in randi_range(1, 2):
		var ln: int = used[i]
		var x: float = LANES[ln]
		match randi() % 4:
			0: items.append({node = model(M.FENCE, Vector3(x, 0.3, z)), kind = "hit", h = 0.6, snd = "çit"})   # çit: atla
			1: items.append({node = model(M.BARREL, Vector3(x, 0.8, z)), kind = "hit", h = 1.6, snd = "varil"})  # varil: şerit değiştir
			2:  # tavuk kendi şeridiyle boş olmayan komşusu arasında gider, boş şeride girmez
				var nb := near_lanes(ln).filter(func(o): return o != keep)
				var home: float = (x + LANES[nb.pick_random()]) / 2.0 if not nb.is_empty() else x
				var hen := model(M.CHICKEN, Vector3(x, 0.25, z), null, M.RIG_CHICKEN)
				model(M.SHADOW_BLOB, Vector3(0, -0.23, 0), hen).scale = Vector3.ONE * 0.6
				items.append({node = hen, kind = "chicken", h = 0.5, phase = randf() * TAU, home = home, snd = "tavuk", anim = "chicken"})
			3: items.append({node = model(M.CARROT, Vector3(x, 0.3, z)), kind = "carrot", h = 1.0})
	if randf() < 0.5:
		items.append({node = model(M.CARROT, Vector3(LANES[keep], 0.3, z)), kind = "carrot", h = 1.0})
	if zone(-z) == "kumes" and randf() < GOOSE_CHANCE:  # yol kenarında kaz: yanından geçersen öter
		var side: int = [-1, 1].pick_random()
		items.append({node = model(M.GOOSE, Vector3(side * GOOSE_X, 0, z), null, M.RIG_GOOSE), kind = "goose", lane = 1 + side, h = 0.0, phase = randf() * TAU, anim = "goose", honk = 0.0})  # h 0: hits() hiç tutmaz, kaz çarpmaz
	for it in items.slice(first):  # "pop" diye belirsin
		var n: Node3D = it.node
		n.scale = Vector3.ONE * 0.01  # tam 0 ölçek dönüşümü bozar
		n.create_tween().tween_property(n, "scale", Vector3.ONE, POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Karabaş: köpek bölgesinde tavşanın şeridinde arkadan koşarak gelir; önce uyarı şeridi çıkar.
func run_dog(delta: float, p: Vector3, r: Vector3) -> void:
	dog_t -= delta
	if dog.is_empty() and dog_t <= 0.0 and zone(-p.z) == "kopek":
		dog = {node = model(M.DOG, Vector3(LANES[lane], 0.3, p.z + DOG_START), null, M.RIG_DOG), warn = model(M.WARN_STRIP, Vector3(LANES[lane], 0.03, p.z)),
				lane = lane, rel = DOG_START}
		say("Hav! Karabaş arkanda")
		play("bark")
	if dog.is_empty():
		return
	var was: float = dog.rel
	dog.rel -= DOG_START / DOG_WARN * delta
	dog.node.position = Vector3(LANES[dog.lane], 0.3, p.z + dog.rel)
	apply_pose(dog.node, "dog", clock, 0.0)
	if dog.warn:
		dog.warn.position = Vector3(LANES[dog.lane], 0.03, p.z)
	if was > 0.0 and dog.rel <= 0.0:  # tavşanın hizasına geldi
		dog.warn.queue_free()
		dog.warn = null
		if hits(r, LANES[dog.lane], p.z, DOG_H):
			hurt("Karabaş yakaladı! Halil yaklaşıyor", "köpek")
	if dog.rel < -25.0:  # tavşanı geçip ileride kayboldu
		dog.node.queue_free()
		dog = {}
		dog_t = randf_range(DOG_EVERY.x, DOG_EVERY.y)  # ara köpek gidince başlar


func set_lane(l: int) -> void:
	if l != lane:
		lane_left = lane
		lane_left_t = clock
		lane = l


func say(text: String) -> void:
	msg = text
	msg_t = 1.5


func hurt(text: String, what := "") -> void:
	gap -= HIT_COST
	play(hit_snd(what))
	blink_t = BLINK_TIME
	say(text)
	pop(text, HUD_DANGER)  # önemli mesaj ortada da görünsün
	vibrate(30)
	burst(rabbit.position + Vector3(0, 0.7, 0), STAR_C, 10)  # vurulma yıldızları
	hitstop_t = HITSTOP
	shake_t = SHAKE_TIME if shake_on else 0.0
	flash.modulate.a = 1.0
	flash.create_tween().tween_property(flash, "modulate:a", 0.0, FLASH_TIME)


func _process(delta: float) -> void:
	delta = minf(delta, MAX_DT)
	blink_t -= delta  # oyun bitse de sürsün, tavşan görünmez kalmasın
	rabbit.visible = blink_t <= 0.0 or int(blink_t * 20.0) % 2 == 0
	pause_btn.visible = (state == "intro" or state == "run") and not paused
	if paused:
		return
	if state == "menu":
		rabbit.rotation.y += MENU_SPIN * delta
		return
	if state == "over" or state == "win":
		return  # tuşlar _unhandled_input'ta
	if state == "feast":
		run_feast(delta)
		return
	if state == "intro":
		fill_rows(0.0)
		for c in crossed(INTRO_CUES.keys(), intro_t, intro_t + delta):
			pop(INTRO_CUES[c], HUD_WARN)
			if INTRO_CUES[c].begins_with("HEY"):
				play("hey")
		intro_t += delta
		var k := smoothstep(INTRO_DASH.x, INTRO_DASH.y, intro_t)  # 0: çimde kemiriyor, 1: yolda
		body(rabbit).rotation.x = sin(intro_t * 14.0) * 0.08 * (1.0 - k)  # havuç kemirirken kafa sallanır
		rabbit.position = Vector3(lerpf(INTRO_X, LANES[1], k), 0.3 + sin(k * PI) * 0.5, 0.0)  # yola sıçrayarak koşar
		rabbit.rotation.y = lerpf(INTRO_FACE, 0.0, k)
		halil.position.y = 1.0 + absf(sin(intro_t * 9.0)) * 0.25  # Halil kızgın zıplar
		if intro_t < INTRO_TIME:
			return
		begin_run()
		return  # açılışı atlayan tuş bu karede zıplatmasın ya da şerit değiştirmesin

	if hitstop_t > 0.0:  # vurulma anında kısa duraksama
		hitstop_t -= delta
		return
	shake_t -= delta
	cam_mix = minf(cam_mix + delta / CAM_BLEND, 1.0)
	clock += delta
	speed = minf(speed + ACCEL * delta, SPEED_MAX)
	if Input.is_action_just_pressed("ui_left"):
		set_lane(maxi(lane - 1, 0))
	if Input.is_action_just_pressed("ui_right"):
		set_lane(mini(lane + 1, LANES.size() - 1))
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_accept"):
		jump_t = jump_buf
	if jump_t > 0.0 and ry == 0.0:
		jump_t = 0.0
		vy = JUMP_VY
		play("jump")
		rabbit.scale = JUMP_STRETCH
	jump_t -= delta
	if Input.is_action_just_pressed("ui_down"):
		try_dash()
	dash_t -= delta
	var dashing := dash_t > 0.0
	var spd := (speed + (DASH_SPEED if dashing else 0.0)) * speed_mult(slow_on)  # atılım hızı kalıcı speed'e eklenmez
	var was_air := ry > 0.0
	vy -= GRAVITY * delta
	ry = maxf(ry + vy * delta, 0.0)
	if ry == 0.0:
		vy = 0.0  # yerdeyken eksiye birikmesin
	if was_air and ry == 0.0:
		rabbit.scale = LAND_SQUASH
		play("land")
		burst(Vector3(rabbit.position.x, 0.05, rabbit.position.z), M.DUST_C, 8, Vector2(0.8, 1.6))  # iniş pufu
	rabbit.scale = rabbit.scale.lerp(Vector3.ONE, SQUASH_BACK * delta)

	var p := rabbit.position
	p.x = move_toward(p.x, LANES[lane], LANE_SPEED * delta)
	p.z -= spd * delta
	p.y = ry + 0.3
	rabbit.position = p
	var r := Vector3(p.x, ry, p.z)

	gap = minf(gap + (GAP_REGEN + (DASH_GAP if dashing else 0.0)) * delta, GAP_MAX)
	gap_shown = lerpf(gap_shown, gap, 6.0 * delta)  # çarpmada Halil ışınlanmasın, koşarak yaklaşsın
	halil.position = Vector3(lerpf(halil.position.x, p.x + (HALIL_SIDE if lane < 2 else -HALIL_SIDE), 2.0 * delta), 1.0, p.z + 1.5 + gap_shown * 0.5)
	follow_cam(p.z)
	cam.fov = lerpf(cam.fov, CAM_FOV + (DASH_FOV if dashing else 0.0), 3.0 * delta)
	blind_t -= delta
	bucket.visible = blind_t > 0.0
	blind_rect.visible = bucket.visible
	if not farm_nodes.is_empty() and p.z < -FARM_FREE_Z:  # menü çiftliği geride kaldı
		for n in farm_nodes:
			n.queue_free()
		farm_nodes.clear()
	scenery.position.z = p.z
	clouds.position.z = p.z * CLOUD_PARALLAX
	shadow.position = Vector3(p.x, 0.02, p.z)
	shadow.scale = Vector3.ONE * (1.0 - M.SHADOW_SHRINK * clampf(ry / 1.2, 0.0, 1.0))  # zıplarken küçülür
	run_dust.emitting = ry == 0.0
	run_dust.amount_ratio = 1.0 if dashing else 0.35

	fill_rows(p.z)
	var dist := -p.z
	for k in crossed(EVENTS.keys(), prev_dist, dist):
		pop(EVENTS[k], HUD_WARN)
	prev_dist = dist
	run_dog(delta, p, r)

	var t := clock  # oyun saati: düşük FPS'te (MAX_DT) tavuklar da oyunla aynı yavaşlar
	for who in [rabbit, halil]:
		body(who).position.y = sin(t * BOB_SPEED) * BOB
	halil_throw = move_toward(halil_throw, 0.0, delta * 2.5)
	apply_pose(halil, "halil", t, 0.0, halil_throw)
	apply_pose(rabbit, "rabbit", t, 0.0, 1.0 if ry > 0.0 else 0.0)
	run_items(delta, p, r, t)
	run_throws(delta, p, r, spd)
	if gap <= 0.0 or dist >= GOAL:
		finish(gap > 0.0, minf(dist, GOAL))
		return  # bitiş karesinde HUD ipuçları panelin üstüne çıkmasın
	msg_t -= delta
	update_hud(dist)


func run_items(delta: float, p: Vector3, r: Vector3, t: float) -> void:
	for i in range(items.size() - 1, -1, -1):  # sondan başa: silerken kopya ve arama gerekmesin
		var it: Dictionary = items[i]
		var n: Node3D = it.node
		if it.kind == "chicken":
			n.position.x = it.home + sin(t * 1.5 + it.phase)
			n.rotation.y = PI / 2 * signf(cos(t * 1.5 + it.phase))  # gittiği yöne baksın
		elif it.kind == "carrot":
			n.rotation.y = t * 3.0  # dönen havuç göze çarpsın
		elif it.kind == "roll":
			n.position.z += ROLL_SPEED * delta
			n.rotation.x += ROLL_SPEED / 0.28 * delta
		if it.has("anim") and absf(n.position.z - p.z) < ANIM_DIST:
			var al := 0.0
			if it.anim == "chicken":  # yaklaşınca ürkür, kanat çırpar
				al = clampf(1.0 - Vector2(n.position.x - p.x, n.position.z - p.z).length() / 4.0, 0.0, 1.0)
			else:
				it.honk = maxf(it.honk - delta * 0.8, 0.0)
				al = it.honk
			apply_pose(n, it.anim, t, it.phase, al)
		if it.kind == "goose" and absf(n.position.z - p.z) < 1.0 and absi(lane - it.lane) <= 1:
			it.kind = "deco"  # her kaz bir kez öter
			throw_timer = minf(throw_timer, 0.3)
			it.honk = 1.0
			say("Vak vak! Halil duydu")
			play("goose")
		if it.kind == "slick" and hits(r, n.position.x, n.position.z, it.h):
			it.kind = "deco"  # bir kez kaydırır, sonra süs olarak kalır
			lane = near_lanes(lane).pick_random()  # set_lane değil: kayma kıl payı sayılmasın
			say("Kaydın!")
			continue
		var passed := n.position.z > p.z + CULL_BEHIND
		if passed or (it.kind != "deco" and hits(r, n.position.x, n.position.z, it.h)):
			items.remove_at(i)  # önce listeden çıkar, çarpışma bir daha sayılmasın
			if not passed and it.kind == "carrot":
				carrots += 1
				carrots_total += 1
				burst(n.position, M.CARROT_C, 12)  # havuç parıltısı
				play("carrot")
				vibrate(15)
				var tw := n.create_tween()
				tw.tween_property(n, "scale", Vector3.ONE * 1.6, POP_TIME)
				tw.tween_property(n, "scale", Vector3.ONE * 0.01, POP_TIME)
				tw.tween_callback(n.queue_free)
				continue
			if not passed:
				hurt("Tökezledin! Halil yaklaşıyor", it.get("snd", ""))
			n.queue_free()


func run_throws(delta: float, p: Vector3, r: Vector3, spd: float) -> void:
	throw_timer -= delta
	if throw_timer <= 0.0:
		throw_timer = randf_range(THROW_EVERY.x, THROW_EVERY.y) * lerpf(1.0, THROW_RAMP, -p.z / GOAL)  # yuvaya yaklaştıkça sıklaşır
		var what: Array = THROWN.pick_random()
		var ahead := spd * (RAKE_AHEAD if what[0] == "tırmık" else 1.0)
		var to := Vector3(LANES[lane], 0, p.z - ahead)  # 1 sn sonra tavşanın olacağı yer
		var obj := box(what[2], what[1], Vector3(halil.position.x, 2.2, minf(halil.position.z, p.z + THROW_FROM_Z)), null, what[3])  # kameranın yanından fırlayıp ekranı örtmesin
		var marker := Node3D.new()
		marker.position = to + Vector3(0, 0.03, 0)
		add_child(marker)
		box(Vector3(1.4, 0.04, 1.4), M.TARGET_C, Vector3.ZERO, marker, "y")
		for a in [45.0, -45.0]:  # disk üstünde X: renk körleri için desen
			box(Vector3(1.2, 0.03, 0.14), Color(1, 1, 1, 0.85), Vector3(0, 0.03, 0), marker, "b", Vector3(0, a, 0))
		throws.append({node = obj, marker = marker,
				from = obj.position, to = to, t = -delta / 2.0, item = what[0], lane = lane, spd = spd})  # bu karede de ilerler: yarım kare geriden başla ki her FPS'te tam 1 sn sonra insin
		say("Halil %s fırlattı!" % what[0])
		play("throw")
		halil_throw = 1.0
	for i in range(throws.size() - 1, -1, -1):
		var th: Dictionary = throws[i]
		th.t += delta
		var k := minf(th.t, 1.0)
		var pos: Vector3 = th.from.lerp(th.to, k)
		pos.y += sin(k * PI) * THROW_ARC
		th.node.position = pos
		if k >= 1.0:
			if hits(r, th.to.x, th.to.z, THROW_H):
				hurt("Vuruldun!", th.item)
				if th.item == "kova":
					blind_t = BLIND_TIME
					say("Kova kafana geçti!")
			elif th.item == "tırmık":  # sadece ıskalanınca saplanır; isabette tavşanın altına düşüp ikinci kez çarptırırdı
				items.append({node = model(M.RAKE_STUCK, th.to), kind = "hit", h = 0.6, snd = "tırmık"})
			else:
				if near_miss(lane_left, clock - lane_left_t, th.lane, hits(Vector3(r.x, 0, r.z), th.to.x, th.to.z, THROW_H), near_win):
					gap = minf(gap + NEAR_BONUS, GAP_MAX)
					say("Kıl payı!")
					play("near")
					pop("Kıl payı!", HUD_WARN)
				# Iskalanan yumurta/lahana sekip ileri düşer; tavşanın arkasında kalsa etkisi olmazdı
				var fwd: Vector3 = th.to - Vector3(0, 0, th.spd * BOUNCE_AHEAD)
				if th.item == "yumurta":
					items.append({node = model(M.EGG_SPLAT, fwd), kind = "slick", h = 0.1})
				elif th.item == "lahana":
					items.append({node = model(M.CABBAGE, fwd + Vector3(0, 0.28, 0)), kind = "roll", h = 0.5})
			th.node.queue_free()
			th.marker.queue_free()
			throws.remove_at(i)


func update_hud(dist: float) -> void:
	hud.text = "%s    %d / %d m    Havuç: %d" % [rabbit_name, dist, GOAL, carrots]
	dist_bar.value = dist / GOAL * 100.0
	var safe := clampf(gap / GAP_MAX, 0.0, 1.0)  # gap çarpınca negatif olabilir
	gap_bar.value = safe * 100.0
	gap_label.text = gap_text(safe)
	var near := safe < 0.3  # renge ek olarak yazı, ▲ sayısı ve kalın koyu kenar
	for side in 4:
		gap_fill.set_border_width(side, 3 if near else 0)
	gap_fill.bg_color = HUD_DANGER.lerp(HUD_WARN, safe * 2.0) if safe < 0.5 else HUD_WARN.lerp(HUD_SAFE, safe * 2.0 - 1.0)
	msg_label.text = msg
	for i in dash_pips.size():  # dolu havuçlar renkli, boşlar soluk
		dash_pips[i].modulate = Color.WHITE if i < carrots else Color(1, 1, 1, 0.25)
	var dash_ready := can_dash(carrots, dash_t)
	dash_hint.visible = dash_ready
	if dash_ready:
		dash_hint.modulate.a = 0.6 + 0.4 * sin(clock * 8.0)  # hafifçe parlasın
		if not dash_hinted:  # mekaniği bir kez öğret
			dash_hinted = true
			pop("↓ ile atıl!", M.CARROT_C)
	msg_label.modulate.a = 1.0 if msg_t > 0.0 and state == "run" else 0.0  # metni silmek paneli zıplatırdı


# Halil çubuğunun yazısı: yalnız renge güvenme (renk körlüğü).
static func gap_text(safe: float) -> String:
	if safe < 0.3:
		return "Halil'e uzaklık: YAKIN! ▲▲▲"
	return "Halil'e uzaklık: dikkat ▲" if safe < 0.6 else "Halil'e uzaklık: güvenli"


# Koşu bitti: puanı tabloya yaz. Kazanılırsa yuvaya girilip şölen verilir (feast), sonra panel; kaybedilirse panel hemen.
func finish(won: bool, dist: float) -> void:
	blind_rect.visible = false  # kova karartması bitiş panelini örtmesin
	bucket.visible = false
	run_dust.emitting = false
	play("win" if won else "lose")
	var pts := score(dist, carrots_total, won)
	var entry := {isim = rabbit_name, puan = pts}
	var table := Secim.insert_score(Secim.load_scores(), entry)
	Secim.save("skor", {liste = table})  # şölen yarıda kapansa da puan kaybolmaz
	dolap_st.havuc = Dolap.bank_run(carrots_total, won)  # kumbara hemen kaydedilir
	var title := ("%s yuvada şölen yaptı!\nHalil eli boş döndü." % rabbit_name) if won else ("Halil yakaladı: %s" % rabbit_name)
	end_text = "%s\nPuan: %d    Kumbara: +%d (%d havuç)\n\nEn iyiler\n%s\n\nEnter / dokun: tekrar koş    Esc: menü" % [title, pts,
			Dolap.earned(carrots_total, won), dolap_st.havuc, Secim.score_lines(table, table.find_custom(func(e): return is_same(e, entry)))]  # aynı puanlı eski kayıt değil, bu kayıt
	if won:
		begin_feast()
	else:
		show_end(false)


func show_end(won: bool) -> void:
	state = "win" if won else "over"
	set_process_unhandled_input(false)
	get_tree().create_timer(END_LOCK).timeout.connect(set_process_unhandled_input.bind(true))
	if pop_tw:
		pop_tw.kill()  # "Mmm!" / "Ham!" panelin üstünde kalmasın
	pop_label.modulate.a = 0.0
	end_box.visible = true
	end_label.text = end_text


# --- Yuvada şölen ---

func mconst(name: String) -> Variant:  # Tasarımcının modeli yoksa null: kod kutu yedeğine düşer
	var sc: Script = M
	return sc.get_script_constant_map().get(name)


func begin_feast() -> void:
	state = "feast"
	feast_t = 0.0
	feast_bites = 0
	feast_last = -9.0
	feast_done_t = -1.0
	feast_swapped = false
	feast_from = rabbit.position
	feast_cam_from = cam.position
	for th in throws:  # havada asılı kalmasın
		th.node.visible = false
		th.marker.visible = false
	skip_btn.visible = true
	feast_fade.visible = true
	hint_box.visible = false  # dokunma ipucu şölene taşmasın


func feast_input(e: InputEvent) -> void:
	if not e.is_pressed() or e.is_echo():
		return
	if (e is InputEventKey and e.keycode == KEY_ESCAPE) or (e is InputEventJoypadButton and e.button_index == JOY_BUTTON_B):
		feast_finish()
	elif e is InputEventKey or e is InputEventScreenTouch or e is InputEventJoypadButton or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT):
		feast_bite()


func run_feast(delta: float) -> void:
	feast_t += delta
	if feast_t < FEAST_ENTER:  # yuva ağzına sıçra, kamera yaklaşsın, ekran kararsın
		var k := feast_t / FEAST_ENTER
		var mouth := Vector3(0, 0.3, -GOAL - 1.5)
		rabbit.position = feast_from.lerp(mouth, k) + Vector3(0, sin(k * PI) * 0.8, 0)
		rabbit.scale = Vector3.ONE * lerpf(1.0, 0.5, k)
		cam.position = feast_cam_from.lerp(Vector3(0, 2.5, -GOAL + 4), smoothstep(0.0, 1.0, k))
		cam.look_at(Vector3(0, 0.6, -GOAL - 2))
		feast_fade.color.a = smoothstep(0.6, 1.0, k)
		return
	if not feast_swapped:
		swap_to_room()
	feast_fade.color.a = maxf(0.0, 1.0 - (feast_t - FEAST_ENTER) / (FEAST_EAT_AT - FEAST_ENTER))
	feast_fade.visible = feast_fade.color.a > 0.0
	var eating := feast_done_t < 0.0
	if eating and feast_t >= FEAST_EAT_AT and feast_t - feast_last >= FEAST_AUTO:
		feast_bite()  # kimse dokunmasa da yer
	if eating and feast_t >= FEAST_MAX - FEAST_END_WAIT:
		end_eating()
	if feast_done_t >= 0.0:
		feast_done_t += delta
		body(rabbit).rotation.z = sin(feast_done_t * 20.0) * 0.15  # "Mmm!" sallanır
		if feast_done_t >= FEAST_END_WAIT:
			feast_finish()
			return
	if feast_idx < feast_piles_list.size():
		var d: Vector3 = feast_piles_list[feast_idx].pos - rabbit.position
		rabbit.rotation.y = lerp_angle(rabbit.rotation.y, atan2(-d.x, -d.z), 1.0 - exp(-8.0 * delta))
	rabbit.position = rabbit.position.lerp(feast_goal, 1.0 - exp(-6.0 * delta))
	rabbit.scale = rabbit.scale.lerp(Vector3.ONE, SQUASH_BACK * delta)


# Dünyayı (zemin, çiftlik, öğeler, Halil) gizle: yalnız oda çizilsin. Tavşan, kamera, ışıklar ve parçacık havuzu kalır.
func swap_to_room() -> void:
	feast_swapped = true
	build_feast_room()
	for c in get_children():
		if c is Node3D and c != rabbit and c != cam and c != feast_root and not c is Light3D and not c is GPUParticles3D:
			c.visible = false
	hud_panel.visible = false
	rabbit.scale = Vector3.ONE
	rabbit.rotation.y = 0.0
	rabbit.position = FEAST_POS + Vector3(0, 0.3, 0.8)
	cam.fov = 55.0
	cam.position = FEAST_POS + Vector3(0, 4.2, 8.0)  # oda +z'den açık; tavan kameranın altında kalır
	cam.look_at(FEAST_POS + Vector3(0, 0.2, -0.5))
	feast_idx = 0
	feast_goal = rabbit.position
	set_feast_goal()
	pop("Dokun, ye!", HUD_WARN)


func build_feast_room() -> void:
	feast_root = Node3D.new()
	feast_root.position = FEAST_POS
	add_child(feast_root)
	box(Vector3(90, 0.2, 90), FEAST_BG, Vector3(0, -0.3, 0), feast_root)  # arkalık: sky ve yeşil zemin görünmesin (Compatibility'de BG_COLOR işe yaramadı)
	box(Vector3(90, 50, 0.4), FEAST_BG, Vector3(0, 20, -14), feast_root)
	var inside: Variant = mconst("BURROW_INSIDE")
	if inside is Array:
		model(inside, Vector3.ZERO, feast_root)
	else:  # yedek: toprak zemin ve üç duvar
		box(Vector3(18, 0.4, 18), M.DIRT, Vector3(0, -0.2, 0), feast_root)
		box(Vector3(18, 6, 0.6), M.DIRT_DARK, Vector3(0, 3, -9), feast_root)
		box(Vector3(0.6, 6, 18), M.DIRT_DARK, Vector3(-9, 3, 0), feast_root)
		box(Vector3(0.6, 6, 18), M.DIRT_DARK, Vector3(9, 3, 0), feast_root)
	var kinds := []
	for n in ["CARROT_PILE", "VEG_CABBAGE", "VEG_TURNIP", "VEG_CORN", "VEG_TOMATO", "VEG_EGGPLANT"]:
		var v: Variant = mconst(n)
		if v is Array:
			kinds.append(v)
	if kinds.is_empty():
		kinds = [M.CARROT, M.CABBAGE]
	var count := feast_piles(carrots_total)
	feast_piles_list.clear()
	for i in count:
		var a := TAU * i / count + 0.35
		var local := Vector3(sin(a) * 3.3, 0, -0.6 - cos(a) * 2.3)  # oda 10 x 9 m (BURROW_INSIDE)
		var pile := Node3D.new()
		pile.position = local
		feast_root.add_child(pile)
		var kind: Array = kinds[i % kinds.size()]
		for o in ([Vector3.ZERO] if kind == mconst("CARROT_PILE") else [Vector3(-0.35, 0, 0.1), Vector3(0.3, 0, 0.15), Vector3(0, 0, -0.3)]):  # havuç yığını zaten yığın
			model(kind, o, pile).scale = Vector3.ONE * 1.4
		feast_piles_list.append({node = pile, left = FEAST_BITES, pos = FEAST_POS + local})


func set_feast_goal() -> void:
	if feast_idx < feast_piles_list.size():
		var pos: Vector3 = feast_piles_list[feast_idx].pos
		feast_goal = Vector3(pos.x, 0.3, pos.z).lerp(FEAST_POS + Vector3(0, 0.3, -0.6), 0.3)


func feast_bite() -> void:
	if state != "feast" or not feast_swapped or feast_done_t >= 0.0 or feast_t < FEAST_EAT_AT or feast_t - feast_last < FEAST_BITE_GAP:
		return
	feast_last = feast_t
	feast_bites += 1
	var pl: Dictionary = feast_piles_list[feast_idx]
	pl.left -= 1
	burst(pl.pos + Vector3(0, 0.8, 0), M.CARROT_C, 12)
	rabbit.scale = LAND_SQUASH
	var cheek := 1.0 + minf(feast_bites * 0.02, 0.25)  # yanaklar şişer
	body(rabbit).scale = Vector3(cheek, 1.0, cheek)
	pop("Ham!", M.CARROT_C)
	crunch()
	vibrate(20)
	var tw: Tween = pl.node.create_tween()
	tw.tween_property(pl.node, "scale", Vector3.ONE * maxf(float(pl.left) / FEAST_BITES, 0.01), 0.12)
	if pl.left <= 0:
		tw.tween_callback(pl.node.set_visible.bind(false))
		feast_idx += 1
		if feast_idx >= feast_piles_list.size():
			end_eating()
		else:
			set_feast_goal()


func end_eating() -> void:
	if feast_done_t < 0.0:
		feast_done_t = 0.0
		pop("Mmm!", HUD_WARN)


# Şölen biter (süre, tüm yığınlar ya da Geç/Esc): panele geç.
func feast_finish() -> void:
	if state != "feast":
		return
	skip_btn.visible = false
	feast_fade.visible = false
	body(rabbit).rotation.z = 0.0
	show_end(true)


# Ses: üretim ses.gd'de. Ekransızda ses sürücüsü sahte (çıkışta sızıntı uyarısı verir): hiç kurulmaz, play() sessiz geçer.
# Oynatıcılar sabit: POOL efekt (sırayla) + 1 müzik. Tarayıcı sesi ilk dokunuştan sonra açar (Godot kendisi yönetir).
func make_audio() -> void:
	if DisplayServer.get_name() == "headless" and not force_audio:
		return
	snd_bank = Ses.make_all().duplicate()
	snd_bank.merge(Ses.load_files(), true)  # dosyadan yüklenenler üretilmişlerin yerini alır
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		snd_pool.append(p)
	music = AudioStreamPlayer.new()
	music.stream = snd_bank.music
	music.volume_db = -22.0  # efektlerin altında
	add_child(music)
	if snd_on:
		music.play()


# Çıkışta oynatıcı akışlarını ve ses önbelleğini bırak ("ObjectDB instances leaked" uyarısı olmasın).
func release_audio() -> void:
	for pl in snd_pool:
		pl.stop()
		pl.stream = null
	if music:
		music.stop()
		music.stream = null
	snd_bank = {}
	Ses.bank = {}


func play(snd: String) -> void:
	if snd_on and not snd_pool.is_empty() and snd_bank.has(snd):
		snd_pool[snd_next].volume_db = -8.0 + (HIT_TRIM if snd.begins_with("hit_") else 0.0)
		snd_pool[snd_next].stream = snd_bank[snd]
		snd_pool[snd_next].play()
		snd_next = (snd_next + 1) % POOL


func crunch() -> void:
	play("crunch%d" % (feast_bites % 2))


func toggle_snd() -> void:
	snd_on = not snd_on
	Secim.save("ayar", {ses = snd_on})
	snd_label()
	if music:
		if snd_on:
			music.play()
		else:
			music.stop()
			for p in snd_pool:
				p.stop()
	play("click")


func snd_label() -> void:
	snd_btn.text = "Ses: Açık" if snd_on else "Ses: Kapalı"
	if set_btns.has("ses"):
		set_btns.ses.text = snd_btn.text


# Menüde sağ altta (sağ üstte skor kutusu var), oyunda sağ üstte.
func place_snd(menu: bool) -> void:
	snd_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT if menu else Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	set_btn.visible = menu  # menüde sol üst köşe (orada başka şey yok)
	dolap_btn.visible = menu
	dolap_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	dolap_btn.grow_horizontal = Control.GROW_DIRECTION_END
	set_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	set_btn.grow_horizontal = Control.GROW_DIRECTION_END
	set_btn.grow_vertical = Control.GROW_DIRECTION_END
	pause_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)  # ses düğmesinin solunda
	pause_btn.offset_left -= SND_BTN.x + 8
	pause_btn.offset_right -= SND_BTN.x + 8
