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

# Menü ve Bölüm 1 (PLAN-karakter-secimi.md, PLAN-bolum1.md)
const MENU_CAM := Vector3(1.9, 1.0, -3.0)  # menü kamerası, tavşana göre (Tasarımcı ayarlar)
const MENU_LOOK := Vector3(-1.5, 0.05, 0)  # tavşan ekranın solunda: panel ortada, liste sağda kalsın
const FARM_CHANCE := 0.3                    # her sırada yol kenarına bina çıkma olasılığı
const MENU_SPIN := 0.6                     # tavşanın menüde dönüşü (rad/sn)
const INTRO_GO := "KAÇ!"
const INTRO_CUES := {0.05: "Mmm, taze havuç...", 1.6: "HEY! Havuçlarım!", 3.2: "3", 3.8: "2", 4.4: "1", 5.0: INTRO_GO}
const INTRO_TIME := 5.2
const INTRO_X := -5.5          # tavşan yolun dışında, çimde başlar
const INTRO_DASH := Vector2(2.3, 3.0)  # yola koştuğu aralık (sn)
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

var rabbit: Node3D
var halil: Node3D
var scenery: Node3D  # zemin, yol ve tepeler: tavşanla birlikte kayar
var cam: Camera3D
var hud: Label
var dist_bar: ProgressBar
var gap_bar: ProgressBar
var gap_fill: StyleBoxFlat
var msg_label: Label
var end_box: CenterContainer
var end_label: Label

# Arayüz renkleri (Tasarımcı ayarlar)
const HUD_BG := Color(1.0, 0.97, 0.9, 0.82)
const HUD_TEXT := Color(0.33, 0.22, 0.14)
const HUD_BAR_BG := Color(0.33, 0.22, 0.14, 0.15)
const HUD_SAFE := Color(0.45, 0.72, 0.3)
const HUD_DANGER := Color(0.87, 0.3, 0.25)
const HUD_WARN := Color(0.96, 0.75, 0.25)


# Tavşan (ayak noktası r) bir şeye çarptı mı? h: engelin yüksekliği, üstünden atlanabilir.
static func hits(r: Vector3, x: float, z: float, h: float) -> bool:
	return absf(r.x - x) < 0.8 and absf(r.z - z) < 0.6 and r.y < h


# Yeni sıranın boş şeridi öncekine en fazla 1 şerit uzak olsun, oyuncu hep yetişebilsin.
static func pick_free(last: int) -> int:
	return clampi(last + randi_range(-1, 1), 0, LANES.size() - 1)


static func can_dash(carrot_count: int, dash_left: float) -> bool:
	return carrot_count >= DASH_COST and dash_left <= 0.0


# Iskalanan atış kıl payı mı? Hedef şeridi az önce terk ettin ya da tam üstünden atladın.
static func near_miss(left_lane: int, left_age: float, target_lane: int, airborne_over: bool) -> bool:
	return airborne_over or (left_lane == target_lane and left_age <= NEAR_TIME)


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
		meshes[shape] = m
	return meshes[shape]


func soft_mat(color: Color) -> Material:
	if not mats.has(color):
		if color.a >= 1.0:  # opak: iki bantlı toon shader
			var sm := ShaderMaterial.new()
			sm.shader = TOON
			sm.set_shader_parameter("albedo", color)
			sm.set_shader_parameter("sway", color in SWAY_COLORS)
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


# Parça: [boyut, renk, konum, şekil?, dönüş(derece)?]
func model(parts: Array, pos: Vector3, parent: Node = null) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	(parent if parent else self).add_child(root)
	var body := Node3D.new()  # sallanma bunu oynatır; kök çarpışma noktası olduğu için yerinde kalır
	root.add_child(body)
	for pt in parts:
		box(pt[0], pt[1], pt[2], body, pt[3] if pt.size() > 3 else "b", pt[4] if pt.size() > 4 else Vector3.ZERO)
	return root


func _ready() -> void:
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
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC  # AgX sahneyi soluk gösterdi
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.fog_enabled = true
	env.fog_light_color = horizon
	env.fog_density = 0.007
	env.fog_sky_affect = 0.15 # varsayılan 1.0 gökyüzünü tamamen sise boğuyor
	env.ssao_enabled = true
	env.adjustment_enabled = true  # FILMIC'in soldurduğu rengi geri getir
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.05
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-25, -40, 0)
	sun.light_color = Color(1.0, 0.85, 0.68)
	sun.light_energy = 1.2
	sun.light_angular_distance = 2.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40.0  # gölge çözünürlüğü kameranın yakınında toplansın
	add_child(sun)

	make_world()
	var choice := Secim.load_choice()
	make_rabbit(choice.skin)
	rabbit_name = Secim.clean_name(choice.isim, M.RABBIT_SKINS[choice.skin].ad)
	halil = model(M.HALIL, Vector3(0, 1, 7))
	model(M.SHADOW_BLOB, Vector3(0, -0.98, 0), halil).scale = Vector3.ONE * 1.3
	cam = Camera3D.new()
	var cam_fx := CameraAttributesPractical.new()  # minyatür oyuncak dünya: uzak tepeler hafif bulanık
	cam_fx.dof_blur_far_enabled = true
	cam_fx.dof_blur_far_distance = 40.0
	cam_fx.dof_blur_amount = 0.05
	cam.attributes = cam_fx
	add_child(cam)

	make_hud()

	model(M.FENCE, Vector3(-3.4, 0.3, 0.6)).rotation.y = 0.5  # başlangıç süsü (menü + açılış): yol kenarında çit ve havuç yığını
	model(M.BURROW.slice(2), Vector3(-0.9, 0, -1.5))
	if go_menu:
		hud_panel.visible = false
		cam.position = rabbit.position + MENU_CAM
		cam.look_at(rabbit.position + MENU_LOOK)
		var menu := Secim.new()
		add_child(menu)
		var t := ui_theme()
		for c in menu.get_children():
			c.theme = t
		menu.renk.connect(make_rabbit)
		menu.basla.connect(on_start)
	else:
		on_start(rabbit_name)


# Zemin, çiftlik, bulutlar, yuva, kümes ve tabelalar.
func make_world() -> void:
	scenery = model(M.GROUND, Vector3.ZERO)
	for f in M.FARM_SET:  # menünün arkası ve kenarları çiftlik
		var fm := model(f[0], f[1])  # scenery'nin çocuğu değil: o tavşanla kayar, evler sabit kalmalı
		fm.rotation_degrees.y = f[2]
		fm.scale = Vector3.ONE * f[3]
	clouds = Node3D.new()
	add_child(clouds)
	for c in [Vector3(-30, 28, -90), Vector3(18, 34, -130), Vector3(42, 26, -70), Vector3(-12, 38, -170), Vector3(-48, 30, -140)]:
		model(M.CLOUD, c, clouds)
	shadow = model(M.SHADOW_BLOB, Vector3(0, 0.02, 0))
	model(M.BURROW, Vector3(0, 0, -GOAL - 2))
	model(M.COOP, Vector3(-6.5, 0, -ZONES[2][0] - 4))  # kümes bölgesinin başında, yol kenarında
	for k in EVENTS:
		model(M.SIGN, Vector3(4.2, 0, -k))  # bölge tabelası


# HUD, bitiş paneli, kova karartması ve ortadaki yazı.
func make_hud() -> void:
	var layer := CanvasLayer.new()
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
	hud_label(col, 18).text = "Halil'e uzaklık"
	gap_bar = hud_bar(col, HUD_SAFE)
	gap_fill = gap_bar.get_theme_stylebox("fill")
	msg_label = hud_label(col, 20)
	end_box = CenterContainer.new()
	end_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_box.visible = false
	layer.add_child(end_box)
	var end_panel := PanelContainer.new()
	end_panel.add_theme_stylebox_override("panel", rounded(HUD_BG, 24))
	end_box.add_child(end_panel)
	end_label = hud_label(end_panel, 28)  # tablo da sığsın
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	pop_label.add_theme_font_size_override("font_size", 56)
	pop_label.add_theme_color_override("font_outline_color", HUD_TEXT)
	pop_label.add_theme_constant_override("outline_size", 12)
	pop_label.rotation_degrees = -6
	pop_label.modulate.a = 0.0
	layer.add_child(pop_label)


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
	rabbit = model(Secim.skin_parts(M.RABBIT, M.RABBIT_SKINS[s]), Vector3(0, 0.3, 0))
	rabbit.rotation.y = turn
	bucket = model(M.BUCKET_HAT, Vector3.ZERO, body(rabbit))  # body altında: sallanmayla oynar
	bucket.visible = false
	run_dust = particles(M.DUST_C, 24, 0.5, Vector3(0.2, 0.02, 0.1), Vector2(0.3, 0.9), false)
	run_dust.position = Vector3(0, -0.28, 0.3)
	rabbit.add_child(run_dust)


func on_start(isim: String) -> void:
	rabbit_name = isim
	rabbit.position.x = INTRO_X
	rabbit.rotation.y = INTRO_FACE
	hud_panel.visible = true
	follow_cam(0.0)
	state = "intro"
	update_hud(0.0)  # açılışta önceki/varsayılan değerler görünmesin


func follow_cam(z: float) -> void:
	cam.position = Vector3(0, 6, z + 11)
	cam.look_at(Vector3(0, 0, z - 8))


func fill_rows(z: float) -> void:
	while next_row_z > z - 80 and next_row_z > -GOAL + 10:
		spawn_row(next_row_z)
		next_row_z -= randf_range(9.0, 15.0)


# Açılışta herhangi bir tuş ya da tıklama açılışı atlar. Bitişte Enter tekrar koşturur, Esc menüye döner
# (Space yok; Enter da zıplattığı için bitişte END_LOCK kadar kilit var, bkz. finish()).
func _unhandled_input(e: InputEvent) -> void:
	if not e.is_pressed() or e.is_echo():
		return
	if state == "run" and e is InputEventScreenTouch:
		touch_control(e.position.x)  # telefon: görünmez sol / orta / sağ bölgeler
		return
	if state == "intro" and (e is InputEventKey or e is InputEventScreenTouch or e is InputEventJoypadButton or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT)):
		if intro_t < INTRO_CUES.find_key(INTRO_GO):
			pop(INTRO_GO, HUD_WARN)  # atlanınca da görünsün (henüz çıkmadıysa)
		intro_t = INTRO_TIME
	elif state == "over" or state == "win":
		var again: bool = (e is InputEventKey and e.keycode in [KEY_ENTER, KEY_KP_ENTER]) or (e is InputEventJoypadButton and e.button_index == JOY_BUTTON_A) or e is InputEventScreenTouch
		var menu: bool = (e is InputEventKey and e.keycode == KEY_ESCAPE) or (e is InputEventJoypadButton and e.button_index == JOY_BUTTON_B)
		if again or menu:
			go_menu = menu
			get_tree().reload_current_scene()


# Telefon: ekranın sol üçte biri sola, sağ üçte biri sağa geçer, ortası zıplatır (görünmez bölgeler).
func touch_control(x: float) -> void:
	match int(3.0 * x / get_viewport().get_visible_rect().size.x):
		0: set_lane(maxi(lane - 1, 0))
		1: jump_t = JUMP_BUFFER
		_: set_lane(mini(lane + 1, LANES.size() - 1))


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


func burst(pos: Vector3, color: Color, amount: int, vel := Vector2(1.0, 2.5)) -> void:
	var g := particles(color, amount, 0.6, Vector3(0.15, 0.05, 0.15), vel, true)
	g.position = pos
	add_child(g)
	g.emitting = true
	g.finished.connect(g.queue_free)


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
			0: items.append({node = model(M.FENCE, Vector3(x, 0.3, z)), kind = "hit", h = 0.6})   # çit: atla
			1: items.append({node = model(M.BARREL, Vector3(x, 0.8, z)), kind = "hit", h = 1.6})  # varil: şerit değiştir
			2:  # tavuk kendi şeridiyle boş olmayan komşusu arasında gider, boş şeride girmez
				var nb := near_lanes(ln).filter(func(o): return o != keep)
				var home: float = (x + LANES[nb.pick_random()]) / 2.0 if not nb.is_empty() else x
				var hen := model(M.CHICKEN, Vector3(x, 0.25, z))
				model(M.SHADOW_BLOB, Vector3(0, -0.23, 0), hen).scale = Vector3.ONE * 0.6
				items.append({node = hen, kind = "chicken", h = 0.5, phase = randf() * TAU, home = home})
			3: items.append({node = model(M.CARROT, Vector3(x, 0.3, z)), kind = "carrot", h = 1.0})
	if randf() < 0.5:
		items.append({node = model(M.CARROT, Vector3(LANES[keep], 0.3, z)), kind = "carrot", h = 1.0})
	if zone(-z) == "kumes" and randf() < GOOSE_CHANCE:  # yol kenarında kaz: yanından geçersen öter
		var side: int = [-1, 1].pick_random()
		items.append({node = model(M.GOOSE, Vector3(side * GOOSE_X, 0, z)), kind = "goose", lane = 1 + side, h = 0.0})  # h 0: hits() hiç tutmaz, kaz çarpmaz
	for it in items.slice(first):  # "pop" diye belirsin
		var n: Node3D = it.node
		n.scale = Vector3.ONE * 0.01  # tam 0 ölçek dönüşümü bozar
		n.create_tween().tween_property(n, "scale", Vector3.ONE, POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Karabaş: köpek bölgesinde tavşanın şeridinde arkadan koşarak gelir; önce uyarı şeridi çıkar.
func run_dog(delta: float, p: Vector3, r: Vector3) -> void:
	dog_t -= delta
	if dog.is_empty() and dog_t <= 0.0 and zone(-p.z) == "kopek":
		dog = {node = model(M.DOG, Vector3(LANES[lane], 0.3, p.z + DOG_START)), warn = model(M.WARN_STRIP, Vector3(LANES[lane], 0.03, p.z)),
				lane = lane, rel = DOG_START}
		say("Hav! Karabaş arkanda")
	if dog.is_empty():
		return
	var was: float = dog.rel
	dog.rel -= DOG_START / DOG_WARN * delta
	dog.node.position = Vector3(LANES[dog.lane], 0.3, p.z + dog.rel)
	if dog.warn:
		dog.warn.position = Vector3(LANES[dog.lane], 0.03, p.z)
	if was > 0.0 and dog.rel <= 0.0:  # tavşanın hizasına geldi
		dog.warn.queue_free()
		dog.warn = null
		if hits(r, LANES[dog.lane], p.z, DOG_H):
			hurt("Karabaş yakaladı! Halil yaklaşıyor")
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


func hurt(text: String) -> void:
	gap -= HIT_COST
	blink_t = BLINK_TIME
	say(text)
	burst(rabbit.position + Vector3(0, 0.7, 0), STAR_C, 10)  # vurulma yıldızları


func _process(delta: float) -> void:
	delta = minf(delta, MAX_DT)
	blink_t -= delta  # oyun bitse de sürsün, tavşan görünmez kalmasın
	rabbit.visible = blink_t <= 0.0 or int(blink_t * 20.0) % 2 == 0
	if state == "menu":
		rabbit.rotation.y += MENU_SPIN * delta
		return
	if state == "over" or state == "win":
		return  # tuşlar _unhandled_input'ta
	if state == "intro":
		fill_rows(0.0)
		for c in crossed(INTRO_CUES.keys(), intro_t, intro_t + delta):
			pop(INTRO_CUES[c], HUD_WARN)
		intro_t += delta
		var k := smoothstep(INTRO_DASH.x, INTRO_DASH.y, intro_t)  # 0: çimde kemiriyor, 1: yolda
		body(rabbit).rotation.x = sin(intro_t * 14.0) * 0.08 * (1.0 - k)  # havuç kemirirken kafa sallanır
		rabbit.position = Vector3(lerpf(INTRO_X, LANES[1], k), 0.3 + sin(k * PI) * 0.5, 0.0)  # yola sıçrayarak koşar
		rabbit.rotation.y = lerpf(INTRO_FACE, 0.0, k)
		halil.position.y = 1.0 + (absf(sin(intro_t * 9.0)) * 0.25 if intro_t > 1.6 else 0.0)  # Halil fark edince zıplar
		if intro_t < INTRO_TIME:
			return
		body(rabbit).rotation.x = 0.0
		rabbit.position = Vector3(LANES[1], 0.3, 0.0)  # açılışı atlayınca da yolda başlar
		rabbit.rotation.y = 0.0
		halil.position.y = 1.0
		state = "run"
		return  # açılışı atlayan tuş bu karede zıplatmasın ya da şerit değiştirmesin

	clock += delta
	speed = minf(speed + ACCEL * delta, SPEED_MAX)
	if Input.is_action_just_pressed("ui_left"):
		set_lane(maxi(lane - 1, 0))
	if Input.is_action_just_pressed("ui_right"):
		set_lane(mini(lane + 1, LANES.size() - 1))
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_accept"):
		jump_t = JUMP_BUFFER
	if jump_t > 0.0 and ry == 0.0:
		jump_t = 0.0
		vy = JUMP_VY
		rabbit.scale = JUMP_STRETCH
	jump_t -= delta
	if Input.is_action_just_pressed("ui_down") and can_dash(carrots, dash_t):
		carrots -= DASH_COST
		dash_t = DASH_TIME
		say("Atıl!")
	dash_t -= delta
	var dashing := dash_t > 0.0
	var spd := speed + (DASH_SPEED if dashing else 0.0)  # atılım hızı kalıcı speed'e eklenmez
	var was_air := ry > 0.0
	vy -= GRAVITY * delta
	ry = maxf(ry + vy * delta, 0.0)
	if ry == 0.0:
		vy = 0.0  # yerdeyken eksiye birikmesin
	if was_air and ry == 0.0:
		rabbit.scale = LAND_SQUASH
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
	halil.position = Vector3(lerpf(halil.position.x, p.x, 2.0 * delta), 1.0, p.z + 1.5 + gap_shown * 0.5)
	follow_cam(p.z)
	cam.fov = lerpf(cam.fov, 75.0 + (DASH_FOV if dashing else 0.0), 3.0 * delta)
	blind_t -= delta
	bucket.visible = blind_t > 0.0
	blind_rect.visible = bucket.visible
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
		if it.kind == "goose" and absf(n.position.z - p.z) < 1.0 and absi(lane - it.lane) <= 1:
			it.kind = "deco"  # her kaz bir kez öter
			throw_timer = minf(throw_timer, 0.3)
			say("Vak vak! Halil duydu")
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
				var tw := n.create_tween()
				tw.tween_property(n, "scale", Vector3.ONE * 1.6, POP_TIME)
				tw.tween_property(n, "scale", Vector3.ONE * 0.01, POP_TIME)
				tw.tween_callback(n.queue_free)
				continue
			if not passed:
				hurt("Tökezledin! Halil yaklaşıyor")
			n.queue_free()


func run_throws(delta: float, p: Vector3, r: Vector3, spd: float) -> void:
	throw_timer -= delta
	if throw_timer <= 0.0:
		throw_timer = randf_range(THROW_EVERY.x, THROW_EVERY.y) * lerpf(1.0, THROW_RAMP, -p.z / GOAL)  # yuvaya yaklaştıkça sıklaşır
		var what: Array = THROWN.pick_random()
		var ahead := spd * (RAKE_AHEAD if what[0] == "tırmık" else 1.0)
		var to := Vector3(LANES[lane], 0, p.z - ahead)  # 1 sn sonra tavşanın olacağı yer
		var obj := box(what[2], what[1], halil.position + Vector3(0, 1.2, 0), null, what[3])
		throws.append({node = obj, marker = box(Vector3(1.4, 0.04, 1.4), M.TARGET_C, to + Vector3(0, 0.03, 0), null, "y"),
				from = obj.position, to = to, t = -delta / 2.0, item = what[0], lane = lane, spd = spd})  # bu karede de ilerler: yarım kare geriden başla ki her FPS'te tam 1 sn sonra insin
		say("Halil %s fırlattı!" % what[0])
	for i in range(throws.size() - 1, -1, -1):
		var th: Dictionary = throws[i]
		th.t += delta
		var k := minf(th.t, 1.0)
		var pos: Vector3 = th.from.lerp(th.to, k)
		pos.y += sin(k * PI) * THROW_ARC
		th.node.position = pos
		if k >= 1.0:
			if hits(r, th.to.x, th.to.z, THROW_H):
				hurt("Vuruldun!")
				if th.item == "kova":
					blind_t = BLIND_TIME
					say("Kova kafana geçti!")
			elif th.item == "tırmık":  # sadece ıskalanınca saplanır; isabette tavşanın altına düşüp ikinci kez çarptırırdı
				items.append({node = model(M.RAKE_STUCK, th.to), kind = "hit", h = 0.6})
			else:
				if near_miss(lane_left, clock - lane_left_t, th.lane, hits(Vector3(r.x, 0, r.z), th.to.x, th.to.z, THROW_H)):
					gap = minf(gap + NEAR_BONUS, GAP_MAX)
					say("Kıl payı!")
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


# Koşu bitti: puanı tabloya yaz, bitiş panelini göster.
func finish(won: bool, dist: float) -> void:
	state = "win" if won else "over"
	set_process_unhandled_input(false)
	get_tree().create_timer(END_LOCK).timeout.connect(set_process_unhandled_input.bind(true))
	blind_rect.visible = false  # kova karartması bitiş panelini örtmesin
	bucket.visible = false
	run_dust.emitting = false
	var pts := score(dist, carrots_total, won)
	var entry := {isim = rabbit_name, puan = pts}
	var table := Secim.insert_score(Secim.load_scores(), entry)
	Secim.save("skor", {liste = table})
	var title := ("%s yuvaya daldı!\nHalil eli boş döndü." % rabbit_name) if won else ("Halil yakaladı: %s" % rabbit_name)
	end_box.visible = true
	end_label.text = "%s\nPuan: %d\n\nEn iyiler\n%s\n\nEnter / dokun: tekrar koş    Esc: menü" % [title, pts, Secim.score_lines(table, table.find_custom(func(e): return is_same(e, entry)))]  # aynı puanlı eski kayıt değil, bu kayıt
